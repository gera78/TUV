# ZSD_BR_NFSE – Especificação de dicionário e configuração

Objetos a criar no sistema **antes** de ativar os programas. Ordem de transporte separada para o DDIC (guideline TÜV, item 14a). Classe de entrega das tabelas Z de log: **A**; da tabela de parâmetros: **C**.

---

## 1. Domínios

| Domínio | Tipo | Valores fixos |
|---|---|---|
| ZSD_BR_NFSE_FILE_STATUS | CHAR 1 | S Success · P Partially processed · E Error |
| ZSD_BR_NFSE_LINE_STATUS | CHAR 1 | (vazio) Not processed · S Success · E Error · V Validated (test run) |
| ZSD_BR_NFSE_YES_NO | CHAR 1 | S Yes · N No |
| ZSD_BR_NFSE_AMOUNT | CURR 15,2 | – |
| ZSD_BR_NFSE_RATE | DEC 7,4 | – |

## 2. Elementos de dados

Rótulos em inglês (curto / médio / longo). Os não listados usam elemento standard.

| Elemento de dados | Domínio / tipo | Rótulo longo |
|---|---|---|
| ZSD_BR_NFSE_FILE_ID | NUMC 10 | File ID |
| ZSD_BR_NFSE_LINE_ID | NUMC 6 | Excel Row |
| ZSD_BR_NFSE_LOG_ITEM | NUMC 4 | Log Item |
| ZSD_BR_NFSE_FILE_NAME | CHAR 255 | File Name |
| ZSD_BR_NFSE_FILE_PATH | CHAR 255 | File Path |
| ZSD_BR_NFSE_FILE_STATUS | ZSD_BR_NFSE_FILE_STATUS | File Status |
| ZSD_BR_NFSE_LINE_STATUS | ZSD_BR_NFSE_LINE_STATUS | Line Status |
| ZSD_BR_NFSE_LINE_COUNT | INT4 | Number of Lines |
| ZSD_BR_NFSE_SUCCESS_COUNT | INT4 | Lines with Success |
| ZSD_BR_NFSE_ERROR_COUNT | INT4 | Lines with Error |
| ZSD_BR_NFSE_TEST_RUN | CHAR 1 (XFELD) | Validation Only |
| ZSD_BR_NFSE_USER_CANCEL | CHAR 1 (XFELD) | Cancelled by User |
| ZSD_BR_NFSE_CR_CODE | CHAR 10 | CR |
| ZSD_BR_NFSE_CUST_SHORT_NAME | CHAR 40 | Customer Short Name |
| ZSD_BR_NFSE_CITY | CHAR 40 | City |
| ZSD_BR_NFSE_RPS_NUMBER | CHAR 15 | RPS Number |
| ZSD_BR_NFSE_SERVICE_DATE | DATS | Service Date |
| ZSD_BR_NFSE_SERVICE_AMOUNT | ZSD_BR_NFSE_AMOUNT | Service Amount |
| ZSD_BR_NFSE_CBS_DUE_AMT | ZSD_BR_NFSE_AMOUNT | CBS Due |
| ZSD_BR_NFSE_IBS_DUE_AMT | ZSD_BR_NFSE_AMOUNT | IBS Due |
| ZSD_BR_NFSE_INSS_AMT | ZSD_BR_NFSE_AMOUNT | INSS |
| ZSD_BR_NFSE_IRRF_WHT_AMT | ZSD_BR_NFSE_AMOUNT | IRRF Withheld |
| ZSD_BR_NFSE_CSLL_WHT_AMT | ZSD_BR_NFSE_AMOUNT | CSLL Withheld |
| ZSD_BR_NFSE_CBS_WHT_AMT | ZSD_BR_NFSE_AMOUNT | CBS Withheld |
| ZSD_BR_NFSE_IBS_WHT_AMT | ZSD_BR_NFSE_AMOUNT | IBS Withheld |
| ZSD_BR_NFSE_ISS_AMT | ZSD_BR_NFSE_AMOUNT | ISS Amount |
| ZSD_BR_NFSE_ISS_RATE | ZSD_BR_NFSE_RATE | ISS Rate |
| ZSD_BR_NFSE_ISS_WHT_FLAG | ZSD_BR_NFSE_YES_NO | ISS Withheld |
| ZSD_BR_NFSE_OUTSIDE_SP_FLAG | ZSD_BR_NFSE_YES_NO | Service Outside São Paulo |
| ZSD_BR_NFSE_SERVICE_CODE | CHAR 10 | Service Code |
| ZSD_BR_NFSE_SERV_CITY_CODE | NUMC 7 | Service Municipality (IBGE) |
| ZSD_BR_NFSE_SERVICE_REGION | CHAR 3 | Service Region |
| ZSD_BR_NFSE_TAKER_TAX_ID | CHAR 18 | Service Taker CPF/CNPJ |
| ZSD_BR_NFSE_TAKER_MUN_REG | CHAR 20 | Taker Municipal Registration |
| ZSD_BR_NFSE_TAKER_NAME | CHAR 120 | Service Taker Name |
| ZSD_BR_NFSE_TAKER_STR_TYPE | CHAR 10 | Taker Street Type |
| ZSD_BR_NFSE_TAKER_STREET | CHAR 60 | Taker Street |
| ZSD_BR_NFSE_TAKER_HOUSE_NUM | CHAR 10 | Taker House Number |
| ZSD_BR_NFSE_TAKER_DISTRICT | CHAR 40 | Taker District |
| ZSD_BR_NFSE_TAKER_CITY | CHAR 40 | Taker City |
| ZSD_BR_NFSE_TAKER_REGION | CHAR 3 | Taker Region |
| ZSD_BR_NFSE_TAKER_POST_CODE | CHAR 10 | Taker Postal Code |
| ZSD_BR_NFSE_SERVICE_DESCR | STRING | Service Description |
| ZSD_BR_NFSE_RCP_TAX_ID | CHAR 40 | Recipient Tax ID |
| ZSD_BR_NFSE_RCP_NAME | CHAR 120 | Recipient Name |
| ZSD_BR_NFSE_RCP_ADDRESS | CHAR 100 | Recipient Address |
| ZSD_BR_NFSE_RCP_NAT_FOREIGN | CHAR 1 | Recipient National/Foreign |
| ZSD_BR_NFSE_RCP_STREET | CHAR 60 | Recipient Street |
| ZSD_BR_NFSE_RCP_HOUSE_NUM | CHAR 10 | Recipient House Number |
| ZSD_BR_NFSE_RCP_ADDR_COMPL | CHAR 60 | Recipient Address Supplement |
| ZSD_BR_NFSE_RCP_DISTRICT | CHAR 40 | Recipient District |
| ZSD_BR_NFSE_SITE_CIB_CNO | CHAR 20 | Site CIB/CNO |
| ZSD_BR_NFSE_SITE_NATIONAL | CHAR 1 | Site National |
| ZSD_BR_NFSE_SITE_POST_CODE | CHAR 10 | Site Postal Code |
| ZSD_BR_NFSE_SITE_STREET | CHAR 60 | Site Street |
| ZSD_BR_NFSE_SITE_HOUSE_NUM | CHAR 10 | Site House Number |
| ZSD_BR_NFSE_SITE_ADDR_COMPL | CHAR 60 | Site Address Supplement |
| ZSD_BR_NFSE_SITE_DISTRICT | CHAR 40 | Site District |
| ZSD_BR_NFSE_TAX_CLASS_MAIN | CHAR 6 | Main Tax Classification |
| ZSD_BR_NFSE_OPER_IND_CODE | CHAR 6 | Operation Indicator |
| ZSD_BR_NFSE_NBS_CODE | CHAR 9 | NBS Code |
| ZSD_BR_NFSE_TAX_CLASS_REG | CHAR 6 | Regular Tax Classification |
| ZSD_BR_NFSE_EXPORT_FILE | CHAR 255 | Last Output File |
| ZSD_BR_NFSE_EXPORT_DATE | DATS | Last Export Date |
| ZSD_BR_NFSE_EXPORT_TIME | TIMS | Last Export Time |
| ZSD_BR_NFSE_EXPORT_USER | CHAR 12 (UNAME) | Last Exported By |
| ZSD_BR_NFSE_EXPORT_COUNT | INT2 | Times Exported |
| ZSD_BR_NFSE_FIELD_NAME | CHAR 30 | Parameter Name |
| ZSD_BR_NFSE_FILE_COLUMN_NAME | CHAR 60 | Excel Column Name |
| ZSD_BR_NFSE_INPUT_VALUE | CHAR 60 | Input Value |
| ZSD_BR_NFSE_OUTPUT_VALUE | CHAR 255 | Output Value |

