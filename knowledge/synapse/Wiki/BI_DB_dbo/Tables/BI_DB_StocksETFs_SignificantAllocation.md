# BI_DB_dbo.BI_DB_StocksETFs_SignificantAllocation

> Single-day snapshot of customers with significant stock/ETF allocation (|NetMoney| >= $10,000) — tracking money in, money out, balance, equity, account manager, instrument listing, and contact status. Currently 0 rows (TRUNCATE+INSERT; table is repopulated daily with only qualifying customers). Sourced from Dim_Position + V_Liabilities + Dim_Customer + BI_DB_UsageTracking_SF via SP_StocksETFs_SignificantAllocation (Eden Winkler, 2022).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + V_Liabilities → SP_StocksETFs_SignificantAllocation (Eden Winkler, 2022) |
| **Refresh** | Daily TRUNCATE+INSERT (SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated (not in Generic Pipeline mapping) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_StocksETFs_SignificantAllocation identifies customers who made significant stock or ETF trading activity (|NetMoney| >= $10,000) on the previous day. Each row represents one qualifying customer, enriched with their username, marketing region, account balance, realized equity, account manager name, comma-separated list of traded instrument symbols, and whether they were contacted in the last 30 days.

The SP calculates net money flow per customer by summing position open amounts (MoneyIn) and close amounts (MoneyOut) for non-mirror, stock/ETF positions (InstrumentTypeID 5,6) opened or closed on yesterday. Only valid customers (IsValidCustomer=1) are included. The table is TRUNCATEd and re-inserted daily, so it only ever contains the latest day's qualifying customers.

The INNER JOIN to #Contact (BI_DB_UsageTracking_SF) means only customers who have had at least one email or phone contact appear in the output — customers with zero contact history are excluded entirely.

Key facts:
- Currently 0 rows (may be populated after daily SP run or may have zero qualifying customers)
- TRUNCATE+INSERT pattern: no historical data retained
- Threshold: ABS(MoneyIn + MoneyOut) >= $10,000
- Sources: Dim_Position (amounts), Dim_Instrument (stock/ETF filter + symbols), Dim_Customer (UserName, country, AM), V_Liabilities (balance, equity), Dim_Country (region), Dim_Manager (AM name), BI_DB_UsageTracking_SF (contact date)
- Created by Eden Winkler (Mar 2022), migrated to Synapse by Tom Boksenbojm (Jun 2023)

---

## 2. Business Logic

### 2.1 Significant Allocation Threshold

**What**: Only customers with large net stock/ETF money flow are included.
**Columns Involved**: AddMoneyIn, AddMoneyOut, NetMoney
**Rules**:
- AddMoneyIn = SUM(Amount) for positions opened on yesterday
- AddMoneyOut = -1 × SUM(Amount) for positions closed on yesterday
- NetMoney = AddMoneyIn + AddMoneyOut
- Filter: ABS(NetMoney) >= 10,000 (USD)

### 2.2 Stock/ETF Filter

**What**: Only stock and ETF positions are counted.
**Columns Involved**: InstrumentID (from Dim_Position)
**Rules**:
- Filter: Dim_Instrument.InstrumentTypeID IN (5=Stocks, 6=ETFs)
- MirrorID = 0 (exclude copy-trading positions)
- IsValidCustomer = 1 (exclude test/internal accounts)

### 2.3 Contact Status

**What**: Indicates whether the customer was contacted by the sales team in the last 30 days.
**Columns Involved**: ContactedLastMonth
**Rules**:
- Source: MAX(CreatedDate) from BI_DB_UsageTracking_SF where ActionName IN ('Completed_Contact_Email__c', 'Phone_Call_Succeed__c')
- CASE: DATEDIFF(DAY, LastContactedDate, GETDATE()) > 30 → 'Not Contacted', else 'Contacted'
- INNER JOIN: customers without any contact record are excluded from the table entirely

### 2.4 Instrument Listing

**What**: Comma-separated list of instruments the customer traded on the qualifying day.
**Columns Involved**: Listing
**Rules**:
- STRING_AGG(Symbol, ',') from the per-CID×Symbol position data
- Includes both opened and closed instrument symbols

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no index optimization. Table is small (daily snapshot) so full scans are acceptable.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Who had the largest net allocation yesterday? | `ORDER BY ABS(NetMoney) DESC` |
| Which regions have the most significant allocators? | `GROUP BY Region` |
| Uncontacted high-value customers | `WHERE ContactedLastMonth = 'Not Contacted' ORDER BY ABS(NetMoney) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Extended customer profile |

### 3.4 Gotchas

- **Table may be empty**: TRUNCATE+INSERT pattern with strict qualifying criteria (|NetMoney| >= $10K AND contact history required). Zero rows is a valid state.
- **INNER JOIN to contact**: Customers without any email/phone contact history in BI_DB_UsageTracking_SF are silently excluded — not just flagged as 'Not Contacted'.
- **Balance and Equity are integers**: Cast from money — fractional values truncated.
- **Manager is full name**: Concatenation of Dim_Manager.FirstName + ' ' + LastName. No ManagerID column for re-joining.
- **SP description bug**: The SP header says "Insert Data into BI_DB_CID_DailyPanel_Club" but it actually writes to BI_DB_StocksETFs_SignificantAllocation.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Description | Tag Pattern |
|------|-------------|-------------|
| Tier 1 | Upstream wiki verbatim | `(Tier 1 — source)` |
| Tier 2 | SP code / DDL evidence | `(Tier 2 — SP)` |
| Tier 5 | ETL metadata | `(Tier 5 — ETL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer identifier. The user who traded stocks/ETFs with significant allocation. Passthrough from Dim_Position.CID. (Tier 2 — SP_StocksETFs_SignificantAllocation, DWH_dbo.Dim_Position.CID) |
| 2 | UserName | nvarchar(50) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 3 | Region | nvarchar(50) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. Passthrough from Dim_Country via Dim_Customer.CountryID. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 4 | AddMoneyIn | int | YES | Total USD amount invested in stock/ETF positions opened on yesterday. SUM(Amount) for positions where OpenDateID = @YestardayDateID. Cast to int (fractional truncation). (Tier 2 — SP_StocksETFs_SignificantAllocation, SUM of Dim_Position.Amount) |
| 5 | AddMoneyOut | int | YES | Total USD amount from stock/ETF positions closed on yesterday. -1 × SUM(Amount) for positions where CloseDateID = @YestardayDateID. Negative values indicate money flowing out of positions. Cast to int. (Tier 2 — SP_StocksETFs_SignificantAllocation, SUM of Dim_Position.Amount) |
| 6 | NetMoney | int | YES | Net money flow: AddMoneyIn + AddMoneyOut. Positive = net buying, negative = net selling. Only rows with ABS(NetMoney) >= 10,000 are retained. Cast to int. (Tier 2 — SP_StocksETFs_SignificantAllocation, computed) |
| 7 | Balance | int | YES | Customer credit balance (cash) from V_Liabilities.Credit on @YestardayDateID. Cast to int. (Tier 2 — SP_StocksETFs_SignificantAllocation, DWH_dbo.V_Liabilities.Credit) |
| 8 | RealizedEquity | int | YES | Customer realized equity from V_Liabilities.RealizedEquity on @YestardayDateID. Cast to int. (Tier 2 — SP_StocksETFs_SignificantAllocation, DWH_dbo.V_Liabilities.RealizedEquity) |
| 9 | Manager | varchar(max) | YES | Account manager full name: Dim_Manager.FirstName + ' ' + Dim_Manager.LastName via Dim_Customer.AccountManagerID. (Tier 2 — SP_StocksETFs_SignificantAllocation, DWH_dbo.Dim_Manager) |
| 10 | Listing | nvarchar(max) | YES | Comma-separated list of instrument symbols (Dim_Instrument.Symbol) that the customer opened or closed on yesterday. STRING_AGG(Symbol, ','). (Tier 2 — SP_StocksETFs_SignificantAllocation, DWH_dbo.Dim_Instrument.Symbol) |
| 11 | ContactedLastMonth | nvarchar(20) | YES | Contact status: 'Contacted' if the customer had a successful email or phone contact within the last 30 days, 'Not Contacted' if the most recent contact was > 30 days ago. Based on BI_DB_UsageTracking_SF where ActionName IN ('Completed_Contact_Email__c', 'Phone_Call_Succeed__c'). (Tier 2 — SP_StocksETFs_SignificantAllocation, BI_DB_UsageTracking_SF.CreatedDate) |
| 12 | UpdateDate | date | YES | Row load timestamp set to GETDATE() at insert time. Not a business date. (Tier 5 — ETL metadata, GETDATE()) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Position | CID | Passthrough (GROUP BY) |
| UserName | DWH_dbo.Dim_Customer | UserName | Dim-lookup passthrough |
| Region | DWH_dbo.Dim_Country | Region | Dim-lookup via Dim_Customer.CountryID |
| AddMoneyIn | DWH_dbo.Dim_Position | Amount | SUM for OpenDateID = yesterday |
| AddMoneyOut | DWH_dbo.Dim_Position | Amount | -1 × SUM for CloseDateID = yesterday |
| NetMoney | Computed | MoneyIn + MoneyOut | Sum of AddMoneyIn + AddMoneyOut |
| Balance | DWH_dbo.V_Liabilities | Credit | Passthrough for DateID = yesterday |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | Passthrough for DateID = yesterday |
| Manager | DWH_dbo.Dim_Manager | FirstName, LastName | Concatenation: FirstName + ' ' + LastName |
| Listing | DWH_dbo.Dim_Instrument | Symbol | STRING_AGG(Symbol, ',') per CID |
| ContactedLastMonth | BI_DB_dbo.BI_DB_UsageTracking_SF | CreatedDate | CASE DATEDIFF > 30 |
| UpdateDate | ETL | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (stocks/ETFs opened/closed yesterday, non-mirror, valid customers)
  + DWH_dbo.Dim_Instrument (Symbol, InstrumentTypeID filter)
  + DWH_dbo.Dim_Customer (UserName, CountryID, AccountManagerID)
  |-- #Pos: per CID × Symbol money in/out ---|
  |-- #String_POS: per CID aggregation + STRING_AGG(Symbol) ---|
  + BI_DB_dbo.BI_DB_UsageTracking_SF (last contact date)
  |-- #Contact: MAX(CreatedDate) per CID ---|
  + DWH_dbo.V_Liabilities (Balance, RealizedEquity on yesterday)
  + DWH_dbo.Dim_Country (Region)
  + DWH_dbo.Dim_Manager (FirstName + LastName)
  |-- SP_StocksETFs_SignificantAllocation ---|
  |  Filter: ABS(NetMoney) >= $10,000 + INNER JOIN #Contact
  |  TRUNCATE + INSERT
  v
BI_DB_dbo.BI_DB_StocksETFs_SignificantAllocation (single-day snapshot)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer profile lookup |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship |
|-------------------|-------------|
| Sales/marketing team dashboards | Primary consumer (manual review of significant allocators) |

---

## 7. Sample Queries

### 7.1 Top Uncontacted High-Value Allocators

```sql
SELECT CID, UserName, Region, NetMoney, Balance, RealizedEquity,
       Manager, Listing
FROM BI_DB_dbo.BI_DB_StocksETFs_SignificantAllocation
WHERE ContactedLastMonth = 'Not Contacted'
ORDER BY ABS(NetMoney) DESC
```

### 7.2 Regional Breakdown of Significant Allocators

```sql
SELECT Region,
       COUNT(*) AS Customers,
       SUM(AddMoneyIn) AS TotalMoneyIn,
       SUM(AddMoneyOut) AS TotalMoneyOut,
       SUM(NetMoney) AS TotalNet
FROM BI_DB_dbo.BI_DB_StocksETFs_SignificantAllocation
GROUP BY Region
ORDER BY TotalNet DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 1 T1, 10 T2, 0 T3, 0 T4, 1 T5 | Elements: 12/12, Logic: 7/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_StocksETFs_SignificantAllocation | Type: Table | Production Source: Dim_Position + V_Liabilities via SP_StocksETFs_SignificantAllocation*
