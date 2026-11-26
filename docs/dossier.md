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
3. `starter-diff` distingue por archivo los 11 estados de la sección 6, entre ellos limpio, modificado en el proyecto y desactualizado frente al starter.
4. `/revisar-diseno` y `/revisar-diff` devuelven hallazgos sobre fixtures con defectos conocidos y no modifican ningún archivo.
5. El README se valida de punta a punta: en un clon limpio en un directorio temporal, siguiendo solo sus instrucciones (clonar, `new-project`, comprobar el resultado), se obtiene un proyecto válido. Cambiado en el Hito 4: antes decía "la landing del portafolio se crea con el starter"; la landing pasa a ser un proyecto propio del Estudio (sección 7).
6. Repo público con tag `v0.1.0`, README, CHANGELOG, LICENSE y sin secretos ni datos personales.

**No-objetivos de la v0.1:** scaffolding de código de aplicaciones (Next.js, Odoo); crear repos remotos o usar `gh`; crear Proyectos de Claude (lo hace el Estudio); mezclar actualizaciones automáticamente (la v0.1 solo reporta diferencias); hooks post-edición; perfiles Turborepo y Python; soporte fuera de WSL2/Linux.

## 4. Requisitos

**Funcionales (historias breves)**

1. Como Adrián, ejecuto `new-project <slug> --tipo personal|work --tier N [--stack a,b] [--visibilidad publico|anonimizado|privado]` y obtengo `~/projects/<tipo>/<slug>` con git inicializado y un primer commit.
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

El starter es un repo de bash y markdown sin dependencias. La plantilla está en capas: `new-project` combina `core`, `t1` … `tN` según el Tier, añade los perfiles del stack y registra el resultado en un lock. La v0.1 no fusiona archivos: una capa superior reemplaza el archivo de la misma ruta, y los únicos añadidos de texto son los fragmentos descritos abajo.

```text
new-project <slug> --tipo T --tier N [--stack a,b] [--visibilidad V] [--dry-run]
  │  valida todo (nada se escribe si algo falla)
  ▼
core → t1 → … → tN → perfiles        capa superior reemplaza la misma ruta; perfiles no colisionan
  │  render: fragmentos y placeholders, en un directorio temporal
  ▼
.claude/starter.lock → mv al destino → git init + primer commit → imprime `git remote add`

starter-diff <ruta>
  lee el lock → recompone el starter actual con tier y stack del lock (S) → compara P, L y S
```

```text
project-starter/
├── VERSION · CHANGELOG.md · README.md · LICENSE
├── CLAUDE.md                  # para trabajar EN el starter
├── bin/
│   ├── new-project            # generador
│   └── starter-diff           # compara un proyecto con el starter
├── lib/common.sh              # validación, composición, hashes, placeholders
├── template/
│   ├── core/                  # todos los Tiers
│   ├── t1/                    # Tier 1+
│   ├── t2/                    # Tier 2+
│   ├── t3/                    # Tier 3
│   └── profiles/<perfil>/     # nextjs, supabase, odoo-addon
├── tests/                     # smoke.sh y fixtures con defectos conocidos
└── docs/                      # dossier.md, plan.md, verificacion.md
```

**Archivos por capa** (normativo; M = managed, S = seeded, ver sección 6). Un proyecto de Tier N recibe `core` y `t1` hasta `tN`, más los perfiles de su stack.

| Capa | Ruta en el proyecto | Fuente en `template/` | Lock |
| --- | --- | --- | --- |
| core | `CLAUDE.md` (corto, unas 10 líneas) | `core/CLAUDE.md.tmpl` | S |
| core | `.gitignore` | `core/dot-gitignore` | S |
| core | `.gitattributes` (`* text=auto eol=lf`) | `core/dot-gitattributes` | S |
| core | `.claude/settings.json` | `core/dot-claude/settings.json` | S |
| core | `docs/brief.md` | `core/docs/brief.md` | S |
| t1 | `CLAUDE.md` (completo, reemplaza al de core) | `t1/CLAUDE.md.tmpl` | S |
| t1 | `docs/spec.md`, `docs/plan.md`, `docs/bitacora.md` | `t1/docs/…` | S |
| t1 | `.claude/agents/goldfish-revisor.md` | `t1/dot-claude/agents/…` | M |
| t1 | `.claude/skills/{hito,cierre-hito,revisar-diff,bitacora}/SKILL.md` | `t1/dot-claude/skills/…` | M |
| t2 | `docs/prd.md`, `docs/adr/0000-plantilla.md` | `t2/docs/…` | S |
| t2 | `.claude/skills/revisar-diseno/SKILL.md` | `t2/dot-claude/skills/…` | M |
| t3 | `CHANGELOG.md` | `t3/CHANGELOG.md` | S |
| t3 | Sección de gobierno dentro de `CLAUDE.md` (no es archivo) | `t3/_fragmentos/gobierno.md` | (en `CLAUDE.md`) |
| perfil `p` | `.claude/rules/stack-p.md` (con `paths:`) | `profiles/p/dot-claude/rules/stack-p.md` | M |
| perfil `p` | Comandos del stack dentro de `CLAUDE.md`, solo Tier 1+ | `profiles/p/_fragmentos/comandos.md` | (en `CLAUDE.md`) |

Además se genera `.claude/starter.lock`, que no se lista a sí mismo. Un perfil solo puede aportar su regla y su fragmento. El `CLAUDE.md` de core no referencia archivos que Tier 0 no tiene (`docs/spec.md`, `docs/plan.md`). Los nombres del agente y de los skills son contrato, y todos los skills llevan `disable-model-invocation: true`. Frontmatter validado en el spike del Hito 2:
- **agente:** `tools: Read, Grep, Glob` (sin Bash) y `omitClaudeMd: true`;
- **`revisar-diff` y `revisar-diseno`:** `context: fork`, `agent: goldfish-revisor` y `background: false`;
- **`allowed-tools`:** solo reglas exactas, sin comodín, para los comandos `!` (por ejemplo `Bash(git diff HEAD)`). Una regla con prefijo como `Bash(sed -n *)` preaprueba también `sed -n -i`, que escribe (sección 5, Verificado). Lo que no es un comando `!` se lee con Read y Grep, que no necesitan preaprobación.

