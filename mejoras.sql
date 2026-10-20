-- Historia entre voces: listado público de nombres, sin textos ni contraseñas.
-- Ejecutar en Supabase → SQL Editor, después de los scripts anteriores.
create or replace function public.hev_participant_names(p_token uuid)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare v_room uuid; result jsonb;
begin
  select id into v_room from public.hev_rooms where invite_token = p_token;
  if v_room is null then raise exception 'Sala inexistente'; end if;
  select coalesce(jsonb_agg(participant_name order by first_sent), '[]'::jsonb)
    into result
    from (
      select participant_name, min(created_at) as first_sent
      from public.hev_entries
      where room_id = v_room
      group by participant_name
    ) names;
  return result;
end $$;
revoke all on function public.hev_participant_names(uuid) from public, anon;
grant execute on function public.hev_participant_names(uuid) to authenticated;
