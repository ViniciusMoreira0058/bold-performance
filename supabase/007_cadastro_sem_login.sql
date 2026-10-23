-- =====================================================================
-- BOLD PERFORMANCE · cadastrar barbeiro antes de ele criar o login
-- Rode depois do 006 (SQL Editor → New query → cole tudo → Run).
-- Pode rodar mais de uma vez.
--
-- O admin cadastra o barbeiro (nome e, se souber, e-mail) e já pode lançar,
-- importar a planilha e definir metas para ele. Quando o barbeiro criar a
-- conta com o mesmo e-mail, a conta se liga a esse cadastro e ele vê todo
-- o histórico.
-- =====================================================================

alter table public.equipe add column if not exists tem_login boolean not null default true;
alter table public.equipe alter column id set default gen_random_uuid();

-- 1. o perfil deixa de exigir uma conta de login; metas e lançamentos acompanham
--    quando o cadastro é ligado à conta (on update cascade)
do $$
declare r record;
begin
  for r in select conname from pg_constraint
           where conrelid = 'public.equipe'::regclass and contype = 'f' and confrelid = 'auth.users'::regclass loop
    execute format('alter table public.equipe drop constraint %I', r.conname);
  end loop;
  for r in select c.conrelid::regclass as tabela, c.conname, a.attname as coluna
           from pg_constraint c join pg_attribute a on a.attrelid = c.conrelid and a.attnum = c.conkey[1]
           where c.contype = 'f' and c.confrelid = 'public.equipe'::regclass
             and c.conrelid in ('public.metas'::regclass, 'public.lancamentos'::regclass) loop
    execute format('alter table %s drop constraint %I', r.tabela, r.conname);
    execute format('alter table %s add constraint %I foreign key (%I) references public.equipe(id) on delete cascade on update cascade',
                   r.tabela, r.conname, r.coluna);
  end loop;
end $$;

-- conta de login apagada → perfil apagado (antes era feito pela chave estrangeira)
create or replace function public.bp_usuario_apagado()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  delete from public.equipe where id = old.id;
  return old;
end $$;
drop trigger if exists bp_usuario_apagado on auth.users;
create trigger bp_usuario_apagado after delete on auth.users
  for each row execute function public.bp_usuario_apagado();

-- 2. liga a conta nova ao cadastro feito pelo admin (mesmo e-mail)
create or replace function public.bp_ligar_cadastro(uid uuid, em text)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare alvo uuid;
begin
  if em is null or exists (select 1 from public.equipe where id = uid) then return false; end if;
  select id into alvo from public.equipe
   where not tem_login and lower(email) = lower(em)
   order by criado_em limit 1;
  if alvo is null then return false; end if;
  perform set_config('bp.vinculando', '1', true);
  update public.equipe set id = uid, tem_login = true, email = lower(em) where id = alvo;
  perform set_config('bp.vinculando', '', true);
  return true;
end $$;
revoke all on function public.bp_ligar_cadastro(uuid, text) from public, anon, authenticated;

-- o gatilho de proteção deixa passar só a ligação feita acima
create or replace function public.bp_proteger_perfil()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if coalesce(current_setting('bp.vinculando', true), '') = '1' then return new; end if;
  if not public.bp_sou_admin() then
    if new.papel <> old.papel or new.ativo <> old.ativo or new.aprovado <> old.aprovado
       or new.comissao_servicos <> old.comissao_servicos
       or new.comissao_produtos <> old.comissao_produtos or new.id <> old.id
       or new.ganho_desejado is distinct from old.ganho_desejado
       or new.ticket_medio is distinct from old.ticket_medio
       or new.tem_login is distinct from old.tem_login then
      raise exception 'somente o admin altera papel, status, aprovação, comissão, ganho desejado e ticket médio';
    end if;
  end if;
  return new;
end $$;

-- cadastro pelo app (conta nova)
create or replace function public.bp_novo_usuario()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare c public.convites;
begin
  if public.bp_ligar_cadastro(new.id, new.email) then return new; end if;
  select * into c from public.convites where lower(email) = lower(new.email);
  if found then
    insert into public.equipe (id, nome, email, papel, comissao_servicos, comissao_produtos, aprovado, ativo)
    values (new.id, c.nome, lower(new.email), c.papel, c.comissao_servicos, c.comissao_produtos, true, true)
    on conflict (id) do nothing;
  elsif coalesce(new.raw_user_meta_data->>'app', '') = 'bold' then
    insert into public.equipe (id, nome, email, papel, aprovado, ativo)
    values (new.id,
            coalesce(nullif(trim(new.raw_user_meta_data->>'nome'), ''), split_part(new.email, '@', 1)),
            lower(new.email), 'barbeiro', false, false)
    on conflict (id) do nothing;
  end if;
  return new;
end $$;

-- quem já tinha login (ex.: conta do HABITAH) e entra no Bold pela primeira vez
create or replace function public.bp_vincular()
returns boolean language plpgsql security definer set search_path = ''
as $$
declare c public.convites; u record;
begin
  if exists (select 1 from public.equipe where id = auth.uid()) then return true; end if;
  select email, raw_user_meta_data into u from auth.users where id = auth.uid();
  if not found then return false; end if;
  if public.bp_ligar_cadastro(auth.uid(), u.email) then return true; end if;
  select * into c from public.convites where lower(email) = lower(u.email);
  if found then
    insert into public.equipe (id, nome, email, papel, comissao_servicos, comissao_produtos, aprovado, ativo)
    values (auth.uid(), c.nome, lower(u.email), c.papel, c.comissao_servicos, c.comissao_produtos, true, true)
    on conflict (id) do nothing;
  else
    insert into public.equipe (id, nome, email, papel, aprovado, ativo)
    values (auth.uid(),
            coalesce(nullif(trim(u.raw_user_meta_data->>'nome'), ''), split_part(u.email, '@', 1)),
            lower(u.email), 'barbeiro', false, false)
    on conflict (id) do nothing;
  end if;
  return true;
end $$;
revoke all on function public.bp_vincular() from public, anon;
grant execute on function public.bp_vincular() to authenticated;

-- 3. convites antigos que ainda não viraram conta passam a ser cadastros sem login
insert into public.equipe (nome, email, papel, comissao_servicos, comissao_produtos, aprovado, ativo, tem_login)
select c.nome, lower(c.email), c.papel, c.comissao_servicos, c.comissao_produtos, true, true, false
from public.convites c
where not exists (select 1 from public.equipe e where lower(e.email) = lower(c.email));

-- confira: lista os barbeiros cadastrados sem login (vazio é normal)
select nome, email from public.equipe where not tem_login;
