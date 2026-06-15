# BI_DB_dbo.BI_DB_Employees_Program

> 2,076-row daily TRUNCATE+INSERT employee trading program eligibility report tracking all eToro employee and analyst accounts (~2K internal accounts) with their trading activity, equity, volume, and program eligibility status. Populated by `SP_M_EmployeesProgram` via daily TRUNCATE+INSERT (OpsDB says Monthly, but SP runs daily), sourcing from `Dim_Customer`, `V_Liabilities`, `Fact_CustomerAction`, `Dim_Position`, and `Fact_CurrencyPriceWithSplit`. Program year resets annually on April 5th.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH aggregation via `SP_M_EmployeesProgram` |
| **Refresh** | SB_Daily (OpsDB: Monthly, ProcessType 1). TRUNCATE+INSERT — only latest snapshot. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Dan (2021-03-31), enhanced by Yarden (2022-2024), Lior Ben Dor (2024-2026) |

---

## 1. Business Meaning

This table reports on eToro's internal employee trading program. Each row represents one employee or analyst account, showing their current equity position, trading activity metrics over the program year, and whether they meet the eligibility criteria for the program.

**Purpose**: HR/Compliance monitoring of employee trading activity. Determines which employees are "eligible" based on minimum investment thresholds or trading volume criteria.

**Population**: Internal accounts — `PlayerLevelID=4`, `AccountTypeID IN (7=Employee, 13=Analyst)`, not closed, not blocked. Plus hardcoded `RealCID=149`.

**Program year**: Resets annually on **April 5th** (computed dynamically: if current date >= Apr 5 of current year, start = Apr 5 current year; else start = Apr 5 previous year). All trading metrics (ManualTrades, NewCopy, VolumeAtOpen) are counted within the current program year.

**Eligibility criteria** (IsEligible='Yes'):
- AvgInvestment >= 50% (average ratio of invested-to-equity over the year), OR
- NumOfActions >= 100 AND AvgMVolToEqy >= 10 (high trading activity with sufficient volume-to-equity ratio)

---

## 2. Business Logic

### 2.1 Program Year Reset

**What**: Trading metrics reset annually on April 5th.
**Columns Involved**: All activity metrics (ManualTrades, NewCopy, VolumeAtOpen, etc.)
**Rules**:
- @StartDate = April 5 of the applicable year
- Changed from May 9 (2023) → April 7 (2024) → April 5 (2026) based on SP change history
- All activity windows use @StartDateID to @DateID

### 2.2 Eligibility Determination

**What**: Two-path eligibility check.
**Columns Involved**: IsEligible, AvgInvestment, NumOfActions, AvgMVolToEqy
**Rules**:
- Path 1: `AvgInvestment >= 0.5` — employee kept at least 50% of equity invested on average
- Path 2: `NumOfActions >= 100 AND AvgMVolToEqy >= 10` — high trading activity with volume
- Either path → 'Yes'; neither → 'No'

### 2.3 Volume Calculation

**What**: USD-converted trading volume at open, with multi-currency conversion.
**Columns Involved**: VolumeAtOpen, AvgMVolToEqy
**Rules**:
- VolumeAtOpen = AmountInUnitsDecimal * InitForexRate * USD conversion rate
- USD conversion uses Fact_CurrencyPriceWithSplit with 3-tier currency resolution (direct USD, inverse USD, cross-rate)
- Only manual positions (MirrorID=0) — copy positions excluded from the program
- AvgMVolToEqy = AVG(monthly volume / monthly average equity)

### 2.4 Equity Components

**What**: Current-day financial snapshot from V_Liabilities.
**Columns Involved**: TotalEquity, ActualNWA, Credit, TotalPositionsAmount, PositionPnL, TotalCash, BonusCredit
**Rules**:
- TotalEquity = ActualNWA + Liabilities (at @Date)
- AvgInvestment = AVG((RealizedEquity - Credit) / RealizedEquity) over program year, WHERE RealizedEquity > 0
- Credit > 50% of RealizedEquity indicates insufficient investment

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — table is very small (~2K rows). No optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many employees are eligible? | `SELECT IsEligible, COUNT(*) FROM ... GROUP BY IsEligible` |
| Top traders by volume | `SELECT CID, FirstName, LastName, VolumeAtOpen FROM ... ORDER BY VolumeAtOpen DESC` |
| Employees close to eligibility | `WHERE IsEligible='No' AND (AvgInvestment >= 0.4 OR NumOfActions >= 80)` |

