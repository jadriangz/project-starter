#!/usr/bin/env bash
# Smoke del generador (Tiers 0 a 3). Nunca toca ~/projects:
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
tabla() { printf '%s\n' "$@" | LC_ALL=C sort; } # el lock ordena por ruta con LC_ALL=C
TABLA_T1=$(tabla '.claude/settings.json|core/dot-claude/settings.json|S' \
	'.gitattributes|core/dot-gitattributes|S' \
	'.gitignore|core/dot-gitignore|S' \
	'CLAUDE.md|t1/CLAUDE.md.tmpl|S' \
	'docs/bitacora.md|t1/docs/bitacora.md|S' \
	'docs/brief.md|core/docs/brief.md|S' \
	'docs/plan.md|t1/docs/plan.md|S' \
	'docs/spec.md|t1/docs/spec.md|S' \
	'.claude/agents/goldfish-revisor.md|t1/dot-claude/agents/goldfish-revisor.md|M' \
	'.claude/skills/bitacora/SKILL.md|t1/dot-claude/skills/bitacora/SKILL.md|M' \
	'.claude/skills/cierre-hito/SKILL.md|t1/dot-claude/skills/cierre-hito/SKILL.md|M' \
	'.claude/skills/hito/SKILL.md|t1/dot-claude/skills/hito/SKILL.md|M' \
	'.claude/skills/revisar-diff/SKILL.md|t1/dot-claude/skills/revisar-diff/SKILL.md|M')
TABLA_T2=$(tabla "$TABLA_T1" \
	'docs/prd.md|t2/docs/prd.md|S' \
	'docs/adr/0000-plantilla.md|t2/docs/adr/0000-plantilla.md|S' \
	'.claude/skills/revisar-diseno/SKILL.md|t2/dot-claude/skills/revisar-diseno/SKILL.md|M')
TABLA_T3=$(tabla "$TABLA_T2" 'CHANGELOG.md|t3/CHANGELOG.md|S')

seccion() { # seccion <lock> managed|seeded
	if [[ $2 == managed ]]; then
		sed -n '/^--managed--$/,/^--seeded--$/{/^--/d;p}' "$1"
	else
		sed -n '/^--seeded--$/,${/^--/d;p}' "$1"
	fi
}

verificar_lock() { # verificar_lock <proyecto> <tabla> <slug> <tipo> <tier> <metodologia> <visibilidad> [stack]
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
stack=${8:-}
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
	fi
	if ((t >= 2)); then
		for f in docs/prd.md docs/adr/0000-plantilla.md; do [[ -f $p/$f ]] || faltan+="$f "; done
	else
		for f in docs/prd.md docs/adr .claude/skills/revisar-diseno; do [[ ! -e $p/$f ]] || faltan+="(sobra)$f "; done
	fi
	if ((t == 3)); then [[ -f $p/CHANGELOG.md ]] || faltan+="CHANGELOG.md "; else [[ ! -e $p/CHANGELOG.md ]] || faltan+="(sobra)CHANGELOG.md "; fi
	if [[ -z $faltan ]]; then ok "estructura T$t"; else mal "estructura T$t" "$faltan"; fi

	# Fragmento de gobierno: solo en Tier 3.
	local gob=0
	grep -qx '## Gobierno' "$p/CLAUDE.md" && gob=1
	if ((gob == (t == 3))); then ok "gobierno T$t: $( ((gob)) && echo presente || echo ausente) en CLAUDE.md"; else mal "gobierno T$t"; fi

	# Frontmatter de agentes y skills (§8): '---' en la línea 1, name = carpeta o
	# archivo, description, y disable-model-invocation en cada skill. El agente
	# es de solo lectura y sin CLAUDE.md.
	local fm nombre malos=''
	for f in "$p"/.claude/skills/*/SKILL.md "$p"/.claude/agents/*.md; do
		[[ -f $f ]] || continue
		if [[ $f == */SKILL.md ]]; then nombre=$(basename "$(dirname "$f")"); else nombre=$(basename "$f" .md); fi
		fm=$(sed -n '1{/^---$/!q};1d;/^---$/q;p' "$f")
		grep -qx "name: $nombre" <<<"$fm" && grep -q '^description: .' <<<"$fm" || malos+="${f#"$p"/} "
		if [[ $f == */SKILL.md ]]; then
			grep -qx 'disable-model-invocation: true' <<<"$fm" || malos+="(invocación)${f#"$p"/} "
			# allowed-tools preaprueba por prefijo: con '*', 'sed -n *' deja pasar 'sed -n -i'.
			! grep -q '^allowed-tools:.*\*' <<<"$fm" || malos+="(allowed-tools con *)${f#"$p"/} "
		else
			grep -qx 'omitClaudeMd: true' <<<"$fm" && grep -qx 'tools: Read, Grep, Glob' <<<"$fm" || malos+="(solo lectura)${f#"$p"/} "
		fi
	done
	if ((t > 0)); then
		if [[ -z $malos ]]; then ok "frontmatter T$t: agente y skills"; else mal "frontmatter T$t" "$malos"; fi
	fi

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
check "genera Tier 2 (work)" "$NP" ocho --tipo work --tier 2
check "genera Tier 3 (personal, anonimizado)" "$NP" nueve --tipo personal --tier 3 --visibilidad anonimizado

