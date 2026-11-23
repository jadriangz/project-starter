#!/usr/bin/env bash
# Smoke del generador (Hito 1: Tier 0 y 1). Nunca toca ~/projects:
# todo se genera en un PROJECTS_ROOT temporal con una identidad git de prueba.
set -euo pipefail

STARTER=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
NP=$STARTER/bin/new-project
VERSION=$(<"$STARTER/VERSION")

R=$(mktemp -d)
trap 'rm -rf -- "$R"' EXIT
mkdir "$R/personal" "$R/work" "$R/tmpdir"
printf '[user]\n\tname = Smoke\n\temail = smoke@example.invalid\n' >"$R/gitconfig"
export PROJECTS_ROOT=$R GIT_CONFIG_GLOBAL=$R/gitconfig GIT_CONFIG_NOSYSTEM=1
unset STARTER_WORK_OWNER

if [[ -t 1 ]]; then VERDE=$'\e[32m' ROJO=$'\e[31m' NORMAL=$'\e[0m'; else VERDE='' ROJO='' NORMAL=''; fi
FALLOS=0
ok() { printf '%sPASA%s  %s\n' "$VERDE" "$NORMAL" "$1"; }
mal() {
	printf '%sFALLA%s %s\n' "$ROJO" "$NORMAL" "$1"
	if [[ -n ${2:-} ]]; then printf '      %s\n' "$2"; fi
	FALLOS=$((FALLOS + 1))
}
check() { # check <descripción> <comando...>
	local d=$1
	shift
	if "$@" >/dev/null 2>&1; then ok "$d"; else mal "$d"; fi
}
snapshot() { find "$1" | LC_ALL=C sort; }

# Tabla esperada por Tier (§5): ruta|fuente en template/|clase. Los patrones de
# managed de §6 son normativos (C13); aquí se comprueba que coinciden con la tabla.
TABLA_T0='.claude/settings.json|core/dot-claude/settings.json|S
.gitattributes|core/dot-gitattributes|S
.gitignore|core/dot-gitignore|S
CLAUDE.md|core/CLAUDE.md.tmpl|S
docs/brief.md|core/docs/brief.md|S'
TABLA_T1='.claude/settings.json|core/dot-claude/settings.json|S
.gitattributes|core/dot-gitattributes|S
.gitignore|core/dot-gitignore|S
CLAUDE.md|t1/CLAUDE.md.tmpl|S
docs/bitacora.md|t1/docs/bitacora.md|S
docs/brief.md|core/docs/brief.md|S
docs/plan.md|t1/docs/plan.md|S
docs/spec.md|t1/docs/spec.md|S'

seccion() { # seccion <lock> managed|seeded
	if [[ $2 == managed ]]; then
		sed -n '/^--managed--$/,/^--seeded--$/{/^--/d;p}' "$1"
	else
		sed -n '/^--seeded--$/,${/^--/d;p}' "$1"
	fi
}

