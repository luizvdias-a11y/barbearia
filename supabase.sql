-- BARBERFLOW / SUPABASE
-- Rode este SQL no SQL Editor do Supabase.
-- As políticas abaixo permitem o site usar a chave anon pública.
-- Para um sistema real com login, recomendamos trocar essas políticas
-- por políticas baseadas em autenticação.

create extension if not exists pgcrypto;

create table if not exists public.clientes (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  telefone text default '',
  observacoes text default '',
  criado_em timestamptz not null default now()
);

create table if not exists public.agendamentos (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id) on delete cascade,
  barbeiro text not null check (barbeiro in ('André','Valmor','Gustavo','Leonardo')),
  servico text not null,
  preco numeric(10,2) not null default 0,
  duracao integer not null default 30,
  data date not null,
  horario time not null,
  status text not null default 'agendado'
    check (status in ('agendado','concluido','cancelado','faltou')),
  observacoes text default '',
  criado_em timestamptz not null default now()
);

create index if not exists agendamentos_data_idx on public.agendamentos(data);
create index if not exists agendamentos_barbeiro_idx on public.agendamentos(barbeiro);
create index if not exists agendamentos_cliente_idx on public.agendamentos(cliente_id);

alter table public.clientes enable row level security;
alter table public.agendamentos enable row level security;

drop policy if exists "barberflow clientes select" on public.clientes;
drop policy if exists "barberflow clientes insert" on public.clientes;
drop policy if exists "barberflow clientes update" on public.clientes;
drop policy if exists "barberflow agendamentos select" on public.agendamentos;
drop policy if exists "barberflow agendamentos insert" on public.agendamentos;
drop policy if exists "barberflow agendamentos update" on public.agendamentos;
drop policy if exists "barberflow agendamentos delete" on public.agendamentos;

create policy "barberflow clientes select" on public.clientes for select to anon using (true);
create policy "barberflow clientes insert" on public.clientes for insert to anon with check (true);
create policy "barberflow clientes update" on public.clientes for update to anon using (true) with check (true);

create policy "barberflow agendamentos select" on public.agendamentos for select to anon using (true);
create policy "barberflow agendamentos insert" on public.agendamentos for insert to anon with check (true);
create policy "barberflow agendamentos update" on public.agendamentos for update to anon using (true) with check (true);
create policy "barberflow agendamentos delete" on public.agendamentos for delete to anon using (true);


-- Permissões necessárias para o GitHub Pages usando a chave pública (anon).
grant usage on schema public to anon;
grant select, insert, update on table public.clientes to anon;
grant select, insert, update, delete on table public.agendamentos to anon;
