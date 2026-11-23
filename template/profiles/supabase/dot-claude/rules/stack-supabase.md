---
paths:
  - "supabase/**"
  - "**/supabase/**"
---
# Supabase (CLI v3)
Verificado el 2026-11-23 con la documentación de Supabase y el changelog de la CLI v3.
- Los comandos de base de datos y `gen types` usan el stack local por defecto. El proyecto alojado se apunta con `--remote`, que reemplaza a `--linked`, `--project-ref` y `--db-url` (obsoletos, igual que `--local`).
- Todo cambio a un proyecto alojado pide confirmación y, sin terminal, falla salvo con `--yes`. No uses `--yes` ni `SUPABASE_YES` sin que la persona lo pida.
- Cambios de esquema solo con migraciones: `supabase migration new <nombre>` crea `supabase/migrations/<timestamp>_<nombre>.sql`. Nunca cambies la base remota directamente.
- Activa RLS en cada tabla de un esquema expuesto (`alter table … enable row level security;`) y crea sus políticas: sin RLS, cualquier rol con grant la lee y la escribe.
- Con Next.js: `@supabase/ssr` y `supabase.auth.getClaims()` para proteger páginas y datos; nunca confíes en `getSession()` en código de servidor. Variables: `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`.
