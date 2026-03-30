# Guia de pruebas de alertas

Esta guia explica que necesitas para probar el flujo completo de alertas con notificacion por Evolution API.

## Requisitos

- API levantada en `http://localhost:9002`
- Base de datos conectada
- API key configurada y enviada en header
- JWT de usuario obtenido desde `/api/auth/login`
- Variables de Evolution API configuradas en `.env`:

```env
API_KEY=change_me_api_key
API_KEY_HEADER_NAME=x-api-key
```

Header obligatorio en cada request:

```http
x-api-key: change_me_api_key
```

Si falta o es incorrecta la API key, la API responde `401 Unauthorized`.

Header obligatorio para endpoints protegidos:

```http
Authorization: Bearer <jwt>
```

Si falta o es inválido el JWT, la API responde `401 Unauthorized`.

```env
EVOLUTION_API_BASE_URL=http://localhost:8080
EVOLUTION_INSTANCE=mi_instancia
EVOLUTION_API_KEY=mi_api_key
```

## Flujo de prueba recomendado

1. Registrar usuario (`POST /api/auth/register`) o iniciar sesión (`POST /api/auth/login`) con `x-api-key`.
2. Guardar `access_token` del login.
3. Crear contactos de emergencia del usuario autenticado.
4. Crear alerta proactiva (`es_proactiva: true`).
5. Revisar respuesta con `contactosNotificar`.
6. Crear alerta no proactiva (`es_proactiva: false`) y validar que no intente notificar.

## Body de usuario

```json
{
  "nombre": "Cesar",
  "apellido": "Lopez",
  "email": "cesar@example.com",
  "telefono": "+56999999999",
  "token_fcm": null
}
```

## Body de contacto de emergencia

```json
{
  "nombre_contacto": "Maria Perez",
  "telefono_contacto": "+56912345678",
  "prioridad": 1
}
```

## Body de alerta proactiva

```json
{
  "latitud": -33.43719212,
  "longitud": -70.65058345,
  "url_audio_contexto": "https://storage.example.com/audio/12345.mp3",
  "fecha_hora": "2026-03-29T14:00:00Z",
  "es_proactiva": true
}
```

## Body de alerta no proactiva

```json
{
  "latitud": -33.43719212,
  "longitud": -70.65058345,
  "url_audio_contexto": "https://storage.example.com/audio/12345.mp3",
  "es_proactiva": false
}
```

## Respuesta esperada en alerta proactiva

- `data.alerta`
- `data.contactosNotificar`

El `id_usuario` de la alerta se asigna automáticamente desde el JWT del usuario autenticado.

Nota: el envío a contactos se procesa de forma asíncrona y no bloquea la petición HTTP. Por tanto la respuesta NO incluye el resumen de `notificaciones` (se procesa en background). Si necesitas auditoría, se puede persistir el resultado de envíos en una tabla separada.

**Nota sobre el mensaje enviado a contactos**

- El mensaje que se envía a los contactos de emergencia *no* incluye la URL de audio de contexto ni muestra las coordenadas en texto plano.
- Como ubicación se incluye únicamente un enlace a Google Maps (`https://maps.google.com/?q=lat,long`) para que el receptor pueda abrir la ubicación.
- El mensaje incluye el nombre de la persona, la fecha/hora formateada y un llamado a comunicarse.

## Archivo HTTP

Usa `alertas.http` en esta misma carpeta para ejecutar todas las pruebas desde VS Code REST Client.
