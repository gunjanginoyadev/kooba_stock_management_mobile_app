-- =============================================================================
-- Run this entire script in Supabase Dashboard → SQL Editor → New query
-- Then click "Run". This creates the tables needed for Add item / Manage items.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Profiles (for operator name on stock entries)
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users can read profiles" on public.profiles;
create policy "Users can read profiles"
  on public.profiles for select
  using (auth.role() = 'authenticated');

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- Auto-create profile on signup using auth metadata (full_name)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do update
    set full_name = excluded.full_name;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- NEW (Frame stock / Excel-style)
-- -----------------------------------------------------------------------------
-- item_types: profile/die (e.g. HETVA DIE 2001) with optional image URL
create table if not exists public.item_types (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  image_url text,
  remark text,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(name, user_id)
);

-- items_v2: stock lines under a type (code + finish + qty10/qty12)
create table if not exists public.items_v2 (
  id uuid primary key default gen_random_uuid(),
  type_id uuid not null references public.item_types(id) on delete cascade,
  code text not null,
  finish text not null,
  qty_10ft int not null default 0,
  qty_12ft int not null default 0,
  remark text,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, type_id, code, finish)
);

-- One (type + code + finish) per user (case-insensitive)
drop index if exists public.items_v2_user_type_code_finish_lower_unique;
create unique index items_v2_user_type_code_finish_lower_unique
  on public.items_v2 (user_id, type_id, lower(code), lower(finish));

create index if not exists item_types_user_id_idx on public.item_types(user_id);
create index if not exists items_v2_user_id_idx on public.items_v2(user_id);
create index if not exists items_v2_type_id_idx on public.items_v2(type_id);

alter table public.item_types enable row level security;
alter table public.items_v2 enable row level security;

drop policy if exists "Users can manage own item types" on public.item_types;
create policy "Users can manage own item types"
  on public.item_types for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

drop policy if exists "Users can manage own items v2" on public.items_v2;
create policy "Users can manage own items v2"
  on public.items_v2 for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- stock_entries_v2: history for stock in/out with 10ft/12ft deltas
create table if not exists public.stock_entries_v2 (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items_v2(id) on delete cascade,
  entry_type text not null check (entry_type in ('in', 'out')),
  delta_10ft int not null default 0,
  delta_12ft int not null default 0,
  entered_by_name text,
  location text,
  notes text,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.stock_entries_v2
  add column if not exists entered_by_name text;

create index if not exists stock_entries_v2_user_id_idx on public.stock_entries_v2(user_id);
create index if not exists stock_entries_v2_item_id_idx on public.stock_entries_v2(item_id);

alter table public.stock_entries_v2 enable row level security;

drop policy if exists "Users can manage own stock entries v2" on public.stock_entries_v2;
create policy "Users can manage own stock entries v2"
  on public.stock_entries_v2 for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- Item categories (for "special" / category-based items)
create table if not exists public.item_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  image_url text,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(name, user_id)
);

-- For existing projects: add the column if the table already exists
alter table public.item_categories
  add column if not exists image_url text;

-- Stock items: normal (category_id null) or special (category_id set)
create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sku text,
  category_id uuid references public.item_categories(id) on delete cascade,
  quantity int not null default 0,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists items_category_id_idx on public.items(category_id);
create index if not exists items_user_id_idx on public.items(user_id);
create index if not exists item_categories_user_id_idx on public.item_categories(user_id);

-- One item name per user: no duplicate between normal and special, or across categories (case-insensitive)
drop index if exists public.items_user_id_name_lower_unique;
create unique index items_user_id_name_lower_unique on public.items (user_id, lower(name));

-- Row Level Security (each user only sees their own data)
alter table public.item_categories enable row level security;
alter table public.items enable row level security;

drop policy if exists "Users can manage own categories" on public.item_categories;
create policy "Users can manage own categories"
  on public.item_categories for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can manage own items" on public.items;
create policy "Users can manage own items"
  on public.items for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