printf '\n== Tier 0\n'
verificar_proyecto "$R/personal/uno" 0 15
verificar_lock "$R/personal/uno" "$TABLA_T0" uno personal 0 ninguna publico

printf '\n== Tier 1\n'
verificar_proyecto "$R/work/dos" 1 60
verificar_lock "$R/work/dos" "$TABLA_T1" dos work 1 eg-ligero privado

printf '\n== Tier 2\n'
verificar_proyecto "$R/work/ocho" 2 60
verificar_lock "$R/work/ocho" "$TABLA_T2" ocho work 2 eg privado

printf '\n== Tier 3\n'
verificar_proyecto "$R/personal/nueve" 3 60
verificar_lock "$R/personal/nueve" "$TABLA_T3" nueve personal 3 eg anonimizado

printf '\n== Perfiles de stack\n'
regla() { printf '.claude/rules/stack-%s.md|profiles/%s/dot-claude/rules/stack-%s.md|M' "$1" "$1" "$1"; }
verificar_stack() { # verificar_stack <proyecto> <tier> <perfil…> (en orden normalizado)
	local p=$1 t=$2 perfil fm malos='' esperado=''
	shift 2
	for perfil in "$@"; do
		# Regla managed con paths: (lista YAML de patrones entre comillas) y sin '{{'.
		fm=$(sed -n '1{/^---$/!q};1d;/^---$/q;p' "$p/.claude/rules/stack-$perfil.md")
		grep -qx 'paths:' <<<"$fm" && grep -qE '^  - ".+"$' <<<"$fm" || malos+="(paths)$perfil "
		grep -qE '^Verificado el [0-9]{4}-[0-9]{2}-[0-9]{2}' "$p/.claude/rules/stack-$perfil.md" || malos+="(fecha)$perfil "
		esperado+=$(<"$STARTER/template/profiles/$perfil/_fragmentos/comandos.md")$'\n'
	done
	if [[ -z $malos ]]; then ok "stack T$t ($*): reglas con paths: y fecha de verificación"; else mal "stack T$t ($*): reglas" "$malos"; fi
	if ((t == 0)); then
		if grep -qF -- "$(head -n1 "$STARTER/template/profiles/$1/_fragmentos/comandos.md")" "$p/CLAUDE.md"; then
			mal "stack T0: CLAUDE.md no debería llevar comandos del stack"
		else
			ok "stack T0: regla sí, comandos del stack no"
		fi
	elif [[ $(<"$p/CLAUDE.md") == *"$esperado"* ]]; then
		ok "stack T$t ($*): fragmentos de comandos en CLAUDE.md, en orden"
	else
		mal "stack T$t ($*): fragmentos de comandos"
	fi
}
check "genera Tier 1 --stack nextjs" "$NP" diez --tipo personal --tier 1 --stack nextjs
check "genera Tier 2 --stack Supabase,nextjs,supabase (normaliza)" "$NP" once --tipo work --tier 2 --stack Supabase,nextjs,supabase
check "genera Tier 3 --stack odoo-addon" "$NP" doce --tipo personal --tier 3 --stack odoo-addon
check "genera Tier 0 --stack nextjs" "$NP" trece --tipo personal --tier 0 --stack nextjs
verificar_proyecto "$R/personal/diez" 1 60
verificar_lock "$R/personal/diez" "$(tabla "$TABLA_T1" "$(regla nextjs)")" diez personal 1 eg-ligero publico nextjs
verificar_stack "$R/personal/diez" 1 nextjs
verificar_proyecto "$R/work/once" 2 60
verificar_lock "$R/work/once" "$(tabla "$TABLA_T2" "$(regla nextjs)" "$(regla supabase)")" once work 2 eg privado nextjs,supabase
verificar_stack "$R/work/once" 2 nextjs supabase
verificar_proyecto "$R/personal/doce" 3 60
verificar_lock "$R/personal/doce" "$(tabla "$TABLA_T3" "$(regla odoo-addon)")" doce personal 3 eg publico odoo-addon
verificar_stack "$R/personal/doce" 3 odoo-addon
verificar_proyecto "$R/personal/trece" 0 15
verificar_lock "$R/personal/trece" "$(tabla "$TABLA_T0" "$(regla nextjs)")" trece personal 0 ninguna publico nextjs
verificar_stack "$R/personal/trece" 0 nextjs

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
rechazo "perfil desconocido" "$R" tres --tipo personal --tier 1 --stack nextjs,inexistente
rechazo "perfil con nombre inválido" "$R" tres --tipo personal --tier 1 --stack 'next_js'
rechazo "opción desconocida" "$R" tres --tipo personal --tier 0 --color azul

