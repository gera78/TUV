# ZSD_BR_NFSE – Upload Excel → Nota Fiscal Writer

**Documento de desenho funcional/técnico**

| Item | Valor |
|---|---|
| Projeto | TÜV – Criação de NF Writer a partir de planilha de NFS-e |
| Empresa / Local de negócio | 5596 / 0001 (padrão) |
| Ambiente | SAP S/4HANA (notas da Reforma Tributária em implantação) |
| Versão | 0.3 – Verificação de duplicidade com popup, bloqueio, LUW única, LGPD/expurgo, reprocessamento, avisos (W), data de emissão |
| Data | 09.10.2026 |
| Developer / IT Responsible / Business Responsible | `<TBD>` |
| Status | Em revisão do mockup → aprovação → codificação |

> Convenções deste documento: ✅ decidido · ⏳ pendente · 💡 sugestão (aguarda aprovação).
> Nomes técnicos, textos de tela e mensagens em inglês (guideline TÜV, itens 11 e 16).

---

## 1. Objetivo e escopo

Ler uma planilha Excel (.xlsx/.xlsm) do computador do usuário, gravar o conteúdo em tabelas Z de log, validar cada linha e, para as linhas válidas, criar uma Nota Fiscal Writer (equivalente à J1B1N) via `BAPI_J_1B_NF_CREATEFROMDATA`. O resultado e o histórico são exibidos em ALV.

**Fora de escopo**
- Documento contábil/financeiro: **não é criado** (✅). Todos os impostos vão apenas como linhas de imposto do item da NF.
- Geração do TXT para a prefeitura (aba "gerar txt") – evolução futura.
- NFS-e Padrão Nacional / transmissão via SAP DRC – evolução futura; o desenho não a impede.
- Execução em background (o upload é via SAP GUI).
- Agrupar várias linhas numa única NF: regra é **1 linha = 1 NF** (⏳ confirmar com fiscal, P12).

---

## 2. Fluxo geral

```
 Tela de seleção (Opção 1)
        │
        ▼
 [1] Authority check (BUKRS / J1B1N) + local de negócio pertence à empresa (031) + NF type de saída sem contabilização (032)
        │
        ▼
 [2] Upload binário (GUI_UPLOAD) → CL_FDT_XL_SPREADSHEET → aba SHEET_NAME
        │
        ▼
 [3] Validação de layout (001) e limite de linhas MAX_LINES (033) ── erro ──► FILE status E + LOG (linha 0) ──► ALV
        │ ok
        ▼
 [4] FILE_ID (range ZNFSE_FILE) → grava ZSD_BR_NFSE_FILE + ZSD_BR_NFSE_DATA (status ' ') → COMMIT
        │
        ▼
 [5] Validações por linha (E bloqueia · W só avisa) → LOG; linha com erro → status E
        │
        ▼
 [6] Verificação de duplicidade (seção 10): critério A (RPS) e B (conteúdo)
        │   encontrou? → POPUP com a lista
        │        ├─ "Continue without duplicates" → duplicadas: status E (017/026); demais seguem
        │        └─ "Cancel processing"          → todas as linhas E + LOG 027; arquivo E; nenhuma NF
        │   (Validate only: popup apenas informativo)
        ▼
 [7] Bloqueio EZSD_BR_NFSE (BUKRS + BRANCH) ── ocupado ──► msg 030, nada é criado
        │
        ▼
 [8] Para cada linha OK (com indicador de progresso):
        BAPI_J_1B_NF_CREATEFROMDATA
          ├─ sucesso → UPDATE DATA (DOCNUM, S) + LOG 022 → BAPI_TRANSACTION_COMMIT (WAIT)  ← mesma LUW
          └─ erro    → BAPI_TRANSACTION_ROLLBACK → DATA E + LOG (mensagens E/A da BAPI) → COMMIT WORK
        │
        ▼
 [9] Desbloqueio · status do arquivo: todas S → S · todas E → E · senão → P (+ contadores)
        │
        ▼
 [10] ALV de resultado (semáforo + hotspot DOCNUM → J1B3N)
```

- As validações de uma linha **não param no primeiro erro**: todos os erros e avisos da linha são gravados.
- Cada NF é confirmada individualmente – um erro numa linha não desfaz as anteriores.
- **LUW única** ✅: o status S e o DOCNUM são gravados **antes** do `BAPI_TRANSACTION_COMMIT`, de modo que NF e log são confirmados juntos (nunca existe NF sem registro – evita reemissão).
- **Validate only (`P_TEST`)**: executa os passos 1–6 e grava o log; linhas válidas ficam com status V; não há bloqueio nem BAPI.

---

## 3. Objetos de desenvolvimento

### 3.1 Programas e includes

| Objeto | Tipo | Usado por | Conteúdo |
|---|---|---|---|
| `ZSD_BR_NFSE_UPLOAD` | Report | Usuário | Opções 1 e 2 |
| `ZSD_BR_NFSE_UPLOAD_ADM` | Report | Admin | Opções 1, 2, 3 (parâmetros) e 4 (expurgo de logs) |
| `ZSD_BR_NFSE_TOP` | Include | Ambos | Tipos, dados globais, constantes, classes ALV de evento |
| `ZSD_BR_NFSE_SCR_COM` | Include | Ambos | Blocos de parâmetros das opções 1 e 2 |
| `ZSD_BR_NFSE_SCR` | Include | Usuário | Radio buttons (1, 2) + eventos de tela |
| `ZSD_BR_NFSE_SCR_ADM` | Include | Admin | Radio buttons (1, 2, 3) + eventos de tela |
| `ZSD_BR_NFSE_F01` | Include | Ambos | Autorização, upload, gravação, validações, BAPI, status |
| `ZSD_BR_NFSE_ALV` | Include | Ambos | ALV de processamento e de log, semáforo, hotspot, popup de mensagens |
| `ZSD_BR_NFSE_F02_ADM` | Include | Admin | Manutenção de parâmetros, expurgo de logs, reprocessamento de erros |

> O radio group precisa ser declarado de uma só vez, por isso há um include SCR por programa; os blocos de parâmetros ficam no `SCR_COM`.
> Estilo: FORMs (consistente com o projeto ICMS), ALV com `CL_SALV_TABLE`.

### 3.2 Dicionário e configuração

