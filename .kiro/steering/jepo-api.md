---
inclusion: auto
---

# JEPO API v1.2.0 — Referencia Rápida

Sistema de Asistencia Proactiva a Personas.

## Base URL

Definida en el archivo `.env` del frontend como `API_BASE_URL`. Ejemplo local: `http://localhost:3000`.

Todas las rutas están prefijadas con `/api`.

## Autenticación

Cada request a la API (públicos y protegidos) requiere el header de API Key:

```
x-api-key: <valor_de_API_KEY>
```

Las rutas protegidas además requieren JWT:

```
Authorization: Bearer <jwt_token>
```

El JWT se obtiene en `/api/auth/register` o `/api/auth/login` y expira según `JWT_EXPIRES_IN` (por defecto 30 días).

### Invalidación de JWT por cambio de contraseña

Al completar `/api/auth/reset-password` o actualizar la contraseña del usuario, todos los JWT emitidos antes del cambio quedan inválidos (`password_changed_at > iat`). El cliente debe pedir un nuevo login.

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

| Método | Ruta | Descripción | Auth |
|--------|------|-------------|------|
| POST | `/api/auth/register` | Registrar usuario y generar JWT | Solo `x-api-key` |
| POST | `/api/auth/login` | Iniciar sesión y obtener JWT | Solo `x-api-key` |
| POST | `/api/auth/forgot-password` | Solicitar OTP para recuperar contraseña | Solo `x-api-key` |
| POST | `/api/auth/reset-password` | Resetear contraseña con OTP | Solo `x-api-key` |
| GET | `/api/auth/me` | Obtener datos del usuario autenticado | `x-api-key` + Bearer |

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
    "token_type": "Bearer",
    "expires_in": "30d",
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

**Errores comunes:** 409 — email, cédula o teléfono ya registrados.

### POST /api/auth/login

**Body:**

```json
{
  "email": "maria.perez@jepo.com",
  "password": "Passw0rd!Segura"
}
```

**Respuesta 200:** mismo formato que `register`.

**Errores:** 401 — Credenciales inválidas.

### POST /api/auth/forgot-password

Solicita el envío de un OTP (6 dígitos, TTL 15 min) al canal indicado.

**Body:**

```json
{
  "email_or_phone": "maria.perez@jepo.com",
  "method": "email"
}
```

- `method`: `"email"` (Nodemailer / Gmail) o `"whatsapp"` (Evolution API).
- `email_or_phone`: email registrado o teléfono E.164.

**Respuesta 200 (siempre, anti-enumeración):**

```json
{
  "success": true,
  "message": "Si la cuenta existe, recibiras un codigo de verificacion",
  "data": null
}
```

**Errores:**

- `400` — Cooldown activo (menos de 60 s desde el último envío) o máximo de 3 envíos activos alcanzado.
- `500` — El proveedor de entrega (Gmail / Evolution) falló. No se reintenta automáticamente; el cliente puede reintentar tras unos segundos.

**Throttling:** 5 solicitudes / 60 s por IP.

### POST /api/auth/reset-password

Consume el OTP activo y actualiza la contraseña. Tras éxito, todos los JWT previos quedan invalidados.

**Body:**

```json
{
  "email_or_phone": "maria.perez@jepo.com",
  "otp": "123456",
  "new_password": "NuevaClave#2026"
}
```

**Política de contraseña:** mínimo 8 caracteres, al menos 1 mayúscula y 1 número.

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Contrasena actualizada correctamente",
  "data": null
}
```

**Errores:** 401 — Código inválido, expirado o intentos agotados (máx 3 por challenge).

**Throttling:** 5 solicitudes / 60 s por IP.

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

**Errores:** 401 — Token ausente, inválido, expirado o invalidado por cambio de contraseña.

---

## Contactos de Emergencia

Flujo opt-in: al crearse, el contacto nace en estado `PENDING` y se envía un OTP por WhatsApp al teléfono del contacto. El contacto le dicta el código al usuario, y este lo verifica. **Solo los contactos en estado `VERIFIED` reciben notificaciones de alertas proactivas.**

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/usuarios/contactos` | Crear contacto (PENDING + envía OTP) |
| GET | `/api/usuarios/contactos` | Listar contactos del usuario (ordenados por prioridad) |
| PATCH | `/api/usuarios/contactos/reordenar` | Reordenar contactos (bulk update de prioridades) |
| GET | `/api/usuarios/contactos/{id}` | Obtener contacto por ID |
| PATCH | `/api/usuarios/contactos/{id}` | Actualizar contacto |
| DELETE | `/api/usuarios/contactos/{id}` | Eliminar contacto |
| POST | `/api/usuarios/contactos/{id}/verificar` | Verificar OTP del contacto |
| POST | `/api/usuarios/contactos/{id}/reenviar-codigo` | Reenviar OTP (cooldown 60 s) |

