-- Bold Performance · 012: o admin exclui um barbeiro de vez (também quem já tem login)
-- Rode no SQL Editor do Supabase (precisa do 007 já rodado).
-- Apaga o cadastro, as metas e os lançamentos dele, e o convite pelo e-mail.
-- A conta de login também é apagada quando foi criada pelo Bold. Se o e-mail
-- tem conta de outro app neste Supabase (ex.: HABITAH), essa conta fica.

create or replace function public.bp_excluir_barbeiro(barbeiro uuid)
returns void language plpgsql security definer set search_path = ''
as $$
declare alvo public.equipe;
begin
  if not public.bp_sou_admin() then raise exception 'somente o admin exclui barbeiros'; end if;
  select * into alvo from public.equipe where id = barbeiro;
  if not found then return; end if;
  if alvo.papel = 'admin' then raise exception 'conta de admin não é excluída por aqui'; end if;
  delete from public.equipe where id = barbeiro;  -- metas e lançamentos vão junto (on delete cascade)
  if alvo.email is not null then delete from public.convites where lower(email) = lower(alvo.email); end if;
  if alvo.tem_login then
    delete from auth.users where id = barbeiro and coalesce(raw_user_meta_data->>'app', '') = 'bold';
  end if;
end $$;

revoke all on function public.bp_excluir_barbeiro(uuid) from public, anon;
grant execute on function public.bp_excluir_barbeiro(uuid) to authenticated;
