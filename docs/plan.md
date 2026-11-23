# Plan · project-starter

Derivado de la sección 7 de [`docs/dossier.md`](dossier.md). Los criterios de aceptación se copian literales; si cambian, cambian primero en el Dossier.

- **Estado global:** Hito 0 cerrado (23 nov 2026). Hito 1 cerrado (23 nov 2026, commit `854f76a`): smoke 53/53, shellcheck limpio y `/memory` verificado a mano. Hito 2 cerrado (23 nov 2026): smoke verde en los 4 Tiers, spike sin Plan B y los skills verificados sobre fixtures; pendiente el commit.
- **Regla:** una sesión de Claude Code por hito, en plan mode. El código del Hito 1 no empieza hasta cumplir el criterio del Hito 0.
- **Cierre de cada hito:** checks verdes, `CLAUDE.md` del starter actualizado y entrada de bitácora.

| Hito | Nombre | Sesiones | Estado |
| --- | --- | --- | --- |
| 0 | Contrato revisado | 0,5 | Cerrado |
| 1 | Generador y capas base | 2 | Cerrado |
| 2 | Subagente y skills | 1,5 | Cerrado |
| 3 | Perfiles y starter-diff | 1 | Pendiente |
| 4 | Publicación y primer uso real | 0,5 a 1 | Pendiente |

## Hito 0 · Contrato revisado

- **Objetivo:** confirmar que las secciones 5 y 6 bastan para implementar sin preguntas.
- **Entregables:** Dossier corregido y `docs/plan.md` derivado de esta sección.
- **Criterio de aceptación:** un goldfish que recibe solo las secciones 5 y 6 enumera los archivos de cada Tier y el algoritmo de `new-project` sin contradecir el Dossier, y cada ambigüedad de severidad alta queda resuelta.
- **Riesgo:** que el goldfish revise algo que el Dossier no dice. Se corrige el Dossier, no el prompt.

Tareas:
- [x] Crear `docs/plan.md` a partir de la sección 7.
- [x] Primera revisión goldfish de §5 y §6 (35 hallazgos, 7 altos).
- [x] Decidir metodología por Tier, visibilidad, perfiles en Tier 0 y composición de `CLAUDE.md`.
- [x] Aplicar las correcciones a §4, §5, §6, §7 (criterio del Hito 3: estados nuevos) y §9 del Dossier.
- [x] Segunda revisión goldfish con las §5 y §6 corregidas: 0 altos, 12 medios y 10 bajos. Aplicados los que afectan al Hito 1; los de `starter-diff` quedan en §9 para el Hito 3.

## Hito 1 · Generador y capas base

- **Objetivo:** `new-project` funcional para Tier 0 y 1.
- **Entregables:** `bin/new-project`, `lib/common.sh`, capas `core` y `t1` (sin skills todavía), lock, primer commit, `tests/smoke.sh` para Tier 0 y 1 y README mínimo.
- **Criterio de aceptación:** `tests/smoke.sh` verde para Tier 0 y 1; un destino existente, un slug inválido y una carpeta padre inexistente terminan con error y sin escribir nada; al abrir `claude` en un proyecto generado, `/memory` lista su `CLAUDE.md`.
- **Riesgo:** sustitución de placeholders frágil. Smoke verifica cero `{{` restantes.

El contrato que se implementa está en las secciones 5 y 6 del Dossier (tabla de archivos por capa, reglas de composición, algoritmo de `new-project` y gramática del lock). Antes de empezar, decidir las preguntas abiertas de la sección 9 marcadas "Hito 1" (C13, C17, C18 y C22).

Decisiones del inicio del Hito 1 (registradas en la sección 9 del Dossier):
- **C13:** los patrones de managed de la sección 6 son normativos; la tabla de la sección 5 es descriptiva. Smoke comprueba que coinciden.
- **C17:** la línea del marcador debe ser exactamente `{{GOBIERNO}}` o `{{COMANDOS_STACK}}`; con espacios, la generación falla.
- **C18:** `-dirty` por cambios sin commitear (incluidos sin seguimiento) en `template/`, `lib/`, `bin/` o `VERSION`.
- **C22:** el `.gitignore` generado lleva `.env`, `.env.*` y `!.env.example` (más `secrets/`); el `deny` de `settings.json` no cambia.

