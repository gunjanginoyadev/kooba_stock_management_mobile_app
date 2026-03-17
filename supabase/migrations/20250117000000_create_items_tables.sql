-- Item categories (for "special" / category-based items)
-- Each category belongs to the authenticated user.
create table if not exists public.item_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(name, user_id)
);

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

-- One item name per user (no duplicate between normal/special or across categories), case-insensitive
create unique index if not exists items_user_id_name_lower_unique on public.items (user_id, lower(name));

-- RLS
alter table public.item_categories enable row level security;
alter table public.items enable row level security;

create policy "Users can manage own categories"
  on public.item_categories for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can manage own items"
  on public.items for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
