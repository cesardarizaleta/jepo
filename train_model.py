"""
==============================================================================
JEPO — Human Activity Recognition (HAR) Model Training Pipeline v2
==============================================================================

Autor:          Equipo JEPO
Propósito:      Entrenar un modelo SOTA de clasificación de actividades humanas
                basado en una arquitectura híbrida CNN + Bi-LSTM, optimizado
                para inferencia embebida en dispositivos móviles via TFLite.

Arquitectura "Aura":
    Input (50, 6)
    → Conv1D(64, k=3) → BatchNorm → ReLU → MaxPool(2)
    → Conv1D(128, k=3) → BatchNorm → ReLU → MaxPool(2)
    → Bidirectional(LSTM(64))
    → Dense(64, ReLU) → Dropout(0.5)
    → Dense(3, softmax)

Clases (3 clases maestras para el cliente Flutter):
    0 = caida          ← dataset_caida.csv
    1 = actividad      ← dataset_escaleras.csv, dataset_caminaryescaleras.csv
    2 = normal         ← dataset_normal.csv, dataset_falsospositivos.csv,
                         dataset_normalcaminandocontelefonoenmano.csv

Data Augmentation:
    - Jittering (ruido Gaussiano σ=0.05)
    - Scaling (factor aleatorio 0.8–1.2)
    - Multiplica el dataset x3

Entrenamiento:
    - Optimizer: Adam con ReduceLROnPlateau
    - EarlyStopping (patience=10, monitor=val_loss)
    - Máximo 50 épocas

Exportación:
    - assets/models/jepo_model.tflite (cuantización dinámica)
    - jepo_label_map.json

Uso:
    pip install numpy pandas scikit-learn tensorflow
    python train_model.py

==============================================================================
"""

import json
import os

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.utils import shuffle
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau

# ==============================================================================
# 1. CONFIGURACIÓN
# ==============================================================================

# Ruta base del proyecto.
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))

# Directorio de datasets (usar el más reciente).
DATASETS_DIR = os.path.join(PROJECT_ROOT, 'datasets', 'datasets_15-05-2026')

# Mapeo de archivos CSV → clase maestra.
# Clase 0: Caída | Clase 1: Actividad | Clase 2: Normal
FILE_CLASS_MAP = {
    'dataset_caida.csv': 0,
    'dataset_escaleras.csv': 1,
    'dataset_caminaryescaleras.csv': 1,
    'dataset_normal.csv': 2,
    'dataset_falsospositivos.csv': 2,
    'dataset_normalcaminandocontelefonoenmano.csv': 2,
    'dataset_sillas.csv': 2,
    'dataset_escritorio.csv': 2,
}

# Nombres legibles de las clases (índice → nombre).
CLASS_NAMES = {
    0: 'caida',
    1: 'actividad',
    2: 'normal',
}

# Columnas de features sensoriales.
FEATURE_COLS = ['ax', 'ay', 'az', 'gx', 'gy', 'gz']
N_FEATURES = len(FEATURE_COLS)

# Sliding window.
WINDOW_SIZE = 50   # ~1 segundo a 50 Hz
STEP_SIZE = 25     # 50% solapamiento

# Entrenamiento.
EPOCHS = 50
BATCH_SIZE = 32
VALIDATION_SPLIT = 0.2

# Augmentation multiplier (original + N copias augmentadas).
AUGMENTATION_COPIES = 2  # Total = original + 2 = x3

# Rutas de salida.
OUTPUT_TFLITE = os.path.join(PROJECT_ROOT, 'assets', 'models', 'jepo_model.tflite')
OUTPUT_KERAS = os.path.join(PROJECT_ROOT, 'jepo_model_full.keras')
OUTPUT_LABEL_MAP = os.path.join(PROJECT_ROOT, 'jepo_label_map.json')


# ==============================================================================
# 2. CARGA DE DATOS CON MAPEO DINÁMICO
# ==============================================================================

