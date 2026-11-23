# Plan · demo-diff

| Hito | Nombre | Estado |
| --- | --- | --- |
| 1 | Promedio | En curso |

## Hito 1 · Promedio

- **Objetivo:** script que calcula el promedio entero de sus argumentos.
- **Criterio de aceptación:** `bash promedio.sh 2 4 6` imprime `4`; sin argumentos imprime `error: faltan números` en stderr y sale con 1; un argumento no numérico imprime `error: no es un número: <arg>` y sale con 1.

Tareas:
- [ ] Implementar `promedio.sh`.
- [ ] Prueba en `tests/promedio_test.sh`.
