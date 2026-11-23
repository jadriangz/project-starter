# project-starter

> **In English:** a Bash generator that scaffolds new Claude Code projects. Each project gets its `CLAUDE.md`, docs, base permissions and, from Tier 1 up, a read-only "goldfish" review subagent and workflow skills, all sized to the project's complexity tier and stack. A lock file records which starter version each project came from, and `bin/starter-diff` reports drift. Quickstart below; the rest of the docs are in Spanish.

Generador de proyectos para Claude Code. Con un solo comando crea la carpeta de un proyecto nuevo, adaptada a su Tier de complejidad y a su stack:
- `CLAUDE.md`, docs y permisos base;
- desde Tier 1, un subagente revisor "goldfish" (sin memoria de la conversación) y skills de flujo.

El proyecto sale con git inicializado y un primer commit. En `.claude/starter.lock` queda registrado de qué versión del starter salió, y `bin/starter-diff` te dice después qué divergió.

## Requisitos

- Linux o WSL2 con bash 5, git 2.28 o superior y coreutils (`sha256sum`). Sin jq, Python ni Node. Las pruebas usan `GIT_CONFIG_GLOBAL`, que pide git 2.32 o superior.
- **Identidad de git por ruta.** El generador hace el primer commit ya en el destino final, después de moverlo, así que git necesita saber quién eres en `~/projects/personal` y `~/projects/work`. Sin esa identidad el commit falla y el generador deshace lo que acaba de crear. Con reglas `includeIf` en `~/.gitconfig`:

  ```ini
  [includeIf "gitdir:~/projects/personal/"]
      path = ~/.gitconfig-personal
  [includeIf "gitdir:~/projects/work/"]
      path = ~/.gitconfig-work
  ```

  Cada archivo incluido lleva su `[user]` con `name` y `email`. Una identidad global única también sirve.

## Quickstart

```bash
git clone https://github.com/jadriangz/project-starter.git && cd project-starter
mkdir -p ~/projects/personal ~/projects/work
bin/new-project mi-proyecto --tipo personal --tier 1
```

El generador no crea la carpeta padre; por eso va el `mkdir`. Al terminar imprime el `git remote add` para conectar el proyecto con GitHub; el generador no toca la red. Entra con `cd ~/projects/personal/mi-proyecto` y abre `claude`.

## Uso

```text
bin/new-project <slug> --tipo personal|work --tier 0-3 [--stack nextjs,supabase,odoo-addon] [--visibilidad publico|anonimizado|privado] [--dry-run]
```

- `--tipo` y `--tier` son obligatorios. El slug usa minúsculas, dígitos y guiones simples (hasta 64 caracteres). El destino es `$PROJECTS_ROOT/<tipo>/<slug>`; `PROJECTS_ROOT` vale `~/projects` por defecto.
- `--visibilidad` decide qué cuenta `/bitacora` del proyecto. Por defecto es `publico` en `personal` y `privado` en `work`.
  - `publico`: entrada completa;
  - `anonimizado`: sin nombres de clientes, empresas, personas ni enlaces;
  - `privado`: solo un resumen interno.
- `--stack` acepta cualquier combinación de perfiles. Cada uno añade:
  - una regla `.claude/rules/stack-<perfil>.md`, que Claude carga solo al leer archivos de ese stack;
  - desde Tier 1, los comandos del stack en `CLAUDE.md`.

  El perfil `odoo-addon` trata el proyecto como directorio de addons. Sus comandos usan `ODOO_BIN` y `ODOO_ADDONS_PATH`, que defines en tu entorno para trabajar en el proyecto; no hacen falta para generarlo.
- `--dry-run` imprime las rutas y el lock sin escribir nada.
- **Nunca sobrescribe un destino existente.** Valida todo antes de escribir, construye en un directorio temporal y lo mueve al final.
- **Remoto.** El `git remote add` impreso usa el alias SSH `github-<tipo>`.
  - En `personal`, el dueño es la cuenta del autor (`jadriangz`); si usas el starter con tu cuenta, cámbialo en el comando impreso.
  - En `work`, el dueño es el valor de `STARTER_WORK_OWNER`, que puedes definir con `export STARTER_WORK_OWNER=mi-org` en `~/.bashrc`. Sin la variable se imprime `<ORG>`.

  Este repo no guarda nombres de organizaciones.

### Probar sin tocar tus carpetas

Con un `PROJECTS_ROOT` temporal y una identidad de git solo para la prueba (un directorio temporal queda fuera de tus reglas `includeIf`):

```bash
export PROJECTS_ROOT=$(mktemp -d) && mkdir "$PROJECTS_ROOT/personal"
printf '[user]\n\tname = Prueba\n\temail = prueba@example.invalid\n' >"$PROJECTS_ROOT/gitconfig"
GIT_CONFIG_GLOBAL="$PROJECTS_ROOT/gitconfig" bin/new-project prueba --tipo personal --tier 1
```

Para comprobar el resultado:
- `git -C "$PROJECTS_ROOT/personal/prueba" log --oneline` muestra un solo commit;
- `bin/starter-diff "$PROJECTS_ROOT/personal/prueba"` reporta cada archivo como `limpio` o `plantilla-sin-cambios`.

Al terminar, ejecuta `unset PROJECTS_ROOT`. Si no, los siguientes `new-project` de esa terminal también generarán en el temporal.

