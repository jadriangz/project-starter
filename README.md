# project-starter

Generador de proyectos para Claude Code. Con un solo comando crea la carpeta de un proyecto nuevo (`CLAUDE.md`, docs, reglas y permisos base) adaptada a su Tier de complejidad, con git inicializado y un primer commit, y deja en `.claude/starter.lock` de qué versión del starter salió.

## Requisitos

Linux o WSL2 con bash 5, git 2.28 o superior y coreutils (`sha256sum`). Sin jq, Python ni Node.

## Uso

```bash
git clone <este-repo> && cd project-starter
mkdir -p ~/projects/personal ~/projects/work   # el generador no crea la carpeta padre
bin/new-project mi-proyecto --tipo personal --tier 1
```

- `--tipo personal|work` y `--tier 0-3` son obligatorios; `--visibilidad publico|anonimizado|privado` es opcional (por defecto `publico` en `personal` y `privado` en `work`).
- `--dry-run` imprime las rutas y el lock sin escribir nada.
- El destino es `$PROJECTS_ROOT/<tipo>/<slug>`, con `PROJECTS_ROOT=~/projects` por defecto. Para probar sin tocar tus carpetas:

  ```bash
  export PROJECTS_ROOT=$(mktemp -d) && mkdir "$PROJECTS_ROOT/personal"
  bin/new-project prueba --tipo personal --tier 0
  ```

- Nunca sobrescribe un destino existente: valida todo antes de escribir, construye en un directorio temporal y lo mueve al final.

Pruebas: `tests/smoke.sh` (y `shellcheck bin/* lib/*.sh tests/*.sh` si está instalado).

## Estado

v0.1 en construcción. Funcionan los Tiers 0 y 1 sin stack. Pendientes: subagente revisor y skills, Tiers 2 y 3, perfiles de stack (`--stack`) y `bin/starter-diff`. El diseño está en [`docs/dossier.md`](docs/dossier.md) y el avance en [`docs/plan.md`](docs/plan.md).
