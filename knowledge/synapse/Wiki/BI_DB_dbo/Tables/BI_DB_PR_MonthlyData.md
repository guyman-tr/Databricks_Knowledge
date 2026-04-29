# BI_DB_dbo.BI_DB_PR_MonthlyData

> 100.2M-row monthly position-level dataset for PR (Public Relations) reporting, tracking non-mirror positions opened by depositing customers with demographic breakdowns (age, gender, region, instrument type). One row per position per month. Covers January 2019 to March 2026 (87 months). Refreshed monthly via `SP_M_PR_MonthlyData` (DELETE+INSERT by month).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_CIDFirstDates` + `DWH_dbo.Dim_Position` + `Dim_Instrument` + `Dim_Country` + `Dim_Date` |
| **Writer SP** | `BI_DB_dbo.SP_M_PR_MonthlyData` (no author attribution in SP header) |
| **Refresh** | Monthly, DELETE+INSERT by month (accumulating — retains historical months) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | _Not_Mapped (no Generic Pipeline entry found) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table feeds **PR (Public Relations) monthly reporting** on trading activity by customer demographics. It answers questions like: "How many positions did customers in the 25-34 age group open in stocks this month?" or "What is the gender split of trading activity by region?"

Each row represents one **non-mirror position** opened by a **depositing customer** during a given month. The table excludes:
- **Copy-trading/mirror positions** (MirrorID = 0 filter) — only direct, self-initiated trades
- **Non-depositors** (FirstDepositDate > 2000-01-01) — customers who never deposited are excluded

The dataset enriches each position with demographic attributes from `BI_DB_CIDFirstDates` (age, gender, country), geographic groupings from `Dim_Country` (desk, region), and instrument classification from `Dim_Instrument` (display name, type). Opening time is decomposed into hour and day-of-week for temporal analysis.

Currently holds 100.2M rows across 87 months (January 2019 to March 2026), averaging ~1.15M positions per month. The latest month (March 2026) has 320K positions across 6 instrument types (Commodities=124.6K, Stocks=109.5K, Indices=46.4K, ETF=19.7K, Crypto=13.1K, Currencies=7.3K).

---

## 2. Business Logic

### 2.1 Depositor Filter

**What**: Restricts to customers who have deposited funds.
**Columns Involved**: CID (via CIDFirstDates.FirstDepositDate)
**Rules**:
- FirstDepositDate > '20000101' — customers must have a valid first deposit date
- The 1900-01-01 sentinel in CIDFirstDates means "never deposited" — excluded by this filter

### 2.2 Non-Mirror Filter

**What**: Excludes copy-trading positions.
**Columns Involved**: PositionID (via Dim_Position.MirrorID)
**Rules**:
- MirrorID = 0 — only direct, self-initiated trades
- Mirror positions (MirrorID > 0) are excluded to avoid double-counting copier activity

### 2.3 Age Group Classification

**What**: Bins customers by age at query time.
**Columns Involved**: Age_Group
**Rules**:
- Computed from BirthDate: `FLOOR(DATEDIFF(DAY, BirthDate, GETDATE()) / 365.25)`
- 18-24, 25-34, 35-44, 45-54, 55+
- NULL if BirthDate is NULL
- Age is calculated at SP execution time (GETDATE()), not at position open time — re-runs will produce different age groups

### 2.4 Gender Normalization

**What**: Normalizes gender codes to display values.
**Columns Involved**: Gender
**Rules**:
- M → 'Male', F → 'Female', anything else → 'Male' (default)

### 2.5 Monthly Grain

**What**: Table accumulates monthly snapshots.
**Columns Involved**: Date
**Rules**:
- Date = first day of the month (@Startofmonth parameter)
- DELETE WHERE Date = @Startofmonth before INSERT (idempotent re-run)
- OpenDateID must be within the month: BETWEEN @StartofmonthINT AND @yesterdayINT (end of month)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution. CLUSTERED INDEX on Date ASC — efficient for date-range scans. Always filter by Date for monthly analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Monthly position count by age group | `SELECT Date, Age_Group, COUNT(*) FROM ... GROUP BY Date, Age_Group` |
| Gender split by instrument type | `SELECT Gender, InstrumentType, COUNT(*) FROM ... WHERE Date = '2026-03-31' GROUP BY Gender, InstrumentType` |
| Regional trading trends | `SELECT Date, Region, COUNT(*) FROM ... GROUP BY Date, Region ORDER BY Date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | PositionID = PositionID | Full position details (PnL, close date, etc.) |
| DWH_dbo.Dim_Instrument | Instrument = InstrumentDisplayName | Additional instrument details |
| BI_DB_CIDFirstDates | CID = CID | Full customer lifecycle dates |

