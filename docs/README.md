# Documentación API — Índice

Carpeta `docs/` con guías y colecciones HTTP para cada módulo.

- Usuarios
  - [docs/users/users.md](docs/users/users.md)
  - [docs/users/users.http](docs/users/users.http)

- Autenticacion
  - [docs/auth/auth.md](docs/auth/auth.md)
  - [docs/auth/auth.http](docs/auth/auth.http)

- Contactos de emergencia
  - [docs/emergency-contacts/emergency-contacts.md](docs/emergency-contacts/emergency-contacts.md)
  - [docs/emergency-contacts/emergency-contacts.http](docs/emergency-contacts/emergency-contacts.http)

- Alertas
  - [docs/alertas/alertas.md](docs/alertas/alertas.md)
  - [docs/alertas/alertas.http](docs/alertas/alertas.http)

Uso:
- Abre los `.http` en VS Code con REST Client o usa `curl` desde terminal.
- Reemplaza `@baseUrl` si tu servidor usa otro puerto.
- Todas las peticiones requieren API key en header (por defecto `x-api-key`), excepto `POST /api/auth/register` y `POST /api/auth/login`.
