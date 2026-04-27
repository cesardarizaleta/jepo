# API JEPO - Documentación Completa de Integración

**Proyecto:** Sistema de Asistencia Proactiva a Personas  
**Stack:** NestJS + PostgreSQL + TypeORM  
**Versión documento:** 1.0.0  
**Fecha:** 2026-04-26

## 1) Resumen ejecutivo

Este documento centraliza todas las rutas de la API con esquemas de request/response, ejemplos `curl`, reglas de autenticación y consideraciones técnicas para conectar aplicaciones web/móvil.

### Estado de robustez (evaluación rápida)

**Puntuación:** 6/10

**Fortalezas:**
- Validaciones con `class-validator` y `ValidationPipe` global.
- Manejo global uniforme de respuestas y errores JSON.
- Módulos separados por dominio (`auth`, `users`, `emergency-contacts`, `incident-alerts`).

**Riesgos principales:**
- Inconsistencia potencial entre `id` y `cedula` en relaciones de entidades.
- Endpoints de usuarios sin guard JWT (solo API key).
- Límite de 5 contactos y unicidad de teléfono resueltos en capa app (no constraint DB).

---

## 2) Base URL, docs y autenticación

### Base URL

- Desarrollo local típico: `http://localhost:3000`
- Prefijo global: `/api`

### Swagger / OpenAPI

- UI: `GET /api/docs`
- JSON OpenAPI: `GET /api/docs-json`

### Autenticación usada

La API usa **2 capas**:

1. **API Key obligatoria** para prácticamente todas las rutas:
   - Header por defecto: `x-api-key`
   - Valor: variable de entorno `API_KEY`

2. **JWT Bearer** para rutas protegidas (`/auth/me`, `/usuarios/contactos*`, `/alertas*`):
   - Header: `Authorization: Bearer <token>`

### Headers estándar

```http
Content-Type: application/json
x-api-key: {{API_KEY}}
Authorization: Bearer {{JWT}}   // solo en rutas protegidas
```

---

## 3) Formato de respuesta y errores

### Respuesta exitosa (interceptor global)

```json
{
  "success": true,
  "message": "Operacion exitosa",
  "data": {}
}
```

### Respuesta de error (filtro global)

```json
{
  "success": false,
  "message": "Error de validacion",
  "data": null,
  "errors": [
    "email must be an email"
  ],
  "timestamp": "2026-04-26T12:00:00.000Z",
  "path": "/api/auth/register"
}
```

---

## 4) Tabla rápida de endpoints

| Módulo | Método | Ruta | Auth requerida |
|---|---|---|---|
| Health | GET | `/api/health` | API Key |
| Auth | POST | `/api/auth/register` | API Key |
| Auth | POST | `/api/auth/login` | API Key |
| Auth | GET | `/api/auth/me` | API Key + JWT |
| Usuarios | POST | `/api/usuarios` | API Key |
| Usuarios | GET | `/api/usuarios` | API Key |
| Usuarios | GET | `/api/usuarios/:id` | API Key |
| Usuarios | PATCH | `/api/usuarios/:id` | API Key |
| Usuarios | PATCH | `/api/usuarios/:id/token-fcm` | API Key |
| Usuarios | DELETE | `/api/usuarios/:id` | API Key |
| Contactos | POST | `/api/usuarios/contactos` | API Key + JWT |
| Contactos | GET | `/api/usuarios/contactos` | API Key + JWT |
| Contactos | GET | `/api/usuarios/contactos/:id` | API Key + JWT |
| Contactos | PATCH | `/api/usuarios/contactos/:id` | API Key + JWT |
| Contactos | DELETE | `/api/usuarios/contactos/:id` | API Key + JWT |
| Alertas | POST | `/api/alertas` | API Key + JWT |
| Alertas | GET | `/api/alertas` | API Key + JWT |
| Alertas | GET | `/api/alertas/:id` | API Key + JWT |
| Alertas | PATCH | `/api/alertas/:id` | API Key + JWT |
| Alertas | DELETE | `/api/alertas/:id` | API Key + JWT |

---

## 5) Esquemas de entrada (DTO)

### 5.1 `CreateUserDto` / `RegisterDto`

```json
{
  "cedula": "V-12345678",
  "nombre": "Cesar",
  "apellido": "Perez",
  "email": "cesar@correo.com",
  "telefono": "+56912345678",
  "password": "Passw0rd!Segura",
  "token_fcm": "fcm_device_token_abc123456789"
}
```

