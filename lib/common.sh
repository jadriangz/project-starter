# shellcheck shell=bash
# Funciones compartidas de project-starter. Solo define funciones: cargarlo no
# tiene efectos. Quien lo carga fija STARTER_ROOT (raíz del repo del starter).
#
# Contrato: docs/dossier.md, secciones 5 y 6.

readonly RE_SLUG='^[a-z0-9]+(-[a-z0-9]+)*$'
readonly LOCK_COMENTARIO='# project-starter lock: editar solo las entradas, nunca la cabecera'

# --- Mensajes -----------------------------------------------------------------

log() { printf '%s\n' "$*" >&2; }

die() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

# --- Validaciones -------------------------------------------------------------

validar_slug() {
	local s=$1
	[[ $s =~ $RE_SLUG ]] || die "slug inválido '$s': usa minúsculas, dígitos y guiones simples (^[a-z0-9]+(-[a-z0-9]+)*\$)"
	((${#s} <= 64)) || die "slug inválido: ${#s} caracteres (máximo 64)"
}

validar_tipo() {
	case $1 in
	personal | work) ;;
	*) die "tipo inválido '$1': usa personal o work" ;;
	esac
}

validar_tier() {
	case $1 in
	0 | 1 | 2 | 3) ;;
	*) die "tier inválido '$1': usa 0, 1, 2 o 3" ;;
	esac
}

validar_visibilidad() {
	case $1 in
	publico | anonimizado | privado) ;;
	*) die "visibilidad inválida '$1': usa publico, anonimizado o privado" ;;
	esac
}

validar_perfil() {
	local p=$1
	[[ $p =~ $RE_SLUG ]] || die "perfil inválido '$p' en --stack"
	[[ -d $STARTER_ROOT/template/profiles/$p ]] || die "perfil desconocido '$p' en --stack (no existe template/profiles/$p)"
}

# Normaliza la lista separada por comas: minúsculas, valida cada perfil, ordena
# con LC_ALL=C y quita duplicados. Deja el resultado en STACK_NORMALIZADO
# (cadena con comas, vacía si no hay perfiles) y en el array PERFILES.
normalizar_stack() {
	local crudo=${1,,} p
	local -a partes=()
	STACK_NORMALIZADO=''
	PERFILES=()
	[[ -z $crudo ]] && return 0
	[[ $crudo == *, || $crudo == ,* || $crudo == *,,* ]] && die "stack inválido '$1': hay un perfil vacío"
	IFS=, read -r -a partes <<<"$crudo"
	for p in "${partes[@]}"; do validar_perfil "$p"; done
	mapfile -t PERFILES < <(printf '%s\n' "${partes[@]}" | LC_ALL=C sort -u)
	STACK_NORMALIZADO=$(
		IFS=,
		printf '%s' "${PERFILES[*]}"
	)
}

metodologia_para_tier() {
	case $1 in
	0) METODOLOGIA=ninguna ;;
	1) METODOLOGIA=eg-ligero ;;
	*) METODOLOGIA=eg ;;
	esac
}

# Deja en CAPAS las capas de un Tier: core, t1 … tN.
capas_para_tier() {
	local i
	CAPAS=(core)
	for ((i = 1; i <= $1; i++)); do CAPAS+=("t$i"); done
}

# --- Composición --------------------------------------------------------------

