# BI_DB_dbo.BI_DB_AB_Test

> Daily-grain A/B test assignment tracking table. Contains 314,240 rows covering two product experiments run between June 2020 and April 2023. Each row records a customer's test group assignment (control or treatment) for a specific day and test. No active writer SP exists in the SSDT project; not registered in OpsDB. **Last updated 2023-04-30** — the table is historical/stale as of 2026.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — A/B experiment daily assignment log |
| **Production Source** | Unknown — no Generic Pipeline, no SSDT SP |
| **Refresh** | None active (last load 2023-04-30) |
| **Synapse Distribution** | HASH (RealCID) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC, Name ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 314,240 (as of 2026-04-23; frozen since 2023-04-30) |
| **Date Range** | 2020-06-10 to 2023-04-29 (DateID: 20200610–20230429) |
| **Distinct Tests** | 2 |
| **Related Table** | BI_DB_dbo.BI_DB_AB_Test_Data (period-based variant, September 2019 test only) |

---

## 1. Business Meaning

`BI_DB_AB_Test` is the eToro A/B experiment daily assignment log. It records which customers were assigned to the control or treatment group for each active experiment, at daily granularity. Each row represents one customer's test group assignment on one calendar day — enabling experiment analysis with daily-resolution cohort tracking.

Two experiments are recorded:

1. **AB_Test_lead_conv_202202** (Lead Conversion, Feb 2022 cohort)
   - BI Owner: Tom Boksenbojm | Business Owner: Elie Edery
   - 239,186 unique customers across 2022-03-02 to 2023-04-29
   - 33,840 control (14.1%) vs 205,346 treatment (85.9%) customer-day rows
   - Likely tested a lead conversion funnel change; large treatment skew suggests hold-out style design

2. **AB_Test_Onboarding_202007** (Onboarding, July 2020 cohort)
   - BI Owner: Tom Boksenbojm | Business Owner: Steven Freedman
   - 75,054 rows with all IsControl=1 (no treatment rows recorded)
   - Date range: 2020-06-10 to 2022-03-01 (predates AB_Test_lead_conv_202202)
   - All-control row pattern may indicate a baseline measurement period or a one-sided comparison

The table has had no new data since 2023-04-30, indicating the experiment management program feeding this table has been discontinued or moved to a different system.

The companion table `BI_DB_AB_Test_Data` uses a different schema (period-based, not daily) and covers only a September 2019 Data Science experiment.

---

## 2. Business Logic

### 2.1 Control vs. Treatment Assignment

**What**: The `IsControl` flag identifies which test group each customer belongs to.

**Columns Involved**: `IsControl`, `RealCID`, `Name`

**Rules**:
- `IsControl = 1` → customer assigned to the control group (receives baseline/standard experience)
- `IsControl = 0` → customer assigned to the treatment group (receives the new feature/variant)
- Assignment persists over the test duration (same RealCID keeps the same IsControl value for a given test Name)
- `AB_Test_Onboarding_202007`: all rows IsControl=1 — no treatment variant rows in this table

### 2.2 Daily Grain Tracking

**What**: One row per customer-test-day, allowing time-series analysis of test populations.

**Columns Involved**: `DateID`, `Date`, `RealCID`, `Name`

**Rules**:
- `DateID` is an integer YYYYMMDD key (matches standard DWH date dimension pattern)
- `Date` is the calendar date equivalent of DateID
- The clustered index on (DateID, Name) enables efficient date-range + test-name lookups
- HASH(RealCID) distribution ensures customer joins are collocated

### 2.3 Test Ownership

**What**: Each test has two ownership fields tracking who is responsible.

**Columns Involved**: `BI_Owner`, `Business_Owner`, `Name`

**Rules**:
- `BI_Owner` — the BI analyst or data person owning the experiment analysis (varchar(14) — short names only)
- `Business_Owner` — the product/business stakeholder who requested the test (varchar(15))
- Both observed owners: Tom Boksenbojm (BI), Elie Edery / Steven Freedman (Business)
- varchar(14/15) lengths are tight — may truncate long names

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(RealCID) with CLUSTERED INDEX (DateID, Name). Join to DWH_dbo.Dim_Customer on RealCID is collocated (if that table is also HASH(RealCID)). Date-range queries on DateID will benefit from the clustered index but require a broadcast or shuffle for tables not distributed on RealCID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Control vs treatment sizes for a test | `GROUP BY Name, IsControl ORDER BY Name, IsControl` |
| Customer list for a test group | `WHERE Name = 'AB_Test_lead_conv_202202' AND IsControl = 0` |
| Daily customer count by variant | `GROUP BY DateID, Name, IsControl` |
| Join to outcomes table | `JOIN Fact_CustomerAction ON a.RealCID = b.RealCID AND b.DateID BETWEEN a.DateID AND a.DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON a.RealCID = c.RealCID` | Customer demographics |
| DWH_dbo.Fact_CustomerAction | `ON a.RealCID = b.RealCID AND a.DateID = b.DateID` | Measure outcome during test period |
| BI_DB_dbo.BI_DB_AB_Test_Data | `ON a.RealCID = b.RealCID AND a.Name LIKE '%' + b.TestName + '%'` | Compare daily vs. period-based assignment records |

### 3.4 Gotchas