## 3. Tabelas

### 3.1 ZSD_BR_NFSE_FILE (classe A)

| Campo | Chave | Elemento de dados |
|---|---|---|
| MANDT | X | MANDT |
| FILE_ID | X | ZSD_BR_NFSE_FILE_ID |
| FILE_NAME | | ZSD_BR_NFSE_FILE_NAME |
| FILE_PATH | | ZSD_BR_NFSE_FILE_PATH |
| BUKRS | | BUKRS |
| BRANCH | | J_1BBRANC_ |
| NFTYPE | | J_1BNFTYPE |
| DOC_DATE | | J_1BDOCDAT |
| EXEC_USER | | UNAME |
| EXEC_DATE | | DATUM |
| EXEC_TIME | | UZEIT |
| LINE_COUNT | | ZSD_BR_NFSE_LINE_COUNT |
| SUCCESS_COUNT | | ZSD_BR_NFSE_SUCCESS_COUNT |
| ERROR_COUNT | | ZSD_BR_NFSE_ERROR_COUNT |
| STATUS | | ZSD_BR_NFSE_FILE_STATUS |
| TEST_RUN | | ZSD_BR_NFSE_TEST_RUN |
| CANCEL_FLAG | | ZSD_BR_NFSE_USER_CANCEL |

Índice secundário Z01: BUKRS, BRANCH, EXEC_DATE.

