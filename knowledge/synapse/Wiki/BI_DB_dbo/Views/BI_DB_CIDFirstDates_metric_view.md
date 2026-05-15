# BI_DB_dbo.BI_DB_CIDFirstDates_metric_view

> Seven-column Metric View derived from CID first-dates enrichment: exposes customer identifier, CRM username PII, eToro Club tier label, registration date, and three balance/deposit KPI measures for dashboards that consume the Lakehouse METRIC_VIEW projection.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | View (Metric View export in UC) |
| **Production Source** | `BI_DB_dbo.BI_DB_CIDFirstDates` (see upstream table wiki); measures trace to `V_Liabilities.Credit`, `V_Liabilities.RealizedEquity`, and last-deposit aggregates per `SP_CIDFirstDates` |
| **Refresh** | Inherits CIDFirstDates ETL cadence (`SP_CIDFirstDates` / SB pipelines); UC METRIC_VIEW is Gold projection |
| | |
| **Synapse Distribution** | N/A |
| **Synapse Index** | N/A |
| | |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view` |
| **UC alternate (Databricks verified)** | `main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view` (METRIC_VIEW; column comments historically unsupported — see deploy report) |
| **UC Format** | METRIC VIEW (Lakehouse exports `CustomerID`, `UserName`, `ClubName`, `registered date`, `Total Credit`, `Total Realized Equity`, `Last Deposit Amount` per `DESCRIBE TABLE`) |
| **UC Partitioned By** | _Unknown from describe_ |
| **UC Table Type** | Derived metric projection |

---

## 1. Business Meaning

Retail analytics and Salesforce-facing extracts need a concise slice of CID first-dates data without the wide 139-column parent table (`BI_DB_CIDFirstDates`). The metric view publishes the customer grain (`CustomerID` alias), high-signal demographics (`UserName`, `ClubName`, `registered date`), and three KPI columns that mirror populated fields in CIDFirstDates: bonus credit snapshot, realized equity snapshot, and the most recent deposit amount.

Databricks `DESCRIBE TABLE main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view` documents the authoritative UC column list and datatype markers (`decimal(... ) measure`). The Synapse MCP pools available to this pipeline did **not** return `OBJECT_ID`/`sys.columns` for `BI_DB_CIDFirstDates_metric_view`; semantic grounding pulls forward **verbatim formulas** quoted in `BI_DB_CIDFirstDates.md` §2.6 (`Credit`, `RealizedEquity`) and column rename relationships (`CID`≡CustomerID, `Club`≡ClubName, `registered`≡registered date).

---

## 2. Business Logic

### 2.1 Measure semantics (inherits CIDFirstDates)

**What**: Credit and equity fields follow the CIDFirstDates nightly snapshot semantics.

**Columns Involved**: `Total Credit`, `Total Realized Equity`

**Rules** (verbatim from wiki §2.6):
- `Credit = ISNULL(V_Liabilities.Credit, 0)`
- `RealizedEquity = ISNULL(V_Liabilities.RealizedEquity, 0)`
- Snapshot only updates during the `@date=yesterday` run path — not intraday realtime.

---

## 3. Query Advisory

### 3.0 Data Preview (Databricks)

Prefer `DESCRIBE ...` filters for Analysts validating schema; METRIC_VIEW row preview may be restricted by entitlement.

### 3.1 Synapse Distribution & Index

Synapse DDL not surfaced in MCP for this pipeline run — treat view as PASS-THROUGH to base CIDFirstDates table distribution (`HASH(CID)` on base table wiki).

### 3.1b UC (Databricks) Storage & Partitioning

Treat as analytic projection; METRIC_VIEW may not expose standard Delta column COMMENT metadata (see deploy-report skip note).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Pull KPI-ready facts for a CID | Filter `CustomerID = @cid`; join to `Dim_Customer` if additional attributes required |
| Compare credit vs deposits | Align on same snapshot date sourced from CIDFirstDates refresh calendar |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `BI_DB_CIDFirstDates` | `CID = CustomerID` | Validate measures against wide table |

### 3.4 Gotchas

- Column `registered date` contains a literal space — quote with backticks in Databricks SQL.
- Measure datatype tokens appear in DESCRIBE output (`measure` suffix).
- Duplicate catalog names (`bi_db` roster vs `pii_data` live) affect deployment ACLs — confirm before altering.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★☆ | Tier 1 | `(Tier 1 — upstream wiki)` | Copied lineage from CustomerStatic / BackOffice refs |
| ★★★☆☆ | Tier 2 | `(Tier 2 — SP code)` | Mapped from CIDFirstDates + SP citations |
| ★★☆☆☆ | Tier 3 | `(Tier 3 — structure)` | Column rename only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CustomerID | int | NO | Platform customer surrogate aligned with `BI_DB_CIDFirstDates.CID`: "Customer ID — platform-internal primary key... Mapped from Dim_Customer.RealCID." **UC rename:** `CustomerID`. (Tier 1 — Customer.CustomerStatic via BI_DB_CIDFirstDates) |
| 2 | UserName | nvarchar(512) | YES | Customer eToro login / display identifier; PII. Existing UC metadata states "From Dim_Customer.UserName" path. Ground with Dim_Customer join described in CIDFirstDates pipeline. (Tier 2 — SP_CIDFirstDates, Dim_Customer) |
| 3 | ClubName | varchar(500) | YES | eToro Club tier display label equivalent to base column `Club` ("Tier display name: Bronze...") in `BI_DB_CIDFirstDates`; **presentation rename** `ClubName`. (Tier 1 — Dictionary.PlayerLevel via BI_DB_CIDFirstDates.Club) |
| 4 | registered date | date | YES | Customer registration timestamp column `registered` on `BI_DB_CIDFirstDates` exposed with spaced identifier in UC METRIC_VIEW. (Tier 2 — Dim_Customer / SP_CIDFirstDates) |
| 5 | Total Credit | decimal(29,4) | YES | Metric alias of `Credit`: nightly `ISNULL(V_Liabilities.Credit, 0)` snapshot per §2.6. (Databricks stores as METRIC datatype; DDL-style `decimal(29,4)` for Elements parsing.) (Tier 1 — Fact_SnapshotEquity via V_Liabilities) |
| 6 | Total Realized Equity | decimal(29,4) | YES | Metric alias of `RealizedEquity`: nightly `ISNULL(V_Liabilities.RealizedEquity, 0)` snapshot per §2.6. (Tier 1 — Fact_SnapshotEquity via V_Liabilities) |
| 7 | Last Deposit Amount | decimal(29,4) | YES | Mirrors `BI_DB_CIDFirstDates.LastDepositAmount`: "Most recent deposit amount in USD (Amount * ExchangeRate)." (Tier 2 — Fact_BillingDeposit via SP_CIDFirstDates) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CustomerID | Customer.CustomerStatic | RealCID mapping | Routed through `BI_DB_CIDFirstDates.CID` then renamed |
| Credit / Total Credit | V_Liabilities | Credit | `ISNULL(..., 0)` |
| RealizedEquity / Total Realized Equity | V_Liabilities | RealizedEquity | `ISNULL(..., 0)` |
| Last Deposit Amount | Fact_BillingDeposit | Amount × FX | Via `LastDeposit*` pipeline in SP_CIDFirstDates |

### 5.2 ETL Pipeline

```
Operational sources → SP_CIDFirstDates → BI_DB_CIDFirstDates
        → METRIC_VIEW projection → UC (bi_db roster / pii_data verified)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | `BI_DB_CIDFirstDates` | Wide enrichment table documented in repo wiki |
