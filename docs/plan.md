# Plan · project-starter

Derivado de la sección 7 de [`docs/dossier.md`](dossier.md). Los criterios de aceptación se copian literales; si cambian, cambian primero en el Dossier.

- **Estado global:** Hito 0 cerrado (23 nov 2026). Hito 1 cerrado (23 nov 2026, commit `854f76a`): smoke 53/53, shellcheck limpio y `/memory` verificado a mano. Hito 2 cerrado (23 nov 2026, commit `7bd2fb6`): smoke verde en los 4 Tiers, spike sin Plan B y los skills verificados sobre fixtures. Hito 3 cerrado (23 nov 2026, commit `df56317`): smoke verde con stacks y los 11 estados de `starter-diff`; la prueba manual de carga de reglas del perfil `nextjs` pasó. Hito 4 cerrado (23 nov 2026, commit `798ed25`, tag `v0.1.0`): repo público y tag publicado en GitHub; Releases deshabilitado en el repo. **v0.1 terminada.**
- **Regla:** una sesión de Claude Code por hito, en plan mode. El código del Hito 1 no empieza hasta cumplir el criterio del Hito 0.
- **Cierre de cada hito:** checks verdes, `CLAUDE.md` del starter actualizado y entrada de bitácora.

| Hito | Nombre | Sesiones | Estado |
| --- | --- | --- | --- |
| 0 | Contrato revisado | 0,5 | Cerrado |
| 1 | Generador y capas base | 2 | Cerrado |
| 2 | Subagente y skills | 1,5 | Cerrado |
| 3 | Perfiles y starter-diff | 1 | Cerrado |
| 4 | Publicación y primer uso real | 0,5 a 1 | Cerrado |

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
- [x] Commit: `7bd2fb6` (23 nov 2026).

## Hito 3 · Perfiles y starter-diff

- **Objetivo:** stacks componibles y detección de divergencias.
- **Entregables:** perfiles `nextjs`, `supabase` y `odoo-addon` (escritos con la documentación vigente de cada uno) y `bin/starter-diff`.
- **Criterio de aceptación:** smoke verde en los 4 Tiers y en las combinaciones `nextjs`, `nextjs,supabase` y `odoo-addon`; sobre un proyecto manipulado a propósito, `starter-diff` reporta cada uno de los 11 estados de la sección 6 al menos una vez y con la clasificación correcta: 8 managed (faltante, retirado, limpio, desactualizado, actualizado-sin-registrar, modificado, conflicto, nuevo-en-starter) y 3 seeded (faltante, plantilla-sin-cambios, plantilla-cambió).
- **Riesgo:** los comandos de cada stack cambian. Cada perfil lleva su fecha de verificación.

Decisiones del inicio del Hito 3 (registradas en las secciones 6 y 9 del Dossier):
- **Aceptación de actualizaciones:** manual; `starter-diff` es de solo lectura e imprime la línea exacta del lock.
- **C10:** perfil del lock que ya no existe → aviso en stderr y sus managed como `retirado`.
- **C14:** segunda pasada para `nuevo-en-starter`; si la ruta ya existe en el proyecto, P = S → `actualizado-sin-registrar` y P ≠ S → `conflicto`.
- **Odoo:** el proyecto es el directorio de addons; comandos con `$ODOO_BIN` y `--addons-path="$ODOO_ADDONS_PATH,."`; perfil agnóstico, verificado en 19.0 y 20.0.
- **Sandbox:** fuera de este hito; queda abierta sin hito.
- `VERSION` sigue en `0.1.0`: no cambia el formato del lock ni los nombres de capas o skills.

Tareas:
- [x] Perfiles `nextjs`, `supabase` y `odoo-addon`: regla `stack-<perfil>.md` con `paths:` y fragmento de comandos, cada viñeta verificada en la documentación vigente (fuentes en la sección 5 del Dossier). Quedó fuera lo que no se pudo leer textual: los scripts de `create-next-app` y el retiro de `attrs` en Odoo. Hallazgo: Odoo 20 usa `security/ir.access.csv` y 19 `ir.model.access.csv`; la regla nombra ambos.
- [x] `lib/common.sh`: un perfil solo puede aportar su regla y `_fragmentos/comandos.md`; `leer_lock` para `starter-diff`.
- [x] `bin/starter-diff` con los 11 estados de la sección 6, C10, C14 y la línea de lock sugerida.
- [x] Decidir cómo se acepta una actualización en el lock, junto con C10 y C14 (preguntas abiertas de la sección 9).
- [x] Smoke con combinaciones de stack (`nextjs`, `nextjs,supabase`, `odoo-addon` y stack en Tier 0) y fixture manipulado que provoca los 11 estados: 178 checks en verde en 6 s, shellcheck limpio. Dos mutaciones deliberadas (escribir en el proyecto y seguir enlaces) hacen fallar el smoke.
- [x] Revisión goldfish del diff con un subagente de contexto limpio: cumple con reservas, 0 altos, 2 medios y 6 bajos, todos aplicados:
  - la prueba de solo lectura compara contenido, no solo nombres y `git status`;
  - `starter-diff` no sigue enlaces simbólicos: un enlace o un directorio en una ruta managed da `conflicto`, y un `.claude` enlazado fuera del proyecto es error;
  - `leer_lock` rechaza un `stack` sin normalizar, rutas con `//` o `/` final y entradas en la sección equivocada;
  - un perfil no puede llevar otros archivos en `_fragmentos/`;
  - smoke cubre ruta absoluta, nota C12, `retirado` de una capa y las líneas `lock:` de desactualizado y nuevo-en-starter;
  - objetivo 3 de la sección 3 del Dossier alineado con los 11 estados.
