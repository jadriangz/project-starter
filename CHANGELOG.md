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
- Perfiles `nextjs` (Next.js 16), `supabase` (CLI v3) y `odoo-addon` (Odoo 19.0 y 20.0): regla `.claude/rules/stack-<perfil>.md` con `paths:` y fecha de verificación, y fragmento de comandos en `CLAUDE.md` desde Tier 1.
- `bin/starter-diff`: compara un proyecto con el starter actual y reporta los 11 estados de §6 (8 managed y 3 seeded). Es de solo lectura e imprime la línea del lock que hay que editar.
- `lib/common.sh`: `leer_lock` valida la gramática del lock: rechaza rutas absolutas, con `..` o mal formadas, un `stack` sin normalizar y entradas en la sección equivocada. `starter-diff` no sigue enlaces simbólicos.
- Smoke: combinaciones de stack (incluido Tier 0) y un proyecto manipulado que provoca los 11 estados.

### Cambiado
- `new-project`: si falla el primer commit, la pista es `git config --global --get-regexp '^includeif'` (C20).
- Skills: la sección del hito y el lock se leen con Grep y Read; `allowed-tools` solo con reglas exactas (`Bash(git diff HEAD)` y similares), porque una regla con prefijo preaprueba también comandos que escriben (`sed -n -i`, `git diff --output`). Smoke lo comprueba.
- `CLAUDE.md` generado (core y t1): Claude no edita `.env.example` e indica la línea exacta de cada variable nueva.
- Composición: un perfil solo puede aportar `.claude/rules/stack-<perfil>.md` y su fragmento; cualquier otro archivo es error.

### Decidido
- C13: los patrones de managed son normativos; la tabla de archivos por capa es descriptiva.
- C17: los marcadores de fragmento deben ocupar la línea exacta, sin espacios.
- C18: `starter_commit` lleva `-dirty` por cambios sin commitear en `template/`, `lib/`, `bin/` o `VERSION`.
- C22: el `.gitignore` generado ignora `.env`, `.env.*` y `secrets/`, y versiona `.env.example`.
- Spike del Hito 2: `context: fork`, `agent`, `omitClaudeMd` y la inyección con `!` funcionan en Claude Code 2.1.330; no se aplicó el Plan B.
- Hito 3: las actualizaciones aceptadas se registran a mano en el lock; un perfil retirado da `retirado` con aviso (C10); una ruta managed nueva que ya existe en el proyecto da `actualizado-sin-registrar` o `conflicto` (C14); el perfil `odoo-addon` usa `ODOO_BIN` y `ODOO_ADDONS_PATH` y no guarda rutas.
- Verificado: el `deny` de `.env*` impide a Claude leer, editar y crear `.env.example`; `settings.json` no cambia. Decidido: se mantiene así.
