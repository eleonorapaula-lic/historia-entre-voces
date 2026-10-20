-- HISTORIA ENTRE VOCES — REINICIO DE DATOS DE PRUEBA
-- Ejecutar en Supabase > SQL Editor.
-- ADVERTENCIA: elimina DEFINITIVAMENTE todas las salas y textos enviados.
-- Conserva: tablas, índices, funciones, políticas RLS, configuración,
-- contraseña docente (hev_settings), autenticación y claves de Supabase.
-- Los enlaces anteriores a salas dejarán de funcionar.

begin;

-- Primero los envíos y participantes (nombres asociados a envíos).
delete from public.hev_entries;

-- Luego las salas / experiencias.
delete from public.hev_rooms;

commit;

-- Verificar que las tablas de trabajo estén vacías:
select 'Salas' as tipo, count(*) as registros from public.hev_rooms
union all
select 'Intervenciones / participantes', count(*) from public.hev_entries;