Los managed no se renderizan, así que los skills leen del lock los datos del proyecto que necesitan (por ejemplo, la visibilidad).

**Reglas de composición**

- **Destino:** `$PROJECTS_ROOT/<tipo>/<slug>`. `PROJECTS_ROOT` es una variable de entorno, con `~/projects` por defecto. La carpeta padre `$PROJECTS_ROOT/<tipo>` debe existir; el generador no la crea.
- **Rutas:** la ruta dentro de la capa es la ruta en el proyecto, con dos transformaciones: un segmento `dot-x` pasa a `.x` y el sufijo `.tmpl` se quita. Así la plantilla no contiene `.claude/`, `.gitignore` ni `CLAUDE.md` reales, que Claude Code y git aplicarían al propio repo del starter.
- **Colisiones:** entre capas, la superior reemplaza el archivo completo. Una ruta repetida entre perfiles, entre un perfil y una capa, o dentro de una misma capa (por ejemplo `CLAUDE.md` y `CLAUDE.md.tmpl`), termina con error. Un `.claude/`, `.gitignore` o `CLAUDE.md` real dentro de `template/` también es error.
- **Fragmentos:** los directorios `_fragmentos/` no se copian. Una línea cuyo único contenido es exactamente `{{GOBIERNO}}` o `{{COMANDOS_STACK}}`, sin espacios alrededor (C17), se sustituye por el fragmento correspondiente (los de comandos, concatenados en el orden normalizado de `stack`, sin separador); si no hay fragmento, la línea se elimina. Ambas líneas están solo en `t1/CLAUDE.md.tmpl`; `core/CLAUDE.md.tmpl` no las contiene, y por eso Tier 0 no recibe comandos ni gobierno.
- **Placeholders:** sintaxis `{{NOMBRE}}`, con `NOMBRE` en `[A-Z_]+`. Variables: `SLUG`, `TIPO`, `TIER`, `METODOLOGIA`, `STACK` (vacío si no hay stack), `VISIBILIDAD` y `FECHA` (`YYYY-MM-DD`, UTC, del mismo instante que `generated_at`). Se renderizan todos los seeded: primero se insertan los fragmentos y después se resuelven los placeholders. `.tmpl` solo sirve para ocultar archivos a Claude Code y no indica qué se renderiza. Un managed que contenga `{{` es error al componer; un `{{` que quede tras el render es error.
- **Metodología:** se deriva del Tier: 0 → `ninguna`, 1 → `eg-ligero`, 2 y 3 → `eg`.
- **Visibilidad:** `--visibilidad publico|anonimizado|privado`. Por defecto, `personal` → `publico` y `work` → `privado`. En la v0.1 solo se registra en el lock; la usa `/bitacora`.

**Algoritmo de `new-project`**

1. Leer argumentos: `<slug>`, `--tipo` y `--tier` obligatorios; `--stack`, `--visibilidad` y `--dry-run` opcionales. Una opción desconocida es error.
2. Validar sin escribir nada:
   - slug con `^[a-z0-9]+(-[a-z0-9]+)*$` y 64 caracteres como máximo;
   - `tipo` en {personal, work}; `tier` en {0, 1, 2, 3}; `visibilidad` en {publico, anonimizado, privado};
   - `stack` separado por comas; cada perfil cumple la misma regex del slug y existe en `template/profiles/`; se pasa a minúsculas antes de validar y se normaliza (orden `LC_ALL=C`, sin duplicados) y esa forma se usa en todo: lock, `{{STACK}}` y orden de fragmentos;
   - existen `git` (2.28 o superior, por `init -b`) y `sha256sum`; existe la carpeta padre; no existe el destino.
3. Componer la lista de fuentes (capas y perfiles) aplicando las reglas de rutas y colisiones, y comprobar que ningún managed contiene `{{`. Hasta aquí no se ha escrito nada.
4. Crear un directorio temporal con `mktemp -d` dentro de la carpeta padre (con `--dry-run`, en `$TMPDIR`) y registrar su borrado con `trap`. Desde aquí, cualquier error borra el temporal y deja el disco como estaba.
5. Escribir cada archivo: los seeded con fragmentos y placeholders resueltos; los managed, copiados sin cambios.
6. Escribir `.claude/starter.lock` (sección 6).
7. Con `--dry-run`: imprimir la lista de rutas (ordenada) y el lock, borrar el temporal y salir con 0.
8. Ajustar los permisos del temporal según la umask (`mktemp -d` lo crea con 0700), volver a comprobar que el destino no existe y moverlo con `mv -T`. Límite conocido: un directorio vacío creado justo entre la comprobación y el `mv` sería reemplazado.
9. En el destino: `git init -b main`, `git add -A -f` (para que un `core.excludesFile` global no deje fuera archivos generados) y un commit con el mensaje `chore: proyecto generado por project-starter v<VERSION>`. El commit se hace después de mover porque la identidad de git depende de `includeIf gitdir:` sobre la ruta final. Si `git` falla, el árbol no queda limpio tras el commit o la ejecución se interrumpe antes del commit, se borra el destino que creó esta misma ejecución y se sale con error.
10. Imprimir `git remote add origin git@github-<tipo>:<OWNER>/<slug>.git`, donde `github-<tipo>` es el alias de host de SSH y `OWNER` es `jadriangz` en `personal`; en `work` es el valor de la variable de entorno `STARTER_WORK_OWNER` o, si no existe, el literal `<ORG>` (el repo es público y no guarda el nombre de la organización). No toca la red.

Los errores van a stderr y terminan con código distinto de 0. Las opciones se escriben como `--opcion valor`.