- **Stale data** — no new rows since 2023-04-30. Not suitable for current experiment analysis.
- **AB_Test_Onboarding_202007 has zero treatment rows** — IsControl is always 1 for this test. Joining to an "outcome" table will only show control-group results. Verify test design intent before analyzing.
- **varchar(14/15) for owner names** — `BI_Owner` and `Business_Owner` are very narrow; names may be truncated. Do not use for exact-match joins to HR/identity systems.
- **Name is varchar(25)** — tight. All known test names fit (e.g., "AB_Test_lead_conv_202202" = 25 chars exactly).
- **No UC migration** — this table is `_Not_Migrated`; it is not available in Unity Catalog.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from writer SP code (direct tracing) |
| Tier 3 | Inferred from column name, live data sampling, and domain context |
| Tier 4 | No source traceable — best-effort description |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Integer date key in YYYYMMDD format. Matches DWH_dbo date dimension convention. Clustered index lead key — range queries on date are efficient. (Tier 3 — live data: range 20200610–20230429) |
| 2 | Date | date | YES | Calendar date equivalent of DateID. Redundant with DateID but provided for human-readable filtering. (Tier 3 — live data: 2020-06-10 to 2023-04-29) |
| 3 | RealCID | int | YES | eToro real-money customer ID. Distribution key — joins to Dim_Customer.RealCID are collocated. (Tier 3 — HASH distribution key + live data: 312,861 unique CIDs) |
| 4 | IsControl | int | YES | A/B group assignment flag. 1 = control group (baseline experience), 0 = treatment group (new feature/variant). Confirmed from live data: AB_Test_lead_conv_202202 has both 0 and 1 values; AB_Test_Onboarding_202007 has only 1. (Tier 3 — live data analysis) |
| 5 | BI_Owner | varchar(14) | YES | Name of the BI analyst or data scientist who owns the experiment analysis. Observed values: "Tom Boksenbojm". Max 14 characters — long names may be truncated. (Tier 3 — live data sampling) |
| 6 | Business_Owner | varchar(15) | YES | Name of the product or business stakeholder who requested the A/B test. Observed values: "Elie Edery", "Steven Freedman". Max 15 characters. (Tier 3 — live data sampling) |
| 7 | Name | varchar(25) | YES | Unique identifier for the A/B test. Follows convention: AB_Test_{purpose}_{YYYYMM}. Known values: "AB_Test_lead_conv_202202", "AB_Test_Onboarding_202007". Max 25 chars — tight fit. (Tier 3 — live data sampling) |
| 8 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last loaded. All rows for AB_Test_lead_conv_202202: 2023-04-30 05:27. (Tier 5 — propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | etoro production (Customer) | RealCID | Passthrough |
| DateID | etoro production or experiment tool | Date | YYYYMMDD integer key |
| IsControl | Experiment management tool | GroupAssignment | 0/1 flag |
| Name | Experiment management tool | TestName | Passthrough |
| BI_Owner | Manually entered or experiment metadata | — | Passthrough |
| Business_Owner | Manually entered or experiment metadata | — | Passthrough |
| UpdateDate | ETL pipeline | — | Load timestamp |

### 5.2 ETL Pipeline

```
Experiment management platform (A/B test assignment system — external or manual)
  |-- Unknown feed mechanism (no Generic Pipeline, no External Table, no SSDT SP) --|
  v
BI_DB_dbo.BI_DB_AB_Test (314,240 rows — last updated 2023-04-30)

Tests recorded:
  AB_Test_lead_conv_202202:   2022-03-02 → 2023-04-29  |  239,186 CIDs
  AB_Test_Onboarding_202007:  2020-06-10 → 2022-03-01  |  ~73,675 CIDs

No downstream consumers identified.

Migration staging:
  BI_DB_Migration.BI_DB_AB_Test (ROUND_ROBIN CCI — Sept 2024 migration event)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer demographics via RealCID FK |
| DateID | DWH_dbo.Dim_Date | Date dimension calendar lookup |
| Test schema | BI_DB_dbo.BI_DB_AB_Test_Data | Period-based A/B assignment companion (different test, different grain) |

### 6.2 Referenced By

No downstream consumers identified in the SSDT BI_DB_dbo stored procedures or views.

---

## 7. Sample Queries

### Control vs. treatment split per test

```sql
SELECT
    Name,
    IsControl,
    COUNT(DISTINCT RealCID) AS UniqueCustomers,
    COUNT(*) AS TotalRows,
    MIN(Date) AS StartDate,
    MAX(Date) AS EndDate
FROM [BI_DB_dbo].[BI_DB_AB_Test]
GROUP BY Name, IsControl
ORDER BY Name, IsControl;
```

### Daily customer count by test variant

```sql
SELECT
    Name,
    Date,
    IsControl,
    COUNT(DISTINCT RealCID) AS Customers
FROM [BI_DB_dbo].[BI_DB_AB_Test]
WHERE Name = 'AB_Test_lead_conv_202202'
GROUP BY Name, Date, IsControl
ORDER BY Date;
```

### Join to customer outcomes during test period

```sql
SELECT
    ab.Name,
    ab.IsControl,
    COUNT(DISTINCT ab.RealCID) AS Customers,
    SUM(fa.Amount) AS TotalAmount
FROM [BI_DB_dbo].[BI_DB_AB_Test] ab
JOIN [DWH_dbo].[Fact_CustomerAction] fa
    ON ab.RealCID = fa.RealCID
    AND ab.DateID = fa.DateID
WHERE ab.Name = 'AB_Test_lead_conv_202202'
GROUP BY ab.Name, ab.IsControl;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. This is an experiment tracking table with no active pipeline documentation.

---

*Generated: 2026-04-23 | Quality: 7.5/10 | Phases: 8/14 (P3/P5/P7/P9/P9B/P10 skipped — no writer SP, static historical data)*
*Tiers: 0 T1, 0 T2, 7 T3, 0 T4, 1 T5 | Elements: 8/8 | Object: BI_DB_dbo.BI_DB_AB_Test | Type: Table | Production Source: Unknown (A/B experiment management system)*
*Note: Table has 314,240 rows but no new data since 2023-04-30. All columns Tier 3 from live data sampling + domain inference. Quality 7.5 (penalized for missing writer SP and no active pipeline).*
