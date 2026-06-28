---
object_fqn: main.bi_output.finance_tables_functions_revenue_trading_fees
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.finance_tables_functions_revenue_trading_fees
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 46
row_count: null
generated_at: '2026-06-19T14:35:59Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/finance_tables_functions_revenue_trading_fees.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/finance_tables_functions_revenue_trading_fees.sql
concept_count: 3
formula_count: 46
tier_breakdown:
  tier1_columns: 1
  tier2_columns: 45
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# finance_tables_functions_revenue_trading_fees

> View in `main.bi_output`. 3 business concept(s) in §2; 46 of 46 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.finance_tables_functions_revenue_trading_fees` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 46 |
| **Concepts** | 3 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Tue Apr 02 14:30:50 UTC 2024 |

---

## 1. Business Meaning

`finance_tables_functions_revenue_trading_fees` is a view in `main.bi_output` that composes a UNION ALL with sign-flipped amount legs (deposit/withdraw composition), 1 CASE-based classifier flag(s) computed from upstream IDs, 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 46 columns: 1 inherit byte-for-byte from upstream wikis (Tier 1), 45 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `TradingFeeType` discriminator: `ActionTypeID = 36`, `CompensationReasonID = 117`, `ActionTypeID = 36` → set to '         ' else '  '
**What**: Computed flag on `TradingFeeType` set to `'         '` when the predicates below hold, else `'  '`.
**Columns Involved**: `TradingFeeType`
**Rules**:
- `ActionTypeID = 36`
- `CompensationReasonID = 117`
- `ActionTypeID = 36`
- `CompensationReasonID = 118`
- `ActionTypeID = 35`
- `IsFeeDividend = 4`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/finance_tables_functions_revenue_trading_fees.sql` bi_output.sql L10-L13
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`

### 2.2 Sign-flip leg `main` (multiplies `TradingFee` by -1)
**What**: This subselect contributes the negative-sign leg of a UNION ALL composition — amount columns are multiplied by -1 so the downstream rollup nets to (deposit - withdraw).
**Columns Involved**: `TradingFee`
**Rules**:
- `-1 * fca.Amount` (sign-flip on amount)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/finance_tables_functions_revenue_trading_fees.sql` L9
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

