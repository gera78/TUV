# ZSD_BR_NFSE – Histórico de versões

Cada versão lista os problemas tratados, o que foi alterado e os objetos SAP a transportar. Versões anteriores à 0.5 estão resumidas a partir do histórico do repositório.

| Versão | Data | Alterado por | Resumo |
|---|---|---|---|
| [0.5](#versão-05--04112026-a-06112026) | 04.11.2026 – 06.11.2026 | Alexandre Marcondes Silva | Correções do teste de criação da NF, check string da NF Writer, tabela de parâmetros classe A, mensagens de configuração como aviso |
| [0.4](#versão-04--09102026-a-12102026) | 09.10.2026 – 12.10.2026 | Renato Santos | Versão inicial do código, gerador do DDIC, carga de parâmetros, arquivo de saída CSV |

---

## Versão 0.5 – 04.11.2026 a 06.11.2026

**Alterado por:** Alexandre Marcondes Silva
**Branch:** `revisao/mensagens-validacao-linha`

### Problemas corrigidos

| # | Problema | Causa | Alteração | Objeto |
|---|---|---|---|---|
| 1 | **Dump ao criar a NF: "function parameter … is unknown"** | `BAPI_J_1B_NF_CREATEFROMDATA` chamada com `IMPORTING DOC_NUMBER`; o parâmetro correto é `E_DOCNUM` | Parâmetro corrigido. A chamada ficou protegida (`TRY/CATCH CX_SY_DYN_CALL_ERROR` + `EXCEPTIONS ERROR_MESSAGE/OTHERS`): qualquer falha vira erro no log da linha (nova mensagem **047**), com rollback e status E, sem dump | `ZSD_BR_NFSE_F01` (`CREATE_NF`), msg 047 |
| 2 | **8B 685 – Valuation area is not assigned to plant 5596** | Área de avaliação (`BWKEY`) do item nunca era preenchida | `DETERMINE_PLANT` lê `T001W-BWKEY` do centro (`GV_BWKEY`); `BUILD_BAPI_ITEM` envia no item | `ZSD_BR_NFSE_TOP`, `ZSD_BR_NFSE_F01` |
| 3 | **8B 660 – Enter the usage of the material** | A carga de parâmetros cria `MATUSE` (e outros) com `Z_OUTPUT` vazio; a validação 025 só verificava se o parâmetro existia | Validação 025 passa a exigir valor preenchido (CFOP, TAXLW1–5, ITMTYP, MATUSE); `MATORG` incluído na verificação | `ZSD_BR_NFSE_F01` (`CHECK_LINE_CONFIG`) |
| 4 | **8B 150 – Tax situation missing / 8B 151 – NCM code missing** | Checks padrão de situação tributária ICMS/IPI e de NCM não se aplicam ao item de serviço | Novo check string da NF Writer com os checks **13, 27 e 28 desligados**, passado à BAPI no parâmetro `NFCHECK` | `ZSD_BR_NFSE_F01` (`BUILD_BAPI_NFCHECK`, `CREATE_NF`) |

### Melhorias

| # | Alteração | Objeto |
|---|---|---|
| 5 | **Novo `FORM BUILD_BAPI_NFCHECK`**: monta o check string de 47 posições lido pela rotina padrão `CHECK_NF_BAPI`, uma variável por check com comentário do que o `X` ativa. Passado à BAPI em `NFCHECK-CHEKCON` (CHAR 50, conferido na SE11) | `ZSD_BR_NFSE_F01` |
| 6 | **Mensagens de configuração 023 e 025 só como aviso no Validate only**: novo `FORM ADD_CONFIG_LOG`. Na execução real não são geradas e o erro vem do retorno da BAPI | `ZSD_BR_NFSE_F01` |
| 7 | **Tabela `ZSD_BR_NFSE_PARM` com classe de entrega A** (aplicação) em vez de C (customizing): parâmetros mantidos direto em cada mandante, sem ordem de transporte | `ZSD_BR_NFSE_DDIC_GEN`, SE11, SE54 |
| 8 | Nova mensagem **047** "Error calling &1: &2&3&4" na classe `ZSD_BR_NFSE_MSG` | `ZSD_BR_NFSE_DDIC_GEN` / SE91 |
| 4a | **Total da NF 2.100 em vez de 2.000 / retenções sem flag** (comparação com NF de serviço correta do SD, 226744) | Item com `TMISS = X` (serviço, sem ICMS/IPI) e `INCLTX = X` (preço com ISS); leis ICMS/IPI (TAXLW1/TAXLW2) não enviadas nem validadas; linhas de imposto retido com `WITHHOLD = X` e `TAXINNET = X` (`FORM SET_WITHHELD`); função de parceiro **RE** em vez de AG; cabeçalho com `NFESRV = X` e `MUNICIPAL = X` | `ZSD_BR_NFSE_TOP`, `ZSD_BR_NFSE_F01` (`BUILD_BAPI_ITEM`, `BUILD_BAPI_TAXES`, `APPEND_TAX`, `CHECK_LINE_CONFIG`) |
| 8a | **Descrição do serviço no texto de cabeçalho da NF** (problema: texto ia para `OBJ_HEADER_MSG` e não aparecia na J1B3N). Com o novo parâmetro `HDR_TEXT_ID`, a coluna AH "Discriminação dos Serviços" vai para `OBJ_HEADER_TEXT` (linhas de 132 caracteres); parâmetro vazio mantém o `OBJ_HEADER_MSG` | `ZSD_BR_NFSE_TOP`, `ZSD_BR_NFSE_F01` (`BUILD_BAPI_TEXTS`, `CREATE_NF`), `ZSD_BR_NFSE_PARM_LOAD` |

### Documentação

| # | Documento |
|---|---|
| 9 | Nova especificação Word das mensagens de validação de linha: `ZSD_BR_NFSE_Mensagens_Validacao_Linha.docx` |
| 10 | Nova documentação do check string: `ZSD_BR_NFSE_NFCHECK.md` |
| 11 | `ZSD_BR_NFSE_Design.md`: versão 0.5; seção 11.6 (retorno com `E_DOCNUM` e falhas sem dump), nova seção 11.7 (check string), mensagens 023/025/047; pendências **P25** (parâmetro `MATNR` por código de serviço) e **P26** (erros do teste de 06.11.2026) |
| 12 | `ZSD_BR_NFSE_DDIC.md`: classe de entrega A da tabela de parâmetros, mensagem 047 |

### Objetos SAP a atualizar

| Objeto | Ação |
|---|---|
| Include `ZSD_BR_NFSE_TOP` | Copiar e ativar (antes da F01) |
| Include `ZSD_BR_NFSE_F01` | Copiar e ativar |
| Include `ZSD_BR_NFSE_F02_ADM` | Opcional (só comentários) |
| Programas `ZSD_BR_NFSE_UPLOAD` / `ZSD_BR_NFSE_UPLOAD_ADM` | Sem alteração de código; ativar junto com as includes |
| Programa `ZSD_BR_NFSE_DDIC_GEN` | Copiar e rodar (cria a mensagem 047) – ou criar a 047 na SE91 |
| Tabela `ZSD_BR_NFSE_PARM` | SE11: classe de entrega C → A. SE54: regerar com "sem rotina de gravação ou rotina do usuário" |
| Programa `ZSD_BR_NFSE_PARM_LOAD` | Copiar e ativar (proposta do parâmetro `HDR_TEXT_ID`) |
| Parâmetros (SM30) | Preencher `Z_OUTPUT` de MATUSE, ITMTYP, TAXLW3–5, TAXTYP_*; criar `HDR_TEXT_ID`; CFOP no formato `5933/AA` / `6933/AA`; `TAXLW3 = I01` |

### Pendências abertas

- **ID do texto de cabeçalho** (`HDR_TEXT_ID`) – definir qual ID de texto a J1B3N mostra no cabeçalho da NF.
- **P25** – confirmar se o material deve ser determinado pelo código de serviço (parâmetro `MATNR`).
- Na execução real, parâmetros vazios de configuração não bloqueiam mais a linha; com o check 27 desligado, a NF pode ser criada sem TAXLW1/TAXLW2. Rodar sempre o Validate only antes.

---

## Versão 0.4 – 09.10.2026 a 12.10.2026

**Alterado por:** Renato Santos

- Desenho funcional/técnico v0.2 a v0.4 (popup de duplicidade, bloqueio, LUW única, expurgo LGPD, reprocessamento, arquivo de saída CSV no layout da PMSP com controle de exportação).
- Código ABAP inicial: `ZSD_BR_NFSE_UPLOAD`, `ZSD_BR_NFSE_UPLOAD_ADM` e includes.
- Gerador do DDIC `ZSD_BR_NFSE_DDIC_GEN` e carga inicial de parâmetros `ZSD_BR_NFSE_PARM_LOAD`.
- Correções de sintaxe e de tipos (AUTHORITY-CHECK, SELECT-OPTIONS, `RP_CALC_DATE_IN_INTERVAL`, campos `Z_INPUT`/`Z_OUTPUT`).
- Opção de colar a planilha pela área de transferência – mantida só no branch `feature/clipboard-paste`.
