-- MyAllowance database schema
-- Run this in: Supabase Dashboard -> SQL Editor -> New query

-- 1) Allowance settings (one row per user)
create table if not exists public.allowance_settings (
  user_id    uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  amount     numeric(12,2) not null default 0 check (amount >= 0),
  period     text not null default 'weekly' check (period in ('weekly', 'monthly')),
  updated_at timestamptz not null default now()
);

-- 2) Transactions (expenses)
create table if not exists public.transactions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title      text not null,
  amount     numeric(12,2) not null check (amount > 0),
  category   text not null default 'Other',
  note       text,
  date       date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists transactions_user_date_idx
  on public.transactions (user_id, date desc);

-- 3) Row Level Security: users can only see and change their own rows
alter table public.allowance_settings enable row level security;
alter table public.transactions       enable row level security;

drop policy if exists "own settings" on public.allowance_settings;
create policy "own settings" on public.allowance_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own transactions" on public.transactions;
create policy "own transactions" on public.transactions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