| Objeto | Transação | Nome |
|---|---|---|
| Tabelas | SE11 | `ZSD_BR_NFSE_FILE`, `ZSD_BR_NFSE_DATA`, `ZSD_BR_NFSE_LOG`, `ZSD_BR_NFSE_PARM` |
| Domínios / elementos de dados | SE11 | ver seção 6 |
| Classe de mensagem | SE91 | `ZSD_BR_NFSE_MSG` |
| Range de numeração | SNRO | `ZNFSE_FILE` (intervalo 01, 10 dígitos) |
| Objeto de bloqueio | SE11 | `EZSD_BR_NFSE` (tabela `ZSD_BR_NFSE_FILE`, argumentos BUKRS + BRANCH; campos adicionados à tabela de bloqueio via estrutura) |
| Visão de manutenção (TMG) | SE54 | `ZSD_BR_NFSE_PARM` (grupo de funções `ZSD_BR_NFSE_PARM`) |
| Transações | SE93 | `ZNFSE` (usuário), `ZNFSE_ADM` (admin) |

---

## 4. Telas de seleção

### 4.1 Programa do usuário (`ZNFSE`)

**Bloco "Processing option"** (radio buttons, com `USER-COMMAND` para alternar os blocos)

| Radio | Texto |
|---|---|
| `P_RUPL` | Process upload and create NF Writer (padrão) |
| `P_RLOG` | Display execution log |

**Bloco "Upload parameters"** – visível só com `P_RUPL`

| Parâmetro | Tipo | Padrão | Obrigatório | Obs. |
|---|---|---|---|---|
| `P_BUKRS` | `BUKRS` | 5596 | Sim | Authority check |
| `P_BRANCH` | `J_1BBRANC_` | 0001 | Sim | Validado contra `J_1BBRANCH` |
| `P_NFTYPE` | `J_1BNFTYPE` | Z1 | Sim | Validado contra `J_1BAA`: saída, sem contabilização (032) |
| `P_DOCDAT` | `J_1BDOCDAT` | SY-DATUM | Sim | Data de emissão. **Somente leitura no programa do usuário; editável no admin** (fechamento de mês) ⏳ validar com fiscal (P13) |
| `P_FILE` | `STRING`/`RLGRAP-FILENAME` | – | Sim | F4: `CL_GUI_FRONTEND_SERVICES=>FILE_OPEN_DIALOG` (filtro *.xlsx;*.xlsm) |
| `P_TEST` | Checkbox | vazio | Não | "Validate only (no NF creation)" ✅ – valida e grava log, sem chamar a BAPI |

`P_BRANCH` precisa pertencer a `P_BUKRS` (`J_1BBRANCH`, msg 031).

**Bloco "Log selection"** – visível só com `P_RLOG`

| Campo | Referência | Obs. |
|---|---|---|
| `S_BUKRS` | `ZSD_BR_NFSE_FILE-BUKRS` | Padrão 5596 |
| `S_BRANCH` | `ZSD_BR_NFSE_FILE-BRANCH` | |
| `S_FILEID` | `ZSD_BR_NFSE_FILE-FILE_ID` | |
| `S_EXDATE` | `ZSD_BR_NFSE_FILE-EXEC_DATE` | Padrão: últimos 30 dias |
| `S_EXUSER` | `ZSD_BR_NFSE_FILE-EXEC_USER` | |
| `S_FSTAT` | `ZSD_BR_NFSE_FILE-STATUS` | S / P / E |
| `S_LSTAT` | `ZSD_BR_NFSE_DATA-STATUS` | S / E |
| `S_KUNNR` | `ZSD_BR_NFSE_DATA-KUNNR` | |
| `S_RPS` | `ZSD_BR_NFSE_DATA-RPS_NUMBER` | |
| `S_DOCNUM` | `ZSD_BR_NFSE_DATA-DOCNUM` | |
| `S_MSGNO` | `ZSD_BR_NFSE_LOG-MSGNO` | Filtra linhas que tenham a mensagem |
| `P_ERRONLY` | Checkbox | "Lines with errors only" |

### 4.2 Programa do admin (`ZNFSE_ADM`)

Mesmos blocos do usuário (com `P_DOCDAT` editável) + dois radios exclusivos do admin:

| Radio | Texto | Tela |
|---|---|---|
| `P_RPARM` | Maintain parameters | Sem campos; executa a manutenção da `ZSD_BR_NFSE_PARM` (seção 13.1) |
| `P_RPURG` | Purge old logs | Bloco "Purge" (abaixo) |

**Bloco "Purge"** – visível só com `P_RPURG`

| Parâmetro | Tipo | Padrão | Obs. |
|---|---|---|---|
| `P_PBUKRS` | `BUKRS` | 5596 | Obrigatório |
| `P_PDATE` | `DATUM` | hoje − `LOG_RETENTION_YEARS` | Apaga arquivos com `EXEC_DATE` anterior a esta data |
| `P_PTEST` | Checkbox | X | Simulação: só conta o que seria apagado |

---

## 5. Autorização

| Momento | Verificação | Ação se falhar |
|---|---|---|
| Opção 1 – antes do upload | `F_BKPF_BUK` – `BUKRS = P_BUKRS`, `ACTVT = 01` | Mensagem 021, processamento interrompido |
| Opção 1 – antes do upload | `S_TCODE` – `TCD = J1B1N` | Mensagem 021 |
| Opção 2 – ao exibir | `F_BKPF_BUK` – `ACTVT = 03` por BUKRS selecionado | Linhas de empresas sem autorização são removidas (mensagem informativa) |
| Hotspot DOCNUM | `CALL TRANSACTION 'J1B3N' WITH AUTHORITY-CHECK` | Padrão SAP |
| Opção 3 | Transação `ZNFSE_ADM` + `S_TABU_DIS` (grupo de autorização da tabela) | Padrão SAP |
| Opção 4 / "Reprocess errors" | Transação `ZNFSE_ADM` + `F_BKPF_BUK` (ACTVT 06 expurgo / 01 reprocessamento) | Mensagem 021 |

⏳ Confirmar na **SU24 da J1B1N** se existe objeto específico de NF (com BUKRS/ACTVT) que deva substituir ou complementar `F_BKPF_BUK`. ACTVT 01 = Create (TACT) ✅.

---

## 6. Modelo de dados

### 6.1 Domínios