**Fuera de alcance:** perfiles, capas `t2` y `t3`, agente, skills y `starter-diff`. En este hito la sección managed del lock queda vacía en ambos Tiers.

Pasos, en orden:
- [x] **1. Verificar la documentación de Claude Code:**
  - semántica de `Read(**/.env)` y `Read(**/.env.*)`;
  - si `Bash(git commit *)` cubre `git commit` sin argumentos;
  - carga de `CLAUDE.md` anidados y descubrimiento de skills en subdirectorios, que justifican `dot-` y `.tmpl`.

  Anotar el resultado en "Verificado" de la sección 5 del Dossier.
- [x] **2. `VERSION` y `CHANGELOG.md`:** `VERSION` con `0.1.0`; `CHANGELOG.md` con la sección `[Unreleased]`.
- [x] **3. `lib/common.sh`**, solo funciones y sin efectos al cargarse:
  - `die` y `log` (a stderr);
  - validaciones de slug, tipo, tier, visibilidad y perfil;
  - `normalizar_stack`;
  - `capas_para_tier`;
  - composición de fuentes: ruta de destino con `dot-` → `.` y sin `.tmpl`; capa superior gana; colisiones con error; sin entrar en `_fragmentos/`;
  - clasificación managed/seeded por patrón;
  - render: primero los fragmentos de línea completa, después los placeholders, con `while read` y expansión de parámetros, sin sed;
  - `starter_commit`;
  - `escribir_lock`.
- [x] **4. `template/core/`:**
  - `CLAUDE.md.tmpl`: 15 líneas o menos, sin referencias a `docs/spec.md` ni `docs/plan.md`, y sin `{{COMANDOS_STACK}}` ni `{{GOBIERNO}}`;
  - `dot-gitignore`: **ya existe** con `*:Zone.Identifier`; completarlo con `.claude/settings.local.json`, `CLAUDE.local.md` y los patrones `.env` que se decidan (C22);
  - `dot-gitattributes` (`* text=auto eol=lf`), `dot-claude/settings.json` (contenido de la sección 6) y `docs/brief.md`.
- [x] **5. `template/t1/`:**
  - `CLAUDE.md.tmpl`: 60 líneas o menos, con las secciones del Anexo A adaptadas y las líneas `{{COMANDOS_STACK}}` y `{{GOBIERNO}}`;
  - `docs/spec.md`, `docs/plan.md` y `docs/bitacora.md`.
- [x] **6. `bin/new-project`:** los 10 pasos del algoritmo de la sección 5:
  - validar antes de escribir;
  - temporal con `mktemp -d` en la carpeta padre (con `--dry-run`, en `$TMPDIR`) y `trap` de limpieza;
  - permisos según la umask, segunda comprobación del destino y `mv -T`;
  - `git init -b main`, `add -A` y commit; si fallan, se borra el destino y el mensaje nombra las causas probables;
  - imprimir `git remote add`.

  Mientras no haya perfiles, cualquier `--stack` termina con error de perfil desconocido.
- [x] **7. `tests/smoke.sh`:**
  - `PROJECTS_ROOT=$(mktemp -d)` con `personal/` y `work/`;
  - `GIT_CONFIG_GLOBAL` apuntando a un archivo temporal con una identidad de prueba;
  - los checks de la tabla de abajo, con salida verde o roja por check, `exit 1` si alguno falla y menos de 30 s en total.
