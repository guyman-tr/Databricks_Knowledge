---
object_fqn: main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 26
row_count: null
generated_at: '2026-06-19T14:36:06Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_snapshotcustomer_for_emoney_genie.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_snapshotcustomer_for_emoney_genie.sql
concept_count: 3
formula_count: 26
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 26
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_fact_snapshotcustomer_for_emoney_genie

> View in `main.bi_output`. 3 business concept(s) in §2; 26 of 26 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 26 |
| **Concepts** | 3 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Sun Jan 04 12:57:19 UTC 2026 |

---

## 1. Business Meaning

`vg_fact_snapshotcustomer_for_emoney_genie` is a view in `main.bi_output` that composes 3 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md`. Additional upstreams: 3 object(s), listed in §5 Lineage.

Of its 26 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 26 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `b` → `gold_sql_dp_prod_we_dwh_dbo_dim_range`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_range` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `a.DateRangeID = b.DateRangeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_snapshotcustomer_for_emoney_genie.sql` L48
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`

### 2.2 Dim lookup via alias `c` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `a.PlayerLevelID = c.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_snapshotcustomer_for_emoney_genie.sql` L50
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.3 Dim lookup via alias `d` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `a.CountryID=d.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_fact_snapshotcustomer_for_emoney_genie.sql` L52
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_range`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `gold_sql_dp_prod_we_dwh_dbo_dim_country`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | `a.DateRangeID = b.DateRangeID` | Lookup via alias `b` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `a.PlayerLevelID = c.PlayerLevelID` | Lookup via alias `c` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `a.CountryID=d.CountryID` | Lookup via alias `d` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDateID | INT | YES | Direct passthrough from upstream. Formula: `FromDateID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`) |
| 1 | ToDateID | INT | YES | Direct passthrough from upstream. Formula: `ToDateID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`) |
| 2 | GCID | INT | YES | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 — via Fact_SnapshotCustomer) |
| 3 | CID | INT | YES | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 — via Fact_SnapshotCustomer) |
| 4 | CountryID_FromDate_ToDate | INT | YES | Customer's registered country. FK to Dim_Country. Key filter for valid customer segmentation. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 5 | RegionID_FromDate_ToDate | INT | YES | Direct passthrough from upstream. Formula: `RegionID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 6 | RegulationID_FromDate_ToDate | INT | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 — via Fact_SnapshotCustomer) |
| 7 | LanguageID_FromDate_ToDate | INT | YES | Customer's preferred interface language. FK to Dim_Language. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 8 | CommunicationLanguageID_FromDate_ToDate | INT | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 — via Fact_SnapshotCustomer) |
| 9 | VerificationLevelID_FromDate_ToDate | INT | YES | KYC verification level. FK to Dim_VerificationLevel. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 10 | PlayerStatusID_FromDate_ToDate | INT | YES | Customer lifecycle status. FK to Dim_PlayerStatus. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 11 | RiskStatusID_FromDate_ToDate | INT | YES | Customer risk assessment status. FK to Dim_RiskStatus. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 12 | RiskClassificationID_FromDate_ToDate | INT | YES | Risk classification tier for compliance. FK to Dim_RiskClassification. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 13 | AccountStatusID_FromDate_ToDate | INT | YES | Account enabled/suspended status. FK to Dim_AccountStatus. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 14 | IsValidCustomer_FromDate_ToDate | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 15 | IsEmailVerified_FromDate_ToDate | INT | YES | Direct passthrough from upstream. Formula: `IsEmailVerified`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 16 | IsPhoneVerified_FromDate_ToDate | BOOLEAN | YES | Direct passthrough from upstream. Formula: `IsPhoneVerified`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 17 | PlayerLevelID_FromDate_ToDate | INT | YES | Account tier (4=demo, other=real tiers). FK to Dim_PlayerLevel. Critical for IsValidCustomer. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 18 | Club_FromDate_ToDate | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`) |
| 19 | AccountTypeID_FromDate_ToDate | INT | YES | Account type (e.g., 7=Employee, 9=excluded). FK to Dim_AccountType. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 20 | IsDepositor_FromDate_ToDate | BOOLEAN | YES | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 — via Fact_SnapshotCustomer) |
| 21 | GuruStatusID_FromDate_ToDate | INT | YES | Popular Investor (Guru) program status. FK to Dim_GuruStatus. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 22 | AccountManagerID_FromDate_ToDate | INT | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 — via Fact_SnapshotCustomer) |
| 23 | City_FromDate_ToDate | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- Location (valid in snapshot period) City`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 24 | Address_FromDate_ToDate | STRING | YES | Direct passthrough from upstream. Formula: `Address`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 25 | Country_FromDate_ToDate | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
... (1 more upstream(s))
        │
        ▼
main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=26 runtime=26 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md`)
- **JOIN/UNION upstreams**: 3 additional object(s)
- **Wiki coverage**: 3/3 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 3 | Formulas: 26 | Tiers: 0 T1, 26 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 26/26 | Source: view_definition*
