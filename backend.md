Viewed user.entity.ts:11-32
Listed directory auth
Listed directory emergency-contacts
Listed directory incident-alerts
Viewed auth.controller.ts:1-141
Viewed emergency-contacts.controller.ts:1-114
Viewed incident-alerts.controller.ts:1-124
Viewed users.controller.ts:1-91
Viewed health.controller.ts:1-22
Viewed app.controller.ts:1-31
Viewed api-key.guard.ts:1-58
Viewed login.dto.ts:1-23
Viewed register.dto.ts:1-4
Viewed create-emergency-contact.dto.ts:1-21
Viewed create-incident-alert.dto.ts:1-47
Viewed create-user.dto.ts:1-69
Viewed update-token.dto.ts:1-14

Aquí tienes la guía completa de todos los endpoints del backend **API JEPO**.

Esta documentación incluye los encabezados requeridos, los cuerpos de las peticiones (Body), los parámetros de ruta y ejemplos de respuestas exitosas.

> [!IMPORTANT]
> **Configuración Global:**
> *   **Base URL:** `http://localhost:9002/api` (o el puerto configurado en `.env`)
> *   **Prefijo Global:** Todos los endpoints comienzan con `/api`.
> *   **API Key:** Prácticamente todos los endpoints requieren el encabezado configurado en `API_KEY_HEADER_NAME` (por defecto `x-api-key`).

---

# 📚 Guía Completa de Endpoints - API JEPO

## 🔐 Seguridad y Autenticación

### Encabezados Requeridos (Headers)
1.  **x-api-key:** Requerido en **todos** los endpoints (excepto `/api/docs`).
2.  **Authorization:** Requerido en endpoints protegidos con JWT. Formato: `Bearer <token>`.

---

## 🔑 Módulo de Autenticación (`/auth`)

### 1. Registrar Usuario
Crea una cuenta nueva y emite automáticamente un token JWT.
*   **Método:** `POST`
*   **URL:** `/auth/register`
*   **Seguridad:** `x-api-key`
*   **Body:**
    ```json
    {
      "cedula": "V-12345678",
      "nombre": "Cesar",
      "apellido": "Perez",
      "email": "cesar@correo.com",
      "telefono": "+56912345678",
      "password": "Passw0rd!Segura",
      "token_fcm": "fcm_device_token_abc..." (Opcional)
    }
    ```
*   **Respuesta (200 OK):**
    ```json
    {
      "success": true,
      "message": "Registro exitoso",
      "data": {
        "access_token": "eyJhbG...",
        "token_type": "Bearer",
        "expires_in": "15m",
        "user": { "id": 1, "nombre": "Cesar", ... }
      }
    }
    ```

### 2. Iniciar Sesión
Autentica a un usuario existente.
*   **Método:** `POST`
*   **URL:** `/auth/login`
*   **Seguridad:** `x-api-key`
*   **Body:**
    ```json
    {
      "email": "cesar@correo.com",
      "password": "Passw0rd!Segura"
    }
    ```
*   **Respuesta (200 OK):** Igual a la respuesta de registro.

### 3. Obtener Sesión Actual (Me)
Valida el token y retorna los datos del usuario autenticado.
*   **Método:** `GET`
*   **URL:** `/auth/me`
*   **Seguridad:** `x-api-key` + `Authorization: Bearer <token>`
*   **Respuesta (200 OK):** Retorna el objeto del usuario.

---

## 👤 Módulo de Usuarios (`/usuarios`)

### 1. Listar Usuarios (Admin)
*   **Método:** `GET` | **URL:** `/usuarios`

### 2. Obtener Usuario por ID
*   **Método:** `GET` | **URL:** `/usuarios/:id`

### 3. Actualizar Token FCM
Actualiza el token de notificaciones push del dispositivo.
*   **Método:** `PATCH` | **URL:** `/usuarios/:id/token-fcm`
*   **Body:** `{ "token_fcm": "nuevo_token_123" }`

### 4. Eliminar Usuario
*   **Método:** `DELETE` | **URL:** `/usuarios/:id`

---

## 📞 Contactos de Emergencia (`/usuarios/contactos`)
*Requieren autenticación JWT. Gestionan los contactos del usuario que envía el token.*

### 1. Crear Contacto
*   **Método:** `POST` | **URL:** `/usuarios/contactos`
*   **Body:**
    ```json
    {
      "nombre_contacto": "Maria Perez",
      "telefono_contacto": "+56912345678",
      "prioridad": 1
    }
    ```

### 2. Listar Mis Contactos
*   **Método:** `GET` | **URL:** `/usuarios/contactos`

### 3. Eliminar Contacto
*   **Método:** `DELETE` | **URL:** `/usuarios/contactos/:id`

---

## 🚨 Alertas de Incidentes (`/alertas`)
*Requieren autenticación JWT.*

### 1. Crear Alerta
Si `es_proactiva` es `true`, el sistema envía automáticamente notificaciones por WhatsApp a tus contactos de emergencia en segundo plano.
*   **Método:** `POST` | **URL:** `/alertas`
*   **Body:**
    ```json
    {
      "latitud": -33.437192,
      "longitud": -70.650583,
      "url_audio_contexto": "https://storage.com/audio.mp3",
      "es_proactiva": true,
      "fecha_hora": "2026-04-26T12:30:00Z" (Opcional)
    }
    ```
*   **Respuesta (200 OK):**
    ```json
    {
      "message": "Alerta creada",
      "data": {
        "alerta": { "id": 1, ... },
        "contactosNotificar": [...],
        "notificaciones": { "total": 2, "enviadas": 2, ... }
      }
    }
    ```

### 2. Listar Mis Alertas
*   **Método:** `GET` | **URL:** `/alertas`

---

## 🏥 Monitoreo y Salud (`/health`)

### 1. Estado del Sistema
Verifica que la API y la conexión a la base de datos estén funcionando correctamente.
*   **Método:** `GET`
*   **URL:** `/health`
*   **Seguridad:** `x-api-key`
*   **Respuesta (200 OK):**
    ```json
    {
      "status": "ok",
      "info": {
        "database": { "status": "up" }
      },
      "error": {},
      "details": {
        "database": { "status": "up" }
      }
    }
    ```

---

## 📝 Notas de Implementación
*   **Paginación:** Por defecto, los listados retornan todos los elementos (se recomienda implementar paginación si el volumen crece).
*   **Soft Delete:** Los endpoints de eliminación no borran el registro físicamente, sino que marcan la columna `deleted_at`.
*   **Timeouts:** Las peticiones externas (como Evolution API) tienen un tiempo de espera de 5 segundos para evitar bloqueos del sistema.