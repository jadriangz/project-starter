# Verificación manual · project-starter

Pruebas que dependen del comportamiento de Claude Code y no caben en `tests/smoke.sh`, porque gastan cuota. Cada entrada indica la fecha, la versión, el comando, lo observado y si pasa. Se repiten cuando cambian los skills, el agente o `settings.json`, o cuando cambia la versión de Claude Code.

## 2026-11-23 · Hito 2 · Claude Code 2.1.330

Todas las ejecuciones se hicieron con `claude -p`, lanzado desde una sesión de Claude Code, en proyectos temporales fuera de `~/projects`. El estado de git se compara con `git status --porcelain` y `git rev-list --count HEAD` antes y después.

### Spike: `context: fork`, `agent`, `omitClaudeMd` e inyección con `!`

Proyecto desechable con:
- `CLAUDE.md` que contiene `CANARIO-CLAUDEMD`;
- un agente `goldfish-revisor` (`tools: Read, Grep, Glob`, `omitClaudeMd: true`) que se identifica con `CANARIO-AGENTE`;
- un skill con `context: fork`, `agent: goldfish-revisor`, `background: false`, `` !`git diff HEAD` `` y `` !`sed -n "/^## Hito $0 /,/^## /p" docs/plan.md` ``.

Primer turno: `claude -p "Recuerda esta palabra: CANARIO-CHAT"`. Segundo turno: `claude -p --continue "/spike 1"`.

| Pieza | Evidencia esperada | Observado | Resultado |
| --- | --- | --- | --- |
| `agent:` con un agente propio | Responde con `CANARIO-AGENTE` | "IDENTIDAD: CANARIO-AGENTE" | Pasa |
| `context: fork` | No conoce `CANARIO-CHAT` | Solo cita `CANARIO-AGENTE`, "ninguna en la conversación" | Pasa |
| `omitClaudeMd: true` | No conoce `CANARIO-CLAUDEMD` | No lo cita | Pasa |
| `!` + `git diff HEAD` | Resume el cambio real | Describe el cambio de `app.py` y detecta que no cumple el criterio | Pasa |
| `$0` dentro de `!` | Recibe solo el hito 1 | Recibe el hito 1. El rango de `sed` incluía el encabezado del hito siguiente; los skills lo excluyen | Pasa |
| Herramientas del agente | Read, Grep y Glob | "Read, Grep, Glob"; no tiene Bash aunque el skill declare `allowed-tools` | Pasa |

Conclusión: no hace falta Plan B. Notas:
- Los skills con fork corren en segundo plano por defecto. Con `background: false`, el resultado vuelve en el mismo turno.
- `allowed-tools` preaprueba los comandos `!` y, en la conversación principal, cualquier llamada de Claude que case durante ese turno. No restringe herramientas ni da Bash al agente de un skill con fork. Ver "Alcance de `allowed-tools`".
- `$0` entra sin sanear en el comando `!`. Es aceptable porque el argumento lo escribe el usuario.

### Permisos sobre `.env` y `.env.example`

Proyecto temporal con el `settings.json` de `template/core`, `.env` y `.env.example`. Se ejecutó `claude -p --allowedTools "Read" "Write" "Edit" "Bash(cat *)"`; el allow aísla el efecto del deny, porque en `-p` lo no permitido se niega de todas formas. El disco se comprobó con `sha256sum -c` y `ls`.

| # | Acción | Mensaje | Disco | Resultado |
| --- | --- | --- | --- | --- |
| 1 | Read `.env` | "File is in a directory that is denied by your permission settings." | Sin cambios | Negado |
| 2 | Read `.env.example` | Igual que 1 | Sin cambios | Negado |
| 3 | Bash `cat .env.example` | "Permission to use Bash with command cat .env.example has been denied." | Sin cambios | Negado, aunque `Bash(cat *)` estaba permitido |
| 4 | Edit `.env.example` | "File is covered by a Read deny rule in your permission settings and cannot be edited." | Hash igual | Negado |
| 5 | Write `.env.example` | "… cannot be written." | Hash igual | Negado |
| 6 | Write `.env.local` (nuevo) | "… cannot be written." | No se creó | Negado |
| 7 | Write `otro.txt` (control) | "File created successfully" | Creado | Permitido |

Conclusión: con el `deny` actual, Claude no puede leer, editar ni crear ningún `.env*`, incluido `.env.example`. Es coherente con la documentación: "A `Read` deny rule also blocks the Edit and Write tools on the same path, including creating a new file there".

### Skills sobre fixtures

Cada proyecto se prepara con `tests/fixtures/preparar.sh <caso>`.

