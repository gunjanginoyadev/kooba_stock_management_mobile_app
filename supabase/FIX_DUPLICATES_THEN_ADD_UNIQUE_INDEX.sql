-- =============================================================================
-- Run this if you get: "Key (user_id, lower(name))=(..., demo) is duplicated"
-- It removes duplicate items (keeps one per user + name, case-insensitive), then
-- creates the unique index.
-- =============================================================================

-- 1. Delete duplicate rows: keep one row per (user_id, lower(name)) (oldest by created_at)
with dups as (
  select id,
         row_number() over (partition by user_id, lower(name) order by created_at, id) as rn
  from public.items
)
delete from public.items
where id in (select id from dups where rn > 1);

-- 2. Now create the unique index
drop index if exists public.items_user_id_name_lower_unique;
create unique index items_user_id_name_lower_unique on public.items (user_id, lower(name));
