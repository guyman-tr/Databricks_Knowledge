# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions

> 1.09M-row quarterly table capturing per-customer, per-instrument-type trading volume and value within each quarter for FSA Seychelles (RegulationID=9) regulated customers. Populated by `SP_Q_AML_FSA_Report` alongside sibling tables `BI_DB_Q_AML_FSA_Report_end` (customer detail) and `BI_DB_Q_AML_FSA_Report_end_Market_Value` (aggregated market values). Population: IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position (primary) via `SP_Q_AML_FSA_Report` |
| **Refresh** | Quarterly (TRUNCATE+INSERT per quarter-end snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~1,085,687 (9 quarterly snapshots) |

---

## 1. Business Meaning

`BI_DB_Q_AML_FSA_Report_end_Positions` captures per-customer, per-instrument-type trading activity within each quarter for the FSA Seychelles AML regulatory report. Each row represents one CID's trading volume and value for a specific instrument type (Stocks, ETFs, Real_Crypto, CFD_Crypto, Other_CFDs, Other) within a single quarter.

The table enables analysis of trading behavior patterns across instrument types for regulatory compliance monitoring. TradingVolume measures the total number of units traded (opens + closes), while TradingValue measures the total USD-equivalent monetary value of those trades.

This is one of three companion tables produced by `SP_Q_AML_FSA_Report`:
- `BI_DB_Q_AML_FSA_Report_end` — customer-level demographic and status snapshot
- `BI_DB_Q_AML_FSA_Report_end_Market_Value` — aggregated market value by instrument type
- `BI_DB_Q_AML_FSA_Report_end_Positions` (this table) — per-customer trading volumes and values

---

## 2. Business Logic

### 2.1 Trading Volume Calculation

**What**: Total units traded per customer per instrument type within the quarter.
**Columns Involved**: `TradingVolume`
**Rules**:
- For position opens during the quarter: SUM(InitialUnits) — the number of units at position opening
- For position closes during the quarter: SUM(AmountInUnitsDecimal) — the number of units at position closing
- TradingVolume = sum of both open and close unit quantities
- Measured in instrument units (shares, coins, lots, etc.)

### 2.2 Trading Value Calculation

**What**: Total USD-equivalent value of trades per customer per instrument type within the quarter.
**Columns Involved**: `TradingValue`
**Rules**:
- For position opens: SUM(InitialUnits * InitForexRate * InitConversionRate) — value at time of opening
- For position closes: SUM(AmountInUnitsDecimal * EndForexRate * EndForex_USDConversionRate) — value at time of closing
- TradingValue = sum of both open and close monetary values in USD
- Forex rates convert from instrument currency to USD

### 2.3 Instrument Type Classification

**What**: Categorizes instruments into regulatory reporting buckets.
**Columns Involved**: `Instrument_Type`
**Rules**:
- InstrumentTypeID = 5 → 'Stocks'
- InstrumentTypeID = 6 → 'ETFs'
- InstrumentTypeID = 10 AND IsSettled = 1 → 'Real_Crypto' (physically settled crypto)
- InstrumentTypeID = 10 AND IsSettled = 0 → 'CFD_Crypto' (crypto CFDs)
- IsSettled = 0 AND InstrumentTypeID NOT IN (5, 6, 10) → 'Other_CFDs'
- Otherwise → 'Other'

### 2.4 Account Type Group Classification

**What**: Classifies account holder type for regulatory reporting.
**Columns Involved**: `Account_Type_Group`
**Rules**:
- AccountTypeGroupID = 1 → 'Natural Persons'
- AccountTypeGroupID = 2 → 'Legal Entities'
- Otherwise → 'Other'

### 2.5 Activity Flag

**What**: Customer activity indicator for the quarter.
**Columns Involved**: `Is_Active`
**Rules**:
- Is_Active = 1 if the customer opened/closed any position or had any deposit/cashout during the quarter
- Same logic as in sibling `BI_DB_Q_AML_FSA_Report_end` table

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — 1.09M rows across 9 quarters. Filter on `Report_End_Date` for single-quarter analysis. No hash key; JOINs to other tables on CID will be broadcast joins.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top traders by value | `SELECT TOP 100 CID, SUM(TradingValue) FROM ... WHERE Report_End_Date = X GROUP BY CID ORDER BY 2 DESC` |
| Crypto trading volume trend | `WHERE Instrument_Type IN ('Real_Crypto','CFD_Crypto') GROUP BY Report_End_Date` |
| Instrument type breakdown by quarter | `SELECT Report_End_Date, Instrument_Type, SUM(TradingValue) FROM ... GROUP BY Report_End_Date, Instrument_Type` |
| Inactive customers with positions | `WHERE Is_Active = 0 AND TradingVolume > 0` — should not exist logically |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Q_AML_FSA_Report_end | `CID = CID AND Report_End_Date = Report_End_Date` | Enrich with customer demographics and equity |
| BI_DB_Q_AML_FSA_Report_end_Market_Value | `Report_End_Date = End_DateID AND Instrument_Type = Instrument_Type AND Account_Type_Group = Account_Type_Group` | Combine trading volume with market value |
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer profile |

### 3.4 Gotchas

- **Report_End_Date is int, not date**: Stored as YYYYMMDD integer (e.g., 20240331). Use `CAST(CAST(Report_End_Date AS VARCHAR) AS DATE)` for date functions.
- **TradingVolume units vary by instrument**: Stocks = shares, Crypto = coins, CFDs = lots. Do not compare TradingVolume across instrument types without normalization.
- **TradingValue is in USD**: Forex conversion rates applied at trade time (open or close), not at quarter end. Values are historical, not mark-to-market.
- **Multiple rows per CID per quarter**: One row per CID per Instrument_Type per quarter. A customer trading Stocks and Crypto will have 2 rows for the same quarter.
- **Money type columns**: TradingVolume and TradingValue are money type (4 decimal places). Be aware of implicit rounding.
- **Is_Active may seem redundant**: A row with TradingVolume > 0 implies activity, but Is_Active also includes deposit/cashout-only activity from the sibling table's logic.

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
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Mapped from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Instrument_Type | varchar(250) | YES | Instrument classification: 'Stocks' (IT=5), 'ETFs' (IT=6), 'Real_Crypto' (IT=10 settled), 'CFD_Crypto' (IT=10 not settled), 'Other_CFDs' (not settled non-crypto), 'Other'. Derived from Dim_Instrument. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Instrument) |
| 3 | TradingVolume | money | YES | Total units traded during the quarter: SUM of InitialUnits (opens) + AmountInUnitsDecimal (closes) from Dim_Position. Units depend on instrument type (shares, coins, lots). (Tier 2 — SP_Q_AML_FSA_Report, Dim_Position) |
| 4 | TradingValue | money | YES | Total USD-equivalent trade value during the quarter: SUM of (InitialUnits*InitForexRate*InitConversionRate) for opens + (AmountInUnitsDecimal*EndForexRate*EndForex_USDConversionRate) for closes. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Position) |
| 5 | Report_End_Date | int | YES | Quarter-end date as integer in YYYYMMDD format (e.g., 20240331, 20260331). Identifies which quarterly snapshot this row belongs to. (Tier 2 — SP_Q_AML_FSA_Report) |
| 6 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. All rows in a quarterly batch share the same value. (Tier 2 — SP_Q_AML_FSA_Report) |
| 7 | Is_Active | int | YES | Activity flag. 1 if customer had position or deposit/cashout activity during the quarter, else 0. Same logic as sibling _end table. (Tier 2 — SP_Q_AML_FSA_Report) |
| 8 | Country | varchar(250) | YES | Full country name in English. Passthrough from Dim_Country via CountryID. (Tier 1 — Dictionary.Country) |
| 9 | Account_Type_Group | varchar(250) | YES | Account holder classification: 'Natural Persons' (GroupID=1), 'Legal Entities' (GroupID=2), or 'Other'. Derived from Dim_AccountType.AccountTypeGroupID. (Tier 2 — SP_Q_AML_FSA_Report, Dim_AccountType) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | rename (RealCID → CID) via Dim_Customer |
| Instrument_Type | Dim_Instrument | InstrumentTypeID, IsSettled | CASE classification (Stocks/ETFs/Real_Crypto/CFD_Crypto/Other_CFDs/Other) |
| TradingVolume | Dim_Position | InitialUnits, AmountInUnitsDecimal | SUM of opens + closes during quarter |
| TradingValue | Dim_Position | InitialUnits, InitForexRate, InitConversionRate, AmountInUnitsDecimal, EndForexRate, EndForex_USDConversionRate | SUM of USD-converted open + close values |
| Report_End_Date | (computed) | — | quarter-end YYYYMMDD integer |
| UpdateDate | (computed) | — | GETDATE() |
| Is_Active | Dim_Position + Fact_CustomerAction | CID | 1 if position or deposit/cashout activity |
| Country | Dictionary.Country | Name | dim-lookup via Dim_Country |
| Account_Type_Group | Dim_AccountType | AccountTypeGroupID | CASE: 1='Natural Persons', 2='Legal Entities', else 'Other' |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (position opens/closes during quarter)
DWH_dbo.Dim_Instrument (InstrumentTypeID, IsSettled for classification)
DWH_dbo.Dim_Customer (HASH(RealCID) — CID mapping)
DWH_dbo.Dim_Country (REPLICATE — Country name)
DWH_dbo.Dim_AccountType (REPLICATE — Account_Type_Group)
DWH_dbo.Fact_CustomerAction (deposit/cashout activity for Is_Active)
  |
  |-- SP_Q_AML_FSA_Report (quarterly TRUNCATE+INSERT)
  |   Step 1: Filter Dim_Position for opens/closes within the quarter date range
  |   Step 2: JOIN to Dim_Instrument for InstrumentTypeID + IsSettled
  |   Step 3: Classify Instrument_Type (Stocks/ETFs/Real_Crypto/CFD_Crypto/Other_CFDs/Other)
  |   Step 4: Compute TradingVolume = SUM(InitialUnits opens + AmountInUnitsDecimal closes)
  |   Step 5: Compute TradingValue = SUM(units * forex rates) for opens and closes
  |   Step 6: Aggregate per CID, Instrument_Type, quarter
  |   Step 7: JOIN Country + Account_Type_Group + Is_Active
  |   Step 8: INSERT into target table
  v
BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions (1.09M rows, ROUND_ROBIN HEAP)
  |-- No UC target (Not_Migrated) --|
  v
(Quarterly FSA Seychelles AML regulatory report — positions component)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Primary customer dimension |
| Country | DWH_dbo.Dim_Country (Name) | Country dimension lookup |
| Instrument_Type | DWH_dbo.Dim_Instrument | Instrument classification |
| TradingVolume, TradingValue | DWH_dbo.Dim_Position | Position open/close data |
| Account_Type_Group | DWH_dbo.Dim_AccountType | Account type classification |
| Is_Active | DWH_dbo.Fact_CustomerAction | Deposit/cashout activity |

### 6.2 Referenced By (other objects point to this)

| Consuming Object | Relationship |
|-----------------|-------------|
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end | Sibling table — same SP, joins on CID + Report_End_Date |
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value | Sibling table — same SP, joins on Report_End_Date + Instrument_Type + Account_Type_Group |

---

## 7. Sample Queries

### 7.1 Top 20 Traders by Value — Latest Quarter

```sql
SELECT TOP 20
    CID,
    Country,
    Account_Type_Group,
    SUM(TradingValue) AS Total_Trading_Value,
    SUM(TradingVolume) AS Total_Trading_Volume
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions
WHERE Report_End_Date = (SELECT MAX(Report_End_Date) FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions)
GROUP BY CID, Country, Account_Type_Group
ORDER BY Total_Trading_Value DESC
```

### 7.2 Crypto Trading Trend by Quarter

```sql
SELECT
    Report_End_Date,
    Instrument_Type,
    COUNT(DISTINCT CID) AS Unique_Traders,
    SUM(TradingValue) AS Total_Value,
    SUM(TradingVolume) AS Total_Volume
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions
WHERE Instrument_Type IN ('Real_Crypto', 'CFD_Crypto')
GROUP BY Report_End_Date, Instrument_Type
ORDER BY Report_End_Date, Instrument_Type
```

### 7.3 Per-Customer Trading Summary with Demographics

```sql
SELECT
    p.CID,
    e.Country,
    e.SeychellesCategorization,
    e.Account_Type_Group,
    p.Instrument_Type,
    p.TradingVolume,
    p.TradingValue,
    e.UnrealizedEquity,
    e.RealizedEquity
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions p
JOIN BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end e
  ON p.CID = e.CID AND p.Report_End_Date = e.Report_End_Date
WHERE p.Report_End_Date = 20260331
  AND p.TradingValue > 100000
ORDER BY p.TradingValue DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 7 T2, 0 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 8/10, Completeness: 8/10*
*Object: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions | Type: Table | Production Source: DWH_dbo.Dim_Position via SP_Q_AML_FSA_Report*
