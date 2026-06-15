---
object_fqn: main.bi_output.vg_acquisitionfunnel_em1
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_acquisitionfunnel_em1
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 17
row_count: null
generated_at: '2026-05-19T15:01:57Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_acquisitionfunnel_em1.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_acquisitionfunnel_em1.sql
concept_count: 1
formula_count: 17
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 15
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_acquisitionfunnel_em1

> View in `main.bi_output`. 1 business concept(s) in §2; 17 of 17 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_acquisitionfunnel_em1` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 17 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu Jan 01 15:12:02 UTC 2026 |

---

## 1. Business Meaning

`vg_acquisitionfunnel_em1` is a view in `main.bi_output` that composes 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Reports_AcquisitionFunnel.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 17 columns: 2 inherit byte-for-byte from upstream wikis (Tier 1), 15 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `b` → `gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `a.CID = b.CID    AND b.GCID_Unique_Count = 1    AND b.IsValidETM = 1    AND b.IsValidCustomer = 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_acquisitionfunnel_em1.sql` L36
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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `a.CID = b.CID    AND b.GCID_Unique_Count = 1    AND b.IsValidETM = 1    AND b.IsValidCustomer = 1` | Lookup via alias `b` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 1 | GCID | INT | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 — dbo.FiatAccount) |
| 2 | Country_as_of_yesterday | STRING | YES | Customer's eMoney-registered country name. Derived as ISNULL(eMoney_Dim_Account.RegCountry, eMoney_Dim_Country_Rollout.CountryName) — eMoney account's registered country takes precedence over the current eToro trading country. Scoped to eMoney-eligible markets only. (Tier 2 — SP_eMoney_Reports_Daily) |
| 3 | Club_as_of_yesterday | STRING | YES | Customer's current eToro loyalty club tier at time of refresh. 6 values: Bronze=84%, Silver=5.9%, Gold=5.4%, Platinum=2.6%, Platinum Plus=1.9%, Diamond=0.2%. Sourced from DWH_dbo.Dim_PlayerLevel.Name. (Tier 2 — SP_eMoney_Reports_Daily) |
| 4 | IsValidForFunnel_as_of_yesterday | INT | YES | 1 if the customer is eligible for the eToro Money funnel, 0 if excluded. Derived from ISNULL(eMoney_Dim_Account.IsValidETM, 1). Defaults to 1 when no eMoney account exists (customer is potentially eligible). 0 indicates an invalid eMoney enrollment (710 rows = 0.02%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 5 | IsVerifiedFTD_as_of_yesterday | INT | YES | Always 1 — all rows in this table are verified eToro FTD depositors (IsDepositor=1, VerificationLevelID=3 filter applied during SP execution). Serves as an eligibility label confirming funnel entry criteria. (Tier 2 — SP_eMoney_Reports_Daily) |
| 6 | IsVerifiedFTDPlus2Weeks_as_of_yesterday | INT | YES | 1 if the customer's first deposit was more than 14 days ago (DATEDIFF(DAY, FirstDepositDate, yesterday) > 14). Measures 2-week post-FTD maturation used in some cohort definitions. 3,659,851 rows = 1 (99.6%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 7 | IsActiveMIMO_as_of_yesterday | INT | YES | 1 if the customer performed at least one MIMO action (ActionTypeID IN [7, 8] in DWH_dbo.Fact_CustomerAction) within the last 91 days (rolling window from yesterday). 449,123 rows = 1 (12.2%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 8 | HasEMoneyAccount_as_of_yesterday | INT | YES | 1 if the customer has a row in eMoney_Panel_FirstDates (GCID IS NOT NULL after LEFT JOIN). Indicates the customer has an active eMoney account represented in the first-dates panel. 1,726,054 rows = 1 (47.0%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 9 | IsFMI_as_of_yesterday | INT | YES | 1 if the customer's FMI_Date IS NOT NULL in eMoney_Panel_FirstDates — they have received their first settled incoming eToro Money transfer (First Money In). 1,201,484 rows = 1 (32.7%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 10 | IsFMO_as_of_yesterday | INT | YES | 1 if the customer's FMO_Date IS NOT NULL in eMoney_Panel_FirstDates — they have made their first settled outgoing eToro Money transfer (First Money Out). 1,160,237 rows = 1 (31.6%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 11 | IsCardCreated_as_of_yesterday | INT | YES | 1 if eMoney_Dim_Account.CardCreateTime IS NOT NULL — an eToro Money physical or virtual card has been issued for this customer. 89,823 rows = 1 (2.4%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 12 | IsCardActivated_as_of_yesterday | INT | YES | 1 if eMoney_Panel_FirstDates.CardActivationTime IS NOT NULL — the customer's card has reached Active status (CardStatusID=1). 26,079 rows = 1 (0.7%). Always ≤ IsCardCreated. (Tier 2 — SP_eMoney_Reports_Daily) |
| 13 | IsCardFirstTx_as_of_yesterday | INT | YES | 1 if eMoney_Panel_FirstDates.FirstCardSettledTXDate IS NOT NULL — the customer has made at least one settled card transaction. 23,690 rows = 1 (0.6%). The final stage of the card adoption funnel. (Tier 2 — SP_eMoney_Reports_Daily) |
| 14 | AccountSubProgram_as_of_yesterday | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- eMoney account program (as of yesterday) AccountSubProgram`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`) |
| 15 | AccountSubProgramID_as_of_yesterday | INT | YES | Direct passthrough from upstream. Formula: `AccountSubProgramID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`) |
| 16 | eMoneyAccountCreateDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `AccountCreateDate`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | Primary | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Reports_AcquisitionFunnel.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | JOIN/UNION | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
        │
        ▼
main.bi_output.vg_acquisitionfunnel_em1   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=17 runtime=17 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` (wiki: `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Reports_AcquisitionFunnel.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 1/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 17 | Tiers: 2 T1, 15 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 17/17 | Source: view_definition*
