"""
==============================================================================
JEPO — Human Activity Recognition (HAR) Model Training Pipeline
==============================================================================

Autor:          Equipo JEPO
Propósito:      Entrenar un modelo de clasificación de actividades humanas
                basado en datos de acelerómetro y giroscopio recolectados
                desde dispositivos móviles, y exportarlo a TensorFlow Lite
                para inferencia embebida en Flutter/Android.

Arquitectura:   Conv1D → MaxPooling1D → Conv1D → MaxPooling1D → Flatten →
                Dense → Dropout → Dense (softmax)

Entrada:        Ventanas deslizantes de 50 muestras × 6 canales (ax,ay,az,gx,gy,gz)
Salida:         Probabilidad sobre 5 clases de actividad

Clases:
    0 = normal
    1 = caminar
    2 = correr / subir escaleras
    3 = bajar escaleras
    4 = caida

Uso:
    pip install numpy pandas scikit-learn tensorflow
    python train_model.py

Resultado:
    - jepo_model.tflite          (modelo cuantizado para móvil)
    - jepo_label_map.json        (mapeo índice → etiqueta)
    - jepo_model_full.keras      (modelo completo para re-entrenamiento)
==============================================================================
"""

import json
import glob
import os

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.utils import shuffle
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

# ==============================================================================
# 1. CONFIGURACIÓN DE HIPERPARÁMETROS
# ==============================================================================

# Tamaño de la ventana deslizante (en número de muestras).
# Con una frecuencia de muestreo típica de ~50 Hz, 50 muestras ≈ 1 segundo.
WINDOW_SIZE = 50

# Paso de desplazamiento entre ventanas consecutivas.
# Un step de 25 genera un solapamiento del 50%, lo cual aumenta la cantidad
# de ejemplos de entrenamiento y mejora la generalización del modelo.
STEP_SIZE = 25

# Columnas de features sensoriales (6 ejes: acelerómetro + giroscopio).
FEATURE_COLS = ['ax', 'ay', 'az', 'gx', 'gy', 'gz']

# Número de canales de entrada (debe coincidir con len(FEATURE_COLS)).
N_FEATURES = len(FEATURE_COLS)

# Directorio donde residen los archivos CSV de telemetría.
DATASETS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'datasets')

# Épocas de entrenamiento.
EPOCHS = 20

# Tamaño del batch para entrenamiento.
BATCH_SIZE = 32

# Fracción de datos reservada para validación.
VALIDATION_SPLIT = 0.2

# Rutas de salida.
OUTPUT_TFLITE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'jepo_model.tflite')
OUTPUT_KERAS = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'jepo_model_full.keras')
OUTPUT_LABEL_MAP = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'jepo_label_map.json')


# ==============================================================================
# 2. CARGA Y LIMPIEZA DE DATOS
# ==============================================================================

