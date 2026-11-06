# ZSD_BR_NFSE – Evidências de teste das soluções

Testes de 06.11.2026 (empresa 5596, local de negócio 0001, tipo de NF Z2, cliente 2632597 – WINITY S.A., serviço de R$ 2.000,00, ISS 5%, CSLL 1%, IRRF 1,5%), executados por MARCONDESA.

**Fonte das evidências:** exports das tabelas da NF (`J_1BNFDOC` cabeçalho, `J_1BNFLIN` item, `J_1BNFSTX` impostos) em SharePoint *DZeeTech-Projects › TUV › 2_Technical Documentation › IT Unit test Documentation*, e o log do `ZSD_BR_NFSE` copiado na conversa de desenvolvimento.

## 1. NFs e arquivos

| NF (DOCNUM) | Criada | Versão do programa | Cabeçalho | Item | Impostos | Observação |
|---|---|---|---|---|---|---|
| — | 06.11 09:08 | antes das correções | – | – | – | Log com 8B 660, 8B 150, 8B 151, 8B 685; NF não criada |
| 226751 / 226752 / 226753 | 06.11 10:04 / 10:28 / 10:55 | 0.5 parcial (E_DOCNUM, BWKEY, 025, check string) | `EXPORT_20261106_130429.xlsx` | `EXPORT_20261106_130520.xlsx` | `EXPORT_20261106_130611.xlsx` | Primeiras NFs criadas pelo programa |
| **226744** (referência) | 02.11 (SD) | – | `EXPORT_20261106_133016.xlsx` | `EXPORT_20261106_133131.xlsx` | `EXPORT_20261106_133418.xlsx` | NF de serviço **correta** criada pelo faturamento SD (empresa 5590) |
| 226756 | 06.11 16:50 | 0.5 + item de serviço | `EXPORT_20261106_165420.xlsx` | `EXPORT_20261106_170353.xlsx` | – | Alterada manualmente às 16:52 (CFOP 5933/AA) – não usar como evidência do programa |
| **226758** | 06.11 17:29 | 0.5 final | `EXPORT_20261106_173216.xlsx` | `EXPORT_20261106_173304.xlsx` | `EXPORT_20261106_173356.xlsx` | Criada pelo programa, sem alteração posterior |
| **226759** / **226761** | 06.11 17:52 / 19:17 | 0.6 (CFOP_10) | `EXPORT_20261106_195409.xlsx` | `EXPORT_20261106_195456.xlsx` | `EXPORT_20261106_195524.xlsx` | Criadas pelo programa; parâmetro `TAXLW3` = I02 |

## 2. Evidência por solução

### #5 – Dump "function parameter ... is unknown" (E_DOCNUM) – PR #1

| | Antes | Depois |
|---|---|---|
| Execução real | Dump na chamada da BAPI | NFs 226751–226753 e 226758 criadas; cabeçalho "NF via BAPI" = **X** |

Arquivos: `EXPORT_20261106_130429.xlsx`, `EXPORT_20261106_173216.xlsx`.
A testar: falha forçada da chamada → mensagem 047 no log, sem dump.

### #6 – 8B 685 Valuation area is not assigned to plant 5596 – PR #1

| Campo (`J_1BNFLIN`) | Antes (09:08) | Depois (226751, 226758) |
|---|---|---|
| Valuation Area (`BWKEY`) | vazio → 8B 685 | **5596** |
| Plant | 5596 | 5596 |

Arquivos: `EXPORT_20261106_130520.xlsx`, `EXPORT_20261106_173304.xlsx`.

### #7 – 8B 660 Enter the usage of the material – PR #1

| Campo (`J_1BNFLIN`) | Antes (09:08) | Depois (226751, 226758) |
|---|---|---|
| Material Usage (`MATUSE`) | vazio → 8B 660 | **1** |
| NF Item Type (`ITMTYP`) | – | 1 |

Arquivos: `EXPORT_20261106_130520.xlsx`, `EXPORT_20261106_173304.xlsx`.
A testar: parâmetro com `Z_OUTPUT` vazio → mensagem 025 (aviso no Validate only).

### #8 – 8B 150 / 8B 151 Tax situation / NCM missing – PR #1

| | Antes (09:08) | Depois (226751, 226758) |
|---|---|---|
| Resultado | 8B 150 e 8B 151, NF não criada | NF criada com Material Group e NCM (Control Code) vazios – checks 13, 27 e 28 desligados (`NFCHECK-CHEKCON`) |

Arquivos: `EXPORT_20261106_130520.xlsx`, `EXPORT_20261106_173304.xlsx`.

### #9 – Descrição do serviço na J1B3N (OBJ_HEADER_TEXT) – PR #1

Sem evidência ainda: os exports não incluem os textos da NF e o parâmetro `HDR_TEXT_ID` não foi definido (OT7).
A testar: com `HDR_TEXT_ID` preenchido, texto da coluna AH nos textos de cabeçalho da J1B3N; com vazio, nas mensagens de cabeçalho.

