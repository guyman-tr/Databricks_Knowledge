# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value

> 207K-row quarterly aggregated table containing market value of open positions at quarter end, broken down by Instrument_Type and Account_Type_Group. Populated by `SP_Q_AML_FSA_Report` for FSA Seychelles (RegulationID=9) regulated customers. Sibling table to `BI_DB_Q_AML_FSA_Report_end` (customer detail) and `BI_DB_Q_AML_FSA_Report_end_Positions` (per-customer trading volumes).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_PositionPnL (primary) via `SP_Q_AML_FSA_Report` |
| **Refresh** | Quarterly (TRUNCATE+INSERT per quarter-end snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~207,198 (9 quarterly snapshots) |

---

## 1. Business Meaning

`BI_DB_Q_AML_FSA_Report_end_Market_Value` provides an aggregated view of the market value of all open positions held by FSA Seychelles regulated customers at each quarter end. Each row represents one combination of Instrument_Type, Account_Type_Group, and quarter-end date, with the total market value summed across all customers in that segment.

This table supports the FSA Seychelles quarterly AML report by quantifying the total value of assets under management across different instrument categories (Stocks, ETFs, Real Crypto, CFD Crypto, Other CFDs, Other) and account types (Natural Persons, Legal Entities, Other).

Market_Value is computed as `SUM(AmountInUnitsDecimal * RateBid * USD_CR)` from BI_DB_PositionPnL for open positions at the quarter-end date. This represents the notional USD value of all open positions.

**Note**: Early data (Q1 2024) shows many rows with empty Instrument_Type values — likely a bug in early SP runs where the instrument classification logic was incomplete or the Dim_Instrument join failed for some instruments.

---

## 2. Business Logic

### 2.1 Market Value Calculation

**What**: Total market value of open positions per instrument type and account type group at quarter end.
**Columns Involved**: `Market_Value`
**Rules**:
- Market_Value = SUM(AmountInUnitsDecimal * RateBid * USD_CR) from BI_DB_PositionPnL
- Only includes open positions (CloseDateID=0 or equivalent) at the quarter-end date
- AmountInUnitsDecimal = number of units held
- RateBid = market bid price at snapshot time
- USD_CR = USD conversion rate for non-USD denominated instruments

### 2.2 Instrument Type Classification

**What**: Categorizes instruments into regulatory reporting buckets.
**Columns Involved**: `Instrument_Type`
**Rules**:
- InstrumentTypeID = 5 → 'Stocks'
- InstrumentTypeID = 6 → 'ETFs'
- InstrumentTypeID = 10 AND IsSettled = 1 → 'Real_Crypto' (physically settled crypto)
- InstrumentTypeID = 10 AND IsSettled = 0 → 'CFD_Crypto' (crypto CFDs)
- IsSettled = 0 AND InstrumentTypeID NOT IN (5, 6, 10) → 'Other_CFDs'
- Otherwise → 'Other'
- **Bug note**: Empty Instrument_Type values appear in Q1 2024 data

### 2.3 Account Type Group Classification

**What**: Classifies account holder type for regulatory reporting.
**Columns Involved**: `Account_Type_Group`
**Rules**:
- AccountTypeGroupID = 1 → 'Natural Persons'
- AccountTypeGroupID = 2 → 'Legal Entities'
- Otherwise → 'Other'

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — small table (~207K rows across 9 quarters). Full table scans are efficient.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total market value by quarter | `SELECT End_DateID, SUM(Market_Value) FROM ... GROUP BY End_DateID` |
| Crypto vs non-crypto split | `WHERE Instrument_Type IN ('Real_Crypto','CFD_Crypto')` vs rest |
| Natural persons market exposure | `WHERE Account_Type_Group = 'Natural Persons'` |
| Quarter-over-quarter change | Self-join on End_DateID with LAG() |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Q_AML_FSA_Report_end | `End_DateID = Report_End_Date` | Combine market values with customer-level detail (aggregated level only) |
| BI_DB_Q_AML_FSA_Report_end_Positions | `End_DateID = Report_End_Date AND Instrument_Type = Instrument_Type AND Account_Type_Group = Account_Type_Group` | Combine market value with trading volume |

### 3.4 Gotchas

- **Empty Instrument_Type in early data**: Q1 2024 has rows with blank Instrument_Type — likely a bug in early SP runs. Filter with `WHERE Instrument_Type <> ''` or `WHERE LEN(Instrument_Type) > 0`.
- **End_DateID is int, not date**: Stored as YYYYMMDD integer. Use `CAST(CAST(End_DateID AS VARCHAR) AS DATE)` for date functions.
- **Aggregated table — no CID**: This table has no customer-level granularity. Use the sibling `_end` table for customer detail.
- **Market_Value is money type**: Money type has 4 decimal places. Be aware of implicit rounding in arithmetic operations.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Market_Value | money | YES | Total market value of open positions in USD: SUM(AmountInUnitsDecimal * RateBid * USD_CR) from BI_DB_PositionPnL at quarter end. Represents notional value for all customers in the Instrument_Type + Account_Type_Group segment. (Tier 2 — SP_Q_AML_FSA_Report, BI_DB_PositionPnL) |
| 2 | Account_Type_Group | varchar(250) | YES | Account holder classification: 'Natural Persons' (GroupID=1), 'Legal Entities' (GroupID=2), or 'Other'. Derived from Dim_AccountType.AccountTypeGroupID. (Tier 2 — SP_Q_AML_FSA_Report, Dim_AccountType) |
| 3 | End_DateID | int | YES | Quarter-end date as integer in YYYYMMDD format (e.g., 20240331, 20260331). Identifies which quarterly snapshot this row belongs to. (Tier 2 — SP_Q_AML_FSA_Report) |
| 4 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. All rows in a quarterly batch share the same value. (Tier 2 — SP_Q_AML_FSA_Report) |
| 5 | Instrument_Type | varchar(200) | YES | Instrument classification: 'Stocks' (IT=5), 'ETFs' (IT=6), 'Real_Crypto' (IT=10 settled), 'CFD_Crypto' (IT=10 not settled), 'Other_CFDs' (not settled non-crypto), 'Other'. Empty values appear in Q1 2024 data due to early-run bug. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Instrument) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Market_Value | BI_DB_PositionPnL | AmountInUnitsDecimal, RateBid, USD_CR | SUM(AmountInUnitsDecimal * RateBid * USD_CR) for open positions |
| Account_Type_Group | Dim_AccountType | AccountTypeGroupID | CASE: 1='Natural Persons', 2='Legal Entities', else 'Other' |
| End_DateID | (computed) | — | quarter-end YYYYMMDD integer |
| UpdateDate | (computed) | — | GETDATE() |
| Instrument_Type | Dim_Instrument | InstrumentTypeID, IsSettled | CASE classification (Stocks/ETFs/Real_Crypto/CFD_Crypto/Other_CFDs/Other) |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (open positions at quarter end)
DWH_dbo.Dim_Instrument (InstrumentTypeID, IsSettled for classification)
DWH_dbo.Dim_AccountType (AccountTypeGroupID for account type grouping)
  |
  |-- SP_Q_AML_FSA_Report (quarterly TRUNCATE+INSERT)
  |   Step 1: Filter BI_DB_PositionPnL for open positions at quarter-end date
  |   Step 2: JOIN to Dim_Instrument for InstrumentTypeID + IsSettled
  |   Step 3: Classify Instrument_Type (Stocks/ETFs/Real_Crypto/CFD_Crypto/Other_CFDs/Other)
  |   Step 4: Classify Account_Type_Group from Dim_AccountType
  |   Step 5: Aggregate SUM(AmountInUnitsDecimal * RateBid * USD_CR)
  |           GROUP BY Instrument_Type, Account_Type_Group, End_DateID
  |   Step 6: INSERT into target table
  v
BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value (207K rows, ROUND_ROBIN HEAP)
  |-- No UC target (Not_Migrated) --|
  v
(Quarterly FSA Seychelles AML regulatory report — market value component)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Market_Value | BI_DB_dbo.BI_DB_PositionPnL | Source of position values |
| Instrument_Type | DWH_dbo.Dim_Instrument | Instrument classification |
| Account_Type_Group | DWH_dbo.Dim_AccountType | Account type classification |

### 6.2 Referenced By (other objects point to this)

| Consuming Object | Relationship |
|-----------------|-------------|
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end | Sibling table — same SP, joins on End_DateID = Report_End_Date |
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions | Sibling table — same SP, joins on End_DateID = Report_End_Date |

---

## 7. Sample Queries

### 7.1 Total Market Value by Quarter

```sql
SELECT
    End_DateID,
    SUM(Market_Value) AS Total_Market_Value,
    COUNT(*) AS Segment_Count
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value
WHERE Instrument_Type <> '' OR Instrument_Type IS NOT NULL
GROUP BY End_DateID
ORDER BY End_DateID
```

### 7.2 Crypto Exposure by Quarter and Account Type

```sql
SELECT
    End_DateID,
    Account_Type_Group,
    Instrument_Type,
    Market_Value
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value
WHERE Instrument_Type IN ('Real_Crypto', 'CFD_Crypto')
ORDER BY End_DateID, Account_Type_Group
```

### 7.3 Instrument Type Breakdown — Latest Quarter

```sql
SELECT
    Instrument_Type,
    Account_Type_Group,
    Market_Value,
    Market_Value * 100.0 / SUM(Market_Value) OVER () AS Pct_of_Total
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value
WHERE End_DateID = (SELECT MAX(End_DateID) FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value)
  AND LEN(Instrument_Type) > 0
ORDER BY Market_Value DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 8/10, Completeness: 8/10*
*Object: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value | Type: Table | Production Source: BI_DB_dbo.BI_DB_PositionPnL via SP_Q_AML_FSA_Report*