printf '\n== Fallo de git\n'
printf '[user]\n\tname = Smoke\n\temail = smoke@example.invalid\n[commit]\n\tgpgsign = true\n[gpg]\n\tprogram = false\n' >"$R/gitconfig-firma"
GIT_CONFIG_GLOBAL=$R/gitconfig-firma rechazo "commit fallido borra el destino" "$R" tres --tipo personal --tier 1
err=$(GIT_CONFIG_GLOBAL=$R/gitconfig-firma "$NP" tres --tipo personal --tier 1 2>&1 >/dev/null || true)
if [[ $err == *"git config --global --get-regexp '^includeif'"* ]]; then ok "commit fallido: la pista nombra las reglas includeIf globales (C20)"; else mal "commit fallido: pista includeIf (C20)" "$err"; fi

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
if sed -n '/^--managed--$/,/^--seeded--$/{/^--/d;p}' <<<"$salida" | cut -c67- | grep -qx .claude/agents/a.md; then
	ok "composición: dot-claude/agents/… se clasifica managed por patrón (C13)"
else
	mal "composición: clasificación managed por patrón"
fi
copia c7 && mkdir -p "$R/c7/template/profiles/nextjs/docs" && printf 'x\n' >"$R/c7/template/profiles/nextjs/docs/extra.md"
if "$R/c7/bin/new-project" seis --tipo personal --tier 1 --stack nextjs --dry-run >/dev/null 2>&1; then
	mal "composición: un perfil que aporta algo distinto de su regla debería fallar"
else
	ok "composición: un perfil solo aporta su regla y su fragmento"
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

printf '\n== starter-diff\n'
SD=$STARTER/bin/starter-diff
no_limpios=''
for p in personal/uno work/dos work/ocho personal/nueve work/once personal/doce personal/trece; do
	if ! salida=$("$SD" "$R/$p" 2>&1) || grep -vqE '^(# |managed  limpio  |seeded  plantilla-sin-cambios  )' <<<"$salida"; then
		no_limpios+="$p "
	fi
done
if [[ -z $no_limpios ]]; then ok "starter-diff tras generar: solo limpio y plantilla-sin-cambios, código 0"; else mal "starter-diff tras generar" "$no_limpios"; fi
huella() { # huella <dir>: rutas, tipos y contenido (para probar que nada se escribe)
	(cd "$1" && find . -path ./.git -prune -o -printf '%y %p\n' | LC_ALL=C sort &&
		find . -path ./.git -prune -o -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum)
}

