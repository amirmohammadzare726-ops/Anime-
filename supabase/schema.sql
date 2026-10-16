-- ETERNUM schema. This project has been repurposed; legacy game tables were removed.
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


-- One-time, authenticated, server-side power awakening.
-- This function generates the power inside PostgreSQL and never accepts client-chosen powers.
create or replace function public.awaken_eternum_power()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_profile public.player_profiles%rowtype;
  v_pool jsonb := '[
    {"name":"سایه‌خوری","ability":"جذب و بلعیدن انرژی تاریک"},
    {"name":"شکاف فضایی","ability":"گشودن شکاف‌های کوتاه در فضا"},
    {"name":"طنین روح","ability":"شنیدن رد احساسات باقی‌مانده"},
    {"name":"آذر خاموش","ability":"آتش بنفش با قابلیت مهار"},
    {"name":"توقف لحظه","ability":"کندکردن حرکت برای چند ثانیه"},
    {"name":"زره اثیری","ability":"ساخت پوشش دفاعی از انرژی"},
    {"name":"نخ تقدیر","ability":"دیدن پیوندهای پنهان میان رویدادها"},
    {"name":"آینه تاریک","ability":"بازتاب محدود یک حمله انرژی"},
    {"name":"گام شبح","ability":"حرکت سریع و بی‌صدا در سایه"},
    {"name":"مهر فراموشی","ability":"پنهان‌کردن رد انرژی برای مدت کوتاه"},
    {"name":"چشم شکاف","ability":"تشخیص دروازه‌ها و ترک‌های جادویی"},
    {"name":"نبض زمین","ability":"حس‌کردن لرزش‌ها و حرکت نزدیکان"},
    {"name":"زنجیر روح","ability":"مهار کوتاه هدف با رشته انرژی"},
    {"name":"غبار ستاره","ability":"پراکندن ذرات نور برای فریب"},
    {"name":"خون سرد","ability":"مقاومت کوتاه در برابر درد"},
    {"name":"ندای کلاغ","ability":"فرستادن پژواک حسی به فاصله نزدیک"},
    {"name":"یخ سیاه","ability":"ساخت تیغه‌های یخی تیره"},
    {"name":"شراره وارونه","ability":"تغییر مسیر محدود پرتابه انرژی"},
    {"name":"موج خاموش","ability":"ایجاد ضربه موجی بی‌صدا"},
    {"name":"قفل زمان","ability":"کندکردن یک شیء کوچک برای لحظه‌ای"}
  ]'::jsonb;
  v_power jsonb;
  v_subpowers jsonb;
begin
  if v_uid is null then
    raise exception 'برای بیداری قدرت باید وارد حساب شوی.' using errcode = '28000';
  end if;
  select * into v_profile from public.player_profiles where id = v_uid for update;
  if not found then
    raise exception 'پروفایل شخصیت پیدا نشد.' using errcode = 'P0002';
  end if;
  if v_profile.power_data <> '{}'::jsonb then
    return v_profile.power_data;
  end if;
  select jsonb_agg(jsonb_build_object('slot', slot, 'name', item->>'name', 'ability', item->>'ability') order by slot)
  into v_subpowers
  from (
    select item, row_number() over () as slot
    from (select value as item from jsonb_array_elements(v_pool) as elements(value) order by random() limit 10) chosen
  ) numbered;
  v_power := jsonb_build_object(
    'name', 'موهبتِ آستانه',
    'rarity', 'نامتعارف',
    'description', 'قدرتی ناشناخته که در لحظه عبور از آستانه بیدار شده است.',
    'subpowers', v_subpowers,
    'mastery', 1,
    'locked', true,
    'awakened_at', now()
  );
  update public.player_profiles set power_data = v_power, power_level = 1 where id = v_uid;
  return v_power;
end;
$$;
revoke all on function public.awaken_eternum_power() from public, anon;
grant execute on function public.awaken_eternum_power() to authenticated;
