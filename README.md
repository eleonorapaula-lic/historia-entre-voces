# Historia entre voces — actualización de interfaz

Esta actualización conserva `config.js` y el diseño de las salas existentes.

## Instalar
1. En Supabase → SQL Editor ejecutá **solo `mejoras.sql`**. No hace falta repetir `schema.sql` ni `actualizacion.sql`.
2. En GitHub Pages reemplazá `index.html` por el incluido en este ZIP. Conservá el `config.js` que ya tenés configurado con tus credenciales públicas de Supabase (el archivo incluido es solo una plantilla).
3. Esperá a que se actualice GitHub Pages y recargá la página.

## Cambios
- El formulario Ingreso docente desaparece tras entrar correctamente, incluso tras una sesión guardada.
- Si hay un solo turno, no aparecen ni «Turno 1 de 1» ni «Actualizar turno».
- Debajo del formulario del estudiante aparece «Autores de esta historia» con el nombre de quienes **ya enviaron** una intervención, sin incluir textos. Nombres repetidos se muestran una sola vez. La lista se consulta de nuevo automáticamente cada 12 segundos en las salas de un turno.

Los participantes se identifican por el nombre que escriben al enviar su texto, sin registro previo. El enlace de la sala da acceso a esta lista de nombres, pero nunca al relato completo.
