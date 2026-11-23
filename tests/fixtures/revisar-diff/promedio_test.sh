#!/usr/bin/env bash
set -euo pipefail
[[ $(bash promedio.sh 2 4 6) == 4 ]] && echo "PASA 2 4 6"
! bash promedio.sh 2 x 2>/dev/null && echo "PASA no numérico"
