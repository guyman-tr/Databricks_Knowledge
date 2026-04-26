# BI_DB_dbo.BI_DB_Employee_Crypto_NWA

> 3,006-row monthly employee crypto Net Wallet Amount report aggregating crypto holdings across all eToro employee/analyst accounts by instrument, with EOD bid pricing. Covers 185 crypto instruments from January 2024 to March 2026 (27 EOM dates). Populated by `SP_Employee_Crypto_NWA` via DELETE-INSERT per Date, sourcing employee accounts from `Fact_SnapshotCustomer` (PlayerLevelID=4, AccountTypeID IN 7,13), positions from `BI_DB_PositionPnL`, and EOD rates from `BI_DB_Crypto_NOP`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH/BI_DB aggregation via `SP_Employee_Crypto_NWA` |
| **Refresh** | SB_Daily, but only executes on EOM dates (Dim_Date.IsLastDayOfMonth='Y') |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Adi Meidan (2024-05-09) |

---

## 1. Business Meaning

This table tracks the aggregate crypto holdings of eToro employee and analyst accounts on a monthly (EOM) basis. Each row represents one crypto instrument on one month-end date, showing the total units held across all eligible employee accounts and the EOD bid price for valuation.

**Purpose**: Regulatory and compliance reporting — monitoring employee crypto exposure. NWA = Net Wallet Amount, measuring the firm's employee crypto position for risk management.

**Population**: Only internal accounts — `PlayerLevelID=4` (Internal), `AccountTypeID IN (7=Employee, 13=Analyst)`, not closed (`AccountStatusID != 2`), not blocked (`PlayerStatusID != 2`). Also includes hardcoded `RealCID=149` (special account). Further filtered to accounts with `Liabilities > 0` AND `TotalCryptoPositionAmount > 0`.

**Grain**: Instrument-level per date — individual employee CIDs are aggregated away (SUM of Units across all employees).

---

## 2. Business Logic

### 2.1 Employee Population Filtering

**What**: Identifies eligible employee/analyst accounts with active crypto holdings.
**Columns Involved**: (population filter, not output columns)
**Rules**:
- PlayerLevelID = 4 (Internal accounts only)
- AccountTypeID IN (7, 13) — Employee Account or Analyst
- AccountStatusID != 2 (not closed)
- PlayerStatusID != 2 (not blocked)
- RealCID = 149 hardcoded inclusion (special account)
- Liabilities > 0 AND TotalCryptoPositionAmount > 0 (must have active funded crypto positions)

### 2.2 Unit Aggregation

**What**: Sums crypto position units across all employees per instrument.
**Columns Involved**: Units, Instrument
**Rules**:
- Units = SUM(BI_DB_PositionPnL.AmountInUnitsDecimal) per instrument per date
- Only crypto instruments: Dim_Instrument.InstrumentTypeID = 10
- Instrument = Dim_Instrument.Name (e.g., 'BTC/USD', 'ETH/USD')
- CID-level detail is aggregated away — output is instrument-level only

### 2.3 EOD Rate Lookup

**What**: Gets the end-of-day bid price for each crypto instrument.
**Columns Involved**: Rate
**Rules**:
- Rate = MAX(EOD_Bid_Price) from BI_DB_Crypto_NOP for the instrument on the same date
- Joined on Date + InstrumentName = Instrument

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — table is very small (~3K rows). No optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Total employee crypto exposure on a date | `SELECT SUM(Units * Rate) FROM ... WHERE [Date] = '2026-03-31'` |
| Top crypto holdings by value | `SELECT Instrument, Units, Rate, Units * Rate AS value FROM ... WHERE [Date] = '2026-03-31' ORDER BY value DESC` |
| Crypto exposure trend | `SELECT [Date], SUM(Units * Rate) AS total_exposure FROM ... GROUP BY [Date] ORDER BY [Date]` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Instrument | Instrument = Name | Full instrument metadata |

### 3.4 Gotchas

