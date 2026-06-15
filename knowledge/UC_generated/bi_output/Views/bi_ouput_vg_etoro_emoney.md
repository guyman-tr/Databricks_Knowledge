---
object_fqn: main.bi_output.bi_ouput_vg_etoro_emoney
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_ouput_vg_etoro_emoney
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 18
row_count: null
generated_at: '2026-05-19T15:01:29Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_ouput_vg_etoro_emoney.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_ouput_vg_etoro_emoney.sql
concept_count: 1
formula_count: 18
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 18
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_ouput_vg_etoro_emoney

> View in `main.bi_output`. 1 business concept(s) in §2; 18 of 18 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_ouput_vg_etoro_emoney` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 18 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Aug 25 10:06:12 UTC 2025 |

---

## 1. Business Meaning

`bi_ouput_vg_etoro_emoney` is a view in `main.bi_output` that composes 1 CASE-based classifier flag(s) computed from upstream IDs.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`. Additional upstreams: 10 object(s), listed in §5 Lineage.

Of its 18 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 18 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `Fundingtype_Txtype_7` discriminator: `MIMOPlatform = '      '`, `IsInternalTransfer = 0`, `IsTradeFromIBAN = 0` → set to '           ' else '            '
**What**: Computed flag on `Fundingtype_Txtype_7` set to `'           '` when the predicates below hold, else `'            '`.
**Columns Involved**: `Fundingtype_Txtype_7`
**Rules**:
- `MIMOPlatform = '      '`
- `IsInternalTransfer = 0`
- `IsTradeFromIBAN = 0`
- `IsValidCustomer = 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_ouput_vg_etoro_emoney.sql` bi_output.sql L41-L77
**Source(s)**: `bi_db.bronze_moneytransfer_billing_transfers`, `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`, `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

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
| Filter on discriminator flags | Use `Fundingtype_Txtype_7 = 1`-style filters on the precomputed flag columns (`Fundingtype_Txtype_7`) instead of recomputing the underlying CASE predicates downstream. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MIMO_Ind | STRING | NO | Direct passthrough from upstream. Formula: `aa.Ind`. (Tier 2 — computed in source) |
| 1 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `aa.RealCID`. (Tier 2 — computed in source) |
| 2 | MarketingRegionManualName | STRING | YES | Direct passthrough from upstream. Formula: `aa.MarketingRegionManualName`. (Tier 2 — computed in source) |
| 3 | Country | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 4 | Club | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`) |
| 5 | Regulation | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`) |
| 6 | Date_MIMO | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `Date`. (Tier 2 — from `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`) |
| 7 | EOM_MIMO | DATE | YES | Function call computed in source. Formula: `last_day(Date)`. (Tier 2 — from `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`) |
| 8 | MIMOPlatform | STRING | YES | Direct passthrough from upstream. Formula: `aa.MIMOPlatform`. (Tier 2 — computed in source) |
| 9 | EOM_FTD | DATE | YES | Function call computed in source. Formula: `last_day(FirstDepositDate)`. (Tier 2 — from `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 10 | EOM_Reg | DATE | YES | Function call computed in source. Formula: `last_day(RegisteredReal)`. (Tier 2 — from `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 11 | IsInternalTransfer | INT | YES | Direct passthrough from upstream. Formula: `aa.IsInternalTransfer`. (Tier 2 — computed in source) |
| 12 | IsTradeFromIBAN | INT | YES | Direct passthrough from upstream. Formula: `aa.IsTradeFromIBAN`. (Tier 2 — computed in source) |
| 13 | Currency | STRING | YES | Direct passthrough from upstream. Formula: `Abbreviation`. (Tier 2 — from `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`) |
| 14 | MOP | STRING | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN MIMOPlatform = 'eMoney' AND IsInternalTransfer = 0 AND IsTradeFromIBAN = 0 THEN o.Fundingtype_Txtype_7 …`. (Tier 2 — from `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`) |
| 15 | IsFTD | INT | YES | Direct passthrough from upstream. Formula: `IsPlatformFTD`. (Tier 2 — from `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`) |
| 16 | AmountUSD_MIMO | DECIMAL | YES | Direct passthrough from upstream. Formula: `aa.AmountUSD`. (Tier 2 — computed in source) |
| 17 | Rank_Amount | INT | NO | Window function over upstream rows. Formula: `row_number() over (partition by aa.RealCID order by AmountUSD DESC) Rank_Amount`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | JOIN/UNION | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Transaction.md` |
| `main.bi_db.bronze_moneytransfer_billing_transfers` | JOIN/UNION | `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
... (8 more upstream(s))
        │
        ▼
main.bi_output.bi_ouput_vg_etoro_emoney   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=18 runtime=18 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`)
- **JOIN/UNION upstreams**: 10 additional object(s)
- **Wiki coverage**: 10/10 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 18 | Tiers: 0 T1, 18 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 18/18 | Source: view_definition*
