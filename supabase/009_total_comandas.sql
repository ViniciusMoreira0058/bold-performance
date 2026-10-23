-- =====================================================================
-- BOLD PERFORMANCE · total das comandas importadas do CashBarber
-- Rode depois do 008 (SQL Editor → New query → cole tudo → Run).
-- Pode rodar mais de uma vez.
--
-- Guarda o total das comandas do dia vindo da planilha. Quando o admin
-- lança extras e produtos nesse dia, o app desconta do total para não
-- contar duas vezes (serviços = total − extras − produtos).
-- =====================================================================

alter table public.lancamentos add column if not exists total_comandas numeric(12,2);

-- confira: deve aparecer a coluna total_comandas
select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'lancamentos' and column_name = 'total_comandas';