Reglas relevantes:
- `nombre`, `apellido`: 2-80.
- `email`: válido, 5-120.
- `telefono`: 7-30.
- `password`: 8-72, exige mayúscula/minúscula/número/especial.
- `token_fcm`: opcional, 10-255.
- `cedula`: validación personalizada (`IsCedula`).

### 5.2 `LoginDto`

```json
{
  "email": "cesar@correo.com",
  "password": "Passw0rd!Segura"
}
```

### 5.3 `CreateEmergencyContactDto`

```json
{
  "nombre_contacto": "Maria Perez",
  "telefono_contacto": "+56911111111",
  "prioridad": 1
}
```

Reglas:
- `prioridad`: entero entre 1 y 5.
- Máximo 5 contactos por usuario.

### 5.4 `CreateIncidentAlertDto`

```json
{
  "latitud": -33.43719212,
  "longitud": -70.65058345,
  "url_audio_contexto": "https://storage.ejemplo.com/audio/contexto-123.mp3",
  "fecha_hora": "2026-04-26T12:30:00.000Z",
  "es_proactiva": true
}
```

Reglas:
- `latitud`, `longitud`: máximo 8 decimales.
- `url_audio_contexto`: URL válida con protocolo.
- `es_proactiva`: booleano obligatorio.

---

## 6) Endpoints detallados (request/response)

## 6.1 Health

### GET `/api/health`

**Headers:**
- `x-api-key`

**cURL:**

```bash
curl -X GET "http://localhost:3000/api/health" \
  -H "x-api-key: TU_API_KEY"
```

**Response 200:**

```json
{
  "success": true,
  "message": "Operacion exitosa",
  "data": {
    "status": "ok",
    "service": "api-jepo",
    "timestamp": "2026-04-26T12:00:00.000Z"
  }
}
```

---

## 6.2 Auth

### POST `/api/auth/register`

**Headers:**
- `x-api-key`

**Body:** `RegisterDto`

**cURL:**

```bash
curl -X POST "http://localhost:3000/api/auth/register" \
  -H "Content-Type: application/json" \
  -H "x-api-key: TU_API_KEY" \
  -d '{
    "cedula": "V-12345678",
    "nombre": "Cesar",
    "apellido": "Perez",
    "email": "cesar@correo.com",
    "telefono": "+56912345678",
    "password": "Passw0rd!Segura"
  }'
```

**Response 200:**

```json
{
  "success": true,
  "message": "Registro exitoso",
  "data": {
    "access_token": "<jwt>",
    "token_type": "Bearer",
    "expires_in": "15m",
    "user": {
      "id": 1,
      "nombre": "Cesar",
      "apellido": "Perez",
      "email": "cesar@correo.com",
      "telefono": "+56912345678",
      "token_fcm": null
    }
  }
}
```

**Errores comunes:**
- `400` validación.
- `409` email ya registrado.

### POST `/api/auth/login`

**Headers:**
- `x-api-key`

**Body:** `LoginDto`

**cURL:**

```bash
curl -X POST "http://localhost:3000/api/auth/login" \
  -H "Content-Type: application/json" \
  -H "x-api-key: TU_API_KEY" \
  -d '{
    "email": "cesar@correo.com",
    "password": "Passw0rd!Segura"
  }'
```

**Response 200:**

```json
{
  "success": true,
  "message": "Login exitoso",
  "data": {
    "access_token": "<jwt>",
    "token_type": "Bearer",
    "expires_in": "15m",
    "user": {
      "id": 1,
      "nombre": "Cesar",
      "apellido": "Perez",
      "email": "cesar@correo.com",
      "telefono": "+56912345678",
      "token_fcm": null
    }
  }
}
```

**Errores comunes:**
- `401` credenciales inválidas.

### GET `/api/auth/me`

**Headers:**
- `x-api-key`
- `Authorization: Bearer <jwt>`

**cURL:**

```bash
curl -X GET "http://localhost:3000/api/auth/me" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT"
```

**Response 200:**

```json
{
  "success": true,
  "message": "Sesion valida",
  "data": {
    "id": 1,
    "nombre": "Cesar",
    "apellido": "Perez",
    "email": "cesar@correo.com",
    "telefono": "+56912345678",
    "token_fcm": "fcm_device_token_abc123456789"
  }
}
```

---

## 6.3 Usuarios

### POST `/api/usuarios`

**Headers:** `x-api-key`  
**Body:** `CreateUserDto`

```bash
curl -X POST "http://localhost:3000/api/usuarios" \
  -H "Content-Type: application/json" \
  -H "x-api-key: TU_API_KEY" \
  -d '{
    "cedula": "V-12345679",
    "nombre": "Ana",
    "apellido": "Rojas",
    "email": "ana@correo.com",
    "telefono": "+56922222222",
    "password": "Passw0rd!Segura"
  }'
```

