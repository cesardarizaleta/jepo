# Usuarios — API

Documentación de endpoints para gestionar usuarios.

Base path: `/api/usuarios`

## Autenticacion por API Key (obligatoria)

Todas las peticiones requieren API key en header.

- Header por defecto: `x-api-key`
- Valor: `API_KEY` definido en `.env`
- Header configurable por env: `API_KEY_HEADER_NAME`

Ejemplo:

```http
x-api-key: change_me_api_key
```

Archivos relevantes:
- [Controlador](src/users/users.controller.ts)
- [Servicio](src/users/users.service.ts)
- [DTOs](src/users/dto)

---

## Endpoints

### 1) Crear usuario
- Método: `POST /api/usuarios`
- Descripción: Crea un nuevo usuario.
- Body (JSON):

```json
{
  "nombre": "Cesar",
  "apellido": "Lopez",
  "email": "cesar@example.com",
  "telefono": "+56999999999",
  "password": "Passw0rd!Segura",
  "token_fcm": null
}
```

- Validaciones principales:
  - `nombre`, `apellido`: strings 2–80 caracteres
  - `email`: email válido
  - `telefono`: string 7–30 caracteres
  - `password`: string 8–72 caracteres, con mayúscula, minúscula, número y carácter especial
  - `token_fcm`: opcional

- Respuesta (ejemplo):

```json
{
  "success": true,
  "message": "Usuario creado",
  "data": {
    "id": 1,
    "nombre": "Cesar",
    "apellido": "Lopez",
    "email": "cesar@example.com",
    "telefono": "+56999999999",
    "token_fcm": null
  }
}
```

---

### 2) Listar usuarios
- Método: `GET /api/usuarios`
- Respuesta: lista de usuarios.

### 3) Obtener usuario
- Método: `GET /api/usuarios/:id`
- Parámetros: `id` (path)

### 4) Actualizar usuario
- Método: `PATCH /api/usuarios/:id`
- Body: campos opcionales del DTO `UpdateUserDto` (ver DTOs)
- Nota: si envías `password`, se vuelve a hashear antes de persistir.

### 5) Actualizar token FCM
- Método: `PATCH /api/usuarios/:id/token-fcm`
- Body (JSON):

```json
{ "token_fcm": "AAAA..." }
```

Respuesta (ejemplo):

```json
{
  "success": true,
  "message": "Token FCM actualizado",
  "data": { /* usuario actualizado */ }
}
```

### 6) Eliminar usuario
- Método: `DELETE /api/usuarios/:id`
- Respuesta: `{ success: true, message: 'Usuario eliminado', data: null }`

---

## Notas para el frontend
- Todas las rutas están bajo el prefijo global `/api` (p. ej. `POST /api/usuarios`).
- Errores y validaciones devuelven formato estandarizado por el `ResponseInterceptor` y el `HttpExceptionFilter`.
- Usa los campos del DTO para validar en el cliente antes de llamar la API.
- Si falta o es incorrecta la API key, la API responde `401 Unauthorized`.

---

Ejecuta los ejemplos desde `users.http` (misma carpeta) para probar.