| Domínio | Tipo | Valores fixos |
|---|---|---|
| `ZSD_BR_NFSE_FILE_STATUS` | CHAR 1 | S = Success · P = Partially processed · E = Error |
| `ZSD_BR_NFSE_LINE_STATUS` | CHAR 1 | ' ' = Not processed · S = Success · E = Error · V = Validated (test run, sem NF) |
| `ZSD_BR_NFSE_YES_NO` | CHAR 1 | S = Yes (Sim) · N = No (Não) – valores como vêm da planilha |
| `ZSD_BR_NFSE_AMOUNT` | CURR 15,2 | – |
| `ZSD_BR_NFSE_RATE` | DEC 7,4 | – (fração, ex. 0,0500) |

### 6.2 `ZSD_BR_NFSE_FILE` – cabeçalho de execução (1 registro por arquivo)

| Campo | Chave | Elemento de dados | Tipo | Descrição |
|---|---|---|---|---|
| MANDT | ✔ | `MANDT` | CLNT 3 | Client |
| FILE_ID | ✔ | `ZSD_BR_NFSE_FILE_ID` | NUMC 10 | File ID (range `ZNFSE_FILE`) |
| FILE_NAME | | `ZSD_BR_NFSE_FILE_NAME` | CHAR 255 | File name |
| FILE_PATH | | `ZSD_BR_NFSE_FILE_PATH` | CHAR 255 | File path |
| BUKRS | | `BUKRS` | CHAR 4 | Company code |
| BRANCH | | `J_1BBRANC_` | CHAR 4 | Business place |
| NFTYPE | | `J_1BNFTYPE` | CHAR 2 | NF type |
| EXEC_USER | | `UNAME` | CHAR 12 | Executed by |
| EXEC_DATE | | `DATUM` | DATS | Execution date |
| EXEC_TIME | | `UZEIT` | TIMS | Execution time |
| LINE_COUNT | | `ZSD_BR_NFSE_LINE_COUNT` | INT4 | Number of lines |
| SUCCESS_COUNT | | `ZSD_BR_NFSE_SUCCESS_COUNT` | INT4 | Lines with success |
| ERROR_COUNT | | `ZSD_BR_NFSE_ERROR_COUNT` | INT4 | Lines with error |
| STATUS | | `ZSD_BR_NFSE_FILE_STATUS` | CHAR 1 | File status |
| TEST_RUN | | `ZSD_BR_NFSE_TEST_RUN` | CHAR 1 | Validation only (`P_TEST`) ✅ |
| DOC_DATE | | `J_1BDOCDAT` | DATS | Data de emissão usada (`P_DOCDAT`) |
| CANCEL_FLAG | | `ZSD_BR_NFSE_USER_CANCEL` | CHAR 1 | Processamento cancelado pelo usuário no popup de duplicidade |
| 💡 FILE_CONTENT | | `XSTRING` (RAWSTRING) | – | **Opcional (sugestão 11)**: binário do arquivo original para auditoria |

### 6.3 `ZSD_BR_NFSE_DATA` – linhas da planilha (1 registro por linha)

**Controle**

| Campo | Chave | Elemento de dados | Tipo | Descrição |
|---|---|---|---|---|
| MANDT | ✔ | `MANDT` | CLNT 3 | Client |
| FILE_ID | ✔ | `ZSD_BR_NFSE_FILE_ID` | NUMC 10 | File ID |
| LINE_ID | ✔ | `ZSD_BR_NFSE_LINE_ID` | NUMC 6 | Excel row number |
| STATUS | | `ZSD_BR_NFSE_LINE_STATUS` | CHAR 1 | Line status |
| DOCNUM | | `J_1BDOCNUM` | NUMC 10 | NF document number |
| WAERS | | `WAERS` | CUKY 5 | Currency (BRL) – referência dos campos CURR |

**Dados da planilha (aba "Emissão NF - Ductor")** – coluna A ("ULTIMA RPS UTILIZADA") não é gravada.

