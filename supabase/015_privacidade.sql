-- Bold Performance · 015: privacidade (LGPD)
-- Rode no SQL Editor do Supabase (precisa do 007 já rodado). Pode rodar mais de uma vez.
-- 1. guarda quando cada pessoa aceitou a política de privacidade
-- 2. pedidos do barbeiro sobre os próprios dados (ver, corrigir, apagar), atendidos pelo admin

alter table public.equipe add column if not exists privacidade_aceita_em timestamptz;

create table if not exists public.pedidos_dados (
  id           uuid primary key default gen_random_uuid(),
  barbeiro_id  uuid not null default auth.uid() references public.equipe(id) on delete cascade on update cascade,
  tipo         text not null check (tipo in ('ver','corrigir','apagar')),
  detalhe      text check (length(detalhe) <= 1000),
  status       text not null default 'aberto' check (status in ('aberto','atendido')),
  resposta     text check (length(resposta) <= 1000),
  atendido_em  timestamptz,
  criado_em    timestamptz not null default now()
);

alter table public.pedidos_dados enable row level security;

drop policy if exists pd_admin on public.pedidos_dados;
create policy pd_admin on public.pedidos_dados for all to authenticated
  using (public.bp_sou_admin()) with check (public.bp_sou_admin());
drop policy if exists pd_ler_proprio on public.pedidos_dados;
create policy pd_ler_proprio on public.pedidos_dados for select to authenticated
  using (barbeiro_id = auth.uid());
drop policy if exists pd_criar_proprio on public.pedidos_dados;
create policy pd_criar_proprio on public.pedidos_dados for insert to authenticated
  with check (barbeiro_id = auth.uid() and status = 'aberto' and resposta is null and atendido_em is null);
