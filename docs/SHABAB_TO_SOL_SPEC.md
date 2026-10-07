# SOL — Especificação de referência Shabab → Sol

> Documento de trabalho do laboratório Sol. O objetivo é reproduzir a experiência e o conjunto funcional observado no Shabab:Chat&Meet com implementação independente e identidade Sol. Não usar classes Java, assets proprietários ou código decompilado do Shabab como código do Sol.

## 1. Regra central

**Shabab = mapa funcional e de UX.**  
**Open source = referência de implementação.**  
**Sol = implementação independente, com marca e identidade próprias.**

Tudo que foi confirmado na auditoria entra no backlog/especificação do Sol. Nada deve ser removido só porque não está no primeiro protótipo.

## 2. Experiência principal da sala

Implementar como núcleo:

- descoberta/listagem de salas;
- entrada e saída da sala;
- sala de voz em tempo real;
- grade de cadeiras/microfones;
- ocupação/liberação de cadeira;
- microfone ligado/desligado;
- permissões/moderação de cadeira;
- anfitrião/host;
- administradores da sala;
- chat da sala;
- convite;
- senha/modo da sala;
- plano de fundo;
- música;
- metas/atividade da sala;
- presentes virtuais;
- efeitos/animações de presentes;
- ranking;
- tarefas/recompensas;
- CP;
- jogos dentro da sala;
- notificações/eventos;
- perfil e decoração;
- molduras de avatar;
- rides/decorações;
- chat privado e contatos.

A capacidade de cadeiras não deve ficar artificialmente presa a 8, 30 ou 48: deve ser configurável por tipo de sala/plano, mantendo o comportamento visual estudado.

## 3. Conta e usuário

Módulos observados no APK:

- login;
- senha;
- perfil;
- segurança;
- usuários bloqueados;
- visitantes;
- notificações;
- idioma;
- contatos/amigos;
- chat privado;
- personalização do perfil.

## 4. Voz, RTC e comunicação

O APK analisado contém referências a:

- ByteDance/Volcengine ByteRTC;
- NetEase NIM/Artemis;
- Microsoft Cognitive Services Speech;
- Tencent AAI/ASR;
- Firebase;
- ExoPlayer;
- OkHttp;
- Room/SQLite;
- Glide;
- SVGA/VAP.

Para o Sol, a implementação será independente. A camada RTC preferencial do laboratório é LiveKit; alternativas serão avaliadas separadamente.

## 5. Economia do Sol — LAB

A economia deve existir desde a arquitetura do laboratório, mas inicialmente em **modo simulado**, sem movimentação de dinheiro real.

Camadas:

1. saldo de créditos de teste;
2. Gold;
3. Diamonds;
4. presentes;
5. recompensas;
6. carteira;
7. agência;
8. host;
9. BD;
10. ADM Oficial;
11. ADM Regional;
12. ledger/auditoria;
13. retirada simulada.

Toda alteração de saldo deve gerar evento/ledger imutável com:

- ID;
- usuário;
- operador, quando aplicável;
- origem;
- destino;
- tipo;
- quantidade;
- saldo anterior;
- saldo posterior;
- timestamp;
- motivo;
- referência da operação.

## 6. Estrutura econômica observada no Shabab

A auditoria do APK encontrou rotas/estruturas relacionadas a:

- topUpGoldCoins;
- transferGoldCoins;
- transferGoldCoinsRecord;
- myWallet;
- transaction_details;
- currencyExchangeCenter;
- currencyExchangeAgentCollection;
- agency_wallet;
- agency_income_balance;
- agency_settlement_details;
- agency_settlement_record;
- agency_withdrawal_payment_account;
- withdraw_salary;
- memberWithdraw;
- memberPWithdraw;
- masterPWithdraw;
- withdrawNew;
- withdrawRecord.

Strings/estruturas encontradas:

- goldNum;
- goldValue;
- goldRate;
- diamond;
- diamondBalance;
- diamondIncome;
- usdExchangeGoldRate;
- withdrawDiamond;
- totalWithdrawDiamond;
- hostDiamond;
- hostSalary;
- guildWalletBalance;
- guildMasterSalary;
- guildMasterBonusSalary;
- rewardCoins;
- rewardTotalGoldNum;
- MEMBER_NO_ENOUGH_DIAMOND;
- WITHDRAW_NO_ENOUGH_DIAMOND;
- MINIMUM_WITHDRAWAL_AMOUNT_NOT_MET;
- WithdrawSalaryResponse;
- SaveWithdrawBankInfoParams.