- [x] **8. `README.md` mínimo:** qué es, requisitos, uso con `PROJECTS_ROOT` y estado.
- [x] **9. Cierre:**
  - [x] verificación manual: `/memory` en un proyecto generado, hecha por Adrián: `/memory` lista el `CLAUDE.md` del proyecto y la identidad de git sale de `includeIf` por ruta (`bash -n` y `shellcheck` pasan);
  - [x] revisión goldfish del diff, a mano, porque `/revisar-diff` es del Hito 2: 0 altos, 2 medios y 8 bajos. Aplicados: `git add -A -f` y árbol limpio tras el commit, trap que borra el destino hasta el commit, rutas con salto de línea, `.claude/` vacío, `-dirty` con ignorados y `--no-optional-locks`, y fixtures de composición en smoke. Sin aplicar: `[Unreleased]` se fecha con el tag del Hito 4; `date -d` de GNU es aceptable en Ubuntu;
  - [x] actualizar este plan;
  - [x] entrada de bitácora guardada en el anexo C del Dossier (sin publicar en el repo `portfolio`).

Verificación del criterio de aceptación, con `tests/smoke.sh`:

| Check | Cómo |
| --- | --- |
| Estructura | **Tier 0:** existen `CLAUDE.md`, `.gitignore`, `.gitattributes`, `.claude/settings.json`, `docs/brief.md` y `.claude/starter.lock`; no existen `docs/spec.md` ni `docs/plan.md`.<br>**Tier 1:** además existen `docs/spec.md`, `docs/plan.md` y `docs/bitacora.md`; no existe `docs/adr/` |
| Placeholders | `grep -rF '{{'`, excluyendo `.git`, no devuelve nada |
| Tamaño de `CLAUDE.md` | Tier 0, 15 líneas o menos; Tier 1, 60 o menos |
| Lock | Comentario y claves en orden; los dos marcadores; managed vacía (se omite `sha256sum -c`); cada hash seeded igual al `sha256sum` de su fuente en `template/`; sin `$HOME` ni rutas absolutas |
| Git | `git rev-list --count HEAD` = 1, `git status --porcelain` vacío y el lock incluido en el commit |
| Rechazos | Código distinto de 0 y `find $PROJECTS_ROOT` idéntico antes y después, en cada caso: destino existente, slug inválido, tipo inválido, carpeta padre inexistente, Tier fuera de rango, visibilidad inválida y perfil desconocido |
| `--dry-run` | Código 0, imprime el lock y no escribe en `PROJECTS_ROOT` |
| Visibilidad por defecto | `personal` → `publico`; `work` → `privado` |

A mano:
- generar en un `PROJECTS_ROOT` de prueba, abrir `claude` en el proyecto y confirmar que `/memory` lista su `CLAUDE.md`;
- `bash -n` sobre los scripts, o `shellcheck bin/* lib/*.sh tests/*.sh` si está instalado.

## Hito 2 · Subagente y skills

- **Objetivo:** flujo goldfish y de cierre operativo, más las capas `t2` y `t3`.
- **Entregables:** `goldfish-revisor`, skills `hito`, `cierre-hito`, `revisar-diff`, `revisar-diseno` y `bitacora`, plantillas de ADR y PRD, y `tests/fixtures/` con defectos conocidos.
- **Criterio de aceptación:** un spike inicial confirma que `context: fork`, `agent` y la inyección del diff con `!` + comando funcionan (si no, plan B de la sección 9); sobre los fixtures, `/revisar-diff` encuentra el defecto sembrado y `/revisar-diseno` lista lo omitido; `git status` es idéntico antes y después; `/cierre-hito` no crea commits.
- **Riesgo:** dependen de comportamiento de Claude Code. La verificación manual queda documentada en `docs/verificacion.md`.

