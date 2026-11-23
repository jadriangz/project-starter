# project-starter

Generador de proyectos para Claude Code. Con un solo comando crea la carpeta de un proyecto nuevo (`CLAUDE.md`, docs, permisos base y, desde Tier 1, un subagente revisor goldfish y skills de flujo) adaptada a su Tier de complejidad, con git inicializado y un primer commit, y deja en `.claude/starter.lock` de qué versión del starter salió.

## Requisitos

Linux o WSL2 con bash 5, git 2.28 o superior y coreutils (`sha256sum`). Sin jq, Python ni Node.

## Uso

```bash
git clone <este-repo> && cd project-starter
mkdir -p ~/projects/personal ~/projects/work   # el generador no crea la carpeta padre
bin/new-project mi-proyecto --tipo personal --tier 1
```

- `--tipo personal|work` y `--tier 0-3` son obligatorios; `--visibilidad publico|anonimizado|privado` es opcional (por defecto `publico` en `personal` y `privado` en `work`).
- `--stack nextjs,supabase,odoo-addon` (cualquier combinación) añade una regla `.claude/rules/stack-<perfil>.md`, que Claude carga solo al leer archivos de ese stack, y, desde Tier 1, sus comandos en `CLAUDE.md`. El perfil `odoo-addon` trata el proyecto como directorio de addons y espera las variables `ODOO_BIN` y `ODOO_ADDONS_PATH` en tu entorno; el starter no guarda rutas.
- `--dry-run` imprime las rutas y el lock sin escribir nada.
- El destino es `$PROJECTS_ROOT/<tipo>/<slug>`, con `PROJECTS_ROOT=~/projects` por defecto. Para probar sin tocar tus carpetas:

  ```bash
  export PROJECTS_ROOT=$(mktemp -d) && mkdir "$PROJECTS_ROOT/personal"
  bin/new-project prueba --tipo personal --tier 0
  ```

- Nunca sobrescribe un destino existente: valida todo antes de escribir, construye en un directorio temporal y lo mueve al final.

Para ver qué divergió un proyecto del starter actual: `bin/starter-diff ~/projects/personal/mi-proyecto`. Es de solo lectura: reporta el estado de cada archivo (por ejemplo `limpio`, `modificado`, `desactualizado` o `plantilla-cambió`) y, cuando hay que tocar el lock, imprime la línea exacta para editarlo a mano.

Pruebas: `tests/smoke.sh` (y `shellcheck bin/* lib/*.sh tests/*.sh tests/fixtures/*.sh` si está instalado). Los skills se verifican a mano sobre fixtures: `tests/fixtures/preparar.sh <caso>` y [`docs/verificacion.md`](docs/verificacion.md).

## Tiers

| Tier | Recibe |
| --- | --- |
| 0 | `CLAUDE.md` corto, `docs/brief.md`, `.gitignore`, `.gitattributes` y `.claude/settings.json` |
| 1 | `CLAUDE.md` completo, `docs/spec.md`, `docs/plan.md`, `docs/bitacora.md`, el subagente `goldfish-revisor` y los skills `/hito`, `/revisar-diff`, `/cierre-hito` y `/bitacora` |
| 2 | además `docs/prd.md`, plantilla de ADR y `/revisar-diseno` |
| 3 | además `CHANGELOG.md` y una sección de gobierno en `CLAUDE.md` |

Los skills solo se ejecutan cuando los invocas (`disable-model-invocation`). Los de revisión corren en el subagente `goldfish-revisor`, sin la conversación ni el `CLAUDE.md` y con herramientas de solo lectura.

## Estado

v0.1 en construcción. Funcionan los Tiers 0 a 3, los perfiles `nextjs`, `supabase` y `odoo-addon`, el subagente, los skills y `bin/starter-diff`. Pendiente: la publicación (Hito 4). El diseño está en [`docs/dossier.md`](docs/dossier.md) y el avance en [`docs/plan.md`](docs/plan.md).
