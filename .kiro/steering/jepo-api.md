---
inclusion: auto
---

# JEPO API v1.0.0 — Referencia Rápida

Sistema de Asistencia Proactiva a Personas.

## Base URL

Definida en el archivo `.env` del proyecto como `API_BASE_URL`.

## Autenticación

Todas las rutas protegidas requieren el header:

```
Authorization: Bearer <jwt_token>
```

El token se obtiene en `/api/auth/register` o `/api/auth/login`.

---

## Health

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/health` | Verificar estado del sistema y BD |

**Respuesta 200:**

```json
{
  "status": "ok",
  "info": { "database": { "status": "up" } },
  "error": {},
  "details": { "database": { "status": "up" } }
}
```

---

## Auth

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/auth/register` | Registrar usuario y generar JWT |
| POST | `/api/auth/login` | Iniciar sesión y obtener JWT |
| GET | `/api/auth/me` | Obtener datos del usuario autenticado |

### POST /api/auth/register

**Body:**

```json
{
  "cedula": "V-12345678",
  "nombre": "Maria",
  "apellido": "Perez",
  "email": "maria.perez@jepo.com",
  "telefono": "+584121112233",
  "password": "Passw0rd!Segura",
  "token_fcm": "fcm_device_token_abc123456789"
}
```

**Respuesta 201:**

```json
{
  "success": true,
  "message": "Registro exitoso",
  "data": {
    "access_token": "<jwt_token>",
    "user": {
      "id": 1,
      "cedula": 12123456,
      "nombre": "Maria",
      "apellido": "Perez",
      "email": "maria.perez@jepo.com",
      "telefono": "+584121112233",
      "token_fcm": "fcm_token_ABC123XYZ"
    }
  }
}
```

### POST /api/auth/login

**Body:**

```json
{
  "email": "maria.perez@jepo.com",
  "password": "Passw0rd!Segura"
}
```

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Login exitoso",
  "data": {
    "access_token": "<jwt_token>",
    "user": {
      "id": 1,
      "cedula": 12123456,
      "nombre": "Maria",
      "apellido": "Perez",
      "email": "maria.perez@jepo.com",
      "telefono": "+584121112233",
      "token_fcm": "fcm_token_ABC123XYZ"
    }
  }
}
```

**Errores:** 401 — Credenciales inválidas.

### GET /api/auth/me

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Sesion valida",
  "data": {
    "id": 1,
    "cedula": 12123456,
    "nombre": "Maria",
    "apellido": "Perez",
    "email": "maria.perez@jepo.com",
    "telefono": "+584121112233",
    "token_fcm": "fcm_token_ABC123XYZ"
  }
}
```

**Errores:** 401 — Token ausente, inválido o expirado.

---

## Contactos de Emergencia

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/usuarios/contactos` | Crear contacto de emergencia |
| GET | `/api/usuarios/contactos` | Listar contactos del usuario |
| GET | `/api/usuarios/contactos/{id}` | Obtener contacto por ID |
| PATCH | `/api/usuarios/contactos/{id}` | Actualizar contacto por ID |
| DELETE | `/api/usuarios/contactos/{id}` | Eliminar contacto por ID |

### POST /api/usuarios/contactos

**Body:**

```json
{
  "nombre_contacto": "Juan Lopez",
  "telefono_contacto": "+584141234567",
  "prioridad": 1
}
```

**Respuesta 201:**

```json
{
  "success": true,
  "message": "Contacto de emergencia creado",
  "data": {
    "id": 10,
    "id_usuario": 1,
    "nombre_contacto": "Juan Lopez",
    "telefono_contacto": "+584141234567",
    "prioridad": 1
  }
}
```

### GET /api/usuarios/contactos

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Contactos obtenidos",
  "data": [
    {
      "id": 10,
      "id_usuario": 1,
      "nombre_contacto": "Juan Lopez",
      "telefono_contacto": "+584141234567",
      "prioridad": 1
    }
  ]
}
```

### PATCH /api/usuarios/contactos/{id}

**Body (todos los campos opcionales):**

```json
{
  "nombre_contacto": "Carlos Romero",
  "telefono_contacto": "+584121998877",
  "prioridad": 2
}
```

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Contacto actualizado",
  "data": {
    "id": 10,
    "id_usuario": 1,
    "nombre_contacto": "Carlos Romero",
    "telefono_contacto": "+584121998877",
    "prioridad": 2
  }
}
```

### DELETE /api/usuarios/contactos/{id}

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Contacto eliminado",
  "data": null
}
```

---

