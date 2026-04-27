Estado: Fase 1-5 completadas (2026-04-26). Plan de integracion finalizado.
Prioridad inmediata: Smoke testing manual en dispositivo Android.


## Plan: Integracion Robusta Jepo API + App

Integrar completamente el frontend Flutter actual con la API documentada usando una capa de red tipada, control estricto de incidentes (1 alerta por incidente + cooldown fuerte), y sincronizacion confiable entre servicio en background y UI. El enfoque prioriza seguridad, trazabilidad, anti-spam y resiliencia sin envios masivos ni canales paralelos fuera del backend.

**Steps**
1. Fase 1 - Contrato API unificado y endurecimiento de red. Crear una capa comun de parsing para el envelope {success, message, data, errors, path, timestamp} en ApiClient; separar errores transitorios/permanentes; estandarizar timeouts/reintentos por tipo de error; mantener x-api-key + Bearer de forma centralizada. Esta fase bloquea todas las siguientes.
2. Fase 1 - Configuracion segura por entorno (paralela con paso 1 en gran parte). Introducir AppConfig/Environment para BASE_URL, API key header name y banderas de debug; retirar dependencia operativa de .env en produccion; mantener .env.example y reglas de carga por flavor/dev-prod.
3. Fase 2 - Dominio tipado y mapeo DTOs (depende de 1). Implementar modelos/serializacion para Auth, User, EmergencyContact, IncidentAlert y ApiResponse; eliminar uso de Map dinamicos en servicios para reducir errores de runtime y facilitar validaciones de formulario.
4. Fase 2 - Servicios API completos y alineados a documentacion (depende de 3). Completar metodos faltantes: usuarios (actualizacion perfil + token_fcm), contactos (CRUD completo con orden por prioridad), alertas (CRUD, consulta por id); normalizar telefono y coordenadas (8 decimales) en una sola utilidad de dominio.
5. Fase 3 - Estado de sesion y ownership estricto en frontend (depende de 4). Restringir consumo de usuarios a perfil autenticado (me + update propio) y evitar flujos de CRUD amplio en UI comun; fortalecer manejo 401 para cerrar sesion, detener pipelines de background y reintentar solo cuando exista sesion valida.
6. Fase 3 - Orquestacion anti-envio masivo (depende de 4 y 5). Rediseñar AlertQueueService para: 1 alerta por incidente, cooldown de incidente (5-10 min), deduplicacion por event_id (UUID cliente), backoff exponencial con jitter para cola, limite de reintentos por item, y reenvio por lotes controlados (max 1 alerta activa por ciclo).
7. Fase 3 - Flujo proactivo end-to-end (depende de 6). Ajustar BackgroundService + PreAlertService para separar: deteccion -> preconfirmacion -> creacion incidente -> actualizaciones de ubicacion (sin renotificar contactos). Mantener solo canal backend (sin SMS/llamada automatica local en esta fase).
8. Fase 4 - Sinergia frontend-backend en UX (depende de 5, 6, 7). Actualizar pantallas para consumir estados reales de backend: estado de sesion, errores de validacion por campo, estado de incidente activo, contactos listos para protocolo, y feedback de cola offline/online.
9. Fase 4 - Observabilidad y auditoria operativa (depende de 6 y 7). Agregar telemetry logs estructurados locales (sin datos sensibles), correlacion por event_id, y panel simple en app para diagnostico (cola pendiente, ultimo envio, ultimo error).
10. Fase 5 - Pruebas y validacion robusta (depende de todas). Incorporar unit tests (ApiClient, cola, deduplicacion), widget tests de formularios/errores, e2e de flujo critico (impacto detectado -> prealerta -> alerta API -> estado UI). Incluir pruebas de conectividad intermitente y expiracion de token.

