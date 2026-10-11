-- Sol room runtime: seat claim/release, microphone state and a clearly named test room.
-- Additive migration; no existing room, wallet, or user data is deleted.

create unique index if not exists room_participants_active_seat_uidx
  on public.room_participants(room_id, seat_no)
  where left_at is null;

create unique index if not exists room_participants_active_member_uidx
  on public.room_participants(room_id, member_id)
  where left_at is null;

create or replace function public.claim_room_seat(
  p_room_id uuid,
  p_member_id uuid,
  p_seat_no integer default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_capacity integer;
  v_current_seat integer;
  v_seat integer;
begin
  if auth.uid() is null or p_member_id is distinct from auth.uid() then
    raise exception 'member_not_owned_by_current_user';
  end if;

  select seats into v_capacity
  from public.room_sessions
  where id = p_room_id and status = 'live'
  for update;

  if v_capacity is null then
    raise exception 'room_not_live';
  end if;

  select seat_no into v_current_seat
  from public.room_participants
  where room_id = p_room_id
    and member_id = p_member_id
    and left_at is null
  limit 1
  for update;

  if v_current_seat is not null then
    if p_seat_no is null or p_seat_no = v_current_seat then
      return v_current_seat;
    end if;
    if p_seat_no < 1 or p_seat_no > v_capacity then
      raise exception 'invalid_seat_no';
    end if;
    if exists (
      select 1 from public.room_participants
      where room_id = p_room_id
        and seat_no = p_seat_no
        and left_at is null
        and member_id <> p_member_id
    ) then
      raise exception 'seat_already_taken';
    end if;
    update public.room_participants
    set seat_no = p_seat_no
    where room_id = p_room_id
      and member_id = p_member_id
      and left_at is null;
    return p_seat_no;
  end if;

  if p_seat_no is null then
    select candidate into v_seat
    from generate_series(1, v_capacity) as series(candidate)
    where not exists (
      select 1 from public.room_participants rp
      where rp.room_id = p_room_id
        and rp.seat_no = candidate
        and rp.left_at is null
    )
    order by candidate
    limit 1;
  else
    if p_seat_no < 1 or p_seat_no > v_capacity then
      raise exception 'invalid_seat_no';
    end if;
    if exists (
      select 1 from public.room_participants
      where room_id = p_room_id
        and seat_no = p_seat_no
        and left_at is null
    ) then
      raise exception 'seat_already_taken';
    end if;
    v_seat := p_seat_no;
  end if;

  if v_seat is null then
    raise exception 'room_full';
  end if;

  insert into public.room_participants(room_id, member_id, seat_no, mic_enabled, camera_enabled, joined_at, left_at)
  values (p_room_id, p_member_id, v_seat, false, false, now(), null);

  return v_seat;
exception
  when unique_violation then
    raise exception 'seat_already_taken';
end;
$$;

create or replace function public.leave_room_seat(
  p_room_id uuid,
  p_member_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  if auth.uid() is null or p_member_id is distinct from auth.uid() then
    raise exception 'member_not_owned_by_current_user';
  end if;

  update public.room_participants
  set left_at = now(), mic_enabled = false
  where room_id = p_room_id
    and member_id = p_member_id
    and left_at is null;

  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

create or replace function public.set_room_mic(
  p_room_id uuid,
  p_member_id uuid,
  p_enabled boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  if auth.uid() is null or p_member_id is distinct from auth.uid() then
    raise exception 'member_not_owned_by_current_user';
  end if;

  update public.room_participants
  set mic_enabled = p_enabled
  where room_id = p_room_id
    and member_id = p_member_id
    and left_at is null;

  get diagnostics v_count = row_count;
  if v_count = 0 then
    raise exception 'seat_required_before_microphone';
  end if;
  return true;
end;
$$;

revoke all on function public.claim_room_seat(uuid, uuid, integer) from public;
grant execute on function public.claim_room_seat(uuid, uuid, integer) to authenticated;
revoke all on function public.leave_room_seat(uuid, uuid) from public;
grant execute on function public.leave_room_seat(uuid, uuid) to authenticated;
revoke all on function public.set_room_mic(uuid, uuid, boolean) from public;
grant execute on function public.set_room_mic(uuid, uuid, boolean) to authenticated;

insert into public.room_sessions(room_key, title, status, seats, video_enabled, chat_enabled)
values ('sol-test-room', 'Sala de Teste Sol', 'live', 30, false, true)
on conflict (room_key) do update
set title = excluded.title,
    status = 'live',
    video_enabled = false,
    chat_enabled = true;
