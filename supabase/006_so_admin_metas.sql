-- =====================================================================
-- BOLD PERFORMANCE · só o admin define metas e ganho desejado
-- Rode depois do 005 (SQL Editor → New query → cole tudo → Run).
-- Pode rodar mais de uma vez.
--
-- O barbeiro só visualiza a meta de ganho e o ticket médio; quem altera é
-- o admin. O barbeiro continua podendo trocar o próprio nome e foto.
-- =====================================================================

create or replace function public.bp_proteger_perfil()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if not public.bp_sou_admin() then
    if new.papel <> old.papel or new.ativo <> old.ativo or new.aprovado <> old.aprovado
       or new.comissao_servicos <> old.comissao_servicos
       or new.comissao_produtos <> old.comissao_produtos or new.id <> old.id
       or new.ganho_desejado is distinct from old.ganho_desejado
       or new.ticket_medio is distinct from old.ticket_medio then
      raise exception 'somente o admin altera papel, status, aprovação, comissão, ganho desejado e ticket médio';
    end if;
  end if;
  return new;
end $$;

-- confira: deve aparecer 1 linha com bp_proteger_perfil
select tgname from pg_trigger where tgname = 'bp_proteger_perfil';
