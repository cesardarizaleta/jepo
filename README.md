# Jepo — Sistema de Asistencia Proactiva

Jepo es una aplicación móvil prototipo (tesis) cuyo objetivo es cambiar
el paradigma de asistencia: de un modelo reactivo (el usuario pide ayuda)
a un modelo proactivo (el sistema detecta situaciones de riesgo y actúa
para solicitar ayuda en nombre del usuario).

**Resumen rápido**
- Plataforma: Flutter (Dart)
- Objetivo: Android (primario), iOS (secundario)
- Componentes: App móvil (inteligencia y recolección de datos), servicios
	en la nube (API) y un panel de control para terceros autorizados.

**Estado**: prototipo avanzado — incluye reconocimiento de actividad,
servicios de background, y flujo de pre-alerta para evitar falsos positivos.

**Contenido**
- **Arquitectura & módulos críticos**: geolocalización continua, lectura de
	sensores y reconocimiento de actividad (HAR), y gestión de alertas.
- **API**: documentación en `docs/` (endpoints de auth, usuarios, contactos, alertas).
- **Flujo de pre-alerta**: la app muestra una pantalla de confirmación
	(full-screen) antes de notificar contactos; el background persistente
	no puede enviar alertas sin pasar por esta confirmación.

**Enlaces rápidos**
- Documentación API: [docs/README.md](docs/README.md)
- Guía de contactos de emergencia: [docs/emergency-contacts/emergency-contacts.md](docs/emergency-contacts/emergency-contacts.md)
- Guía de alertas y pruebas: [docs/alertas/alertas.md](docs/alertas/alertas.md)
- Instrucciones del proyecto (operación y objetivos): [.github/copilot-instructions.md](.github/copilot-instructions.md)

**Arquitectura (alto nivel)**
- App móvil: recoge sensores (GPS, acelerómetro, giroscopio), ejecuta
	detección local de riesgo (HAR) y coordina el flujo de pre-alerta.
- Servicios en la nube: gestión de usuarios, contactos y orquestación de
	notificaciones a terceros (el backend maneja el fan-out hacia servicios
	externos de envío).
- Panel de control: interfaz para supervisión/autorización (separado).

**Módulos críticos**
- Geolocalización continua: seguimiento en background, geofencing y rutas
	hacia zonas seguras.
- Sensor + HAR: detección de caídas, impactos, inactividad prolongada,
	movimientos inusuales — implementado priorizando eficiencia energética.
- Gestión de alertas y notificaciones: incluye un flujo de "pre-alerta"
	(10s por defecto) que solicita confirmación del usuario antes de
	notificar a los contactos.

Implementación relevante en el repo:
- `lib/services/background_service.dart` — servicio en background (emite eventos `risk_detected`, persiste payloads pendientes y dispara notificaciones intrusivas para traer al usuario a la app).
- `lib/services/pre_alert_service.dart` — interfaz para solicitar confirmación desde servicios que quieran enviar alertas.
- `lib/screens/pre_alert_confirmation_screen.dart` — UI full-screen para la cuenta regresiva y confirmación.
- `lib/services/alert_queue_service.dart` — cola/gate para enviar o encolar alertas (ahora respeta la pre-alerta).
- `lib/services/emergency_contacts_service.dart` — llamadas para crear/listar/actualizar/eliminar contactos.

**API y seguridad**
- Prefijo API: `/api`
- Autenticación: todas las llamadas protegidas requieren `x-api-key` (header) y para endpoints de usuario además `Authorization: Bearer <jwt>`.
- Endpoints clave:
	- `POST /api/auth/register` — registrar usuario (retorna `access_token`).
	- `POST /api/auth/login` — iniciar sesión.
	- `GET /api/auth/me` — perfil del usuario autenticado.
	- `POST /api/usuarios/contactos` — crear contacto de emergencia.
	- `GET /api/usuarios/contactos` — listar contactos del usuario.
	- `POST /api/alertas` — crear alerta (campo `es_proactiva: true` para alertas proactivas).

Ver la documentación detallada de cada módulo en `docs/`:
- [docs/auth/auth.md](docs/auth/auth.md)
- [docs/users/users.md](docs/users/users.md)
- [docs/emergency-contacts/emergency-contacts.md](docs/emergency-contacts/emergency-contacts.md)
- [docs/alertas/alertas.md](docs/alertas/alertas.md)

**Notas importantes para frontend / integradores**
- `telefono_contacto` en contactos debe ser una cadena numérica (7–30 chars)
	y única por usuario; el owner viene del JWT (no enviar idUsuario).
- El API responde con formato estandarizado; manejar `401`, `409` y mensajes
	de validación (por ejemplo: "Validation failed (numeric string is expected)").
- Usa los `.http` dentro de `docs/` (o `curl`) para probar endpoints.

**Variables de entorno y configuración**
- `.env` (ejemplo variables):
	- `API_KEY` — clave de aplicación para llamadas API.
	- `API_KEY_HEADER_NAME` — nombre del header si se personaliza (default `x-api-key`).
	- `BASE_URL` — URL base para el API (si no, usa `https://api-jepo.irissoftware.lat`).
	- Variables relacionadas con Evolution API u otros servicios externas según `docs/alertas/alertas.md`.

**Desarrollo y ejecución local**
Requisitos: Flutter SDK, Android SDK/JDK, (opcional) emulador o dispositivo.

Comandos básicos:

```bash
flutter pub get
flutter run -d <device_id>
flutter build apk --release
flutter analyze
```

Para pruebas de API desde VS Code: abre los archivos `*.http` en `docs/` y ejecuta con REST Client.

**Notas operativas y decisiones de diseño**
- Pre-alerta: por seguridad, cualquier alerta que pase por la cola debe
	solicitar confirmación en la UI (si el usuario no confirma, la alerta
	se envía después de la cuenta regresiva). El background no debe
	enviar notificaciones directas sin pasar por este flujo.
- Notificaciones y fan-out: la lógica de notificación masiva (SMS, Twilio,
	etc.) debe ser preferiblemente gestionada en el backend; el cliente
	solo almacena y envía instrucciones al servicio.

**Dónde encontrar código relevante**
- Pantallas: `lib/screens/`
- Servicios y lógica: `lib/services/`
- Widgets reutilizables: `lib/widgets/`
- Recursos y assets: `assets/`

**Contribuir**
- Sigue el estilo y estructura existente; PRs pequeñas y revisables.
- Metodología de desarrollo: XP — implementación iterativa y pruebas
	constantes.

Si quieres, puedo:
- Ejecutar `flutter analyze` y reportar warnings/errores.
- Añadir un CHANGELOG o plantilla `CONTRIBUTING.md`.

---
Archivo actualizado automáticamente con la documentación disponible en `docs/` y las instrucciones del proyecto.
