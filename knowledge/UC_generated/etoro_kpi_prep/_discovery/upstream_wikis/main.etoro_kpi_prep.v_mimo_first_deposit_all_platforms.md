---
object_fqn: main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:04:41Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
- main.emoney.bronze_fiatdwhdb_dbo_fiattransactions
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_first_deposit_all_platforms.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_first_deposit_all_platforms.sql
concept_count: 9
formula_count: 6
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 4
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_mimo_first_deposit_all_platforms

> View in `main.etoro_kpi_prep`. 9 business concept(s) in §2; 6 of 6 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 6 |
| **Concepts** | 9 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:11:40 UTC 2026 |

---

## 1. Business Meaning

`v_mimo_first_deposit_all_platforms` is a view in `main.etoro_kpi_prep` that composes 5 CASE-based classifier flag(s) computed from upstream IDs, 4 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`. Additional upstreams: 4 object(s), listed in §5 Lineage.

Of its 6 columns: 2 inherit byte-for-byte from upstream wikis (Tier 1), 4 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsIBANTrade` discriminator: `ActionTypeID = 44` → set to 1 else 0
**What**: Computed flag on `IsIBANTrade` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsIBANTrade`
**Rules**:
- `ActionTypeID = 44`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_first_deposit_all_platforms.sql` etoro_kpi_prep.sql L14-L14
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`

### 2.2 `IsIBANQuickTransfer` discriminator: `MoveMoneyReasonID = 6` → set to 1 else 0
**What**: Computed flag on `IsIBANQuickTransfer` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsIBANQuickTransfer`
**Rules**:
- `MoveMoneyReasonID = 6`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_first_deposit_all_platforms.sql` etoro_kpi_prep.sql L15-L15
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`

### 2.3 `IsCryptoToFiat` discriminator: `TxTypeID = 14` (CryptoToFiat per upstream wiki) → set to 1 else 0
**What**: Computed flag on `IsCryptoToFiat` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCryptoToFiat`
**Rules**:
- `TxTypeID = 14` (CryptoToFiat per upstream wiki)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_first_deposit_all_platforms.sql` etoro_kpi_prep.sql L37-L37
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`

### 2.4 `FTDPlatform` discriminator: `FTDPlatformID = 3`, `FTDPlatformID = 1`, `FTDPlatformID = 1` → set to '         ' else '  '
**What**: Computed flag on `FTDPlatform` set to `'         '` when the predicates below hold, else `'  '`.
**Columns Involved**: `FTDPlatform`
**Rules**:
- `FTDPlatformID = 3`
- `FTDPlatformID = 1`
- `FTDPlatformID = 1`
- `FTDPlatformID = 2`
- `FTDPlatformID = 3`
- `FTDPlatformID = 4`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_first_deposit_all_platforms.sql` etoro_kpi_prep.sql L65-L81
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`, `main.emoney.bronze_fiatdwhdb_dbo_fiattransactions`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.5 `IsC2USD` computed flag
**What**: Computed flag on `IsC2USD` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsC2USD`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_first_deposit_all_platforms.sql` etoro_kpi_prep.sql L88-L88
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`

### 2.6 Filter on scope `new_tp`: `ActionTypeID = 7`; `IsFTD = 1`
**What**: `WHERE` clause at the top of scope `new_tp` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `ActionTypeID`, `IsFTD`
**Rules**:
- `ActionTypeID = 7`
- `IsFTD = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_first_deposit_all_platforms.sql` L17

### 2.7 Filter on scope `new_iban`: `MoneyMoveDirection = '       '`; `TxStatusID = 2`
**What**: `WHERE` clause at the top of scope `new_iban` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `MoneyMoveDirection`, `TxStatusID`
**Rules**:
- `MoneyMoveDirection = '       '`
- `TxStatusID = 2`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_first_deposit_all_platforms.sql` L44

### 2.8 Filter on scope `c2usd`: `IsFTD = 1`; `FundingTypeID = 27`
**What**: `WHERE` clause at the top of scope `c2usd` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `IsFTD`, `FundingTypeID`
**Rules**:
- `IsFTD = 1`
- `FundingTypeID = 27`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_first_deposit_all_platforms.sql` L55

### 2.9 Filter on scope `dimcust`: `FirstDepositDate >= '          '`
**What**: `WHERE` clause at the top of scope `dimcust` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `FirstDepositDate`
**Rules**:
- `FirstDepositDate >= '          '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_first_deposit_all_platforms.sql` L101

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
| Filter on discriminator flags | Use `FTDPlatform = 1`-style filters on the precomputed flag columns (`FTDPlatform`, `IsC2USD`, `IsCryptoToFiat`, `IsIBANQuickTransfer`) instead of recomputing the underlying CASE predicates downstream. |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- Scope `new_tp` applies `ActionTypeID = 7`; `IsFTD = 1` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `new_iban` applies `MoneyMoveDirection = '       '`; `TxStatusID = 2` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `c2usd` applies `IsFTD = 1`; `FundingTypeID = 27` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `dimcust` applies `FirstDepositDate >= '          '` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | INT | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 1 | DepositID | LONG | YES | Deposit transaction reference on inbound money rows (`NULL` off-deposit actions). (Tier 1 — History.Credit) |
| 2 | FirstDepositDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `FirstDepositDate`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 3 | FirstDepositAmount | DECIMAL | YES | Direct passthrough from upstream. Formula: `FirstDepositAmount`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 4 | FTDPlatform | STRING | NO | `FTDPlatform` discriminator: `FTDPlatformID = 3`, `FTDPlatformID = 1`, `FTDPlatformID = 1` → set to '         ' else '  '. Formula: `-- FTDPlatform name mapping CASE WHEN FTDPlatformID = 1 THEN 'TradingPlatform' WHEN FTDPlatformID = 2 THEN 'Options' WHEN FTDPlatformID = 3 THEN '…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 5 | FTDPlatformID | STRING | YES | Direct passthrough from upstream. Formula: `FTDPlatformID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | JOIN/UNION | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Fact_Transaction_Status.md` |
| `main.emoney.bronze_fiatdwhdb_dbo_fiattransactions` | JOIN/UNION | `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatTransactions.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
main.emoney.bronze_fiatdwhdb_dbo_fiattransactions
... (2 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms   ←── this object
        │
        ▼
main.etoro_kpi_prep.v_mimo_allplatforms
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=6 runtime=6 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`)
- **JOIN/UNION upstreams**: 4 additional object(s)
- **Wiki coverage**: 4/4 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep.v_mimo_allplatforms`

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

*Generated: 2026-05-19 | Concepts: 9 | Formulas: 6 | Tiers: 2 T1, 4 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: view_definition*
