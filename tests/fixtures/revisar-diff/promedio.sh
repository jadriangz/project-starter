#!/usr/bin/env bash
# Promedio entero de los argumentos.
set -euo pipefail
suma=0
for n in "$@"; do
	[[ $n =~ ^-?[0-9]+$ ]] || { echo "error: no es un número: $n" >&2; exit 1; }
	suma=$((suma + n))
done
echo $((suma / $#))