- [x] CHANGELOG, README y entrada de bitácora en el anexo C del Dossier.
- [x] A mano: en un proyecto con `--stack nextjs`, abrir `claude`, leer un archivo de `app/` y confirmar que `stack-nextjs.md` se carga solo entonces. Hecho por Adrián: pasó.
- [x] Commit: `df56317` (23 nov 2026).

## Hito 4 · Publicación y primer uso real

- **Objetivo:** repo público y probado con un proyecto real.
- **Entregables:** README (qué es, Tiers, uso, razón de E/G), CHANGELOG, LICENSE, tag `v0.1.0` y entrada de bitácora del propio starter.
- **Criterio de aceptación:** clon limpio en un directorio temporal y quickstart del README en 3 comandos o menos; búsqueda de secretos y datos personales en todo el historial de git sin hallazgos; un goldfish con solo el README y el árbol del repo explica qué hace el starter; el README se valida de punta a punta, siguiendo solo sus instrucciones en el clon temporal (clonar, `new-project` y comprobar el resultado).
- **Riesgo:** un README que solo entiende su autor. Lo cubre la revisión goldfish.

Decisiones del inicio del Hito 4 (registradas en las secciones 3, 7 y 9 del Dossier):
- **Cambio de criterio:** sale "la landing se genera sin editar la estructura a mano" y entra la validación del README de punta a punta. Razón: la landing merece su propio Dossier y su clasificación en el Estudio; meterla aquí mezclaría dos proyectos y dejaría el cierre de la v0.1 sujeto a otro.
- **Idioma del README:** español, con un resumen breve en inglés al inicio.
- **Sandbox en WSL2:** no entra en la v0.1; se evalúa en la v0.2. El README documenta el límite de los `deny`.
- **Organización de GitHub para `work`:** solo `STARTER_WORK_OWNER`; el repo no guarda el nombre.
- **Licencia:** MIT, confirmada.
- **Publicación:** hacer público el repo, subir el tag o cambiar ajustes de GitHub exige confirmación explícita de Adrián.

Tareas:
- [x] Decidir idioma del README, sandbox, organización de `work` y licencia.
- [x] Búsqueda de secretos y datos personales en todo el historial (`gitleaks git --log-opts=--all` y grep de rutas y correos sobre `git log -p --all`): sin hallazgos.
- [x] README completo, LICENSE (MIT) y CHANGELOG con `[0.1.0]`. Smoke verde (5 s), shellcheck limpio y gitleaks sin hallazgos en árbol e historial.
- [x] El README documenta como requisito previo la identidad de git por ruta: reglas `includeIf` para `~/projects/personal` y `~/projects/work`; sin ellas el primer commit de `new-project` falla y el destino se borra.
- [x] Validar el README de punta a punta en un clon temporal:
  - quickstart literal con `HOME` temporal y el `includeIf` del README, en 3 comandos: 1 commit, árbol limpio y lock presente;
  - "Probar sin tocar tus carpetas", también literal;
  - `starter-diff` en ambos casos: 5 `limpio` y 8 `plantilla-sin-cambios`.

  Hallazgo corregido: el bloque de prueba anterior fallaba sin identidad global; ahora usa `GIT_CONFIG_GLOBAL`.
- [x] Revisión goldfish del README y el árbol, con un subagente que solo vio esos dos: explicó bien el starter y dio "con reservas", con 0 altos, 5 medios y 7 bajos, todos aplicados:
  - git 2.32 para las pruebas;
  - commit en el destino final;
  - criterio orientativo de Tier;
  - tabla de estados de `starter-diff`;
  - E/G ligado a `metodologia=eg-ligero`;
  - slug, visibilidad, remoto `personal`, `unset PROJECTS_ROOT` y variables de Odoo.
- [x] Entrada de bitácora en el anexo C del Dossier.
- [x] Tag `v0.1.0` sobre `798ed25`, subido a `origin` con confirmación de Adrián. El repo es público (`"visibility": "public"` en la API de GitHub, licencia detectada `MIT`). Adrián deshabilitó Releases en el repo, así que no hay release: la versión publicada es el tag.
- [x] Verificación final contra el repo publicado:
  - clon limpio desde GitHub siguiendo el README, con un `HOME` temporal: código 0, 1 commit, árbol limpio y `starter-diff` con 5 `limpio` y 8 `plantilla-sin-cambios`;
  - smoke: 178 PASA, 0 fallas, 6 s;
  - gitleaks sobre los 9 commits: sin hallazgos.
- [x] Commit de la explicación de E/G (Elephant/Goldfish) en el README: `8be757a`, posterior al tag y anotado en `[Unreleased]`.

**Siguiente paso, fuera del Hito 4:** la landing del portafolio, como proyecto propio en el Estudio (Dossier y Tier propios), generada después con `bin/new-project`.