Reglas:

- Máximo **5 contactos por usuario**.
- Máximo **3 reenvíos activos** por contacto.
- Cooldown entre reenvíos: **60 s**.
- Intentos de adivinar el código: **3 por challenge**.
- Si se edita `telefono_contacto`, el contacto vuelve a `PENDING` y debe reverificarse.

### POST /api/usuarios/contactos

**Body:**

```json
{
  "nombre_contacto": "Juan Lopez",
  "telefono_contacto": "+584141234567",
  "prioridad": 1
}
```

- `prioridad` es **opcional**. Si no se envía, el contacto se asigna automáticamente al final de la lista (`MAX(prioridad) + 1`).

**Respuesta 201:**

```json
{
  "success": true,
  "message": "Contacto de emergencia creado",
  "data": {
    "id": 10,
    "id_usuario": 12123456,
    "nombre_contacto": "Juan Lopez",
    "telefono_contacto": "+584141234567",
    "prioridad": 1,
    "estado_verificacion": "PENDING",
    "accepted_at": null
  }
}
```

**Errores:** 400 — máximo de contactos alcanzado. 409 — teléfono duplicado para el usuario.

### GET /api/usuarios/contactos

Retorna los contactos **ordenados por `prioridad ASC`** (el orden visual de la lista).

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Contactos obtenidos",
  "data": [
    {
      "id": 10,
      "id_usuario": 12123456,
      "nombre_contacto": "Juan Lopez",
      "telefono_contacto": "+584141234567",
      "prioridad": 1,
      "estado_verificacion": "VERIFIED",
      "accepted_at": "2026-05-13T14:22:10.000Z"
    },
    {
      "id": 15,
      "id_usuario": 12123456,
      "nombre_contacto": "Maria Gomez",
      "telefono_contacto": "+584121234567",
      "prioridad": 2,
      "estado_verificacion": "PENDING",
      "accepted_at": null
    }
  ]
}
```

### PATCH /api/usuarios/contactos/reordenar

Reordena masivamente los contactos tras un Drag & Drop en el frontend. Envía el array completo con el nuevo orden.

**Body:**

```json
{
  "orden": [
    { "id": 15, "prioridad": 1 },
    { "id": 10, "prioridad": 2 },
    { "id": 12, "prioridad": 3 }
  ]
}
```

- `prioridad`: posición en la lista (índice del array + 1).
- Todos los IDs deben pertenecer al usuario autenticado.
- Se ejecuta en transacción para consistencia.

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Contactos reordenados",
  "data": [
    { "id": 15, "nombre_contacto": "Maria Gomez", "prioridad": 1, "..." : "..." },
    { "id": 10, "nombre_contacto": "Juan Lopez", "prioridad": 2, "..." : "..." },
    { "id": 12, "nombre_contacto": "Pedro Ruiz", "prioridad": 3, "..." : "..." }
  ]
}
```

**Errores:** 403 — algún ID no pertenece al usuario autenticado.

### PATCH /api/usuarios/contactos/{id}

**Body (todos los campos opcionales):**

```json
{
  "nombre_contacto": "Carlos Romero",
  "telefono_contacto": "+584121998877",
  "prioridad": 2
}
```

**Nota:** cambiar `telefono_contacto` resetea `estado_verificacion` a `PENDING` y `accepted_at` a `null`. Debes llamar `/reenviar-codigo` para re-emitir OTP.

### DELETE /api/usuarios/contactos/{id}

**Respuesta 200:**

```json
{ "success": true, "message": "Contacto eliminado", "data": null }
```

### POST /api/usuarios/contactos/{id}/verificar