def load_datasets(datasets_dir: str) -> pd.DataFrame:
    """
    Carga todos los archivos CSV del directorio especificado y los concatena
    en un único DataFrame unificado.

    Cada CSV debe contener las columnas:
        timestamp, ax, ay, az, gx, gy, gz, etiqueta

    Esta función es tolerante a:
        - Cabeceras con espacios en blanco o nombres inconsistentes.
        - Archivos sin cabecera explícita.
        - Valores no numéricos infiltrados en columnas de sensores.
        - Filas completamente vacías o corruptas.

    Returns:
        DataFrame con todas las muestras concatenadas y ordenadas por timestamp.
    """
    # Nombres canónicos que forzamos en cada CSV.
    CANONICAL_COLS = ['timestamp', 'ax', 'ay', 'az', 'gx', 'gy', 'gz', 'etiqueta']

    csv_files = glob.glob(os.path.join(datasets_dir, '*.csv'))

    if not csv_files:
        raise FileNotFoundError(
            f"No se encontraron archivos CSV en '{datasets_dir}'. "
            f"Asegúrate de que la carpeta datasets/ contenga los archivos de telemetría."
        )

    print(f"[INFO] Archivos CSV encontrados: {len(csv_files)}")
    for f in csv_files:
        print(f"       • {os.path.basename(f)}")

    frames = []
    for csv_path in csv_files:
        # Leer sin asumir cabecera; forzar nuestros nombres canónicos.
        # header=0 descarta la primera fila si contiene texto (cabecera vieja).
        # Si el archivo NO tiene cabecera, la primera fila de datos se perdería,
        # así que primero inspeccionamos la primera línea.
        try:
            peek = pd.read_csv(csv_path, nrows=1, header=None)
        except Exception as e:
            print(f"[WARN] No se pudo leer '{os.path.basename(csv_path)}': {e}")
            continue

        # Determinar si la primera fila es una cabecera (contiene strings no numéricos
        # en las columnas que deberían ser numéricas: posiciones 1-6).
        first_row_is_header = False
        for col_idx in range(1, min(7, len(peek.columns))):
            val = str(peek.iloc[0, col_idx]).strip()
            try:
                float(val)
            except (ValueError, TypeError):
                first_row_is_header = True
                break

        # Leer el CSV completo con nombres forzados.
        df = pd.read_csv(
            csv_path,
            names=CANONICAL_COLS,
            header=0 if first_row_is_header else None,
            skipinitialspace=True,
        )

        # Si el CSV tiene más o menos columnas de las esperadas, recortar/expandir.
        for col in CANONICAL_COLS:
            if col not in df.columns:
                df[col] = np.nan
        df = df[CANONICAL_COLS]

        frames.append(df)
        print(f"       ✓ {os.path.basename(csv_path)}: {len(df)} filas")

    if not frames:
        raise ValueError("Ningún archivo CSV pudo ser leído correctamente.")

    combined = pd.concat(frames, ignore_index=True)

    # Forzar conversión numérica en columnas de sensores.
    # Cualquier valor que no sea parseable se convierte a NaN.
    for col in FEATURE_COLS:
        combined[col] = pd.to_numeric(combined[col], errors='coerce')

    # Convertir timestamp a numérico también (milisegundos epoch).
    combined['timestamp'] = pd.to_numeric(combined['timestamp'], errors='coerce')

    # Eliminar filas donde algún sensor sea NaN (datos corruptos).
    combined.dropna(subset=FEATURE_COLS, inplace=True)

    # Eliminar filas sin etiqueta.
    combined = combined[combined['etiqueta'].notna() & (combined['etiqueta'].astype(str).str.strip() != '')]

    # Normalizar etiquetas a minúsculas y sin espacios.
    combined['etiqueta'] = combined['etiqueta'].astype(str).str.strip().str.lower()

    # Ordenar por timestamp para mantener coherencia temporal.
    combined.sort_values('timestamp', inplace=True)
    combined.reset_index(drop=True, inplace=True)

    print(f"\n[INFO] Total de muestras válidas: {len(combined)}")
    print(f"[INFO] Distribución de clases:\n{combined['etiqueta'].value_counts().to_string()}\n")

    return combined


def encode_labels(df: pd.DataFrame) -> tuple[pd.DataFrame, dict[int, str]]:
    """
    Convierte las etiquetas de texto a valores numéricos enteros (0..N-1).

    Returns:
        - DataFrame con columna 'label' numérica añadida.
        - Diccionario de mapeo {índice: nombre_etiqueta}.
    """
    unique_labels = sorted(df['etiqueta'].unique())
    label_to_idx = {label: idx for idx, label in enumerate(unique_labels)}
    idx_to_label = {idx: label for label, idx in label_to_idx.items()}

    df = df.copy()
    df['label'] = df['etiqueta'].map(label_to_idx)

    print(f"[INFO] Mapeo de etiquetas: {label_to_idx}")
    print(f"[INFO] Número de clases: {len(unique_labels)}\n")

    return df, idx_to_label


# ==============================================================================
# 3. SLIDING WINDOW (VENTANA DESLIZANTE)
# ==============================================================================