verificar_lock() { # verificar_lock <proyecto> <tabla> <slug> <tipo> <tier> <metodologia> <visibilidad>
	local p=$1 tabla=$2 lock=$1/.claude/starter.lock
	local esperado_cab
	esperado_cab="# project-starter lock: editar solo las entradas, nunca la cabecera
schema=1
starter_version=$VERSION
starter_commit=
slug=$3
tipo=$4
tier=$5
metodologia=$6
stack=
visibilidad=$7
generated_at="
	local cab
	cab=$(head -n 11 "$lock" | sed -E 's/^(starter_commit|generated_at)=.*/\1=/')
	if [[ $cab == "$esperado_cab" ]]; then ok "lock T$5: comentario, claves en orden y valores"; else mal "lock T$5: cabecera" "$(diff <(printf '%s\n' "$esperado_cab") <(printf '%s\n' "$cab") | head -5)"; fi

	check "lock T$5: starter_commit con formato válido" grep -qE '^starter_commit=([0-9a-f]{12}(-dirty)?)?$' "$lock"
	check "lock T$5: generated_at en UTC" grep -qE '^generated_at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' "$lock"
	if [[ $(grep -nxE -- '--(managed|seeded)--' "$lock" | cut -d: -f2 | tr '\n' ' ') == '--managed-- --seeded-- ' &&
		$(sed -n 12p "$lock") == --managed-- ]]; then
		ok "lock T$5: marcadores presentes, una vez y en orden"
	else
		mal "lock T$5: marcadores"
	fi
	local m
	m=$(seccion "$lock" managed)
	if [[ -z $m ]]; then
		ok "lock T$5: managed vacía (sha256sum -c se omite)"
	elif (cd "$p" && printf '%s\n' "$m" | sha256sum -c --quiet); then
		ok "lock T$5: sha256sum -c de managed pasa"
	else
		mal "lock T$5: sha256sum -c de managed"
	fi

	# Rutas y clases del lock contra la tabla (C13), y hash = fuente sin renderizar.
	local esperado_seeded esperado_managed
	esperado_seeded=$(printf '%s\n' "$tabla" | awk -F'|' '$3=="S"{print $1}')
	esperado_managed=$(printf '%s\n' "$tabla" | awk -F'|' '$3=="M"{print $1}')
	if [[ $(seccion "$lock" seeded | cut -c67-) == "$esperado_seeded" && $(seccion "$lock" managed | cut -c67-) == "$esperado_managed" ]]; then
		ok "lock T$5: rutas, clase managed/seeded y orden coinciden con la tabla de §5"
	else
		mal "lock T$5: rutas o clases" "$(seccion "$lock" seeded | cut -c67- | tr '\n' ' ')"
	fi
	local ruta fuente clase h malos=''
	while IFS='|' read -r ruta fuente clase; do
		h=$(awk -v r="$ruta" '/^[0-9a-f]{64}  / && $2 == r {print $1}' "$lock")
		[[ $h == "$(sha256sum <"$STARTER/template/$fuente" | cut -c1-64)" ]] || malos+="$ruta "
	done <<<"$tabla"
	if [[ -z $malos ]]; then ok "lock T$5: cada hash seeded = sha256 de su fuente en template/"; else mal "lock T$5: hashes" "$malos"; fi
	if grep -qF -e "$HOME" -e "$R" "$lock" || grep -qE '  /' "$lock"; then mal "lock T$5: contiene rutas absolutas"; else ok "lock T$5: sin \$HOME ni rutas absolutas"; fi
}

verificar_proyecto() { # verificar_proyecto <proyecto> <tier> <max-lineas>
	local p=$1 t=$2 f faltan=''
	for f in CLAUDE.md .gitignore .gitattributes .claude/settings.json docs/brief.md .claude/starter.lock; do
		[[ -f $p/$f ]] || faltan+="$f "
	done
	if ((t == 0)); then
		for f in docs/spec.md docs/plan.md docs/bitacora.md; do [[ ! -e $p/$f ]] || faltan+="(sobra)$f "; done
	else
		for f in docs/spec.md docs/plan.md docs/bitacora.md; do [[ -f $p/$f ]] || faltan+="$f "; done
		[[ ! -e $p/docs/adr ]] || faltan+="(sobra)docs/adr "
	fi
	if [[ -z $faltan ]]; then ok "estructura T$t"; else mal "estructura T$t" "$faltan"; fi

	if grep -rF '{{' --exclude-dir=.git "$p" >/dev/null; then mal "placeholders T$t" "$(grep -rnF '{{' --exclude-dir=.git "$p" | head -3)"; else ok "placeholders T$t: ningún '{{'"; fi

	local n
	n=$(wc -l <"$p/CLAUDE.md")
	if ((n <= $3)); then ok "CLAUDE.md T$t: $n líneas (máx. $3)"; else mal "CLAUDE.md T$t: $n líneas (máx. $3)"; fi

	if [[ $(git -C "$p" rev-list --count HEAD) == 1 && -z $(git -C "$p" status --porcelain) ]] &&
		git -C "$p" ls-files --error-unmatch .claude/starter.lock >/dev/null 2>&1 &&
		[[ $(git -C "$p" symbolic-ref --short HEAD) == main ]]; then
		ok "git T$t: un commit en main, árbol limpio y lock incluido"
	else
		mal "git T$t"
	fi

	# C22: secretos ignorados, .env.example versionable.
	if git -C "$p" check-ignore -q .env && git -C "$p" check-ignore -q .env.local &&
		git -C "$p" check-ignore -q secrets/clave && git -C "$p" check-ignore -q .claude/settings.local.json &&
		git -C "$p" check-ignore -q CLAUDE.local.md && ! git -C "$p" check-ignore -q .env.example; then
		ok ".gitignore T$t: .env*, secrets/ y locales ignorados; .env.example no"
	else
		mal ".gitignore T$t"
	fi
}