# Fixture: proyecto Tier 2 nextjs,supabase generado con una copia del starter;
# después se manipulan la copia (S) y el proyecto (P) para provocar los 11 estados.
copia sd
"$R/sd/bin/new-project" sd --tipo personal --tier 2 --stack nextjs,supabase >/dev/null 2>&1
T=$R/sd/template PJ=$R/personal/sd
rm "$PJ/.claude/skills/hito/SKILL.md"                         # managed faltante
rm -r "$T/profiles/nextjs"                                    # managed retirado (C10)
rm "$T/t1/dot-claude/agents/goldfish-revisor.md"               # managed retirado (de una capa)
rm "$T/t2/docs/adr/0000-plantilla.md"                          # seeded fuera del starter (C12)
printf 'cambio\n' >>"$T/t1/dot-claude/skills/bitacora/SKILL.md" # managed desactualizado
printf 'cambio\n' >>"$T/t1/dot-claude/skills/cierre-hito/SKILL.md"
cp "$T/t1/dot-claude/skills/cierre-hito/SKILL.md" "$PJ/.claude/skills/cierre-hito/SKILL.md" # actualizado-sin-registrar
printf 'local\n' >>"$PJ/.claude/skills/revisar-diff/SKILL.md"                               # managed modificado
printf 'starter\n' >>"$T/t2/dot-claude/skills/revisar-diseno/SKILL.md"
printf 'local\n' >>"$PJ/.claude/skills/revisar-diseno/SKILL.md" # managed conflicto
for s in nuevo otro igual; do
	mkdir -p "$T/t1/dot-claude/skills/$s" && printf -- '---\nname: %s\n---\n' "$s" >"$T/t1/dot-claude/skills/$s/SKILL.md"
done # nuevo-en-starter; otro e igual: C14
mkdir -p "$PJ/.claude/skills/otro" "$PJ/.claude/skills/igual"
printf 'propio\n' >"$PJ/.claude/skills/otro/SKILL.md"
cp "$T/t1/dot-claude/skills/igual/SKILL.md" "$PJ/.claude/skills/igual/SKILL.md"
rm "$PJ/docs/prd.md"                  # seeded faltante
printf 'cambio\n' >>"$T/t1/docs/plan.md" # seeded plantilla-cambió

antes=$(huella "$PJ")
estado_git=$(git -C "$PJ" status --porcelain)
rc=0
salida=$("$R/sd/bin/starter-diff" "$PJ" 2>"$R/sd.err") || rc=$?
if ((rc == 0)); then ok "starter-diff manipulado: código 0"; else mal "starter-diff manipulado: código $rc" "$(cat "$R/sd.err")"; fi
malos=''
while IFS= read -r esperada; do
	grep -qxF -- "$esperada" <<<"$salida" || malos+="[$esperada] "
done <<'EOF'
managed  faltante  .claude/skills/hito/SKILL.md
managed  retirado  .claude/rules/stack-nextjs.md
managed  retirado  .claude/agents/goldfish-revisor.md
managed  limpio  .claude/rules/stack-supabase.md
managed  desactualizado  .claude/skills/bitacora/SKILL.md
managed  actualizado-sin-registrar  .claude/skills/cierre-hito/SKILL.md
managed  modificado  .claude/skills/revisar-diff/SKILL.md
managed  conflicto  .claude/skills/revisar-diseno/SKILL.md
managed  nuevo-en-starter  .claude/skills/nuevo/SKILL.md
managed  conflicto  .claude/skills/otro/SKILL.md
managed  actualizado-sin-registrar  .claude/skills/igual/SKILL.md
seeded  faltante  docs/prd.md
seeded  plantilla-sin-cambios  docs/spec.md
seeded  plantilla-cambió  docs/plan.md
seeded  plantilla-cambió  docs/adr/0000-plantilla.md
EOF
if [[ -z $malos ]]; then ok "starter-diff manipulado: los 11 estados (8 managed, 3 seeded) y C14 con la clasificación correcta"; else mal "starter-diff manipulado: estados" "$malos"; fi
n=$(grep -cE '^(managed|seeded)  ' <<<"$salida")
if ((n == 21)); then ok "starter-diff manipulado: una línea por archivo (21)"; else mal "starter-diff manipulado: $n líneas de estado (se esperaban 21)"; fi
sugiere() { # sugiere <línea de estado> <línea esperada debajo>
	grep -A2 -xF -- "$1" <<<"$salida" | grep -qxF -- "$2"
}
sha_t() { sha256sum <"$T/$1" | cut -c1-64; }
malos=''
for c in 'actualizado-sin-registrar|cierre-hito|t1' 'desactualizado|bitacora|t1' 'nuevo-en-starter|nuevo|t1' 'actualizado-sin-registrar|igual|t1'; do
	IFS='|' read -r estado skill capa <<<"$c"
	sugiere "managed  $estado  .claude/skills/$skill/SKILL.md" \
		"  lock: $(sha_t "$capa/dot-claude/skills/$skill/SKILL.md")  .claude/skills/$skill/SKILL.md" || malos+="$estado/$skill "