**Response 200:** `Usuario creado` en `data`.

### GET `/api/usuarios`

```bash
curl -X GET "http://localhost:3000/api/usuarios" \
  -H "x-api-key: TU_API_KEY"
```

**Response 200:** lista de usuarios en `data`.

### GET `/api/usuarios/:id`

```bash
curl -X GET "http://localhost:3000/api/usuarios/1" \
  -H "x-api-key: TU_API_KEY"
```

**Response 200:** usuario por ID.

### PATCH `/api/usuarios/:id`

```bash
curl -X PATCH "http://localhost:3000/api/usuarios/1" \
  -H "Content-Type: application/json" \
  -H "x-api-key: TU_API_KEY" \
  -d '{
    "nombre": "Ana Maria",
    "telefono": "+56933333333"
  }'
```

**Response 200:** usuario actualizado.

### PATCH `/api/usuarios/:id/token-fcm`

```bash
curl -X PATCH "http://localhost:3000/api/usuarios/1/token-fcm" \
  -H "Content-Type: application/json" \
  -H "x-api-key: TU_API_KEY" \
  -d '{
    "token_fcm": "fcm_device_token_abc123456789"
  }'
```

**Response 200:** token actualizado.

### DELETE `/api/usuarios/:id`

```bash
curl -X DELETE "http://localhost:3000/api/usuarios/1" \
  -H "x-api-key: TU_API_KEY"
```

**Response 200:**

```json
{
  "success": true,
  "message": "Usuario eliminado",
  "data": null
}
```

---

## 6.4 Contactos de emergencia

> Todas estas rutas requieren API key + JWT.

### POST `/api/usuarios/contactos`

```bash
curl -X POST "http://localhost:3000/api/usuarios/contactos" \
  -H "Content-Type: application/json" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT" \
  -d '{
    "nombre_contacto": "Carlos Soto",
    "telefono_contacto": "+56944444444",
    "prioridad": 1
  }'
```

**Response 200:** contacto creado.

**Errores comunes:**
- `400`: usuario ya tiene 5 contactos.
- `409`: teléfono ya existe para ese usuario.

### GET `/api/usuarios/contactos`

```bash
curl -X GET "http://localhost:3000/api/usuarios/contactos" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT"
```

**Response 200:** lista ordenada por prioridad ascendente.

### GET `/api/usuarios/contactos/:id`

```bash
curl -X GET "http://localhost:3000/api/usuarios/contactos/1" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT"
```

### PATCH `/api/usuarios/contactos/:id`

```bash
curl -X PATCH "http://localhost:3000/api/usuarios/contactos/1" \
  -H "Content-Type: application/json" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT" \
  -d '{
    "prioridad": 2
  }'
```

### DELETE `/api/usuarios/contactos/:id`

```bash
curl -X DELETE "http://localhost:3000/api/usuarios/contactos/1" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT"
```

---

## 6.5 Alertas de incidentes

> Todas estas rutas requieren API key + JWT.

### POST `/api/alertas`

**Body:** `CreateIncidentAlertDto`

```bash
curl -X POST "http://localhost:3000/api/alertas" \
  -H "Content-Type: application/json" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT" \
  -d '{
    "latitud": -33.43719212,
    "longitud": -70.65058345,
    "url_audio_contexto": "https://storage.ejemplo.com/audio/contexto-123.mp3",
    "fecha_hora": "2026-04-26T12:30:00.000Z",
    "es_proactiva": true
  }'
```

**Response 200 (es_proactiva = true):**

```json
{
  "success": true,
  "message": "Alerta creada",
  "data": {
    "alerta": {
      "id": 10,
      "id_usuario": 1,
      "latitud": "-33.43719212",
      "longitud": "-70.65058345",
      "url_audio_contexto": "https://storage.ejemplo.com/audio/contexto-123.mp3",
      "fecha_hora": "2026-04-26T12:30:00.000Z",
      "es_proactiva": true
    },
    "contactosNotificar": [
      {
        "id": 1,
        "id_usuario": 1,
        "nombre_contacto": "Carlos Soto",
        "telefono_contacto": "+56944444444",
        "prioridad": 1
      }
    ],
    "notificaciones": null
  }
}
```

**Response 200 (es_proactiva = false):**
- `contactosNotificar` retorna arreglo vacío.

**Errores comunes:**
- `400`: coordenadas/URL inválidas.
- `404`: usuario no encontrado.

### GET `/api/alertas`

```bash
curl -X GET "http://localhost:3000/api/alertas" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT"
```

**Response 200:** lista de alertas del usuario autenticado.