| Col. | Cabeçalho Excel | Campo | Elemento de dados | Tipo |
|---|---|---|---|---|
| B | Codigo SAP | KUNNR | `KUNNR` | CHAR 10 (ALPHA) |
| C | CR | CR_CODE | `ZSD_BR_NFSE_CR_CODE` | CHAR 10 ⏳ |
| D | Cliente | CUSTOMER_SHORT_NAME | `ZSD_BR_NFSE_CUST_SHORT_NAME` | CHAR 40 |
| E | Cidade | CITY | `ZSD_BR_NFSE_CITY` | CHAR 40 |
| F | RPS | RPS_NUMBER | `ZSD_BR_NFSE_RPS_NUMBER` | CHAR 15 |
| G | Pedido de Compra | PO_NUMBER | `BSTKD` | CHAR 35 |
| H | Data de prestação de serviço | SERVICE_DATE | `ZSD_BR_NFSE_SERVICE_DATE` | DATS |
| I | Valor dos Serviços | SERVICE_AMOUNT | `ZSD_BR_NFSE_SERVICE_AMOUNT` | CURR 15,2 |
| J | CBS Devido | CBS_DUE_AMT | `ZSD_BR_NFSE_CBS_DUE_AMT` | CURR 15,2 |
| K | IBS Devido | IBS_DUE_AMT | `ZSD_BR_NFSE_IBS_DUE_AMT` | CURR 15,2 |
| L | INSS | INSS_AMT | `ZSD_BR_NFSE_INSS_AMT` | CURR 15,2 |
| M | IRRF RETIDO | IRRF_WHT_AMT | `ZSD_BR_NFSE_IRRF_WHT_AMT` | CURR 15,2 |
| N | CSLL RETIDO | CSLL_WHT_AMT | `ZSD_BR_NFSE_CSLL_WHT_AMT` | CURR 15,2 |
| O | CBS RETIDO | CBS_WHT_AMT | `ZSD_BR_NFSE_CBS_WHT_AMT` | CURR 15,2 |
| P | IBS RETIDO | IBS_WHT_AMT | `ZSD_BR_NFSE_IBS_WHT_AMT` | CURR 15,2 |
| Q | ISS RETIDO/DEVIDO | ISS_AMT | `ZSD_BR_NFSE_ISS_AMT` | CURR 15,2 |
| R | Alíquota | ISS_RATE | `ZSD_BR_NFSE_ISS_RATE` | DEC 7,4 |
| S | ISS Retido | ISS_WHT_FLAG | `ZSD_BR_NFSE_ISS_WHT_FLAG` | CHAR 1 (S/N) |
| T | Prestação de Serviço fora de São Paulo | OUTSIDE_SP_FLAG | `ZSD_BR_NFSE_OUTSIDE_SP_FLAG` | CHAR 1 (S/N) |
| U | Código do Serviço Prestado na Nota Fiscal | SERVICE_CODE | `ZSD_BR_NFSE_SERVICE_CODE` | CHAR 10 |
| V | Município da Prestação do Serviço | SERVICE_CITY_CODE | `ZSD_BR_NFSE_SERV_CITY_CODE` | NUMC 7 (IBGE) |
| W | UF | SERVICE_REGION | `ZSD_BR_NFSE_SERVICE_REGION` | CHAR 3 |
| X | CPF/CNPJ do Tomador | TAKER_TAX_ID | `ZSD_BR_NFSE_TAKER_TAX_ID` | CHAR 18 |
| Y | Inscrição Municipal do Tomador | TAKER_MUN_REG | `ZSD_BR_NFSE_TAKER_MUN_REG` | CHAR 20 |
| Z | Razão Social do Tomador | TAKER_NAME | `ZSD_BR_NFSE_TAKER_NAME` | CHAR 120 |
| AA | Tipo do Endereço do Tomador | TAKER_STREET_TYPE | `ZSD_BR_NFSE_TAKER_STR_TYPE` | CHAR 10 |
| AB | Endereço do Tomador | TAKER_STREET | `ZSD_BR_NFSE_TAKER_STREET` | CHAR 60 |
| AC | Número do Endereço do Tomador | TAKER_HOUSE_NUM | `ZSD_BR_NFSE_TAKER_HOUSE_NUM` | CHAR 10 (aceita "S/N") |
| AD | Bairro do Tomador | TAKER_DISTRICT | `ZSD_BR_NFSE_TAKER_DISTRICT` | CHAR 40 |
| AE | Cidade do Tomador | TAKER_CITY | `ZSD_BR_NFSE_TAKER_CITY` | CHAR 40 |
| AF | UF do Tomador | TAKER_REGION | `ZSD_BR_NFSE_TAKER_REGION` | CHAR 3 |
| AG | CEP do Tomador | TAKER_POSTAL_CODE | `ZSD_BR_NFSE_TAKER_POST_CODE` | CHAR 10 |
| AH | Discriminação dos Serviços | SERVICE_DESCRIPTION | `ZSD_BR_NFSE_SERVICE_DESCR` | STRING (até 2000) |
| AI | CPF/CNPJ/NIF/S NIF | RCP_TAX_ID | `ZSD_BR_NFSE_RCP_TAX_ID` | CHAR 40 |
| AJ | Nome | RCP_NAME | `ZSD_BR_NFSE_RCP_NAME` | CHAR 120 |
| AK | Email | RCP_EMAIL | `AD_SMTPADR` | CHAR 241 |
| AL | Endereço | RCP_ADDRESS | `ZSD_BR_NFSE_RCP_ADDRESS` | CHAR 100 |
| AM | Nacional/Exterior | RCP_NAT_FOREIGN | `ZSD_BR_NFSE_RCP_NAT_FOREIGN` | CHAR 1 |
| AN | Logradouro | RCP_STREET | `ZSD_BR_NFSE_RCP_STREET` | CHAR 60 |
| AO | Número | RCP_HOUSE_NUM | `ZSD_BR_NFSE_RCP_HOUSE_NUM` | CHAR 10 |
| AP | Complemento | RCP_ADDR_COMPL | `ZSD_BR_NFSE_RCP_ADDR_COMPL` | CHAR 60 |
| AQ | Bairro | RCP_DISTRICT | `ZSD_BR_NFSE_RCP_DISTRICT` | CHAR 40 |
| AR | CIB/CNO | SITE_CIB_CNO | `ZSD_BR_NFSE_SITE_CIB_CNO` | CHAR 20 |
| AS | Nacional | SITE_NATIONAL | `ZSD_BR_NFSE_SITE_NATIONAL` | CHAR 1 ⏳ significado |
| AT | CEP | SITE_POSTAL_CODE | `ZSD_BR_NFSE_SITE_POST_CODE` | CHAR 10 |
| AU | Logradouro | SITE_STREET | `ZSD_BR_NFSE_SITE_STREET` | CHAR 60 |
| AV | Número | SITE_HOUSE_NUM | `ZSD_BR_NFSE_SITE_HOUSE_NUM` | CHAR 10 |
| AW | Complemento | SITE_ADDR_COMPL | `ZSD_BR_NFSE_SITE_ADDR_COMPL` | CHAR 60 |
| AX | Bairro | SITE_DISTRICT | `ZSD_BR_NFSE_SITE_DISTRICT` | CHAR 40 |
| AY | Código de Classificação Tributária Principal | TAX_CLASS_MAIN | `ZSD_BR_NFSE_TAX_CLASS_MAIN` | CHAR 6 (cClassTrib) |
| AZ | Código do Indicador de Operação | OPER_IND_CODE | `ZSD_BR_NFSE_OPER_IND_CODE` | CHAR 6 (cIndOp) |
| BA | Código NBS | NBS_CODE | `ZSD_BR_NFSE_NBS_CODE` | CHAR 9 |
| BB | Código de Classificação Tributária Regular | TAX_CLASS_REG | `ZSD_BR_NFSE_TAX_CLASS_REG` | CHAR 6 |

Prefixos: `TAKER_` = Tomador · `RCP_` = Destinatário · `SITE_` = Imóvel/Obra · `TAX_` = Tributário.

### 6.4 `ZSD_BR_NFSE_LOG` – mensagens (n registros por linha)

| Campo | Chave | Elemento de dados | Tipo | Descrição |
|---|---|---|---|---|
| MANDT | ✔ | `MANDT` | CLNT 3 | Client |
| FILE_ID | ✔ | `ZSD_BR_NFSE_FILE_ID` | NUMC 10 | File ID |
| LINE_ID | ✔ | `ZSD_BR_NFSE_LINE_ID` | NUMC 6 | Excel row (000000 = mensagem do arquivo) |
| LOG_ITEM | ✔ | `ZSD_BR_NFSE_LOG_ITEM` | NUMC 4 | Log item |
| MSGTY | | `SYMSGTY` | CHAR 1 | Message type (E/W/S) |
| MSGID | | `SYMSGID` | CHAR 20 | Message class |
| MSGNO | | `SYMSGNO` | NUMC 3 | Message number |
| MSGV1–MSGV4 | | `SYMSGV` | CHAR 50 | Message variables |
| MESSAGE | | `BAPI_MSG` | CHAR 220 | Message text (description) |
| LOG_DATE | | `DATUM` | DATS | Log date |
| LOG_TIME | | `UZEIT` | TIMS | Log time |