**Body:**

```json
{ "codigo": "123456" }
```

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Contacto verificado",
  "data": {
    "id": 10,
    "id_usuario": 12123456,
    "nombre_contacto": "Juan Lopez",
    "telefono_contacto": "+584141234567",
    "prioridad": 1,
    "estado_verificacion": "VERIFIED",
    "accepted_at": "2026-05-13T14:22:10.000Z"
  }
}
```

**Errores:**

- `400` — el contacto ya está `VERIFIED`.
- `401` — código inválido, expirado o intentos agotados (máx 3).

**Throttling:** 10 solicitudes / 60 s por IP.

### POST /api/usuarios/contactos/{id}/reenviar-codigo

Re-emite el OTP invalidando el anterior. Respeta cooldown y límite de activos.

**Respuesta 200:**

```json
{ "success": true, "message": "Codigo de verificacion reenviado", "data": null }
```

**Errores:**

- `400` — cooldown activo, máximo de reenvíos alcanzado o contacto ya verificado.

**Throttling:** 5 solicitudes / 60 s por IP.

---

## Alertas de Incidentes

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/alertas` | Crear alerta de incidente |
| GET | `/api/alertas` | Listar alertas del usuario |
| GET | `/api/alertas/{id}` | Obtener alerta por ID |
| PATCH | `/api/alertas/{id}` | Actualizar alerta |
| DELETE | `/api/alertas/{id}` | Eliminar alerta |

Las alertas `es_proactiva: true` notifican vía WhatsApp (Evolution API) **únicamente a contactos en estado `VERIFIED`**.

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
      "id_usuario": 12123456,
      "latitud": "10.50234567",
      "longitud": "-66.91234567",
      "url_audio_contexto": "https://storage.jepo.com/audio/contexto-123.mp3",
      "fecha_hora": "2026-05-08T10:30:00.000Z",
      "es_proactiva": true
    },
    "contactosNotificar": [
      {
        "id": 10,
        "nombre_contacto": "Juan Lopez",
        "telefono_contacto": "+584141234567",
        "prioridad": 1,
        "estado_verificacion": "VERIFIED"
      }
    ],
    "notificaciones": null
  }
}
```

Los envíos a WhatsApp son asíncronos: `notificaciones` puede ser `null` en la respuesta inmediata; los resultados se loguean en el servidor.

### GET /api/alertas

**Respuesta 200:** arreglo de alertas ordenadas por `fecha_hora DESC`.

### PATCH /api/alertas/{id}

**Body (todos opcionales):**

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
{ "success": true, "message": "Alerta eliminada", "data": null }
```

---

