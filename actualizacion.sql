-- Ejecutar DESPUÉS del schema.sql que ya ejecutaste.
-- IMPORTANTE: reemplazá CAMBIA_ESTA_CLAVE por tu contraseña docente.
create table if not exists public.hev_settings (
 singleton boolean primary key default true check (singleton),
 password_hash text not null
);
alter table public.hev_settings enable row level security;
revoke all on public.hev_settings from public, anon, authenticated;
insert into public.hev_settings(singleton,password_hash)
values(true,crypt('Jonas1907', gen_salt('bf')))
on conflict (singleton) do update set password_hash=excluded.password_hash;

create or replace function public.hev_check_teacher(p_password text)
returns boolean language sql security definer set search_path = '' as $$
 select exists(select 1 from public.hev_settings where singleton=true
 and password_hash=public.crypt(coalesce(p_password,''),password_hash));
$$;

create or replace function public.hev_simple_create(p_password text,p_title text,p_context text,p_opening text,p_max_turns integer)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.hev_rooms;
begin
 if not public.hev_check_teacher(p_password) then raise exception 'Contraseña docente incorrecta'; end if;
 if auth.uid() is null then raise exception 'No se pudo iniciar la sesión'; end if;
 insert into public.hev_rooms(owner_id,title,context,opening,max_turns)
 values(auth.uid(),trim(p_title),trim(p_context),trim(p_opening),p_max_turns) returning * into r;
 return jsonb_build_object('id',r.id,'token',r.invite_token);
end $$;

create or replace function public.hev_simple_rooms(p_password text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
 if not public.hev_check_teacher(p_password) then raise exception 'Contraseña docente incorrecta'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'token',invite_token,'title',title,'status',status,'turn',current_turn,'max_turns',max_turns) order by created_at desc),'[]'::jsonb)
 into result from public.hev_rooms;
 return result;
end $$;

create or replace function public.hev_simple_state(p_password text,p_room uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.hev_rooms; a jsonb; e jsonb;
begin
 if not public.hev_check_teacher(p_password) then raise exception 'Contraseña docente incorrecta'; end if;
 select * into r from public.hev_rooms where id=p_room;
 if not found then raise exception 'Sala inexistente'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',participant_name,'body',body,'turn',turn_number,'accepted',accepted) order by created_at),'[]'::jsonb)
 into e from public.hev_entries where room_id=r.id and (turn_number=r.current_turn or accepted);
 select coalesce(jsonb_agg(jsonb_build_object('turn',turn_number,'name',participant_name,'body',body) order by turn_number),'[]'::jsonb)
 into a from public.hev_entries where room_id=r.id and accepted;
 return jsonb_build_object('title',r.title,'context',r.context,'opening',r.opening,'token',r.invite_token,'turn',r.current_turn,'max_turns',r.max_turns,'status',r.status,'entries',e,'accepted',a);
end $$;

create or replace function public.hev_simple_approve(p_password text,p_room uuid,p_entry uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.hev_rooms; n integer;
begin
 if not public.hev_check_teacher(p_password) then raise exception 'Contraseña docente incorrecta'; end if;
 select * into r from public.hev_rooms where id=p_room for update;
 if not found then raise exception 'Sala inexistente'; end if;
 if r.status <> 'open' then raise exception 'Sala cerrada'; end if;
 update public.hev_entries set accepted=true where id=p_entry and room_id=r.id and turn_number=r.current_turn and not accepted;
 get diagnostics n = row_count;
 if n<>1 then raise exception 'Intervención no disponible'; end if;
 update public.hev_rooms set current_turn=current_turn+1,status=case when current_turn>=max_turns then 'closed' else 'open' end where id=r.id;
 return jsonb_build_object('ok',true);
end $$;

create or replace function public.hev_simple_close(p_password text,p_room uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare n integer;
begin
 if not public.hev_check_teacher(p_password) then raise exception 'Contraseña docente incorrecta'; end if;
 update public.hev_rooms set status='closed' where id=p_room;
 get diagnostics n = row_count;
 if n<>1 then raise exception 'Sala inexistente'; end if;
 return jsonb_build_object('ok',true);
end $$;

-- Cerrar las funciones docentes anteriores para evitar accesos sin contraseña.
revoke execute on function public.hev_create_room(text,text,text,integer), public.hev_my_rooms(), public.hev_teacher_state(uuid), public.hev_approve(uuid,uuid), public.hev_close(uuid) from public, anon, authenticated;
revoke execute on function public.hev_check_teacher(text),public.hev_simple_create(text,text,text,text,integer),public.hev_simple_rooms(text),public.hev_simple_state(text,uuid),public.hev_simple_approve(text,uuid,uuid),public.hev_simple_close(text,uuid) from public,anon;
grant execute on function public.hev_check_teacher(text),public.hev_simple_create(text,text,text,text,integer),public.hev_simple_rooms(text),public.hev_simple_state(text,uuid),public.hev_simple_approve(text,uuid,uuid),public.hev_simple_close(text,uuid) to authenticated;
