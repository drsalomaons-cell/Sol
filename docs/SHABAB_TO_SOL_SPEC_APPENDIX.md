

## 19. PARIDADE DE LOJA, COSM├ëTICOS, PRESENTES, EVENTOS E RECOMPENSAS ÔÇö CHECKLIST OBRIGAT├ôRIO

Esta se├º├úo ├® obrigat├│ria para o Sol. O primeiro prot├│tipo pode usar itens pr├│prios/tempor├írios, mas nenhuma destas categorias deve ser eliminada do produto final.

### 19.1 Loja / Mall
A loja deve ser tratada como um cat├ílogo completo e extens├¡vel, com categorias separadas e busca/filtros:
- recarga de moeda;
- Gold/credits e pacotes;
- Diamonds/recompensas;
- presentes virtuais;
- presentes com anima├º├úo especial;
- molduras de avatar;
- bolhas/efeitos de chat ou mensagem;
- carros/rides/ve├¡culos;
- decora├º├Áes de perfil;
- decora├º├Áes/efeitos de entrada;
- t├¡tulos/medalhas/badges;
- itens VIP;
- itens tempor├írios e permanentes;
- itens obtidos por evento/tarefa/recompensa;
- itens de destaque/raridade;
- hist├│rico de compra, posse, uso e validade;
- itens gratuitos/promocionais;
- itens que retornam/reaparecem por ciclo/evento, quando aplic├ível.

### 19.2 Identidade visual do usu├írio
O Sol deve possuir sistema independente para equipar/retirar:
- moldura do avatar;
- efeito/borda do perfil;
- bolha/estilo de mensagem;
- entrada/entrada especial na sala;
- carro/ride;
- t├¡tulo;
- medalha/badge;
- decora├º├úo;
- VIP;
- outros cosm├®ticos desbloque├íveis.

Cada item deve ter ID, nome, categoria, raridade, dura├º├úo, estado de posse, pre├ºo/recompensa, asset pr├│prio do Sol e regras de disponibilidade.

### 19.3 Presentes e efeitos
Implementar motor de presentes, n├úo apenas uma lista est├ítica:
- presente normal;
- presente de alto valor;
- presente com anima├º├úo;
- presente de entrada/efeito;
- presente que contribui para meta da sala/host;
- presente que contribui para ranking;
- presente de evento;
- presente especial/limitado;
- presente com contagem/combina├º├úo quando a regra do item exigir;
- confirma├º├úo de envio;
- d├®bito do saldo;
- cr├®dito do destinat├írio/receita em Diamonds conforme a regra configurada;
- registro no ledger;
- exibi├º├úo da anima├º├úo;
- hist├│rico de presentes enviados/recebidos.

### 19.4 Ba├║/caixa, foguete e efeitos de sala
As refer├¬ncias observadas pelo usu├írio incluem mecanismos de evento/efeito como ba├║/caixa que pode ser estourado/ativado e foguete. No Sol eles ser├úo implementados como mec├ónicas pr├│prias, configur├íveis e n├úo como c├│pia de assets:
- ba├║/caixa de sala;
- ativa├º├úo/abertura/estouro;
- recompensa associada;
- anima├º├úo/efeito coletivo;
- foguete/efeito de destaque;
- efeitos especiais acionados por presentes ou metas;
- fila/prioridade de anima├º├Áes para evitar conflito;
- registro da origem do efeito e recompensa.

Quando uma regra exata n├úo estiver comprovada no APK/PDF, o campo permanece CONFIGUR├üVEL e marcado como PENDENTE DE CONFIRMA├ç├âO; n├úo inventar n├║meros.

### 19.5 Metas
Implementar metas em pelo menos estes n├¡veis:
- meta da sala;
- meta do host;
- meta baseada em presentes/atividade;
- progresso em tempo real;
- percentual/progresso visual;
- contribui├º├úo por usu├írio;
- recompensa ao atingir marco;
- hist├│rico de metas;
- reset/ciclo configur├ível;
- integra├º├úo com eventos e tarefas;
- integra├º├úo com ranking.

