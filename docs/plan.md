# Plan · project-starter

Derivado de la sección 7 de [`docs/dossier.md`](dossier.md). Los criterios de aceptación se copian literales; si cambian, cambian primero en el Dossier.

- **Estado global:** Hito 0 cerrado (23 nov 2026). Siguiente: Hito 1, en una sesión nueva.
- **Regla:** una sesión de Claude Code por hito, en plan mode. El código del Hito 1 no empieza hasta cumplir el criterio del Hito 0.
- **Cierre de cada hito:** checks verdes, `CLAUDE.md` del starter actualizado y entrada de bitácora.

| Hito | Nombre | Sesiones | Estado |
| --- | --- | --- | --- |
| 0 | Contrato revisado | 0,5 | Cerrado |
| 1 | Generador y capas base | 2 | Siguiente |
| 2 | Subagente y skills | 1,5 | Pendiente |
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

**Fuera de alcance:** perfiles, capas `t2` y `t3`, agente, skills y `starter-diff`. En este hito la sección managed del lock queda vacía en ambos Tiers.

Pasos, en orden:
- [ ] **1. Verificar la documentación de Claude Code:**
  - semántica de `Read(**/.env)` y `Read(**/.env.*)`;
  - si `Bash(git commit *)` cubre `git commit` sin argumentos;
  - carga de `CLAUDE.md` anidados y descubrimiento de skills en subdirectorios, que justifican `dot-` y `.tmpl`.

  Anotar el resultado en "Verificado" de la sección 5 del Dossier.
- [ ] **2. `VERSION` y `CHANGELOG.md`:** `VERSION` con `0.1.0`; `CHANGELOG.md` con la sección `[Unreleased]`.
- [ ] **3. `lib/common.sh`**, solo funciones y sin efectos al cargarse:
  - `die` y `log` (a stderr);
  - validaciones de slug, tipo, tier, visibilidad y perfil;
  - `normalizar_stack`;
  - `capas_para_tier`;
  - composición de fuentes: ruta de destino con `dot-` → `.` y sin `.tmpl`; capa superior gana; colisiones con error; sin entrar en `_fragmentos/`;
  - clasificación managed/seeded por patrón;
  - render: primero los fragmentos de línea completa, después los placeholders, con `while read` y expansión de parámetros, sin sed;
  - `starter_commit`;
  - `escribir_lock`.
- [ ] **4. `template/core/`:**
  - `CLAUDE.md.tmpl`: 15 líneas o menos, sin referencias a `docs/spec.md` ni `docs/plan.md`, y sin `{{COMANDOS_STACK}}` ni `{{GOBIERNO}}`;
  - `dot-gitignore`: **ya existe** con `*:Zone.Identifier`; completarlo con `.claude/settings.local.json`, `CLAUDE.local.md` y los patrones `.env` que se decidan (C22);
  - `dot-gitattributes` (`* text=auto eol=lf`), `dot-claude/settings.json` (contenido de la sección 6) y `docs/brief.md`.
- [ ] **5. `template/t1/`:**
  - `CLAUDE.md.tmpl`: 60 líneas o menos, con las secciones del Anexo A adaptadas y las líneas `{{COMANDOS_STACK}}` y `{{GOBIERNO}}`;
  - `docs/spec.md`, `docs/plan.md` y `docs/bitacora.md`.
- [ ] **6. `bin/new-project`:** los 10 pasos del algoritmo de la sección 5:
  - validar antes de escribir;
  - temporal con `mktemp -d` en la carpeta padre (con `--dry-run`, en `$TMPDIR`) y `trap` de limpieza;
  - permisos según la umask, segunda comprobación del destino y `mv -T`;
  - `git init -b main`, `add -A` y commit; si fallan, se borra el destino y el mensaje nombra las causas probables;
  - imprimir `git remote add`.

  Mientras no haya perfiles, cualquier `--stack` termina con error de perfil desconocido.
- [ ] **7. `tests/smoke.sh`:**
  - `PROJECTS_ROOT=$(mktemp -d)` con `personal/` y `work/`;
  - `GIT_CONFIG_GLOBAL` apuntando a un archivo temporal con una identidad de prueba;
  - los checks de la tabla de abajo, con salida verde o roja por check, `exit 1` si alguno falla y menos de 30 s en total.
- [ ] **8. `README.md` mínimo:** qué es, requisitos, uso con `PROJECTS_ROOT` y estado.
- [ ] **9. Cierre:**
  - verificación manual;
  - revisión goldfish del diff, a mano, porque `/revisar-diff` es del Hito 2;
  - actualizar este plan;
  - proponer en el chat la entrada de bitácora, que vive en el repo `portfolio`.

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
- [ ] Spike de `context: fork`, `agent`, `omitClaudeMd` e inyección con `!`.
- [ ] Agente `goldfish-revisor` y skills de t1 y t2.
- [ ] Capas `t2` (PRD, ADR) y `t3` (CHANGELOG, fragmento de gobierno).
- [ ] `tests/fixtures/` y verificación manual en `docs/verificacion.md`.
- [ ] Smoke ampliado a los 4 Tiers (frontmatter y `sha256sum -c` de managed).

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
- [ ] Búsqueda de secretos y datos personales.
- [ ] Revisión goldfish del README y el árbol.
- [ ] Generar la landing del portafolio y registrar lo que falte como issue.
- [ ] Tag `v0.1.0`.
