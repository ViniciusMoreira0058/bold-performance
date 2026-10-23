-- =====================================================================
-- BOLD PERFORMANCE · só o admin lança os resultados
-- Rode no SQL Editor (New query → cole tudo → Run). Pode rodar mais de uma vez.
--
-- O barbeiro passa a só VER os próprios lançamentos; criar, editar e excluir
-- fica só com o admin (política lc_admin, que já existe).
-- =====================================================================

drop policy if exists lc_proprio on public.lancamentos;
drop policy if exists lc_ler_proprio on public.lancamentos;
create policy lc_ler_proprio on public.lancamentos for select to authenticated
  using (barbeiro_id = auth.uid() and exists (select 1 from public.equipe e where e.id = auth.uid() and e.ativo));

-- confira: devem aparecer lc_admin (tudo) e lc_ler_proprio (só leitura)
select policyname, cmd from pg_policies where schemaname = 'public' and tablename = 'lancamentos';