### 3.2 ZSD_BR_NFSE_DATA (classe A)

Chave MANDT + FILE_ID + LINE_ID. Campos de controle: STATUS (ZSD_BR_NFSE_LINE_STATUS), DOCNUM (J_1BDOCNUM), WAERS (WAERS – referência de todos os campos CURR). Campos da planilha: os 53 campos da seção 6.3 do documento de desenho (KUNNR … TAX_CLASS_REG), com os elementos de dados da seção 2. Campos de exportação: EXPORT_FILE, EXPORT_DATE, EXPORT_TIME, EXPORT_USER, EXPORT_COUNT.

Índices secundários: Z01 RPS_NUMBER, STATUS · Z02 KUNNR, SERVICE_DATE · Z03 DOCNUM.

### 3.3 ZSD_BR_NFSE_LOG (classe A)

| Campo | Chave | Elemento de dados |
|---|---|---|
| MANDT | X | MANDT |
| FILE_ID | X | ZSD_BR_NFSE_FILE_ID |
| LINE_ID | X | ZSD_BR_NFSE_LINE_ID |
| LOG_ITEM | X | ZSD_BR_NFSE_LOG_ITEM |
| MSGTY | | SYMSGTY |
| MSGID | | SYMSGID |
| MSGNO | | SYMSGNO |
| MSGV1 … MSGV4 | | SYMSGV |
| MESSAGE | | BAPI_MSG |
| LOG_DATE | | DATUM |
| LOG_TIME | | UZEIT |

### 3.4 ZSD_BR_NFSE_PARM (classe C, log de alterações ativo)

| Campo | Chave | Elemento de dados |
|---|---|---|
| MANDT | X | MANDT |
| BUKRS | X | BUKRS |
| FIELD_NAME | X | ZSD_BR_NFSE_FIELD_NAME |
| FILE_COLUMN_NAME | X | ZSD_BR_NFSE_FILE_COLUMN_NAME |
| INPUT | X | ZSD_BR_NFSE_INPUT_VALUE |
| OUTPUT | | ZSD_BR_NFSE_OUTPUT_VALUE |

Manutenção (SE54): grupo de funções ZSD_BR_NFSE_PARM, tela única, grupo de autorização próprio (S_TABU_DIS). FILE_COLUMN_NAME, INPUT e OUTPUT com "Lower case" marcado no domínio.

## 4. Outros objetos

| Objeto | Detalhe |
|---|---|
| Range de numeração ZNFSE_FILE (SNRO) | Intervalo 01, 0000000001–9999999999, sem buffer |
| Bloqueio | Não precisa de objeto próprio: usa `ENQUEUE_E_TABLE` com tabela ZSD_BR_NFSE_FILE e chave mandante + empresa + local de negócio |
| Transações (SE93) | ZNFSE → ZSD_BR_NFSE_UPLOAD · ZNFSE_ADM → ZSD_BR_NFSE_UPLOAD_ADM (tela 1000) |
| Status GUI ZNFSE_EXPORT | Nos **dois** programas: cópia do status SALV_STANDARD do programa SAPLSALV_METADATA_STATUS + funções SELALL (Select all), DESALL (Deselect all), EXPORT (Export CSV) |
| Status GUI ZNFSE_LOG | Só no programa admin: cópia do SALV_STANDARD + função REPROC (Reprocess errors) |

