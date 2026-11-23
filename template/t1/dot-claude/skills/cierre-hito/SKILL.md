---
name: cierre-hito
description: Cierra un hito de docs/plan.md: corre los checks, actualiza el plan y la bitácora y propone el commit sin hacerlo. Uso /cierre-hito N.
argument-hint: "[N]"
disable-model-invocation: true
allowed-tools: Bash(git status --short)
---
Cierre del hito $0. Nunca hagas commit, push ni tag en este skill: solo propón el mensaje.

## Hito $0 en docs/plan.md
Localiza con Grep la línea que empieza por `## Hito $0 ` en `docs/plan.md` y léela con Read (`offset` en esa línea y `limit` suficiente) hasta el siguiente encabezado `## `. No uses Bash para esto.

## Estado de git
!`git status --short`

Pasos, en orden. Si uno falla, informa y para; no marques nada como cerrado:
1. Si no existe la sección del hito, el hito $0 no existe: dilo y para.
2. Corre los checks de la sección "Comandos" de `CLAUDE.md` (tests, lint, build). Informa cada uno con su resultado. Si un check falla o no existe ninguno, el hito no se cierra.
3. Comprueba cada criterio de aceptación del hito, uno por uno, con evidencia (salida de un comando, archivo y línea). Si alguno no se cumple o no se puede comprobar, el hito no se cierra.
4. Pregunta si ya se hizo la revisión goldfish con `/revisar-diff $0` y si se atendieron sus hallazgos altos. Si no, pide que la ejecute el usuario (este skill no puede invocarla) y para.
5. Con todo verde: en `docs/plan.md`, marca las tareas hechas y pon el hito en estado "Cerrado" con la fecha de hoy; añade la entrada del hito en `docs/bitacora.md` (qué se hizo, decisiones, hallazgos goldfish y cómo se resolvieron).
6. Muestra el resumen y propón un mensaje de commit. No lo ejecutes.
