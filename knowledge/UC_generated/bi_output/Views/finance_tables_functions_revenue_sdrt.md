---
object_fqn: main.bi_output.finance_tables_functions_revenue_sdrt
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.finance_tables_functions_revenue_sdrt
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 45
row_count: null
generated_at: '2026-06-19T14:35:58Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/finance_tables_functions_revenue_sdrt.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/finance_tables_functions_revenue_sdrt.sql
concept_count: 3
formula_count: 45
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 45
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# finance_tables_functions_revenue_sdrt

> View in `main.bi_output`. 3 business concept(s) in §2; 45 of 45 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.finance_tables_functions_revenue_sdrt` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 45 |
| **Concepts** | 3 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Tue Apr 02 14:17:48 UTC 2024 |

---

## 1. Business Meaning

`finance_tables_functions_revenue_sdrt` is a view in `main.bi_output` that composes a UNION ALL with sign-flipped amount legs (deposit/withdraw composition), 1 JOIN-enriched dimension lookup(s), 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 45 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 45 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Sign-flip leg `SDRTPrep2` (multiplies `SDRT` by -1)
**What**: This subselect contributes the negative-sign leg of a UNION ALL composition — amount columns are multiplied by -1 so the downstream rollup nets to (deposit - withdraw).
**Columns Involved**: `SDRT`
**Rules**:
- `-1 * f.Amount` (sign-flip on amount)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/finance_tables_functions_revenue_sdrt.sql` L110
**Source(s)**: `SDRTPrep`

### 2.2 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.DateRangeID = dr.DateRangeID AND fca.DateID >= dr.FromDateID AND fca.DateID <= dr.ToDateID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/finance_tables_functions_revenue_sdrt.sql` L58
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

### 2.3 Filter on scope `SDRTPrep`: `ActionTypeID = 35`; `IsFeeDividend = 3`
**What**: `WHERE` clause at the top of scope `SDRTPrep` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `ActionTypeID`, `IsFeeDividend`
**Rules**:
- `ActionTypeID = 35`
- `IsFeeDividend = 3`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/finance_tables_functions_revenue_sdrt.sql` L59

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_range`). |
| Sum amounts directly for net flow | Amount columns are already sign-flipped per leg — summing them yields net flow (deposits - withdraws). No need to subset by MIMOAction unless you want gross flow. |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `fsc.DateRangeID = dr.DateRangeID AND fca.DateID >= dr.FromDateID AND fca.DateID <= dr.ToDateID` | Lookup via alias `dr` |

### 3.4 Gotchas

- Scope `SDRTPrep` applies `ActionTypeID = 35`; `IsFeeDividend = 3` unconditionally — rows failing these predicates are NOT in this view's output.
- Sign flip in scope(s) `SDRTPrep2` means summing amount columns nets to (deposit - withdraw). Multiply by -1 again if you want gross withdraw amounts.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `RealCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 1 | Occurred | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 2 | DateID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 3 | GCID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 4 | CountryID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 5 | LabelID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 6 | LanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 7 | VerificationLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 8 | DocsOK | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 9 | PlayerStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 10 | Bankruptcy | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 11 | RiskStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 12 | RiskClassificationID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 13 | CommunicationLanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 14 | PremiumAccount | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 15 | Evangelist | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 16 | GuruStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 17 | RegulationID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 18 | AccountStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 19 | AccountManagerID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 20 | PlayerLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 21 | AccountTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 22 | DateRangeID | LONG | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 23 | IsDepositor | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 24 | PendingClosureStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 25 | DocumentStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 26 | SuitabilityTestStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 27 | MifidCategorizationID | INT | YES | Computed in source (transform kind not classified). Formula: `RealCID , Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , B…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 28 | IsEmailVerified | INT | YES | Computed in source (transform kind not classified). Formula: `, Occurred , Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 29 | IsValidCustomer | INT | YES | Computed in source (transform kind not classified). Formula: `, Amount , DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 30 | DesignatedRegulationID | INT | YES | Computed in source (transform kind not classified). Formula: `, DateID , GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskCla…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 31 | EvMatchStatus | INT | YES | Computed in source (transform kind not classified). Formula: `, GCID , CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 32 | RegionID | INT | YES | Computed in source (transform kind not classified). Formula: `, CountryID , LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , Commun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 33 | PlayerStatusReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `, LabelID , LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 34 | IsCreditReportValidCB | INT | YES | Computed in source (transform kind not classified). Formula: `, LanguageID , VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumA…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 35 | AffiliateID | INT | YES | Computed in source (transform kind not classified). Formula: `, VerificationLevelID , DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evan…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 36 | Email | STRING | YES | Computed in source (transform kind not classified). Formula: `, DocsOK , PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 37 | City | STRING | YES | Computed in source (transform kind not classified). Formula: `, PlayerStatusID , Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID , UpdateD…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 38 | Address | STRING | YES | Computed in source (transform kind not classified). Formula: `, Bankruptcy , RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID , UpdateDate , RegulationI…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 39 | Zip | STRING | YES | Computed in source (transform kind not classified). Formula: `, RiskStatusID , RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID , UpdateDate , RegulationID , AccountSt…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 40 | PhoneNumber | STRING | YES | Computed in source (transform kind not classified). Formula: `, RiskClassificationID , CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID , UpdateDate , RegulationID , AccountStatusID , Accoun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 41 | IsPhoneVerified | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `, CommunicationLanguageID , PremiumAccount , Evangelist , GuruStatusID , UpdateDate , RegulationID , AccountStatusID , AccountManagerID , PlayerLeve…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 42 | PhoneVerificationDateID | STRING | YES | Computed in source (transform kind not classified). Formula: `, PremiumAccount , Evangelist , GuruStatusID , UpdateDate , RegulationID , AccountStatusID , AccountManagerID , PlayerLevelID , AccountTypeID , fs…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 43 | PlayerStatusSubReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `, Evangelist , GuruStatusID , UpdateDate , RegulationID , AccountStatusID , AccountManagerID , PlayerLevelID , AccountTypeID , DateRangeID , I…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 44 | SDRT | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `, Evangelist , GuruStatusID , RegulationID , AccountStatusID , AccountManagerID , PlayerLevelID , AccountTypeID , DateRangeID , IsDepositor , PendingClosureStatusID , D…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`) |

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
main.bi_output.finance_tables_functions_revenue_sdrt   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=45 runtime=45 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

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

*Generated: 2026-06-19 | Concepts: 3 | Formulas: 45 | Tiers: 0 T1, 45 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 45/45 | Source: view_definition*