### 6.5 `ZSD_BR_NFSE_PARM` – parâmetros

| Campo | Chave | Elemento de dados | Tipo | Descrição |
|---|---|---|---|---|
| MANDT | ✔ | `MANDT` | CLNT 3 | Client |
| BUKRS | ✔ | `BUKRS` | CHAR 4 | Company code |
| FIELD_NAME | ✔ | `ZSD_BR_NFSE_FIELD_NAME` | CHAR 30 | Target field / parameter name |
| FILE_COLUMN_NAME | ✔ | `ZSD_BR_NFSE_FILE_COLUMN_NAME` | CHAR 60 | Excel column header (vazio = parâmetro fixo) |
| INPUT | ✔ | `ZSD_BR_NFSE_INPUT_VALUE` | CHAR 60 | Value read from file (`*` = default) |
| OUTPUT | | `ZSD_BR_NFSE_OUTPUT_VALUE` | CHAR 255 | Value used in SAP |

Configurações técnicas: classe de entrega **C** (customizing), **log de alterações ativo**, grupo de autorização para `S_TABU_DIS`.

---

## 7. Leitura do arquivo

| Regra | Definição |
|---|---|
| Método | `GUI_UPLOAD` (binário) → XSTRING → `CL_FDT_XL_SPREADSHEET` |
| Aba | Parâmetro `SHEET_NAME` (padrão "Emissão NF - Ductor"); aba inexistente → msg 018 |
| Linha 1 | Grupos (Destinatário / Imóvel-Obra / Tributário) – ignorada |
| Linha 2 | Cabeçalho – validação de layout (msg 001): posição + texto de A até BB, **comparado sem espaços nas pontas, sem diferenciar maiúsculas/minúsculas e sem acentos** (ex.: "Nacional " = "NACIONAL") ✅ |
| Limite | No máximo `MAX_LINES` linhas de dados (msg 033) |
| Linha 3+ | Dados; linha considerada somente se **coluna B (Codigo SAP)** preenchida |
| Coluna A | Ignorada (não gravada) |

**Conversões**

| Dado | Regra |
|---|---|
| Valores (I–Q) | Numérico → arredondado a 2 casas na carga (ex. 3,0544200000000004 → 3,05) |
| Alíquota (R) | Guardada como fração (0,05); ×100 ao enviar à BAPI |
| Data (H) | Número serial do Excel → DATS; texto dd/mm/aaaa também aceito; inválida → msg 024 |
| Código SAP (B) | `CONVERSION_EXIT_ALPHA_INPUT` |
| Código de serviço (U) | Sem zeros à esquerda (1805 = "01805") antes da busca em parâmetros |
| Município (V) | Número ou texto → 7 dígitos |
| CPF/CNPJ (X) | Gravado como veio; comparação feita só com dígitos |
| Número endereço (AC/AO/AV) | Texto (aceita "S/N") |
| Discriminação (AH) | Texto integral (STRING) |
| Textos | `CONDENSE`; maiúsculas não são forçadas |

---

## 8. Tabela de parâmetros – regras e conteúdo inicial

**Busca**: `BUKRS` + `FIELD_NAME` + `FILE_COLUMN_NAME` + `INPUT` exato → se não encontrar, mesma chave com `INPUT = '*'` → se não encontrar: erro 023/025 (ou uso do próprio valor, quando o parâmetro é opcional).

### 8.1 Mapeamentos (dependem de valor da planilha)

| FIELD_NAME | FILE_COLUMN_NAME | INPUT | OUTPUT (exemplo) | Obrig. | Uso |
|---|---|---|---|---|---|
| MATNR | Código do Serviço Prestado na Nota Fiscal | 1805 | 56984-258656-22 | Sim | Material do item (msg 005) |
| KUNNR | Codigo SAP | (valor) | (cliente) | Não | Sem entrada → usa o próprio Código SAP ✅ |
| CFOP | UF do Tomador | SP | 5933AA | Sim | CFOP dentro do estado |
| CFOP | UF do Tomador | * | 6933AA | Sim | CFOP fora do estado |
| TAXTYP_ISS | ISS Retido | S | (tipo ISS retido) | Sim | Tipo de imposto ISS |
| TAXTYP_ISS | ISS Retido | N | (tipo ISS devido) | Sim | |
| TAXLW3 | ISS Retido | S / N | (lei ISS) | Sim | Lei fiscal ISS |
| CCLASSTRIB | Código do Serviço Prestado na Nota Fiscal | 1805 | (cClassTrib) | Não | Padrão se coluna AY vazia |

### 8.2 Parâmetros fixos (`FILE_COLUMN_NAME` vazio, `INPUT = '*'`)

| FIELD_NAME | OUTPUT (exemplo) | Obrig. | Uso |
|---|---|---|---|
| SHEET_NAME | Emissão NF - Ductor | Sim | Aba lida |
| TAXTYP_CBS | (tipo CBS – notas reforma) | Se coluna J > 0 | Grupo 01 |
| TAXTYP_IBS | (tipo IBS – notas reforma) | Se coluna K > 0 | Grupo 01 |
| TAXTYP_INSS | (tipo INSS retido) | Se coluna L > 0 | Grupo 02 |
| TAXTYP_IRRF | (tipo IRRF retido) | Se coluna M > 0 | Grupo 03 |
| TAXTYP_CSLL | (tipo CSLL retido) | Se coluna N > 0 | Grupo 03 |
| TAXTYP_CBS_WHT | (tipo CBS retido) | Se coluna O > 0 | Grupo 03 |
| TAXTYP_IBS_WHT | (tipo IBS retido) | Se coluna P > 0 | Grupo 03 |
| TAXLW1 / TAXLW2 | (lei ICMS / IPI não tributado) | Sim | Item da NF |
| TAXLW4 / TAXLW5 | (lei COFINS / PIS) | Sim | ⏳ confirmar com fiscal |
| ITMTYP | (tipo de item) | Sim | Item da NF |
| MATUSE | (utilização do material) | Sim | Item da NF |
| MATORG | 0 | Sim | Origem do material |
| WERKS | (centro) | Não | Vazio → derivado do local de negócio (`J_1BT001WV`) |
| TAXGRP_REQ_01 | X | Não | Grupo 01 obrigatório (msg 014) |
| TAXGRP_REQ_02 | (vazio) | Não | Grupo 02 opcional |
| TAXGRP_REQ_03 | (vazio) | Não | Grupo 03 opcional |
| ISS_TOLERANCE | 0.01 | Não | Tolerância da msg 013 (padrão 0,01) |
| RPS_TARGET | TEXT | Não | Destino do RPS ⏳ (TEXT = última linha do texto) |
| MAX_LINES | 500 | Não | Limite de linhas por arquivo (msg 033) |
| LOG_RETENTION_YEARS | 5 | Não | Prazo de retenção do log (LGPD) – padrão do expurgo ⏳ validar com DPO (P14) |

