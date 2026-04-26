# BI_DB_dbo.BI_DB_Daily_Open_Closed_Position

> 7.6M-row daily aggregated open and close position amounts by regulation, instrument type, player status, club, and country — spanning Jan 2023 to present. Sourced from DWH_dbo.Dim_Position joined to Fact_SnapshotCustomer point-in-time dimensions, refreshed daily via SP_Daily_Open_Closed_Position (delete-insert by date). Stocks are split into US Stocks and Non-US Stocks based on ISIN code.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + Fact_SnapshotCustomer via SP_Daily_Open_Closed_Position |
| **Refresh** | Daily incremental (DELETE WHERE Date=@date, then INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table tracks daily aggregated open and close position amounts across the eToro trading platform, providing a breakdown by regulatory jurisdiction, instrument type, customer validity, settlement type, player status, club tier, and country.

Each row represents a unique combination of these dimensions for a single trading date. The table captures **7.6M rows** from **January 2023 to April 2026** (~1,200 dates). The grain is Date x Regulation x IsValidCustomer x IsCreditReportValidCB x IsSettled x InstrumentType x PlayerStatus x Club x Country.

The SP aggregates two position flows:
- **Open positions**: SUM of InitialAmountCents/100 from Dim_Position where positions opened on @date (Buy Amount)
- **Close positions**: SUM of (Amount + NetProfit) from Dim_Position where positions closed on @date (Sell Amount)
- **Total Amount** = Buy Amount - Sell Amount (net flow)

Customer attributes are point-in-time from Fact_SnapshotCustomer via Dim_Range SCD2 join, ensuring the regulation, player status, club, and country reflect the customer's state on the position's open/close date.

Partial close child positions are excluded from opens (ISNULL(IsPartialCloseChild,0)=0) but NOT from closes.

Author: Adi Meidan. Logic updated 2024-05-30 (final table restructure), 2024-06-20 (US/Non-US Stocks separation).

---

## 2. Business Logic

### 2.1 US/Non-US Stock Classification

**What**: Stocks (InstrumentTypeID=5) are split into US Stocks and Non-US Stocks based on ISIN code.
**Columns Involved**: InstrumentType, Dim_Instrument.ISINCode, Dim_Instrument.InstrumentTypeID
**Rules**:
- ISINCode LIKE '%US%' AND InstrumentTypeID=5 → 'US Stocks'
- ISINCode NOT LIKE '%US%' AND InstrumentTypeID=5 → 'Non-US Stocks'
- All other instrument types → use Dim_Instrument.InstrumentType as-is (Currencies, Commodities, Indices, ETF, Crypto Currencies)
- A residual 'Stocks' value exists in data (86 rows in 2026) — likely edge cases where the CASE logic was not applied or InstrumentTypeID changed

### 2.2 Open vs Close Amount Asymmetry

**What**: Buy Amount and Sell Amount use different calculation bases.
**Columns Involved**: Buy Amount, Sell Amount, Total Amount
**Rules**:
- Buy Amount = SUM(Dim_Position.InitialAmountCents / 100) for open positions — represents the initial investment at open
- Sell Amount = SUM(Dim_Position.Amount + Dim_Position.NetProfit) for close positions — represents the position value at close including realized PnL
- Total Amount = Buy Amount - Sell Amount — positive means net inflow (more opened than closed), negative means net outflow
- These are NOT symmetrical: buy uses initial cents, sell uses amount + profit

### 2.3 IsSettled Asymmetry Between Opens and Closes

**What**: The IsSettled column is computed differently for open vs close positions.
**Columns Involved**: IsSettled
**Rules**:
- For opens: ISNULL(Dim_Position.IsSettledOnOpen, Dim_Position.IsSettled) — prefers the snapshot at open time
- For closes: Dim_Position.IsSettled — uses the current settlement flag
- 1 = real/settled asset, 0 = CFD
- This asymmetry means a position that changed settlement status between open and close may appear with IsSettled=1 in the open row and IsSettled=0 in the close row (or vice versa)

### 2.4 Point-in-Time Customer Attributes

**What**: Customer dimension attributes are resolved at the position's open/close date, not current state.
**Columns Involved**: Regulation, IsValidCustomer, IsCreditReportValidCB, PlayerStatus, Club, Country
**Rules**:
- Fact_SnapshotCustomer joined via Dim_Range SCD2: DateRangeID with OpenDateID/CloseDateID BETWEEN FromDateID AND ToDateID
- A customer who changed regulation or club between two position dates will appear under different dimension values on each date
- IsValidCustomer and IsCreditReportValidCB are ETL-computed flags from Fact_SnapshotCustomer reflecting eligibility at that point in time

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no co-location benefit for any particular join pattern. HEAP storage — no index. For large date-range queries, always filter on DateID or Date to limit scan scope.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Daily net position flow by regulation | `SELECT Date, Regulation, SUM([Buy Amount]), SUM([Sell Amount]), SUM([Total Amount]) WHERE IsValidCustomer=1 AND IsCreditReportValidCB=1 GROUP BY Date, Regulation` |
| CFD vs Real volume comparison | Filter by `IsSettled` (1=Real, 0=CFD) |
| Instrument type breakdown for valid settled customers | `WHERE IsValidCustomer=1 AND IsCreditReportValidCB=1 AND IsSettled=1` |
| US vs Non-US stock split | Filter `InstrumentType IN ('US Stocks','Non-US Stocks')` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Date | DateID = Dim_Date.DateID | Calendar attributes (weekday, month) |

### 3.4 Gotchas

- **Column names with spaces**: `[Buy Amount]`, `[Sell Amount]`, `[Total Amount]` require bracket quoting in SQL
- **Buy/Sell asymmetry**: Buy uses InitialAmountCents/100, Sell uses Amount+NetProfit — these are not the same measurement basis
- **IsSettled asymmetry**: Open and close rows for the same positions may have different IsSettled values (see §2.3)
- **Residual 'Stocks' value**: A small number of rows (86 in 2026) have InstrumentType='Stocks' instead of 'US Stocks' or 'Non-US Stocks'
- **Regulation exclusions**: Commented-out query in SP suggests excluding eToroUS, FinCEN, FinCEN+FINRA for certain analyses
- **No CID-level grain**: This is an aggregate table — no customer-level drill-down is possible

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (DWH_dbo dimension/fact wiki) | Highest — verified against production documentation |
| Tier 2 | SP code analysis | High — traced from ETL logic |
| Tier 5 | Propagation / ETL metadata | Standard ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | Trading date when positions were opened or closed. CAST as DATE from Dim_Position.OpenOccurred (for opens) or CloseOccurred (for closes). Used as the DELETE key for incremental refresh. (Tier 2 — SP_Daily_Open_Closed_Position) |
| 2 | Regulation | varchar(20) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Resolved via Fact_SnapshotCustomer.RegulationID → Dim_Regulation.DWHRegulationID at point-in-time. 12 values: CySEC, FCA, FSA Seychelles, FSRA, ASIC & GAML, BVI, ASIC, FinCEN+FINRA, MAS, FinCEN, eToroUS, NYDFS+FINRA. (Tier 1 — DWH_dbo.Dim_Regulation) |
| 3 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See Fact_SnapshotCustomer §2.2. Point-in-time via Dim_Range. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 4 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. Point-in-time via Dim_Range. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 5 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. DWH note: for opens uses ISNULL(IsSettledOnOpen, IsSettled), for closes uses IsSettled directly — values may differ for the same position between open and close rows. (Tier 1 — DWH_dbo.Dim_Position) |
| 6 | InstrumentType | varchar(50) | YES | Instrument asset class with US/Non-US stock split. CASE: ISINCode LIKE '%US%' AND InstrumentTypeID=5 → 'US Stocks'; NOT LIKE '%US%' AND InstrumentTypeID=5 → 'Non-US Stocks'; else Dim_Instrument.InstrumentType. 8 values: US Stocks, Non-US Stocks, ETF, Crypto Currencies, Commodities, Indices, Currencies, Stocks (residual). (Tier 2 — SP_Daily_Open_Closed_Position via Dim_Instrument) |
| 7 | PlayerStatus | varchar(50) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. Resolved via Fact_SnapshotCustomer.PlayerStatusID → Dim_PlayerStatus. Point-in-time. 9 values: Normal, Deposit Blocked, Warning, Block Deposit & Trading, Trade & MIMO Blocked, Copy Block, Blocked Upon Request, Pending Verification, Blocked. (Tier 1 — DWH_dbo.Dim_PlayerStatus, upstream Dictionary.PlayerStatus) |
| 8 | Club | varchar(20) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal. Resolved via Fact_SnapshotCustomer.PlayerLevelID → Dim_PlayerLevel. Point-in-time. (Tier 1 — DWH_dbo.Dim_PlayerLevel, upstream Dictionary.PlayerLevel) |
| 9 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Resolved via Fact_SnapshotCustomer.CountryID → Dim_Country. Point-in-time. (Tier 1 — DWH_dbo.Dim_Country, upstream Dictionary.Country) |
| 10 | Buy Amount | money | YES | Total opened position amount in dollars for this dimension combination on this date. SUM(Dim_Position.InitialAmountCents / 100) for open positions where OpenDateID=@DateID. Excludes partial close child positions. (Tier 2 — SP_Daily_Open_Closed_Position) |
| 11 | Sell Amount | money | YES | Total closed position value in dollars for this dimension combination on this date. SUM(Dim_Position.Amount + Dim_Position.NetProfit) for close positions where CloseDateID=@DateID. Includes realized PnL. (Tier 2 — SP_Daily_Open_Closed_Position) |
| 12 | Total Amount | money | YES | Net position flow: Buy Amount - Sell Amount. Positive = more opened than closed, negative = more closed than opened for this dimension slice on this date. (Tier 2 — SP_Daily_Open_Closed_Position) |
| 13 | UpdateDate | date | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. CAST(GETDATE() AS DATE). (Tier 5 — Propagation) |
| 14 | DateID | int | YES | Integer date key in YYYYMMDD format. Derived from SP parameter @date via DWH_dbo.DateToDateID(@date). Matches Date column value. (Tier 2 — SP_Daily_Open_Closed_Position) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| Date | DWH_dbo.Dim_Position | OpenOccurred / CloseOccurred | CAST as DATE |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough via FSC.RegulationID |
| IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | Passthrough point-in-time |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough point-in-time |
| IsSettled | DWH_dbo.Dim_Position | IsSettledOnOpen / IsSettled | Opens: ISNULL(IsSettledOnOpen, IsSettled); Closes: IsSettled |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType + ISINCode + InstrumentTypeID | CASE for US/Non-US Stocks |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Passthrough via FSC.PlayerStatusID |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough via FSC.PlayerLevelID |
| Country | DWH_dbo.Dim_Country | Name | Passthrough via FSC.CountryID |
| Buy Amount | DWH_dbo.Dim_Position | InitialAmountCents | SUM(cents/100) for opens |
| Sell Amount | DWH_dbo.Dim_Position | Amount + NetProfit | SUM for closes |
| Total Amount | (computed) | Buy Amount - Sell Amount | Derived |
| UpdateDate | (ETL) | GETDATE() | CAST as DATE |
| DateID | (ETL) | @date parameter | DateToDateID() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (open/close positions)
DWH_dbo.Fact_SnapshotCustomer (point-in-time customer attributes)
DWH_dbo.Dim_Range (SCD2 date range join)
DWH_dbo.Dim_Instrument (instrument type + ISIN)
DWH_dbo.Dim_Regulation (regulation name)
DWH_dbo.Dim_PlayerStatus (player status name)
DWH_dbo.Dim_PlayerLevel (club name)
DWH_dbo.Dim_Country (country name)
  |-- SP_Daily_Open_Closed_Position @date --|
  |   #open: open positions SUM(InitialAmountCents/100)
  |   #close: close positions SUM(Amount+NetProfit)
  |   #final_1: UNION ALL with TransactionType
  |   #final: pivot Buy/Sell/Total amounts
  |   DELETE WHERE Date=@date, INSERT
  v
BI_DB_dbo.BI_DB_Daily_Open_Closed_Position (7.6M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Regulation | DWH_dbo.Dim_Regulation | Regulation.Name resolved via FSC |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | PlayerStatus.Name resolved via FSC |
| Club | DWH_dbo.Dim_PlayerLevel | PlayerLevel.Name resolved via FSC |
| Country | DWH_dbo.Dim_Country | Country.Name resolved via FSC |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType with US/Non-US split |
| Buy Amount, Sell Amount | DWH_dbo.Dim_Position | Position amounts aggregated |
| IsValidCustomer, IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | Point-in-time customer validity |

### 6.2 Referenced By (other objects point to this)

No known consumers in BI_DB_dbo.

---

## 7. Sample Queries

### 7.1 Daily Net Flow by Regulation (Valid Settled Customers)

```sql
SELECT [Date],
       Regulation,
       SUM([Buy Amount]) AS TotalBuy,
       SUM([Sell Amount]) AS TotalSell,
       SUM([Total Amount]) AS NetFlow
FROM [BI_DB_dbo].[BI_DB_Daily_Open_Closed_Position]
WHERE IsValidCustomer = 1
  AND IsCreditReportValidCB = 1
  AND IsSettled = 1
  AND DateID >= 20260101
GROUP BY [Date], Regulation
ORDER BY [Date] DESC, TotalBuy DESC
```

### 7.2 Instrument Type Breakdown (CFD vs Real)

```sql
SELECT InstrumentType,
       IsSettled,
       SUM([Buy Amount]) AS TotalBuy,
       SUM([Sell Amount]) AS TotalSell,
       COUNT(*) AS RowCount
FROM [BI_DB_dbo].[BI_DB_Daily_Open_Closed_Position]
WHERE DateID >= 20260401
  AND IsValidCustomer = 1
GROUP BY InstrumentType, IsSettled
ORDER BY TotalBuy DESC
```

### 7.3 US vs Non-US Stocks Monthly Trend

```sql
SELECT YEAR([Date]) AS Yr,
       MONTH([Date]) AS Mo,
       InstrumentType,
       SUM([Buy Amount]) AS MonthlyBuy
FROM [BI_DB_dbo].[BI_DB_Daily_Open_Closed_Position]
WHERE InstrumentType IN ('US Stocks', 'Non-US Stocks')
  AND IsValidCustomer = 1
  AND IsCreditReportValidCB = 1
GROUP BY YEAR([Date]), MONTH([Date]), InstrumentType
ORDER BY Yr DESC, Mo DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 6 T1, 6 T2, 0 T3, 0 T4, 1 T5 | Elements: 14/14, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Daily_Open_Closed_Position | Type: Table | Production Source: DWH_dbo dims via SP_Daily_Open_Closed_Position*