**Relevant files**
- c:/Users/Cesar/Desktop/Code/jepo/lib/services/api_client.dart — Envolver respuestas API, clasificar errores, politicas de retry/timeout, cabeceras globales.
- c:/Users/Cesar/Desktop/Code/jepo/lib/services/auth_service.dart — Sesion tipada, persistencia segura, me/update profile, token lifecycle.
- c:/Users/Cesar/Desktop/Code/jepo/lib/services/users_service.dart — Reducir/ajustar superficie a perfil autenticado segun ownership.
- c:/Users/Cesar/Desktop/Code/jepo/lib/services/emergency_contacts_service.dart — CRUD tipado y reglas de negocio (max 5, prioridad, telefono normalizado).
- c:/Users/Cesar/Desktop/Code/jepo/lib/services/alerts_service.dart — Creacion/consulta/actualizacion de alertas con DTOs y event_id.
- c:/Users/Cesar/Desktop/Code/jepo/lib/services/alert_queue_service.dart — Control absoluto anti-spam, deduplicacion, cooldown incidente, backoff.
- c:/Users/Cesar/Desktop/Code/jepo/lib/services/background_service.dart — Pipeline de deteccion + despacho robusto en segundo plano.
- c:/Users/Cesar/Desktop/Code/jepo/lib/services/pre_alert_service.dart — Confirmacion previa y contrato con UI.
- c:/Users/Cesar/Desktop/Code/jepo/lib/services/session_events.dart — Reaccion global a 401 y coordinacion con background.
- c:/Users/Cesar/Desktop/Code/jepo/lib/main.dart — Bootstrap de servicios, SessionGate, listeners de prealerta/sesion.
- c:/Users/Cesar/Desktop/Code/jepo/lib/screens/login_screen.dart — Manejo de errores API y rehidratacion de cola post-login.
- c:/Users/Cesar/Desktop/Code/jepo/lib/screens/family_screen.dart — Integracion fuerte con contactos backend y validaciones UI.
- c:/Users/Cesar/Desktop/Code/jepo/lib/screens/profile_screen.dart — Fuente unica de datos del usuario autenticado.
- c:/Users/Cesar/Desktop/Code/jepo/lib/screens/telemetry_screen.dart — Visualizacion de estado de riesgo alineada con incidente activo.
- c:/Users/Cesar/Desktop/Code/jepo/lib/utils/phone_utils.dart — Normalizacion canonica para comparacion/serializacion.
- c:/Users/Cesar/Desktop/Code/jepo/pubspec.yaml — Config de assets/env/dependencias para estrategia por entornos.
- c:/Users/Cesar/Desktop/Code/jepo/docs/documentation.md — Contrato funcional base de integracion.

**Verification**
1. Ejecutar pruebas unitarias de servicios: parseo envelope, errores 4xx/5xx, retry solo en fallos transitorios.
2. Simular expiracion JWT y comprobar: logout consistente, detencion de pipeline de alertas, redireccion a login sin loops.
3. Simular 20 eventos de impacto en 60s y verificar: solo 1 incidente activo, sin envios masivos, cola controlada.
4. Probar conectividad intermitente: alertas pasan a cola, reenvio con backoff y deduplicacion por event_id al recuperar red.
5. Validar contactos: maximo 5, telefono unico normalizado por usuario, orden por prioridad.
6. Validar alertas: lat/long a 8 decimales, es_proactiva true dispara protocolo backend, false no notifica contactos.
7. Verificar UX de errores: mostrar errors[] de backend en formularios (register/login/contactos/alertas).
8. Ejecutar smoke manual Android con app en foreground/background + pantalla bloqueada.

**Decisions**
- Politica de incidente: solo 1 alerta por incidente con cooldown fuerte (sin multi-envio de notificaciones).
- Canal de envio: solo backend en esta fase; no SMS/llamada automatica local.
- Alcance usuarios: frontend orientado a perfil autenticado y ownership; no CRUD amplio para usuario final.
- Incluye: integracion API-frontend, robustez de cola, estado de sesion, UX de errores, pruebas.
- Excluye (esta fase): rediseño visual completo, nuevas capacidades ML avanzadas de HAR, backend schema migrations.

**Further Considerations**
1. Event ID y idempotencia: recomendado enviar client_event_id en POST /api/alertas y registrar respuesta para correlacion.
2. Politica de cooldown exacta: recomendado 10 min para incidente nuevo + heartbeat de ubicacion cada 30-60s sin renotificar contactos.
3. Rollout seguro: activar cambios por feature flags (strict_alert_control, typed_api_layer) para despliegue gradual.