def load_datasets(datasets_dir: str, file_class_map: dict) -> pd.DataFrame:
    """
    Carga los CSV del directorio y asigna la clase maestra según el mapeo
    de nombres de archivo. Tolerante a cabeceras sucias y tipos corruptos.

    Args:
        datasets_dir:   Ruta al directorio con los CSV.
        file_class_map: Dict {nombre_archivo: clase_int}.

    Returns:
        DataFrame con columnas FEATURE_COLS + 'label'.
    """
    CANONICAL_COLS = ['timestamp', 'ax', 'ay', 'az', 'gx', 'gy', 'gz', 'etiqueta']

    frames = []
    for filename, class_id in file_class_map.items():
        csv_path = os.path.join(datasets_dir, filename)
        if not os.path.exists(csv_path):
            print(f"[WARN] Archivo no encontrado, omitiendo: {filename}")
            continue

        # Detectar si la primera fila es cabecera.
        try:
            peek = pd.read_csv(csv_path, nrows=1, header=None)
        except Exception as e:
            print(f"[WARN] No se pudo leer '{filename}': {e}")
            continue

        first_row_is_header = False
        for col_idx in range(1, min(7, len(peek.columns))):
            val = str(peek.iloc[0, col_idx]).strip()
            try:
                float(val)
            except (ValueError, TypeError):
                first_row_is_header = True
                break

        df = pd.read_csv(
            csv_path,
            names=CANONICAL_COLS,
            header=0 if first_row_is_header else None,
            skipinitialspace=True,
        )

        # Forzar tipos numéricos en columnas de sensores.
        for col in FEATURE_COLS:
            if col in df.columns:
                df[col] = pd.to_numeric(df[col], errors='coerce')

        # Asignar clase maestra (ignora la columna 'etiqueta' del CSV).
        df['label'] = class_id

        # Conservar solo features + label.
        df = df[FEATURE_COLS + ['label']].copy()
        df.dropna(subset=FEATURE_COLS, inplace=True)

        frames.append(df)
        print(f"  ✓ {filename}: {len(df)} muestras → clase {class_id} ({CLASS_NAMES[class_id]})")

    if not frames:
        raise ValueError("No se pudo cargar ningún archivo CSV.")

    combined = pd.concat(frames, ignore_index=True)
    print(f"\n[INFO] Total muestras cargadas: {len(combined)}")
    print(f"[INFO] Distribución de clases:")
    for cls_id, name in CLASS_NAMES.items():
        count = (combined['label'] == cls_id).sum()
        print(f"       {cls_id} ({name}): {count}")
    print()

    return combined


# ==============================================================================
# 3. SLIDING WINDOW
# ==============================================================================

def create_windows(df: pd.DataFrame, window_size: int, step_size: int) -> tuple:
    """
    Segmenta la serie temporal en ventanas de tamaño fijo con solapamiento.
    Etiqueta de cada ventana = moda de las etiquetas en esa ventana.

    Returns:
        X: ndarray (n_windows, window_size, n_features)
        y: ndarray (n_windows,)
    """
    features = df[FEATURE_COLS].values.astype(np.float32)
    labels = df['label'].values.astype(np.int32)

    windows_X = []
    windows_y = []

    for start in range(0, len(features) - window_size + 1, step_size):
        end = start + window_size
        window_features = features[start:end]
        window_labels = labels[start:end]

        # Moda (etiqueta mayoritaria en la ventana).
        majority_label = np.bincount(window_labels).argmax()

        windows_X.append(window_features)
        windows_y.append(majority_label)

    X = np.array(windows_X, dtype=np.float32)
    y = np.array(windows_y, dtype=np.int32)

    print(f"[INFO] Ventanas generadas: {X.shape[0]}")
    print(f"[INFO] Forma de X: {X.shape}  (ventanas × timesteps × canales)")
    print(f"[INFO] Forma de y: {y.shape}\n")

    return X, y


# ==============================================================================
# 4. DATA AUGMENTATION
# ==============================================================================

def augment_jitter(X: np.ndarray, sigma: float = 0.05) -> np.ndarray:
    """
    Inyecta ruido Gaussiano (Jittering) a cada muestra.
    Simula variaciones naturales del sensor.

    Args:
        X:     Tensor de entrada (n, window_size, n_features).
        sigma: Desviación estándar del ruido.

    Returns:
        Tensor con ruido añadido, misma forma que X.
    """
    noise = np.random.normal(loc=0.0, scale=sigma, size=X.shape).astype(np.float32)
    return X + noise


