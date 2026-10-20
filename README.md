# Historia entre voces — versión simple GitHub Pages + Supabase

## Corrección de pgcrypto
Esta versión utiliza `extensions.crypt` y `extensions.gen_salt`, porque Supabase suele instalar `pgcrypto` en el esquema `extensions`.

## Ya ejecutaste el primer script SQL
No hace falta borrar el proyecto ni ejecutar `schema.sql` de nuevo.

1. Abrí `actualizacion.sql`, reemplazá **CAMBIA_ESTA_CLAVE** por tu contraseña docente (entre comillas simples; si tiene `'`, duplicala: `''`).
2. Pegá y ejecutá el contenido de `actualizacion.sql` en el **SQL Editor** de Supabase. Esto mantiene tus salas e intervenciones, crea funciones para contraseña docente y deshabilita los accesos docentes de la versión anterior.
3. En Supabase → **Authentication → Providers**, habilitá **Anonymous Sign-Ins**. Aunque parezca una cuenta, sucede automáticamente: los alumnos *solo escriben su nombre*.
4. En `config.js`, ingresá URL y **publishable/anon key** de tu proyecto Supabase. **Nunca** pegues `service_role` o una clave secreta en un sitio público.
5. Subí `index.html` y `config.js` a GitHub Pages (Settings → Pages → Deploy from a branch). El SQL y README no tienen que estar en la web.
6. Abrí el enlace de Pages y pulsá **Soy docente**, ingresá la contraseña y creá la sala. Usá **Copiar enlace** para enviarlo.
7. Los alumnos abren el enlace, escriben su nombre y su intervención. No ingresan contraseña y no pueden leer el texto completo.

### Consideraciones
- La contraseña **no está guardada en el código público**; se verifica en Supabase. Por simplicidad, el navegador docente la mantiene durante esa pestaña (sessionStorage) y la envía al servidor para cada operación. Usá tu equipo personal y cerrá el panel al terminar.
- Es una contraseña compartida para **todas las salas** del proyecto, no cuentas individuales.
- Mantuvimos el funcionamiento previo: varias propuestas por turno, docente selecciona cuál incorporar, después continúa el siguiente turno. La página estudiantil tiene botón para actualizar el turno.
- Para cambiar la contraseña, volvé a ejecutar solo el `INSERT INTO public.hev_settings ... ON CONFLICT ...` de `actualizacion.sql`, con una nueva clave.
- No se trata de seguridad de alto riesgo, pero no publiques la contraseña ni uses una contraseña reutilizada de otra cuenta.
