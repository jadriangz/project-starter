---
name: bitacora
description: Redacta la entrada de portafolio del proyecto (content/projects/<slug>.md) respetando la visibilidad del lock. No publica nada.
disable-model-invocation: true
---
Redacta la entrada de bitácora para el portafolio. No escribas en otros repos ni publiques nada: muestra la entrada en la respuesta.

## Datos del proyecto
Lee `.claude/starter.lock` con Read y toma `slug`, `tipo`, `tier`, `metodologia`, `stack` y `visibilidad` de su cabecera. No uses Bash para esto.

Fuentes: `docs/brief.md`, `docs/spec.md`, `docs/plan.md` y `docs/bitacora.md`. No leas secretos.

Visibilidad (manda la del lock):
- `publico`: entrada completa, con enlaces al repo si existen.
- `anonimizado`: sin nombres de clientes, empresas, personas, dominios ni enlaces al repo. Antes de la entrada, lista cada nombre que encontraste en las fuentes y cómo lo sustituiste (por ejemplo, "un cliente del sector logístico"). Ninguno de ellos aparece en la entrada.
- `privado`: no se publica. Dilo y ofrece solo un resumen interno para `docs/bitacora.md`.

Formato de la entrada (frontmatter y secciones):

```markdown
---
slug:
titulo:
tipo:
visibilidad:
estado: en-curso | terminado | pausado
inicio: AAAA-MM
fin: null
tier:
metodologia:
rol:
stack: []
destacado: false
enlaces: { repo: , demo: , caso: }
---

## Problema
## Enfoque (decisiones clave y por qué)
## Solución
## Cómo se usó Claude Code
## Resultados
## Aprendizajes
```

No inventes métricas ni resultados: si un dato no está en las fuentes, deja la sección con "Pendiente" y dilo al final.
