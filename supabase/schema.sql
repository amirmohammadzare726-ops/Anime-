-- ETERNUM initial schema. Run only in a NEW Supabase project dedicated to ETERNUM.
create table if not exists public.player_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  character_name text not null default 'مسافر بی‌نام',
  character_level integer not null default 1 check (character_level between 1 and 500),
  power_level integer not null default 1 check (power_level between 1 and 100),
  power_data jsonb not null default '{}'::jsonb,
  world_state jsonb not null default '{"chapter":"first_gate","location":"threshold"}'::jsonb,
  intro_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists player_profiles_username_lower_uq on public.player_profiles (lower(username));
alter table public.player_profiles enable row level security;
drop policy if exists "Players can read their own profile" on public.player_profiles;
create policy "Players can read their own profile" on public.player_profiles for select using (auth.uid() = id);
drop policy if exists "Players can update their own profile" on public.player_profiles;
create policy "Players can update their own profile" on public.player_profiles for update using (auth.uid() = id) with check (auth.uid() = id);

create or replace function public.handle_new_eternum_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.player_profiles (id, username, character_name)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'username', ''), 'traveler_' || substr(new.id::text, 1, 8)),
    coalesce(nullif(new.raw_user_meta_data ->> 'character_name', ''), 'مسافر بی‌نام')
  );
  return new;
end;
$$;
drop trigger if exists on_eternum_auth_user_created on auth.users;
create trigger on_eternum_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_eternum_user();

create or replace function public.set_eternum_updated_at()
returns trigger language plpgsql set search_path = ''
as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists set_eternum_profile_updated_at on public.player_profiles;
create trigger set_eternum_profile_updated_at before update on public.player_profiles for each row execute procedure public.set_eternum_updated_at();
revoke update on public.player_profiles from authenticated;
grant select on public.player_profiles to authenticated;
grant update (world_state, intro_completed) on public.player_profiles to authenticated;
-- Character/power progression must be changed by trusted server-side game logic, not client requests.
