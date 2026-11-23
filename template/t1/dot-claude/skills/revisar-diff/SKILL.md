---
name: revisar-diff
description: Revisión goldfish del diff sin commitear contra el criterio de aceptación de un hito de docs/plan.md. Uso /revisar-diff N.
argument-hint: "[N]"
disable-model-invocation: true
context: fork
agent: goldfish-revisor
background: false
allowed-tools: Bash(git diff HEAD) Bash(git ls-files --others --exclude-standard)
---
Revisa el diff contra el criterio del hito $0. No modifiques nada.

## Hito $0 en docs/plan.md
Localiza con Grep la línea que empieza por `## Hito $0 ` en `docs/plan.md` y léela con Read (`offset` en esa línea y `limit` suficiente) hasta el siguiente encabezado `## `. No uses Bash para esto. Es el criterio contra el que revisas.

Si no existe esa sección, el hito $0 no existe en `docs/plan.md`: dilo y termina sin revisar.

## Diff sin commitear (git diff HEAD)
````diff
!`git diff HEAD`
````

## Archivos nuevos sin seguimiento
Léelos con Read; forman parte del cambio.
!`git ls-files --others --exclude-standard`

## Tarea
Comprueba si el diff cumple el criterio de aceptación del hito $0 y busca defectos en lo que cambió: casos borde sin manejar, errores silenciosos, regresiones y contradicciones con el criterio. Si el diff y la lista de archivos nuevos están vacíos, di que no hay nada que revisar.