## Alertas de Incidentes

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/alertas` | Crear alerta de incidente |
| GET | `/api/alertas` | Listar alertas del usuario |
| GET | `/api/alertas/{id}` | Obtener alerta por ID |
| PATCH | `/api/alertas/{id}` | Actualizar alerta por ID |
| DELETE | `/api/alertas/{id}` | Eliminar alerta por ID |

### POST /api/alertas

**Body:**

```json
{
  "latitud": 10.50234567,
  "longitud": -66.91234567,
  "url_audio_contexto": "https://storage.jepo.com/audio/contexto-123.mp3",
  "fecha_hora": "2026-05-08T10:30:00.000Z",
  "es_proactiva": true
}
```

**Respuesta 201:**

```json
{
  "success": true,
  "message": "Alerta creada",
  "data": {
    "alerta": {
      "id": 100,
      "id_usuario": 1,
      "latitud": 10.50234567,
      "longitud": -66.91234567,
      "url_audio_contexto": "https://storage.jepo.com/audio/contexto-123.mp3",
      "fecha_hora": "2026-05-08T10:30:00.000Z",
      "es_proactiva": true
    },
    "contactosNotificar": [
      {
        "id": 10,
        "nombre_contacto": "Juan Lopez",
        "telefono_contacto": "+584141234567",
        "prioridad": 1
      }
    ],
    "notificaciones": [
      {
        "contactoId": 10,
        "enviado": true,
        "detalle": "Mensaje enviado por Evolution API"
      }
    ]
  }
}
```

### GET /api/alertas

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Alertas obtenidas",
  "data": [
    {
      "id": 100,
      "id_usuario": 1,
      "latitud": 10.50234567,
      "longitud": -66.91234567,
      "url_audio_contexto": "https://storage.jepo.com/audio/contexto-123.mp3",
      "fecha_hora": "2026-05-08T10:30:00.000Z",
      "es_proactiva": true
    }
  ]
}
```

### PATCH /api/alertas/{id}

**Body (todos los campos opcionales):**

```json
{
  "latitud": 10.50000001,
  "longitud": -66.90000001,
  "url_audio_contexto": "https://storage.jepo.com/audio/contexto-actualizado.mp3",
  "fecha_hora": "2026-05-08T11:05:00.000Z",
  "es_proactiva": false
}
```

### DELETE /api/alertas/{id}

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Alerta eliminada",
  "data": null
}
```

---

## Usuarios

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/usuarios` | Crear usuario |
| GET | `/api/usuarios` | Listar usuarios |
| GET | `/api/usuarios/{id}` | Obtener usuario por ID |
| PATCH | `/api/usuarios/{id}` | Actualizar usuario por ID |
| DELETE | `/api/usuarios/{id}` | Eliminar usuario por ID |
| PATCH | `/api/usuarios/{id}/token-fcm` | Actualizar token FCM |

### POST /api/usuarios

**Body:**

```json
{
  "cedula": "V-12345678",
  "nombre": "Maria",
  "apellido": "Perez",
  "email": "maria.perez@jepo.com",
  "telefono": "+584121112233",
  "password": "Passw0rd!Segura",
  "token_fcm": "fcm_device_token_abc123456789"
}
```

### PATCH /api/usuarios/{id}

**Body (todos los campos opcionales):**

```json
{
  "nombre": "Maria Elena",
  "apellido": "Perez Rojas",
  "email": "maria.actualizada@jepo.com",
  "telefono": "+584241112233",
  "password": "NuevaClave#2026",
  "token_fcm": "nuevo_fcm_token_XYZ987"
}
```

### PATCH /api/usuarios/{id}/token-fcm

**Body:**

```json
{
  "token_fcm": "fcm_device_token_abc123456789"
}
```

---

## Formato de Respuesta Estándar

Todas las respuestas siguen esta estructura:

```json
{
  "success": true | false,
  "message": "Descripción del resultado",
  "data": { ... } | [ ... ] | null
}
```

## Formato de Teléfono

Los teléfonos se almacenan en formato E.164 venezolano: `+58XXXXXXXXXX` (12 dígitos con prefijo de país).

## DTOs Principales

- **RegisterDto**: cedula, nombre, apellido, email, telefono, password, token_fcm
- **LoginDto**: email, password
- **CreateEmergencyContactDto**: nombre_contacto, telefono_contacto, prioridad
- **UpdateEmergencyContactDto**: nombre_contacto?, telefono_contacto?, prioridad?
- **CreateIncidentAlertDto**: latitud, longitud, url_audio_contexto, fecha_hora, es_proactiva
- **UpdateIncidentAlertDto**: latitud?, longitud?, url_audio_contexto?, fecha_hora?, es_proactiva?
- **CreateUserDto**: cedula, nombre, apellido, email, telefono, password, token_fcm
- **UpdateUserDto**: nombre?, apellido?, email?, telefono?, password?, token_fcm?
- **UpdateTokenDto**: token_fcm
