-- Bold Performance · 013: deixa a aba Backup conferir quais arquivos SQL já foram rodados
-- Rode no SQL Editor do Supabase. Pode rodar mais de uma vez. Só lê, não muda nenhum dado.
-- O app já confere sozinho colunas, tabelas e funções; este arquivo libera a conferência
-- das regras de acesso (004 e 006), que o app não enxerga de fora.

create or replace function public.bp_verificar()
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
begin
  if not public.bp_sou_admin() then raise exception 'somente o admin'; end if;
  return jsonb_build_object(
    '004', exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'lancamentos' and policyname = 'lc_ler_proprio')
           and not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'lancamentos' and policyname = 'lc_proprio'),
    '006', exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                    where n.nspname = 'public' and p.proname = 'bp_proteger_perfil' and p.prosrc ilike '%ganho_desejado%')
  );
end $$;

revoke all on function public.bp_verificar() from public, anon;
grant execute on function public.bp_verificar() to authenticated;