| Decisión | Elegido | Alternativa descartada | Por qué |
| --- | --- | --- | --- |
| Modelo de uso | Generador + lock | Clonar por proyecto; template de GitHub | Evita historial y archivos sobrantes, permite `starter-diff` y las mejoras llegan con `git pull` |
| Lenguaje del generador | Bash puro | CLI en Python o Node | Cero dependencias en WSL. Si supera unas 300 líneas o necesita fusionar archivos, migrar a Python stdlib |
| Plantilla | Capas core, t1, t2, t3 con reemplazo por ruta y fragmentos | Una carpeta completa por Tier | Un cambio se hace una vez, no cuatro |
| Comandos | Skills en `.claude/skills/<nombre>/SKILL.md` | `.claude/commands/` | La documentación vigente fusionó los comandos en skills, y los skills permiten `context: fork` y `disable-model-invocation` |
| Goldfish | Subagente `goldfish-revisor` + skills con `context: fork`; el agente usa `omitClaudeMd: true` | Pegar el prompt de la plantilla E a mano; bootstrap de terceros | Aislamiento repetible sin dependencias externas ni `gh`. Se valida en un spike del Hito 2 |
| Manifest | `.claude/starter.lock` en texto plano | `starter.json` | JSON exige jq o Python; la sección managed usa el formato de `sha256sum` y se verifica con `sha256sum -c` |
| Reglas de perfil | `.claude/rules/` con `paths:` | Reglas siempre cargadas | Las reglas con `paths` cargan solo al leer archivos que coinciden |
| Comandos del stack | Fragmento en `CLAUDE.md` (Tier 1+) | Skills por perfil | Son pocas líneas de contexto y no justifican un skill |
| Spec y plan en CLAUDE.md | Referencia por ruta | Import con `@docs/spec.md` | Los imports cargan al inicio y no reducen el contexto |
| Permisos base | `deny` de lectura de secretos + `ask` para commit y push | Sandbox desde la v0.1; `deny` total de push | Los `deny` de Read cubren las herramientas integradas, no cualquier subproceso. El sandbox se evalúa en la v0.2 (sección 9) |
| Perfiles v1 | nextjs, supabase, odoo-addon | Turborepo, Python | Entran con el primer proyecto real que los pida |
| Primer commit | Lo crea el generador, después de mover | Repo sin commits; commit en el temporal | `/revisar-diff` necesita una base; la identidad de git depende de la ruta final |

**Verificado en la documentación de Claude Code (23 nov 2026):**

