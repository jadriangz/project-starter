# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y versiones con [SemVer](https://semver.org/lang/es/).

## [Unreleased]

### Añadido
- `bin/new-project`: genera un proyecto de Tier 0 o 1 en `$PROJECTS_ROOT/<tipo>/<slug>`, valida todo antes de escribir, construye en un temporal, mueve con `mv -T` y crea el primer commit.
- `lib/common.sh`: validación, composición de capas (`dot-` → `.`, sin `.tmpl`), render de fragmentos y placeholders, y escritura del lock.
- Capas `template/core` y `template/t1` (sin agente ni skills todavía).
- Contrato `.claude/starter.lock` con `schema=1`.
- `tests/smoke.sh` para Tier 0 y 1.

### Decidido
- C13: los patrones de managed son normativos; la tabla de archivos por capa es descriptiva.
- C17: los marcadores de fragmento deben ocupar la línea exacta, sin espacios.
- C18: `starter_commit` lleva `-dirty` por cambios sin commitear en `template/`, `lib/`, `bin/` o `VERSION`.
- C22: el `.gitignore` generado ignora `.env`, `.env.*` y `secrets/`, y versiona `.env.example`.
