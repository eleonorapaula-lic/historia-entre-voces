# Historia entre voces — GitHub Pages + Supabase

Esta versión reemplaza Firebase. **GitHub Pages publica los archivos estáticos** y **Supabase almacena salas e intervenciones**. El proyecto no incluye credenciales: debes configurar las tuyas. No existe un enlace público hasta que publiques el repositorio.

## Puesta en marcha

1. Crea un proyecto en https://supabase.com/dashboard.
2. En **SQL Editor**, ejecuta el archivo `schema.sql` completo. Crea dos tablas privadas y siete funciones RPC. Comprueba los mensajes de error en el editor.
3. En **Authentication > Providers**, habilita **Anonymous Sign-Ins** para estudiantes. Si hay uso abierto al público, considera protección antiabuso/CAPTCHA desde el panel de Supabase.
4. En **Authentication > Users**, crea/invita tu cuenta docente con correo y contraseña. Debe ser una cuenta **normal**, no anónima. Activa un método de confirmación de correo si el panel lo requiere. No compartas esa cuenta.
5. En **Project Settings > API Keys** (la denominación exacta puede variar), copia la **Project URL** y la **publishable key** a `config.js`. **Nunca** pegues la `service_role`, `secret key` ni contraseñas en archivos GitHub.
6. Sube `index.html`, `config.js` y, si deseas, `README.md` al directorio publicado por GitHub Pages. `schema.sql` puede quedarse en el repositorio, pero no contiene secretos.
7. En GitHub: **Settings > Pages > Deploy from a branch**, elige tu rama y carpeta raíz; abre la URL publicada.
8. Haz clic en **Soy docente**, inicia sesión, crea una sala y copia el enlace generado. Comparte el enlace por Moodle/WhatsApp. Los estudiantes ingresan sin registro desde su celular.
9. Desde tu panel docente, **Actualizar propuestas** para ver los aportes del turno; al aprobar uno, se muestra a los siguientes solo el fragmento final de ese aporte. Cierra o descarga el relato cuando quieras.

## Seguridad y alcance

- Las tablas tienen RLS habilitado y **no permiten SELECT directo a estudiantes**. Solo se accede mediante funciones RPC que comprueban la identidad y devuelven campos específicos.
- `hev_student_state` devuelve **contexto + fragmento del turno**, nunca el conjunto de aportes. `hev_teacher_state` solo responde a quien creó la sala con una cuenta de Supabase Auth no anónima.
- `hev_submit` permite **una intervención por cuenta anónima y por turno**. Una persona que borre cookies o abra otro navegador podría obtener otra cuenta anónima; esto no equivale a verificar identidad institucional.
- El enlace de sala se comporta como invitación: quien lo reciba puede participar. No lo publiques indiscriminadamente.
- El texto final se mantiene privado para alumnos dentro de la app, aunque **la docente puede compartirlo fuera de ella**. Las contraseñas y autorizaciones se validan en Supabase, no en HTML.
- No hay refresco automático: usa los botones **Actualizar**. No se elimina el historial de propuestas no aceptadas de la base de datos; solo se muestran en el turno actual del panel.
- **No probado contra una instancia real de Supabase** en esta sesión: se requiere realizar una prueba de extremo a extremo con dos navegadores (docente y estudiante) antes de usar con el curso.

## Por qué no guardar en un archivo de GitHub Pages

GitHub Pages es alojamiento **estático**: el JavaScript descargado por visitantes no puede actualizar por sí solo un archivo del repositorio. Automatizar escritura vía la API de GitHub exigiría un intermediario seguro para guardar el token, que funcionaría como backend. Supabase elimina esa necesidad.

## Archivos

- `index.html`: aplicación web para docente y estudiantes.
- `config.js`: datos públicos de tu proyecto Supabase (se deben completar).
- `schema.sql`: base de datos, reglas de permisos y funciones.
