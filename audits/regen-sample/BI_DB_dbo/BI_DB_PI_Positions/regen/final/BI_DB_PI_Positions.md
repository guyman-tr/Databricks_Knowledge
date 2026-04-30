# BI_DB_dbo.BI_DB_PI_Positions

> ~24.1M-row PI-specific shadow cache of DWH_dbo.Dim_Position storing the full trading position history for every active Popular Investor and CopyFund account, covering positions from Jan 2009 to Apr 2024. Maintained incrementally by SP_PI_Dashboard_COPYDATA_RuningSideBySide (sections 2.1-2.3) to avoid re-scanning the massive Dim_Position table during dashboard computation. Data stopped refreshing around 2024-04-15.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide` (sections 2.1, 2.2, 2.3) from DWH_dbo.Dim_Position |
| **Refresh** | Daily — new PI backfill (full history) + DELETE WHERE OpenDateID=@yesterday + INSERT. Synced via UPDATE for close events. |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (PositionID ASC) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_PI_Positions` is a filtered shadow cache of `DWH_dbo.Dim_Position` containing position records for **active Popular Investors (PIs)** and **CopyFund accounts**. It exists to avoid re-scanning the massive Dim_Position table (hundreds of millions of rows, monthly-partitioned) during the daily PI Dashboard computation.

The table holds ~24.1M rows covering positions opened from 2009-01-02 through 2024-04-14, with ~7,534 distinct CIDs. All 17 data columns are **direct passthroughs** from `Dim_Position` — no transformation is applied. The only difference from the source is the population filter: only customers who are currently PIs (GuruStatusID IN 2,3,4,5,6 AND IsValidCustomer=1) or CopyFund accounts (AccountTypeID=9) have their positions cached here.

**ETL pattern**: The SP has three data paths:
1. **New PI backfill** (section 2.1): When a customer first enters the PI population, ALL their historical positions from `Dim_Position` are copied in via a WHILE loop iterating by CID (descending order).
2. **Daily incremental** (section 2.2): Each day, DELETE rows for @yesterdayINT OpenDateID and INSERT yesterday's new positions from `Dim_Position` for the current PI population.
3. **Close sync** (section 2.3): UPDATE Amount, CloseDateID, CloseOccurred, FullCommissionOnCloseOrig, and FullCommissionByUnits from `Dim_Position` when values differ — catching positions that closed after their open date was already cached.

**Consumers** (all within the same SP):
- Section 2.4: Largest asset class per PI (manual positions only, MirrorID=0)
- Section 2.5: Top 3 traded instruments (full history, manual only)
- Section 2.6: Top 3 traded instruments (open positions only, manual only)
- Section 2.7: Top 3 invested industries (open positions only)
- Section 2.8: PI Classification (asset allocation of open manual positions)
- Section 3.6: Average holding time and TraderType (closed manual positions + Dim_Mirror in last 2 years)

**Data stopped refreshing around 2024-04-15**, consistent with the parent dashboard table `BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide`.

---

## 2. Business Logic

### 2.1 PI Population Filter

**What**: Only PI-eligible and CopyFund customers have their positions cached.

**Columns Involved**: `CID`

**Rules**:
- Active Popular Investors: `Dim_Customer.GuruStatusID IN (2,3,4,5,6) AND Dim_Customer.IsValidCustomer = 1`
- CopyFund accounts: `Dim_Customer.AccountTypeID = 9`
- Population is determined from `#pop` temp table built in section 1 of the SP
- GuruStatusID values: 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro

### 2.2 New PI Backfill (Section 2.1)

**What**: When a customer first appears in the PI population, their full position history is loaded.

**Columns Involved**: All columns

**Rules**:
- SP checks for PIs in `#pop` that have no existing rows in `BI_DB_PI_Positions`
- For each new PI, ALL positions from `Dim_Position` are inserted (no date filter)
- Uses a WHILE loop iterating CID by CID (descending order)
- This ensures that metrics like `Largest_Asset_Class`, `Top_3_Traded_Instruments`, and `Avgerage_Holding_Time` have full history from day one