**Conclusão:** existe evidência técnica forte de cadeia Gold/Diamond/wallet/agência/host/withdrawal no APK. Isso não prova, sozinho, como cada pagamento externo é liquidado.

## 7. Revenda / merchants

Há evidência pública adicional na versão 2.12.2 do Shabab de uma função descrita como merchants de moeda que podem receber saldo em dólares em nome de clientes e realizar retirada própria.

Há também documentação de trabalho externa disponível no acervo do projeto descrevendo um modelo de revendedor/agente com:

- primeira recarga;
- depósito de garantia;
- identificação do agente;
- recarga em moeda;
- preço de revenda;
- valor mínimo de recarga;
- referência a Binance/USDT em documentação de OneR.

**Importante:** Binance não deve ser tratado como componente confirmado do Shabab apenas pelo APK. Para Sol, qualquer integração real será separada do laboratório e somente depois de requisitos jurídicos, KYC/AML, pagamentos e operação estarem definidos.

## 8. Agência

Implementar no Sol:

- abertura/aplicação;
- entrada de membros;
- administradores da agência;
- salas;
- ranking;
- estrela;
- carteira;
- saldo;
- ganhos em Diamonds;
- salário/participação do host;
- liquidação;
- registros;
- retirada;
- conta de pagamento;
- retirada pessoal;
- retirada de agente;
- overdraft;
- saída rápida;
- auditoria.

Hierarquia-alvo do ecossistema:

**HOST → AGÊNCIA → BD → ADM OFICIAL**

Com possibilidade de ADM Regional/operacional no painel.

## 9. Host

Implementar:

- criação/gestão de sala;
- cadeira e microfone;
- atividade;
- presentes;
- Diamonds;
- metas;
- ranking;
- recompensas;
- histórico;
- participação econômica virtual no LAB;
- regras de conduta;
- antifraude.

A referência encontrada no acervo OneR contém uma tabela de metas de host de 60.000 até 400.000.000 Diamonds e pagamentos associados. Esses números devem ser tratados como **referência externa do material OneR**, não como regra confirmada do Shabab.

## 10. Jogos

O APK contém:

- HomeGameMatchActivity;
- SudGameView;
- pacotes de jogos baixáveis;
- gameCode;
- gameName;
- gameCost;
- gameZipUrl;
- execução de jogos dentro da sala;
- roulette;
- baiyou/joy;
- carregamento de game package.

No Sol:

- criar catálogo de jogos;
- jogos dentro da sala;
- sessões de jogo;
- custo em créditos LAB;
- resultado;
- ledger;
- ranking/recompensa;
- pacotes versionados;
- ativação/desativação pelo ADM.

Os jogos do laboratório podem começar com jogos sociais/de habilidade. Qualquer operação de dinheiro real ou jogo regulado é uma etapa separada.

## 11. Ranking e progressão

Implementar:

- ranking de riqueza;
- ranking de charme;
- ranking de sala;
- ranking de agência;
- medalhas;
- tarefas de medalha;
- recompensas;
- ranking por período;
- histórico;
- posições e mudanças.

## 12. VIP e decoração

Implementar:

- níveis VIP;
- benefícios configuráveis;
- molduras;
- rides;
- decoração de perfil;
- decoração de sala;
- efeitos;
- presentes especiais;
- gifts de guild/agência;
- Star Shine Gift como referência funcional observada em atualização recente.

A identidade visual não deve copiar a marca/arte proprietária do Shabab.

## 13. Painel Web ADM

O Sol precisa de painel central para:

- usuários;
- salas;
- hosts;
- agências;
- BD;
- ADM;
- carteira;
- ledger;
- Gold;
- Diamonds;
- presentes;
- jogos;
- ranking;
- tarefas;
- VIP;
- decoração;
- metas;
- recompensas;
- auditoria;
- antifraude;
- concessão/reposição de créditos de teste;
- bloqueio/suspensão;
- configuração regional;
- relatórios.

