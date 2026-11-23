# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y versiones con [SemVer](https://semver.org/lang/es/).

## [Unreleased]

### Añadido
- `bin/new-project`: genera un proyecto de Tier 0 a 3 en `$PROJECTS_ROOT/<tipo>/<slug>`, valida todo antes de escribir, construye en un temporal, mueve con `mv -T` y crea el primer commit.
- `lib/common.sh`: validación, composición de capas (`dot-` → `.`, sin `.tmpl`), render de fragmentos y placeholders, y escritura del lock.
- Capas `template/core` y `template/t1`.
- Contrato `.claude/starter.lock` con `schema=1`.
- Subagente `goldfish-revisor` (solo lectura, `omitClaudeMd`) y skills `/hito`, `/revisar-diff`, `/cierre-hito` y `/bitacora` en la capa `t1`; todos con `disable-model-invocation: true`.
- Capa `t2`: `docs/prd.md`, `docs/adr/0000-plantilla.md` y `/revisar-diseno`. Capa `t3`: `CHANGELOG.md` y el fragmento de gobierno en `CLAUDE.md`.
- `tests/smoke.sh` para los Tiers 0 a 3: frontmatter de agente y skills, `sha256sum -c` de managed y gobierno solo en Tier 3.
- `tests/fixtures/` con defectos sembrados y `tests/fixtures/preparar.sh`; resultados manuales en `docs/verificacion.md`.

### Cambiado
- `new-project`: si falla el primer commit, la pista es `git config --global --get-regexp '^includeif'` (C20).
- Skills: la sección del hito y el lock se leen con Grep y Read; `allowed-tools` solo con reglas exactas (`Bash(git diff HEAD)` y similares), porque una regla con prefijo preaprueba también comandos que escriben (`sed -n -i`, `git diff --output`). Smoke lo comprueba.
- `CLAUDE.md` generado (core y t1): Claude no edita `.env.example` e indica la línea exacta de cada variable nueva.

### Decidido
- C13: los patrones de managed son normativos; la tabla de archivos por capa es descriptiva.
- C17: los marcadores de fragmento deben ocupar la línea exacta, sin espacios.
- C18: `starter_commit` lleva `-dirty` por cambios sin commitear en `template/`, `lib/`, `bin/` o `VERSION`.
- C22: el `.gitignore` generado ignora `.env`, `.env.*` y `secrets/`, y versiona `.env.example`.
- Spike del Hito 2: `context: fork`, `agent`, `omitClaudeMd` y la inyección con `!` funcionan en Claude Code 2.1.330; no se aplicó el Plan B.
- Verificado: el `deny` de `.env*` impide a Claude leer, editar y crear `.env.example`; `settings.json` no cambia. Decidido: se mantiene así.
