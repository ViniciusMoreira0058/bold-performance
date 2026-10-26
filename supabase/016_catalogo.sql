-- Bold Performance · 016: serviços e produtos (tabela de preços)
-- Rode no SQL Editor do Supabase (precisa do 007 já rodado). Pode rodar mais de uma vez.
-- O admin cadastra serviços, serviços extras, produtos e bebidas com o preço e o desconto de assinante em %; todos da equipe podem ver.
-- Os preços entram na comissão estimada ("+1 produto por dia = +R$ X").

create table if not exists public.catalogo (
  id         uuid primary key default gen_random_uuid(),
  tipo       text not null check (tipo in ('servico','extra','produto','bebida')),
  marca      text check (length(marca) <= 80),
  nome       text not null check (length(trim(nome)) between 1 and 80),
  preco      numeric(10,2) not null default 0 check (preco >= 0),   -- valor final
  desc_assinante numeric(5,2) check (desc_assinante >= 0 and desc_assinante < 100),  -- % · serviços: assinante · produtos: Prime/Black
  desc_start     numeric(5,2) check (desc_start >= 0 and desc_start < 100),          -- % · produtos: plano Start
  ativo      boolean not null default true,
  criado_em  timestamptz not null default now()
);
create index if not exists catalogo_tipo on public.catalogo (tipo, nome);

alter table public.catalogo enable row level security;

drop policy if exists ca_admin on public.catalogo;
create policy ca_admin on public.catalogo for all to authenticated
  using (public.bp_sou_admin()) with check (public.bp_sou_admin());

-- quem está na equipe (ativo) pode ver a tabela de preços
drop policy if exists ca_ler on public.catalogo;
create policy ca_ler on public.catalogo for select to authenticated
  using (exists (select 1 from public.equipe e where e.id = auth.uid() and e.ativo));

-- quantos clientes são assinantes (em %), para a comissão estimada aplicar os descontos
alter table public.barbearia_config add column if not exists pct_prime numeric(5,2) not null default 30 check (pct_prime between 0 and 100);
alter table public.barbearia_config add column if not exists pct_start numeric(5,2) not null default 10 check (pct_start between 0 and 100);