Tareas:
- [x] Spike de `context: fork`, `agent`, `omitClaudeMd` e inyección con `!`: las cuatro piezas funcionan en Claude Code 2.1.330, sin Plan B. Hallazgo: los skills con fork corren en segundo plano salvo con `background: false`.
- [x] Agente `goldfish-revisor` y skills de t1 y t2.
- [x] Capas `t2` (PRD, ADR) y `t3` (CHANGELOG, fragmento de gobierno).
- [x] `tests/fixtures/` y verificación manual en `docs/verificacion.md`: los cuatro skills pasan y `git status` queda idéntico.
- [x] Smoke ampliado a los 4 Tiers (frontmatter y `sha256sum -c` de managed).
- [x] Pista del error de git en `new-project`: `git config --global --get-regexp '^includeif'` (sección 9 del Dossier, C20), cubierta en smoke.
- [x] Prueba empírica de permisos sobre `.env` y `.env.example`, registrada en la sección 5 del Dossier. Abre una pregunta en la sección 9: si Claude debe poder mantener `.env.example`.
- [x] Cierre: revisión goldfish del diff con un subagente de contexto limpio: cumple con reservas, 0 altos, 2 medios y 4 bajos, todos aplicados:
  - `allowed-tools` restringido (después sustituido, ver abajo);
  - fixture `cierre-hito-ok` para el camino verde, que cierra sin commitear;
  - `preparar.sh` con limpieza ante errores, stderr visible y comprobación de la inserción del check;
  - `/revisar-diseno` mencionado en `CLAUDE.md`;
  - cerca de cuatro acentos graves para el diff.
- [x] Entrada de bitácora en el anexo C del Dossier.
- [x] Ajustes previos al commit:
  - `allowed-tools`: la prueba mostró que `Bash(sed -n *)` preaprueba `sed -n -i`. Los skills leen con Grep y Read, y los comandos `!` usan reglas exactas; smoke prohíbe `*` en `allowed-tools`.
  - `.env.example`: se mantiene el `deny` (pregunta de la sección 9 cerrada) y el `CLAUDE.md` generado lleva la convención de indicar la línea exacta de cada variable nueva.
  - Fixtures revisados: sin cadenas con forma de secreto.
- [ ] Commit, cuando se pida.

## Hito 3 · Perfiles y starter-diff

- **Objetivo:** stacks componibles y detección de divergencias.
- **Entregables:** perfiles `nextjs`, `supabase` y `odoo-addon` (escritos con la documentación vigente de cada uno) y `bin/starter-diff`.
- **Criterio de aceptación:** smoke verde en los 4 Tiers y en las combinaciones `nextjs`, `nextjs,supabase` y `odoo-addon`; sobre un proyecto manipulado a propósito, `starter-diff` reporta cada uno de los 11 estados de la sección 6 al menos una vez y con la clasificación correcta: 8 managed (faltante, retirado, limpio, desactualizado, actualizado-sin-registrar, modificado, conflicto, nuevo-en-starter) y 3 seeded (faltante, plantilla-sin-cambios, plantilla-cambió).
- **Riesgo:** los comandos de cada stack cambian. Cada perfil lleva su fecha de verificación.

Tareas:
- [ ] Perfiles con regla `stack-<perfil>.md` y fragmento de comandos.
- [ ] `bin/starter-diff` con los estados de la sección 6.
- [ ] Decidir cómo se acepta una actualización en el lock, junto con C10 y C14 (preguntas abiertas de la sección 9).
- [ ] Smoke con combinaciones de stack y proyecto manipulado.

## Hito 4 · Publicación y primer uso real

- **Objetivo:** repo público y probado con un proyecto real.
- **Entregables:** README (qué es, Tiers, uso, razón de E/G), CHANGELOG, LICENSE, tag `v0.1.0`, entrada de bitácora del propio starter y la landing del portafolio creada con `new-project`.
- **Criterio de aceptación:** clon limpio en un directorio temporal y quickstart del README en 3 comandos o menos; búsqueda de secretos y datos personales sin hallazgos; un goldfish con solo el README y el árbol del repo explica qué hace el starter; la landing se genera sin editar la estructura a mano.
- **Riesgo:** un README que solo entiende su autor. Lo cubre la revisión goldfish.

Tareas:
- [ ] Decidir idioma del README.
- [ ] README completo, LICENSE (MIT) y CHANGELOG.
- [ ] El README documenta como requisito previo la identidad de git por ruta: reglas `includeIf` para `~/projects/personal` y `~/projects/work`; sin ellas el primer commit de `new-project` falla y el destino se borra.
- [ ] Búsqueda de secretos y datos personales.
- [ ] Revisión goldfish del README y el árbol.
- [ ] Generar la landing del portafolio y registrar lo que falte como issue.
- [ ] Tag `v0.1.0`.