> Valores entre parênteses: a definir pelo consultor fiscal / configuração das notas da reforma.

---

## 9. Validações

**Nível arquivo** (interrompem o processamento; LOG com `LINE_ID = 000000`; FILE status E)

| Msg | Regra |
|---|---|
| 031 | Local de negócio não pertence à empresa (tela – antes do upload) |
| 032 | NF type não é de saída ou gera contabilização (tela – antes do upload) |
| 018 | Arquivo não pôde ser lido ou aba `SHEET_NAME` não existe |
| 001 | Cabeçalho da linha 2 difere do padrão (posição/texto); informa a 1ª coluna divergente |
| 033 | Arquivo excede `MAX_LINES` linhas |
| 030 | Processamento bloqueado por outro usuário (BUKRS + BRANCH) – nenhuma NF criada; linhas permanecem com status ' ' para reprocessamento |

**Nível linha** (todas executadas; cada falha grava LOG e linha → status E)

| Msg | Regra | Colunas |
|---|---|---|
| 002 | Cliente não existe (`KNA1`) | B |
| 019 ✅ | Cliente não ampliado para a empresa (`KNB1`) | B |
| 020 ✅ | Cliente bloqueado (bloqueio central/empresa ou marcado para eliminação) | B |
| 003 | CPF/CNPJ (só dígitos) ≠ `KNA1-STCD1` (CNPJ, 14 díg.) / `STCD2` (CPF, 11 díg.) | B, X |
| 004 | Código de serviço vazio ou zero | U |
| 005 | Sem parâmetro MATNR para o código, ou material inexistente / não ampliado para o centro | U |
| 006 | Valor dos serviços ≤ 0 | I |
| 007 | INSS + IRRF + CSLL + CBS ret. + IBS ret. + (ISS **se** ISS Retido = S) > valor dos serviços | I, L–Q, S |
| 024 ✅ | Data de prestação vazia ou inválida | H |
| 008 | Data de prestação > data de emissão (`P_DOCDAT`) | H |
| 009 | Discriminação dos serviços vazia | AH |
| 010 | CBS retido > CBS devido | J, O |
| 011 | IBS retido > IBS devido | K, P |
| 012 | Indicador ISS Retido diferente de S ou N ✅ | S |
| 013 | \|arred(valor × alíquota; 2) − ISS\| > `ISS_TOLERANCE` | I, Q, R |
| 014 | Grupo marcado como obrigatório (`TAXGRP_REQ_nn`) sem nenhum valor > 0 (grupo 01: J/K · 02: L · 03: M–Q) ✅ | J–Q |
| 015 | Prestação fora de SP = S e município vazio | T, V |
| 016 | Município preenchido e 2 primeiros dígitos IBGE ≠ UF (tabela de 27 UFs) ou código ≠ 7 dígitos | V, W |
| 017 ✅ | Duplicidade critério A – ver seção 10 | F |
| 026 ✅ | Duplicidade critério B – ver seção 10 | B, H, I, U |
| 023 ✅ | Coluna de imposto com valor > 0 sem `TAXTYP_*` configurado | J–Q, S |
| 025 ✅ | Parâmetro obrigatório não configurado (CFOP, TAXLW*, ITMTYP, MATUSE…) | – |

**Avisos (tipo W – não bloqueiam; semáforo amarelo)** ✅

| Msg | Regra | Colunas |
|---|---|---|
| 028 | Endereço/cidade/UF do tomador na planilha difere do cadastro do cliente (a NF usa o cadastro) | AB, AE, AF |
| 029 | Município de prestação preenchido, mas "Prestação fora de SP" = N | T, V |

---

## 10. Verificação de duplicidade (antes da criação) ✅

Executada após as validações de linha, **somente para as linhas sem erro**, e antes do bloqueio/BAPI.

| Critério | Regra | Mensagem |
|---|---|---|
| A – RPS | Mesmo **BUKRS + BRANCH + RPS** já com status S em `ZSD_BR_NFSE_DATA` (qualquer arquivo) **ou** repetido em outra linha válida do mesmo arquivo | 017 |
| B – Conteúdo | Mesmo **BUKRS + BRANCH + cliente + data de prestação + valor dos serviços + código de serviço** já com status S, mesmo com RPS diferente, **ou** repetido no mesmo arquivo | 026 |

- **Exceção – NF cancelada**: se a NF anterior estiver cancelada (`J_1BNFDOC-CANCEL = X`), não é duplicidade (permite reemissão).
- No mesmo arquivo, a 1ª ocorrência segue; as seguintes são duplicadas.
- Alcance: só NFs criadas por esta solução (tabelas Z). NFs digitadas manualmente na J1B1N não são verificadas.

**Popup (um único, com todas as duplicidades)**

Colunas: Linha · Cliente · RPS · Valor · Critério (A/B) · Arquivo/linha anterior · NF anterior (hotspot J1B3N) · Data de emissão anterior.

| Modo | Botões | Efeito |
|---|---|---|
| Normal | **Continue without duplicates** | Duplicadas → status E + 017/026; demais seguem para a criação |
| Normal | **Cancel processing** | Nenhuma NF criada; todas as linhas → E + 027; arquivo → E, `CANCEL_FLAG = X` |
| Validate only | **OK** (informativo) | Duplicadas → E + 017/026 |

Não existe opção "criar mesmo assim" ✅.

---

## 11. Criação da NF – `BAPI_J_1B_NF_CREATEFROMDATA`

Uma NF por linha válida, 1 item, sob o bloqueio `EZSD_BR_NFSE`. Após a chamada: sem mensagem E/A em `RETURN` e `DOC_NUMBER` preenchido → UPDATE `ZSD_BR_NFSE_DATA` (S, DOCNUM) + INSERT LOG 022 → `BAPI_TRANSACTION_COMMIT` (WAIT = X), tudo na mesma LUW; caso contrário → `BAPI_TRANSACTION_ROLLBACK`, depois DATA E + mensagens E/A no LOG e `COMMIT WORK`.

### 11.1 `OBJ_HEADER`