-- tabela de preços da barbearia (planilha de 26/10/2026); só entra se a tabela estiver vazia
insert into public.catalogo (tipo, marca, nome, preco, desc_assinante, desc_start)
select v.tipo, v.marca, v.nome, v.preco, v.desc_assinante, v.desc_start from (values
  ('servico', null, 'Corte', 50, 10, null),
  ('servico', null, 'Barba', 50, 10, null),
  ('extra', null, 'Sobrancelha', 20, 10, null),
  ('extra', null, 'Penteado', 20, 10, null),
  ('extra', null, 'Acabamento (Pezinho)', 15, 10, null),
  ('extra', null, 'Pigmentação Cabelo', 35, 10, null),
  ('extra', null, 'Pigmentação Barba', 30, 10, null),
  ('extra', null, 'Relaxamento', 35, 10, null),
  ('extra', null, 'Hidratação', 35, 10, null),
  ('extra', null, 'Depilação Nariz', 25, 10, null),
  ('extra', null, 'Depilação Orelha', 25, 10, null),
  ('extra', null, 'Limpeza Facial', 50, 10, null),
  ('extra', null, 'Selagem', 115, 10, null),
  ('extra', null, 'Cone Hindu', 30, 10, null),
  ('extra', null, 'Abordagem Visagista', 200, 10, null),
  ('extra', null, 'Luzes', 130, 10, null),
  ('produto', 'You Man', 'Pomada Bryce Bland', 79.5, 10, 8),
  ('produto', 'You Man', 'Pomada City View', 79.5, 10, 8),
  ('produto', 'You Man', 'Pomada All Ways', 79.5, 10, 8),
  ('produto', 'You Man', 'Leave-In', 82, 10, 8),
  ('produto', 'You Man', 'Balm Bryce Bland', 57.2, 10, 8),
  ('produto', 'You Man', 'Óleo City View', 66, 10, 8),
  ('produto', 'You Man', 'Spray Fixador 400ml', 110, 10, 8),
  ('produto', 'You Man', 'Spray Fixador 150ml', 69.9, 10, 8),
  ('produto', 'You Man', 'Pomada em Pó', 57.2, 10, 8),
  ('produto', 'You Man', 'Body Splash', 78, 10, 8),
  ('produto', 'You Man', 'Pomada Bryce Bland 30g', 45, 10, 8),
  ('produto', 'You Man', 'Shampoo Barba', 78, 10, 8),
  ('produto', 'You Man', 'Shampoo Esfoliante', 60, 10, 8),
  ('produto', 'You Man', 'Pomada Allways 30g', 45, 10, 8),
  ('produto', 'Garden', 'Pomada Neutra', 58, 10, 8),
  ('produto', 'Garden', 'Pomada Matte', 58, 10, 8),
  ('produto', 'Garden', 'Pomada Cera de Abelha', 58, 10, 8),
  ('produto', 'Garden', 'Pomada Black', 58, 10, 8),
  ('produto', 'Garden', 'Óleo Garden', 74.8, 10, 8),
  ('produto', 'Garden', 'Pós Barba Creme', 90, 10, 8),
  ('produto', 'Garden', 'Leave-In Curls', 90, 10, 8),
  ('produto', 'Garden', 'Leave In', 88, 10, 8),
  ('produto', 'Garden', 'Gel Neutro', 39.6, 10, 8),
  ('produto', 'Garden', 'Gel Black', 39.6, 10, 8),
  ('produto', 'Garden', 'Shampoo Fortificante', 80, 10, 8),
  ('produto', 'Garden', 'Tônico', 184, 10, 8),
  ('produto', 'Garden', 'Geleia Modeladora Curls', 77, 10, 8),
  ('produto', 'Garden', 'Balm', 80, 10, 8),
  ('produto', 'Kirkland', 'Minoxidil', 150, 10, 8),
  ('produto', 'Lowell', 'Shampoo Mirtilo', 87.9, 10, 8),
  ('produto', 'Lowell', 'Condicionador Mirtilo', 87.9, 10, 8),
  ('produto', 'Lowell', 'Shampoo Dynamic', 89.9, 10, 8),
  ('produto', 'Lowell', 'Condicionador Dynamic', 89.9, 10, 8),
  ('produto', 'Lowell', 'Sérum', 87.9, 10, 8),
  ('produto', 'Lowell', 'Leave In', 87.9, 10, 8),
  ('produto', 'Jaboque', 'Shampoo 2x1', 49.5, 10, 8),
  ('produto', 'Armazém', 'Pomada Brilho', 82, 10, 8),
  ('produto', 'Armazém', 'Pomada Matte', 82, 10, 8),
  ('produto', 'Armazém', 'Óleo Barba', 75.9, 10, 8),
  ('produto', 'Armazém', 'Leave In', 78, 10, 8),
  ('produto', 'Armazém', 'Balm Hidra', 75.9, 10, 8),
  ('bebida', null, 'Coca Cola Zero 350ml', 6.5, null, null),
  ('bebida', null, 'Coca Cola 350ml', 6.5, null, null),
  ('bebida', null, 'Sprite Zero 350ml', 6.5, null, null),
  ('bebida', null, 'Sprite 350ml', 6.5, null, null),
  ('bebida', null, 'Água c/ Gás', 4.5, null, null),
  ('bebida', null, 'Água s/ Gás', 4, null, null),
  ('bebida', null, 'Energético Monster Zero', 15, null, null),
  ('bebida', null, 'Energético Monster', 15, null, null),
  ('bebida', null, 'Guaraná Antarctica Zero', 6.5, null, null),
  ('bebida', null, 'Guaraná Antarctica', 6.5, null, null),
  ('bebida', null, 'Energético Red Bull 250ml', 13.99, null, null)
) as v(tipo, marca, nome, preco, desc_assinante, desc_start)
where not exists (select 1 from public.catalogo);
