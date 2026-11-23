---
paths:
  - "**/__manifest__.py"
  - "**/*.py"
  - "**/*.xml"
  - "**/security/*.csv"
---
# Addons de Odoo (19.0 y 20.0)
Verificado el 2026-11-23 con la documentación de Odoo 19.0 y 20.0.
- La versión de Odoo es la del `version` de `__manifest__.py`; consulta la documentación de esa versión. 20.0 pide Python 3.12 o superior; 19.0, 3.10 o superior.
- Permisos: sin reglas de acceso, ningún usuario ve el modelo. En 19.0 van en `security/ir.model.access.csv` (modelo `ir.model.access`); en 20.0, en `security/ir.access.csv` (modelo `ir.access`). Cada modelo nuevo lleva las suyas.
- Vistas en `views/<modelo>_views.xml`. La raíz de una vista de lista es `<list>` (antes `<tree>`).
- Tests en el subpaquete `tests/`, en módulos `test_*.py` importados desde `tests/__init__.py`; los que no se importan no corren.
- Nunca llames `cr.commit()` ni `cr.rollback()`. Si uno es imprescindible, lleva un comentario explícito que explique por qué.