### 19.6 Tarefas
Implementar sistema de tarefas com:
- tarefas di├írias;
- tarefas semanais;
- tarefas de evento;
- tarefas de atividade de sala;
- tarefas de envio/recebimento de presentes;
- tarefas de recarga, quando habilitadas;
- tarefas sociais;
- tarefas de host/ag├¬ncia;
- progresso;
- conclus├úo;
- recompensa;
- resgate;
- prazo;
- hist├│rico;
- regras de elegibilidade;
- preven├º├úo de resgate duplicado.

### 19.7 Datas comemorativas e eventos
Criar um calend├írio de eventos configur├ível, sem codificar datas diretamente na interface:
- eventos sazonais;
- datas comemorativas;
- eventos regionais por pa├¡s/idioma;
- campanhas tempor├írias;
- loja tem├ítica;
- presentes tem├íticos;
- molduras/bolhas/carros tem├íticos;
- tarefas tem├íticas;
- metas tem├íticas;
- recompensas tem├íticas;
- ranking/evento;
- in├¡cio/fim;
- fuso hor├írio;
- regras de repeti├º├úo;
- prioridade quando dois eventos coincidem.

A primeira implementa├º├úo deve suportar Brasil, LATAM, pa├¡ses ├írabes e pa├¡ses europeus selecionados como configura├º├úo de calend├írio; o conjunto final de datas ser├í confirmado a partir da pesquisa de rentabilidade/eventos j├í prevista.

### 19.8 VIP
Implementar o sistema VIP como m├│dulo pr├│prio:
- n├¡vel/status;
- benef├¡cios;
- progress├úo;
- dura├º├úo/renova├º├úo;
- itens exclusivos;
- molduras;
- efeitos;
- privil├®gios;
- loja VIP;
- tarefas/recompensas relacionadas;
- hist├│rico;
- regras de elegibilidade.

Os n├¡veis, pre├ºos e benef├¡cios exatos do Shabab s├│ entram como par├ómetros depois de confirma├º├úo; n├úo inventar valores.

### 19.9 Regras e pol├¡ticas
O Sol deve possuir um motor/configura├º├úo de regras para:
- entrada e sa├¡da;
- cadeiras/microfones;
- host/admin;
- pedidos para falar;
- mute/kick/ban/bloqueio;
- presentes;
- metas;
- tarefas;
- ranking;
- VIP;
- loja;
- validade de itens;
- eventos;
- recompensas;
- carteira/ledger;
- ag├¬ncia/host;
- retirada;
- limites m├¡nimos/m├íximos;
- antifraude/auditoria.

As pol├¡ticas encontradas no PDF j├í auditado permanecem no backlog obrigat├│rio:
1. Host Policy
2. Coins Seller Policy
3. Agency Opening Rewards
4. Host Weekly Rewards
5. Agency Weekly Rewards
6. Agency Monthly Rewards
7. Supporters' Rewards

Os valores das tabelas do PDF ainda devem ser transcritos por inspe├º├úo/OCR antes de virar regra execut├ível.

### 19.10 Navega├º├úo de paridade
O fluxo do Sol deve permitir chegar a todas as ├íreas funcionais sem telas mortas:
In├¡cio/Descoberta ÔåÆ Sala ÔåÆ Perfil ÔåÆ Loja/Mall ÔåÆ Presentes ÔåÆ VIP ÔåÆ Tarefas ÔåÆ Eventos ÔåÆ Rankings ÔåÆ Wallet ÔåÆ Ag├¬ncia/Host ÔåÆ Admin.

### 19.11 Regra de n├úo omiss├úo
Se uma fun├º├úo for descoberta posteriormente no APK, PDF, telas, assets ou comportamento observado do Shabab e ainda n├úo estiver implementada, ela deve ser adicionada a esta matriz como PENDENTE, e n├úo descartada.

### 19.12 Regra de diferencia├º├úo do Sol
A fun├º├úo pode ser equivalente, mas o Sol dever├í substituir:
- marca/nome;
- ├¡cone;
- splash;
- nomes comerciais;
- assets propriet├írios;
- textos propriet├írios;
- identidade visual;
- nomes espec├¡ficos de itens quando necess├írio;
- implementa├º├úo interna.

O resultado deve ser um produto Sol independente, usando comportamento/UX auditados como refer├¬ncia e implementa├º├úo baseada em componentes open source/licenciados ou c├│digo pr├│prio.