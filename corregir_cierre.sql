-- Historia entre voces: corrección de visualización de propuestas al finalizar.
-- Ejecutar en Supabase SQL Editor. Conserva todos los datos y la clave docente.
create or replace function public.hev_simple_state(p_password text,p_room uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.hev_rooms; a jsonb; e jsonb;
begin
 if not public.hev_check_teacher(p_password) then raise exception 'Contraseña docente incorrecta'; end if;
 select * into r from public.hev_rooms where id=p_room;
 if not found then raise exception 'Sala inexistente'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',participant_name,'body',body,'turn',turn_number,'accepted',accepted) order by turn_number,created_at),'[]'::jsonb)
 into e from public.hev_entries where room_id=r.id;
 select coalesce(jsonb_agg(jsonb_build_object('turn',turn_number,'name',participant_name,'body',body) order by turn_number),'[]'::jsonb)
 into a from public.hev_entries where room_id=r.id and accepted;
 return jsonb_build_object('title',r.title,'context',r.context,'opening',r.opening,'token',r.invite_token,'turn',r.current_turn,'max_turns',r.max_turns,'status',r.status,'entries',e,'accepted',a);
end $$;
revoke execute on function public.hev_simple_state(text,uuid) from public, anon;
grant execute on function public.hev_simple_state(text,uuid) to authenticated;
