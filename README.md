# <div align="center">JEPO</div>

<div align="center">

**Sistema de Asistencia Proactiva para personas en situación de riesgo**

Una plataforma full-stack orientada a detección temprana, geolocalización continua y gestión automática de alertas con contexto operativo.

<br />

[![Versión](https://img.shields.io/badge/version-0.1.0-0f172a?style=for-the-badge)](https://github.com/)
[![Licencia](https://img.shields.io/badge/licencia-no%20declarada-334155?style=for-the-badge)](https://github.com/)
[![Flutter](https://img.shields.io/badge/frontend-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/lenguaje-Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Backend](https://img.shields.io/badge/backend-NestJS%20%2B%20TypeORM-E0234E?style=for-the-badge&logo=nestjs&logoColor=white)](https://nestjs.com/)
[![Base de datos](https://img.shields.io/badge/base%20de%20datos-PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)

</div>

---

## ✨ Características principales

### Frontend móvil

- **Monitoreo en background** con servicios persistentes para detectar eventos de riesgo aun con la pantalla bloqueada.
- **Geolocalización continua** con soporte para seguimiento, cercanía a zonas seguras y manejo de contexto espacial.
- **Reconocimiento de actividad** con sensores inerciales para identificar caídas, impactos, inactividad prolongada y patrones anómalos.
- **Flujo de pre-alerta** que introduce confirmación antes de disparar notificaciones críticas, reduciendo falsos positivos.
- **Gestión de contactos de emergencia** para registrar, priorizar y mantener destinatarios autorizados.
- **Experiencia visual moderna** con navegación móvil, pantallas dedicadas y componentes reutilizables.

### Backend y orquestación

- **API REST** para autenticación, gestión de usuarios, contactos y alertas.
- **Protección por API Key y JWT** para separar acceso de aplicación y sesión de usuario.
- **Fan-out de notificaciones** para orquestar el envío a contactos desde el backend.
- **Persistencia transaccional** en PostgreSQL con modelo preparado para usuarios, contactos y alertas.
- **Documentación de endpoints** alineada con los DTOs y reglas de validación del servicio.

---

## 🏗️ Arquitectura y tecnologías

| Capa | Stack | Rol |
|---|---|---|
| Frontend móvil | Flutter, Dart, Riverpod, Flutter Animate, Google Fonts | Interfaz principal, captura de sensores, geolocalización y UX de alerta |
| Sensores y contexto | `sensors_plus`, `geolocator`, `flutter_background_service`, `flutter_local_notifications` | Detección de actividad, tracking continuo y notificaciones intrusivas |
| Seguridad | `flutter_secure_storage`, `local_auth`, `permission_handler` | Resguardo de credenciales, autenticación biométrica y permisos |
| Mapa y ubicación | `flutter_map`, `latlong2` | Visualización y lógica geoespacial |
| Backend | NestJS, TypeORM | Exposición de la API, validaciones y lógica de dominio |
| Base de datos | PostgreSQL | Persistencia de usuarios, contactos y alertas |
| DevOps / despliegue | Docker, Dokploy, Nixpacks | Construcción y despliegue del stack en entornos gestionados |

### Componentes clave del frontend

| Módulo | Archivo principal | Función |
|---|---|---|
| Servicio de background | [lib/services/background_service.dart](lib/services/background_service.dart) | Ejecuta la vigilancia pasiva y dispara eventos de riesgo |
| Pre-alerta | [lib/services/pre_alert_service.dart](lib/services/pre_alert_service.dart) | Orquesta la confirmación antes del envío de alerta |
| Confirmación visual | [lib/screens/pre_alert_confirmation_screen.dart](lib/screens/pre_alert_confirmation_screen.dart) | Pantalla full-screen para validar o dejar expirar la alerta |
| Cola de alertas | [lib/services/alert_queue_service.dart](lib/services/alert_queue_service.dart) | Encapsula el gate de envío y encolado |
| Contactos de emergencia | [lib/services/emergency_contacts_service.dart](lib/services/emergency_contacts_service.dart) | CRUD de contactos desde la app |

---

## 🔌 Documentación de la API

**Base URL:** `http://localhost:3000/api`  
**Prefijo global:** `/api`  
**Headers estándar:**

```http
Content-Type: application/json
x-api-key: {{API_KEY}}
Authorization: Bearer {{JWT}}
```

> Todas las rutas protegidas requieren `x-api-key`. Las rutas de sesión y dominio de usuario además requieren `Authorization: Bearer <token>`.

### Resumen de endpoints

| Módulo | Método | Ruta | Descripción |
|---|---|---|---|
| Salud | GET | `/api/health` | Verifica estado de la API y la base de datos |
| Auth | POST | `/api/auth/register` | Registra un usuario y emite JWT |
| Auth | POST | `/api/auth/login` | Autentica un usuario existente |
| Auth | GET | `/api/auth/me` | Devuelve la sesión actual |
| Usuarios | POST | `/api/usuarios` | Crea un usuario |
| Usuarios | GET | `/api/usuarios` | Lista usuarios |
| Usuarios | GET | `/api/usuarios/:id` | Obtiene un usuario por ID |
| Usuarios | PATCH | `/api/usuarios/:id` | Actualiza campos del usuario |
| Usuarios | PATCH | `/api/usuarios/:id/token-fcm` | Actualiza el token FCM |
| Usuarios | DELETE | `/api/usuarios/:id` | Elimina un usuario |
| Contactos | POST | `/api/usuarios/contactos` | Crea un contacto de emergencia |
| Contactos | GET | `/api/usuarios/contactos` | Lista los contactos del usuario |
| Contactos | GET | `/api/usuarios/contactos/:id` | Obtiene un contacto por ID |
| Contactos | PATCH | `/api/usuarios/contactos/:id` | Actualiza un contacto |
| Contactos | DELETE | `/api/usuarios/contactos/:id` | Elimina un contacto |
| Alertas | POST | `/api/alertas` | Crea una alerta de incidente |
| Alertas | GET | `/api/alertas` | Lista alertas del usuario |
| Alertas | GET | `/api/alertas/:id` | Obtiene una alerta por ID |
| Alertas | PATCH | `/api/alertas/:id` | Actualiza una alerta |
| Alertas | DELETE | `/api/alertas/:id` | Elimina una alerta |

### 1) Salud del sistema

#### `GET /api/health`

**Descripción:** valida que el servicio y la base de datos estén operativos.

**Request**

```json
{}
```

**Response**

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

### 2) Autenticación

#### `POST /api/auth/register`

**Descripción:** registra una cuenta nueva y devuelve un `access_token`.

**Payload**

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

**Response**

```json
{
 "success": true,
 "message": "Registro exitoso",
 "data": {
  "access_token": "eyJhbG...",
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

#### `POST /api/auth/login`

**Descripción:** autentica un usuario existente y devuelve sesión JWT.

**Payload**

```json
{
 "email": "cesar@correo.com",
 "password": "Passw0rd!Segura"
}
```

**Response**

```json
{
 "success": true,
 "message": "Login exitoso",
 "data": {
  "access_token": "eyJhbG...",
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

#### `GET /api/auth/me`

**Descripción:** devuelve el usuario autenticado a partir del JWT.

**Payload**

```json
{}
```

**Response**

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

### 3) Usuarios

#### `POST /api/usuarios`

**Descripción:** crea un usuario desde la capa administrativa o de integración.

**Payload**

```json
{
 "cedula": "V-12345679",
 "nombre": "Ana",
 "apellido": "Rojas",
 "email": "ana@correo.com",
 "telefono": "+56922222222",
 "password": "Passw0rd!Segura"
}
```

**Response**

```json
{
 "success": true,
 "message": "Usuario creado",
 "data": {
  "id": 2,
  "nombre": "Ana",
  "apellido": "Rojas",
  "email": "ana@correo.com"
 }
}
```

#### `GET /api/usuarios`

**Descripción:** lista usuarios registrados.

**Payload**

```json
{}
```

**Response**

```json
{
 "success": true,
 "message": "Operacion exitosa",
 "data": [
  {
   "id": 1,
   "nombre": "Cesar",
   "apellido": "Perez",
   "email": "cesar@correo.com"
  }
 ]
}
```

#### `GET /api/usuarios/:id`

**Descripción:** obtiene un usuario por identificador.

**Payload**

```json
{}
```

**Response**

```json
{
 "success": true,
 "message": "Operacion exitosa",
 "data": {
  "id": 1,
  "nombre": "Cesar",
  "apellido": "Perez",
  "email": "cesar@correo.com"
 }
}
```

#### `PATCH /api/usuarios/:id`

**Descripción:** actualiza campos editables del usuario.

**Payload**

```json
{
 "nombre": "Ana Maria",
 "telefono": "+56933333333"
}
```

**Response**

```json
{
 "success": true,
 "message": "Usuario actualizado",
 "data": {
  "id": 2,
  "nombre": "Ana Maria",
  "telefono": "+56933333333"
 }
}
```

#### `PATCH /api/usuarios/:id/token-fcm`

**Descripción:** actualiza el token de notificaciones push del dispositivo.

**Payload**

```json
{
 "token_fcm": "fcm_device_token_abc123456789"
}
```

**Response**

```json
{
 "success": true,
 "message": "Token actualizado",
 "data": {
  "id": 1,
  "token_fcm": "fcm_device_token_abc123456789"
 }
}
```

#### `DELETE /api/usuarios/:id`

**Descripción:** elimina un usuario.

**Payload**

```json
{}
```

**Response**

```json
{
 "success": true,
 "message": "Usuario eliminado",
 "data": null
}
```

### 4) Contactos de emergencia

#### `POST /api/usuarios/contactos`

**Descripción:** crea un contacto de emergencia del usuario autenticado.

**Payload**

```json
{
 "nombre_contacto": "Maria Perez",
 "telefono_contacto": "+56911111111",
 "prioridad": 1
}
```

**Response**

```json
{
 "success": true,
 "message": "Contacto creado",
 "data": {
  "id": 1,
  "nombre_contacto": "Maria Perez",
  "telefono_contacto": "+56911111111",
  "prioridad": 1
 }
}
```

#### `GET /api/usuarios/contactos`

**Descripción:** lista los contactos del usuario autenticado, ordenados por prioridad.

**Payload**

```json
{}
```

**Response**

```json
{
 "success": true,
 "message": "Operacion exitosa",
 "data": [
  {
   "id": 1,
   "nombre_contacto": "Maria Perez",
   "telefono_contacto": "+56911111111",
   "prioridad": 1
  }
 ]
}
```

#### `GET /api/usuarios/contactos/:id`

**Descripción:** obtiene un contacto específico por ID.

**Payload**

```json
{}
```

**Response**

```json
{
 "success": true,
 "message": "Operacion exitosa",
 "data": {
  "id": 1,
  "nombre_contacto": "Maria Perez",
  "telefono_contacto": "+56911111111",
  "prioridad": 1
 }
}
```

#### `PATCH /api/usuarios/contactos/:id`

**Descripción:** actualiza un contacto de emergencia.

**Payload**

```json
{
 "prioridad": 2
}
```

**Response**

```json
{
 "success": true,
 "message": "Contacto actualizado",
 "data": {
  "id": 1,
  "prioridad": 2
 }
}
```

#### `DELETE /api/usuarios/contactos/:id`

**Descripción:** elimina un contacto del usuario autenticado.

**Payload**

```json
{}
```

**Response**

```json
{
 "success": true,
 "message": "Contacto eliminado",
 "data": null
}
```

### 5) Alertas de incidentes

#### `POST /api/alertas`

**Descripción:** crea una alerta; si `es_proactiva = true`, el backend activa la notificación a contactos.

**Payload**

```json
{
 "latitud": -33.43719212,
 "longitud": -70.65058345,
 "url_audio_contexto": "https://storage.ejemplo.com/audio/contexto-123.mp3",
 "fecha_hora": "2026-04-26T12:30:00.000Z",
 "es_proactiva": true
}
```

**Response**

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

#### `GET /api/alertas`

**Descripción:** lista las alertas del usuario autenticado.

**Payload**

```json
{}
```

**Response**

```json
{
 "success": true,
 "message": "Operacion exitosa",
 "data": [
  {
   "id": 10,
   "latitud": "-33.43719212",
   "longitud": "-70.65058345",
   "es_proactiva": true
  }
 ]
}
```

#### `GET /api/alertas/:id`

**Descripción:** obtiene una alerta específica.

**Payload**

```json
{}
```

**Response**

```json
{
 "success": true,
 "message": "Operacion exitosa",
 "data": {
  "id": 10,
  "latitud": "-33.43719212",
  "longitud": "-70.65058345",
  "es_proactiva": true
 }
}
```

#### `PATCH /api/alertas/:id`

**Descripción:** actualiza una alerta existente.

**Payload**

```json
{
 "es_proactiva": false,
 "latitud": -33.44,
 "longitud": -70.65
}
```

**Response**

```json
{
 "success": true,
 "message": "Alerta actualizada",
 "data": {
  "id": 10,
  "es_proactiva": false
 }
}
```

#### `DELETE /api/alertas/:id`

**Descripción:** elimina una alerta.

**Payload**

```json
{}
```

**Response**

```json
{
 "success": true,
 "message": "Alerta eliminada",
 "data": null
}
```

### Reglas relevantes de la API

- `telefono_contacto` debe ser numérico y único por usuario.
- El usuario autenticado se resuelve desde el JWT; no envíes `id_usuario` en el payload.
- Maneja respuestas `400`, `401`, `404` y `409` como estados de flujo normales.
- Usa la colección y la documentación en [docs/documentation.md](docs/documentation.md) para contrastar los contratos.

---

## 🚀 Guía de inicio rápido

### Requisitos previos

- Flutter SDK 3.x
- Android SDK y JDK
- Node.js 18+ para el backend de referencia
- pnpm o npm para el stack web/API
- Docker Desktop si vas a levantar el entorno con contenedores

### Instalación local del frontend

```bash
git clone <URL_DEL_REPOSITORIO>
cd jepo
flutter pub get
```

### Variables de entorno del frontend

Archivo de ejemplo: [.env.example](.env.example)

```env
API_KEY=change_me_api_key
API_KEY_HEADER_NAME=x-api-key
BASE_URL=https://api-jepo.irissoftware.lat
```

### Variables de entorno del backend

```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=api_jepo
API_KEY=tu_api_key
API_KEY_HEADER_NAME=x-api-key
JWT_SECRET=super_secreto
JWT_EXPIRES_IN=15m
EVOLUTION_API_BASE_URL=https://tu-evolution
EVOLUTION_API_KEY=tu_key
EVOLUTION_INSTANCE=tu_instancia
EVOLUTION_CHANNEL=whatsapp
```

### Levantar desarrollo

```bash
flutter run -d <device_id>
```

### Verificación rápida

```bash
flutter analyze
flutter test
flutter build apk --release
```

---

## 🐳 Despliegue y Docker

Este proyecto está preparado para un despliegue separado por capas:

- **Frontend móvil:** compilación Flutter para Android/iOS.
- **Backend API:** servicio NestJS expuesto detrás de una URL pública.
- **Base de datos:** PostgreSQL persistente.

### Levantamiento con Docker

Si encapsulas la API y la base de datos en contenedores, el flujo estándar es:

```bash
docker build -t jepo-api <RUTA_O_REPOSITORIO_DEL_BACKEND>
docker run -p 3000:3000 --env-file .env jepo-api
```

Para el stack completo, usa un `docker-compose.yml` con al menos:

- API NestJS
- PostgreSQL
- variables de entorno compartidas
- volumen persistente para la base de datos

### Producción

- **Dokploy:** encaja bien para desplegar la API y la base de datos como servicios gestionados.
- **Nixpacks:** útil si tu backend se construye desde un repositorio con detección automática de runtime.
- **Frontend móvil:** se distribuye como artefacto nativo, no como servicio web.

---

## 📂 Estructura del proyecto

```text
jepo/
├── lib/                          # Frontend Flutter
│   ├── main.dart
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── assets/                       # Recursos gráficos y archivos estáticos
├── docs/                         # Documentación de API, flujos y pruebas
├── android/                      # Proyecto Android nativo generado por Flutter
├── ios/                          # Proyecto iOS nativo generado por Flutter
├── web/                          # Configuración web de soporte
├── linux/                        # Target desktop Linux
├── macos/                        # Target desktop macOS
├── windows/                      # Target desktop Windows
├── test/                         # Pruebas unitarias y de servicios
├── backend.md                    # Especificación/guía del backend
├── .env.example                  # Variables de entorno del frontend
└── README.md
```

---

## 📎 Referencias útiles

- [Documentación de API](docs/documentation.md)
- [Guía de contactos de emergencia](docs/emergency-contacts/emergency-contacts.md)
- [Guía de alertas](docs/alertas/alertas.md)
- [Instrucciones del proyecto](.github/copilot-instructions.md)

## Nota final

Jepo está diseñado bajo una lógica de **asistencia proactiva**: detectar, contextualizar y actuar antes de que el usuario tenga que pedir ayuda. La app móvil ejecuta la capa de percepción y experiencia; la API centraliza identidad, contactos y alertas.
