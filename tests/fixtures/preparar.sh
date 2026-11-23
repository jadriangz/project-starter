#!/usr/bin/env bash
# Prepara un proyecto de prueba para verificar a mano un skill (docs/verificacion.md).
# Uso: tests/fixtures/preparar.sh revisar-diff|revisar-diseno|cierre-hito|cierre-hito-ok|bitacora
# Genera en un PROJECTS_ROOT temporal (nunca en ~/projects) con una identidad git
# de prueba, aplica el caso e imprime la ruta del proyecto en stdout.
# Los nombres de clientes y personas de los fixtures son ficticios.
set -euo pipefail

FIX=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NP=$FIX/../../bin/new-project
caso=${1:-}

R=$(mktemp -d)
limpiar() { local rc=$?; if ((rc != 0)); then rm -rf -- "$R"; fi; }
trap limpiar EXIT # si algo falla, no deja el temporal
mkdir "$R/personal" "$R/work"
printf '[user]\n\tname = Fixture\n\temail = fixture@example.invalid\n' >"$R/gitconfig"
export PROJECTS_ROOT=$R GIT_CONFIG_GLOBAL=$R/gitconfig GIT_CONFIG_NOSYSTEM=1

generar() {
	local salida
	salida=$("$NP" "$@" 2>&1) || { printf 'falló new-project %s:\n%s\n' "$*" "$salida" >&2; exit 1; }
}
usar_check() { # inserta el comando de test en la sección Comandos de CLAUDE.md
	# shellcheck disable=SC2016 # los backticks son markdown literal
	sed -i 's|^<!-- Completa: cómo instalar, correr, probar y revisar estilo. -->$|- Test: `bash tests/check.sh`|' CLAUDE.md
	grep -qF 'bash tests/check.sh' CLAUDE.md || { echo "fixture: no se pudo insertar el check en CLAUDE.md" >&2; exit 1; }
}
commit() { git add -A && git commit -qm "$1"; }

case $caso in
revisar-diff)
	# Defecto sembrado: promedio.sh divide por $# sin comprobar que haya argumentos.
	generar demo-diff --tipo personal --tier 1
	P=$R/personal/demo-diff
	cd "$P"
	cp "$FIX/revisar-diff/plan.md" docs/plan.md
	cp "$FIX/revisar-diff/promedio-base.sh" promedio.sh
	commit "docs: plan del hito 1 y esqueleto"
	cp "$FIX/revisar-diff/promedio.sh" promedio.sh # cambio sin commitear
	mkdir tests && cp "$FIX/revisar-diff/promedio_test.sh" tests/ # archivo sin seguimiento
	;;
revisar-diseno)
	# Omisiones sembradas: "Pruebas y verificación" vacía y un criterio no medible (R1).
	generar demo-diseno --tipo work --tier 2
	P=$R/work/demo-diseno
	cd "$P"
	cp "$FIX/revisar-diseno/brief.md" docs/brief.md
	cp "$FIX/revisar-diseno/prd.md" docs/prd.md
	cp "$FIX/revisar-diseno/spec.md" docs/spec.md
	commit "docs: diseño"
	;;
cierre-hito)
	# Check que falla: suma.sh suma 1 de más.
	generar demo-cierre --tipo personal --tier 1
	P=$R/personal/demo-cierre
	cd "$P"
	cp "$FIX/cierre-hito/plan.md" docs/plan.md
	cp "$FIX/cierre-hito/suma.sh" suma.sh
	mkdir tests && cp "$FIX/cierre-hito/check.sh" tests/check.sh
	usar_check
	commit "feat: suma"
	;;
cierre-hito-ok)
	# Camino verde: check que pasa y revisión goldfish registrada. Lo que se prueba es que no commitea.
	generar demo-cierre-ok --tipo personal --tier 1
	P=$R/personal/demo-cierre-ok
	cd "$P"
	sed 's/demo-cierre/demo-cierre-ok/' "$FIX/cierre-hito/plan.md" >docs/plan.md
	cp "$FIX/cierre-hito-ok/suma.sh" suma.sh
	mkdir tests && cp "$FIX/cierre-hito/check.sh" tests/check.sh
	cp "$FIX/cierre-hito-ok/bitacora.md" docs/bitacora.md
	usar_check
	commit "feat: suma"
	;;
bitacora)
	# Nombres sembrados: un cliente y una persona en docs/, con visibilidad anonimizado.
	generar demo-bitacora --tipo work --tier 1 --visibilidad anonimizado
	P=$R/work/demo-bitacora
	cd "$P"
	cp "$FIX/bitacora/brief.md" docs/brief.md
	cp "$FIX/bitacora/bitacora.md" docs/bitacora.md
	commit "docs: brief y bitácora"
	;;
*)
	echo "uso: $0 revisar-diff|revisar-diseno|cierre-hito|cierre-hito-ok|bitacora" >&2
	exit 2
	;;
esac
printf '%s\n' "$P"
