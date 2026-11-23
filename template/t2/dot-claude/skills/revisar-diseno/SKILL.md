---
name: revisar-diseno
description: Revisión goldfish del diseño (brief, PRD y spec) antes de implementar. Busca secciones vacías, criterios no medibles y contradicciones.
disable-model-invocation: true
context: fork
agent: goldfish-revisor
background: false
---
Revisa el diseño del proyecto como alguien que lo lee por primera vez. No modifiques nada.

Lee con Read, en este orden: `docs/brief.md`, `docs/prd.md`, `docs/spec.md` y los ADR de `docs/adr/` (salvo `0000-plantilla.md`). Si falta alguno, es un hallazgo.

Busca:
1. Secciones vacías, con solo comentarios de plantilla (`<!-- … -->`) o con "por definir".
2. Criterios de aceptación no medibles: sin número, umbral, caso concreto ni forma de comprobarlo ("rápido", "intuitivo", "robusto").
3. Contradicciones entre documentos (alcance, usuarios, requisitos, decisiones).
4. Requisitos sin criterio de aceptación y criterios sin requisito.
5. Preguntas que tendrías que hacer antes de implementar.

En cada hallazgo, cita el archivo y la sección. Termina con la lista de preguntas abiertas.
