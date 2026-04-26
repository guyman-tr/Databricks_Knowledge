# BI_DB_dbo.BI_DB_AB_Test_Data

> Period-based A/B test assignment table with experiment-specific metadata. Contains 5,000 rows from a single Data Science experiment ("DataScienceSeptemberExperimentAM") run in September 2019. Each row represents one customer's test group assignment for the full experiment period (FromDateID/ToDateID), with additional experiment variant flags (`IsPortfolioAnchored`, `IsControlPortfolioEnabled`, `ServiceLevelAnchored`). No active writer SP; last updated 2019-09-03. The companion daily-grain table `BI_DB_AB_Test` covers later experiments (2020–2023).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — A/B experiment period assignment with variant metadata |
| **Production Source** | Unknown — no Generic Pipeline, no SSDT SP |
| **Refresh** | None active (last load 2019-09-03) |
| **Synapse Distribution** | HASH (RealCID) |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 5,000 (as of 2026-04-23; frozen since 2019-09-03) |
| **Test Period** | 2019-09-02 to 2019-09-30 (DateID: 20190902–20190930) |
| **Distinct Tests** | 1 (DataScienceSeptemberExperimentAM) |
| **Related Table** | BI_DB_dbo.BI_DB_AB_Test (daily-grain A/B log, 2020–2023 experiments) |

---

## 1. Business Meaning

`BI_DB_AB_Test_Data` is a period-based A/B test assignment table that stores customer experiment memberships for the eToro "DataScienceSeptemberExperimentAM" — a Data Science team portfolio-anchoring experiment run in September 2019. Unlike the companion `BI_DB_AB_Test` table (which records daily rows for each test day), this table stores one row per customer for the entire experiment period (FromDateID → ToDateID).

The experiment tested **portfolio anchoring** — a feature where a customer's portfolio composition is "anchored" (locked or fixed) relative to a baseline. Treatment group customers have `IsPortfolioAnchored=1`, while control group customers have NULL. This was a one-month experiment (Sept 2–30, 2019) with 5,000 participants.

The table also contains two additional experiment variant flags (`IsControlPortfolioEnabled`, `ServiceLevelAnchored`) that were NULL for all rows in this experiment — these may be metadata columns reserved for future experiment designs with richer variant configurations.

The table is effectively frozen: it has never been updated since the 2019-09-03 load, and no new experiments have been added. It predates the more widely-used `BI_DB_AB_Test` table by nearly a year.

---

## 2. Business Logic

### 2.1 Period-Based Assignment Model

**What**: Each row covers the customer's assignment for the full experiment period, not per-day.

**Columns Involved**: `RealCID`, `TestName`, `IsControl`, `FromDateID`, `ToDateID`

**Rules**:
- One row per customer-test (not per customer-test-day — this is the key difference from `BI_DB_AB_Test`)
- `FromDateID` / `ToDateID` define the experiment duration in YYYYMMDD integer format
- All rows: FromDateID=20190902, ToDateID=20190930 (single-month experiment)
- `TestName` is the unique experiment identifier (varchar(50), not the shorter varchar(25) in `BI_DB_AB_Test`)

### 2.2 Portfolio Anchoring Experiment Design

**What**: The experiment tested "portfolio anchoring" — treatment customers had their portfolio anchored.

**Columns Involved**: `IsControl`, `IsPortfolioAnchored`

**Rules**:
- `IsControl = 0` (treatment): `IsPortfolioAnchored = 1` — these customers had portfolio anchoring enabled
- `IsControl = 1` (control): `IsPortfolioAnchored = NULL` — baseline experience, no anchoring
- `IsControlPortfolioEnabled` and `ServiceLevelAnchored` are NULL for all 5,000 rows — reserved for richer future experiments

### 2.3 Null-Heavy Variant Columns

**What**: Three variant metadata columns are present but mostly NULL.

**Columns Involved**: `IsControlPortfolioEnabled`, `ServiceLevelAnchored`, `IsPortfolioAnchored`

