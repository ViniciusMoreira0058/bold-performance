-- Bold Performance · 011: o admin troca o e-mail de um barbeiro
-- Rode no SQL Editor do Supabase (precisa do 007 já rodado).
-- Barbeiro sem login: troca só o e-mail do cadastro (ele cria a conta com o e-mail novo).
-- Barbeiro com login: troca também o e-mail de entrada; a senha continua a mesma.
-- Não mexe em contas de admin nem em e-mails que já têm outra conta neste Supabase (ex.: HABITAH).

create or replace function public.bp_trocar_email(barbeiro uuid, novo text)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  e text := lower(trim(novo));
  alvo public.equipe;
begin
  if not public.bp_sou_admin() then raise exception 'somente o admin troca o e-mail'; end if;
  if e is null or e !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'e-mail inválido'; end if;
  select * into alvo from public.equipe where id = barbeiro;
  if not found then raise exception 'barbeiro não encontrado'; end if;
  if alvo.papel = 'admin' then raise exception 'o e-mail do admin não é trocado por aqui'; end if;
  if exists (select 1 from public.equipe where lower(email) = e and id <> barbeiro) then
    raise exception 'já existe alguém da equipe com esse e-mail';
  end if;
  if alvo.tem_login then
    if exists (select 1 from auth.users where lower(email) = e and id <> barbeiro) then
      raise exception 'esse e-mail já tem uma conta neste Supabase';
    end if;
    update auth.users set email = e, updated_at = now() where id = barbeiro;
    update auth.identities set identity_data = jsonb_set(identity_data, '{email}', to_jsonb(e)), updated_at = now()
     where user_id = barbeiro and provider = 'email';
  end if;
  update public.equipe set email = e where id = barbeiro;
end $$;

revoke all on function public.bp_trocar_email(uuid, text) from public, anon;
grant execute on function public.bp_trocar_email(uuid, text) to authenticated;