### #10 – Total da NF 2.100 e retenções sem flag – PR #1

| Campo | NF do SD 226744 (referência) | Antes – 226751 | **Depois – 226758** |
|---|---|---|---|
| Total value incl. tax (`J_1BNFDOC`) | = serviço (17.654,93) | 2.100,00 ❌ | **2.000,00** ✅ |
| NF partner function | RE | AG | **RE** ✅ |
| Service NF/NF-e (`NFESRV`) | X | vazio | **X** ✅ |
| Municipal Fiscal Document | X | vazio | **X** ✅ |
| Tax Category | R | N | **R** ✅ |
| Service/No ICMS-IPI (`TMISS`) | X | vazio | **X** ✅ |
| Incl. ICMS/ISS (`INCLTX`) | X | vazio | **X** ✅ |
| Net Price / Value com imposto | = líquido | 2.100 / 2.100 | **2.000 / 2.000** ✅ |
| ICMS / IPI law | vazias | ISS / ISS | **vazias** ✅ |
| Tax situation ICMS / IPI | vazia / 0 | 90 / 99999 | **vazia / 0** ✅ |
| Retenção CSLL (ICSQ) – Withholding Tax / Tax Incl. in Net Value | X / X | vazio / vazio | **X / X** ✅ |
| Retenção IRRF (IIRW) – Withholding Tax / Tax Incl. in Net Value | X / X | vazio / vazio | **X / X** ✅ |

Arquivos: referência `EXPORT_20261106_133016/133131/133418.xlsx`; antes `EXPORT_20261106_130429/130520/130611.xlsx`; depois `EXPORT_20261106_173216/173304/173356.xlsx`.

### #11 – Include F01 não ativava (FORMs duplicados) – PR #1

| | Antes | Depois |
|---|---|---|
| Ativação da `ZSD_BR_NFSE_F01` | Erro de sintaxe (FORMs duplicados) | Ativada; NFs 226756 e 226758 criadas com a versão corrigida |

### #12 – Tabela ZSD_BR_NFSE_PARM classe de entrega A – PR #1

Sem evidência de teste ainda.
A testar: SE11 mostra classe de entrega A; SM30 em produção mantém parâmetros sem pedir ordem de transporte.

### #13 – Mensagens 023/025 como aviso só no Validate only – PR #1

Sem evidência de teste ainda.
A testar: Validate only com parâmetro faltando → 025 tipo W, linha com status V; execução real → sem 023/025, erro vem do retorno da BAPI.

### #14 – CFOP gravado como 593/3A – PR #2

| Campo | NF do SD 226744 | Antes – 226758 | Depois |
|---|---|---|---|
| CFOP (`J_1BNFLIN`) | 6933/AA | **593/3A** ❌ (parâmetro 5933AA, campo `CFOP` antigo CHAR 5) | **5933/AA** ✅ (226759, 226761) |
| Operation Nature (`J_1BNFDOC`) | Prestação de serviço tributado pelo ISSQN | **vazia** ❌ | **Prestação de serviço tributado pelo ISSQN** ✅ (226759, 226761) |

Arquivos: antes `EXPORT_20261106_173216.xlsx`, `EXPORT_20261106_173304.xlsx`; depois `EXPORT_20261106_195409.xlsx`, `EXPORT_20261106_195456.xlsx`.

## 3. Encerramento dos testes (06.11.2026)

Testes encerrados com as NFs 226758 (v0.5), 226759 e 226761 (v0.6). Resultado:

| Solução | Resultado |
|---|---|
| #5, #6, #7, #8, #10, #11 | ✅ Confirmadas |
| #14 CFOP | ✅ Confirmada – 226759 / 226761: CFOP 5933/AA e natureza da operação preenchida |
| #9 texto de cabeçalho | ⚪ Não testado – depende de `HDR_TEXT_ID` (OT7) |
| #12 classe de entrega A | ⚪ Não testado (configuração DDIC) |
| #13 023/025 como aviso | ⚪ Não testado (Validate only) |
| #4 simulação no Validate only (PR #3, v0.7) | ⚪ Não testado – v0.7 ainda não ativada no sistema (226759/226761 sem série 1, descrição em EN e sem código de recolhimento) |

Observações dos últimos testes (para o fiscal):

| Campo | NF do SD 226744 | 226759 / 226761 |
|---|---|---|
| Lei ISS / situação tributária ISS | I01 / T | **I02 / A** (parâmetro `TAXLW3` = I02) |
| Tipo de imposto do ISS | ISSA (ISSP, domicílio SP 3550308) | ISSE (ISSS) |
| Código de recolhimento das retenções | 5952 / 1708 | vazio (v0.7 / parâmetro `COLLCODE`) |
| Série | 1 | vazia (v0.7 / parâmetro `NF_SERIES`) |
| Descrição do material | Português | inglês (v0.7) |

NFs de teste a estornar antes de qualquer envio à Prefeitura (J1BNFE): 226751, 226752, 226753, 226756, 226758, 226759, 226761.
