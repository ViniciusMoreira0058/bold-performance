-- Bold Performance · 010: comissão até hoje por barbeiro
-- Rode no SQL Editor do Supabase depois do 009.
-- Em Lançamentos, o admin informa a comissão do mês até a data (não soma no faturamento).
-- Em "Minha meta", o barbeiro compara a comissão real com a meta de ganho.

alter table public.lancamentos
  add column if not exists comissao_rs numeric(12,2) not null default 0 check (comissao_rs >= 0);
