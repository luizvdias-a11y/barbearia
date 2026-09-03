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

-- VIEW PARA VISUALIZAR A AGENDA COMPLETA NO SUPABASE
-- No Table Editor, procure por "agenda_completa" em Views.
create or replace view public.agenda_completa as
select
  a.id,
  a.data,
  a.horario,
  a.barbeiro,
  c.nome as cliente,
  c.telefone,
  a.servico,
  a.preco,
  a.duracao,
  a.status,
  a.observacoes,
  a.criado_em,
  a.cliente_id
from public.agendamentos a
join public.clientes c on c.id = a.cliente_id;

grant select on public.agenda_completa to anon;

-- Função para conferir rapidamente os agendamentos de uma data.
create or replace function public.ver_agenda(p_data date default current_date)
returns table (
  id uuid,
  data date,
  horario time,
  barbeiro text,
  cliente text,
  telefone text,
  servico text,
  preco numeric,
  duracao integer,
  status text,
  observacoes text
)
language sql
security invoker
as $$
  select
    a.id,
    a.data,
    a.horario,
    a.barbeiro,
    a.cliente,
    a.telefone,
    a.servico,
    a.preco,
    a.duracao,
    a.status,
    a.observacoes
  from public.agenda_completa a
  where a.data = p_data
  order by a.horario, a.barbeiro;
$$;

grant execute on function public.ver_agenda(date) to anon;


-- ==============================
-- CONTROLE COMPLETO DE STATUS
-- ==============================

-- Garante que o status sempre seja salvo e atualizado.
alter table public.agendamentos
  add column if not exists status_atualizado_em timestamptz not null default now();

-- Histórico de mudanças de status.
create table if not exists public.agendamento_status_historico (
  id uuid primary key default gen_random_uuid(),
  agendamento_id uuid not null references public.agendamentos(id) on delete cascade,
  status_anterior text,
  status_novo text not null check (status_novo in ('agendado','concluido','cancelado','faltou')),
  alterado_em timestamptz not null default now()
);

create index if not exists agendamento_status_historico_agendamento_idx
on public.agendamento_status_historico(agendamento_id, alterado_em desc);

-- Atualiza automaticamente a data de alteração do status e grava histórico.
create or replace function public.registrar_status_agendamento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    new.status_atualizado_em := now();
    insert into public.agendamento_status_historico
      (agendamento_id, status_anterior, status_novo)
    values
      (new.id, null, new.status);
    return new;
  end if;

  if old.status is distinct from new.status then
    new.status_atualizado_em := now();
    insert into public.agendamento_status_historico
      (agendamento_id, status_anterior, status_novo)
    values
      (new.id, old.status, new.status);
  end if;

  return new;
end;
$$;

drop trigger if exists trg_registrar_status_agendamento on public.agendamentos;
create trigger trg_registrar_status_agendamento
before insert or update of status on public.agendamentos
for each row execute function public.registrar_status_agendamento();

-- Impede conflito de horários também no banco, não apenas no JavaScript.
create or replace function public.validar_conflito_agendamento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  inicio timestamp;
  fim timestamp;
begin
  if new.status in ('cancelado','faltou') then
    return new;
  end if;

  inicio := new.data::timestamp + new.horario;
  fim := inicio + make_interval(mins => new.duracao);

  if exists (
    select 1
    from public.agendamentos a
    where a.barbeiro = new.barbeiro
      and a.id <> new.id
      and a.data = new.data
      and a.status not in ('cancelado','faltou')
      and inicio < (a.data::timestamp + a.horario + make_interval(mins => a.duracao))
      and fim > (a.data::timestamp + a.horario)
  ) then
    raise exception 'Horário já ocupado para este barbeiro.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validar_conflito_agendamento on public.agendamentos;
create trigger trg_validar_conflito_agendamento
before insert or update of data, horario, barbeiro, duracao, status on public.agendamentos
for each row execute function public.validar_conflito_agendamento();

alter table public.agendamento_status_historico enable row level security;

drop policy if exists "barberflow status history select" on public.agendamento_status_historico;
create policy "barberflow status history select"
on public.agendamento_status_historico
for select to anon using (true);

grant select on public.agendamento_status_historico to anon;
grant execute on function public.registrar_status_agendamento() to anon;
grant execute on function public.validar_conflito_agendamento() to anon;

-- View para consultar o agendamento já com o status e a última alteração.
create or replace view public.agenda_completa as
select
  a.id,
  a.data,
  a.horario,
  a.barbeiro,
  c.nome as cliente,
  c.telefone,
  a.servico,
  a.preco,
  a.duracao,
  a.status,
  a.status_atualizado_em,
  a.observacoes,
  a.criado_em,
  a.cliente_id
from public.agendamentos a
join public.clientes c on c.id = a.cliente_id;

grant select on public.agenda_completa to anon;