### 2.3 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.DateRangeID = dr.DateRangeID AND fca.DateID >= dr.FromDateID AND fca.DateID <= dr.ToDateID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/finance_tables_functions_revenue_trading_fees.sql` L60
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

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
| Filter on discriminator flags | Use `TradingFeeType = 1`-style filters on the precomputed flag columns (`TradingFeeType`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_range`). |
| Sum amounts directly for net flow | Amount columns are already sign-flipped per leg — summing them yields net flow (deposits - withdraws). No need to subset by MIMOAction unless you want gross flow. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `fsc.DateRangeID = dr.DateRangeID AND fca.DateID >= dr.FromDateID AND fca.DateID <= dr.ToDateID` | Lookup via alias `dr` |

### 3.4 Gotchas

- Sign flip in scope(s) `main` means summing amount columns nets to (deposit - withdraw). Multiply by -1 again if you want gross withdraw amounts.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | INT | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 1 | TradingFee | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `RealCID , -1 * Amount`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 2 | TradingFeeType | STRING | NO | `TradingFeeType` discriminator: `ActionTypeID = 36`, `CompensationReasonID = 117`, `ActionTypeID = 36` → set to '         ' else '  '. Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 3 | DateID | INT | YES | **`Occurred`** → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) |
| 4 | GCID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 5 | CountryID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 6 | LabelID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 7 | LanguageID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 8 | VerificationLevelID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 9 | DocsOK | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 10 | PlayerStatusID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 11 | Bankruptcy | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 12 | RiskStatusID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 13 | RiskClassificationID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 14 | CommunicationLanguageID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 15 | PremiumAccount | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 16 | Evangelist | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 17 | GuruStatusID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 18 | UpdateDate | TIMESTAMP | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 19 | RegulationID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 20 | AccountStatusID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 21 | AccountManagerID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 22 | PlayerLevelID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 23 | AccountTypeID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 24 | DateRangeID | LONG | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 25 | IsDepositor | BOOLEAN | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 26 | PendingClosureStatusID | INT | YES | Computed flag (CASE expression in source). Formula: `RealCID , -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 27 | DocumentStatusID | INT | YES | Computed flag (CASE expression in source). Formula: `, -1 * Amount AS TradingFee , CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID = 118 THEN 'Sp…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 28 | SuitabilityTestStatusID | INT | YES | Computed flag (CASE expression in source). Formula: `, CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN 'Administrationfee' WHEN ActionTypeID = 36 AND CompensationReasonID = 118 THEN 'SpotPriceAdjustment' WHEN Acti…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 29 | MifidCategorizationID | INT | YES | Computed in source (transform kind not classified). Formula: `WHEN ActionTypeID = 36 AND CompensationReasonID = 118 THEN 'SpotPriceAdjustment' WHEN ActionTypeID = 35 AND IsFeeDividend = 4 THEN 'TicketFee' ELSE 'NA' END AS TradingFeeType , fc…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 30 | IsEmailVerified | INT | YES | Computed in source (transform kind not classified). Formula: `WHEN ActionTypeID = 35 AND IsFeeDividend = 4 THEN 'TicketFee' ELSE 'NA' END AS TradingFeeType , DateID , GCID , CountryID , LabelID , LanguageID , Verifica…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 31 | IsValidCustomer | INT | YES | Computed in source (transform kind not classified). Formula: `ELSE 'NA' END AS TradingFeeType , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 32 | DesignatedRegulationID | INT | YES | Computed in source (transform kind not classified). Formula: `, DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskCla…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 33 | EvMatchStatus | INT | YES | Computed in source (transform kind not classified). Formula: `, GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 34 | RegionID | INT | YES | Computed in source (transform kind not classified). Formula: `, CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , Commun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 35 | PlayerStatusReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `, LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 36 | IsCreditReportValidCB | INT | YES | Computed in source (transform kind not classified). Formula: `, LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumA…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 37 | AffiliateID | INT | YES | Computed in source (transform kind not classified). Formula: `, VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evan…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 38 | Email | STRING | YES | Computed in source (transform kind not classified). Formula: `, DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 39 | City | STRING | YES | Computed in source (transform kind not classified). Formula: `, PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID , UpdateD…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 40 | Address | STRING | YES | Computed in source (transform kind not classified). Formula: `, Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID , UpdateDate , RegulationI…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 41 | Zip | STRING | YES | Computed in source (transform kind not classified). Formula: `, RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID , UpdateDate , RegulationID , AccountSt…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 42 | PhoneNumber | STRING | YES | Computed in source (transform kind not classified). Formula: `, RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID , UpdateDate , RegulationID , AccountStatusID , Accoun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 43 | IsPhoneVerified | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `, CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID , UpdateDate , RegulationID , AccountStatusID , AccountManagerID , PlayerLeve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 44 | PhoneVerificationDateID | STRING | YES | Computed in source (transform kind not classified). Formula: `, PremiumAccount , Evangelist , GuruStatusID , UpdateDate , RegulationID , AccountStatusID , AccountManagerID , PlayerLevelID , AccountTypeID , fs…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 45 | PlayerStatusSubReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `, Evangelist , GuruStatusID , UpdateDate , RegulationID , AccountStatusID , AccountManagerID , PlayerLevelID , AccountTypeID , DateRangeID , I…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
        │
        ▼
main.bi_output.finance_tables_functions_revenue_trading_fees   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=46 runtime=46 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 3 | Formulas: 46 | Tiers: 1 T1, 45 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 46/46 | Source: view_definition*