| Skill | Fixture | Esperado | Observado | git antes/después | Resultado |
| --- | --- | --- | --- | --- | --- |
| `/revisar-diff 1` | `revisar-diff`: `promedio.sh` divide por `$#` sin comprobar que haya argumentos; la prueba no tiene seguimiento | Cita el defecto | Hallazgo alto en `promedio.sh:9`: sin argumentos, división por cero en lugar de `error: faltan números`. Leyó también la prueba sin seguimiento y señaló que no cubre ese caso | Idéntico | Pasa |
| `/revisar-diseno` | `revisar-diseno`: "Pruebas y verificación" vacía y el criterio "rápida e intuitiva" | Lista ambas carencias | Hallazgos altos 1 (criterio de R1 no medible) y 2 (sección de pruebas vacía), y 8 más | Idéntico | Pasa |
| `/cierre-hito 1` | `cierre-hito`: `tests/check.sh` falla | Informa el fallo, no cierra y no commitea | Informa `FALLA suma 2 2 = 5` y se detiene en el paso 2. `docs/plan.md` y `docs/bitacora.md` sin cambios, aunque tenía permiso de Edit y Write | Idéntico (2 commits) | Pasa |
| `/cierre-hito 1` | `cierre-hito-ok`: el check pasa y la revisión goldfish está en `docs/bitacora.md` | Cierra sin commitear | Primer turno: checks y criterio en verde; se detiene en el paso 4 y pide confirmar la revisión goldfish, aunque esté en la bitácora. Segundo turno (`--continue`, confirmando): marca el hito como "Cerrado (2026-11-23)", añade la entrada de cierre a la bitácora y no commitea. En la transcripción `stream-json` no hay ningún intento de `git commit` | 2 commits antes y después; solo `docs/plan.md` y `docs/bitacora.md` modificados | Pasa |
| `/bitacora` | `bitacora`: `anonimizado`, con un cliente y una persona ficticios en `docs/` | Marca los nombres y los omite | Lista ambos nombres con su sustitución; ninguno aparece en la entrada. Señaló además la incoherencia entre el plan y la bitácora del fixture | Idéntico | Pasa |

En los dos casos de `/cierre-hito` se usó `--allowedTools "Bash(bash tests/check.sh)" "Edit" "Write"`. Los demás corrieron sin permisos extra.

Tras la revisión goldfish del diff del Hito 2, el diff va en una cerca de cuatro acentos graves. `allowed-tools` cambió dos veces: primero a `Bash(sed -n *)`, y después a reglas exactas tras la prueba siguiente.

Para repetir en interactivo: `cd "$(tests/fixtures/preparar.sh revisar-diff)" && claude`, y después `/revisar-diff 1`.

### Alcance de `allowed-tools`

Proyecto temporal con un skill que declara `allowed-tools: Bash(sed -n *) Bash(git diff *)` y pide ejecutar dos comandos que escriben. Se lanzó con `claude -p "/prueba-sed"`, sin permisos extra.

| Comando | Con el skill | Sin el skill (control) |
| --- | --- | --- |
| `sed -n -i '1p' a.txt` | Se ejecutó sin preguntar; `a.txt` quedó truncado a una línea (hash distinto) | "needs approval … Claude Code asks before a shell command creates, changes or removes files"; disco sin cambios |
| `git diff --no-index --output=salida.txt a.txt b.txt` | Se ejecutó sin preguntar y creó `salida.txt` | No se ejecutó |

Conclusión: una regla con prefijo en `allowed-tools` preaprueba cualquier comando que empiece así, incluidos los que escriben, y se salta la detección de escritura que se aplica sin ella. Coincide con la documentación: `allowed-tools` preaprueba y no restringe, y "A rule with no `*` matches one exact command". Cambios:
- `/hito`, `/cierre-hito` y `/revisar-diff` leen la sección del hito con Grep y Read, sin `sed`;
- `/bitacora` lee el lock con Read y no declara `allowed-tools`;
- los comandos `!` que quedan usan reglas exactas: `Bash(git diff HEAD)`, `Bash(git ls-files --others --exclude-standard)` y `Bash(git status --short)`;
- smoke falla si un skill generado declara `allowed-tools` con `*`.

Casos repetidos con los skills nuevos, sobre fixtures recién preparados:

| Skill | Fixture | Observado | git antes/después | Resultado |
| --- | --- | --- | --- | --- |
| `/revisar-diff 1` | `revisar-diff` | Hallazgo alto en `promedio.sh:9` (caso sin argumentos); la inyección con reglas exactas funciona dentro del fork | Idéntico | Pasa |
| `/hito 1` | `revisar-diff` | Leyó `docs/plan.md` con Read. Usó Bash solo para explorar (`git diff`, ejecutar `promedio.sh`). Propuso preguntas y no escribió código | Idéntico | Pasa |
| `/cierre-hito 1` | `cierre-hito` (rojo) | Se detiene en el check que falla; plan y bitácora sin cambios | 2 commits antes y después | Pasa |
| `/cierre-hito 1` | `cierre-hito-ok` (verde, dos turnos) | Marca el hito como Cerrado y añade la bitácora; 0 intentos de `git commit` en la transcripción | 2 commits antes y después; solo `docs/plan.md` y `docs/bitacora.md` modificados | Pasa |
| `/bitacora` | `bitacora` | Toma `anonimizado` del lock y ningún nombre sembrado aparece en la entrada | Idéntico | Pasa |
