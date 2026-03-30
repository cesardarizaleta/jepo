# Contactos de emergencia — API

Documentación para gestionar la red de confianza del usuario autenticado.

Base path: `/api/usuarios/contactos`

## Seguridad obligatoria

Todas las peticiones requieren ambos headers:

- Header por defecto: `x-api-key`
- Valor: `API_KEY` definido en `.env`
- Header configurable por env: `API_KEY_HEADER_NAME`
- Header de usuario: `Authorization: Bearer <jwt>`

Ejemplo:

```http
x-api-key: change_me_api_key
Authorization: Bearer <jwt>
```

Archivos relevantes:
- [Controlador](src/emergency-contacts/emergency-contacts.controller.ts)
- [Servicio](src/emergency-contacts/emergency-contacts.service.ts)
- [DTOs](src/emergency-contacts/dto)

---

## Reglas importantes
- Máximo 5 contactos por usuario (se retorna error si se excede).
- `telefono_contacto` debe ser único por usuario.
- El usuario dueño se toma desde el JWT; el cliente no envía `idUsuario`.

---

## Endpoints

### 1) Crear contacto
- Método: `POST /api/usuarios/contactos`
- Body (JSON):

```json
{
  "nombre_contacto": "Maria Perez",
  "telefono_contacto": "+56912345678",
  "prioridad": 1
}
```

- Validaciones:
  - `nombre_contacto`: 2–120 chars
  - `telefono_contacto`: 7–30 chars
  - `prioridad`: entero 1–5

- Respuesta (ejemplo):

```json
{
  "success": true,
  "message": "Contacto de emergencia creado",
  "data": { /* contacto creado */ }
}
```

### 2) Listar contactos por usuario
- Método: `GET /api/usuarios/contactos`
- Respuesta: lista ordenada por `prioridad` ascendente.

### 3) Obtener contacto
- Método: `GET /api/usuarios/contactos/:id`

### 4) Actualizar contacto
- Método: `PATCH /api/usuarios/contactos/:id`
- Body: campos opcionales de `UpdateEmergencyContactDto`.

### 5) Eliminar contacto
- Método: `DELETE /api/usuarios/contactos/:id`

---

## Notas para el frontend
- El owner ya viene en el JWT, no enviar identificador de usuario por URL o body.
- Manejar errores de `409 Conflict` si el teléfono ya existe.
- Validar localmente la longitud/formato del teléfono.
- Si falta o es incorrecta la API key, la API responde `401 Unauthorized`.
- Si falta o es inválido el JWT, la API responde `401 Unauthorized`.

---

Ejecuta los ejemplos desde `emergency-contacts.http` (misma carpeta).
