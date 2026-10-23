-- =====================================================================
-- BOLD PERFORMANCE · receita de assinaturas da barbearia
-- Rode depois do 007 (SQL Editor → New query → cole tudo → Run).
-- Pode rodar mais de uma vez.
--
-- Total cobrado em assinaturas por dia (novas + renovações), vindo da
-- planilha do CashBarber. Entra no faturamento geral da barbearia.
-- Só o admin lê e altera.
-- =====================================================================

create table if not exists public.receita_assinaturas (
  data           date primary key,
  valor          numeric(12,2) not null default 0 check (valor >= 0),
  cobrancas      integer not null default 0 check (cobrancas >= 0),
  atualizado_em  timestamptz not null default now()
);

alter table public.receita_assinaturas enable row level security;

drop policy if exists ra_admin on public.receita_assinaturas;
create policy ra_admin on public.receita_assinaturas for all to authenticated
  using (public.bp_sou_admin()) with check (public.bp_sou_admin());

-- confira: total por mês (vazio no começo é normal)
select date_trunc('month', data)::date as mes, sum(valor) as valor, sum(cobrancas) as cobrancas
from public.receita_assinaturas group by 1 order by 1;