### 3.3 Common JOINs

None typically needed — table is self-contained with employee demographics.

### 3.4 Gotchas

- **PII-sensitive**: Contains FirstName, LastName, UserName, Email — handle with care
- **TRUNCATE+INSERT**: Only latest snapshot exists; no historical data
- **Only manual trades count**: Copy positions (MirrorID != 0) are excluded from ManualTrades, VolumeAtOpen
- **AvgInvestment interpretation**: Higher = more invested (less cash idle). 1.0 = fully invested at all times
- **Program year start date has changed**: Was May 9 (2023), then April 7 (2024), now April 5 (2026) — historical analysis needs to account for this
- **RealCID 149 always included**: Special account bypasses all employee filters
- **OpsDB says Monthly but SP runs daily**: The SP has no date guard — it runs on every SB_Daily execution

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki documentation |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / propagation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Snapshot date. Always the @Date parameter. Only one date exists (TRUNCATE+INSERT). (Tier 2 — SP_M_EmployeesProgram) |
| 2 | CID | int | NO | eToro customer ID (Real CID) for the employee account. FK to Dim_Customer.RealCID. Only internal/employee/analyst accounts. (Tier 2 — SP_M_EmployeesProgram, via Dim_Customer.RealCID) |
| 3 | GCID | int | YES | Global Customer ID from Dim_Customer. (Tier 2 — SP_M_EmployeesProgram, via Dim_Customer.GCID) |
| 4 | FirstName | nvarchar(50) | YES | Employee first name from Dim_Customer. PII — handle with care. (Tier 2 — SP_M_EmployeesProgram, via Dim_Customer.FirstName) |
| 5 | LastName | nvarchar(50) | YES | Employee last name from Dim_Customer. PII. (Tier 2 — SP_M_EmployeesProgram, via Dim_Customer.LastName) |
| 6 | UserName | varchar(20) | YES | eToro platform username from Dim_Customer. PII. (Tier 2 — SP_M_EmployeesProgram, via Dim_Customer.UserName) |
| 7 | Email | varchar(50) | YES | Employee email from Dim_Customer. PII. (Tier 2 — SP_M_EmployeesProgram, via Dim_Customer.Email) |
| 8 | StartProgramDate | datetime | YES | Date of the employee's first Bonus or Compensation action (ActionTypeID IN 9,36). MIN(Occurred) from Fact_CustomerAction. NULL if no bonus/compensation received. (Tier 2 — SP_M_EmployeesProgram) |
| 9 | TotalEquity | money | NO | Total account equity: ActualNWA + Liabilities from V_Liabilities at the snapshot date. ISNULL to 0. (Tier 2 — SP_M_EmployeesProgram) |
| 10 | ActualNWA | money | NO | Non-Withdrawal Amount: the portion of equity from company contributions (bonus/compensation). Can only decrease unless the employee adds personal funds. (Tier 2 — SP_M_EmployeesProgram, via V_Liabilities) |
| 11 | Credit | money | NO | Customer credit balance from V_Liabilities at the snapshot date. Used in AvgInvestment and eligibility formulas within SP_M_EmployeesProgram. (Tier 2 — V_Liabilities.Credit via Fact_SnapshotEquity.Credit) |
| 12 | AvgInvestment | money | YES | Average investment ratio over the program year: AVG((RealizedEquity - Credit) / RealizedEquity). Range 0-1; >= 0.5 qualifies for eligibility path 1. (Tier 2 — SP_M_EmployeesProgram) |
| 13 | ManualTrades | int | NO | Count of manual open positions (ActionTypeID=1) in the program year. Copy positions excluded. (Tier 2 — SP_M_EmployeesProgram) |
| 14 | NewCopy | int | NO | Count of new copy relationships started (ActionTypeID=17) in the program year. (Tier 2 — SP_M_EmployeesProgram) |
| 15 | NumOfActions | int | YES | Total actions: ManualTrades + NewCopy. >= 100 required for eligibility path 2. (Tier 2 — SP_M_EmployeesProgram) |
| 16 | AvgActionPerM | int | NO | Average actions per month: NumOfActions / months since first action in program year. (Tier 2 — SP_M_EmployeesProgram) |
| 17 | VolumeAtOpen | numeric(38,6) | NO | Total USD-converted trading volume at open for manual positions in the program year. Calculated as AmountInUnitsDecimal * InitForexRate * USD conversion rate. Copy positions excluded. (Tier 2 — SP_M_EmployeesProgram) |
| 18 | AvgMVolToEqy | numeric(38,6) | YES | Average monthly volume-to-equity ratio: AVG(monthly VolumeAtOpen / monthly AvgEquity). >= 10 required for eligibility path 2. (Tier 2 — SP_M_EmployeesProgram) |
| 19 | IsEligible | varchar(3) | NO | Program eligibility: 'Yes' if AvgInvestment >= 0.5 OR (NumOfActions >= 100 AND AvgMVolToEqy >= 10). 'No' otherwise. (Tier 2 — SP_M_EmployeesProgram) |
| 20 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted by SP_M_EmployeesProgram (GETDATE()). (Tier 5 — ETL metadata) |
| 21 | TotalPositionsAmount | money | YES | Total amount invested in open positions at the snapshot date from V_Liabilities. (Tier 2 — SP_M_EmployeesProgram, via V_Liabilities) |
| 22 | PositionPnL | decimal(16,2) | YES | Unrealized P&L across all open positions at the snapshot date from V_Liabilities. (Tier 2 — SP_M_EmployeesProgram, via V_Liabilities) |
| 23 | TotalCash | money | YES | Total cash (Credit + Mirror amounts) from V_Liabilities at the snapshot date. (Tier 2 — SP_M_EmployeesProgram, via V_Liabilities) |
| 24 | BonusCredit | money | YES | Bonus credit amount from V_Liabilities at the snapshot date. Company-funded amount that can only decrease. (Tier 2 — SP_M_EmployeesProgram, via V_Liabilities) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| CID..Email | Dim_Customer | RealCID, GCID, FirstName, LastName, UserName, Email | Direct (employee filter) |
| TotalEquity..BonusCredit | V_Liabilities | Multiple | Current-day snapshot |
| ManualTrades, NewCopy | Fact_CustomerAction | ActionTypeID | COUNT per type in program year |
| VolumeAtOpen | Dim_Position + Fact_CurrencyPriceWithSplit | AmountInUnitsDecimal, InitForexRate, Bid/Ask | SUM of USD-converted volumes |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (employee list: PlayerLevelID=4, AccountTypeID IN 7,13)
DWH_dbo.V_Liabilities (equity over program year)
DWH_dbo.Fact_CustomerAction (trades + bonus/compensation dates)
DWH_dbo.Dim_Position (manual positions for volume, MirrorID=0)
DWH_dbo.Fact_CurrencyPriceWithSplit + Dim_Instrument (USD conversion)
  |
  |-- SP_M_EmployeesProgram @Date (daily TRUNCATE+INSERT) --|
  |   #list (employee accounts)                             |
  |   #equity (V_Liabilities over program year)             |
  |   #CurrentStatus (current day equity snapshot)          |
  |   #ActionDate_and_Trades (manual trade counts)          |
  |   #prices_final (USD-converted position volumes)        |
  |   #volume (monthly volume/equity averages)              |
  |   #List2 (final aggregation + IsEligible)               |
  v
BI_DB_dbo.BI_DB_Employees_Program (2,076 rows)
  |
  (UC: _Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CID | DWH_dbo.Dim_Customer.RealCID | Employee customer dimension |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Employee Eligibility Summary

```sql
SELECT IsEligible, COUNT(*) AS employees,
    AVG(TotalEquity) AS avg_equity,
    AVG(CAST(ManualTrades AS FLOAT)) AS avg_trades,
    AVG(VolumeAtOpen) AS avg_volume
FROM [BI_DB_dbo].[BI_DB_Employees_Program]
GROUP BY IsEligible
```

### 7.2 Top Volume Traders

```sql
SELECT CID, FirstName, LastName,
    VolumeAtOpen, ManualTrades, AvgMVolToEqy,
    TotalEquity, IsEligible
FROM [BI_DB_dbo].[BI_DB_Employees_Program]
ORDER BY VolumeAtOpen DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 22 T2, 0 T3, 0 T4, 1 T5 | Elements: 24/24, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Employees_Program | Type: Table | Production Source: SP_M_EmployeesProgram (employee program analytics)*