### 2.3 Daily Incremental + Close Sync (Sections 2.2 and 2.3)

**What**: Yesterday's new positions are inserted; previously-cached positions are updated when they close or change.

**Columns Involved**: All columns

**Rules**:
- `DELETE FROM BI_DB_PI_Positions WHERE @yesterdayINT = OpenDateID`
- `INSERT` from `Dim_Position` joined to `#pop` on `CID = RealCID` where `@yesterdayINT = OpenDateID`
- UPDATE from `Dim_Position` when `CloseDateID`, `Amount`, or `FullCommissionByUnits` differ — syncs close events and partial-close adjustments

### 2.4 Manual Position Filter for Analysis

**What**: Downstream consumption within the SP filters to manual positions only (MirrorID=0) for classification and instrument analysis.

**Columns Involved**: `MirrorID`, `CloseDateID`, `Amount`, `InstrumentID`, `IsBuy`

**Rules**:
- `#BI_DB_PI_Positions` temp table is created with `WHERE MirrorID = 0` — only manual (non-copy) positions
- Open positions identified by `CloseDateID = 0`
- Classification uses asset allocation of open manual positions to determine PI strategy (Long Equity, Crypto, Multi-Strategy, etc.)
- Top instruments ranked by SUM(Amount) DESC, COUNT(PositionID) DESC

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distributed — no co-located JOINs. CLUSTERED INDEX on PositionID supports point lookups. ~24.1M rows; single-CID queries or PositionID lookups are efficient. Date-range queries should filter on OpenDateID or CloseDateID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PI's position history | `WHERE CID = @cid ORDER BY OpenDateID DESC` |
| Open positions for all PIs | `WHERE CloseDateID = 0` |
| Manual (non-copy) positions only | `WHERE MirrorID = 0` |
| PI's asset class breakdown | `WHERE CID = @cid AND MirrorID = 0 AND CloseDateID = 0 GROUP BY InstrumentID` |
| Closed positions in a date range | `WHERE CloseDateID BETWEEN 20240101 AND 20240414` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve instrument name, type, asset class |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer profile, PI tier, country |
| DWH_dbo.Dim_Mirror | ON MirrorID | Copy-trading relationship details (for non-zero MirrorID) |

### 3.4 Gotchas

