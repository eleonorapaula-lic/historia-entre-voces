-- Historia entre voces / ejecutar en SQL Editor de Supabase.
create extension if not exists pgcrypto;
create table if not exists public.hev_rooms (
 id uuid primary key default gen_random_uuid(),
 invite_token uuid unique not null default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 title text not null check (char_length(title) between 2 and 150),
 context text not null check (char_length(context) between 5 and 4000),
 opening text not null check (char_length(opening) between 5 and 2000),
 max_turns integer not null check (max_turns between 1 and 100),
 current_turn integer not null default 1,
 status text not null default 'open' check (status in ('open','closed')),
 created_at timestamptz not null default now()
);
create table if not exists public.hev_entries (
 id uuid primary key default gen_random_uuid(),
 room_id uuid not null references public.hev_rooms(id) on delete cascade,
 turn_number integer not null,
 participant_id uuid not null references auth.users(id),
 participant_name text not null check(char_length(participant_name) between 1 and 70),
 body text not null check(char_length(body) between 10 and 2000),
 accepted boolean not null default false,
 created_at timestamptz not null default now(),
 unique(room_id, turn_number, participant_id)
);
create unique index if not exists hev_one_accepted_per_turn on public.hev_entries(room_id,turn_number) where accepted;
alter table public.hev_rooms enable row level security;
alter table public.hev_entries enable row level security;
revoke all on public.hev_rooms, public.hev_entries from anon, authenticated, public;
-- Todo acceso pasa por funciones SECURITY DEFINER con comprobaciones propias.
create or replace function public.hev_create_room(p_title text,p_context text,p_opening text,p_max_turns integer)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.hev_rooms;
begin
 if auth.uid() is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,true) then raise exception 'Se requiere cuenta docente'; end if;
 insert into public.hev_rooms(owner_id,title,context,opening,max_turns)
 values(auth.uid(),trim(p_title),trim(p_context),trim(p_opening),p_max_turns) returning * into r;
 return jsonb_build_object('id',r.id,'token',r.invite_token);
end $$;
create or replace function public.hev_my_rooms()
returns jsonb language sql security definer set search_path = '' as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'token',invite_token,'title',title,'status',status,'turn',current_turn,'max_turns',max_turns) order by created_at desc),'[]'::jsonb)
 from public.hev_rooms where owner_id = auth.uid() and coalesce((auth.jwt()->>'is_anonymous')::boolean,true)=false;
$$;
create or replace function public.hev_student_state(p_token uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.hev_rooms; previous text;
begin
 select * into r from public.hev_rooms where invite_token=p_token;
 if not found then raise exception 'Sala inexistente'; end if;
 select body into previous from public.hev_entries where room_id=r.id and accepted and turn_number=r.current_turn-1;
 return jsonb_build_object('title',r.title,'context',r.context,'fragment',case when r.current_turn=1 then r.opening else right(coalesce(previous,''),240) end,
 'turn',r.current_turn,'max_turns',r.max_turns,'status',r.status);
end $$;
create or replace function public.hev_submit(p_token uuid,p_name text,p_body text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.hev_rooms; inserted_id uuid;
begin
 if auth.uid() is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false then raise exception 'Ingresá como estudiante'; end if;
 select * into r from public.hev_rooms where invite_token=p_token for update;
 if not found or r.status <> 'open' then raise exception 'Sala cerrada o inexistente'; end if;
 if trim(coalesce(p_name,''))='' or char_length(p_name)>70 or char_length(trim(coalesce(p_body,''))) not between 10 and 2000 then raise exception 'Revisá el nombre y el texto (10 a 2000 caracteres)'; end if;
 insert into public.hev_entries(room_id,turn_number,participant_id,participant_name,body)
 values(r.id,r.current_turn,auth.uid(),trim(p_name),trim(p_body)) returning id into inserted_id;
 return jsonb_build_object('ok',true,'submission_id',inserted_id,'turn',r.current_turn);
exception when unique_violation then raise exception 'Ya enviaste una propuesta en este turno';
end $$;
create or replace function public.hev_teacher_state(p_room uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.hev_rooms; a jsonb; e jsonb;
begin
 select * into r from public.hev_rooms where id=p_room and owner_id=auth.uid() and coalesce((auth.jwt()->>'is_anonymous')::boolean,true)=false;
 if not found then raise exception 'Sin permiso'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',participant_name,'body',body,'turn',turn_number,'accepted',accepted) order by created_at),'[]'::jsonb)
 into e from public.hev_entries where room_id=r.id and (turn_number=r.current_turn or accepted);
 select coalesce(jsonb_agg(jsonb_build_object('turn',turn_number,'name',participant_name,'body',body) order by turn_number),'[]'::jsonb)
 into a from public.hev_entries where room_id=r.id and accepted;
 return jsonb_build_object('title',r.title,'context',r.context,'opening',r.opening,'token',r.invite_token,'turn',r.current_turn,'max_turns',r.max_turns,'status',r.status,'entries',e,'accepted',a);
end $$;
create or replace function public.hev_approve(p_room uuid,p_entry uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.hev_rooms; n integer;
begin
 select * into r from public.hev_rooms where id=p_room and owner_id=auth.uid() for update;
 if not found then raise exception 'Sin permiso'; end if;
 if r.status <> 'open' then raise exception 'Sala cerrada'; end if;
 update public.hev_entries set accepted=true where id=p_entry and room_id=r.id and turn_number=r.current_turn and not accepted;
 get diagnostics n = row_count;
 if n<>1 then raise exception 'Intervención no disponible'; end if;
 update public.hev_rooms set current_turn=current_turn+1,status=case when current_turn>=max_turns then 'closed' else 'open' end where id=r.id;
 return jsonb_build_object('ok',true);
end $$;
create or replace function public.hev_close(p_room uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare n integer;
begin
 update public.hev_rooms set status='closed' where id=p_room and owner_id=auth.uid();
 get diagnostics n = row_count;
 if n<>1 then raise exception 'Sin permiso'; end if;
 return jsonb_build_object('ok',true);
end $$;
revoke all on function public.hev_create_room(text,text,text,integer), public.hev_my_rooms(), public.hev_student_state(uuid), public.hev_submit(uuid,text,text), public.hev_teacher_state(uuid),public.hev_approve(uuid,uuid),public.hev_close(uuid) from public;
grant execute on function public.hev_create_room(text,text,text,integer),public.hev_my_rooms(),public.hev_student_state(uuid),public.hev_submit(uuid,text,text),public.hev_teacher_state(uuid),public.hev_approve(uuid,uuid),public.hev_close(uuid) to authenticated;
