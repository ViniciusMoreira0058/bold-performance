-- Bold Performance · 014: itens em falta
-- Rode no SQL Editor do Supabase (precisa do 007 já rodado). Pode rodar mais de uma vez.
-- O barbeiro avisa o que está acabando (quanto ainda tem e a urgência); o admin vê ao abrir o app,
-- responde com uma mensagem e a previsão de chegada, ou marca como resolvido.

create table if not exists public.itens_falta (
  id             uuid primary key default gen_random_uuid(),
  barbeiro_id    uuid not null default auth.uid() references public.equipe(id) on delete cascade on update cascade,
  item           text not null check (length(trim(item)) between 1 and 120),
  quanto_tem     text check (length(quanto_tem) <= 120),
  urgencia       smallint not null default 2 check (urgencia between 1 and 4),  -- 1 baixa · 2 média · 3 alta · 4 acabou
  obs            text check (length(obs) <= 500),
  status         text not null default 'aberto' check (status in ('aberto','a_caminho','resolvido')),
  resposta       text check (length(resposta) <= 500),
  previsao       date,
  respondido_em  timestamptz,
  criado_em      timestamptz not null default now()
);
create index if not exists itens_falta_status on public.itens_falta (status, criado_em desc);

alter table public.itens_falta enable row level security;

drop policy if exists if_admin on public.itens_falta;
create policy if_admin on public.itens_falta for all to authenticated
  using (public.bp_sou_admin()) with check (public.bp_sou_admin());

-- o barbeiro vê os próprios avisos, cria novos e apaga um que ainda não foi respondido
drop policy if exists if_ler_proprio on public.itens_falta;
create policy if_ler_proprio on public.itens_falta for select to authenticated
  using (barbeiro_id = auth.uid());
drop policy if exists if_criar_proprio on public.itens_falta;
create policy if_criar_proprio on public.itens_falta for insert to authenticated
  with check (barbeiro_id = auth.uid() and status = 'aberto' and resposta is null and respondido_em is null
              and exists (select 1 from public.equipe e where e.id = auth.uid() and e.ativo));
drop policy if exists if_apagar_proprio on public.itens_falta;
create policy if_apagar_proprio on public.itens_falta for delete to authenticated
  using (barbeiro_id = auth.uid() and respondido_em is null);
