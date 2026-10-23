-- =====================================================================
-- BOLD PERFORMANCE · fotos de perfil
-- Rode depois do 002 (SQL Editor → New query → cole tudo → Run).
-- Pode rodar mais de uma vez.
--
-- Cada pessoa troca a própria foto; o admin pode trocar a de qualquer um.
-- As fotos ficam no Storage, pasta pública "bp-avatares" (só a foto, sem dados).
-- =====================================================================

alter table public.equipe add column if not exists foto_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('bp-avatares', 'bp-avatares', true, 2097152, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 2097152, allowed_mime_types = array['image/jpeg','image/png','image/webp'];

-- o arquivo se chama <id da conta>.jpg
drop policy if exists bp_avatar_ler on storage.objects;
create policy bp_avatar_ler on storage.objects for select to authenticated
  using (bucket_id = 'bp-avatares');

drop policy if exists bp_avatar_enviar on storage.objects;
create policy bp_avatar_enviar on storage.objects for insert to authenticated
  with check (bucket_id = 'bp-avatares' and (split_part(name, '.', 1) = auth.uid()::text or public.bp_sou_admin()));

drop policy if exists bp_avatar_trocar on storage.objects;
create policy bp_avatar_trocar on storage.objects for update to authenticated
  using (bucket_id = 'bp-avatares' and (split_part(name, '.', 1) = auth.uid()::text or public.bp_sou_admin()))
  with check (bucket_id = 'bp-avatares' and (split_part(name, '.', 1) = auth.uid()::text or public.bp_sou_admin()));

drop policy if exists bp_avatar_apagar on storage.objects;
create policy bp_avatar_apagar on storage.objects for delete to authenticated
  using (bucket_id = 'bp-avatares' and (split_part(name, '.', 1) = auth.uid()::text or public.bp_sou_admin()));

-- confira: deve aparecer 1 linha com bp-avatares
select id, public from storage.buckets where id = 'bp-avatares';
