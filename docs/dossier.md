# Dossier · project-starter

Nov 23, 2026 · @Adrián Garza

## 1. Resumen y decisión

`project-starter` es un repo público que genera, con un solo comando, la carpeta de un proyecto nuevo (docs, reglas, skills y subagente revisor de Claude Code) ya adaptada al Tier y al stack, y que deja registrado de qué versión del starter salió cada proyecto.

| Decisión | Resultado |
| --- | --- |
| Complejidad | 7/18 → Tier 1 (Alcance 1 · Integraciones 0 · Riesgo 1 · Incertidumbre 1 · Vida útil 3 · Superficie 1). Sin overrides |
| Metodología | E/G ligero, más una revisión goldfish del contrato (estructura y manifest) antes de codear, por la cláusula "difícil de revertir" |
| Proyecto de Claude propio | No. Cumple 1 de 5 criterios (vida >2 meses). El Dossier vive en `docs/dossier.md` del repo |
| Portafolio | Público, repo en la cuenta personal (`jadriangz`) |
| Modelo de uso | Generador: se clona una vez y `new-project` crea el proyecto en `~/projects/personal\|work/<slug>` |
| Riesgo principal | Que la plantilla envejezca frente a Claude Code, o que los proyectos generados diverjan de ella |

## 2. Problema y usuario

Adrián arranca proyectos nuevos con Claude Code y, sin una base reutilizable, rehace a mano en cada uno la misma estructura de contexto: CLAUDE.md, spec, plan, reglas y flujo de revisión.

- **Usuario:** Adrián, único usuario y mantenedor, trabajando en WSL2 con `~/projects/personal` y `~/projects/work`. Terceros solo lo leen como portafolio.
- **Cómo se resuelve hoy:** no hay plantilla común; la estructura se arma proyecto por proyecto (supuesto, ver sección 9).
- **Costo de no resolverlo:** cada arranque gasta sesiones de configuración sobre una cuota de suscripción limitada. Las correcciones aprendidas en un proyecto no llegan al siguiente. Y el portafolio no tiene una pieza que muestre el método.

## 3. Objetivos y no-objetivos

La v0.1 se da por lograda cuando se cumplen estos seis resultados medibles.

1. `new-project` genera un proyecto válido en cada Tier (0 a 3) en menos de 5 s y sin red.
2. `tests/smoke.sh` pasa en WSL2 Ubuntu 24.04 con los 4 Tiers y al menos 3 combinaciones de stack.
3. `starter-diff` distingue tres estados por archivo: limpio, modificado en el proyecto y desactualizado frente al starter.
4. `/revisar-diseno` y `/revisar-diff` devuelven hallazgos sobre fixtures con defectos conocidos y no modifican ningún archivo.
5. La landing del portafolio se crea con el starter sin editar su estructura a mano; lo que falte se registra como issue del starter.
6. Repo público con tag `v0.1.0`, README, CHANGELOG, LICENSE y sin secretos ni datos personales.

**No-objetivos de la v0.1:** scaffolding de código de aplicaciones (Next.js, Odoo); crear repos remotos o usar `gh`; crear Proyectos de Claude (lo hace el Estudio); mezclar actualizaciones automáticamente (la v0.1 solo reporta diferencias); hooks post-edición; perfiles Turborepo y Python; soporte fuera de WSL2/Linux.

## 4. Requisitos

**Funcionales (historias breves)**

1. Como Adrián, ejecuto `new-project <slug> --tipo personal|work --tier N [--stack a,b]` y obtengo `~/projects/<tipo>/<slug>` con git inicializado y un primer commit.
2. El `CLAUDE.md` generado trae la metodología del Tier y los comandos del stack elegido, sin placeholders sin resolver.
3. Reviso un diseño (`/revisar-diseno`, Tier 2+) o un diff (`/revisar-diff`, Tier 1+) con un goldfish usando un solo comando.
4. `/hito N` propone el plan solo del hito N; `/cierre-hito` corre los checks, actualiza el plan y la bitácora, y no commitea.
5. `/bitacora` produce la entrada lista para `content/projects/<slug>.md` respetando la visibilidad del proyecto.
6. `starter-diff <ruta>` reporta qué archivos del proyecto divergen del starter.
7. Quien visite el repo entiende qué es y cómo usarlo en 5 minutos.