## 5. Textos dos programas

**Textos de seleção** (os dois programas): P_RUPL Process upload and create NF Writer · P_RLOG Display execution log · P_REXP Generate output file (CSV) · P_RPARM Maintain parameters · P_RPURG Purge old logs · P_BUKRS Company Code · P_BRANCH Business Place · P_NFTYPE NF Type · P_DOCDAT Issue Date · P_FILE Excel File · P_TEST Validate only (no NF creation) · P_LERR Lines with errors only · P_XSITU Taxation type (T/F) · P_XNEW Not yet exported only · P_PBUKRS Company Code · P_PDATE Delete files executed before · P_PTEST Test run (count only) · S_L*/S_X*: usar "Dictionary reference".

**Símbolos de texto**

| Símbolo | Texto |
|---|---|
| B01 | Processing Option |
| B02 | Upload Parameters |
| B03 | Log Selection |
| B04 | Output File Selection |
| B05 | Purge |
| F01 | Select the NFS-e workbook |
| G01 | Creating NF |
| P01 | Lines already processed with success |
| P02 | Duplicates found |
| P03 | Some lines were already processed. Continue without them? |
| P04 | Continue without duplicates |
| P05 | Cancel processing |
| P06 | Messages of file / line |
| C01 | Select |
| C02 | File Status |
| C03 | Line Status |
| C04 | Exported |
| C05 | Message |
| C06 | Messages |
| C07 | Taxation (T/F) |
| C08 | NFS-e Status |
| C09 | NF Cancelled |
| H01 | File |
| H02 | Company / Business Place / NF Type |
| H03 | Executed |
| H04 | Status - Lines / Success / Error |
| S01 | Authorized |
| S02 | Awaiting authorization |
| S03 | Rejected |
| S04 | Cancelled |
| E01 | Export again? |
| E02 | selected lines were already exported. Export them again? |
| E03 | Yes - all |
| E04 | No - only new |
| R01 | Purge old logs |
| R02 | Delete the selected log entries permanently? |

## 6. Classe de mensagem ZSD_BR_NFSE_MSG

| Nº | Texto |
|---|---|
| 001 | Excel layout differs from standard (column &1: expected &2) |
| 002 | Customer &1 does not exist |
| 003 | Tax ID &1 differs from customer &2 master data |
| 004 | Service code not filled |
| 005 | Material could not be determined for service code &1 |
| 006 | Service amount must be greater than zero |
| 007 | Total withheld taxes &1 exceed service amount &2 |
| 008 | Service date &1 is after issue date &2 |
| 009 | Service description is empty |
| 010 | CBS withheld &1 greater than CBS due &2 |
| 011 | IBS withheld &1 greater than IBS due &2 |
| 012 | Invalid ISS withheld indicator &1 (expected S or N) |
| 013 | ISS amount &1 differs from rate x service amount (&2) |
| 014 | Tax group &1 not filled |
| 015 | Service municipality not filled |
| 016 | UF &1 does not match municipality code &2 |
| 017 | Duplicate RPS &1 (file &2, line &3) |
| 018 | File &1 could not be read or worksheet &2 not found |
| 019 | Customer &1 not extended to company code &2 |
| 020 | Customer &1 is blocked |
| 021 | No authorization for company code &1 / transaction &2 |
| 022 | Nota Fiscal &1 created successfully |
| 023 | Tax type not configured for &1 |
| 024 | Service date missing or invalid |
| 025 | Parameter &1 not configured for value &2 |
| 026 | Probable duplicate of file &1 line &2 (NF &3) |
| 027 | Processing cancelled by user (duplicates found) |
| 028 | Customer &1: address in file differs from master data |
| 029 | Service municipality filled but service is not outside São Paulo |
| 030 | Processing locked by user &1 for company code &2 / business place &3 |
| 031 | Business place &1 is not assigned to company code &2 |
| 032 | NF type &1 is not an outgoing NF type |
| 033 | File has &1 lines; maximum allowed is &2 |
| 034 | &1 files deleted (&2 lines, &3 messages) |
| 035 | Line exported to output file &1 |
| 036 | Output file &1 could not be written; nothing was recorded |
| 037 | No lines selected for export |
| 038 | &1 lines exported to &2 |
| 039 | RPS &1 is invalid (numeric, max. 6 digits) |
| 040 | CBS/IBS not sent to the NF (parameter SEND_CBS_IBS is off) |
| 041 | File &1 processed: &2 lines OK, &3 lines with error |
| 042 | No data found for the selection |
| 043 | Select a line first |
| 044 | Simulation: &1 files, &2 lines and &3 messages would be deleted |
| 045 | File &1 has no lines to reprocess |
| 046 | Reprocessing started by &1 |