- **Shadow cache, not primary data**: This table is a filtered copy of `Dim_Position`. For non-PI customers, query `Dim_Position` directly.
- **Data stops at 2024-04-14/15**: The table has not been refreshed since this date. The parent SP appears to have stopped running.
- **CloseDateID=0 = open position**: Same sentinel as `Dim_Position`. Do not interpret as a real date.
- **CloseOccurred='1900-01-01' = still open**: Sentinel value inherited from `Dim_Position`.
- **MirrorID=0 = manual position**: Non-zero MirrorID indicates copy-trade positions. The SP's analysis sections (2.4-2.8) filter to MirrorID=0 only.
- **Population drift**: If a PI loses their status (demoted to GuruStatusID < 2 or = 7/8), their historical rows remain but no new rows are added. The table does not purge demoted PIs.
- **ROUND_ROBIN distribution**: JOINs on CID or PositionID with HASH-distributed tables will trigger data movement.
- **Subset of Dim_Position columns**: Only 17 of 134 Dim_Position columns are cached. For full position detail (forex rates, market prices, fees), join back to Dim_Position on PositionID.
- **New PI backfill is per-CID cursor**: For large numbers of new PIs, the backfill can be slow (WHILE loop with individual INSERTs per CID).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki verbatim (Dim_Position via Trade.PositionTbl or SP_Dim_Position_DL_To_Synapse) |
| Tier 5 | Expert Review — upstream confidence is low, carried through from Dim_Position wiki |
| Tier 2 | ETL-computed in this SP only (no upstream wiki) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | YES | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 2 | CID | int | YES | Customer ID. References Customer.Customer. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 3 | InstrumentID | int | NOT NULL | FK to Trade.Instrument. Financial instrument being traded. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 4 | Leverage | int | NOT NULL | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 5 | Amount | money | NOT NULL | Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). Synced via UPDATE when value changes in Dim_Position. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 6 | IsBuy | bit | NOT NULL | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 7 | OpenOccurred | datetime | NOT NULL | When position was persisted (mapped from Occurred in production). Default getutcdate(). Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 8 | CloseOccurred | datetime | NOT NULL | When close was persisted. '1900-01-01 00:00:00' sentinel = still open. Synced via UPDATE from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 9 | ParentPositionID | bigint | YES | Copy-trade parent. 0/1 = root. Positive = child of referenced position. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 10 | OrigParentPositionID | bigint | YES | Original parent before any detachment. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 11 | MirrorID | int | YES | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. Used to filter manual positions (MirrorID=0) for PI classification and instrument analysis. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 12 | OpenDateID | int | NOT NULL | ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. Used as DELETE+INSERT key for daily incremental refresh. Passthrough from Dim_Position. (Tier 1 — SP_Dim_Position_DL_To_Synapse) |
| 13 | CloseDateID | int | YES | ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. Synced via UPDATE from Dim_Position. Passthrough from Dim_Position. (Tier 1 — SP_Dim_Position_DL_To_Synapse) |
| 14 | Volume | int | YES | ETL-computed approximation of USD value: ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion, 0). Passthrough from Dim_Position. (Tier 1 — SP_Dim_Position_DL_To_Synapse) |
| 15 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. Synced via UPDATE from Dim_Position. Passthrough from Dim_Position. (Tier 1 — SP_Dim_Position_DL_To_Synapse) |
| 16 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. Passthrough from Dim_Position. (Tier 5 — Expert Review) |
| 17 | FullCommissionByUnits | decimal(38,6) | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. Synced via UPDATE from Dim_Position. Passthrough from Dim_Position. (Tier 1 — Trade.Position) |
| 18 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted or updated by SP_PI_Dashboard_COPYDATA_RuningSideBySide. Set to GETDATE(). (Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PositionID | DWH_dbo.Dim_Position | PositionID | Passthrough |
| CID | DWH_dbo.Dim_Position | CID | Passthrough (filtered to PI/CopyFund population) |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | Passthrough |
| Leverage | DWH_dbo.Dim_Position | Leverage | Passthrough |
| Amount | DWH_dbo.Dim_Position | Amount | Passthrough (synced via UPDATE section 2.3) |
| IsBuy | DWH_dbo.Dim_Position | IsBuy | Passthrough |
| OpenOccurred | DWH_dbo.Dim_Position | OpenOccurred | Passthrough |
| CloseOccurred | DWH_dbo.Dim_Position | CloseOccurred | Passthrough (synced via UPDATE section 2.3) |
| ParentPositionID | DWH_dbo.Dim_Position | ParentPositionID | Passthrough |
| OrigParentPositionID | DWH_dbo.Dim_Position | OrigParentPositionID | Passthrough |
| MirrorID | DWH_dbo.Dim_Position | MirrorID | Passthrough |
| OpenDateID | DWH_dbo.Dim_Position | OpenDateID | Passthrough |
| CloseDateID | DWH_dbo.Dim_Position | CloseDateID | Passthrough (synced via UPDATE section 2.3) |
| Volume | DWH_dbo.Dim_Position | Volume | Passthrough |
| FullCommissionOnCloseOrig | DWH_dbo.Dim_Position | FullCommissionOnCloseOrig | Passthrough (synced via UPDATE section 2.3) |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | Passthrough |
| FullCommissionByUnits | DWH_dbo.Dim_Position | FullCommissionByUnits | Passthrough (synced via UPDATE section 2.3) |
| UpdateDate | — | — | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (hundreds of millions of rows, HASH(PositionID))
DWH_dbo.Dim_Customer + Dim_GuruStatus + Dim_Country + Dim_PlayerStatus
  → #pop (PI/CopyFund population: ~3,400 CIDs)
  |
  |-- SP_PI_Dashboard_COPYDATA_RuningSideBySide sections 2.1 + 2.2 + 2.3
  |   Section 2.1: New PI backfill (WHILE loop, full position history per new CID)
  |   Section 2.2: Daily DELETE WHERE OpenDateID=@yesterday + INSERT
  |   Section 2.3: UPDATE Amount/CloseDateID/CloseOccurred/FullCommissionOnCloseOrig/
  |                FullCommissionByUnits from Dim_Position when values differ
  v
BI_DB_dbo.BI_DB_PI_Positions (~24.1M rows, PI/CopyFund only)
  |
  |-- Same SP sections 2.4-2.8, 3.6 (consumer)
  |   → #BI_DB_PI_Positions (filtered to MirrorID=0, manual positions only)
  |   → #instrumntstype (largest asset class per CID)
  |   → #Top3instrumnts (top 3 instruments, full history)
  |   → #Top3openinstrumnts (top 3 instruments, open only)
  |   → #Top3openinstrumnts_industries (top 3 industries, open only)
  |   → #Clssification (PI trading strategy classification)
  |   → #hold1 → #avghold (average holding time + TraderType)
  v
BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide
  (PI Dashboard — final output)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (CID = RealCID) |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension (asset name, type, exchange) |
| MirrorID | DWH_dbo.Dim_Mirror | Copy-trading relationship (0 = manual position) |
| PositionID | DWH_dbo.Dim_Position | Source position record (full 134-column detail) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide | Sections 2.4-2.8, 3.6 | Consumed to compute PI classification, top instruments, top industries, and average holding time for the PI Dashboard |

---

## 7. Sample Queries

### 7.1 Open manual positions for a specific PI

```sql
SELECT p.PositionID, p.InstrumentID, di.Symbol, di.InstrumentType,
       p.Amount, p.IsBuy, p.Leverage, p.OpenOccurred
FROM [BI_DB_dbo].[BI_DB_PI_Positions] p
JOIN [DWH_dbo].[Dim_Instrument] di ON p.InstrumentID = di.InstrumentID
WHERE p.CID = 2990627
  AND p.CloseDateID = 0
  AND p.MirrorID = 0
ORDER BY p.Amount DESC;
```

### 7.2 Asset class breakdown for all PIs (open manual positions)

```sql
SELECT p.CID, di.InstrumentType,
       SUM(p.Amount) AS TotalAmount,
       COUNT(p.PositionID) AS PositionCount
FROM [BI_DB_dbo].[BI_DB_PI_Positions] p
JOIN [DWH_dbo].[Dim_Instrument] di ON p.InstrumentID = di.InstrumentID
WHERE p.CloseDateID = 0
  AND p.MirrorID = 0
GROUP BY p.CID, di.InstrumentType
ORDER BY p.CID, TotalAmount DESC;
```

### 7.3 Average holding time for closed manual positions (last 2 years)

```sql
SELECT CID,
       AVG(DATEDIFF(MINUTE, OpenOccurred, CloseOccurred) * 1.0 / 60 / 24) AS AvgHoldingDays,
       COUNT(*) AS ClosedPositions
FROM [BI_DB_dbo].[BI_DB_PI_Positions]
WHERE CloseDateID <> 0
  AND MirrorID = 0
  AND OpenDateID >= 20220415
GROUP BY CID
ORDER BY AvgHoldingDays DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — Phase 10 skipped).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 16 T1, 1 T2, 0 T3, 0 T4, 1 T5 | Elements: 18/18, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_PI_Positions | Type: Table | Production Source: SP_PI_Dashboard_COPYDATA_RuningSideBySide (sections 2.1-2.3 from Dim_Position)*
