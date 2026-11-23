# Spec · demo-diseno

## Problema y usuario
Los cocineros pierden minutos buscando recetas en carpetas compartidas durante el servicio.

## Objetivos
- Encontrar cualquier receta por nombre o ingrediente.

## No-objetivos
- Costeo e inventario.

## Requisitos
- R1. Búsqueda por nombre e ingrediente, tolerante a acentos.
- R2. Alta y edición de recetas, solo para el jefe de cocina.
- Criterio de aceptación de R1: la búsqueda debe ser rápida e intuitiva.
- Criterio de aceptación de R2: el jefe de cocina da de alta una receta con nombre, ingredientes y pasos, y aparece en la búsqueda en menos de 5 segundos.

## Diseño
Aplicación web con SQLite y búsqueda de texto completo (FTS5). Una sola cuenta de administrador.

## Pruebas y verificación

## Riesgos y preguntas abiertas
- El wifi de la cocina puede fallar en horas pico.
