# BI_DB_dbo.BI_DB_US_Apex_Transactions_Trading_Activity

> 2.76M-row Apex-vs-eToro trade-level reconciliation table matching daily stock/ETF open and close transactions between Apex Clearing's SOD 872 files and eToro's Dim_Position, for US-regulated accounts from October 2021 to present. Each row represents one position open or close event with side-by-side Apex and eToro amounts, units, and prices. Refreshed daily via SP_US_Apex_Transactions_Trading_Activity with DELETE+INSERT by DateId.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_Sodreconciliation_apex_EXT872_TradeActivity (Apex SOD 872) + DWH_dbo.Dim_Position (eToro positions) + DWH_dbo.Dim_Instrument + Fact_SnapshotCustomer + Dim_PlayerLevel |
| **Refresh** | Daily (SP_US_Apex_Transactions_Trading_Activity, DELETE+INSERT by DateId, SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateId ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_US_Apex_Transactions_Trading_Activity` is a 2.76M-row trade-level reconciliation table that performs a FULL OUTER JOIN between Apex Clearing's daily trade activity records (SOD Format 872) and eToro's internal position records from Dim_Position. Each row represents one stock/ETF trade (open or close) for a US-regulated (RegulationIDOnOpen=8) customer.

The reconciliation matches trades by PositionID: Apex's OrderID encodes the eToro PositionID with an 'O' (opened) or 'C' (closed) suffix. The FULL OUTER JOIN identifies:
- **Exists in Both** (95%): Trade found in both Apex and eToro — amounts, units, and prices can be compared
- **Missing in Apex** (5%): Trade exists in eToro but not in Apex SOD 872 files
- **Missing in eToro**: Trade exists in Apex but not in eToro (currently 0 rows)

eToro opens are filtered to: stocks/ETFs (InstrumentTypeID IN 5,6), settled on open (IsSettledOnOpen=1), not partial close children, not airdrops. Closes exclude ClosePositionReasonID=10 (system closes handled elsewhere) and verify the customer was under Regulation 8 at close time via Fact_SnapshotCustomer.

Each row includes the customer's eToro Club level (from Dim_PlayerLevel via snapshot) and whether the trade was a copy trade or manual.

---

## 2. Business Logic

### 2.1 Trade Matching via PositionID

**What**: Apex OrderIDs encode eToro PositionIDs with direction suffix.
**Columns Involved**: `OrderIDApex`, `PositionID`, `Category`
**Rules**:
- OrderID ending in 'O' → Opened position
- OrderID ending in 'C' → Closed position
- CAST(REPLACE(REPLACE(OrderId,'O',''),'C','') AS BIGINT) extracts the eToro PositionID
- FULL OUTER JOIN on: PositionID = EtoroID AND Type match AND ProcessDate = Date

### 2.2 Reconciliation Status

**What**: Identifies mismatches between the two systems.
**Columns Involved**: `ReconStatus`
**Rules**:
- 'Exists in Both' (95%): Matched on PositionID + Type + Date
- 'Missing in Apex': eToro has the position but Apex SOD 872 doesn't
- 'Missing in eToro': Apex has the trade but eToro's Dim_Position doesn't

### 2.3 Copy vs Manual Classification

**What**: Identifies whether the trade was a copy (social) trade or manual.
**Columns Involved**: `Copy_Manual`
**Rules**:
- MirrorID > 0 → 'Copy' (CopyTrader trade)
- MirrorID = 0 or NULL → 'Manual' (independent trade)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateId ASC. Efficient for date-range queries. For reconciliation analysis, filter by DateId first, then examine ReconStatus.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily reconciliation summary | `SELECT DateId, ReconStatus, COUNT(*) GROUP BY DateId, ReconStatus` |
| Price discrepancies | `WHERE ReconStatus = 'Exists in Both' AND ABS(PriceApex - PriceEtoro) > 0.01` |
| Missing-in-Apex trades | `WHERE ReconStatus = 'Missing in Apex'` |
| Copy vs manual breakdown | `GROUP BY Copy_Manual, Category` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CIDEtoro = RealCID | Full customer attributes |
| DWH_dbo.Dim_Instrument | InstrumentID | Full instrument details |

### 3.4 Gotchas

- **"ProccessDate" typo**: Column name has triple 'c'. In the DDL; cannot rename without ALTER
- **AmountApex/UnitsApex are ABS()**: Always positive. AmountEtoro can be negative (calculated as Amount+NetProfit for closes)
- **Missing in eToro = 0 rows currently**: The Apex-side filter (OrderId LIKE '%O' or '%C') may exclude non-standard Apex trades
- **Club may be NULL**: Only populated for rows that JOIN to Fact_SnapshotCustomer — "Missing in eToro" rows have no CIDEtoro

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL infrastructure / standard metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ApexID | varchar(40) | YES | Apex Clearing account number. From EXT872 AccountNumber. Filtered: excludes '3ET00001' (house account). Format: alphanumeric (e.g., "3ET13835"). (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, EXT872_TradeActivity) |
| 2 | ProccessDate | date | NOT NULL | Trade processing date. Set to @Date parameter. Note: column name has typo (triple 'c'). Range: 2021-10-11 to present. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity) |
| 3 | DateId | int | YES | Integer date key (YYYYMMDD format) for ProccessDate. Used as delete/insert partition and clustered index. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity) |
| 4 | AmountApex | money | YES | Trade monetary amount from Apex SOD 872. ABS(NetAmount). Always positive. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, EXT872_TradeActivity) |
| 5 | UnitsApex | decimal(16,6) | YES | Number of units traded from Apex SOD 872. ABS(Quantity). Always positive. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, EXT872_TradeActivity) |
| 6 | PriceApex | numeric(28,10) | YES | Trade execution price from Apex SOD 872. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, EXT872_TradeActivity) |
| 7 | SymbolApex | varchar(20) | YES | Instrument ticker symbol from Apex SOD 872. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, EXT872_TradeActivity) |
| 8 | OrderIDApex | varchar(40) | YES | Apex order identifier. Encodes eToro PositionID with 'O' (open) or 'C' (close) suffix. Used for matching. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, EXT872_TradeActivity) |
| 9 | PositionID | bigint | YES | eToro position identifier. From Dim_Position if matched, otherwise parsed from OrderIDApex (REPLACE O/C suffix). (Tier 2 — SP_US_Apex_Transactions_Trading_Activity) |
| 10 | PriceEtoro | numeric(28,10) | YES | Trade execution price from eToro. Opens: InitForexRate. Closes: EndForexRate. NULL for "Missing in eToro" rows. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, Dim_Position) |
| 11 | CIDEtoro | int | YES | eToro Customer ID. From Dim_Position.CID. NULL for "Missing in eToro" rows. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, Dim_Position) |
| 12 | InstrumentID | int | YES | eToro DWH instrument ID. From Dim_Position.InstrumentID. FK to Dim_Instrument. NULL for "Missing in eToro" rows. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, Dim_Position) |
| 13 | InstrumentName | varchar(200) | YES | Human-readable instrument name from eToro. From Dim_Instrument.InstrumentDisplayName. NULL for "Missing in eToro" rows. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, Dim_Instrument) |
| 14 | SymbolEtoro | varchar(20) | YES | Instrument ticker symbol from eToro. From Dim_Instrument.Symbol. Used to compare with SymbolApex. NULL for "Missing in eToro" rows. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, Dim_Instrument) |
| 15 | UnitsEtoro | decimal(16,6) | YES | Number of units from eToro. Opens: InitialUnits. Closes: AmountInUnitsDecimal. NULL for "Missing in eToro" rows. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, Dim_Position) |
| 16 | AmountEtoro | money | YES | Trade monetary amount from eToro. Opens: InitialAmountCents/100. Closes: Amount+NetProfit. Can be negative for losing closes. NULL for "Missing in eToro" rows. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, Dim_Position) |
| 17 | Category | varchar(40) | NOT NULL | Trade direction. 'Opened' (55%) = position opened. 'Closed' (45%) = position closed. Derived from Apex OrderID suffix ('O'/'C') or eToro Type. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity) |
| 18 | ReconStatus | varchar(40) | YES | Reconciliation match result. 'Exists in Both' (95%) = matched. 'Missing in Apex' (5%) = eToro-only. 'Missing in eToro' (0%) = Apex-only. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity) |
| 19 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted (GETDATE()). (Tier 5 — SP_US_Apex_Transactions_Trading_Activity) |
| 20 | Club | varchar(100) | YES | eToro Club membership level at trade date. From Dim_PlayerLevel.Name via Fact_SnapshotCustomer. NULL for "Missing in eToro" rows. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, Dim_PlayerLevel) |
| 21 | Copy_Manual | varchar(100) | YES | Trade origin classification. 'Copy' = CopyTrader trade (MirrorID > 0). 'Manual' = independent trade (MirrorID = 0 or NULL). NULL for "Missing in eToro" rows. (Tier 2 — SP_US_Apex_Transactions_Trading_Activity, Dim_Position) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| ApexID | EXT872_TradeActivity | AccountNumber | Rename |
| ProccessDate | Derived | @Date | Constant |
| AmountApex / UnitsApex / PriceApex | EXT872_TradeActivity | NetAmount / Quantity / Price | ABS for amounts/units |
| PriceEtoro / UnitsEtoro / AmountEtoro | Dim_Position | Various | Open vs Close logic |
| ReconStatus | Derived | FULL OUTER JOIN | Match status |
| Club | Dim_PlayerLevel | Name | JOIN via snapshot |
| Copy_Manual | Dim_Position | MirrorID | CASE logic |

### 5.2 ETL Pipeline

```
Apex Clearing (SOD Format 872 — Trade Activity)        DWH_dbo.Dim_Position (settled US positions)
  |                                                       |
  |-- External Table --|                                   |-- Opened @DateID + Closed @DateID --|
  v                    v                                   v                                     v
EXT872_TradeActivity  #finalap                            #opet + #cpet → #finalet
  |                                                       |
  |------- FULL OUTER JOIN on PositionID + Type + Date ---|
  v
#finaltab → + Dim_PlayerLevel (Club) → #finaltab1
  |
  |-- SP_US_Apex_Transactions_Trading_Activity @date (daily, DELETE+INSERT by DateId) --|
  v
BI_DB_dbo.BI_DB_US_Apex_Transactions_Trading_Activity (2.76M rows)
  |
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PositionID | DWH_dbo.Dim_Position | eToro position |
| CIDEtoro | DWH_dbo.Dim_Customer | Customer dimension |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension |
| Club | DWH_dbo.Dim_PlayerLevel | Club level |

### 6.2 Referenced By (other objects point to this)

No known consumers.

---

## 7. Sample Queries

### 7.1 Daily Reconciliation Summary

```sql
SELECT
    ProccessDate,
    ReconStatus,
    Category,
    COUNT(*) AS TradeCount,
    SUM(CASE WHEN ReconStatus = 'Exists in Both'
        THEN ABS(ISNULL(AmountApex, 0) - ISNULL(AmountEtoro, 0)) ELSE 0 END) AS TotalAmountDiff
FROM BI_DB_dbo.BI_DB_US_Apex_Transactions_Trading_Activity
WHERE DateId >= 20260401
GROUP BY ProccessDate, ReconStatus, Category
ORDER BY ProccessDate DESC
```

### 7.2 Trades Missing in Apex

```sql
SELECT
    ProccessDate, CIDEtoro, PositionID,
    InstrumentName, SymbolEtoro,
    AmountEtoro, UnitsEtoro, Category
FROM BI_DB_dbo.BI_DB_US_Apex_Transactions_Trading_Activity
WHERE ReconStatus = 'Missing in Apex'
    AND DateId >= 20260401
ORDER BY ProccessDate DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 20 T2, 0 T3, 0 T4, 1 T5 | Elements: 21/21, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_US_Apex_Transactions_Trading_Activity | Type: Table | Production Source: Apex SOD 872 + Dim_Position FULL OUTER JOIN*
