---
object_fqn: main.bi_output.vg_positions_open_closed_iban_tp
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_positions_open_closed_iban_tp
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 47
row_count: null
generated_at: '2026-06-19T14:36:08Z'
upstreams:
- main.dwh.dim_position
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet
- main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_positions_open_closed_iban_tp.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_positions_open_closed_iban_tp.sql
concept_count: 5
formula_count: 44
tier_breakdown:
  tier1_columns: 1
  tier2_columns: 46
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_positions_open_closed_iban_tp

> View in `main.bi_output`. 5 business concept(s) in §2; 47 of 47 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_positions_open_closed_iban_tp` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 47 |
| **Concepts** | 5 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Wed Nov 19 08:30:36 UTC 2025 |

---

## 1. Business Meaning

`vg_positions_open_closed_iban_tp` is a view in `main.bi_output` that composes 3 CASE-based classifier flag(s) computed from upstream IDs, 2 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.dim_position` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 5 object(s), listed in §5 Lineage.

Of its 47 columns: 1 inherit byte-for-byte from upstream wikis (Tier 1), 46 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsCloseToIBan` computed flag
**What**: Computed flag on `IsCloseToIBan` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCloseToIBan`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positions_open_closed_iban_tp.sql` bi_output.sql L12-L12
**Source(s)**: `main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet`

### 2.2 `IsOpenFromIBan` computed flag
**What**: Computed flag on `IsOpenFromIBan` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsOpenFromIBan`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positions_open_closed_iban_tp.sql` bi_output.sql L13-L13
**Source(s)**: `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet`

### 2.3 `IsEmoneyCustomer` computed flag
**What**: Computed flag on `IsEmoneyCustomer` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsEmoneyCustomer`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positions_open_closed_iban_tp.sql` bi_output.sql L14-L14
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`

### 2.4 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `a.CID = dc.RealCID AND dc.IsValidCustomer = 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positions_open_closed_iban_tp.sql` L16
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.5 Dim lookup via alias `e` → `gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `a.CID=e.CID and e.IsValidETM=1 and e.GCID_Unique_Count=1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_positions_open_closed_iban_tp.sql` L18
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`

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
| Filter on discriminator flags | Use `IsCloseToIBan = 1`-style filters on the precomputed flag columns (`IsCloseToIBan`, `IsEmoneyCustomer`, `IsOpenFromIBan`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `a.CID = dc.RealCID AND dc.IsValidCustomer = 1` | Lookup via alias `dc` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `a.CID=e.CID and e.IsValidETM=1 and e.GCID_Unique_Count=1` | Lookup via alias `e` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | LONG | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 1 | CID | INT | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 2 | InstrumentID | INT | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 3 | OpenDateID | INT | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 4 | CloseDateID | INT | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 5 | PlatformTypeID | BYTE | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 6 | Amount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 7 | Volume | INT | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 8 | NetProfit | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 9 | Commission | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 10 | Leverage | INT | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 11 | RegulationIDOnOpen | INT | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 12 | PositionUpdateDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `PositionID, CID, InstrumentID, OpenDateID, CloseDateID, PlatformTypeID, Amount, Volume, NetProfit, Commission, Leverage, RegulationIDOnOpen, UpdateDate`. (Tier 2 — from `main.dwh.dim_position`) |
| 13 | RealCID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 14 | CountryID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 15 | LanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 16 | PlayerLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 17 | AccountStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 18 | AccountTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 19 | RegulationID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 20 | RiskStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 21 | RiskClassificationID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 22 | IsValidCustomer | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 23 | PlayerStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 24 | VerificationLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 25 | RegionID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 26 | IsDepositor | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 27 | FirstDepositDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 28 | AccountManagerID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 29 | PremiumAccount | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 30 | AffiliateID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 31 | CampaignID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 32 | SubChannelID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID, CountryID, LanguageID, PlayerLevelID, AccountStatusID, AccountTypeID, RegulationID, RiskStatusID, RiskClassificationID, IsValidCustomer, PlayerStatusID, Ve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 33 | LabelID | INT | YES | Computed in source (transform kind not classified). Formula: `LabelID, RegisteredReal, RegisteredDemo, ReferralID, UpdateDate`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 34 | RegisteredReal | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `LabelID, RegisteredReal, RegisteredDemo, ReferralID, UpdateDate`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 35 | RegisteredDemo | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `LabelID, RegisteredReal, RegisteredDemo, ReferralID, UpdateDate`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 36 | ReferralID | INT | YES | Computed in source (transform kind not classified). Formula: `LabelID, RegisteredReal, RegisteredDemo, ReferralID, UpdateDate`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 37 | CustomerUpdateDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `LabelID, RegisteredReal, RegisteredDemo, ReferralID, UpdateDate`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 38 | InstrumentType | STRING | YES | Computed in source (transform kind not classified). Formula: `InstrumentType, SellCurrency, InstrumentDisplayName`. (Tier 2 — from `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 39 | SellCurrency | STRING | YES | Computed in source (transform kind not classified). Formula: `InstrumentType, SellCurrency, InstrumentDisplayName`. (Tier 2 — from `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 40 | InstrumentDisplayName | STRING | YES | Computed in source (transform kind not classified). Formula: `InstrumentType, SellCurrency, InstrumentDisplayName`. (Tier 2 — from `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 41 | IsCloseToIBan | INT | NO | `IsCloseToIBan` computed flag. Formula: `CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet`) |
| 42 | IsOpenFromIBan | INT | NO | `IsOpenFromIBan` computed flag. Formula: `CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet`) |
| 43 | AccountCreateDate | TIMESTAMP | YES | Date portion of AccountCreateTime. DWH-derived: CAST(AccountCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 44 | AccountSubProgram | STRING | YES | Sub-program display name for AccountSubProgramID, resolved from eMoney_dbo.SubPrograms (16 active programs across UK/EU/AUS regions). (Tier 2 — SP_eMoney_Dim_Account) |
| 45 | AccountSubProgramID | INT | YES | Specific sub-program variant: 1-16 (e.g., Card Premium UK, IBAN EU Green). FK to eMoney_dbo.SubPrograms. NULL if not yet assigned to a specific variant. DWH note: current sub-program; ISNULL(latest FiatAccountsProperties record, original FiatAccount.SubProgramId). (Tier 1 — dbo.FiatAccount) |
| 46 | IsEmoneyCustomer | INT | NO | `IsEmoneyCustomer` computed flag. Formula: `AccountCreateDate, AccountSubProgram, AccountSubProgramID, case when CID is not null then 1 else 0 end`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.dim_position` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | JOIN/UNION | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.dim_position
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
... (3 more upstream(s))
        │
        ▼
main.bi_output.vg_positions_open_closed_iban_tp   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=47 runtime=47 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.dim_position` (wiki: `(no wiki)`)
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

*Generated: 2026-06-19 | Concepts: 5 | Formulas: 44 | Tiers: 1 T1, 46 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 47/47 | Source: view_definition*