### Comparar un proyecto con el starter

```bash
bin/starter-diff ~/projects/personal/mi-proyecto
```

Es de solo lectura y compara tres versiones de cada archivo: la del proyecto, la del starter actual y el hash que guardó el lock al generar. Hay dos tipos de archivo:
- **managed** (agente, skills y reglas de stack): siguen al starter;
- **seeded** (`CLAUDE.md`, docs, `settings.json`): nacen del starter y después son del proyecto.

| Estado | Significa | Qué hacer |
| --- | --- | --- |
| `limpio` | Ni el proyecto ni el starter cambiaron | Nada |
| `desactualizado` | El starter cambió y el proyecto no | Copiar la versión nueva del starter |
| `modificado` | El proyecto cambió y el starter no | Aceptar la divergencia o mover el cambio a un archivo propio |
| `conflicto` | Cambiaron los dos, de forma distinta | Revisión manual |
| `actualizado-sin-registrar` | El proyecto ya tiene la versión nueva, pero el lock no | Actualizar la entrada del lock |
| `faltante` | El archivo del lock no existe en el proyecto | Restaurarlo o retirar su entrada |
| `retirado` | El starter ya no tiene ese archivo | Conservarlo como propio y retirar la entrada |
| `nuevo-en-starter` | El starter tiene un archivo managed que el lock no lista | Copiarlo y añadir su entrada |

Los seeded solo dicen si su plantilla cambió (`plantilla-sin-cambios` o `plantilla-cambió`) o si faltan; lo que haya cambiado el proyecto se respeta. Las actualizaciones se copian a mano. Cuando hay que tocar el lock, `starter-diff` imprime la línea exacta para editarlo.

## Tiers

El Tier mide la complejidad del proyecto, y cada Tier añade capas sobre el anterior. La columna "Para qué" es orientativa; si dudas, empieza en Tier 1.

| Tier | Para qué | Recibe |
| --- | --- | --- |
| 0 | Un experimento o un script de una o dos sesiones | `CLAUDE.md` corto, `docs/brief.md`, `.gitignore`, `.gitattributes` y `.claude/settings.json` |
| 1 | Un proyecto de varias sesiones con hitos | `CLAUDE.md` completo, `docs/spec.md`, `docs/plan.md`, `docs/bitacora.md`, el subagente `goldfish-revisor` y los skills `/hito`, `/revisar-diff`, `/cierre-hito` y `/bitacora` |
| 2 | Además, decisiones de producto y de arquitectura que hay que registrar | además `docs/prd.md`, plantilla de ADR y `/revisar-diseno` |
| 3 | Además, una vida larga, con versiones y reglas de gobierno | además `CHANGELOG.md` y una sección de gobierno en `CLAUDE.md` |

Los skills solo se ejecutan cuando los invocas (`disable-model-invocation`), así que no gastan cuota por su cuenta.

## Por qué E/G

Desde Tier 1, los proyectos siguen el método de trabajo que en el lock y en `CLAUDE.md` aparece como E/G (`metodologia=eg-ligero`):
- primero se escribe qué se construye y cómo se acepta (spec y plan por hitos);
- Claude construye un hito por sesión;
- un **goldfish** revisa el resultado.

El goldfish es el subagente `goldfish-revisor`, que no ve la conversación ni el `CLAUDE.md` y solo tiene herramientas de lectura. Recibe el criterio de aceptación y el diff (`/revisar-diff`) o el diseño (`/revisar-diseno`), y como no comparte el contexto de quien construyó, detecta lo que el autor da por sobrentendido. `/cierre-hito` corre los checks y actualiza el plan y la bitácora, pero nunca commitea.

## Límites conocidos

- El `settings.json` generado niega a Claude la lectura de `.env`, `.env.*`, `secrets/` y `~/.ssh/`, y pregunta antes de `git commit` y `git push`. Es una red de seguridad, no un aislamiento:
  - un script que abre `.env` por su cuenta no está cubierto;
  - una variante como `git -C . push` no coincide con la regla.
- El sandbox de Claude Code se evaluará en la v0.2.
- El `deny` de `.env.*` también impide a Claude editar `.env.example`. Ese archivo lo mantienes tú: Claude te indica la línea exacta de cada variable nueva.
- Solo Linux y WSL2. No hace scaffolding de código de aplicaciones.

## Desarrollo

- **Pruebas:** `tests/smoke.sh` (y `shellcheck bin/* lib/*.sh tests/*.sh tests/fixtures/*.sh` si está instalado). Genera siempre en un `PROJECTS_ROOT` temporal.
- **Skills:** se verifican a mano sobre fixtures con `tests/fixtures/preparar.sh <caso>`; los resultados están en [`docs/verificacion.md`](docs/verificacion.md).
- **Diseño, contrato y decisiones:** [`docs/dossier.md`](docs/dossier.md).
- **Hitos:** [`docs/plan.md`](docs/plan.md).
- **Cambios:** [`CHANGELOG.md`](CHANGELOG.md).

## Estado y licencia

v0.1.0. Funcionan:
- los Tiers 0 a 3;
- los perfiles `nextjs`, `supabase` y `odoo-addon`;
- el subagente y los skills;
- `bin/starter-diff`.

Licencia [MIT](LICENSE).
