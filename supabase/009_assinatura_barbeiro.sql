-- Bold Performance · 009: faturamento de assinaturas por barbeiro
-- Rode no SQL Editor do Supabase depois dos arquivos 002 a 008.
-- Em Lançamentos, cada barbeiro ganha o campo "Assinaturas R$" (total do mês), que soma no faturamento dele.

alter table public.lancamentos
  add column if not exists assinatura_rs numeric(12,2) not null default 0 check (assinatura_rs >= 0);

-- o resumo da equipe (média que o barbeiro vê) passa a somar as assinaturas
drop function if exists public.bp_resumo_equipe(date, date);
create function public.bp_resumo_equipe(inicio date, fim date)
returns table (
  eu boolean, atendimentos bigint, servicos numeric, extras numeric, qtd_extras bigint,
  assinaturas bigint, produtos numeric, assinatura_rs numeric, dias_lancados bigint, metas jsonb
)
language sql stable security definer set search_path = ''
as $$
  select e.id = auth.uid(),
    coalesce(sum(l.atendimentos),0), coalesce(sum(l.servicos),0), coalesce(sum(l.extras),0),
    coalesce(sum(l.qtd_extras),0), coalesce(sum(l.assinaturas),0), coalesce(sum(l.produtos),0),
    coalesce(sum(l.assinatura_rs),0),
    count(l.id),
    (select coalesce(jsonb_agg(jsonb_build_object('mes',m.mes,'faturamento',m.faturamento,'extras',m.extras,
        'assinaturas',m.assinaturas,'produtos',m.produtos)),'[]'::jsonb)
       from public.metas m where m.barbeiro_id = e.id
        and m.mes between date_trunc('month', inicio)::date and date_trunc('month', fim)::date)
  from public.equipe e
  left join public.lancamentos l on l.barbeiro_id = e.id and l.data between inicio and fim
  where e.papel = 'barbeiro' and e.ativo
    and exists (select 1 from public.equipe me where me.id = auth.uid() and me.ativo)
  group by e.id
$$;
revoke all on function public.bp_resumo_equipe(date, date) from public, anon;
grant execute on function public.bp_resumo_equipe(date, date) to authenticated;
