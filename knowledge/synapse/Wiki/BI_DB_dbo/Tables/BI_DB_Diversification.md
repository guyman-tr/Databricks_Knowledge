# BI_DB_dbo.BI_DB_Diversification

> 358.9M-row investment diversification snapshot table tracking how many different asset classes each funded depositor holds on EOM and mid-month (15th) dates, from January 2015 to present. Populated by `SP_Diversification` via DELETE-INSERT per DateID, sourcing population from `BI_DB_CID_DailyPanel_FullData` (IsFunded_New=1), positions from `BI_DB_PositionPnL`, instrument classification from `Dim_Instrument`, and financial data from `V_Liabilities`. ~3.88M CIDs per snapshot across ~96 snapshot dates.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Internal BI_DB/DWH aggregation via `SP_Diversification` (no External table source) |
| **Refresh** | SB_Daily, but SP only executes on EOM + 15th of month (`IF @dd = EOMONTH(@dd) OR DAY(@dd) = 15`) |
| **Synapse Distribution** | HASH([CID]) |
| **Synapse Index** | CLUSTERED INDEX([CID] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Shir Yablon (2021-06-09), migrated by Tal Cohen (2023-06-27) |

---

## 1. Business Meaning

This table captures a semi-monthly snapshot of investment diversification for every funded depositor on the eToro platform. Each row represents one customer on one snapshot date, recording which of 4 broad asset classes they hold positions in (Copy trading, Crypto, Stocks/ETF, Commodities/Indices/Currencies), how many distinct instruments and industries they span, and their financial position (AUA, Balance, Equity, 30-day Revenue).

The table answers questions like: "How many funded users hold only one asset class?", "What is the typical instrument diversification for US vs Rest of World?", and "How does AUA correlate with portfolio breadth?"

**Population**: Only funded depositors — customers where `IsFunded_New=1` in `BI_DB_CID_DailyPanel_FullData` at the snapshot date. Joined with `V_Liabilities` for balance components.

**Key semantics**:
- The table runs only on **EOM and 15th** — not daily. There are ~96 snapshot dates from Jan 2015 through Mar 2026.
- `ActiveUser` is the MAX of `ActiveOpen` over the preceding 30-day window, not a same-day flag.
- `Country` is simplified to just **US** or **Rest** (not the full country name).
- Instrument classification uses `MirrorID` to distinguish Copy positions (MirrorID <> 0) from direct holdings.
- `NumOfAssets`, `NumOfIndustries`, and `NumOfCFD` are only populated for users holding exactly 1 of that category — these are "concentration" metrics for single-asset-class users, NULL for diversified users.
- `InstrumentDisplayName` and `CryptoName` are only populated for users holding exactly 1 instrument across ALL asset classes (NumOfInstruments=1).

---

## 2. Business Logic

### 2.1 Instrument Classification PIVOT

**What**: Each position is classified into one of 4 asset classes, then PIVOTed per CID.
**Columns Involved**: Copy, Crypto Currencies, Stocks/ETF, Commodities/Indices/Currencies, NumOfInstruments
**Rules**:
- MirrorID <> 0 → `Copy` (regardless of instrument type)
- MirrorID = 0 AND InstrumentTypeID IN (5,6) → `Stocks/ETF`
- MirrorID = 0 AND InstrumentTypeID IN (2,4,1) → `Commodities/Indices/Currencies`
- MirrorID = 0 AND other InstrumentType → uses Dim_Instrument.InstrumentType text (e.g., 'Crypto Currencies')
- Each PIVOT column stores the count of distinct instruments in that class (not just 0/1)
- NumOfInstruments = SUM of all 4 PIVOT columns (0-4 range)

### 2.2 Single-Asset Concentration Detection

**What**: Special columns track users holding exactly one instrument/industry/CFD.
**Columns Involved**: NumOfAssets, InstrumentDisplayName, CryptoName, NumOfIndustries, NumOfCFD
**Rules**:
- `NumOfAssets` = COUNT(DISTINCT InstrumentID) for Stocks/ETF positions only, but only stored when that count = 1 (single-stock holders)
- `InstrumentDisplayName` = the name of that single stock, but only when NumOfInstruments=1 across ALL classes
- `CryptoName` = the name of the single crypto, same constraint (NumOfInstruments=1)
- `NumOfIndustries` = count of distinct industries, only when = 1 (single-industry concentration)
- `NumOfCFD` = COUNT(DISTINCT InstrumentID) for CFD, only when = 1

### 2.3 Financial Metrics

**What**: AUA, Balance, and Equity from different sources with different semantics.
**Columns Involved**: AUA, Balance, Equity, Revenue
**Rules**:
- `AUA` = SUM(PositionPnL + Amount) from BI_DB_PositionPnL — value of open positions only (excludes cash)
- `Balance` = V_Liabilities.Credit — cash balance
- `Equity` = AUA + TotalCash + TotalStockOrders + InProcessCashouts — total account value (note: TotalStockOrders and InProcessCashouts are legacy, typically 0 since 2019)
- `Revenue` = SUM(Revenue_Total) from CID_DailyPanel_FullData over the 30-day window ending at the snapshot date

### 2.4 Country Simplification

**What**: Full country name reduced to binary US/Rest.
**Columns Involved**: Country
**Rules**:
- 'United States' → 'US'
- Everything else → 'Rest'
- For users with no position data (#tbl), the fallback uses the CID_DailyPanel_FullData.Country

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distributed on HASH(CID) with CLUSTERED INDEX on CID ASC. Queries filtering by CID are efficient. Cross-CID aggregations (e.g., "how many users hold only crypto?") scan all distributions — use DateID filters to limit scope.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| What % of users are single-asset holders? | `SELECT DateID, SUM(CASE WHEN NumOfInstruments=1 THEN 1 ELSE 0 END)*100.0/COUNT(*) FROM ... WHERE DateID=YYYYMMDD GROUP BY DateID` |
| Average AUA by asset class combination | `SELECT Copy, [Crypto Currencies], [Stocks/ETF], [Commodities/Indices/Currencies], AVG(AUA) FROM ... WHERE DateID=YYYYMMDD GROUP BY ...` |
| Diversification trend over time | `SELECT DateID, AVG(CAST(NumOfInstruments AS FLOAT)) FROM ... GROUP BY DateID ORDER BY DateID` |
| Single-stock holder names | `SELECT InstrumentDisplayName, COUNT(*) FROM ... WHERE InstrumentDisplayName IS NOT NULL AND DateID=YYYYMMDD GROUP BY InstrumentDisplayName ORDER BY 2 DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer demographics (regulation, club, etc.) |
| BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | CID + DateID | Detailed daily metrics (deposits, trading volume) |

### 3.4 Gotchas

- **Column names with spaces/special chars**: `[Crypto Currencies]`, `[Stocks/ETF]`, `[Commodities/Indices/Currencies]` — always bracket-quote these in SQL
- **Not daily**: Only EOM + 15th dates exist. Do NOT expect continuous date coverage
- **NULL concentration columns**: `NumOfAssets`, `NumOfIndustries`, `NumOfCFD` are NULL for multi-class users — these are single-class concentration metrics, not universal counts
- **InstrumentDisplayName/CryptoName sparsity**: Only populated for users holding exactly 1 instrument total (NumOfInstruments=1). Most users are NULL
- **ActiveUser is 30-day**: Not a same-day flag — it's MAX(ActiveOpen) over the prior 30 days
- **Balance = Credit**: The DDL column is `Balance` but the value is V_Liabilities.Credit (cash balance)
- **Equity includes legacy zeros**: TotalStockOrders and InProcessCashouts are always 0 since 2019, so Equity effectively equals AUA + TotalCash
- **IsFunded_New always 1**: The population is pre-filtered to IsFunded_New=1, so this column is always 1

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
| 1 | CID | int | NO | eToro customer ID (Real CID). Only funded depositors (IsFunded_New=1) present. FK to DWH_dbo.Dim_Customer.RealCID. (Tier 1 — DWH_dbo.Dim_Customer) |
| 2 | DateID | int | NO | Snapshot date as YYYYMMDD integer. Only EOM and 15th dates exist. Partition and filter key. (Tier 2 — SP_Diversification) |
| 3 | Date | date | YES | Calendar date corresponding to DateID. Set from SP @dd parameter. (Tier 2 — SP_Diversification) |
| 4 | Seniority | int | YES | Months since customer's first deposit (FTDdate) as of start of the current month. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 5 | IsFunded_New | int | YES | Funded depositor flag. Always 1 in this table because the population is pre-filtered to IsFunded_New=1. Stricter definition: EOD_Equity > 0 AND VerificationLevelID=3 AND FirstActionDate < next day. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 6 | ActiveUser | int | YES | 1 if customer had any active open position (manual trade, new/add mirror) in the 30-day window ending at the snapshot date. MAX(ActiveOpen) over 30 days, not a same-day flag. (Tier 2 — SP_Diversification) |
| 7 | Country | varchar(4) | YES | Simplified country: 'US' for United States, 'Rest' for all other countries. Derived from BI_DB_CID_DailyPanel_FullData.Country via CASE expression. (Tier 2 — SP_Diversification) |
| 8 | Copy | int | YES | Count of distinct Copy trading positions (MirrorID <> 0). NULL if user has no copy positions. From PIVOT on BI_DB_PositionPnL + Dim_Instrument classification. (Tier 2 — SP_Diversification) |
| 9 | Crypto Currencies | int | YES | Count of distinct crypto positions (MirrorID=0 AND InstrumentType='Crypto Currencies'). NULL if user has no crypto positions. (Tier 2 — SP_Diversification) |
| 10 | Stocks/ETF | int | YES | Count of distinct stock and ETF positions (MirrorID=0 AND InstrumentTypeID IN (5,6)). NULL if user has no stock/ETF positions. (Tier 2 — SP_Diversification) |
| 11 | Commodities/Indices/Currencies | int | YES | Count of distinct CFD positions (MirrorID=0 AND InstrumentTypeID IN (2,4,1)). NULL if user has no CFD positions. Covers commodities, indices, and forex. (Tier 2 — SP_Diversification) |
| 12 | NumOfInstruments | int | YES | Total number of asset classes held: SUM of Copy + Crypto + Stocks/ETF + CFD (0-4 range). NULL if user has no open positions. (Tier 2 — SP_Diversification) |
| 13 | NumOfAssets | int | YES | Count of distinct instruments in Stocks/ETF class only. Only populated when this count = 1 (single-stock concentration detection). NULL for multi-asset or non-stock users. (Tier 2 — SP_Diversification) |
| 14 | InstrumentDisplayName | varchar(100) | YES | Display name of the single held stock/ETF instrument (e.g., 'NVIDIA Corporation'). Only populated when NumOfInstruments=1 AND user holds exactly 1 Stock/ETF. NULL for diversified users or non-stock holders. (Tier 2 — SP_Diversification, via Dim_Instrument.InstrumentDisplayName) |
| 15 | CryptoName | varchar(100) | YES | Display name of the single held crypto instrument (e.g., 'Cardano', 'Shiba (in millions)'). Only populated when NumOfInstruments=1 AND user holds exactly 1 crypto. NULL for diversified users or non-crypto holders. (Tier 2 — SP_Diversification, via Dim_Instrument.InstrumentDisplayName) |
| 16 | AUA | decimal(38,4) | YES | Assets Under Administration in USD. SUM(PositionPnL + Amount) from BI_DB_PositionPnL — value of open positions only, excludes cash balance. ISNULL to 0 for users with no position data. (Tier 2 — SP_Diversification) |
| 17 | NumOfIndustries | int | YES | Count of distinct industries (from Dim_Instrument.Industry) for Stocks/ETF positions. Only populated when count = 1 (single-industry concentration). NULL if NULL/empty Industry treated as 'Other'. (Tier 2 — SP_Diversification) |
| 18 | NumOfCFD | int | YES | Count of distinct instruments in Commodities/Indices/Currencies class. Only populated when count = 1 (single-CFD concentration). NULL for multi-CFD or non-CFD users. (Tier 2 — SP_Diversification) |
| 19 | Balance | decimal(38,4) | YES | Cash balance from V_Liabilities.Credit. Renamed from Credit to Balance by the SP. Does not include position value. (Tier 2 — SP_Diversification, via V_Liabilities.Credit) |
| 20 | Equity | decimal(38,4) | YES | Total account value: AUA + TotalCash + TotalStockOrders + InProcessCashouts from V_Liabilities. Note: TotalStockOrders and InProcessCashouts are legacy columns (always 0 since 2019), so effectively AUA + TotalCash. (Tier 2 — SP_Diversification) |
| 21 | Revenue | decimal(38,4) | YES | 30-day rolling revenue: SUM(Revenue_Total) from BI_DB_CID_DailyPanel_FullData over the 30-day window ending at the snapshot date. Includes all fee types (commissions, rollover, ticket, conversion, Islamic). (Tier 2 — SP_Diversification) |
| 22 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_Diversification (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| CID | BI_DB_CID_DailyPanel_FullData | CID | Direct (filtered IsFunded_New=1) |
| DateID | BI_DB_CID_DailyPanel_FullData | DateID | Direct |
| Date | SP parameter | @dd | Direct |
| Seniority | BI_DB_CID_DailyPanel_FullData | Seniority | Direct |
| IsFunded_New | BI_DB_CID_DailyPanel_FullData | IsFunded_New | Direct (always 1) |
| ActiveUser | BI_DB_CID_DailyPanel_FullData | ActiveOpen | MAX over 30-day window |
| Country | BI_DB_CID_DailyPanel_FullData | Country | CASE: US/Rest simplification |
| Copy..CFD columns | BI_DB_PositionPnL + Dim_Instrument | MirrorID, InstrumentTypeID | PIVOT classification |
| AUA | BI_DB_PositionPnL | PositionPnL + Amount | SUM |
| Balance | V_Liabilities | Credit | Rename |
| Equity | V_Liabilities + BI_DB_PositionPnL | AUA + TotalCash + legacy | Computed |
| Revenue | BI_DB_CID_DailyPanel_FullData | Revenue_Total | 30-day SUM |
| UpdateDate | ETL | GETDATE() | Timestamp |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_CID_DailyPanel_FullData (population: funded depositors)
DWH_dbo.V_Liabilities (balance components)
BI_DB_dbo.BI_DB_PositionPnL (open positions)
DWH_dbo.Dim_Instrument (instrument classification)
  |
  |-- SP_Diversification @dd (EOM + 15th only) --|
  |   DELETE WHERE DateID = @ddint              |
  |   INSERT (PIVOT + aggregation + JOINs)      |
  v
BI_DB_dbo.BI_DB_Diversification (358.9M rows)
  |
  (UC: _Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension (via CID_DailyPanel_FullData) |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument.InstrumentDisplayName | Instrument display name for single-holding users |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Asset Class Distribution on Latest Snapshot

```sql
SELECT
    SUM(CASE WHEN NumOfInstruments = 1 THEN 1 ELSE 0 END) AS single_class,
    SUM(CASE WHEN NumOfInstruments = 2 THEN 1 ELSE 0 END) AS two_class,
    SUM(CASE WHEN NumOfInstruments = 3 THEN 1 ELSE 0 END) AS three_class,
    SUM(CASE WHEN NumOfInstruments = 4 THEN 1 ELSE 0 END) AS four_class,
    SUM(CASE WHEN NumOfInstruments IS NULL THEN 1 ELSE 0 END) AS no_positions,
    COUNT(*) AS total
FROM [BI_DB_dbo].[BI_DB_Diversification]
WHERE DateID = 20260331
```

### 7.2 Top Single-Stock Holdings

```sql
SELECT InstrumentDisplayName, COUNT(*) AS holders, AVG(AUA) AS avg_aua
FROM [BI_DB_dbo].[BI_DB_Diversification]
WHERE DateID = 20260331
  AND InstrumentDisplayName IS NOT NULL
GROUP BY InstrumentDisplayName
ORDER BY holders DESC
```

### 7.3 US vs Rest Diversification Comparison

```sql
SELECT
    Country,
    AVG(CAST(NumOfInstruments AS FLOAT)) AS avg_asset_classes,
    AVG(AUA) AS avg_aua,
    SUM(CASE WHEN ActiveUser = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_active
FROM [BI_DB_dbo].[BI_DB_Diversification]
WHERE DateID = 20260331
GROUP BY Country
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 1 T1, 19 T2, 0 T3, 0 T4, 1 T5 | Elements: 22/22, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Diversification | Type: Table | Production Source: SP_Diversification (internal aggregation)*
