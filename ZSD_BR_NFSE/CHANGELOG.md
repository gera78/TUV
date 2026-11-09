# ZSD_BR_NFSE – Histórico de versões

Cada versão lista os problemas tratados, o que foi alterado e os objetos SAP a transportar. Versões anteriores à 0.5 estão resumidas a partir do histórico do repositório.

| Versão | Data | Alterado por | Resumo |
|---|---|---|---|
| [0.7](#versão-07--em-andamento) | 06.11.2026 – | Alexandre Marcondes Silva | Open topics da 0.5: simulação no Validate only, descrição em PT, série e código de recolhimento por parâmetro |
| [0.6](#versão-06--06112026) | 06.11.2026 | Alexandre Marcondes Silva | Ajustes após o teste de 06.11.2026 (open topics da 0.5) |
| [0.5](#versão-05--04112026-a-06112026) | 04.11.2026 – 06.11.2026 | Alexandre Marcondes Silva | Correções do teste de criação da NF, check string da NF Writer, tabela de parâmetros classe A, mensagens de configuração como aviso |
| [0.4](#versão-04--09102026-a-12102026) | 09.10.2026 – 12.10.2026 | Renato Santos | Versão inicial do código, gerador do DDIC, carga de parâmetros, arquivo de saída CSV |

---

## Versão 0.7 – em andamento

**Alterado por:** Alexandre Marcondes Silva
**Branch:** `ajustes/v0.7`

| # | Open topic | Alteração | Objeto |
|---|---|---|---|
| OT10 | Validate only não chamava a BAPI: erros da NF Writer (CFOP, leis, tipos de imposto, centro…) só apareciam na execução real | Validate only monta a NF igual à execução real e chama a BAPI com `SIMULATION = 'X'` + rollback (nenhuma NF criada). Cada mensagem E/A da BAPI vai para o log da linha como **aviso (W)**; status da linha continua V | `ZSD_BR_NFSE_F01` (`MARK_VALIDATED`, novo `SIMULATE_NF`), `ZSD_BR_NFSE_TOP` |
| OT5 | Descrição do material em inglês | `MAKT` lida em português (`GC_NF_LANGU = 'P'`); idioma de logon só se não houver texto em PT | `ZSD_BR_NFSE_F01` (`PREFETCH_MASTER_DATA`) |
| OT6 | Série vazia (NF do SD: série 1) | Parâmetro opcional `NF_SERIES` (fixo, `*`): se preenchido, substitui a série do tipo de NF (`J_1BAA`). Uso do `NFNUM` (RPS) continua em P1 | `ZSD_BR_NFSE_F01` (`BUILD_BAPI_HEADER`), `ZSD_BR_NFSE_TOP` |
| OT4 | Código de recolhimento das retenções vazio (NF do SD: 5952 / 1708) | Parâmetro opcional `COLLCODE` (coluna vazia, `Z_INPUT` = tipo de imposto ou `*`) → campo `COLLCODE` da linha de imposto (novo `SET_COLLCODE`) | `ZSD_BR_NFSE_F01`, `ZSD_BR_NFSE_TOP` |
| #15 | Campos CBS/IBS do item vazios na aba Taxes II (situação tributária, código, classificação – NF do SD: A01 / 000 / 000001) | Campos da reforma ficam na `BAPI_J_1BNFLIN_ADD` (parâmetro `OBJ_ITEM_ADD`), não na `BAPI_J_1BNFLIN`: o programa nunca os enviava. Agora `OBJ_ITEM_ADD` com `TAXSITUATION` (parâmetro `CBSIBS_TAXSIT`), `CST` (parâmetro `CBSIBS_CST`), `CCLASSTRIB` (coluna AY ou parâmetro `CCLASSTRIB`), `NBS` e `CINDOP` – nomes por analogia com os campos de IS (`TAXSITUATIONIS`, `CSTIS`, `CCLASSTRIBIS`), a confirmar na SE11 | `ZSD_BR_NFSE_TOP`, `ZSD_BR_NFSE_F01` (`BUILD_BAPI_ITEM`, `CREATE_NF`, `SIMULATE_NF`), `ZSD_BR_NFSE_PARM_LOAD` |
| OT2 / OT3 | Lei ISS e tipo de ISS | Carga de parâmetros propõe `TAXLW3` N = `I01` e `TAXTYP_ISS` N = `ISSA` (como a NF do SD 226744), `NF_SERIES` = 1, `COLLCODE` ICSQ = 5952 e IIRW = 1708 – a confirmar com o fiscal | `ZSD_BR_NFSE_PARM_LOAD` |

**A conferir no sistema (SE11/SE37):** nomes dos campos CBS/IBS na `BAPI_J_1BNFLIN_ADD` (`TAXSITUATION`, `CST`, `CCLASSTRIB`, `NBS`, `CINDOP`); domínio do parâmetro `SIMULATION` (`J_1BNFE_SIMULATE`) aceita `X`; campo `COLLCODE` existe na `BAPI_J_1BNFSTX` (se não existir, o código de recolhimento não é enviado – sem erro).

**Objetos SAP a atualizar:** `ZSD_BR_NFSE_TOP`, `ZSD_BR_NFSE_F01` (ativar com `ZSD_BR_NFSE_UPLOAD` e `ZSD_BR_NFSE_UPLOAD_ADM`), `ZSD_BR_NFSE_PARM_LOAD`; parâmetros `NF_SERIES` e `COLLCODE` (SM30), se usados.

**Continuam abertos:** OT7 (`HDR_TEXT_ID`), OT8 (`infCpl` via BAdI), OT9 (P25), OT11 (estornar NFs de teste), P1 (uso do `NFNUM`).

---

## Versão 0.6 – 06.11.2026

**Alterado por:** Alexandre Marcondes Silva
**Branch:** `ajustes/v0.6`

| # | Problema (open topic) | Causa | Alteração | Objeto |
|---|---|---|---|---|
| OT1 | **CFOP gravado como `593/3A`** (natureza da operação vazia), com o parâmetro `5933AA` e com `5933/AA` | `BAPI_J_1BNFLIN-CFOP` é o CFOP **antigo** (`J_1BCFOP_OLD`, CHAR 5): o valor era cortado em `5933A`. O CFOP atual (código + extensão, `J_1BCFOP` CHAR 10) é o campo `CFOP_10` | CFOP enviado em `CFOP_10`; `/` e `.` removidos do valor do parâmetro (aceita `5933AA`, `5933/AA` ou `5.933/AA`) | `ZSD_BR_NFSE_F01` (`BUILD_BAPI_ITEM`) |

Demais open topics (OT2–OT11) continuam abertos – lista na versão 0.5.

**Objetos SAP a atualizar:** `ZSD_BR_NFSE_F01` (copiar e ativar com `ZSD_BR_NFSE_UPLOAD` e `ZSD_BR_NFSE_UPLOAD_ADM`). Parâmetro `CFOP` pode ficar `5933AA` / `6933AA` ou com separadores.

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

### Pendências abertas (open topics) – resultado do teste de 06.11.2026 (NF 226758)

| # | Tema | Situação | Próximo passo |
|---|---|---|---|
| OT1 | **CFOP gravado como `593/3A`** (natureza da operação vazia) com `5933AA` e com `5933/AA` | Causa encontrada: o programa preenche `BAPI_J_1BNFLIN-CFOP` (`J_1BCFOP_OLD`, CHAR 5 – formato antigo), o valor é cortado em 5 posições | Corrigir na v0.6: preencher `CFOP_10` (`J_1BCFOP`, CHAR 10) |
| OT2 | Lei ISS `ISS` em vez de `I01` (situação tributária ISS vazia) | Parâmetro | SM30: `TAXLW3` (coluna "ISS Retido", Y e N) = `I01` |
| OT3 | Tipo de imposto do ISS: `ISSE` (grupo ISSS, sem domicílio fiscal) × `ISSA` (grupo ISSP, domicílio SP 3550308) na NF do SD | Fiscal | Confirmar `TAXTYP_ISS` com o consultor fiscal |
| OT4 | Código de recolhimento das retenções vazio (NF do SD: 5952 / 1708) | Fiscal | Confirmar se vem da configuração ou se precisa ser enviado (parâmetro por tipo de imposto) |
| OT5 | Descrição do material em inglês ("1XNK misc. extra costs") | Código | Ler `MAKT` em português (idioma da NF), idioma de logon como reserva |
| OT6 | Série vazia e RPS no número da NF (NF do SD: série 1, NFNUM 0) | Fiscal (P1, P1a) | Decidir série e uso do `NFNUM`; campos `SERIES`, `ZTERM`, `GJAHR` disponíveis na `BAPI_J_1BNFDOC` |
| OT7 | ID do texto de cabeçalho (`HDR_TEXT_ID`) | Funcional | Definir qual ID de texto a J1B3N mostra |
| OT8 | `infCpl` com a discriminação dos serviços | Desenho pronto (bloco 0a da BAdI `ZI_NFE_ADD_DATA`) | Implementar na BAdI (objeto fora deste repositório) |
| OT9 | **P25** – material determinado pelo código de serviço (parâmetro `MATNR`) | Teste | Confirmar |
| OT10 | Validate only não chama a BAPI: erros 8B só aparecem na execução real; na execução real parâmetros vazios não bloqueiam (023/025 só aviso) | Código | Avaliar `SIMULATION = 'X'` da BAPI no Validate only |
| OT11 | NFs de teste 226751–226753, 226756, 226758 | Teste | Estornar antes de enviar à Prefeitura (J1BNFE) |

---

## Versão 0.4 – 09.10.2026 a 12.10.2026

**Alterado por:** Renato Santos

- Desenho funcional/técnico v0.2 a v0.4 (popup de duplicidade, bloqueio, LUW única, expurgo LGPD, reprocessamento, arquivo de saída CSV no layout da PMSP com controle de exportação).
- Código ABAP inicial: `ZSD_BR_NFSE_UPLOAD`, `ZSD_BR_NFSE_UPLOAD_ADM` e includes.
- Gerador do DDIC `ZSD_BR_NFSE_DDIC_GEN` e carga inicial de parâmetros `ZSD_BR_NFSE_PARM_LOAD`.
- Correções de sintaxe e de tipos (AUTHORITY-CHECK, SELECT-OPTIONS, `RP_CALC_DATE_IN_INTERVAL`, campos `Z_INPUT`/`Z_OUTPUT`).
- Opção de colar a planilha pela área de transferência – mantida só no branch `feature/clipboard-paste`.
