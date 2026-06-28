---
object_fqn: main.bi_output.vg_payments_mimo_allplatformddr_genienew
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_payments_mimo_allplatformddr_genienew
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 14
row_count: null
generated_at: '2026-06-19T14:36:07Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype / main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
- main.bi_db.bronze_moneytransfer_billing_transfers
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_payments_mimo_allplatformddr_genienew.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_payments_mimo_allplatformddr_genienew.sql
concept_count: 6
formula_count: 14
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 12
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_payments_mimo_allplatformddr_genienew

> View in `main.bi_output`. 6 business concept(s) in §2; 14 of 14 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_payments_mimo_allplatformddr_genienew` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 14 |
| **Concepts** | 6 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Thu May 14 13:10:51 UTC 2026 |

---

## 1. Business Meaning

`vg_payments_mimo_allplatformddr_genienew` is a view in `main.bi_output` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 5 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md`. Additional upstreams: 10 object(s), listed in §5 Lineage.

Of its 14 columns: 2 inherit byte-for-byte from upstream wikis (Tier 1), 12 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `Fundingtype_Txtype_7` discriminator: `IsInternalTransfer = 1`, `MIMOPlatform = '      '`, `IsInternalTransfer = 0` → set to '           ' else '            '
**What**: Computed flag on `Fundingtype_Txtype_7` set to `'           '` when the predicates below hold, else `'            '`.
**Columns Involved**: `Fundingtype_Txtype_7`
**Rules**:
- `IsInternalTransfer = 1`
- `MIMOPlatform = '      '`
- `IsInternalTransfer = 0`
- `IsValidCustomer = 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_payments_mimo_allplatformddr_genienew.sql` bi_output.sql L19-L52
**Source(s)**: `main.bi_db.bronze_moneytransfer_billing_transfers`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.2 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.DateRangeID = dr.DateRangeID       AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_payments_mimo_allplatformddr_genienew.sql` L35
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

### 2.3 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_payments_mimo_allplatformddr_genienew.sql` L38
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.4 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_payments_mimo_allplatformddr_genienew.sql` L40
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.5 Dim lookup via alias `dr1` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dr1.DWHRegulationID = fsc.RegulationID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_payments_mimo_allplatformddr_genienew.sql` L42
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.6 Dim lookup via alias `dft` → `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `bddfmap.FundingTypeID = dft.FundingTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_payments_mimo_allplatformddr_genienew.sql` L44
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
| Filter on discriminator flags | Use `Fundingtype_Txtype_7 = 1`-style filters on the precomputed flag columns (`Fundingtype_Txtype_7`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_range`, `gold_sql_dp_prod_we_dwh_dbo_dim_country`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `fsc.DateRangeID = dr.DateRangeID       AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID` | Lookup via alias `dr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `fsc.CountryID = dc.CountryID` | Lookup via alias `dc` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `fsc.PlayerLevelID = dpl.PlayerLevelID` | Lookup via alias `dpl` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `dr1.DWHRegulationID = fsc.RegulationID` | Lookup via alias `dr1` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | `bddfmap.FundingTypeID = dft.FundingTypeID` | Lookup via alias `dft` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MIMOAction | STRING | YES | Stable label `'Deposit'` or `'Withdraw'` from UNION halves. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 1 | TransactionID | INT | YES | `DepositID` for deposits (`ActionTypeID` 7/44) OR `WithdrawPaymentID` for withdraw rows (`ActionTypeID` 8/45). ROW_NUMBER dedupe trims duplicate `(MIMOAction, TransactionID)` pairs (`BI_DB_DDR_Fact_MIMO_Trading_Platform` lineage baseline). **AllPlatforms transforms:** `CAST(f.TransactionID AS varchar(50))` persisted into `INT` from `#final`; `UPDATE #final SET TransactionID=NULL WHERE MIMOPlatform='Options'`; Options **`INSERT`** uses literal `0 AS TransactionID`; MoneyFarm literals `0` with outer **`isnull(TransactionID,-1)`** guard. **Not all platforms joinable naïvely.** (Tier 2 — Fact_CustomerAction) |
| 2 | RealCID | INT | YES | Global Real Customer Identifier on the ledger row (`fca.RealCID`). (Tier 1 — Customer.CustomerStatic) |
| 3 | MarketingRegionManualName | STRING | YES | Direct passthrough from upstream. Formula: `MarketingRegionManualName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 4 | Country | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 5 | Club | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`) |
| 6 | Regulation | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`) |
| 7 | Date_MIMO | TIMESTAMP | YES | Calendar counterpart to `DateID`; **`INSERT`** uses `@date AS [Date]` for **`#final` rows**; **`MoneyFarm`** uses `CAST(gf.FirstDepositDate AS date)`. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 8 | MIMOPlatform | STRING | YES | **ETL literals** `'TradingPlatform'`, `'eMoney'`, `'Options'`, `'MoneyFarm'` (see §2.1). Jan‑2026 sample distribution on single day partition enumerated in §1. **(Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms)** |
| 9 | IsInternalTransfer | INT | YES | `CASE WHEN FundingTypeID = 33 THEN 1 ELSE 0` (deposit branch on `fbd.FundingTypeID`; withdraw branch on `fbw.FundingTypeID_Funding`). Mirrors IBAN/quick-transfer interplay described in changelog. **`INSERT ISNULL`; Options inherits `bddfmop.IsInternalTransfer`; MoneyFarm literal `0`.** **(Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform)** |
| 10 | Currency | STRING | YES | Ticker symbol (`dc.Abbreviation`) joined on `CurrencyID`/`ProcessCurrencyID`. `"USD","EUR"` forex; equities/crypto codes per dictionary. Passthrough from `Dim_Currency`. **`MoneyFarm` literal `'GBP'`**. **(Tier 1 — Dictionary.Currency)** |
| 11 | FundingType | STRING | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN IsInternalTransfer = 1 THEN 'internal transfer - etoromoney' WHEN MIMOPlatform = 'eMoney' AND IsInternalTransfer = 0 THEN o.Fundingtype_…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`) |
| 12 | IsGlobalFTD | INT | YES | **Primary path (#final INSERT):** `CASE WHEN f.RealCID IS NOT NULL THEN 1 ELSE 0` after `LEFT JOIN #globalFTDs f` on **`m.MIMOAction='Deposit' AND m.RealCID=f.RealCID AND m.IsFTD=1 AND m.FTDPlatformID=f.FTDPlatformID`** where **`f` originates from **`BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms(0)`** ( **`#globalFTDs`** ). **MoneyFarm synthetic rows forced `1`.** **`INSERT ISNULL` + recovery UPDATE overlays.** **`Options`** second INSERT **`SELECT bddfmop.IsGlobalFTD` (no `#globalFTDs` JOIN in that block). Interpret per **`Function_MIMO_First_Deposit_All_Platforms` §1 business meaning**: date‑routed spine across IBAN / TP extracts with **`REMOVE_BAD_FTDS`** handling. **(Tier 2 — Function_MIMO_First_Deposit_All_Platforms / SP_DDR_Fact_Fact_MIMO_AllPlatforms)** |
| 13 | AmountUSD_MIMO | DECIMAL | YES | `fca.Amount` from `Fact_CustomerAction WHERE ActionTypeID IN (7,44)` (deposits) or `IN (8,45)` (withdrawals) at `@dateID`. **AllPlatforms:** passthrough **`#final`** (see sibling facts); **`MoneyFarm`** uses `gf.FirstDepositAmount` (**`#moneyfarmFTDs`**). **eMoney negatives** retained from sibling negatives for withdrawals (**see **`BI_DB_DDR_Fact_MIMO_eMoney_Platform.md §2.5`**)**. (Tier 2 — Fact_CustomerAction) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype / main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | JOIN/UNION | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Transaction.md` |
| `main.bi_db.bronze_moneytransfer_billing_transfers` | JOIN/UNION | `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
... (8 more upstream(s))
        │
        ▼
main.bi_output.vg_payments_mimo_allplatformddr_genienew   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=14 runtime=14 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md`)
- **JOIN/UNION upstreams**: 10 additional object(s)
- **Wiki coverage**: 9/10 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 6 | Formulas: 14 | Tiers: 2 T1, 12 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 14/14 | Source: view_definition*
