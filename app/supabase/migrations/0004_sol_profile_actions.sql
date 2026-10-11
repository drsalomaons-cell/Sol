-- Profile actions, contact requests, blocking, visitors and host/agency applications for Sol.
-- Additive schema only; does not delete existing room or wallet data.

create table if not exists public.sol_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  language text not null default 'pt' check (language in ('pt','en','ar','es')),
  notifications_push boolean not null default true,
  notifications_room boolean not null default true,
  notifications_friends boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sol_public_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Usuário Sol',
  region text not null default '',
  avatar_url text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sol_contacts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  contact_user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sol_contacts_not_self check (owner_id <> contact_user_id),
  constraint sol_contacts_unique_pair unique (owner_id, contact_user_id)
);
create index if not exists sol_contacts_owner_status_idx on public.sol_contacts(owner_id,status);
create index if not exists sol_contacts_target_status_idx on public.sol_contacts(contact_user_id,status);

create table if not exists public.sol_blocked_users (
  owner_id uuid not null references auth.users(id) on delete cascade,
  blocked_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (owner_id,blocked_user_id),
  constraint sol_blocked_not_self check (owner_id <> blocked_user_id)
);

create table if not exists public.sol_profile_visits (
  profile_user_id uuid not null references auth.users(id) on delete cascade,
  visitor_user_id uuid not null references auth.users(id) on delete cascade,
  last_visited_at timestamptz not null default now(),
  primary key (profile_user_id,visitor_user_id),
  constraint sol_profile_visit_not_self check (profile_user_id <> visitor_user_id)
);
create index if not exists sol_profile_visits_profile_time_idx on public.sol_profile_visits(profile_user_id,last_visited_at desc);

create table if not exists public.sol_agency_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  application_type text not null check (application_type in ('host','agency')),
  message text not null default '',
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);
create index if not exists sol_agency_applications_user_time_idx on public.sol_agency_applications(user_id,created_at desc);

alter table public.sol_profiles enable row level security;
alter table public.sol_public_profiles enable row level security;
alter table public.sol_contacts enable row level security;
alter table public.sol_blocked_users enable row level security;
alter table public.sol_profile_visits enable row level security;
alter table public.sol_agency_applications enable row level security;

drop policy if exists sol_profiles_select_self on public.sol_profiles;
create policy sol_profiles_select_self on public.sol_profiles for select to authenticated using (user_id = auth.uid());
drop policy if exists sol_profiles_insert_self on public.sol_profiles;
create policy sol_profiles_insert_self on public.sol_profiles for insert to authenticated with check (user_id = auth.uid());
drop policy if exists sol_profiles_update_self on public.sol_profiles;
create policy sol_profiles_update_self on public.sol_profiles for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists sol_public_profiles_select_authenticated on public.sol_public_profiles;
create policy sol_public_profiles_select_authenticated on public.sol_public_profiles for select to authenticated using (true);
drop policy if exists sol_public_profiles_insert_self on public.sol_public_profiles;
create policy sol_public_profiles_insert_self on public.sol_public_profiles for insert to authenticated with check (user_id = auth.uid());
drop policy if exists sol_public_profiles_update_self on public.sol_public_profiles;
create policy sol_public_profiles_update_self on public.sol_public_profiles for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists sol_contacts_select_participant on public.sol_contacts;
create policy sol_contacts_select_participant on public.sol_contacts for select to authenticated using (owner_id = auth.uid() or contact_user_id = auth.uid());
drop policy if exists sol_contacts_insert_owner on public.sol_contacts;
create policy sol_contacts_insert_owner on public.sol_contacts for insert to authenticated with check (owner_id = auth.uid() and status = 'pending');
drop policy if exists sol_contacts_update_recipient on public.sol_contacts;
create policy sol_contacts_update_recipient on public.sol_contacts for update to authenticated using (contact_user_id = auth.uid()) with check (contact_user_id = auth.uid() and status in ('accepted','declined'));
drop policy if exists sol_contacts_delete_participant on public.sol_contacts;
create policy sol_contacts_delete_participant on public.sol_contacts for delete to authenticated using (owner_id = auth.uid() or contact_user_id = auth.uid());

drop policy if exists sol_blocked_select_self on public.sol_blocked_users;
create policy sol_blocked_select_self on public.sol_blocked_users for select to authenticated using (owner_id = auth.uid());
drop policy if exists sol_blocked_insert_self on public.sol_blocked_users;
create policy sol_blocked_insert_self on public.sol_blocked_users for insert to authenticated with check (owner_id = auth.uid());
drop policy if exists sol_blocked_delete_self on public.sol_blocked_users;
create policy sol_blocked_delete_self on public.sol_blocked_users for delete to authenticated using (owner_id = auth.uid());

drop policy if exists sol_visits_select_profile_owner on public.sol_profile_visits;
create policy sol_visits_select_profile_owner on public.sol_profile_visits for select to authenticated using (profile_user_id = auth.uid());
drop policy if exists sol_visits_insert_visitor on public.sol_profile_visits;
create policy sol_visits_insert_visitor on public.sol_profile_visits for insert to authenticated with check (visitor_user_id = auth.uid() and profile_user_id <> auth.uid());
drop policy if exists sol_visits_update_visitor on public.sol_profile_visits;
create policy sol_visits_update_visitor on public.sol_profile_visits for update to authenticated using (visitor_user_id = auth.uid()) with check (visitor_user_id = auth.uid());

drop policy if exists sol_agency_select_self on public.sol_agency_applications;
create policy sol_agency_select_self on public.sol_agency_applications for select to authenticated using (user_id = auth.uid());
drop policy if exists sol_agency_insert_self on public.sol_agency_applications;
create policy sol_agency_insert_self on public.sol_agency_applications for insert to authenticated with check (user_id = auth.uid() and status = 'pending');

create or replace function public.sol_create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
  v_region text;
begin
  v_name := nullif(btrim(coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'name', split_part(coalesce(new.email,''),'@',1))), '');
  v_region := coalesce(new.raw_user_meta_data->>'region','');
  insert into public.sol_profiles(user_id) values (new.id) on conflict (user_id) do nothing;
  insert into public.sol_public_profiles(user_id,display_name,region,avatar_url)
  values (new.id,coalesce(v_name,'Usuário Sol'),v_region,coalesce(new.raw_user_meta_data->>'avatar_url',''))
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists sol_auth_user_profile_insert on auth.users;
create trigger sol_auth_user_profile_insert after insert on auth.users for each row execute procedure public.sol_create_profile_for_new_user();

insert into public.sol_profiles(user_id)
select id from auth.users on conflict (user_id) do nothing;

insert into public.sol_public_profiles(user_id,display_name,region,avatar_url)
select id,
       coalesce(nullif(btrim(coalesce(raw_user_meta_data->>'display_name',raw_user_meta_data->>'name',split_part(coalesce(email,''),'@',1))),''),'Usuário Sol'),
       coalesce(raw_user_meta_data->>'region',''),
       coalesce(raw_user_meta_data->>'avatar_url','')
from auth.users
on conflict (user_id) do nothing;

grant select,insert,update on public.sol_profiles to authenticated;
grant select,insert,update on public.sol_public_profiles to authenticated;
grant select,insert,update,delete on public.sol_contacts to authenticated;
grant select,insert,update,delete on public.sol_blocked_users to authenticated;
grant select,insert,update on public.sol_profile_visits to authenticated;
grant select,insert on public.sol_agency_applications to authenticated;