## Usuarios

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/usuarios` | Crear usuario |
| GET | `/api/usuarios` | Listar usuarios |
| GET | `/api/usuarios/{id}` | Obtener usuario por ID |
| PATCH | `/api/usuarios/{id}` | Actualizar usuario |
| DELETE | `/api/usuarios/{id}` | Eliminar usuario |
| PATCH | `/api/usuarios/{id}/token-fcm` | Actualizar token FCM |

Reglas de unicidad al crear/actualizar: `cedula`, `email` y `telefono`.

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

**Body (todos opcionales):**

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

Al enviar `password` se actualiza `password_changed_at` en el servidor y **todos los JWT previos del usuario quedan invalidados**.

### PATCH /api/usuarios/{id}/token-fcm

**Body:**

```json
{ "token_fcm": "fcm_device_token_abc123456789" }
```

---

## Mapa / Grafo Familiar

| Método | Ruta | Descripción |
|--------|------|-------------|
| PATCH | `/api/usuarios/me/ubicacion` | Actualizar ubicación del usuario autenticado |
| GET | `/api/mapa/monitoreados` | Listar usuarios que me tienen como contacto verificado |

### PATCH /api/usuarios/me/ubicacion

**Body:**

```json
{ "latitud": 10.50234567, "longitud": -66.91234567 }
```

**Respuesta 200:** `{ "success": true, "message": "Ubicacion actualizada", "data": null }`

El frontend llama este endpoint cada 15 minutos desde el background service (`LocationReporter`).

### GET /api/mapa/monitoreados

**Respuesta 200:**

```json
{
  "success": true,
  "message": "Usuarios monitoreados obtenidos",
  "data": [
    {
      "id": 5,
      "nombre": "Maria",
      "apellido": "Perez",
      "telefono": "+584121112233",
      "ultima_latitud": 10.5,
      "ultima_longitud": -66.9,
      "fecha_ultima_ubicacion": "2026-05-13T14:22:10.000Z",
      "tiene_alerta_activa": true
    }
  ]
}
```

Devuelve únicamente usuarios que tienen al caller registrado como contacto **VERIFIED**.

---

## Formato de Respuesta Estándar

Todas las respuestas siguen esta estructura:

```json
{
  "success": true,
  "message": "Descripción del resultado",
  "data": { }
}
```

Errores (4xx/5xx) siguen la misma forma con `success: false` y pueden incluir `timestamp` y `path`:

```json
{
  "success": false,
  "message": "Credenciales invalidas",
  "data": null,
  "timestamp": "2026-05-13T13:36:34.326Z",
  "path": "/api/auth/login"
}
```

## Formato de Teléfono

Los teléfonos se almacenan en formato E.164 venezolano: `+58XXXXXXXXXX` (12 dígitos con prefijo de país). El frontend debe normalizar a E.164 antes de enviar.

## Throttling global

Throttler global a partir de `THROTTLE_LIMIT` / `THROTTLE_TTL` del `.env` (por defecto 60 req / 60 s por IP). Algunos endpoints sensibles tienen límites más estrictos (ver cada sección).

## Estados de Contacto de Emergencia

- `PENDING`: creado pero aún no validó el OTP.
- `VERIFIED`: el contacto confirmó vía OTP y recibirá alertas.
- `REJECTED`: reservado para futuro (opt-out explícito).

## DTOs Principales

- **RegisterDto / CreateUserDto**: `cedula`, `nombre`, `apellido`, `email`, `telefono`, `password`, `token_fcm`
- **LoginDto**: `email`, `password`
- **ForgotPasswordDto**: `email_or_phone`, `method` (`"email" | "whatsapp"`)
- **ResetPasswordDto**: `email_or_phone`, `otp` (6 dígitos), `new_password`
- **CreateEmergencyContactDto**: `nombre_contacto`, `telefono_contacto`, `prioridad?` (opcional, 1-5; si no se envía se auto-asigna al final)
- **UpdateEmergencyContactDto**: `nombre_contacto?`, `telefono_contacto?`, `prioridad?`
- **ReorderContactsDto**: `orden` (array de `{ id, prioridad }`)
- **VerifyEmergencyContactDto**: `codigo` (6 dígitos)
- **CreateIncidentAlertDto**: `latitud`, `longitud`, `url_audio_contexto`, `fecha_hora`, `es_proactiva`
- **UpdateIncidentAlertDto**: todos opcionales
- **UpdateUserDto**: todos opcionales (`password` dispara invalidación de JWT)
- **UpdateTokenDto**: `token_fcm`

## Notas para el frontend

- **Login expirado vs revocado**: el código `401` en rutas protegidas puede venir de token expirado o de `password_changed_at` posterior al `iat` del token. En ambos casos la acción es la misma: reenviar al login.
- **Forgot-password**: mostrar mensaje genérico al usuario independientemente de si existe la cuenta. Si el backend devuelve `500`, sugerir reintentar en unos segundos.
- **Verificación de contacto**: después de crear el contacto, la UI debe mostrar el estado (`PENDING`) y un CTA para ingresar el código. Proveer botón de "Reenviar código" con cooldown visual de 60 s.
- **Alertas**: si `contactosNotificar` viene vacío, avisar al usuario que no tiene contactos verificados (los PENDING no reciben la alerta).
- **Drag & Drop de contactos**: al soltar, enviar `PATCH /api/usuarios/contactos/reordenar` con el array `orden` donde `prioridad = index + 1`. La respuesta devuelve la lista completa ya reordenada para sincronizar el estado local. No es necesario enviar `prioridad` al crear un contacto nuevo; siempre cae al final de la lista automáticamente.
- **Crear contacto sin prioridad**: el frontend puede omitir `prioridad` en el body de `POST /api/usuarios/contactos`. El backend lo coloca al final. Tras crear, hacer un GET o usar la data del response para actualizar la lista local.