rechazo() { # rechazo <descripción> <raíz-a-observar> <args...>
	local d=$1 raiz=$2 antes despues rc=0
	shift 2
	antes=$(snapshot "$raiz")
	"$NP" "$@" >/dev/null 2>&1 || rc=$?
	despues=$(snapshot "$raiz")
	if ((rc != 0)) && [[ $antes == "$despues" ]]; then ok "rechazo: $d"; else mal "rechazo: $d (rc=$rc, cambios en disco: $([[ $antes == "$despues" ]] && echo no || echo sí))"; fi
}

printf '== Generación\n'
check "genera Tier 0 (personal)" "$NP" uno --tipo personal --tier 0
check "genera Tier 1 (work)" "$NP" dos --tipo work --tier 1

printf '\n== Tier 0\n'
verificar_proyecto "$R/personal/uno" 0 15
verificar_lock "$R/personal/uno" "$TABLA_T0" uno personal 0 ninguna publico

printf '\n== Tier 1\n'
verificar_proyecto "$R/work/dos" 1 60
verificar_lock "$R/work/dos" "$TABLA_T1" dos work 1 eg-ligero privado

printf '\n== Visibilidad por defecto\n'
check "personal → publico" grep -qx 'visibilidad=publico' "$R/personal/uno/.claude/starter.lock"
check "work → privado" grep -qx 'visibilidad=privado' "$R/work/dos/.claude/starter.lock"

printf '\n== Rechazos (código ≠ 0 y disco idéntico)\n'
mkdir "$R/vacio"
rechazo "destino existente" "$R" uno --tipo personal --tier 1
rechazo "slug inválido" "$R" Mal_Slug --tipo personal --tier 0
rechazo "slug de más de 64 caracteres" "$R" "$(printf 'a%.0s' {1..65})" --tipo personal --tier 0
rechazo "tipo inválido" "$R" tres --tipo otro --tier 0
PROJECTS_ROOT=$R/vacio rechazo "carpeta padre inexistente" "$R" tres --tipo personal --tier 0
rechazo "Tier fuera de rango" "$R" tres --tipo personal --tier 4
rechazo "visibilidad inválida" "$R" tres --tipo personal --tier 0 --visibilidad secreta
rechazo "perfil desconocido" "$R" tres --tipo personal --tier 1 --stack nextjs
rechazo "opción desconocida" "$R" tres --tipo personal --tier 0 --color azul

printf '\n== Fallo de git\n'
printf '[user]\n\tname = Smoke\n\temail = smoke@example.invalid\n[commit]\n\tgpgsign = true\n[gpg]\n\tprogram = false\n' >"$R/gitconfig-firma"
GIT_CONFIG_GLOBAL=$R/gitconfig-firma rechazo "commit fallido borra el destino" "$R" tres --tipo personal --tier 1

printf '\n== Excludes global del usuario\n'
printf 'docs/\n.claude/\n' >"$R/excludes"
printf '[user]\n\tname = Smoke\n\temail = smoke@example.invalid\n[core]\n\texcludesFile = %s\n' "$R/excludes" >"$R/gitconfig-excl"
if GIT_CONFIG_GLOBAL=$R/gitconfig-excl "$NP" cinco --tipo personal --tier 1 >/dev/null 2>&1 &&
	git -C "$R/personal/cinco" ls-files --error-unmatch docs/spec.md .claude/starter.lock >/dev/null 2>&1; then
	ok "un core.excludesFile global no deja archivos fuera del primer commit"
else
	mal "excludes global: primer commit incompleto"
fi