### 3.4 Gotchas

- **Age_Group is computed at execution time** — re-running the SP for a historical month will recalculate ages based on current GETDATE(), potentially shifting customers between age bands
- **Gender default is 'Male'** — NULL/unknown genders default to 'Male'; this biases gender analysis
- **No UC target** — Synapse-only table
- **Monthly not daily** — OpsDB says "Monthly" frequency; do not expect daily updates
- **WITH(NOLOCK) hints** — SP uses NOLOCK on all JOINs; data is eventually consistent

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description from documented upstream wiki (verbatim) |
| Tier 2 | Description from SP code analysis |
| Tier 3 | Description from data sampling / parameter inference |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | First day of the reporting month (@Startofmonth parameter). Clustered index key. DELETE+INSERT granularity. (Tier 3 — SP_M_PR_MonthlyData, parameter) |
| 2 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Sourced from Dim_Customer.RealCID. Passthrough from BI_DB_CIDFirstDates. (Tier 1 — Customer.CustomerStatic) |
| 3 | Instrument | varchar(100) | YES | Instrument display name (e.g., 'Apple', 'Bitcoin', 'Gold'). Resolved from Dim_Instrument.InstrumentDisplayName via InstrumentID. (Tier 2 — SP_M_PR_MonthlyData, Dim_Instrument.InstrumentDisplayName) |
| 4 | InstrumentType | varchar(50) | YES | Instrument category. 6 values: Stocks, Commodities, Indices, ETF, Crypto Currencies, Currencies. From Dim_Instrument.InstrumentType. (Tier 2 — SP_M_PR_MonthlyData, Dim_Instrument) |
| 5 | Desk | nvarchar(50) | YES | Sales desk assignment. Resolved from Dim_Country.Desk via Country name match. (Tier 2 — SP_M_PR_MonthlyData, Dim_Country.Desk) |
| 6 | Region | varchar(50) | YES | Geographic region. Resolved from Dim_Country.Region via Country name match. Values: North Europe, French, Eastern Europe, Other EU, LATAM, Other Asia, etc. (Tier 2 — SP_M_PR_MonthlyData, Dim_Country.Region) |
| 7 | Country | varchar(500) | YES | Country of residence name. Passthrough from BI_DB_CIDFirstDates.Country. (Tier 1 — BI_DB_CIDFirstDates) |
| 8 | Age_Group | varchar(6) | YES | Customer age band computed at SP execution time. CASE on BirthDate: 18-24, 25-34, 35-44, 45-54, 55+. NULL if BirthDate is NULL. Warning: recalculated on re-run. (Tier 2 — SP_M_PR_MonthlyData, CASE on BirthDate) |
| 9 | Gender | varchar(6) | YES | Customer gender. M→'Male', F→'Female', else 'Male' (default). From BI_DB_CIDFirstDates.Gender. (Tier 2 — SP_M_PR_MonthlyData, CASE on Gender) |
| 10 | PositionID | bigint | YES | Trading position identifier. Only non-mirror positions (MirrorID=0). From Dim_Position. (Tier 1 — BI_DB_CIDFirstDates / DWH_dbo.Dim_Position) |
| 11 | OpenDateID | int | YES | Position open date as YYYYMMDD. Must fall within the reporting month. From Dim_Position.OpenDateID. (Tier 1 — DWH_dbo.Dim_Position) |
| 12 | OpenOccurred | datetime | YES | Position open timestamp. From Dim_Position.OpenOccurred. (Tier 1 — DWH_dbo.Dim_Position) |
| 13 | Open_Hour | int | YES | Hour of day when position was opened (0-23). Computed as DATEPART(HOUR, OpenOccurred). (Tier 2 — SP_M_PR_MonthlyData, DATEPART) |
| 14 | OpenDate_DayName | varchar(10) | YES | Day of week name when position was opened (e.g., 'Monday', 'Tuesday'). From Dim_Date.DayName via OpenDateID. (Tier 2 — SP_M_PR_MonthlyData, Dim_Date.DayName) |
| 15 | Amount | money | YES | Position amount in USD. From Dim_Position.Amount. (Tier 1 — DWH_dbo.Dim_Position) |
| 16 | UpdateDate | datetime | YES | Row load timestamp. GETDATE() at insert time. (Tier 3 — SP_M_PR_MonthlyData, GETDATE()) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| Date | — | — | @Startofmonth parameter |
| CID | BI_DB_CIDFirstDates | CID | Passthrough |
| Instrument | Dim_Instrument | InstrumentDisplayName | Rename |
| InstrumentType | Dim_Instrument | InstrumentType | Passthrough |
| Desk, Region | Dim_Country | Desk, Region | LEFT JOIN via Country name |
| Country | BI_DB_CIDFirstDates | Country | Passthrough |
| Age_Group | BI_DB_CIDFirstDates | BirthDate | CASE bucketing |
| Gender | BI_DB_CIDFirstDates | Gender | CASE normalization |
| PositionID, OpenDateID, OpenOccurred, Amount | Dim_Position | Same names | Passthrough |
| Open_Hour | Dim_Position | OpenOccurred | DATEPART(HOUR) |
| OpenDate_DayName | Dim_Date | DayName | Passthrough |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_CIDFirstDates (depositors, FDD > 2000)
  |-- JOIN DWH_dbo.Dim_Position (MirrorID=0, OpenDateID in month)
  |-- LEFT JOIN DWH_dbo.Dim_Date (DayName)
  |-- LEFT JOIN DWH_dbo.Dim_Instrument (DisplayName, InstrumentType)
  |-- LEFT JOIN DWH_dbo.Dim_Country (Desk, Region via Name)
  |-- SP_M_PR_MonthlyData @dd (Monthly, Priority 0)
  |-- Compute: Age_Group, Gender, Open_Hour
  |-- DELETE + INSERT by month
  v