**Rules**:
- `IsControlPortfolioEnabled` — NULL for all rows in this experiment (likely for experiments testing portfolio toggle for the control group specifically)
- `ServiceLevelAnchored` — NULL for all rows (varchar(50) — may hold a service level name when used)
- `IsPortfolioAnchored` — populated only: 1 for treatment rows, NULL for control rows

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(RealCID) with CLUSTERED INDEX (RealCID ASC). Customer-level joins are collocated with Dim_Customer if it is also HASH(RealCID). The RealCID clustered index makes per-customer lookups efficient, but range scans on DateID require a scan of the full table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Treatment vs. control split | `GROUP BY TestName, IsControl` |
| Customers in treatment group | `WHERE IsControl = 0 AND TestName = 'DataScienceSeptemberExperimentAM'` |
| Portfolio-anchored customers | `WHERE IsPortfolioAnchored = 1` |
| Join to daily outcomes | `JOIN Fact_CustomerAction ON RealCID AND DateID BETWEEN FromDateID AND ToDateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON a.RealCID = c.RealCID` | Customer demographics |
| DWH_dbo.Fact_CustomerAction | `ON a.RealCID = fa.RealCID AND fa.DateID BETWEEN a.FromDateID AND a.ToDateID` | Measure outcomes during experiment |
| BI_DB_dbo.BI_DB_AB_Test | `ON a.RealCID = b.RealCID` | Compare with daily-grain experiment tracking |

### 3.4 Gotchas

