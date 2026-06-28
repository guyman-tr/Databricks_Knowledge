---
object_fqn: main.bi_output.vg_fact_billingdepost_forgenie
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_fact_billingdepost_forgenie
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 21
row_count: null
generated_at: '2026-06-19T14:36:05Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot
- main.general.bronze_etoro_dictionary_cardtype
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_billingdepost_forgenie.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_billingdepost_forgenie.sql
concept_count: 4
formula_count: 21
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 14
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_fact_billingdepost_forgenie

> View in `main.bi_output`. 4 business concept(s) in §2; 21 of 21 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_fact_billingdepost_forgenie` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 21 |
| **Concepts** | 4 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Wed Apr 15 15:13:07 UTC 2026 |

---

## 1. Business Meaning

`vg_fact_billingdepost_forgenie` is a view in `main.bi_output` that composes 4 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md`. Additional upstreams: 5 object(s), listed in §5 Lineage.

Of its 21 columns: 7 inherit byte-for-byte from upstream wikis (Tier 1), 14 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `cur` → `gold_sql_dp_prod_we_dwh_dbo_dim_currency`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_currency` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fd.CurrencyID = cur.CurrencyID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_billingdepost_forgenie.sql` L63
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`

### 2.2 Dim lookup via alias `ps` → `gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fd.PaymentStatusID = ps.PaymentStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_billingdepost_forgenie.sql` L65
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus`

### 2.3 Dim lookup via alias `depot` → `gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fd.DepotID = depot.DepotID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_billingdepost_forgenie.sql` L67
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`

### 2.4 Dim lookup via alias `x` → `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fd.FundingTypeID=x.FundingTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_billingdepost_forgenie.sql` L71
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_currency`, `gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus`, `gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`, `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | `fd.CurrencyID = cur.CurrencyID` | Lookup via alias `cur` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` | `fd.PaymentStatusID = ps.PaymentStatusID` | Lookup via alias `ps` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | `fd.DepotID = depot.DepotID` | Lookup via alias `depot` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | `fd.FundingTypeID=x.FundingTypeID` | Lookup via alias `x` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Passthrough `d.CID` from `DWH_staging.etoro_Billing_Deposit`. Production `Billing.Deposit.CID` (same semantics as upstream wiki §4). (Tier 1 — Billing.Deposit) |
| 1 | DepositID | INT | YES | Passthrough `d.DepositID`. `HASH(DepositID)` distribution + clustered index. (Tier 1 — Billing.Deposit) |
| 2 | FundingType | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`) |
| 3 | ModificationDate | TIMESTAMP | YES | Passthrough `d.ModificationDate`. ETL incremental watermark. (Tier 1 — Billing.Deposit) |
| 4 | AmountUSD | DECIMAL | YES | Second INSERT: `Amount * ExchangeRate AS AmountUSD` from `Ext_FBD_Fact_BillingDeposit` snapshot (post-cap `Amount`). (Tier 2 — Billing.Deposit.Amount/ExchangeRate) |
| 5 | Currency | STRING | YES | Direct passthrough from upstream. Formula: `Abbreviation`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`) |
| 6 | BaseExchangeRate | DECIMAL | YES | Passthrough `d.BaseExchangeRate`. Upstream: reference rate before fee markup. (Tier 1 — Billing.Deposit) |
| 7 | IsFTD | INT | YES | ETL `ISNULL(CAST(d.IsFTD AS int),0)` (bit→int). FTD rules upstream wiki §2.2. (Tier 1 — Billing.Deposit) |
| 8 | PaymentStatus | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus`) |
| 9 | Provider | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ====================== -- Funding / provider -- ====================== Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot`) |
| 10 | DepotID | INT | YES | Passthrough `d.DepotID`. (Tier 1 — Billing.Deposit) |
| 11 | PSPCodeAsString | STRING | YES | `[DWH_dbo].[ExtractXMLValue]('PSPCodeAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 12 | BinCodeAsString | STRING | YES | `[DWH_dbo].[ExtractXMLValue]('BinCodeAsString',f.FundingData)`. Downstream `SP_Fact_BillingDeposit`: `CAST(BinCodeAsString AS INT) = Dim_CountryBin.BinCode`. (Tier 2 — Billing.Funding.FundingData) |
| 13 | CardType | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_cardtype`) |
| 14 | CardSubType | STRING | YES | `UPDATE fbw SET CardCategory = cb.CardCategory` same JOIN as `BankName` (`SP_Fact_BillingDeposit`). (Tier 2 — Dim_CountryBin.CardCategory) |
| 15 | BankName | STRING | YES | `[DWH_dbo].[ExtractXMLValue]('BankNameAsString',f.FundingData)` (XML). Distinct from `BankName` column enriched from `Dim_CountryBin`. (Tier 2 — Billing.Funding.FundingData) |
| 16 | DeclineReason | STRING | YES | `[DWH_dbo].[ExtractXMLValue]('ResponseMessageAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 17 | RREReason | STRING | YES | `[DWH_dbo].[ExtractXMLValue]('ErrorCodeAsString',d.PaymentData)`. (Tier 2 — Billing.Deposit.PaymentData) |
| 18 | ThreeDSResponseJson | STRING | YES | `[DWH_dbo].[ExtractXMLValue]('ThreeDsAsJson',d.PaymentData)`. Raw 3DS payload JSON string. (Tier 2 — Billing.Deposit.PaymentData) |
| 19 | ProtocolMIDSettingsID | INT | YES | Passthrough `d.ProtocolMIDSettingsID`. (Tier 1 — Billing.Deposit) |
| 20 | TransactionIDAsString | STRING | YES | `[DWH_dbo].[ExtractXMLValue]('TransactionIDAsString',d.PaymentData)`. Distinct from `Billing.Deposit.TransactionID` (internal 6-char) — this is provider string from XML. (Tier 2 — Billing.Deposit.PaymentData) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PaymentStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md` |
| `main.general.bronze_etoro_dictionary_cardtype` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
... (3 more upstream(s))
        │
        ▼
main.bi_output.vg_fact_billingdepost_forgenie   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=21 runtime=21 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md`)
- **JOIN/UNION upstreams**: 5 additional object(s)
- **Wiki coverage**: 5/5 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-06-19 | Concepts: 4 | Formulas: 21 | Tiers: 7 T1, 14 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 21/21 | Source: view_definition*
