# Historia entre voces — Últimas 15 palabras

## Instalación

1. Ejecutar `ultimas_15_palabras.sql` en el SQL Editor de Supabase.
2. Sustituir `index.html` en GitHub Pages por el incluido aquí.
3. **Conservar el `config.js` que ya tenés configurado** (el incluido es solo una plantilla).
4. Recargar la página publicada (si es necesario, actualización forzada).

## Comportamiento

- La pantalla del participante muestra la etiqueta **ÚLTIMAS 15 PALABRAS** y solo esas palabras del relato acumulado.
- Las palabras proceden del texto de inicio más todas las propuestas enviadas, ordenadas por envío. Se actualiza cada 6 segundos.
- El relato completo docente concatena las aportaciones sin incluir nombres de autor.
- La lista «Autores de esta historia» sigue mostrando nombres por separado.
- No se borran datos ni salas. El SQL no modifica ni elimina tablas.

**Observación didáctica:** en salas de múltiples turnos, las propuestas enviadas se suman todas al relato aunque solo una sea seleccionada para avanzar de turno. La aprobación sirve para controlar el avance, no para elegir qué textos quedan en la narración.
