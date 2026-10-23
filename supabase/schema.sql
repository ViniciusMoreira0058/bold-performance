-- =====================================================================
-- BOLD PERFORMANCE · esquema do banco (Supabase / Postgres)
-- Como usar: Supabase → SQL Editor → New query → cole tudo → Run
-- Pode rodar mais de uma vez sem quebrar.
-- Os nomes não colidem com os do HABITAH, então funciona num projeto novo
-- ou no mesmo projeto do Supabase.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. CONFIGURAÇÃO DA BARBEARIA (1 linha só)
-- ---------------------------------------------------------------------
create table if not exists public.barbearia_config (
  id             smallint primary key default 1 check (id = 1),
  nome           text not null default 'Barbearia',
  dias_trabalho  smallint[] not null default '{1,2,3,4,5,6}',  -- 0=dom ... 6=sáb
  atualizado_em  timestamptz not null default now()
);
insert into public.barbearia_config (id) values (1) on conflict do nothing;

-- ---------------------------------------------------------------------
-- 2. EQUIPE (admin e barbeiros; 1 linha por conta)
-- ---------------------------------------------------------------------
create table if not exists public.equipe (
  id                 uuid primary key references auth.users(id) on delete cascade,
  nome               text not null,
  email              text,
  papel              text not null default 'barbeiro' check (papel in ('admin','barbeiro')),
  ativo              boolean not null default true,
  comissao_servicos  numeric(5,2) not null default 50,   -- % sobre serviços e extras
  comissao_produtos  numeric(5,2) not null default 10,   -- % sobre produtos
  ganho_desejado     numeric(12,2) not null default 0,   -- quanto o barbeiro quer ganhar no mês
  ticket_medio       numeric(10,2) not null default 0,   -- 0 = calcula pelos lançamentos
  criado_em          timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 3. CONVITES (o admin cadastra o e-mail; a pessoa cria a conta com ele)
-- ---------------------------------------------------------------------
create table if not exists public.convites (
  email              text primary key,
  nome               text not null,
  papel              text not null default 'barbeiro' check (papel in ('admin','barbeiro')),
  comissao_servicos  numeric(5,2) not null default 50,
  comissao_produtos  numeric(5,2) not null default 10,
  criado_em          timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 4. METAS DO MÊS (definidas pelo admin, por barbeiro)
-- ---------------------------------------------------------------------
create table if not exists public.metas (
  barbeiro_id   uuid not null references public.equipe(id) on delete cascade,
  mes           date not null check (extract(day from mes) = 1),  -- sempre o dia 1 do mês
  faturamento   numeric(12,2) not null default 0,   -- faturamento total que o admin almeja
  extras        numeric(12,2) not null default 0,   -- R$ em serviços extras
  assinaturas   integer       not null default 0,   -- novas assinaturas vendidas
  produtos      numeric(12,2) not null default 0,   -- R$ em produtos
  atualizado_em timestamptz not null default now(),
  primary key (barbeiro_id, mes)
);

-- ---------------------------------------------------------------------
-- 5. LANÇAMENTOS DIÁRIOS (1 linha por barbeiro por dia)
-- ---------------------------------------------------------------------
create table if not exists public.lancamentos (
  id            uuid primary key default gen_random_uuid(),
  barbeiro_id   uuid not null default auth.uid() references public.equipe(id) on delete cascade,
  data          date not null,
  atendimentos  integer       not null default 0 check (atendimentos >= 0),
  servicos      numeric(12,2) not null default 0 check (servicos >= 0),   -- R$ serviços principais
  extras        numeric(12,2) not null default 0 check (extras >= 0),     -- R$ serviços extras
  qtd_extras    integer       not null default 0 check (qtd_extras >= 0),
  assinaturas   integer       not null default 0 check (assinaturas >= 0),
  produtos      numeric(12,2) not null default 0 check (produtos >= 0),   -- R$ produtos
  obs           text,
  atualizado_em timestamptz not null default now(),
  unique (barbeiro_id, data)
);
create index if not exists lancamentos_barbeiro_data_idx on public.lancamentos (barbeiro_id, data desc);
create index if not exists lancamentos_data_idx on public.lancamentos (data);

-- ---------------------------------------------------------------------
-- 6. FUNÇÕES DE APOIO
-- ---------------------------------------------------------------------
create or replace function public.bp_sou_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.equipe e where e.id = auth.uid() and e.papel = 'admin' and e.ativo) $$;

-- cria o perfil quando alguém com convite cria a conta.
-- Sem convite, nada acontece (não bloqueia o cadastro de outros apps no mesmo Supabase);
-- o app mostra "conta não autorizada".
create or replace function public.bp_novo_usuario()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare c public.convites;
begin
  select * into c from public.convites where lower(email) = lower(new.email);
  if found then
    insert into public.equipe (id, nome, email, papel, comissao_servicos, comissao_produtos)
    values (new.id, c.nome, lower(new.email), c.papel, c.comissao_servicos, c.comissao_produtos)
    on conflict (id) do nothing;
  end if;
  return new;
end $$;

drop trigger if exists bp_on_auth_user_created on auth.users;
create trigger bp_on_auth_user_created
  after insert on auth.users
  for each row execute function public.bp_novo_usuario();

-- vincula uma conta que já existia antes do convite (ex.: o admin que já tinha login)
create or replace function public.bp_vincular()
returns boolean language plpgsql security definer set search_path = ''
as $$
declare c public.convites; em text;
begin
  if exists (select 1 from public.equipe where id = auth.uid()) then return true; end if;
  select email into em from auth.users where id = auth.uid();
  select * into c from public.convites where lower(email) = lower(em);
  if not found then return false; end if;
  insert into public.equipe (id, nome, email, papel, comissao_servicos, comissao_produtos)
  values (auth.uid(), c.nome, lower(em), c.papel, c.comissao_servicos, c.comissao_produtos)
  on conflict (id) do nothing;
  return true;
end $$;

-- resumo anônimo da equipe num período: cada barbeiro ativo vira uma linha sem nome,
-- com totais e metas dos meses do período. Serve para o barbeiro comparar com a média
-- sem ver os números de cada colega.
create or replace function public.bp_resumo_equipe(inicio date, fim date)
returns table (
  eu boolean, atendimentos bigint, servicos numeric, extras numeric, qtd_extras bigint,
  assinaturas bigint, produtos numeric, dias_lancados bigint, metas jsonb
)
language sql stable security definer set search_path = ''
as $$
  select e.id = auth.uid(),
    coalesce(sum(l.atendimentos),0), coalesce(sum(l.servicos),0), coalesce(sum(l.extras),0),
    coalesce(sum(l.qtd_extras),0), coalesce(sum(l.assinaturas),0), coalesce(sum(l.produtos),0),
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

-- ---------------------------------------------------------------------
-- 7. SEGURANÇA (RLS)
-- ---------------------------------------------------------------------
alter table public.barbearia_config enable row level security;
alter table public.equipe           enable row level security;
alter table public.convites         enable row level security;
alter table public.metas            enable row level security;
alter table public.lancamentos      enable row level security;

-- configuração: todos da equipe leem, só admin altera
drop policy if exists cfg_ler on public.barbearia_config;
create policy cfg_ler on public.barbearia_config for select to authenticated
  using (exists (select 1 from public.equipe e where e.id = auth.uid()));
drop policy if exists cfg_admin on public.barbearia_config;
create policy cfg_admin on public.barbearia_config for update to authenticated
  using (public.bp_sou_admin()) with check (public.bp_sou_admin());

-- equipe: cada um lê o próprio perfil; admin lê e altera todos
drop policy if exists eq_ler on public.equipe;
create policy eq_ler on public.equipe for select to authenticated
  using (id = auth.uid() or public.bp_sou_admin());
drop policy if exists eq_admin on public.equipe;
create policy eq_admin on public.equipe for all to authenticated
  using (public.bp_sou_admin()) with check (public.bp_sou_admin());

-- o barbeiro só pode mudar o próprio ganho desejado e ticket médio (o resto o admin define)
create or replace function public.bp_proteger_perfil()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if not public.bp_sou_admin() then
    if new.papel <> old.papel or new.ativo <> old.ativo or new.comissao_servicos <> old.comissao_servicos
       or new.comissao_produtos <> old.comissao_produtos or new.id <> old.id then
      raise exception 'somente o admin altera papel, status e comissão';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists bp_proteger_perfil on public.equipe;
create trigger bp_proteger_perfil before update on public.equipe
  for each row execute function public.bp_proteger_perfil();
drop policy if exists eq_proprio on public.equipe;
create policy eq_proprio on public.equipe for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- convites: só admin
drop policy if exists cv_admin on public.convites;
create policy cv_admin on public.convites for all to authenticated
  using (public.bp_sou_admin()) with check (public.bp_sou_admin());

-- metas: barbeiro lê as próprias; admin faz tudo
drop policy if exists mt_ler on public.metas;
create policy mt_ler on public.metas for select to authenticated
  using (barbeiro_id = auth.uid() or public.bp_sou_admin());
drop policy if exists mt_admin on public.metas;
create policy mt_admin on public.metas for all to authenticated
  using (public.bp_sou_admin()) with check (public.bp_sou_admin());

-- lançamentos: barbeiro ativo lê e grava os próprios; admin faz tudo
drop policy if exists lc_proprio on public.lancamentos;
create policy lc_proprio on public.lancamentos for all to authenticated
  using (barbeiro_id = auth.uid() and exists (select 1 from public.equipe e where e.id = auth.uid() and e.ativo))
  with check (barbeiro_id = auth.uid() and exists (select 1 from public.equipe e where e.id = auth.uid() and e.ativo));
drop policy if exists lc_admin on public.lancamentos;
create policy lc_admin on public.lancamentos for all to authenticated
  using (public.bp_sou_admin()) with check (public.bp_sou_admin());

revoke all on function public.bp_sou_admin() from public, anon;
revoke all on function public.bp_vincular() from public, anon;
revoke all on function public.bp_resumo_equipe(date, date) from public, anon;
grant execute on function public.bp_sou_admin() to authenticated;
grant execute on function public.bp_vincular() to authenticated;
grant execute on function public.bp_resumo_equipe(date, date) to authenticated;

-- ---------------------------------------------------------------------
-- 8. ADMIN: a SUA conta (troque o e-mail se o seu login for outro)
-- ---------------------------------------------------------------------
insert into public.convites (email, nome, papel)
values ('barbeariavm0058@gmail.com', 'Vinicius', 'admin')
on conflict (email) do update set papel = 'admin';

-- se você já tem login neste Supabase (ex.: o mesmo projeto do HABITAH), já vira admin agora
insert into public.equipe (id, nome, email, papel)
select u.id, 'Vinicius', lower(u.email), 'admin' from auth.users u
where lower(u.email) = 'barbeariavm0058@gmail.com'
on conflict (id) do update set papel = 'admin', ativo = true;

-- confira: deve aparecer o seu e-mail como admin (ou nada, se ainda não criou a conta)
select email, papel from public.equipe where papel = 'admin';
