# Autenticacion — API

Documentación de endpoints para registro e inicio de sesión.

Base path: `/api/auth`

## Flujo de seguridad

- Capa 1 (aplicacion): `x-api-key` obligatoria en todos los endpoints.
- Capa 2 (usuario): JWT obligatorio para endpoints protegidos.

## Endpoints de autenticacion (sin JWT)

Aunque son públicos respecto al JWT, requieren API key.

### 1) Registro
- Método: `POST /api/auth/register`
- Headers:
  - `x-api-key: <API_KEY>`
- Descripción: Crea un usuario y retorna JWT de acceso.
- Body (JSON):

```json
{
  "nombre": "Cesar",
  "apellido": "Lopez",
  "email": "cesar@example.com",
  "telefono": "+56999999999",
  "password": "Passw0rd!Segura",
  "token_fcm": "optional_device_token"
}
```

- Respuesta (ejemplo):

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
      "apellido": "Lopez",
      "email": "cesar@example.com",
      "telefono": "+56999999999",
      "token_fcm": "optional_device_token"
    }
  }
}
```

### 2) Login
- Método: `POST /api/auth/login`
- Headers:
  - `x-api-key: <API_KEY>`
- Descripción: Valida credenciales y retorna JWT de acceso.
- Body (JSON):

```json
{
  "email": "cesar@example.com",
  "password": "Passw0rd!Segura"
}
```

## Endpoint protegido

### 3) Perfil de sesión
- Método: `GET /api/auth/me`
- Headers:
  - `x-api-key: <API_KEY>`
  - `Authorization: Bearer <jwt>`
- Descripción: retorna el usuario autenticado.

## Seguridad aplicada
- Las contraseñas se almacenan hasheadas con `scrypt` + `salt` + `pepper` opcional por entorno.
- La API nunca retorna `password_hash` en respuestas.
- Tokens JWT firmados con `JWT_SECRET` y expiración `JWT_EXPIRES_IN`.
