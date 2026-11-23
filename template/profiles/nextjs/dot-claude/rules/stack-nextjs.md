---
paths:
  - "app/**"
  - "src/app/**"
  - "proxy.ts"
  - "src/proxy.ts"
  - "next.config.*"
---
# Next.js 16 (App Router)
Verificado el 2026-11-23 con la documentación de Next.js 16.4.
- Layouts y pages son Server Components por defecto. `'use client'` va al inicio del archivo, antes de los imports, y marca la frontera: todo lo que ese archivo importa entra al bundle del cliente.
- `cookies()`, `headers()`, `draftMode()`, `params` y `searchParams` solo son asíncronos: siempre con `await`.
- `middleware.ts` ahora es `proxy.ts`, con la función exportada `proxy`. Corre solo en Node; si hace falta runtime edge, se mantiene `middleware`.
- `next lint` ya no existe y `next build` no lintea: usa el script del linter del proyecto (ESLint o Biome).
- Turbopack es el bundler por defecto en `next dev` y `next build`. `npx next typegen` genera los tipos de rutas (`PageProps`, `LayoutProps`) sin compilar.
