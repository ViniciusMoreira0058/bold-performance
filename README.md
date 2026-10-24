# BOLD PERFORMANCE

Performance dos barbeiros. O admin define as meta de faturamento do mês de cada barbeiro, o admin atualiza o total do mês de serviços, extras e produtos de cada um e cada barbeiro, com a própria conta, acompanha o painel com nota de 0 a 10, comparação com a média da equipe e dicas.

## O que já existe (versão 1)

| Tela | Quem vê | O que faz |
|---|---|---|
| **Dashboard** | Admin (primeira tela) | Nota geral da equipe no mês e na semana, projeção do mês, comparação com o mesmo período do mês anterior, faturamento contra a meta, serviços, extras e produtos com a parte de cada um no faturamento, quanto falta por dia, resultado de hoje (ou ontem) e quem falta atualizar, destaques, faturamento acumulado x meta e nota de cada barbeiro |
| **Equipe** | Admin | Nota da equipe, totais contra a meta, ranking dos barbeiros com nota, faturamento, % da meta, serviços, extras e produtos; linha de média; gráfico de faturamento por barbeiro; alerta de quem está com nota ruim |
| **Painel do barbeiro** | Barbeiro (o próprio) e admin (qualquer um) | Admin edita a meta do mês e a meta de comissão ali mesmo (a nota e os números recalculam na hora); Nota do período com velocímetro, frase de diagnóstico, indicadores contra a meta e contra a média da equipe, dicas, gráfico de evolução, meta do mês com projeção e quanto falta por dia, tabela "você x equipe" |
| **Filtros de período** | Todos | Diário, semanal, quinzenal, mensal, trimestral, semestral e anual, com navegação para períodos anteriores |
| **Meta da barbearia** | Admin | Meta de faturamento geral do mês; quanto cada barbeiro precisa faturar (pelo histórico dos 90 dias ou igual para todos) e botão para gravar isso nas metas; comparação de cada barbeiro com a média (muito acima / na média / abaixo) e quem está melhor e pior em cada indicador |
| **Meta do barbeiro** | Admin | Metas por barbeiro e por mês, e a meta de comissão de cada barbeiro; copiar do mês anterior; repetir a 1ª linha para todos |
| **Lançamentos** | Só o admin (para qualquer barbeiro) | Todos os barbeiros numa tela: o admin digita o total do mês (desde o dia 1) de serviços, extras, produtos e assinaturas (R$), mais a comissão até hoje (não soma no faturamento), até a data escolhida; o app guarda quanto entrou desde a última atualização e mostra o faturamento do mês e o % da meta enquanto digita; lista das atualizações do mês com corrigir e excluir (o valor da excluída passa para a próxima); importação do relatório do CashBarber (CSV) só para a receita de assinaturas da barbearia (ignorada no mês em que as assinaturas dos barbeiros forem lançadas, para não duplicar) |
| **Relatórios** | Admin | Fechamento do mês (ranking, % da meta, composição, comissão e nota), evolução mês a mês, mix de vendas (serviços/extras/produtos/assinaturas contra a média), comissão x faturamento (quanto fica para a barbearia) e histórico de metas (meses batidos e sequência); cada um baixa em planilha CSV para o Excel |
| **Minha meta** | Barbeiro (só vê) | Meta de comissão definida pelo admin (comparada com a comissão lançada até hoje) → faturamento necessário no mês, por dia, por semana e atendimentos por dia; quanto já ganhou; onde pode chegar (ritmo atual, batendo a meta, passando 20%) |
| **Histórico** | Barbeiro | Lançamentos dos últimos 60 dias |
| **Barbeiros** | Admin | Cadastrar barbeiro (nome e e-mail opcional) antes de ele criar o login: já dá para lançar, importar e definir metas; quando ele cria a conta com o mesmo e-mail, liga ao cadastro com todo o histórico. Aprovar novos cadastros, comissões, desativar/reativar |
| **Ajustes** | Todos | Nome da barbearia e dias de trabalho (admin), tema claro/escuro, trocar senha |

## Como a nota é calculada