def augment_scaling(X: np.ndarray, low: float = 0.8, high: float = 1.2) -> np.ndarray:
    """
    Escala aleatoriamente la magnitud de cada ventana.
    Simula variaciones en la intensidad del movimiento.

    Args:
        X:    Tensor de entrada (n, window_size, n_features).
        low:  Factor mínimo de escala.
        high: Factor máximo de escala.

    Returns:
        Tensor escalado, misma forma que X.
    """
    # Un factor por ventana por canal.
    factors = np.random.uniform(low, high, size=(X.shape[0], 1, X.shape[2])).astype(np.float32)
    return X * factors


def apply_augmentation(X: np.ndarray, y: np.ndarray, copies: int = 2) -> tuple:
    """
    Genera copias augmentadas del dataset combinando jittering y scaling.
    El dataset final = original + (copies × augmentadas).

    Args:
        X:      Tensor original.
        y:      Labels originales.
        copies: Número de copias augmentadas a generar.

    Returns:
        X_aug, y_aug con tamaño (1 + copies) × original.
    """
    all_X = [X]
    all_y = [y]

    for i in range(copies):
        # Alternar entre jittering y scaling+jittering.
        if i % 2 == 0:
            X_new = augment_jitter(X, sigma=0.05)
        else:
            X_new = augment_scaling(augment_jitter(X, sigma=0.03), low=0.85, high=1.15)
        all_X.append(X_new)
        all_y.append(y.copy())

    X_aug = np.concatenate(all_X, axis=0)
    y_aug = np.concatenate(all_y, axis=0)

    print(f"[INFO] Augmentation: {X.shape[0]} → {X_aug.shape[0]} ventanas (x{copies + 1})\n")

    return X_aug, y_aug


# ==============================================================================
# 5. ARQUITECTURA "AURA" — CNN + Bi-LSTM
# ==============================================================================