| Campo | Origem |
|---|---|
| BUKRS / BRANCH / NFTYPE | Tela |
| DOCTYP / MODEL / SERIES | `J_1BAA` pelo NF type |
| DIRECT | '2' (saída) |
| DOCDAT / PSTDAT | `P_DOCDAT` (padrão SY-DATUM) ✅ |
| MANUAL | 'X' |
| WAERK | 'BRL' |
| PARVW / PARID / PARTYP | 'AG' / KUNNR / 'C' ✅ |
| NFNUM / NFENUM | ⏳ RPS? (hoje: não preenchido, numeração conforme NF type) |

### 11.2 `OBJ_PARTNER`

| PARVW | PARID | PARTYP |
|---|---|---|
| AG | KUNNR | C |

Endereço e CNPJ vêm do cadastro SAP; os dados de tomador da planilha são usados só para validação e log.

### 11.3 `OBJ_ITEM` (ITMNUM 000010)

| Campo | Origem |
|---|---|
| MATNR | Parâmetro MATNR (código de serviço) |
| MAKTX | `MAKT` (idioma de logon) |
| MEINS | `MARA-MEINS` |
| MENGE | 1 |
| NETPR / NETWR | SERVICE_AMOUNT |
| WERKS | Parâmetro WERKS ou derivado do local de negócio |
| CFOP | Parâmetro CFOP (por UF do tomador) |
| ITMTYP / MATUSE / MATORG | Parâmetros |
| TAXLW1 / TAXLW2 / TAXLW4 / TAXLW5 | Parâmetros |
| TAXLW3 | Parâmetro TAXLW3 (por ISS Retido) |
| XPED | PO_NUMBER |
| Campos da reforma (cClassTrib, cIndOp, NBS…) | Colunas AY–BB (cClassTrib: padrão por parâmetro se vazio). **Preenchidos dinamicamente**: só se o campo existir na estrutura da BAPI (notas em implantação) 💡✅ |

### 11.4 `OBJ_ITEM_TAX` – uma linha por imposto com valor > 0 ✅

| Grupo | Coluna | TAXTYP | BASE | RATE | TAXVAL |
|---|---|---|---|---|---|
| 01 | J – CBS Devido | TAXTYP_CBS | Valor serviços | valor ÷ base × 100 | J |
| 01 | K – IBS Devido | TAXTYP_IBS | Valor serviços | valor ÷ base × 100 | K |
| 02 | L – INSS | TAXTYP_INSS | Valor serviços | valor ÷ base × 100 | L |
| 03 | M – IRRF Retido | TAXTYP_IRRF | Valor serviços | valor ÷ base × 100 | M |
| 03 | N – CSLL Retido | TAXTYP_CSLL | Valor serviços | valor ÷ base × 100 | N |
| 03 | O – CBS Retido | TAXTYP_CBS_WHT | Valor serviços | valor ÷ base × 100 | O |
| 03 | P – IBS Retido | TAXTYP_IBS_WHT | Valor serviços | valor ÷ base × 100 | P |
| 03 | Q – ISS | TAXTYP_ISS (S/N) | Valor serviços | Alíquota × 100 | Q |

> ⚠️ Pré-requisito fiscal: tipos de retenção configurados como **retenção** na J_1BAJ (não somam ao total da NF) e NF type Z1 sem lançamento contábil (J_1BAA).

### 11.5 `OBJ_HEADER_MSG` – texto da NF

- Discriminação dos serviços: `||` e `|` = quebra de linha; cada linha quebrada em blocos de 72 caracteres (sem cortar palavras).
- Última linha: `RPS: <número>` (enquanto `RPS_TARGET = TEXT`) ⏳.

### 11.6 Retorno

| Resultado | ZSD_BR_NFSE_DATA | ZSD_BR_NFSE_LOG |
|---|---|---|
| Sucesso | STATUS = S, DOCNUM = DOC_NUMBER (gravado antes do COMMIT) | Msg 022 (tipo S) com DOCNUM |
| Erro | STATUS = E | Cada mensagem E/A do RETURN: classe (ID), número, texto |

---

## 12. Status do arquivo

| Situação | FILE-STATUS |
|---|---|
| Erro de arquivo (018/001/033), cancelado no popup ou todas as linhas E | E |
| Todas as linhas S (ou V em Validate only) | S |
| Demais casos | P |

Também atualiza `LINE_COUNT`, `SUCCESS_COUNT`, `ERROR_COUNT`.

---

## 13. Funções do admin

### 13.1 Manutenção de parâmetros (opção 3)

`VIEW_MAINTENANCE_CALL` (ação U, view `ZSD_BR_NFSE_PARM`), usando o TMG gerado. Vantagens: transporte padrão, log de alteração, autorização via `S_TABU_DIS`, sem dynpro manual.

### 13.2 Expurgo de logs – LGPD (opção 4) ✅

As tabelas guardam dados pessoais (CPF/CNPJ, nomes, e-mails, endereços). O expurgo apaga `ZSD_BR_NFSE_FILE` + `ZSD_BR_NFSE_DATA` + `ZSD_BR_NFSE_LOG` dos arquivos com `EXEC_DATE < P_PDATE`. Com `P_PTEST` mostra apenas a contagem; sem ele pede confirmação (popup) e grava o resultado (msg 034). As NFs no SAP não são afetadas.

### 13.3 Reprocessar erros (botão no ALV de log, só admin) ✅

Para um arquivo selecionado, reprocessa as linhas com status E (ou ' ' após bloqueio 030) **a partir dos dados já gravados** – sem novo upload. Útil quando o erro era de configuração (ex.: material não cadastrado em parâmetros). Executa novamente validações, duplicidade e criação (passos 5–9); as mensagens antigas da linha são mantidas e as novas são acrescentadas com novo `LOG_ITEM`; o status do arquivo é recalculado.

---

## 14. ALVs

### 14.1 Resultado do processamento (opção 1)

Cabeçalho (top-of-list): File ID, arquivo, empresa/local de negócio, status do arquivo, linhas / sucesso / erro.

