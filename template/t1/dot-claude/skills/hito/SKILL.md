---
name: hito
description: Prepara el plan de implementación de un solo hito de docs/plan.md, sin escribir código. Uso /hito N.
argument-hint: "[N]"
disable-model-invocation: true
---
Vamos a trabajar el hito $0, y solo ese.

## Hito $0 en docs/plan.md
Localiza con Grep la línea que empieza por `## Hito $0 ` en `docs/plan.md` y léela con Read (`offset` en esa línea y `limit` suficiente) hasta el siguiente encabezado `## `. No uses Bash para esto.

Si no existe esa sección, el hito $0 no existe: dilo y para.

Pasos:
1. Lee `docs/spec.md` y las partes del código que el hito toca. Si el hito anterior no está cerrado en `docs/plan.md`, avísalo antes de seguir.
2. Si no estás en plan mode, pide entrar en plan mode antes de seguir.
3. Propón el plan del hito: archivos a crear o cambiar, en orden; cómo verificarás cada criterio de aceptación; riesgos y preguntas abiertas.
4. Si el plan, la spec y el código difieren, pregunta cuál manda; no lo decidas tú.
5. No escribas código ni hagas commits hasta que el plan esté aprobado. Nada de otros hitos.