- **Very old data** — all rows from September 2019; last loaded 2019-09-03. Not suitable for current experiment analysis.
- **Only one test** — `DataScienceSeptemberExperimentAM`. This table is effectively a single-use artifact.
- **Null-heavy variant columns** — `IsControlPortfolioEnabled` and `ServiceLevelAnchored` are NULL for all rows. Do not rely on these columns for analysis of this experiment.
- **`IsPortfolioAnchored` NULL ≠ 0** — control group rows have NULL (not 0) for `IsPortfolioAnchored`. Use `ISNULL(IsPortfolioAnchored, 0)` if comparing control vs. treatment numerically.
- **No UC migration** — this table is `_Not_Migrated`.

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
| 1 | RealCID | int | NO | eToro real-money customer ID. Distribution and index key — customer-level lookups are efficient. (Tier 3 — HASH distribution key + live data: 5,000 unique CIDs) |
| 2 | TestName | varchar(50) | NO | Unique identifier for the A/B experiment. Observed value: "DataScienceSeptemberExperimentAM". Wider than BI_DB_AB_Test.Name (varchar(25)) — supports longer experiment identifiers. (Tier 3 — live data sampling) |
| 3 | IsControl | int | NO | A/B group assignment. 1 = control group (baseline, IsPortfolioAnchored=NULL), 0 = treatment group (portfolio anchoring enabled, IsPortfolioAnchored=1). (Tier 3 — live data analysis) |
| 4 | IsControlPortfolioEnabled | int | YES | Experiment variant flag — whether portfolio is enabled specifically for the control group. NULL for all rows in the September 2019 experiment; reserved for future experiment designs. (Tier 4 — all NULL, unknown semantics) |
| 5 | ServiceLevelAnchored | varchar(50) | YES | Experiment variant dimension — service level being anchored in this test variant. NULL for all rows in the September 2019 experiment; reserved for future experiment designs. (Tier 4 — all NULL, unknown semantics) |
| 6 | IsPortfolioAnchored | int | YES | Flag indicating whether the customer's portfolio is anchored in this experiment. Treatment rows: 1 (anchoring enabled), Control rows: NULL (no anchoring). Core experiment variable for DataScienceSeptemberExperimentAM. (Tier 3 — live data analysis: treatment=1, control=NULL) |
| 7 | FromDateID | int | NO | Start date of the experiment period in YYYYMMDD integer format. All rows: 20190902 (September 2, 2019). (Tier 3 — live data: all rows = 20190902) |
| 8 | ToDateID | int | NO | End date of the experiment period in YYYYMMDD integer format. All rows: 20190930 (September 30, 2019). (Tier 3 — live data: all rows = 20190930) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was loaded. All rows: 2019-09-03 10:27:41. (Tier 5 — propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | etoro production (Customer) | RealCID | Passthrough |
| TestName | Data Science experiment tool | TestName | Passthrough |
| IsControl | Data Science experiment tool | GroupAssignment | 0/1 flag |
| IsPortfolioAnchored | Data Science experiment tool | — | 1 for treatment, NULL for control |
| FromDateID / ToDateID | Data Science experiment tool | Start/End date | YYYYMMDD integer |
| UpdateDate | ETL pipeline | — | Load timestamp |

### 5.2 ETL Pipeline

```
Data Science team (portfolio-anchoring experiment, Sept 2019)
  |-- Unknown load mechanism (likely manual INSERT or Python script) --|
  v
BI_DB_dbo.BI_DB_AB_Test_Data (5,000 rows — loaded 2019-09-03, never updated)

Single experiment: DataScienceSeptemberExperimentAM
  Period: 20190902–20190930
  Treatment (IsControl=0, IsPortfolioAnchored=1): portfolio anchoring enabled
  Control (IsControl=1): baseline, no portfolio anchoring

No downstream consumers identified.

Migration staging:
  BI_DB_Migration.BI_DB_AB_Test_Data (ROUND_ROBIN CCI — Sept 2024 migration)
  BI_DB_Migration.JUNK_BI_DB_AB_Test_Data (marked for cleanup)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer demographics via RealCID FK |
| FromDateID/ToDateID | DWH_dbo.Dim_Date | Date dimension lookup for experiment period |
| Experiment family | BI_DB_dbo.BI_DB_AB_Test | Daily-grain A/B companion (different tests, 2020–2023) |

### 6.2 Referenced By

No downstream consumers identified in the SSDT BI_DB_dbo stored procedures or views.

---

## 7. Sample Queries

### Experiment group breakdown

```sql
SELECT
    TestName,
    IsControl,
    IsPortfolioAnchored,
    COUNT(*) AS Customers,
    MIN(FromDateID) AS StartDate,
    MAX(ToDateID) AS EndDate
FROM [BI_DB_dbo].[BI_DB_AB_Test_Data]
GROUP BY TestName, IsControl, IsPortfolioAnchored
ORDER BY IsControl;
```

### Treatment group customers during experiment

```sql
SELECT
    d.RealCID,
    d.TestName,
    d.IsPortfolioAnchored,
    c.Country,
    c.Regulation
FROM [BI_DB_dbo].[BI_DB_AB_Test_Data] d
JOIN [DWH_dbo].[Dim_Customer] c ON d.RealCID = c.RealCID
WHERE d.IsControl = 0;
```

### Customer actions during experiment period

```sql
SELECT
    d.RealCID,
    d.IsControl,
    COUNT(fa.ActionID) AS ActionCount,
    SUM(fa.Amount) AS TotalAmount
FROM [BI_DB_dbo].[BI_DB_AB_Test_Data] d
JOIN [DWH_dbo].[Fact_CustomerAction] fa
    ON d.RealCID = fa.RealCID
    AND fa.DateID BETWEEN d.FromDateID AND d.ToDateID
GROUP BY d.RealCID, d.IsControl
ORDER BY ActionCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. This is a frozen experiment artifact from September 2019 with no active pipeline documentation.

---

*Generated: 2026-04-23 | Quality: 7.0/10 | Phases: 8/14 (P3/P5/P7/P9/P9B/P10 skipped — no writer SP, frozen 2019 data)*
*Tiers: 0 T1, 0 T2, 6 T3, 2 T4, 1 T5 | Elements: 9/9 | Object: BI_DB_dbo.BI_DB_AB_Test_Data | Type: Table | Production Source: Unknown (Data Science experiment management — 2019)*
*Note: Table frozen since 2019-09-03. Two Tier 4 columns (IsControlPortfolioEnabled, ServiceLevelAnchored) are all-NULL with no traceable semantics. Quality 7.0.*
