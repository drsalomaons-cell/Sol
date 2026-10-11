create or replace function public.create_room_session(
  p_title text,
  p_seats integer default 30,
  p_video_enabled boolean default false,
  p_chat_enabled boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_key text;
  v_title text;
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  v_title := btrim(coalesce(p_title, ''));
  if length(v_title) < 3 or length(v_title) > 80 then
    raise exception 'room_title_must_be_3_to_80_characters';
  end if;
  if p_seats < 30 or p_seats > 100 then
    raise exception 'room_capacity_must_be_between_30_and_100';
  end if;
  v_key := 'sol-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 16);
  insert into public.room_sessions(room_key, title, status, seats, video_enabled, chat_enabled)
  values (v_key, v_title, 'live', p_seats, coalesce(p_video_enabled, false), coalesce(p_chat_enabled, true))
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'room_key', v_key, 'title', v_title, 'status', 'live',
    'seats', p_seats, 'video_enabled', coalesce(p_video_enabled, false), 'chat_enabled', coalesce(p_chat_enabled, true));
end;
$$;
revoke all on function public.create_room_session(text, integer, boolean, boolean) from public;
revoke all on function public.create_room_session(text, integer, boolean, boolean) from anon;
grant execute on function public.create_room_session(text, integer, boolean, boolean) to authenticated;