**No funcionales**

- **Entorno:** bash 5, git y coreutils (`sha256sum`, `sed`, `find`) en Ubuntu 24.04 sobre WSL2. Sin jq, Python ni Node para el generador.
- **Escritura segura:** valida todo antes de escribir, construye en un directorio temporal y lo mueve al destino. Nunca sobrescribe un destino existente.
- **Contexto:** `CLAUDE.md` de unas 60 líneas o menos en Tier 1+ (unas 10 en Tier 0). Las reglas de perfil usan `paths:` para cargar solo al leer archivos del stack.
- **Costo:** los skills de revisión corren solo por invocación explícita (`disable-model-invocation: true`).
- **Evolutividad:** semver en `VERSION`, `CHANGELOG.md` y contrato versionado (`schema=1` en el lock).
- **Privacidad:** repo público sin secretos, rutas personales ni datos de empresa.

## 5. Arquitectura y stack

El starter es un repo de bash y markdown sin dependencias, con la plantilla en capas aditivas: `new-project` las combina según Tier y stack y registra el resultado en un lock. Tier 0 usa solo `core`; Tier N suma `t1` hasta `tN`.

&#91;embedded content: generación y comparación · 4 cajas\]

`starter-diff` compara tres hashes por archivo: el del proyecto hoy (P), el del lock (L) y el del starter hoy (S).

```text
project-starter/
├── VERSION · CHANGELOG.md · README.md · LICENSE
├── CLAUDE.md                  # para trabajar EN el starter
├── bin/
│   ├── new-project            # generador
│   └── starter-diff           # compara un proyecto con el starter
├── lib/common.sh              # validación, copia, hashes, placeholders
├── template/
│   ├── core/                  # todos los Tiers: .gitignore, settings.json, brief, CLAUDE.md corto
│   ├── t1/                    # CLAUDE.md completo, spec, plan, bitacora, agente y skills
│   ├── t2/                    # docs/adr/, PRD, skill revisar-diseno
│   ├── t3/                    # CHANGELOG del proyecto y sección de gobierno
│   └── profiles/<perfil>/     # nextjs, supabase, odoo-addon: reglas con paths + comandos
├── tests/                     # smoke.sh y fixtures con defectos conocidos
└── docs/                      # dossier.md, plan.md, verificacion.md
```

| Decisión | Elegido | Alternativa descartada | Por qué |
| --- | --- | --- | --- |
| Modelo de uso | Generador + lock | Clonar por proyecto; template de GitHub | Evita historial y archivos sobrantes, permite `starter-diff` y las mejoras llegan con `git pull` |
| Lenguaje del generador | Bash puro | CLI en Python o Node | Cero dependencias en WSL. Si supera unas 300 líneas o necesita merge, migrar a Python stdlib |
| Plantilla | Capas aditivas core, t1, t2, t3 | Una carpeta completa por Tier | Un cambio se hace una vez, no cuatro |
| Comandos | Skills en `.claude/skills/<nombre>/SKILL.md` | `.claude/commands/` | La documentación vigente fusionó los comandos en skills, y los skills permiten `context: fork` y `disable-model-invocation` |
| Goldfish | Subagente `goldfish-revisor` + skills con `context: fork`; el agente usa `omitClaudeMd: true` | Pegar el prompt de la plantilla E a mano; bootstrap de terceros | Aislamiento repetible sin dependencias externas ni `gh`. Se valida en un spike del Hito 2 |
| Manifest | `.claude/starter.lock` en texto plano | `starter.json` | JSON exige jq o Python; el formato de `sha256sum` se verifica con `sha256sum -c` |
| Reglas de perfil | `.claude/rules/` con `paths:` | Reglas siempre cargadas | Las reglas con `paths` cargan solo al leer archivos que coinciden |
| Spec y plan en CLAUDE.md | Referencia por ruta | Import con `@docs/spec.md` | Los imports cargan al inicio y no reducen el contexto |
| Permisos base | `deny` de lectura de secretos + `ask` para commit y push | Sandbox desde la v0.1; `deny` total de push | Los `deny` de Read cubren las herramientas integradas, no cualquier subproceso. El sandbox se evalúa aparte (sección 9) |
| Perfiles v1 | nextjs, supabase, odoo-addon | Turborepo, Python | Entran con el primer proyecto real que los pida |
| Primer commit | Lo crea el generador | Repo sin commits | `/revisar-diff` necesita una base contra la cual comparar |