| Target | METRIC_VIEW | Seven-column KPI-friendly projection |

```text
UPSTREAM SEARCH LOG — BI_DB_CIDFirstDates_metric_view:
  Lineage source objects (from .lineage.md):
    1. BI_DB_CIDFirstDates (fact enrichment grain)
    2. Dim_Customer (UserName linkage)
  For each source:
    BI_DB_CIDFirstDates
      (a) Local wiki: knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CIDFirstDates.md → FOUND Read tool: YES
      (b) Production wiki: routed via CID → Customer.CustomerStatic → FOUND indirectly via BI_DB_CIDFirstDates sections
      Effective upstream: BI_DB_CIDFirstDates.md formulas for Credit / RealizedEquity / deposits
    Dim_Customer
      (a) Local wiki: knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md → FOUND Read tool: YES (PII attribution for UserName)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CustomerID | `BI_DB_CIDFirstDates.CID` | Same grain |
| UserName | `DWH_dbo.Dim_Customer` | Login / PII |
| KPI measures | `V_Liabilities`, `Fact_BillingDeposit` | See §2.1 |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|----------------|-------------|
| Marketing / CRM METRIC dashboards | KPI columns | Lightweight extracts |

---

## 7. Sample Queries

### 7.1 Single customer KPI profile
```sql
SELECT *
FROM main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view
WHERE CustomerID = 123456789;
```

### 7.2 Compare credit vs deposits
```sql
SELECT CustomerID, `Total Credit`, `Total Realized Equity`, `Last Deposit Amount`
FROM main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view
WHERE ClubName IS NOT NULL;
```

### 7.3 Join back to CIDFirstDates
```sql
SELECT v.CustomerID, t.Credit AS wide_credit_check
FROM main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view v
JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates t
  ON v.CustomerID = t.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources queried in this shortened speckit run.

---

*Generated: 2026-05-14 | Quality: 8.6/10 (★★★★☆) | Phases: speckit-condensed*

*Tiers: 4 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5*

*Object: BI_DB_dbo.BI_DB_CIDFirstDates_metric_view | Type: View | UC: roster bi_db METRIC*