## 7. Conteúdo inicial da ZSD_BR_NFSE_PARM (empresa 5596)

| FIELD_NAME | FILE_COLUMN_NAME | INPUT | OUTPUT |
|---|---|---|---|
| SHEET_NAME | | * | Emissão NF - Ductor |
| MAX_LINES | | * | 500 |
| ISS_TOLERANCE | | * | 0.01 |
| SEND_CBS_IBS | | * | (vazio) |
| TAXGRP_REQ_01 | | * | X |
| LOG_RETENTION_YEARS | | * | 5 |
| RPS_SERIES | | * | 900 |
| CSV_REMOVE_ACCENTS | | * | X |
| PRV_MUN_REG | | * | 8.169.973-5 |
| PRV_TAX_ID | | * | 47.096.581/0001-70 |
| PRV_NAME | | * | TUV RHEINLAND DUCTOR LTDA |
| PRV_STREET_TYPE | | * | AV |
| PRV_STREET | | * | FRANCISCO MATARAZZO |
| PRV_HOUSE_NUM | | * | 1400 |
| PRV_ADDR_COMPL | | * | ANDAR 6 |
| PRV_DISTRICT | | * | AGUA BRANCA |
| PRV_POSTAL_CODE | | * | 05001-903 |
| PRV_EMAIL | | * | fiscal@br.tuv.com |
| SRV_DESCRIPTION | Código do Serviço Prestado na Nota Fiscal | 1805 | Acompanhamento e fiscalizacao da execucao de obras de engenharia, arquitetura e urbanismo. |
| SRV_DESCRIPTION | Código do Serviço Prestado na Nota Fiscal | 1902 | Pericias, laudos, exames tecnicos e analises tecnicas, inclusive institutos psicotecnicos. |
| SRV_DESCRIPTION | Código do Serviço Prestado na Nota Fiscal | 1694 | Estudos, planos e projetos tecnicos de engenharia, arquitetura e urbanismo. |
| SRV_DESCRIPTION | Código do Serviço Prestado na Nota Fiscal | 3115 | Assessoria ou consultoria de qualquer natureza, nao contida em outros itens desta lista. |
| MATNR | Código do Serviço Prestado na Nota Fiscal | (código) | ⏳ material – consultor fiscal |
| CFOP | UF do Tomador | SP / * | ⏳ CFOP – consultor fiscal |
| TAXTYP_ISS | ISS Retido | S / N | ⏳ tipo de imposto |
| TAXLW3 | ISS Retido | S / N | ⏳ lei fiscal ISS |
| TAXTYP_INSS, _IRRF, _CSLL (e _CBS, _IBS, _CBS_WHT, _IBS_WHT) | | * | ⏳ tipos de imposto |
| TAXLW1, TAXLW2, TAXLW4, TAXLW5, ITMTYP, MATUSE, MATORG | | * | ⏳ consultor fiscal |
| WERKS | | * | opcional: vazio = centro do local de negócio (T001W-J_1BBRANCH) |

## 8. Pontos a verificar na ativação

- Nomes de campos das estruturas da BAPI (`BAPI_J_1BNFDOC`, `BAPI_J_1BNFLIN`, `BAPI_J_1BNFSTX`, `BAPI_J_1BNFFTX`): campos opcionais (CFOP, TAXLW3, XPED, campos da reforma, DOCTYP/MODEL/SERIES) já são preenchidos dinamicamente; os demais são os padrão do NF Writer.
- Parameter ID do DOCNUM usado na J1B3N: constante `GC_PID_DOCNUM = 'JEF'` (verificar no elemento J_1BDOCNUM).
- Valor de `J_1BNFE_ACTIVE-DOCSTA` para NFS-e autorizada: constante `GC_DOCSTA_AUTH = '1'`.