| Coluna | Visível | Obs. |
|---|---|---|
| Status (ícone) | ✔ | S = 🟢 · S com avisos (W) = 🟡 · E = 🔴 · NF cancelada = ⚪ cinza · V (validate only) = 🔵 · não processada = vazio |
| LINE_ID | ✔ | Linha do Excel |
| KUNNR | ✔ | |
| CUSTOMER_SHORT_NAME | ✔ | |
| RPS_NUMBER | ✔ | |
| SERVICE_DATE | ✔ | |
| SERVICE_AMOUNT | ✔ | Com total |
| ISS_AMT | ✔ | Com total |
| SERVICE_CODE | ✔ | |
| DOCNUM | ✔ | **Hotspot** → `SET PARAMETER ID 'JEF'` + `CALL TRANSACTION 'J1B3N' AND SKIP FIRST SCREEN` (⏳ confirmar PID) |
| CANCELLED | ✔ | Lido em tempo real de `J_1BNFDOC-CANCEL` (X = NF cancelada) ✅ |
| MESSAGE | ✔ | 1ª mensagem de erro (ou aviso, ou sucesso); nº de mensagens entre parênteses |
| Demais campos da DATA | – | Disponíveis via layout |

Duplo clique na linha → popup com todas as mensagens da linha (`ZSD_BR_NFSE_LOG`). Layouts de usuário salváveis. Durante o processamento: indicador de progresso (`SAPGUI_PROGRESS_INDICATOR`, "Creating NF 12 of 85").

### 14.2 Log de execução (opção 2)

Mesma estrutura do 14.1, com colunas adicionais visíveis: **FILE_ID, FILE_NAME, EXEC_DATE, EXEC_USER** e **File status** (ícone: S 🟢 / P 🟡 / E 🔴). Erros de arquivo (linha 000000) aparecem como linha própria. Duplo clique → popup de mensagens; hotspot DOCNUM igual ao 14.1. **Admin**: botão "Reprocess errors" na barra (seção 13.3).

---

## 15. Classe de mensagem `ZSD_BR_NFSE_MSG`

| Nº | Texto (EN) | Status |
|---|---|---|
| 001 | Excel layout differs from standard (column &1: expected &2) | ✅ |
| 002 | Customer &1 does not exist | ✅ |
| 003 | Tax ID &1 differs from customer &2 master data | ✅ |
| 004 | Service code not filled | ✅ |
| 005 | Material could not be determined for service code &1 | ✅ |
| 006 | Service amount must be greater than zero | ✅ |
| 007 | Total withheld taxes &1 exceed service amount &2 | ✅ |
| 008 | Service date &1 is after issue date &2 | ✅ |
| 009 | Service description is empty | ✅ |
| 010 | CBS withheld &1 greater than CBS due &2 | ✅ |
| 011 | IBS withheld &1 greater than IBS due &2 | ✅ |
| 012 | Invalid ISS withheld indicator &1 (expected S or N) | ✅ |
| 013 | ISS amount &1 differs from rate x service amount (&2) | ✅ |
| 014 | Tax group &1 not filled | ✅ |
| 015 | Service municipality not filled | ✅ |
| 016 | UF &1 does not match municipality code &2 | ✅ |
| 017 | Duplicate RPS &1 (file &2, line &3, NF &4) | ✅ |
| 018 | File &1 could not be read or worksheet &2 not found | ✅ |
| 019 | Customer &1 not extended to company code &2 | ✅ |
| 020 | Customer &1 is blocked | ✅ |
| 021 | No authorization for company code &1 / transaction &2 | ✅ |
| 022 | Nota Fiscal &1 created successfully | ✅ |
| 023 | Tax type not configured for &1 | ✅ |
| 024 | Service date missing or invalid | ✅ |
| 025 | Parameter &1 not configured for value &2 | ✅ |
| 026 | Probable duplicate of file &1 line &2 (NF &3): same customer, date, amount and service | ✅ |
| 027 | Processing cancelled by user (duplicates found) | ✅ |
| 028 | Warning: customer &1 address in file differs from master data | ✅ (W) |
| 029 | Warning: service municipality filled but service is not outside São Paulo | ✅ (W) |
| 030 | Processing locked by user &1 for company code &2 / business place &3 | ✅ |
| 031 | Business place &1 is not assigned to company code &2 | ✅ |
| 032 | NF type &1 is not an outgoing NF type without accounting posting | ✅ |
| 033 | File has &1 lines; maximum allowed is &2 | ✅ |
| 034 | &1 files deleted (&2 lines, &3 messages) | ✅ |

---

## 16. Pendências e premissas

| # | Item | Status | Tratamento provisório |
|---|---|---|---|
| P1 | Destino do RPS (campo específico ou texto) | ⏳ | Última linha do texto da NF (`RPS_TARGET = TEXT`) |
| P2 | Significado do CR | ⏳ | Gravado e exibido no log; não vai à NF |
| P3 | Objeto de autorização da J1B1N (SU24) | ⏳ | `F_BKPF_BUK` + `S_TCODE` |
| P4 | Valores fiscais dos parâmetros (TAXTYP, TAXLW, CFOP, ITMTYP, MATUSE) | ⏳ consultor fiscal | – |
| P5 | Notas da reforma (campos CBS/IBS/NBS/cClassTrib) | ⏳ em implantação | Preenchimento dinâmico |
| P6 | Significado da coluna AS ("Nacional") | ⏳ | Gravada, sem uso |
| P7 | Parameter ID do DOCNUM na J1B3N (`JEF`) | ⏳ verificar no sistema | – |
| P8 | Nomes do header (Developer / IT / Business) | ⏳ | `<TBD>` |
| P9 | Sugestões (P_TEST, msgs 017–022, 024, 025) | ✅ aprovadas | – |
| P10 | Chave do RPS duplicado | ✅ BUKRS + BRANCH | – |
| P11 | Guardar o arquivo original (`FILE_CONTENT`) | 💡 opcional | Não implementado salvo decisão |
| P12 | Regra 1 linha = 1 NF | ⏳ confirmar com fiscal | 1:1 |
| P13 | `P_DOCDAT` editável pelo admin e impacto nos livros fiscais / EFD-Reinf / DIRF dos tipos de retenção | ⏳ confirmar com fiscal | Admin pode alterar |
| P14 | Prazo de retenção do log (LGPD) | ⏳ validar com DPO | 5 anos |

---

## 17. Entregáveis e próximos passos

1. Revisão deste documento (v0.3) e do mockup – https://claude.ai/artifact/UewVEduzZQ7zAnPXbE3VZj
2. Aprovação.
3. Codificação + especificação final do DDIC (transporte de DDIC separado – guideline item 14a).
4. Documentação do programa para o usuário (SE38, em português) além do header ✅.
5. ATC / Code Inspector sem erros ✅.
6. Planilha de teste com um caso por mensagem (001–034) para o teste integrado ✅.