def create_windows(df: pd.DataFrame, window_size: int, step_size: int) -> tuple[np.ndarray, np.ndarray]:
    """
    Segmenta la serie temporal en ventanas de tamaño fijo con solapamiento.

    Para cada ventana, se toma la etiqueta más frecuente (moda) como la
    etiqueta representativa de esa ventana. Esto maneja correctamente los
    bordes entre actividades distintas.

    Args:
        df:          DataFrame con columnas FEATURE_COLS + 'label'.
        window_size: Número de muestras por ventana.
        step_size:   Desplazamiento entre ventanas consecutivas.

    Returns:
        X: ndarray de forma (n_windows, window_size, n_features)
        y: ndarray de forma (n_windows,) con etiquetas enteras.
    """
    features = df[FEATURE_COLS].values
    labels = df['label'].values

    windows_X = []
    windows_y = []

    for start in range(0, len(features) - window_size + 1, step_size):
        end = start + window_size
        window_features = features[start:end]
        window_labels = labels[start:end]

        # Etiqueta mayoritaria en la ventana (moda).
        # np.bincount requiere enteros no-negativos.
        majority_label = np.bincount(window_labels.astype(int)).argmax()

        windows_X.append(window_features)
        windows_y.append(majority_label)

    X = np.array(windows_X, dtype=np.float32)
    y = np.array(windows_y, dtype=np.int32)

    print(f"[INFO] Ventanas generadas: {X.shape[0]}")
    print(f"[INFO] Forma de X: {X.shape}  (ventanas × muestras × canales)")
    print(f"[INFO] Forma de y: {y.shape}\n")

    return X, y


# ==============================================================================
# 4. CONSTRUCCIÓN DEL MODELO (Conv1D para Series Temporales)
# ==============================================================================

def build_model(n_timesteps: int, n_features: int, n_classes: int) -> keras.Model:
    """
    Construye un modelo CNN 1D ligero optimizado para HAR en dispositivos móviles.

    Arquitectura:
        Input (window_size, 6)
        → Conv1D(64, kernel=3, ReLU) → MaxPool1D(2)
        → Conv1D(128, kernel=3, ReLU) → MaxPool1D(2)
        → Flatten
        → Dense(64, ReLU) → Dropout(0.3)
        → Dense(n_classes, softmax)

    El modelo es deliberadamente compacto (~50-100 KB en TFLite) para
    ejecutarse en tiempo real en dispositivos Android de gama media.

    Args:
        n_timesteps: Longitud de la ventana temporal (WINDOW_SIZE).
        n_features:  Número de canales sensoriales (6).
        n_classes:   Número de actividades a clasificar.

    Returns:
        Modelo Keras compilado.
    """
    model = keras.Sequential([
        # Primera capa convolucional: extrae patrones locales de corto alcance.
        layers.Input(shape=(n_timesteps, n_features)),
        layers.Conv1D(filters=64, kernel_size=3, activation='relu', padding='same'),
        layers.MaxPooling1D(pool_size=2),

        # Segunda capa convolucional: captura patrones de mayor abstracción.
        layers.Conv1D(filters=128, kernel_size=3, activation='relu', padding='same'),
        layers.MaxPooling1D(pool_size=2),

        # Aplanar para conectar con capas densas.
        layers.Flatten(),

        # Capa densa con regularización por Dropout para evitar overfitting.
        layers.Dense(64, activation='relu'),
        layers.Dropout(0.3),

        # Capa de salida: distribución de probabilidad sobre las clases.
        layers.Dense(n_classes, activation='softmax'),
    ])

    model.compile(
        optimizer='adam',
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy'],
    )

    model.summary()
    print()

    return model


# ==============================================================================
# 5. EXPORTACIÓN A TENSORFLOW LITE
# ==============================================================================

