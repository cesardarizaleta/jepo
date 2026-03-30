# Postman - JEPO API

## Archivos

- Coleccion: docs/Jepo.postman_collection.json
- Environment: docs/Jepo.postman_environment.json

## Variables importantes

- baseUrl: URL base de la API (por defecto http://localhost:9002)
- apiKey: valor de API_KEY del .env
- jwt: token de acceso (se completa automaticamente al ejecutar Register o Login)
- userId, contactId, alertId: ids de trabajo para requests por ID

## Flujo recomendado

1. Ejecutar 00 - Health y Docs > Health
2. Ejecutar 01 - Auth > Register o Login
3. Verificar que jwt quedo cargado en environment
4. Ejecutar 03 - Contactos de Emergencia
5. Ejecutar 04 - Alertas de Incidentes

## Notas

- Todas las rutas usan x-api-key.
- Rutas protegidas (Me, Contactos, Alertas) tambien requieren Authorization Bearer {{jwt}}.
- La coleccion incluye scripts de test para guardar automaticamente jwt, userId, contactId y alertId cuando la respuesta los trae.