done
sugiere 'managed  retirado  .claude/rules/stack-nextjs.md' '  lock: quitar la línea de .claude/rules/stack-nextjs.md' || malos+="retirado "
sugiere 'seeded  plantilla-cambió  docs/adr/0000-plantilla.md' '  → ya no está en el starter: revisar a mano y retirar la entrada' || malos+="C12 "
if [[ -z $malos ]]; then
	ok "starter-diff manipulado: líneas de lock exactas (cambiar, añadir, quitar) y nota C12"
else
	mal "starter-diff manipulado: líneas de lock sugeridas" "$malos"
fi
if grep -q "perfil 'nextjs'.*C10" "$R/sd.err"; then ok "starter-diff manipulado: aviso en stderr por el perfil retirado (C10)"; else mal "starter-diff: aviso C10" "$(cat "$R/sd.err")"; fi
if [[ $antes == "$(huella "$PJ")" && $estado_git == "$(git -C "$PJ" status --porcelain)" ]]; then
	ok "starter-diff es de solo lectura: rutas, contenido y git status idénticos"
else
	mal "starter-diff modificó el proyecto"
fi

# Enlaces simbólicos y directorios: no se lee fuera del proyecto.
cp -a "$R/personal/diez" "$R/enlaces"
printf 'externo\n' >"$R/externo.md"
ln -sf "$R/externo.md" "$R/enlaces/.claude/skills/hito/SKILL.md"
rm "$R/enlaces/.claude/skills/bitacora/SKILL.md" && mkdir "$R/enlaces/.claude/skills/bitacora/SKILL.md"
salida=$("$SD" "$R/enlaces" 2>/dev/null || true)
if grep -qxF 'managed  conflicto  .claude/skills/hito/SKILL.md' <<<"$salida" &&
	grep -qxF 'managed  conflicto  .claude/skills/bitacora/SKILL.md' <<<"$salida"; then
	ok "starter-diff: un enlace simbólico o un directorio en una ruta managed da conflicto, sin leerlo"
else
	mal "starter-diff: enlaces y directorios" "$(grep -E 'hito|bitacora' <<<"$salida")"
fi
cp -a "$R/personal/diez" "$R/enlace2"
mv "$R/enlace2/.claude" "$R/claude-fuera" && ln -s "$R/claude-fuera" "$R/enlace2/.claude"

sd_falla() { # sd_falla <descripción> <proyecto>
	if "$SD" "$2" >/dev/null 2>&1; then mal "starter-diff: $1 debería fallar"; else ok "starter-diff: $1 falla"; fi
}
sd_falla "proyecto inexistente" "$R/no-existe"
sd_falla "proyecto sin lock" "$R/vacio"
sd_falla ".claude enlazado fuera del proyecto" "$R/enlace2"
lock_malo() { # lock_malo <descripción> <comando sed sobre el lock de personal/diez>
	local d=$R/lock$((++n_lock))
	mkdir -p "$d/.claude" && sed "$2" "$R/personal/diez/.claude/starter.lock" >"$d/.claude/starter.lock"
	sd_falla "$1" "$d"
}
n_lock=0
lock_malo "cabecera fuera de orden" '5{h;d};6{G}'
lock_malo "ruta del lock con '..'" "\$a0000000000000000000000000000000000000000000000000000000000000000  ../fuera.md"
lock_malo "ruta del lock absoluta" "\$a0000000000000000000000000000000000000000000000000000000000000000  /etc/hosts"
lock_malo "stack sin normalizar" 's/^stack=.*/stack=nextjs,nextjs/'
lock_malo "managed en --seeded--" "\$a0000000000000000000000000000000000000000000000000000000000000000  .claude/skills/x/SKILL.md"

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