## 14. Política de teste do Sol

Primeira fase:

- cadastro/login real;
- perfil real;
- carteira real dentro do LAB;
- sala real;
- cadeiras;
- voz;
- chat;
- presente com débito de créditos virtuais;
- ledger;
- distribuição econômica simulada;
- jogos;
- ranking;
- tarefas;
- agência;
- painel ADM;
- créditos de teste para contas iniciais;
- auditoria completa.

Créditos LAB não têm valor monetário e não devem ser convertidos em dinheiro.

## 15. Modelo econômico inicial de laboratório

A política de teste existente no projeto propõe, como **modelo de teste**:

- Plataforma/reserva: 50%
- Host: 30%
- Agência: 10%
- BD: 4%
- ADM Oficial: 3%
- ADM Regional: 3%
- Total: 100%

Isso é parâmetro de laboratório, não regra definitiva de produção.

## 16. Arquitetura técnica-alvo

App:

- Flutter;
- Android primeiro;
- possibilidade multiplataforma.

Backend:

- Node.js;
- PostgreSQL;
- WebSocket;
- API REST;
- autenticação;
- ledger transacional.

RTC:

- LiveKit preferencialmente;
- self-hosted quando adequado.

Banco mínimo:

- users;
- profiles;
- rooms;
- room_seats;
- room_members;
- room_events;
- voice_sessions;
- chats;
- gifts;
- gift_catalog;
- wallets;
- wallet_transactions;
- gold_transactions;
- diamond_transactions;
- vip;
- tasks;
- rewards;
- rankings;
- agencies;
- agency_members;
- agency_admins;
- hosts;
- host_targets;
- host_earnings;
- settlements;
- withdrawals_lab;
- games;
- game_catalog;
- game_sessions;
- notifications;
- decorations;
- avatar_frames;
- rides;
- audit_logs;
- admin_roles.

## 17. Identidade visual Sol

Direção:

- azul-noite/preto escuro;
- ouro metálico;
- amarelo dourado;
- azul-claro/água;
- luminosidade/glow;
- aparência premium;
- tipografia com personalidade;
- identidade própria Sol.

A experiência de layout pode seguir as proporções e comportamentos observados no estudo, mas logos, nomes, ícones, ilustrações e assets devem ser próprios/licenciados.

## 18. Estado da auditoria

Confirmado por inspeção do APK:

- package: com.chatwm.live;
- versão analisada: 2.13.8;
- minSdk 24;
- targetSdk 36;
- compileSdk 36;
- voz;
- vídeo/câmera;
- chat;
- presentes;
- carteira;
- Gold;
- Diamonds;
- VIP;
- rankings;
- tarefas/medalhas;
- agência;
- host;
- retirada;
- jogos;
- pacotes de jogos;
- pagamentos in-app;
- múltiplas bibliotecas de RTC/chat/áudio.

O app público também declara salas de voz ao vivo, chat privado, presentes virtuais e decoração personalizada. 

## 19. Itens que ainda precisam de confirmação

Não inventar:

- valores exatos das 7 páginas do PDF Shabab_Policy;
- fórmula completa Gold → Diamond;
- fórmula completa Diamond → USD;
- regras exatas de comissão do Shabab;
- todas as probabilidades/custos dos jogos;
- todos os níveis VIP;
- regras completas de ranking;
- mecanismo externo exato de liquidação;
- Binance como integração própria do Shabab.

Esses itens ficam marcados como **PENDENTE DE CONFIRMAÇÃO** até cruzamento de PDF, APK, strings e comportamento observável.

## 20. Próxima sequência de construção

1. fechar transcrição/checagem do PDF de políticas;
2. fechar matriz funcional completa;
3. transformar a matriz em banco/API;
4. construir sala Sol;
5. integrar voz;
6. chat;
7. presentes + ledger;
8. jogos;
9. ranking/tarefas;
10. carteira LAB;
11. agência/host;
12. painel ADM;
13. testes ponta a ponta;
14. somente depois avaliar camada de produção.

**Regra:** não apagar funcionalidades descobertas no raio-X. O Sol deve crescer para incorporar todo o conjunto funcional confirmado, não apenas um protótipo de sala de voz.