# Ruta en el proyecto a partir de la ruta dentro de la capa: cada segmento
# dot-x pasa a .x y el sufijo .tmpl se quita. Resultado en RUTA_DESTINO.
# Un .claude, .gitignore o CLAUDE.md real en la plantilla es error.
ruta_destino() {
	local rel=$1 origen=$2 seg
	local -a segs=() salida=()
	[[ $rel == *[[:space:]\\]* ]] && die "ruta con espacios, barras invertidas o saltos de línea ($origen)"
	IFS=/ read -r -a segs <<<"$rel"
	for seg in "${segs[@]}"; do
		case $seg in
		.claude | .gitignore | CLAUDE.md) die "archivo real '$seg' en la plantilla ($origen): usa dot-… o .tmpl" ;;
		dot-?*) seg=.${seg#dot-} ;;
		esac
		salida+=("$seg")
	done
	local ultimo=$((${#salida[@]} - 1))
	salida[ultimo]=${salida[ultimo]%.tmpl}
	[[ -n ${salida[ultimo]} ]] || die "nombre vacío tras quitar .tmpl ($origen)"
	RUTA_DESTINO=$(
		IFS=/
		printf '%s' "${salida[*]}"
	)
	return 0
}

# Clasificación por patrón (normativa, C13).
es_managed() {
	case $1 in
	.claude/agents/* | .claude/skills/* | .claude/rules/stack-*.md) return 0 ;;
	*) return 1 ;;
	esac
}

# Compone las fuentes de las capas en CAPAS y de los perfiles en PERFILES.
# Resultado:
#   FUENTE[ruta]  fuente relativa a template/ (la que ganó)
#   RUTAS         rutas del proyecto, ordenadas con LC_ALL=C
#   FRAG_GOBIERNO y FRAG_COMANDOS  fragmentos a insertar (rutas absolutas)
componer() {
	local t=$STARTER_ROOT/template capa p dir f rel
	declare -gA FUENTE=()
	RUTAS=()
	FRAG_GOBIERNO=()
	FRAG_COMANDOS=()

	# Un .claude, .gitignore o CLAUDE.md real (archivo o directorio, aunque esté
	# vacío) en cualquier parte de template/ es error.
	f=$(find "$t" \( -name .claude -o -name .gitignore -o -name CLAUDE.md \) -print -quit)
	[[ -z $f ]] || die "archivo real '${f#"$t"/}' en la plantilla: usa dot-… o .tmpl"

	for capa in "${CAPAS[@]}"; do
		dir=$t/$capa
		[[ -d $dir ]] || die "la capa template/$capa no existe todavía"
		_componer_dir "$dir" "$capa" capa
		if [[ -f $dir/_fragmentos/gobierno.md ]]; then FRAG_GOBIERNO=("$dir/_fragmentos/gobierno.md"); fi
	done
	for p in "${PERFILES[@]}"; do
		dir=$t/profiles/$p
		_componer_dir "$dir" "profiles/$p" perfil
		f=$(find "$dir/_fragmentos" -mindepth 1 ! -path "$dir/_fragmentos/comandos.md" -print -quit 2>/dev/null || true)
		[[ -z $f ]] || die "template/profiles/$p/${f#"$dir"/}: un perfil solo aporta _fragmentos/comandos.md como fragmento"
		if [[ -f $dir/_fragmentos/comandos.md ]]; then FRAG_COMANDOS+=("$dir/_fragmentos/comandos.md"); fi
	done

	mapfile -t RUTAS < <(printf '%s\n' "${!FUENTE[@]}" | LC_ALL=C sort)
	for rel in "${RUTAS[@]}"; do
		f=$t/${FUENTE[$rel]}
		if es_managed "$rel" && grep -qF '{{' "$f"; then
			die "el managed ${FUENTE[$rel]} contiene '{{' (los managed no llevan placeholders)"
		fi
	done
}

_componer_dir() {
	local dir=$1 prefijo=$2 clase=$3 f rel
	declare -A vistas=()
	while IFS= read -r -d '' f; do
		rel=${f#"$dir"/}
		ruta_destino "$rel" "$prefijo/$rel"
		[[ -n ${vistas[$RUTA_DESTINO]:-} ]] &&
			die "colisión dentro de template/$prefijo: ${vistas[$RUTA_DESTINO]} y $rel dan $RUTA_DESTINO"
		vistas[$RUTA_DESTINO]=$rel
		if [[ $clase == perfil ]]; then
			# Un perfil solo aporta su regla (y su fragmento, que no se copia).
			[[ $RUTA_DESTINO == ".claude/rules/stack-${prefijo#profiles/}.md" ]] ||
				die "template/$prefijo/$rel: un perfil solo aporta .claude/rules/stack-${prefijo#profiles/}.md y _fragmentos/comandos.md"
			# Los perfiles se componen después de las capas: esto cubre perfil-capa y perfil-perfil.
			[[ -z ${FUENTE[$RUTA_DESTINO]:-} ]] ||
				die "colisión: template/$prefijo/$rel y template/${FUENTE[$RUTA_DESTINO]} dan $RUTA_DESTINO"
		fi
		FUENTE[$RUTA_DESTINO]=$prefijo/$rel
	done < <(find "$dir" -path "$dir/_fragmentos" -prune -o -type f -print0)
	return 0
}

# --- Render -------------------------------------------------------------------

# Resuelve los {{NOMBRE}} de una línea con RENDER_VARS e imprime el resultado.
_resolver_linea() {
	local l=$1 origen=$2 nombre
	local re='\{\{([A-Z_]+)\}\}'
	while [[ $l =~ $re ]]; do
		nombre=${BASH_REMATCH[1]}
		[[ -v RENDER_VARS[$nombre] ]] || die "placeholder desconocido {{$nombre}} en $origen"
		l=${l//"{{$nombre}}"/"${RENDER_VARS[$nombre]}"}
	done
	[[ $l == *'{{'* ]] && die "'{{' sin resolver en $origen: $l"
	printf '%s\n' "$l"
}

_resolver_archivo() {
	local f=$1 origen=$2 linea
	while IFS= read -r linea || [[ -n $linea ]]; do
		_resolver_linea "$linea" "$origen"
	done <"$f"
}

# render <fuente> <destino> <origen-para-mensajes>
# Primero inserta los fragmentos (líneas exactas, C17); después resuelve
# placeholders. Requiere RENDER_VARS, FRAG_GOBIERNO y FRAG_COMANDOS.
render() {
	local src=$1 dst=$2 origen=$3 linea fr
	{
		while IFS= read -r linea || [[ -n $linea ]]; do
			case $linea in
			'{{GOBIERNO}}')
				for fr in "${FRAG_GOBIERNO[@]}"; do _resolver_archivo "$fr" "$fr"; done
				;;
			'{{COMANDOS_STACK}}')
				for fr in "${FRAG_COMANDOS[@]}"; do _resolver_archivo "$fr" "$fr"; done
				;;
			*) _resolver_linea "$linea" "$origen" ;;
			esac
		done <"$src"
	} >"$dst"
}

# --- Lock ---------------------------------------------------------------------

# starter_commit: hash corto del starter, -dirty si template/, lib/, bin/ o
# VERSION tienen cambios sin commitear, incluidos archivos sin seguimiento o
# ignorados (C18); vacío si no es un repo git.
starter_commit() {
	local top c
	STARTER_COMMIT=''
	top=$(git -C "$STARTER_ROOT" rev-parse --show-toplevel 2>/dev/null) || return 0
	[[ $(cd -P "$top" && pwd) == $(cd -P "$STARTER_ROOT" && pwd) ]] || return 0
	c=$(git -C "$STARTER_ROOT" rev-parse --short=12 HEAD 2>/dev/null) || return 0
	if [[ -n $(git --no-optional-locks -C "$STARTER_ROOT" status --porcelain --untracked-files=all --ignored=matching -- template lib bin VERSION) ]]; then
		c+=-dirty
	fi
	STARTER_COMMIT=$c
}

_sha() {
	local h _
	read -r h _ < <(sha256sum <"$1")
	printf '%s' "$h"
}

# leer_lock <archivo>: valida la gramática de §6 con schema=1. Deja la cabecera
# en LOCK[clave] y las entradas en LOCK_M[ruta] y LOCK_S[ruta] (ruta → sha256).
# Una ruta absoluta, con '..', espacios o barras invertidas es error: starter-diff
# no debe leer fuera del proyecto.
readonly CLAVES_LOCK='schema starter_version starter_commit slug tipo tier metodologia stack visibilidad generated_at'
leer_lock() {
	local f=$1 linea n=0 seccion=cabecera clave ruta
	local -a esperadas
	read -r -a esperadas <<<"$CLAVES_LOCK"
	declare -gA LOCK=() LOCK_M=() LOCK_S=()
	[[ -f $f ]] || die "no existe el lock $f"
	while IFS= read -r linea || [[ -n $linea ]]; do
		n=$((n + 1))
		if ((n == 1)); then
			[[ $linea == "$LOCK_COMENTARIO" ]] || die "lock $f:1: falta el comentario inicial"
			continue
		fi
		case $seccion in
		cabecera)
			if [[ $linea == '#'* && ${#LOCK[@]} -eq 0 ]]; then continue; fi
			if [[ $linea == --managed-- ]]; then
				((${#LOCK[@]} == ${#esperadas[@]})) || die "lock $f:$n: faltan claves de cabecera antes de --managed--"
				seccion=managed
				continue
			fi
			clave=${esperadas[${#LOCK[@]}]:-}
			[[ -n $clave && $linea == "$clave="* ]] || die "lock $f:$n: se esperaba '${clave:---managed--}=…' y hay '$linea'"
			LOCK[$clave]=${linea#*=}
			;;
		managed | seeded)
			if [[ $seccion == managed && $linea == --seeded-- ]]; then
				seccion=seeded
				continue
			fi
			[[ $linea =~ ^([0-9a-f]{64})\ \ ([^[:space:]\\]+)$ ]] || die "lock $f:$n: entrada inválida '$linea'"
			ruta=${BASH_REMATCH[2]}
			[[ $ruta != /* && $ruta != */ && $ruta != *//* && /$ruta/ != */../* && /$ruta/ != */./* ]] ||
				die "lock $f:$n: ruta no permitida '$ruta'"
			[[ -z ${LOCK_M[$ruta]:-} && -z ${LOCK_S[$ruta]:-} ]] || die "lock $f:$n: ruta repetida '$ruta'"
			if es_managed "$ruta"; then
				[[ $seccion == managed ]] || die "lock $f:$n: '$ruta' es managed y está en --seeded--"
			else
				[[ $seccion == seeded ]] || die "lock $f:$n: '$ruta' es seeded y está en --managed--"
			fi
			if [[ $seccion == managed ]]; then LOCK_M[$ruta]=${BASH_REMATCH[1]}; else LOCK_S[$ruta]=${BASH_REMATCH[1]}; fi
			;;
		esac
	done <"$f"
	[[ $seccion == seeded ]] || die "lock $f: faltan los marcadores --managed-- y --seeded--"
	[[ ${LOCK[schema]} == 1 ]] || die "lock $f: schema '${LOCK[schema]}' no soportado (solo 1)"
	# stack: perfiles con la regex del slug, ordenados con LC_ALL=C y sin duplicados.
	local re_stack="^(${RE_SLUG:1:-1})(,(${RE_SLUG:1:-1}))*$"
	if [[ -n ${LOCK[stack]} ]]; then
		[[ ${LOCK[stack]} =~ $re_stack &&
			$(tr , '\n' <<<"${LOCK[stack]}" | LC_ALL=C sort -u | paste -sd,) == "${LOCK[stack]}" ]] ||
			die "lock $f: stack '${LOCK[stack]}' no está normalizado (perfiles ordenados, sin duplicados ni vacíos)"
	fi
	validar_tier "${LOCK[tier]}"
	validar_tipo "${LOCK[tipo]}"
}

# escribir_lock <archivo>. Requiere las variables de cabecera, RUTAS y FUENTE.
# Managed: hash del archivo copiado. Seeded: hash de la fuente sin renderizar.
escribir_lock() {
	local out=$1 r
	{
		printf '%s\n' "$LOCK_COMENTARIO"
		printf 'schema=1\n'
		printf 'starter_version=%s\n' "$STARTER_VERSION"
		printf 'starter_commit=%s\n' "$STARTER_COMMIT"
		printf 'slug=%s\n' "$SLUG"
		printf 'tipo=%s\n' "$TIPO"
		printf 'tier=%s\n' "$TIER"
		printf 'metodologia=%s\n' "$METODOLOGIA"
		printf 'stack=%s\n' "$STACK_NORMALIZADO"
		printf 'visibilidad=%s\n' "$VISIBILIDAD"
		printf 'generated_at=%s\n' "$GENERATED_AT"
		printf -- '--managed--\n'
		for r in "${RUTAS[@]}"; do
			if es_managed "$r"; then printf '%s  %s\n' "$(_sha "$STARTER_ROOT/template/${FUENTE[$r]}")" "$r"; fi
		done
		printf -- '--seeded--\n'
		for r in "${RUTAS[@]}"; do
			if ! es_managed "$r"; then printf '%s  %s\n' "$(_sha "$STARTER_ROOT/template/${FUENTE[$r]}")" "$r"; fi
		done
	} >"$out"
}
