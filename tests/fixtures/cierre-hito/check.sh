#!/usr/bin/env bash
r=$(bash suma.sh 2 2)
if [[ $r == 4 ]]; then echo "PASA suma 2 2 = 4"; else echo "FALLA suma 2 2 = $r (esperado 4)"; exit 1; fi