def export_to_tflite(model: keras.Model, output_path: str) -> None:
    """
    Convierte el modelo Keras entrenado a formato TensorFlow Lite (.tflite).

    Se aplica optimización por defecto (cuantización dinámica de pesos) para
    reducir el tamaño del archivo sin pérdida significativa de precisión.

    Args:
        model:       Modelo Keras entrenado.
        output_path: Ruta de salida para el archivo .tflite.
    """
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    # Optimización: cuantización dinámica de pesos (reduce tamaño ~2-4x).
    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    tflite_model = converter.convert()

    with open(output_path, 'wb') as f:
        f.write(tflite_model)

    size_kb = os.path.getsize(output_path) / 1024
    print(f"[INFO] Modelo TFLite exportado: {output_path}")
    print(f"[INFO] Tamaño del modelo: {size_kb:.1f} KB\n")


# ==============================================================================
# 6. PIPELINE PRINCIPAL
# ==============================================================================

def main():
    print("=" * 70)
    print("  JEPO — HAR Model Training Pipeline")
    print("=" * 70)
    print()

    # ── Paso 1: Cargar datos ──
    print("─" * 40)
    print("PASO 1: Carga de datasets")
    print("─" * 40)
    df = load_datasets(DATASETS_DIR)

    # ── Paso 2: Codificar etiquetas ──
    print("─" * 40)
    print("PASO 2: Codificación de etiquetas")
    print("─" * 40)
    df, idx_to_label = encode_labels(df)
    n_classes = len(idx_to_label)

    # Guardar mapeo de etiquetas.
    with open(OUTPUT_LABEL_MAP, 'w', encoding='utf-8') as f:
        json.dump(idx_to_label, f, ensure_ascii=False, indent=2)
    print(f"[INFO] Mapeo guardado en: {OUTPUT_LABEL_MAP}\n")

    # ── Paso 3: Crear ventanas deslizantes ──
    print("─" * 40)
    print("PASO 3: Sliding Window")
    print("─" * 40)
    X, y = create_windows(df, WINDOW_SIZE, STEP_SIZE)

    # ── Paso 4: Split train/test ──
    print("─" * 40)
    print("PASO 4: División Train / Validation")
    print("─" * 40)
    X, y = shuffle(X, y, random_state=42)
    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=VALIDATION_SPLIT, random_state=42, stratify=y
    )
    print(f"[INFO] Train: {X_train.shape[0]} ventanas")
    print(f"[INFO] Val:   {X_val.shape[0]} ventanas\n")

    # ── Paso 5: Construir y entrenar modelo ──
    print("─" * 40)
    print("PASO 5: Construcción y Entrenamiento del Modelo")
    print("─" * 40)
    model = build_model(WINDOW_SIZE, N_FEATURES, n_classes)

    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        verbose=1,
    )

    # Evaluación final.
    val_loss, val_acc = model.evaluate(X_val, y_val, verbose=0)
    print(f"\n[RESULTADO] Accuracy en validación: {val_acc * 100:.2f}%")
    print(f"[RESULTADO] Loss en validación: {val_loss:.4f}\n")

    # ── Paso 6: Guardar modelo completo (para re-entrenamiento futuro) ──
    model.save(OUTPUT_KERAS)
    print(f"[INFO] Modelo Keras guardado: {OUTPUT_KERAS}")

    # ── Paso 7: Exportar a TFLite ──
    print("─" * 40)
    print("PASO 7: Exportación a TensorFlow Lite")
    print("─" * 40)
    export_to_tflite(model, OUTPUT_TFLITE)

    # ── Resumen final ──
    print("=" * 70)
    print("  ENTRENAMIENTO COMPLETADO")
    print("=" * 70)
    print(f"  • Modelo TFLite:   {OUTPUT_TFLITE}")
    print(f"  • Modelo Keras:    {OUTPUT_KERAS}")
    print(f"  • Label Map:       {OUTPUT_LABEL_MAP}")
    print(f"  • Clases:          {list(idx_to_label.values())}")
    print(f"  • Val Accuracy:    {val_acc * 100:.2f}%")
    print("=" * 70)


if __name__ == '__main__':
    main()
