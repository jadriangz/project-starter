# project-starter
Generador de proyectos para Claude Code: crea ~/projects/personal|work/<slug> con docs, reglas, skills y subagente goldfish adaptados al Tier y al stack. Repo público.

## Comandos
- Generar: `bin/new-project <slug> --tipo personal|work --tier 0-3 [--stack nextjs,supabase] [--visibilidad publico|anonimizado|privado] [--dry-run]`
- Comparar un proyecto con el starter: `bin/starter-diff <ruta-del-proyecto>`
- Test: `tests/smoke.sh` · Lint: `shellcheck bin/* lib/*.sh tests/*.sh tests/fixtures/*.sh` (si está instalado) · Fixtures de skills: `tests/fixtures/preparar.sh <caso>`

## Estructura
- `bin/` ejecutables · `lib/` funciones compartidas · `tests/` smoke y fixtures
- `template/{core,t1,t2,t3}/` capas aditivas por Tier · `template/profiles/<perfil>/` reglas y comandos por stack
- `docs/dossier.md` (diseño y contrato) · `docs/plan.md` (hitos) · `VERSION` · `CHANGELOG.md`

## Convenciones
- Bash puro con `set -euo pipefail`; sin jq, Python ni Node. Documentación en español.
- Nunca sobrescribir un destino existente: validar todo antes de escribir, construir en un directorio temporal y mover.
- Contrato estable: formato de `.claude/starter.lock`, nombres de capas y de skills. Cambiarlo exige subir `VERSION`, anotar en `CHANGELOG.md` y cubrirlo en `tests/smoke.sh`.
- Antes de cambiar skills, agentes o `settings.json`, verificar la documentación vigente de Claude Code.
- Repo público: ningún secreto, ruta personal ni dato de empresa o cliente.

## Cómo trabajar aquí
- Plan mode antes de cambios no triviales. Una sesión por hito de `docs/plan.md`.
- Fuente de verdad: `docs/dossier.md` (qué y por qué) y `docs/plan.md` (cuándo). Si el código y el Dossier difieren, preguntar.
- Metodología: Tier 1 · E/G ligero. Revisión goldfish del contrato antes del Hito 1 y del diff al cerrar cada hito.
- Pruebas siempre con un `PROJECTS_ROOT` temporal; nunca generar en el `~/projects` real.
- No commitear sin que se pida. Commits pequeños y con mensaje claro.

## Definición de hecho
`tests/smoke.sh` verde, criterio de aceptación del hito cumplido, `VERSION` y `CHANGELOG.md` al día si cambió el contrato, entrada de bitácora actualizada.
