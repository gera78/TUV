# ZSD_BR_NFSE – Check string da NF Writer (`BUILD_BAPI_NFCHECK`)

Documentação do `FORM BUILD_BAPI_NFCHECK` (include `ZSD_BR_NFSE_F01`), que monta o **check string** lido pela rotina padrão `CHECK_NF_BAPI` da NF Writer. Cada posição do check string liga (`X`) ou desliga (espaço) uma verificação padrão do SAP feita antes de gravar a Nota Fiscal.

> Fonte: código da rotina padrão `CHECK_NF_BAPI` do sistema (arquivo `check_nf_bapi.txt` enviado pelo desenvolvedor). Os números de mensagem citados são os desse código.

---

## 1. Chamada

```abap
DATA lv_nfcheck TYPE c LENGTH 47.

PERFORM build_bapi_nfcheck USING cs_data CHANGING lv_nfcheck.
```

| Parâmetro | Tipo | Uso |
|---|---|---|
| `US_DATA` | `ZSD_BR_NFSE_DATA` | Linha da planilha que está sendo criada. **Reservado** para regras por linha – hoje não é usado. |
| `CV_NFCHECK` | `ANY` (usar `C LENGTH 47`) | Check string montado, 47 posições. |

## 2. Como ativar / desativar um check

- Cada check é uma variável `lv_c01` … `lv_c47`, declarada com `VALUE 'X'` (ligado) e um comentário ao lado dizendo o que ela verifica.
- Para **desligar**, trocar `VALUE 'X'` por `VALUE ' '` na variável correspondente.
- Cada variável é gravada na **sua posição exata** (`lv_check+N(1)`). Desligar um check não desloca os seguintes – por isso o check string não é montado com `&&`, que descartaria os espaços.
- Padrão entregue: **todos os 47 checks ligados**.

## 3. Comportamento da rotina padrão

| Faixa | Efeito no padrão quando o check falha |
|---|---|
| Checks 01–04 | `SUBRC = 4` – aviso, a NF pode continuar. Atenção: os checks 02 e 03 devolvem a mensagem no RETURN com **tipo E** |
| Checks 05–47 | `SUBRC = 8` – a NF **não** é gravada |
| Checks 40–43 | Só rodam para NF-e (`NFE = 'X'` no cabeçalho) |
| Posições 44 e 45 | Não são lidas: os checks de alíquota com 4 casas e de `PAUTA_BASE`/`UNIT` rodam **sempre** |
| Check 01 | Está comentado no código padrão – o `X` não tem efeito |

Além dos checks controlados pelo check string, a rotina padrão sempre executa as verificações de configuração da NF-e (status do documento, flag NF-e e tipo de NF-e).

No `ZSD_BR_NFSE`, toda mensagem de tipo E ou A devolvida no RETURN da BAPI deixa a linha com **status E** e é gravada no log (seção 11.6 do design). Então, para este programa, os checks 02 e 03 também bloqueiam a linha, mesmo sendo "aviso" no padrão.

## 4. Posições do check string

Posição = offset no check string (`checkstring+N(1)`). Classe `8B` = mensagens padrão da NF Writer. "Classe de check" = verificação feita pela classe de checks do padrão, que devolve a mensagem pela rotina `CHECK_ERRORS_BAPI`.