BI_DB_dbo.BI_DB_PR_MonthlyData (100.2M rows, 87 months)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | BI_DB_CIDFirstDates | FK — customer lifecycle dates |
| PositionID | DWH_dbo.Dim_Position | FK — position details |
| Instrument | DWH_dbo.Dim_Instrument.InstrumentDisplayName | Instrument name |
| Country | DWH_dbo.Dim_Country.Name | Country-to-region/desk lookup |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Monthly Position Count by Age Group

```sql
SELECT Date, Age_Group, COUNT(*) AS Positions, SUM(Amount) AS TotalAmount
FROM BI_DB_dbo.BI_DB_PR_MonthlyData
WHERE Date >= '2026-01-01'
GROUP BY Date, Age_Group
ORDER BY Date, Age_Group
```

### 7.2 Instrument Type Distribution by Region

```sql
SELECT Region, InstrumentType, COUNT(*) AS Positions
FROM BI_DB_dbo.BI_DB_PR_MonthlyData
WHERE Date = '2026-03-31'
GROUP BY Region, InstrumentType
ORDER BY Region, Positions DESC
```

### 7.3 Trading Hour Distribution

```sql
SELECT Open_Hour, COUNT(*) AS Positions, OpenDate_DayName
FROM BI_DB_dbo.BI_DB_PR_MonthlyData
WHERE Date = '2026-03-31'
GROUP BY Open_Hour, OpenDate_DayName
ORDER BY Open_Hour
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 5 T1, 7 T2, 2 T3, 2 T4, 0 T5 | Elements: 16/16, Logic: 8/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_PR_MonthlyData | Type: Table | Production Source: BI_DB_CIDFirstDates + Dim_Position via SP_M_PR_MonthlyData*