- A meta do mês é dividida pelos **dias de trabalho** do mês. Em qualquer período o barbeiro é comparado com o que deveria ter feito **até o último dia lançado** (se hoje ainda não tem lançamento, conta até ontem).
- A nota é o **faturamento** (serviços + extras + produtos + assinaturas) ÷ meta de faturamento até aquele dia. Sem meta, não tem nota.
- 100% da meta = nota 9,0. Acima de 111% = 10.
- **Muito bom**: 8 ou mais · **Médio**: 6 a 7,9 · **Ruim**: abaixo de 6. As dicas mudam conforme a faixa e atacam primeiro os dois indicadores mais fracos.
- **Faturamento** = serviços + extras + produtos + assinaturas. **Ganho estimado** = (serviços + extras) × comissão de serviços + produtos × comissão de produtos.
- A **média da equipe** considera os barbeiros ativos com lançamento no período. O barbeiro vê a média, nunca os números de cada colega.

## Modo demonstração

Enquanto `SUPABASE_URL` estiver vazio no topo do `index.html`, o app abre em modo demonstração com 4 barbeiros fictícios e 10 meses de dados, salvos só no navegador. Dá para entrar como admin ou como qualquer barbeiro. Também dá para forçar com `?demo=1` na URL.

## Colocar no ar

1. **Supabase**: o app usa o mesmo projeto do HABITAH (as chaves já estão no `index.html`; os nomes das tabelas não colidem). SQL Editor → New query → cole `supabase/schema.sql` → Run. No fim ele já define `barbeariavm0058@gmail.com` como admin (troque o e-mail no fim do arquivo se for outro).
2. **index.html**: preencha `SUPABASE_URL` e `SUPABASE_KEY` (Project Settings → API, chave *publishable/anon*). Nunca coloque a *secret key*.
3. **Vercel**: Add New → Project → importe o repositório → Deploy (site estático, sem configuração).
4. **Supabase → Authentication → URL Configuration**: adicione a URL da Vercel em **Redirect URLs**. Se o projeto for o mesmo do HABITAH, **não troque o Site URL** (ele continua sendo o do HABITAH); basta incluir a URL do Bold na lista de Redirect URLs.
5. Rode também `supabase/002_cadastro_livre.sql`, `supabase/003_fotos.sql` (fotos de perfil), `supabase/004_so_admin_lanca.sql` (só o admin lança; o barbeiro só vê) `supabase/005_meta_barbearia.sql` (meta geral da barbearia) `supabase/006_so_admin_metas.sql` (só o admin define o ganho desejado) `supabase/007_cadastro_sem_login.sql` (cadastrar barbeiro antes de ele criar o login) `supabase/008_receita_assinaturas.sql` (receita de assinaturas da planilha) `supabase/009_assinatura_barbeiro.sql` (faturamento de assinaturas por barbeiro) `supabase/010_comissao.sql` (comissão até hoje, comparada com a meta de comissão em Minha meta) `supabase/011_trocar_email.sql` (o admin troca o e-mail de login de um barbeiro em Barbeiros) e `supabase/012_excluir_barbeiro.sql` (o admin exclui um barbeiro de vez, inclusive a conta de login criada pelo Bold). Depois entre com o seu e-mail (o mesmo login do HABITAH) e mande o link do app para os barbeiros: cada um toca em **Criar conta** e aparece para você em **Novos cadastros**, aguardando aprovação. Se preferir, cadastre o e-mail antes em **Barbeiros**: aí ele já entra aprovado.

## Segurança

- RLS em todas as tabelas. O barbeiro só lê os próprios lançamentos (quem lança é o admin) e lê só as próprias metas. Comissão, papel e status só o admin altera (gatilho no banco).
- Quem cria conta pelo Bold sem convite entra como pendente: não vê dados da equipe nem lança até o admin aprovar. O barbeiro não consegue se aprovar sozinho (gatilho no banco). Cadastros feitos pelo HABITAH são ignorados pelo Bold.
- A média da equipe vem da função `bp_resumo_equipe`, que devolve os totais sem nome.

## Próximos passos

1. Domínio próprio apontado para a Vercel
2. Lembrete diário para o barbeiro lançar o dia
3. Importar o faturamento direto do sistema de agenda/caixa, se ele tiver exportação ou API
