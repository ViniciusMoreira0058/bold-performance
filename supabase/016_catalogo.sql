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
