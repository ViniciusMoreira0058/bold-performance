-- =====================================================================
-- BOLD PERFORMANCE · meta de faturamento geral da barbearia
-- Rode depois do 004 (SQL Editor → New query → cole tudo → Run).
-- Pode rodar mais de uma vez.
--
-- Uma meta de faturamento por mês para a barbearia inteira, lançada pelo
-- admin na aba "Lançar dia". Só o admin lê e altera.
-- =====================================================================

create table if not exists public.metas_barbearia (
  mes            date primary key check (extract(day from mes) = 1),  -- 1º dia do mês
  faturamento    numeric(12,2) not null default 0 check (faturamento >= 0),
  atualizado_em  timestamptz not null default now()
);

alter table public.metas_barbearia enable row level security;

drop policy if exists mb_admin on public.metas_barbearia;
create policy mb_admin on public.metas_barbearia for all to authenticated
  using (public.bp_sou_admin()) with check (public.bp_sou_admin());

-- confira: lista as metas já lançadas (vazio no começo é normal)
select mes, faturamento from public.metas_barbearia order by mes;