def build_model(n_timesteps: int, n_features: int, n_classes: int) -> keras.Model:
    """
    Construye un modelo Deep CNN 100% TFLite-Native para HAR.

    Flujo:
        Input (n_timesteps, n_features)
        → Conv1D(64, k=3) → BatchNorm → ReLU → MaxPool(2)
        → Conv1D(128, k=3) → BatchNorm → ReLU → MaxPool(2)
        → Conv1D(256, k=3) → BatchNorm → ReLU
        → GlobalAveragePooling1D
        → Dense(64, ReLU) → Dropout(0.5)
        → Dense(n_classes, softmax)

    GlobalAveragePooling1D reemplaza al LSTM: colapsa la dimensión temporal
    promediando los feature maps, capturando la distribución global de
    activaciones sin requerir operaciones recurrentes. Es ligero, rápido
    y 100% soportado por TFLite builtins.

    Args:
        n_timesteps: Longitud de la ventana (50).
        n_features:  Canales sensoriales (6).
        n_classes:   Clases de salida (3).

    Returns:
        Modelo Keras compilado.
    """
    model = keras.Sequential([
        layers.Input(shape=(n_timesteps, n_features)),

        # ── Bloque CNN 1: Features locales de bajo nivel ──
        layers.Conv1D(filters=64, kernel_size=3, padding='same'),
        layers.BatchNormalization(),
        layers.Activation('relu'),
        layers.MaxPooling1D(pool_size=2),

        # ── Bloque CNN 2: Features de nivel medio ──
        layers.Conv1D(filters=128, kernel_size=3, padding='same'),
        layers.BatchNormalization(),
        layers.Activation('relu'),
        layers.MaxPooling1D(pool_size=2),

        # ── Bloque CNN 3: Features de alto nivel ──
        layers.Conv1D(filters=256, kernel_size=3, padding='same'),
        layers.BatchNormalization(),
        layers.Activation('relu'),

        # ── Global Average Pooling: colapsa dimensión temporal ──
        layers.GlobalAveragePooling1D(),

        # ── Clasificador con Dropout agresivo ──
        layers.Dense(64, activation='relu'),
        layers.Dropout(0.5),

        # ── Salida: probabilidad sobre 3 clases ──
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
# 6. EXPORTACIÓN A TENSORFLOW LITE
# ==============================================================================

def export_to_tflite(model: keras.Model, output_path: str) -> None:
    """
    Convierte el modelo Keras a TFLite usando exclusivamente operaciones
    nativas (TFLITE_BUILTINS). Aplica cuantización dinámica de pesos.
    """
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]

    tflite_model = converter.convert()

    with open(output_path, 'wb') as f:
        f.write(tflite_model)

    size_kb = os.path.getsize(output_path) / 1024
    print(f"[INFO] Modelo TFLite exportado: {output_path}")
    print(f"[INFO] Tamaño: {size_kb:.1f} KB\n")


# ==============================================================================
# 7. PIPELINE PRINCIPAL
# ==============================================================================

def main():
    print("=" * 70)
    print("  JEPO — HAR Model Training Pipeline v2 (CNN + Bi-LSTM)")
    print("=" * 70)
    print()

    # ── Paso 1: Cargar datos con mapeo dinámico ──
    print("─" * 50)
    print("PASO 1: Carga de datasets con mapeo de clases")
    print("─" * 50)
    df = load_datasets(DATASETS_DIR, FILE_CLASS_MAP)

    n_classes = len(CLASS_NAMES)

    # Guardar mapeo de etiquetas.
    with open(OUTPUT_LABEL_MAP, 'w', encoding='utf-8') as f:
        json.dump(CLASS_NAMES, f, ensure_ascii=False, indent=2)
    print(f"[INFO] Label map guardado: {OUTPUT_LABEL_MAP}\n")

    # ── Paso 2: Crear ventanas deslizantes ──
    print("─" * 50)
    print("PASO 2: Sliding Window (size={}, step={})".format(WINDOW_SIZE, STEP_SIZE))
    print("─" * 50)
    X, y = create_windows(df, WINDOW_SIZE, STEP_SIZE)

    # ── Paso 3: Data Augmentation ──
    print("─" * 50)
    print("PASO 3: Data Augmentation (Jittering + Scaling)")
    print("─" * 50)
    X_aug, y_aug = apply_augmentation(X, y, copies=AUGMENTATION_COPIES)

    # ── Paso 4: Split train/validation ──
    print("─" * 50)
    print("PASO 4: División Train / Validation")
    print("─" * 50)
    X_aug, y_aug = shuffle(X_aug, y_aug, random_state=42)
    X_train, X_val, y_train, y_val = train_test_split(
        X_aug, y_aug, test_size=VALIDATION_SPLIT, random_state=42, stratify=y_aug
    )
    print(f"[INFO] Train: {X_train.shape[0]} ventanas")
    print(f"[INFO] Val:   {X_val.shape[0]} ventanas\n")

    # ── Paso 5: Construir y entrenar modelo ──
    print("─" * 50)
    print("PASO 5: Construcción y Entrenamiento (CNN + Bi-LSTM)")
    print("─" * 50)
    model = build_model(WINDOW_SIZE, N_FEATURES, n_classes)

    callbacks = [
        EarlyStopping(
            monitor='val_loss',
            patience=10,
            restore_best_weights=True,
            verbose=1,
        ),
        ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5,
            min_lr=1e-6,
            verbose=1,
        ),
    ]

    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        callbacks=callbacks,
        verbose=1,
    )

    # Evaluación final.
    val_loss, val_acc = model.evaluate(X_val, y_val, verbose=0)
    print(f"\n[RESULTADO] Val Accuracy: {val_acc * 100:.2f}%")
    print(f"[RESULTADO] Val Loss:     {val_loss:.4f}\n")

    # ── Paso 6: Guardar modelo Keras completo ──
    model.save(OUTPUT_KERAS)
    print(f"[INFO] Modelo Keras guardado: {OUTPUT_KERAS}")

    # ── Paso 7: Exportar a TFLite ──
    print("─" * 50)
    print("PASO 7: Exportación a TensorFlow Lite")
    print("─" * 50)
    export_to_tflite(model, OUTPUT_TFLITE)

    # ── Resumen final ──
    print("=" * 70)
    print("  ENTRENAMIENTO COMPLETADO")
    print("=" * 70)
    print(f"  • Modelo TFLite:   {OUTPUT_TFLITE}")
    print(f"  • Modelo Keras:    {OUTPUT_KERAS}")
    print(f"  • Label Map:       {OUTPUT_LABEL_MAP}")
    print(f"  • Clases:          {list(CLASS_NAMES.values())}")
    print(f"  • Val Accuracy:    {val_acc * 100:.2f}%")
    print(f"  • Épocas usadas:   {len(history.history['loss'])}")
    print(f"  • LR final:        {model.optimizer.learning_rate.numpy():.2e}")
    print("=" * 70)


if __name__ == '__main__':
    main()