- [Permisos](https://code.claude.com/docs/en/permissions): orden deny, ask, allow; sintaxis `Read(./.env)`; límites de las reglas sobre Bash y subprocesos.
- [Skills](https://code.claude.com/docs/en/skills): comandos fusionados en skills; campos `disable-model-invocation`, `context: fork` y `agent`.
- [Subagentes](https://code.claude.com/docs/en/sub-agents): carpeta `.claude/agents/`, campos `tools` y `omitClaudeMd`, contexto nuevo en cada ejecución.
- [Memoria y reglas](https://code.claude.com/docs/en/memory): `.claude/rules/` con `paths`, imports con `@` y tamaño recomendado de CLAUDE.md.
- [Permisos](https://code.claude.com/docs/en/permissions), inicio del Hito 1: las reglas `Read` usan sintaxis gitignore relativa al directorio actual; según la página, `Read(.env)` y `Read(**/.env)` equivalen y casan cualquier `.env` en la raíz o por debajo. **Prueba empírica (Hito 2, Claude Code 2.1.330, detalle en `docs/verificacion.md`):** con el `deny` de la sección 6 y un `allow` explícito de Read, Write, Edit y `Bash(cat *)`, Claude no pudo leer `.env` ni `.env.example`, ni hacer `cat .env.example`, ni editar o reescribir `.env.example`, ni crear `.env.local`; escribir `otro.txt` sí funcionó. Coincide con la página: "A `Read` deny rule also blocks the Edit and Write tools on the same path, including creating a new file there".
- [Permisos](https://code.claude.com/docs/en/permissions): `Bash(git commit *)` sí cubre `git commit` sin argumentos ("A `*` at the end, with a space before it, also matches the bare command"), siempre que el `*` final sea el único comodín.
- [Memoria](https://code.claude.com/docs/en/memory) y [Skills](https://code.claude.com/docs/en/skills): los `CLAUDE.md` de subdirectorios y los skills de `<subdir>/.claude/skills/` se cargan bajo demanda cuando Claude lee o edita un archivo de ese subárbol. Un `template/t1/CLAUDE.md` o un `template/t1/.claude/skills/` reales se inyectarían en las sesiones de trabajo sobre el starter, lo que confirma `dot-` y `.tmpl`. Los `settings.json` anidados no se aplican (solo el del directorio de trabajo).

**Verificado en el Hito 2 (23 nov 2026, Claude Code 2.1.330; [Skills](https://code.claude.com/docs/en/skills), [Subagentes](https://code.claude.com/docs/en/sub-agents) y spike en `docs/verificacion.md`):**

- `context: fork` con `agent: goldfish-revisor` ejecuta el cuerpo del skill en ese agente, sin el historial de la conversación. El spike lo confirmó con un canario sembrado en el chat que el agente no vio.
- Los skills con fork corren en segundo plano por defecto (`background: true`). Con `background: false`, el resultado vuelve en el mismo turno.
- `` !`cmd` `` se ejecuta antes de enviar el skill al modelo, también dentro de un bloque de código y con `$0` sustituido en el comando. Cada comando se evalúa contra los permisos antes de renderizar: si el resultado no es "allow" (por `allowed-tools` o por una regla `allow`), o si casa un `deny` o un `ask`, se aborta la invocación sin preguntar. Una salida distinta de 0 también la aborta.
- `omitClaudeMd: true` (desde 2.1.271) omite los `CLAUDE.md` de usuario, proyecto y local. El spike lo confirmó con un canario en `CLAUDE.md`.
- `disable-model-invocation: true` impide que Claude invoque el skill, incluso desde otro skill. Por eso `/cierre-hito` pide al usuario `/revisar-diff N` en lugar de invocarlo.
- `allowed-tools` **preaprueba, no restringe**: "It does not restrict which tools are available: every tool remains callable". La concesión dura el turno que invoca el skill ("The grant clears when you send your next message"), y un `deny` o `ask` de settings sigue ganando. No da herramientas al agente de un skill con fork: el agente conserva las de su archivo. Para quitar herramientas existe `disallowed-tools`.
- **Prueba empírica de `allowed-tools`** (detalle en `docs/verificacion.md`). Con `Bash(sed -n *) Bash(git diff *)` en un skill, Claude ejecutó sin preguntar `sed -n -i '1p' a.txt`, que truncó el archivo, y `git diff --no-index --output=salida.txt …`, que creó un archivo. Sin el skill, el mismo `sed -n -i` pidió aprobación. Una regla con prefijo se salta la detección de comandos que escriben; una regla sin `*` casa solo el comando exacto ("A rule with no `*` matches one exact command").
- Los skills no aceptan `tools` ni `permissionMode`: la restricción de solo lectura va en el agente.

**Verificado para los perfiles (Hito 3, 23 nov 2026).** Cada viñeta de las reglas sale de estas páginas; lo que no se pudo leer textual quedó fuera (por ejemplo, los scripts que crea `create-next-app` y el retiro de `attrs` en Odoo):

- **nextjs**, Next.js 16 (16.4 estable): [guía de actualización a 16](https://nextjs.org/docs/app/guides/upgrading/version-16) (APIs asíncronas, `proxy.ts`, retiro de `next lint`, Turbopack por defecto, Node 20.9), [Server and Client Components](https://nextjs.org/docs/app/getting-started/server-and-client-components) y [CLI `next`](https://nextjs.org/docs/app/api-reference/cli/next) (`typegen`).
- **supabase**, CLI v3 (2 nov 2026): [changelog de la v3](https://supabase.com/changelog/supabase-cli-v3) (local por defecto, `--remote`, confirmaciones), [migraciones](https://supabase.com/docs/guides/deployment/database-migrations), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [generar tipos](https://supabase.com/docs/guides/api/rest/generating-types) y [Next.js con `@supabase/ssr`](https://supabase.com/docs/guides/auth/server-side/nextjs).
- **odoo-addon**, Odoo 19.0 y 20.0 (20.0 salió en sept. 2026): CLI (`scaffold`, `--addons-path`, `--test-tags`), coding guidelines, arquitectura de vistas (`<list>`, antes `<tree>`), testing y el tutorial de seguridad, leídos en ambas versiones. Diferencia que entra en la regla: los permisos van en `security/ir.model.access.csv` en 19.0 y en `security/ir.access.csv` (modelo `ir.access`) en 20.0. Python: 3.10+ en 19.0 y 3.12+ en 20.0.
- [Memoria y reglas](https://code.claude.com/docs/en/memory): `paths` acepta una lista YAML de globs (con llaves); una regla con `paths` se carga cuando Claude lee, escribe o edita un archivo que casa.

## 6. Datos e integraciones

El único dato persistente es `.claude/starter.lock` en cada proyecto generado; la v0.1 no usa base de datos, APIs ni red. Ejemplo abreviado para un Tier 1 con stack (se omiten entradas y los hashes, de 64 caracteres hexadecimales, se acortan):

```text
# project-starter lock: editar solo las entradas, nunca la cabecera
schema=1
starter_version=0.1.0
starter_commit=4efe395a1b2c
slug=landing
tipo=personal
tier=1
metodologia=eg-ligero
stack=nextjs,supabase
visibilidad=publico
generated_at=2026-11-23T18:04:00Z
--managed--
9f2c…  .claude/agents/goldfish-revisor.md
1a7e…  .claude/rules/stack-nextjs.md
--seeded--
c41b…  .claude/settings.json
77d0…  CLAUDE.md
```

**Gramática del lock**

- Texto UTF-8 con finales de línea LF. La primera línea es el comentario literal `# project-starter lock: editar solo las entradas, nunca la cabecera`; solo se permiten comentarios `#` antes de `schema`.
- Cabecera `clave=valor` con estas claves y en este orden: `schema`, `starter_version`, `starter_commit`, `slug`, `tipo`, `tier`, `metodologia`, `stack`, `visibilidad`, `generated_at`. Con `schema=1`, una clave desconocida, faltante, repetida o fuera de orden es error. `--managed--` va antes de `--seeded--`.
- `starter_commit`: `git rev-parse --short=12 HEAD` del starter, con el sufijo `-dirty` si `template/`, `lib/`, `bin/` o `VERSION` tienen cambios sin commitear, incluidos archivos sin seguimiento o ignorados (C18); vacío si el starter no es un repo git.
- `stack`: perfiles en minúsculas, ordenados y sin duplicados, separados por comas; `stack=` si no hay ninguno.
- `generated_at`: `YYYY-MM-DDTHH:MM:SSZ`, en UTC.
- Los marcadores `--managed--` y `--seeded--` se escriben siempre, aunque su sección quede vacía (Tier 0 sin perfiles no tiene managed).
- Cada entrada es `<sha256>  <ruta relativa>` (dos espacios), ordenadas por ruta con `LC_ALL=C`. Las rutas no contienen espacios, barras invertidas ni saltos de línea.

**Managed y seeded** (los patrones de esta sección son normativos; la columna "Lock" de la tabla de la sección 5 es descriptiva y smoke comprueba que coinciden, C13)

- **managed:** las rutas que casan con `.claude/agents/**`, `.claude/skills/**` o `.claude/rules/stack-*.md`. El starter es su dueño: no llevan placeholders y el proyecto no los edita. Si necesita variar uno, crea un archivo propio con otro nombre (un skill con otro nombre es un comando adicional; una regla con otro nombre se carga junto a la original). Su hash es el del archivo copiado, idéntico al de su fuente.
- **seeded:** todo lo demás (`CLAUDE.md`, `docs/**`, `.claude/settings.json`, `.gitignore`, `.gitattributes`, `CHANGELOG.md`). Nacen del starter y después son del proyecto. Su hash es el **del archivo de plantilla sin renderizar** (la fuente que ganó la composición), así que no coincide con el archivo del proyecto. Límite conocido: un cambio en un fragmento no cambia el hash del `CLAUDE.md` de plantilla.

`sha256sum -c` se aplica solo a la sección managed, desde la raíz del proyecto. Con la sección vacía, `sha256sum -c` falla con una entrada vacía, así que la verificación se omite y se da por aprobada:

```bash
m=$(sed -n '/^--managed--$/,/^--seeded--$/{/^--/d;p}' .claude/starter.lock)
[ -z "$m" ] || printf '%s\n' "$m" | sha256sum -c
```

**starter-diff.** S se calcula componiendo las capas del starter actual con el `tier` y el `stack` del lock. Para cada archivo managed compara el hash del proyecto hoy (P), el del lock (L) y el del starter hoy (S). Los estados se evalúan en el orden de la tabla y gana el primero que se cumple:

| Estado | Condición | Acción sugerida |
| --- | --- | --- |
| faltante | La ruta del lock no existe en el proyecto | Restaurarla o retirar su entrada del lock |
| retirado | La ruta del lock ya no existe en el starter | Decidir si se conserva como archivo propio y retirar la entrada |
| limpio | P = L y S = L | Ninguna |
| desactualizado | P = L y S ≠ L | Copiar la versión nueva del starter |
| actualizado-sin-registrar | P = S y S ≠ L | Actualizar la entrada del lock |
| modificado | P ≠ L y S = L | Mover el cambio a un archivo propio o aceptar la divergencia |
| conflicto | P ≠ L, S ≠ L y P ≠ S | Revisión manual |
| nuevo-en-starter | La composición actual tiene una ruta managed que el lock no lista | Copiarla y añadir su entrada |

Para los seeded solo compara L con S y reporta tres estados: `faltante` (la ruta del lock no existe en el proyecto), `plantilla-sin-cambios` (S = L) y `plantilla-cambió` (S ≠ L). En la v0.1 no se reportan `retirado` ni `nuevo-en-starter` para seeded (ver riesgos en la sección 9).

En total, `starter-diff` tiene **11 estados**: 8 managed y 3 seeded.

Detalles decididos en el Hito 3 (sección 9):
- **Perfil retirado (C10):** si un perfil del lock ya no existe, S se compone sin él, se avisa en stderr y sus managed salen como `retirado`.
- **Segunda pasada (C14):** las rutas managed de S que el lock no lista se evalúan aparte. Si no existen en el proyecto, `nuevo-en-starter`; si existen, `actualizado-sin-registrar` cuando P = S y `conflicto` cuando P ≠ S.
- **Seeded fuera del starter:** una ruta seeded del lock que ya no está en S se reporta como `plantilla-cambió`, con la nota "ya no está en el starter" (C12).
- **Enlaces y directorios:** `starter-diff` solo lee archivos regulares dentro del proyecto. Un enlace simbólico o un directorio en una ruta managed da `conflicto` sin leerlo, y un lock que no es un archivo regular dentro del proyecto es error. El lock también es inválido si su `stack` no está normalizado o si una ruta está en la sección que no le corresponde según los patrones.
- **Solo lectura:** `starter-diff` no escribe nada. Para cada estado que toca el lock imprime la línea exacta (`lock: <sha256>  <ruta>` para añadir o cambiar, o `lock: quitar la línea de <ruta>`) y la persona edita el lock.
- **Salida y código:** una línea `<clase>  <estado>  <ruta>` por archivo, ordenada por clase y ruta, con la acción sugerida debajo de cada estado no limpio, y un resumen con el conteo por estado. Sale con 0 si completó el reporte, haya o no divergencias, y con 1 ante un error (proyecto o lock inexistente, lock inválido, ruta del lock absoluta o con `..`).

**Qué no se guarda:** secretos, rutas absolutas del usuario, correos ni nombres de clientes o empresas. El lock guarda solo rutas relativas.

**Integraciones:** solo `git` local (init y primer commit), `sha256sum` y coreutils con `sed`. El generador imprime el comando `git remote add` descrito en la sección 5, pero no toca la red.

**Contenido inicial de `.claude/settings.json`** (seeded). El `.gitignore` generado excluye `.claude/settings.local.json`, `CLAUDE.local.md`, `secrets/` y los `.env` (`.env` y `.env.*`, con la excepción `!.env.example`, que se versiona como plantilla de variables sin secretos; C22), que son archivos personales o secretos.

```json
{
  "permissions": {
    "deny": ["Read(**/.env)", "Read(**/.env.*)", "Read(secrets/**)", "Read(~/.ssh/**)"],
    "ask": ["Bash(git commit *)", "Bash(git push *)"]
  }
}
```

Según la documentación, una regla `deny` siempre gana y una `ask` pregunta aunque exista un `allow` más específico. Los `deny` de lectura cubren las herramientas integradas y comandos reconocidos como `cat`, pero no un script que abra el archivo por su cuenta, y una regla de Bash no detecta formas como `git -C . push`. Son una red de seguridad, no un límite de seguridad. Verificado en el Hito 2: `Read(**/.env.*)` bloquea `.env.example` para leer, editar y crear, y también `cat` por Bash. Claude no puede mantener `.env.example`. Decidido (sección 9): se mantiene así; lo mantiene la persona, y el `CLAUDE.md` generado pide a Claude indicar la línea exacta de cada variable nueva.

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
- Estado: Cerrado (23 nov 2026, commit `854f76a`).

**Hito 2 · Subagente y skills (1,5 sesiones)**

- Objetivo: flujo goldfish y de cierre operativo, más las capas `t2` y `t3`.
- Entregables: `goldfish-revisor`, skills `hito`, `cierre-hito`, `revisar-diff`, `revisar-diseno` y `bitacora`, plantillas de ADR y PRD, y `tests/fixtures/` con defectos conocidos.
- Criterio de aceptación: un spike inicial confirma que `context: fork`, `agent` y la inyección del diff con `!` + comando funcionan (si no, plan B de la sección 9); sobre los fixtures, `/revisar-diff` encuentra el defecto sembrado y `/revisar-diseno` lista lo omitido; `git status` es idéntico antes y después; `/cierre-hito` no crea commits.
- Riesgo: dependen de comportamiento de Claude Code. La verificación manual queda documentada en `docs/verificacion.md`.
- Estado: Cerrado (23 nov 2026, commit `7bd2fb6`).

**Hito 3 · Perfiles y starter-diff (1 sesión)**

- Objetivo: stacks componibles y detección de divergencias.
- Entregables: perfiles `nextjs`, `supabase` y `odoo-addon` (escritos con la documentación vigente de cada uno) y `bin/starter-diff`.
- Criterio de aceptación: smoke verde en los 4 Tiers y en las combinaciones `nextjs`, `nextjs,supabase` y `odoo-addon`; sobre un proyecto manipulado a propósito, `starter-diff` reporta cada uno de los 11 estados de la sección 6 al menos una vez y con la clasificación correcta: 8 managed (faltante, retirado, limpio, desactualizado, actualizado-sin-registrar, modificado, conflicto, nuevo-en-starter) y 3 seeded (faltante, plantilla-sin-cambios, plantilla-cambió).
- Riesgo: los comandos de cada stack cambian. Cada perfil lleva su fecha de verificación.
- Estado: Cerrado (23 nov 2026, commit `df56317`). La prueba manual de carga de reglas pasó: en un proyecto con `--stack nextjs`, `stack-nextjs.md` se carga solo al leer archivos de `app/`.

**Hito 4 · Publicación y primer uso real (0,5 a 1 sesión)**

- Objetivo: repo público y probado con un proyecto real.
- Entregables: README (qué es, Tiers, uso, razón de E/G), CHANGELOG, LICENSE, tag `v0.1.0` y entrada de bitácora del propio starter.
- Criterio de aceptación: clon limpio en un directorio temporal y quickstart del README en 3 comandos o menos; búsqueda de secretos y datos personales en todo el historial de git sin hallazgos; un goldfish con solo el README y el árbol del repo explica qué hace el starter; el README se valida de punta a punta, siguiendo solo sus instrucciones en el clon temporal (clonar, `new-project` y comprobar el resultado).
- Riesgo: un README que solo entiende su autor. Lo cubre la revisión goldfish.
- Cambio de criterio (inicio del Hito 4): sale "la landing se genera sin editar la estructura a mano" y entra la validación del README de punta a punta. Razón: la landing merece su propio Dossier y su clasificación en el Estudio; meterla aquí mezclaría dos proyectos y dejaría el cierre de la v0.1 sujeto a otro. La landing es el siguiente paso, fuera del Hito 4, y se generará después con `new-project`.
- Estado: Cerrado (23 nov 2026, commit `798ed25`, tag `v0.1.0`). El repo es público y el tag está publicado en GitHub. Releases está deshabilitado en el repo por decisión de Adrián, así que la versión publicada es el tag, no una release.

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
| starter-diff | Limpio tras generar; detecta cada estado de la sección 6 en un proyecto manipulado |

Comandos: `tests/smoke.sh` y, si está instalado, `shellcheck bin/* lib/*.sh tests/*.sh`. Criterio: salida verde en menos de 30 s.

**Manuales sobre fixtures** (cada caso se prepara con `tests/fixtures/preparar.sh <caso>` y se registra en `docs/verificacion.md`):

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
| El aislamiento goldfish no funciona como se documenta (`context: fork`, `omitClaudeMd`, inyección del diff) | Spike hecho al inicio del Hito 2: las cuatro piezas funcionan y no se aplicó el Plan B (`docs/verificacion.md`). Plan B, si una versión futura lo rompe: el skill pide al goldfish ejecutar `git diff` con una herramienta de solo lectura y el criterio se pega en el prompt, como en la plantilla E. Señal de alerta: el goldfish cita contexto del chat. Repetir el spike al cambiar de versión mayor de Claude Code |
| Los `deny` de lectura no frenan a un subproceso arbitrario (un script que abre `.env`) | Documentado en el README (Hito 4). El sandbox de Claude Code en WSL2 se evalúa en la v0.2 |
| Alcance en el límite: de 5 a 6 sesiones estimadas | Si Alcance pasa a 2 el puntaje es 8 y sigue siendo Tier 1; si el total supera 8, se reclasifica a Tier 2 |
| Proyectos que divergen del starter | Separación managed y seeded, y `starter-diff`. Alerta: más de 3 archivos managed modificados en un proyecto |
| Repo público con datos personales | Búsqueda de secretos y de correo personal antes del tag, y revisión goldfish del árbol |
| Cuota de suscripción | Los skills de revisión corren solo por invocación explícita |
| Un `{{` literal en una plantilla seeded (por ejemplo, en un bloque de código) hace fallar la generación, porque cualquier `{{` restante tras el render es error (goldfish Hito 0, C16) | No escribir `{{` en las plantillas; smoke genera todos los Tiers y lo detectaría. Si se necesita, se define un escape en una versión posterior |
| Los seeded que el starter añade o retira después de generar un proyecto no se reportan: `starter-diff` solo da `retirado` y `nuevo-en-starter` para managed (C12) | Anotarlo en `CHANGELOG.md` cuando cambie la lista de seeded, para revisar a mano los proyectos existentes |
| `git` falla en el primer commit (`commit.gpgsign` sin agente de firma, identidad ausente porque `includeIf` no aplica) y el generador borra el destino (C20) | El mensaje de error nombra estas dos causas probables y los comandos para comprobarlas. **Aplicado en el Hito 2:** la pista es `git config --global --get-regexp '^includeif'` (y `git config --global --show-origin commit.gpgsign`), porque las reglas `includeIf gitdir:` solo se evalúan dentro de un repo y, cuando se muestra la pista, el destino ya se borró. Smoke comprueba la pista |

**Supuestos** (si alguno es falso, avísame y se corrige):

- Ubuntu 24.04 en WSL2 con bash 5, git y coreutils; la identidad Git cambia sola por carpeta (`includeIf`) y existen los alias `github-personal` y `github-work`.
- Tu usuario de GitHub personal es `jadriangz`; para `work` el generador usa `STARTER_WORK_OWNER` o, si no existe, imprime el marcador `<ORG>`.
- Licencia MIT (confirmada en el Hito 4).
- Documentación del starter en español; el idioma del código y los commits de cada proyecto lo define ese proyecto.
- Hoy no existe una plantilla común (sección 2).

**Preguntas abiertas:**

- [x] ¿README en español, inglés o bilingüe? Afecta al portafolio; se decide antes del Hito 4. **Decidido (Hito 4):** español, coherente con `docs/`, skills y plantillas, con un resumen breve en inglés al inicio (qué es y quickstart). Un solo archivo que mantener.
- [x] ¿Cuál es la ruta de addons de Odoo en el nuevo setup de WSL? La necesita el perfil `odoo-addon` (Hito 3). **Decidido (Hito 3):** el starter no guarda ninguna ruta. La raíz del proyecto generado es el directorio de addons (un módulo por carpeta, `<raíz>/<modulo>/`), y los comandos del perfil usan `$ODOO_BIN` y `--addons-path="$ODOO_ADDONS_PATH,."`, variables que la persona define en su entorno. El perfil es agnóstico de versión: solo lleva convenciones vigentes en 19.0 y 20.0, y la versión concreta sale del `version` de `__manifest__.py`.
- [x] ¿Se habilita el sandbox de Claude Code en WSL2? No se evaluó en el Hito 2 ni entra en el Hito 3. **Decidido (Hito 4):** no entra en la v0.1; se evalúa en la v0.2. Habilitarlo cambia el `settings.json` generado (contrato), exige verificar la documentación vigente y probarlo en WSL2. Mientras tanto, el README documenta que los `deny` de lectura no frenan a un subproceso.
- [x] ¿Debe Claude poder mantener `.env.example`? **Decidido (Hito 2):** no; se mantiene el `deny` actual. El `CLAUDE.md` generado (core y t1) lleva la convención: Claude no edita `.env.example` y, si añade una variable de entorno, indica la línea exacta para que la persona la añada.
- [x] ¿Qué organización de GitHub usan los proyectos de `work`? **Decidido (Hito 4):** no se escribe en el repo. Se da con `STARTER_WORK_OWNER` en el entorno de cada persona (por ejemplo, en `~/.bashrc`), y sin ella el generador imprime `<ORG>`. El README lo documenta.
- [x] ¿Cómo se registra en el lock una actualización aceptada (estados actualizado-sin-registrar, retirado y nuevo-en-starter)? ¿Un modo de `starter-diff` o edición manual de las entradas? Se decide en el Hito 3, junto con dos detalles de `starter-diff` que salieron en la revisión goldfish del Hito 0: un perfil retirado del starter debe dar `retirado` y no un error (C10); y `nuevo-en-starter` se evalúa en una pasada aparte, y si la ruta ya existe en el proyecto se reporta como conflicto (C14). **Decidido (Hito 3):**
  - **Aceptación:** manual. `starter-diff` es de solo lectura e imprime la línea exacta del lock que hay que añadir, cambiar o quitar; la persona edita el lock. No cambia el contrato.
  - **C10:** si un perfil del lock ya no existe en `template/profiles/`, `starter-diff` compone S sin él, avisa en stderr y sus managed salen como `retirado`.
  - **C14:** `nuevo-en-starter` se evalúa en una segunda pasada. Si la ruta ya existe en el proyecto, P = S da `actualizado-sin-registrar` y P ≠ S da `conflicto`. Siguen siendo 11 estados.
- [x] ¿Cuál manda si difieren: los patrones de managed de la sección 6 o la columna "Lock" de la tabla de archivos por capa de la sección 5? (C13). **Decidido (Hito 1):** los patrones son normativos y la tabla descriptiva; smoke lleva la tabla esperada y comprueba que la clasificación por patrón coincide.
- [x] ¿Se toleran espacios alrededor de `{{GOBIERNO}}` y `{{COMANDOS_STACK}}` en su línea? (C17). **Decidido (Hito 1):** no; la línea debe ser exactamente el marcador. Con espacios no es fragmento, queda un `{{` y la generación falla.
- [x] ¿`starter_commit` debe marcarse `-dirty` también por cambios en `lib/` y `bin/`? (C18). **Decidido (Hito 1):** sí; `-dirty` si `template/`, `lib/`, `bin/` o `VERSION` tienen cambios sin commitear, incluidos archivos sin seguimiento o ignorados (un ignorado en `template/` se copiaría sin publicarse). Cambios en `docs/` o `tests/` no cuentan.
- [x] ¿Qué patrones exactos de `.env` lleva el `.gitignore` generado, y se ignora `.env.example`? (C22). **Decidido (Hito 1):** `.env`, `.env.*` y `!.env.example`; el ejemplo se versiona. El `deny` de `settings.json` no cambia: Claude no lee `.env.example` salvo que el proyecto lo permita.

## 10. Anexos

**A. `CLAUDE.md` del starter** (para trabajar dentro del repo; va en la raíz de `project-starter`)

```markdown
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
```

**B. Prompt de arranque para Claude Code** (Hitos 0 y 1)

```text
Lee CLAUDE.md y docs/dossier.md. Entra en plan mode.
1. Crea docs/plan.md a partir de la sección 7 del Dossier (estado, hitos, criterio de aceptación y checklist de tareas). No cambies los criterios.
2. Hito 0: lanza un subagente con contexto limpio y entrégale SOLO las secciones 5 y 6 del Dossier. Pídele (a) los archivos que generaría cada Tier, (b) el algoritmo de new-project paso a paso y (c) toda ambigüedad o contradicción, con severidad. Compara su respuesta con el Dossier y propón correcciones al Dossier.
3. Con el contrato aprobado, propón el plan de implementación SOLO del Hito 1: archivos a crear, orden y cómo verificarás su criterio de aceptación.
Señala cualquier ambigüedad o conflicto. No escribas código ni hagas commits hasta que apruebe el plan.
```

**C. Entrada de bitácora (terminada)** para `content/projects/project-starter.md` en el repo `portfolio`

```markdown
---
slug: project-starter
titulo: project-starter
tipo: personal
visibilidad: publico
estado: terminado
inicio: 2026-11
fin: 2026-11
tier: 1
metodologia: eg-ligero
rol: Diseño, especificación y dirección de la construcción con Claude Code
stack: [bash, markdown, claude-code]
destacado: true
enlaces: { repo: https://github.com/jadriangz/project-starter, demo: , caso: }
---

## Problema
Cada proyecto nuevo con Claude Code obligaba a rehacer la misma estructura de contexto (CLAUDE.md, spec, plan, reglas y revisión), sin saber qué versión usaba cada proyecto.

## Enfoque (decisiones clave y por qué)
- Generador en lugar de clonar por proyecto: evita historial y archivos sobrantes, y permite comparar cada proyecto con la versión vigente.
- Plantilla en capas por Tier: un cambio se hace una vez y cada proyecto recibe solo lo que su complejidad justifica.
- Revisión goldfish como skills con contexto aislado, sin dependencias externas.
- Lock en texto plano con hashes, para detectar divergencias sin jq ni Python.
- Aplazado a propósito a la v0.2: el sandbox de Claude Code (cambia el contrato y exige probarlo en WSL2) y un modo para aceptar cambios desde `starter-diff` (escribiría en el lock y exige pruebas de escritura segura). La v0.1 solo reporta y sugiere la línea a editar.

## Solución
- `bin/new-project`: genera proyectos Tier 0 a 3, valida todo antes de escribir, construye en un temporal, mueve con `mv -T` y hace el primer commit. Deja `.claude/starter.lock` con versión, commit del starter y hashes.
- Capas: subagente `goldfish-revisor` (solo lectura, sin `CLAUDE.md`); skills `/hito`, `/revisar-diff`, `/cierre-hito`, `/bitacora` y `/revisar-diseno`; PRD y ADR en `t2`; CHANGELOG y gobierno en `t3`.
- Perfiles `nextjs` (Next.js 16), `supabase` (CLI v3) y `odoo-addon` (Odoo 19.0 y 20.0): cada uno con una regla que Claude carga solo al tocar archivos del stack.
- `bin/starter-diff`: compara un proyecto con el starter actual en 11 estados, sin escribir nada, e imprime la línea del lock a editar.
- Publicación: README (en español, con resumen en inglés), licencia MIT, CHANGELOG `0.1.0` y tag [`v0.1.0`](https://github.com/jadriangz/project-starter/tree/v0.1.0).

## Cómo se usó Claude Code
Planeación en el Estudio de Proyectos (clasificación por Tier y Dossier). Construcción con E/G ligero: revisión goldfish del contrato y del diff de cada hito.
- **Delegado en Claude Code:** implementación, tests, fixtures y las revisiones goldfish.
- **Decisión y verificación humana:** clasificación y alcance, respuesta a cada pregunta abierta, aprobación de cada plan antes de escribir código, pruebas manuales en un proyecto generado (`/memory` y la carga de la regla de Next.js) y la publicación.
- En el Hito 2, un spike con canarios comprobó el aislamiento antes de escribir los skills: uno en el chat (`context: fork`), uno en `CLAUDE.md` (`omitClaudeMd`) y uno en el agente (`agent:`).
- Antes de publicar, un goldfish que solo vio el README y el árbol del repo tuvo que explicar el starter; lo que no pudo deducir se corrigió.

## Resultados
- Generación sin red (`unshare -rn`): 0,10 s (Tier 0), 0,18 s (Tier 1), 0,21 s (Tiers 2 y 3), cada proyecto con 1 commit y sin divergencias en `starter-diff`.
- Smoke: 178 checks en verde en 6 s (Ubuntu 24.04.5 sobre WSL2), con combinaciones de stack y un proyecto manipulado que provoca los 11 estados de `starter-diff`. Dos mutaciones deliberadas hacen fallar el smoke.
- Skills probados sobre fixtures con defectos sembrados: `/revisar-diff` encontró el defecto, `/revisar-diseno` listó las dos omisiones, `/cierre-hito` no commiteó y `/bitacora` omitió los nombres en modo anonimizado.
- Revisiones goldfish: la del contrato encontró 35 hallazgos (7 altos) y, ya corregido, la segunda dio 0 altos; los diffs de los hitos 1 a 3 dieron 0 altos y todos los hallazgos se aplicaron.
- Antes de publicar: gitleaks 8.30.1 sin hallazgos sobre el historial completo (9 commits, hasta `798ed25`) y el árbol, más un grep de rutas y correos; un clon limpio siguiendo solo el README termina con código 0, 1 commit y árbol limpio.

## Aprendizajes
- Un comodín en `allowed-tools` preaprueba más de lo que parece: con `Bash(sed -n *)` y `Bash(git diff *)`, Claude ejecutó sin preguntar `sed -n -i` (truncó un archivo) y `git diff --output` (creó otro). Los skills pasaron a reglas exactas y una regla de smoke prohíbe el `*`.
- La documentación vigente cambió más de lo esperado: Supabase CLI v3 (2 nov 2026) pasó a local por defecto, y Odoo 20 movió los permisos de `ir.model.access.csv` a `ir.access.csv`. Una regla escrita de memoria habría salido mal; leer la página antes de cada viñeta es lo que hace confiable un perfil.
- Las instrucciones «para probar» del README fallaban en una máquina real: un directorio temporal queda fuera de las reglas `includeIf` y el primer commit falla sin identidad global. El smoke no lo detectaba porque trae su propia identidad; seguir el README con un `HOME` temporal sí.
- Las reglas `includeIf gitdir:` solo se evalúan dentro de un repo, así que un diagnóstico de identidad desde la carpeta padre no las ve.
- Un `deny` de `Read` también bloquea editar o crear el archivo: Claude no puede mantener `.env.example` con el `deny` actual.
- Una prueba de «solo lectura» basada en nombres de archivo y `git status` no detecta la reescritura de un archivo ya modificado; hace falta comparar contenido.
- Un canario por fuente de contexto es la forma más barata de probar el aislamiento de un subagente.

```