| Variável | Posição | Check | O que o `X` ativa | Efeito | Mensagem no padrão |
|---|---|---|---|---|---|
| `lv_c01` | 0 | 01 | Tipos de item específicos (só entrada manual) – **comentado no padrão, sem efeito** | – | – |
| `lv_c02` | 1 | 02 | Formulário da NF (`FORM` do cabeçalho) existe na `J_1BAQ` | Aviso | 8B 514 (tipo E) |
| `lv_c03` | 2 | 03 | Combinação tipo de NF + modelo existe na `J_1BAA` | Aviso | 8B 680 (tipo E) |
| `lv_c04` | 3 | 04 | Moeda (`WAERK`) é BRL | Aviso | 8B 681 (tipo W) |
| `lv_c05` | 4 | 05 | Tipo de NF existe na `J_1BAA` e o tipo de documento confere com `DOCTYP` do cabeçalho | Erro | 8B 212 / 8B 682 |
| `lv_c06` | 5 | 06 | Empresa existe na `T001` | Erro | 8B 216 |
| `lv_c07` | 6 | 07 | Local de negócio existe para a empresa (`J_1BBRANCH`) | Erro | 8B 401 |
| `lv_c08` | 7 | 08 | Parceiro do cabeçalho e da tabela de parceiros existem (`J_1B_NF_PARTNER_READ`) | Erro | Mensagem da função |
| `lv_c09` | 8 | 09 | Tipo de item preenchido e existente na `J_1BITEMTYPES` (itens que não são de ISS) | Erro | 8B 683 |
| `lv_c10` | 9 | 10 | Material do item existe na `MARA` | Erro | 8B 051 |
| `lv_c11` | 10 | 11 | Centro do item existe na `T001W` | Erro | 8B 214 |
| `lv_c12` | 11 | 12 | Item com centro precisa ter material | Erro | 8B 663 |
| `lv_c13` | 12 | 13 | Grupo de mercadorias (`MATKL`) preenchido em todos os itens | Erro | 8B 323 |
| `lv_c14` | 13 | 14 | Unidade de medida existe na `T006` | Erro | 8B 185 |
| `lv_c15` | 14 | 15 | NCM (`NBM`) existe na `T604F` (não vale para tipo de documento R) | Erro | 8B 683 |
| `lv_c16` | 15 | 16 | Local de negócio / empresa preenchidos | Erro | Classe de check |
| `lv_c17` | 16 | 17 | Tipo de NF, tipo de documento e direção preenchidos | Erro | Classe de check |
| `lv_c18` | 17 | 18 | Função, ID e tipo de parceiro preenchidos | Erro | Classe de check |
| `lv_c19` | 18 | 19 | Data de lançamento e data do documento preenchidas | Erro | Classe de check |
| `lv_c20` | 19 | 20 | Moeda (`WAERK`) preenchida | Erro | Classe de check |
| `lv_c21` | 20 | 21 | Existe pelo menos um item | Erro | Classe de check |
| `lv_c22` | 21 | 22 | Utilização do material (`MATUSE`) preenchida | Erro | Classe de check |
| `lv_c23` | 22 | 23 | CFOP preenchido | Erro | Classe de check |
| `lv_c24` | 23 | 24 | Referência de documento preenchida nos tipos de item que exigem | Erro | Classe de check |
| `lv_c25` | 24 | 25 | Primeiro dígito do CFOP igual em todos os itens | Erro | Classe de check |
| `lv_c26` | 25 | 26 | Primeiro dígito do CFOP compatível com a direção (entrada/saída) | Erro | Classe de check |
| `lv_c27` | 26 | 27 | Lei fiscal ICMS/IPI, situação tributária e origem do material preenchidas | Erro | Classe de check |
| `lv_c28` | 27 | 28 | NCM preenchido | Erro | Classe de check |
| `lv_c29` | 28 | 29 | Existe pelo menos uma linha de imposto | Erro | Classe de check |
| `lv_c30` | 29 | 30 | Formulário da NF atende aos requisitos legais (tamanho de itens/textos) | Erro | Classe de check |
| `lv_c31` | 30 | 31 | Tipo de documento existe na `J_1BDOCTYPES` | Erro | 8B 683 |
| `lv_c32` | 31 | 32 | Direção é 1, 2, 3 ou 4 | Erro | 8B 683 |
| `lv_c33` | 32 | 33 | Sem `MANUAL = 'X'`, todo item precisa de chave de referência (`REFKEY`) | Erro | 8B 684 |
| `lv_c34` | 33 | 34 | Tipo de avaliação existe na `MBEW` (itens com `BWTAR` e material) | Erro | Mensagem de `MBEW_SINGLE_READ` |
| `lv_c35` | 34 | 35 | Centro existe na `T001W` e a área de avaliação dele é igual à `BWKEY` do item | Erro | 8B 683 / 8B 685 |
| `lv_c36` | 35 | 36 | Área de avaliação existe na `T001K` | Erro | 8B 683 |
| `lv_c37` | 36 | 37 | Tipos de imposto das linhas de imposto existem na `J_1BAJ` | Erro | 8B 683 |
| `lv_c38` | 37 | 38 | Período de lançamento aberto (só tipo de documento 5 – estorno) | Erro | 8B 355 |
| `lv_c39` | 38 | 39 | Nenhuma alíquota negativa | Erro | Classe de check |
| `lv_c40` | 39 | 40 | NF-e: número da NF-e preenchido quando há status do documento | Erro | Erro de NF-e |
| `lv_c41` | 40 | 41 | NF-e: protocolo de autorização preenchido quando há status do documento | Erro | Erro de NF-e |
| `lv_c42` | 41 | 42 | NF-e: versão do XML preenchida | Erro | Erro de NF-e |
| `lv_c43` | 42 | 43 | NF-e: código de status da SEFAZ preenchido quando há status do documento | Erro | Erro de NF-e |
| `lv_c44` | 43 | 44 | **Não lida** – checks de alíquota com 4 casas rodam sempre | – | ICC_NF_WRITER 023 / 026 / 027 |
| `lv_c45` | 44 | 45 | **Não lida** – check de `PAUTA_BASE` / `UNIT` roda sempre | – | ICC_NF_WRITER 029 |
| `lv_c46` | 45 | 46 | Situação tributária do item (`TAXSITUATION` / `TAXSITUATIONREG`) existe | Erro | Classe de check |
| `lv_c47` | 46 | 47 | Situação tributária IS do item (`TAXSITUATIONIS`) existe | Erro | Classe de check |

## 5. Pontos de atenção

| # | Ponto | Status |
|---|---|---|
| 1 | **O check string ainda não é usado na criação da NF.** A `BAPI_J_1B_NF_CREATEFROMDATA`, como é chamada hoje no `FORM CREATE_NF`, não recebe check string. Falta definir onde o `lv_nfcheck` será passado. | ⏳ desenvolvimento |
| 2 | Checks que podem não se aplicar a **serviço** (NFS-e): 13 (grupo de mercadorias – o `ZSD_BR_NFSE` não preenche `MATKL` no item), 15 e 28 (NCM), 27 (ICMS/IPI e origem). Confirmar no teste se o padrão já os ignora para itens de ISS ou completa o campo pelo cadastro do material; se não, desligar a variável correspondente. O check 33 não deve dar problema: o programa envia `MANUAL = 'X'` no cabeçalho. | ⏳ teste |
| 3 | Checks 40–43 só valem para NF-e; para NFS-e não têm efeito, mas foram mantidos ligados. | Informativo |
| 4 | Check 01 e posições 44/45 ficam com `X` só para manter o tamanho de 47 posições. | Informativo |
| 5 | O parâmetro `US_DATA` ainda não é usado; o ATC pode avisar. | Informativo |
