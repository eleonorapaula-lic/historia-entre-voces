-- Historia entre voces: mostrar exclusivamente las últimas 15 palabras
-- del relato acumulado (inicio + todas las intervenciones enviadas).
-- Conservar tablas, contraseñas y datos existentes.
create or replace function public.hev_student_state(p_token uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  r public.hev_rooms;
  full_text text;
  final_fragment text;
begin
  select * into r from public.hev_rooms where invite_token = p_token;
  if not found then raise exception 'Sala inexistente'; end if;

  select concat_ws(' ', r.opening,
    (select string_agg(body, ' ' order by created_at, id)
     from public.hev_entries where room_id = r.id)) into full_text;

  select coalesce(string_agg(word, ' ' order by position), '') into final_fragment
  from (
    select word, position
    from regexp_split_to_table(trim(full_text), '[[:space:]]+') with ordinality as words(word,position)
    order by position desc
    limit 15
  ) last_words;

  return jsonb_build_object(
    'title', r.title, 'context', r.context,
    'fragment', final_fragment,
    'turn', r.current_turn,
    'max_turns', r.max_turns,
    'status', r.status
  );
end $$;
revoke all on function public.hev_student_state(uuid) from public, anon;
grant execute on function public.hev_student_state(uuid) to authenticated;