**Verificado en la documentación de Claude Code (23 nov 2026):**

- [Permisos](https://code.claude.com/docs/en/permissions): orden deny, ask, allow; sintaxis `Read(./.env)`; límites de las reglas sobre Bash y subprocesos.
- [Skills](https://code.claude.com/docs/en/skills): comandos fusionados en skills; campos `disable-model-invocation`, `context: fork` y `agent`.
- [Subagentes](https://code.claude.com/docs/en/sub-agents): carpeta `.claude/agents/`, campos `tools` y `omitClaudeMd`, contexto nuevo en cada ejecución.
- [Memoria y reglas](https://code.claude.com/docs/en/memory): `.claude/rules/` con `paths`, imports con `@` y tamaño recomendado de CLAUDE.md.

## 6. Datos e integraciones

El único dato persistente es `.claude/starter.lock` en cada proyecto generado; la v0.1 no usa base de datos, APIs ni red.

```text
# project-starter lock: no editar a mano
schema=1
starter_version=0.1.0
starter_commit=<sha corto o vacío>
slug=<slug>
tipo=personal|work
tier=1
metodologia=eg-ligero
stack=nextjs,supabase
visibilidad=publico|anonimizado|privado
generated_at=<UTC ISO 8601>
--managed--
<sha256>  .claude/agents/goldfish-revisor.md
--seeded--
<sha256>  CLAUDE.md
```

- **managed:** archivos de los que el starter es dueño (`.claude/agents/`, `.claude/skills/`, `.claude/rules/stack-*.md`). No llevan placeholders y el proyecto no los edita; si necesita variar uno, crea un archivo propio con otro nombre.
- **seeded:** archivos que nacen del starter y después son del proyecto (`CLAUDE.md`, `docs/*`, `.claude/settings.json`, `.gitignore`). `starter-diff` solo informa si la plantilla cambió.

Para cada archivo managed, `starter-diff` compara tres hashes: el del proyecto hoy (P), el del lock (L) y el del starter hoy (S).

| Estado | Condición | Acción sugerida |
| --- | --- | --- |
| limpio | P = L y S = L | Ninguna |
| desactualizado | P = L y S ≠ L | Copiar la versión nueva del starter |
| modificado | P ≠ L y S = L | Mover el cambio a un archivo propio o aceptar la divergencia |
| conflicto | P ≠ L y S ≠ L | Revisión manual |
| faltante | El archivo del lock no existe | Restaurarlo o retirarlo del lock |

**Qué no se guarda:** secretos, rutas absolutas del usuario, correos ni nombres de clientes o empresas. El lock guarda solo rutas relativas.

**Integraciones:** solo `git` local (init y primer commit) y `sha256sum`. El generador imprime el comando `git remote add` con el alias `github-personal` o `github-work`, pero no toca la red.

**Contenido inicial de `.claude/settings.json`** (seeded). El `.gitignore` generado excluye `.claude/settings.local.json`, `CLAUDE.local.md` y los `.env`, que son archivos personales o secretos.

```json
{
  "permissions": {
    "deny": ["Read(**/.env)", "Read(**/.env.local)", "Read(secrets/**)", "Read(~/.ssh/**)"],
    "ask": ["Bash(git commit *)", "Bash(git push *)"]
  }
}
```

Según la documentación, una regla `deny` siempre gana y una `ask` pregunta aunque exista un `allow` más específico. Los `deny` de lectura cubren las herramientas integradas y comandos reconocidos como `cat`, pero no un script que abra el archivo por su cuenta, y una regla de Bash no detecta formas como `git -C . push`. Son una red de seguridad, no un límite de seguridad.

## 7. Plan por hitos

Cinco hitos, de 5 a 6 sesiones de Claude Code en total. El código del Hito 1 no empieza hasta cumplir el criterio del Hito 0. Cada hito cierra con checks verdes, `CLAUDE.md` del starter actualizado y entrada de bitácora.

**Hito 0 · Contrato revisado (0,5 sesión)**

- Objetivo: confirmar que las secciones 5 y 6 bastan para implementar sin preguntas.
- Entregables: Dossier corregido y `docs/plan.md` derivado de esta sección.
- Criterio de aceptación: un goldfish que recibe solo las secciones 5 y 6 enumera los archivos de cada Tier y el algoritmo de `new-project` sin contradecir el Dossier, y cada ambigüedad de severidad alta queda resuelta.
- Riesgo: que el goldfish revise algo que el Dossier no dice. Se corrige el Dossier, no el prompt.

**Hito 1 · Generador y capas base (2 sesiones)**

- Objetivo: `new-project` funcional para Tier 0 y 1.
- Entregables: `bin/new-project`, `lib/common.sh`, capas `core` y `t1` (sin skills todavía), lock, primer commit, `tests/smoke.sh` para Tier 0 y 1 y README mínimo.
- Criterio de aceptación: `tests/smoke.sh` verde para Tier 0 y 1; un destino existente, un slug inválido y una carpeta padre inexistente terminan con error y sin escribir nada; al abrir `claude` en un proyecto generado, `/memory` lista su `CLAUDE.md`.
- Riesgo: sustitución de placeholders frágil. Smoke verifica cero `{{` restantes.

**Hito 2 · Subagente y skills (1,5 sesiones)**

- Objetivo: flujo goldfish y de cierre operativo, más las capas `t2` y `t3`.
- Entregables: `goldfish-revisor`, skills `hito`, `cierre-hito`, `revisar-diff`, `revisar-diseno` y `bitacora`, plantillas de ADR y PRD, y `tests/fixtures/` con defectos conocidos.
- Criterio de aceptación: un spike inicial confirma que `context: fork`, `agent` y la inyección del diff con `!` + comando funcionan (si no, plan B de la sección 9); sobre los fixtures, `/revisar-diff` encuentra el defecto sembrado y `/revisar-diseno` lista lo omitido; `git status` es idéntico antes y después; `/cierre-hito` no crea commits.
- Riesgo: dependen de comportamiento de Claude Code. La verificación manual queda documentada en `docs/verificacion.md`.

**Hito 3 · Perfiles y starter-diff (1 sesión)**

- Objetivo: stacks componibles y detección de divergencias.
- Entregables: perfiles `nextjs`, `supabase` y `odoo-addon` (escritos con la documentación vigente de cada uno) y `bin/starter-diff`.
- Criterio de aceptación: smoke verde en los 4 Tiers y en las combinaciones `nextjs`, `nextjs,supabase` y `odoo-addon`; `starter-diff` reporta correctamente los 5 estados de la sección 6 sobre un proyecto manipulado a propósito.
- Riesgo: los comandos de cada stack cambian. Cada perfil lleva su fecha de verificación.

**Hito 4 · Publicación y primer uso real (0,5 a 1 sesión)**

- Objetivo: repo público y probado con un proyecto real.
- Entregables: README (qué es, Tiers, uso, razón de E/G), CHANGELOG, LICENSE, tag `v0.1.0`, entrada de bitácora del propio starter y la landing del portafolio creada con `new-project`.
- Criterio de aceptación: clon limpio en un directorio temporal y quickstart del README en 3 comandos o menos; búsqueda de secretos y datos personales sin hallazgos; un goldfish con solo el README y el árbol del repo explica qué hace el starter; la landing se genera sin editar la estructura a mano.
- Riesgo: un README que solo entiende su autor. Lo cubre la revisión goldfish.

## 8. Estrategia de pruebas y verificación

Hay dos niveles: pruebas automáticas del generador, que no gastan cuota de Claude, y verificación manual de los skills sobre fixtures, que sí la gasta y queda documentada.

**Automáticas con `tests/smoke.sh`.** Genera proyectos en un `PROJECTS_ROOT` temporal (variable de entorno que `new-project` respeta; por defecto `~/projects`), así que nunca toca tus carpetas reales.

| Check | Cómo se verifica |
| --- | --- |
| Estructura por Tier | Existen los archivos esperados y no los de capas superiores (Tier 0 sin `docs/plan.md`, Tier 1 sin `docs/adr/`) |
| Placeholders | `grep -r '{{'` no devuelve nada |
| Tamaño de CLAUDE.md | Tier 0 hasta 15 líneas; Tier 1+ hasta 60 |
| Frontmatter | Cada skill y agente empieza con `---` y trae `name` y `description` |
| Lock | `sha256sum -c` sobre la sección managed pasa justo tras generar (se omite si la sección está vacía, como en Tier 0) |
| Git | `git log` tiene exactamente un commit |
| Rechazos | Destino existente, slug inválido, tipo inválido y carpeta padre inexistente terminan con código distinto de 0 y sin escribir |
| starter-diff | Limpio tras generar; detecta modificado, desactualizado, conflicto y faltante en un proyecto manipulado |

Comandos: `tests/smoke.sh` y, si está instalado, `shellcheck bin/* lib/*.sh tests/*.sh`. Criterio: salida verde en menos de 30 s.

**Manuales sobre fixtures** (se registran en `docs/verificacion.md`):

| Skill | Fixture | Resultado esperado |
| --- | --- | --- |
| `/revisar-diff 1` | Diff con un bug sembrado (un caso borde sin manejar) | El hallazgo cita el defecto; `git status` es idéntico antes y después |
| `/revisar-diseno` | Spec con una sección vacía y un criterio no medible | Lista ambas carencias |
| `/cierre-hito 1` | Proyecto con un check que falla | Informa el fallo, no marca el hito como cerrado y no crea commits |
| `/bitacora` | Proyecto anonimizado con un nombre de cliente en `docs/` | Marca el nombre y no lo incluye en la entrada |

**Qué revisa un goldfish, y cuándo:**

- Hito 0: solo las secciones 5 y 6 del Dossier, para probar que el contrato se sostiene solo.
- Al cerrar cada hito: los criterios de aceptación del hito y el `git diff`, con `/revisar-diff`.
- Antes de publicar: solo el README y el árbol del repo, para probar que se entiende en 5 minutos.

## 9. Riesgos, supuestos y preguntas abiertas

El riesgo dominante es la deriva: que Claude Code cambie sus formatos o que los proyectos generados se separen de la plantilla.

| Riesgo | Mitigación |
| --- | --- |
| Claude Code cambia formatos de skills, agentes o permisos | Verificar la documentación vigente antes de tocar esas piezas; smoke valida el frontmatter; el lock registra la versión del starter |
| El aislamiento goldfish no funciona como se documenta (`context: fork`, `omitClaudeMd`, inyección del diff) | Spike al inicio del Hito 2. Plan B: el skill pide al goldfish ejecutar `git diff` con una herramienta de solo lectura y el criterio se pega en el prompt, como en la plantilla E. Señal de alerta: el goldfish cita contexto del chat |
| Los `deny` de lectura no frenan a un subproceso arbitrario (un script que abre `.env`) | Documentarlo en el README y evaluar el sandbox de Claude Code en WSL2 como mejora |
| Alcance en el límite: de 5 a 6 sesiones estimadas | Si Alcance pasa a 2 el puntaje es 8 y sigue siendo Tier 1; si el total supera 8, se reclasifica a Tier 2 |
| Proyectos que divergen del starter | Separación managed y seeded, y `starter-diff`. Alerta: más de 3 archivos managed modificados en un proyecto |
| Repo público con datos personales | Búsqueda de secretos y de correo personal antes del tag, y revisión goldfish del árbol |
| Cuota de suscripción | Los skills de revisión corren solo por invocación explícita |

**Supuestos** (si alguno es falso, avísame y se corrige):

- Ubuntu 24.04 en WSL2 con bash 5, git y coreutils; la identidad Git cambia sola por carpeta (`includeIf`) y existen los alias `github-personal` y `github-work`.
- Tu usuario de GitHub personal es `jadriangz`; para `work` el generador imprime un marcador `<ORG>`.
- Licencia MIT.
- Documentación del starter en español; el idioma del código y los commits de cada proyecto lo define ese proyecto.
- Hoy no existe una plantilla común (sección 2).

**Preguntas abiertas:**

- [ ] ¿README en español, inglés o bilingüe? Afecta al portafolio; se decide antes del Hito 4.
- [ ] ¿Cuál es la ruta de addons de Odoo en el nuevo setup de WSL? La necesita el perfil `odoo-addon` (Hito 3).
- [ ] ¿Se habilita el sandbox de Claude Code en WSL2? Se evalúa en los Hitos 2 y 3.
- [ ] ¿Qué organización de GitHub usan los proyectos de `work`? Hasta saberlo el generador imprime un marcador.

## 10. Anexos

**A. `CLAUDE.md` del starter** (para trabajar dentro del repo; va en la raíz de `project-starter`)

```markdown
# project-starter
Generador de proyectos para Claude Code: crea ~/projects/personal|work/<slug> con docs, reglas, skills y subagente goldfish adaptados al Tier y al stack. Repo público.

## Comandos
- Generar: `bin/new-project <slug> --tipo personal|work --tier 0-3 [--stack nextjs,supabase] [--dry-run]`
- Comparar un proyecto con el starter: `bin/starter-diff <ruta-del-proyecto>`
- Test: `tests/smoke.sh` · Lint: `shellcheck bin/* lib/*.sh tests/*.sh` (si está instalado)

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
```

**B. Prompt de arranque para Claude Code** (Hitos 0 y 1)

```text
Lee CLAUDE.md y docs/dossier.md. Entra en plan mode.
1. Crea docs/plan.md a partir de la sección 7 del Dossier (estado, hitos, criterio de aceptación y checklist de tareas). No cambies los criterios.
2. Hito 0: lanza un subagente con contexto limpio y entrégale SOLO las secciones 5 y 6 del Dossier. Pídele (a) los archivos que generaría cada Tier, (b) el algoritmo de new-project paso a paso y (c) toda ambigüedad o contradicción, con severidad. Compara su respuesta con el Dossier y propón correcciones al Dossier.
3. Con el contrato aprobado, propón el plan de implementación SOLO del Hito 1: archivos a crear, orden y cómo verificarás su criterio de aceptación.
Señala cualquier ambigüedad o conflicto. No escribas código ni hagas commits hasta que apruebe el plan.
```

**C. Entrada de bitácora (borrador)** para `content/projects/project-starter.md` en el repo `portfolio`

```markdown
---
slug: project-starter
titulo: project-starter
tipo: personal
visibilidad: publico
estado: en-curso
inicio: 2026-11
fin: null
tier: 1
metodologia: eg-ligero
rol: Diseño, especificación y dirección de la construcción con Claude Code
stack: [bash, markdown, claude-code]
destacado: true
enlaces: { repo: , demo: , caso: }
---

## Problema
Cada proyecto nuevo con Claude Code obligaba a rehacer la misma estructura de contexto (CLAUDE.md, spec, plan, reglas y revisión), sin saber qué versión usaba cada proyecto.

## Enfoque (decisiones clave y por qué)
- Generador en lugar de clonar por proyecto: evita historial y archivos sobrantes, y permite comparar cada proyecto con la versión vigente.
- Plantilla en capas por Tier: un cambio se hace una vez y cada proyecto recibe solo lo que su complejidad justifica.
- Revisión goldfish como skills con contexto aislado, sin dependencias externas.
- Lock en texto plano con hashes, para detectar divergencias sin jq ni Python.

## Solución
Pendiente: se completa al cerrar los hitos.

## Cómo se usó Claude Code
Planeación en el Estudio de Proyectos (clasificación por Tier y Dossier). Construcción con E/G ligero: revisión goldfish del contrato y del diff de cada hito.

## Resultados
Sin datos todavía. Se llenarán con las métricas de la sección 3 del Dossier.

## Aprendizajes
Pendiente.
```