printf '\n== Composición sobre una copia del starter\n'
copia() { # copia <nombre>: copia mínima del starter (sin git) en $R/<nombre>
	mkdir "$R/$1"
	cp -r "$STARTER/bin" "$STARTER/lib" "$STARTER/template" "$STARTER/VERSION" "$R/$1/"
}
compone_falla() { # compone_falla <descripción> <copia>
	if "$R/$2/bin/new-project" seis --tipo personal --tier 1 --dry-run >/dev/null 2>&1; then mal "composición: $1 debería fallar"; else ok "composición: $1 falla"; fi
}
copia c1 && : >"$R/c1/template/core/CLAUDE.md"
compone_falla "CLAUDE.md real en template/" c1
copia c2 && mkdir "$R/c2/template/t1/.claude"
compone_falla ".claude/ real y vacío en template/" c2
copia c3 && cp "$R/c3/template/core/docs/brief.md" "$R/c3/template/core/docs/brief.md.tmpl"
compone_falla "colisión dentro de una capa (x y x.tmpl)" c3
copia c4 && mkdir -p "$R/c4/template/t1/dot-claude/agents" && printf '{{SLUG}}\n' >"$R/c4/template/t1/dot-claude/agents/a.md"
compone_falla "managed con '{{'" c4
copia c5 && : >"$R/c5/template/core/docs/con espacio.md"
compone_falla "ruta con espacios" c5
copia c6 && mkdir -p "$R/c6/template/t1/dot-claude/agents" && printf 'agente\n' >"$R/c6/template/t1/dot-claude/agents/a.md"
salida=$("$R/c6/bin/new-project" seis --tipo personal --tier 1 --dry-run 2>/dev/null || true)
if [[ $(sed -n '/^--managed--$/,/^--seeded--$/{/^--/d;p}' <<<"$salida" | cut -c67-) == .claude/agents/a.md ]]; then
	ok "composición: dot-claude/agents/… se clasifica managed por patrón (C13)"
else
	mal "composición: clasificación managed por patrón"
fi
clasifica() ( # clasifica <ruta> → M o S según es_managed
	STARTER_ROOT=$STARTER
	# shellcheck source=lib/common.sh
	. "$STARTER/lib/common.sh"
	if es_managed "$1"; then echo M; else echo S; fi
)
malos=''
for par in .claude/agents/x.md:M .claude/skills/hito/SKILL.md:M .claude/rules/stack-nextjs.md:M \
	.claude/rules/propia.md:S .claude/settings.json:S CLAUDE.md:S docs/adr/0000-plantilla.md:S CHANGELOG.md:S; do
	[[ $(clasifica "${par%:*}") == "${par##*:}" ]] || malos+="$par "
done
if [[ -z $malos ]]; then ok "patrones managed/seeded coinciden con la columna Lock de §5 (C13)"; else mal "patrones managed/seeded" "$malos"; fi

printf '\n== --dry-run\n'
antes=$(snapshot "$R/personal")
rc=0
salida=$(TMPDIR=$R/tmpdir "$NP" cuatro --tipo personal --tier 1 --dry-run 2>/dev/null) || rc=$?
if ((rc == 0)) && [[ $salida == *'# project-starter lock: editar solo las entradas, nunca la cabecera'*'--seeded--'* && $salida == *docs/spec.md* ]] &&
	[[ $antes == "$(snapshot "$R/personal")" && -z $(ls -A "$R/tmpdir") ]]; then
	ok "--dry-run: código 0, imprime rutas y lock, no escribe ni deja temporales"
else
	mal "--dry-run (rc=$rc)"
fi

printf '\n== Render (C17)\n'
render_prueba() { # render_prueba <línea> → imprime el resultado o falla
	(
		STARTER_ROOT=$STARTER
		# shellcheck source=lib/common.sh
		. "$STARTER/lib/common.sh"
		declare -A RENDER_VARS=([SLUG]=x)
		FRAG_GOBIERNO=() FRAG_COMANDOS=()
		printf '%s\n' "$1" >"$R/render.in"
		render "$R/render.in" "$R/render.out" prueba
		cat "$R/render.out"
	)
}
if [[ -z $(render_prueba '{{GOBIERNO}}' 2>/dev/null) ]]; then ok "marcador exacto sin fragmento: la línea se elimina"; else mal "marcador exacto sin fragmento"; fi
if render_prueba ' {{GOBIERNO}}' >/dev/null 2>&1; then mal "marcador con espacios debería fallar"; else ok "marcador con espacios: falla"; fi
if render_prueba '{{OTRO}}' >/dev/null 2>&1; then mal "placeholder desconocido debería fallar"; else ok "placeholder desconocido: falla"; fi
if [[ $(render_prueba 'a & {{SLUG}} \ b' 2>/dev/null) == 'a & x \ b' ]]; then ok "placeholder con & y \\ en la línea"; else mal "placeholder con & y \\"; fi

printf '\n%d s · ' "$SECONDS"
if ((FALLOS == 0)); then
	printf '%sTODO VERDE%s\n' "$VERDE" "$NORMAL"
else
	printf '%s%d FALLO(S)%s\n' "$ROJO" "$FALLOS" "$NORMAL"
	exit 1
fi
