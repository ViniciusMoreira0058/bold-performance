# BOLD PERFORMANCE

Performance dos barbeiros. O admin define as metas do mês de cada barbeiro (faturamento, serviços extras, assinaturas e produtos), cada barbeiro tem a própria conta, lança o resultado do dia e acompanha o painel com nota de 0 a 10, comparação com a média da equipe e dicas.

## O que já existe (versão 1)

| Tela | Quem vê | O que faz |
|---|---|---|
| **Equipe** | Admin | Nota da equipe, totais contra a meta, ranking dos barbeiros com nota, faturamento, % da meta, extras, assinaturas, produtos, atendimentos e ticket; linha de média; gráfico de faturamento por barbeiro; alerta de quem está com nota ruim |
| **Painel do barbeiro** | Barbeiro (o próprio) e admin (qualquer um) | Nota do período com velocímetro, frase de diagnóstico, indicadores contra a meta e contra a média da equipe, dicas, gráfico de evolução, meta do mês com projeção e quanto falta por dia, tabela "você x equipe" |
| **Filtros de período** | Todos | Diário, semanal, quinzenal, mensal, trimestral, semestral e anual, com navegação para períodos anteriores |
| **Metas do mês** | Admin | Metas por barbeiro e por mês; copiar do mês anterior; repetir a 1ª linha para todos |
| **Lançar dia** | Barbeiro (o próprio) e admin (qualquer um) | Atendimentos, serviços R$, extras R$ e quantidade, assinaturas novas, produtos R$ e observação; últimos 7 dias |
| **Minha meta** | Barbeiro | Quanto quer ganhar → faturamento necessário no mês, por dia, por semana e atendimentos por dia, usando a comissão e o ticket médio |
| **Histórico** | Barbeiro | Lançamentos dos últimos 60 dias |
| **Barbeiros** | Admin | Cadastro por e-mail, comissões (serviços e produtos), desativar/reativar |
| **Ajustes** | Todos | Nome da barbearia e dias de trabalho (admin), tema claro/escuro, trocar senha |

## Como a nota é calculada

- A meta do mês é dividida pelos **dias de trabalho** do mês. Em qualquer período o barbeiro é comparado com o que deveria ter feito **até o último dia lançado** (se hoje ainda não tem lançamento, conta até ontem).
- Cada indicador vale realizado ÷ meta. Pesos: faturamento 40%, extras 20%, assinaturas 20%, produtos 20%. Indicador sem meta não entra.
- 100% de tudo = nota 9,0. Acima de 111% = 10. Cada indicador conta no máximo 125%.
- **Muito bom**: 8 ou mais · **Médio**: 6 a 7,9 · **Ruim**: abaixo de 6. As dicas mudam conforme a faixa e atacam primeiro os dois indicadores mais fracos.
- **Faturamento** = serviços + extras + produtos. **Ganho estimado** = (serviços + extras) × comissão de serviços + produtos × comissão de produtos.
- A **média da equipe** considera os barbeiros ativos com lançamento no período. O barbeiro vê a média, nunca os números de cada colega.

## Modo demonstração

Enquanto `SUPABASE_URL` estiver vazio no topo do `index.html`, o app abre em modo demonstração com 4 barbeiros fictícios e 10 meses de dados, salvos só no navegador. Dá para entrar como admin ou como qualquer barbeiro. Também dá para forçar com `?demo=1` na URL.

## Colocar no ar

1. **Supabase**: o app usa o mesmo projeto do HABITAH (as chaves já estão no `index.html`; os nomes das tabelas não colidem). SQL Editor → New query → cole `supabase/schema.sql` → Run. No fim ele já define `barbeariavm0058@gmail.com` como admin (troque o e-mail no fim do arquivo se for outro).
2. **index.html**: preencha `SUPABASE_URL` e `SUPABASE_KEY` (Project Settings → API, chave *publishable/anon*). Nunca coloque a *secret key*.
3. **Vercel**: Add New → Project → importe o repositório → Deploy (site estático, sem configuração).
4. **Supabase → Authentication → URL Configuration**: adicione a URL da Vercel em **Redirect URLs**. Se o projeto for o mesmo do HABITAH, **não troque o Site URL** (ele continua sendo o do HABITAH); basta incluir a URL do Bold na lista de Redirect URLs.
5. Entre com o seu e-mail (Criar conta, se ainda não tiver login nesse Supabase). Em **Barbeiros**, cadastre nome e e-mail de cada um e mande o link do app: eles tocam em **Criar conta** com o mesmo e-mail e caem direto no painel.

## Segurança

- RLS em todas as tabelas. O barbeiro lê e grava só os próprios lançamentos e lê só as próprias metas. Comissão, papel e status só o admin altera (gatilho no banco).
- Quem cria conta sem convite não ganha perfil e vê "conta não autorizada". O gatilho não bloqueia o cadastro, para não atrapalhar outros apps no mesmo Supabase.
- A média da equipe vem da função `bp_resumo_equipe`, que devolve os totais sem nome.

## Próximos passos

1. Domínio próprio apontado para a Vercel
2. Lembrete diário para o barbeiro lançar o dia
3. Importar o faturamento direto do sistema de agenda/caixa, se ele tiver exportação ou API