### GET `/api/alertas/:id`

```bash
curl -X GET "http://localhost:3000/api/alertas/10" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT"
```

### PATCH `/api/alertas/:id`

```bash
curl -X PATCH "http://localhost:3000/api/alertas/10" \
  -H "Content-Type: application/json" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT" \
  -d '{
    "es_proactiva": false,
    "latitud": -33.44000000,
    "longitud": -70.65000000
  }'
```

### DELETE `/api/alertas/:id`

```bash
curl -X DELETE "http://localhost:3000/api/alertas/10" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT"
```

---

## 7) Entidades principales (modelo de datos)

## 7.1 `usuarios`

Campos clave:
- `id`
- `cedula`
- `nombre`
- `apellido`
- `email`
- `telefono`
- `password_hash` (oculto en select normal)
- `token_fcm`

## 7.2 `contactos_emergencia`

Campos clave:
- `id`
- `id_usuario`
- `nombre_contacto`
- `telefono_contacto`
- `prioridad`

## 7.3 `alertas_incidentes`

Campos clave:
- `id`
- `id_usuario`
- `latitud` (decimal string en salida TypeORM)
- `longitud` (decimal string en salida TypeORM)
- `url_audio_contexto`
- `fecha_hora`
- `es_proactiva`

---

## 8) Flujo crítico: `POST /api/alertas`

1. Se valida JWT + API key.
2. Se valida DTO (lat/long máx 8 decimales, URL, boolean).
3. Se persiste alerta con lat/long a 8 decimales (`toFixed(8)`).
4. Si `es_proactiva = true`:
   - se consultan contactos del usuario,
   - se dispara notificación asíncrona en background,
   - se retorna `contactosNotificar` en el response.

---

## 9) Variables de entorno

```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=api_jepo
DB_SCHEMA=asistencia_proactiva
DB_SYNC=true
THROTTLE_TTL=60000
THROTTLE_LIMIT=60

API_KEY=tu_api_key
API_KEY_HEADER_NAME=x-api-key

JWT_SECRET=super_secreto
JWT_EXPIRES_IN=15m

EVOLUTION_API_BASE_URL=https://tu-evolution
EVOLUTION_API_KEY=tu_key
EVOLUTION_INSTANCE=tu_instancia
EVOLUTION_CHANNEL=whatsapp
```

---

## 10) Guía de conexión para cliente (web/móvil)

1. Configura `baseUrl` en cliente con `/api`.
2. Envía siempre `x-api-key`.
3. Usa `POST /api/auth/login` o `register` para obtener JWT.
4. Guarda `access_token` y envíalo en `Authorization` para rutas protegidas.
5. En flujos de alerta:
   - usa coordenadas con hasta 8 decimales,
   - si quieres activar protocolo automático, envía `es_proactiva=true`.
6. Maneja errores con `success=false` y usa `errors[]` para validación de formulario.

---

## 11) Postman

Archivos:
- Colección: `docs/Jepo.postman_collection.json`
- Environment: `docs/Jepo.postman_environment.json`

Flujo recomendado:
1. `Health`
2. `Auth > Register/Login`
3. Confirmar variable `jwt`
4. `Contactos de Emergencia`
5. `Alertas de Incidentes`

---

## 12) Recomendaciones de robustez (priorizadas)

1. Unificar relaciones por `id` (evitar dependencia `cedula`/backfill).
2. Añadir constraints DB para unicidad de teléfono por usuario.
3. Endurecer autorización en módulo usuarios (JWT + ownership/roles).
4. Añadir pruebas unitarias/e2e para alertas proactivas y regla de 5 contactos.
5. Normalizar teléfonos antes de comparar unicidad.
6. Persistir auditoría de resultados de notificación.

---

## 13) Quick Start de consumo

```bash
# 1) Health
curl -X GET "http://localhost:3000/api/health" -H "x-api-key: TU_API_KEY"

# 2) Login
curl -X POST "http://localhost:3000/api/auth/login" \
  -H "Content-Type: application/json" \
  -H "x-api-key: TU_API_KEY" \
  -d '{"email":"cesar@correo.com","password":"Passw0rd!Segura"}'

# 3) Usar token en ruta protegida
curl -X GET "http://localhost:3000/api/alertas" \
  -H "x-api-key: TU_API_KEY" \
  -H "Authorization: Bearer TU_JWT"
```

---

## 14) Referencias internas

- Swagger UI: `/api/docs`
- OpenAPI JSON: `/api/docs-json`
- Colección Postman: `docs/Jepo.postman_collection.json`
- Esta guía: `docs/API_FULL.md`
