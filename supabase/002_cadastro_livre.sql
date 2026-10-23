-- =====================================================================
-- BOLD PERFORMANCE · cadastro livre dos barbeiros
-- Rode depois do schema.sql (SQL Editor → New query → cole tudo → Run).
-- Pode rodar mais de uma vez.
--
-- Agora o barbeiro cria a conta sozinho pelo app e aparece para o admin
-- em "Novos cadastros", aguardando aprovação. Até ser aprovado ele não vê
-- nada da equipe nem consegue lançar. E-mails cadastrados antes pelo admin
-- continuam entrando já aprovados.
-- =====================================================================

alter table public.equipe add column if not exists aprovado boolean not null default true;

-- cria o perfil no cadastro: com convite entra aprovado; pelo app do Bold entra pendente.
-- Cadastros de outros apps no mesmo Supabase (ex.: HABITAH) são ignorados.
create or replace function public.bp_novo_usuario()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare c public.convites;
begin
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

-- o barbeiro não pode se aprovar sozinho
create or replace function public.bp_proteger_perfil()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if not public.bp_sou_admin() then
    if new.papel <> old.papel or new.ativo <> old.ativo or new.aprovado <> old.aprovado
       or new.comissao_servicos <> old.comissao_servicos
       or new.comissao_produtos <> old.comissao_produtos or new.id <> old.id then
      raise exception 'somente o admin altera papel, status, aprovação e comissão';
    end if;
  end if;
  return new;
end $$;

revoke all on function public.bp_vincular() from public, anon;
grant execute on function public.bp_vincular() to authenticated;

-- confira: lista quem está aguardando aprovação (vazio no começo é normal)
select nome, email from public.equipe where not aprovado;