- **EOM only**: Only month-end dates exist — do not expect daily data
- **No CID column**: Employee identities are aggregated away — this table shows firm-level exposure, not individual
- **No DateID**: Uses Date (date type), not DateID (int). Join with Dim_Date if you need DateID
- **Units can be large**: Some instruments have very small unit prices (e.g., IOTX at $0.01) resulting in large unit counts
- **Rate is MAX**: If multiple bid prices exist in BI_DB_Crypto_NOP for the same instrument/date, MAX is used
- **RealCID 149 hardcoded**: This special account is always included regardless of other filters

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
| 1 | Date | date | YES | Month-end date of the snapshot. Only EOM dates exist (Dim_Date.IsLastDayOfMonth='Y'). DELETE-INSERT partition key. (Tier 2 — SP_Employee_Crypto_NWA) |
| 2 | Instrument | varchar(50) | YES | Crypto instrument name from Dim_Instrument.Name (e.g., 'BTC/USD', 'ETH/USD', 'SOL/USD'). Only crypto instruments (InstrumentTypeID=10). 185 distinct values across the dataset. (Tier 2 — SP_Employee_Crypto_NWA, via Dim_Instrument.Name) |
| 3 | Units | decimal(12,4) | YES | Total units held across all employee/analyst accounts for this instrument on this date. SUM(BI_DB_PositionPnL.AmountInUnitsDecimal) aggregated from individual account positions. (Tier 2 — SP_Employee_Crypto_NWA) |
| 4 | Rate | decimal(12,6) | YES | End-of-day bid price for the instrument from BI_DB_Crypto_NOP.EOD_Bid_Price. MAX used when multiple prices exist. Multiply Units * Rate for USD value. (Tier 2 — SP_Employee_Crypto_NWA, via BI_DB_Crypto_NOP) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_Employee_Crypto_NWA (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Date | V_Liabilities | FullDate | Direct (EOM only) |
| Instrument | Dim_Instrument | Name | Direct (InstrumentTypeID=10) |
| Units | BI_DB_PositionPnL | AmountInUnitsDecimal | SUM across all employee accounts |
| Rate | BI_DB_Crypto_NOP | EOD_Bid_Price | MAX per instrument/date |
| UpdateDate | ETL | GETDATE() | Timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (employee filter: PlayerLevelID=4)
DWH_dbo.V_Liabilities (Liabilities + TotalCryptoPositionAmount > 0)
DWH_dbo.Dim_Date (IsLastDayOfMonth='Y')
DWH_dbo.Dim_Range (date range resolution)
BI_DB_dbo.BI_DB_PositionPnL (position units by instrument)
DWH_dbo.Dim_Instrument (InstrumentTypeID=10, Name)
BI_DB_dbo.BI_DB_Crypto_NOP (EOD bid prices)
  |
  |-- SP_Employee_Crypto_NWA @Date (EOM only) --|
  |   #pop_Emp → #Pop_Emp_Final (funded+crypto) |
  |   #Pop_Emp_Final_Crypto (SUM units/inst)    |
  |   #EOD_Rate1 (MAX bid price)                |
  |   #final (JOIN units + rates)               |
  |   DELETE WHERE Date = @Date                  |
  |   INSERT into BI_DB_Employee_Crypto_NWA     |
  v
BI_DB_dbo.BI_DB_Employee_Crypto_NWA (3,006 rows)
  |
  (UC: _Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| Instrument | DWH_dbo.Dim_Instrument.Name | Crypto instrument lookup |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Top Employee Crypto Holdings by Value

```sql
SELECT Instrument, Units, Rate,
    Units * Rate AS usd_value
FROM [BI_DB_dbo].[BI_DB_Employee_Crypto_NWA]
WHERE [Date] = '2026-03-31'
ORDER BY usd_value DESC
```

### 7.2 Monthly Total Crypto Exposure Trend

```sql
SELECT [Date],
    COUNT(DISTINCT Instrument) AS instruments_held,
    SUM(Units * Rate) AS total_usd_exposure
FROM [BI_DB_dbo].[BI_DB_Employee_Crypto_NWA]
GROUP BY [Date]
ORDER BY [Date]
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4, 1 T5 | Elements: 5/5, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Employee_Crypto_NWA | Type: Table | Production Source: SP_Employee_Crypto_NWA (employee crypto aggregation)*
