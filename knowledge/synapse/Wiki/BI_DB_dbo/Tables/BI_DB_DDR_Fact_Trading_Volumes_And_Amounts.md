# BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts

> 793M-row daily trading volume and invested amount fact table tracking position open/close volumes, invested amounts, and transaction counts per customer, broken down by instrument type, settlement, copy-trade, leverage, and 8+ position flags. Sourced from `Function_Trading_Volume_PositionLevel` (which reads `Dim_Position`, `Dim_Instrument`, and multiple enrichment tables), aggregated by `SP_DDR_Fact_Trading_Volumes_And_Amounts` with daily DELETE/INSERT by DateID.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.Function_Trading_Volume_PositionLevel` → `DWH_dbo.Dim_Position` + `DWH_dbo.Dim_Instrument` |
| **Refresh** | Daily (DELETE/INSERT by DateID) |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table is the **daily trading volume and invested amount fact table** within the DDR framework. Each row represents the aggregated open/close trading activity for a customer on a specific date, broken down by instrument type, settlement, copy-trade status, buy/sell direction, leverage, and multiple position attribute flags.

It answers: "What was the total trading volume and invested amount for each customer today, by asset class and trade characteristics? How many positions were opened and closed?"

Data originates from `Function_Trading_Volume_PositionLevel`, which produces one row per position per open/close event from `Dim_Position`. The function outputs 32 columns including persisted volumes (from `Dim_Position.Volume` and `VolumeOnClose`), computed QA volumes (recomputed from units × FX rates), and invested amounts. The SP aggregates these position-level rows into CID × dimension-group granularity using SUM for all measure columns.

The SP was authored 2025-04-20, making it newer than most DDR SPs. Key changes: IsSQF (2025-06-23), IsMarginTrade (2025-10-23), IsC2P (2025-12-14), and source function replacement with position-level granularity + QA dump (2026-01-15). A QA dump to `BI_DB_VolumeQA` is performed alongside the main INSERT for data quality validation.

---

## 2. Business Logic

### 2.1 Volume Aggregation

**What**: Position-level open/close volumes are aggregated to CID × dimension group level

**Columns Involved**: `VolumeOpen`, `VolumeClose`, `TotalVolume`

**Rules**:
- `VolumeOpen` = SUM of persisted volume from `Dim_Position.Volume` (BIGINT cast) for positions opened on this date
- `VolumeClose` = SUM of persisted volume from `Dim_Position.VolumeOnClose` for positions closed on this date
- `TotalVolume` = SUM of `VolumeOpen + VolumeClose` per position (computed in the function, then summed)
- Partial-close-child positions have `VolumeOpen = 0` and `CountOpenTransactions = 0` (they're not new opens)

### 2.2 Invested Amount Calculation

**What**: Tracks money invested in opens vs money returned on closes

**Columns Involved**: `InvestedAmountOpen`, `InvestedAmountClosed`, `NetInvestedAmount`

**Rules**:
- `InvestedAmountOpen` = SUM of `InitialAmountCents / 100.0` (excluding partial-close children, which contribute 0)
- `InvestedAmountClosed` = SUM of `CAST(Amount AS FLOAT)` for closed positions
- `NetInvestedAmount` = SUM of (InvestedAmountOpen - InvestedAmountClosed) per position, then summed
- Positive NetInvestedAmount = net new investment; negative = net disinvestment

### 2.3 Transaction Counting

**What**: Counts trading actions separately for opens and closes

**Columns Involved**: `CountOpenTransactions`, `CountCloseTransactions`, `CountTotalTransactions`

**Rules**:
- `CountOpenTransactions` = count of position opens (excludes partial-close children)
- `CountCloseTransactions` = count of position closes
- `CountTotalTransactions` = Open + Close (computed per position in function, then summed)
- A position opened and closed on the same day contributes to both open and close counts

### 2.4 Leverage Classification

**What**: Binary flag for leveraged positions

**Columns Involved**: `IsLeverage`

**Rules**:
- `IsLeverage = 1` when `Leverage > 1` in the source function
- Column named `IsLeverage` (not `IsLeveraged` like other DDR tables)
- Applied at GROUP BY level — each leverage state gets its own aggregation row

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `RealCID` with a CLUSTERED COLUMNSTORE INDEX. Always include `RealCID` in WHERE or JOIN conditions for optimal distribution-aligned queries. With 793M rows, always filter by `DateID`.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total volume for a customer | `WHERE RealCID = @cid AND DateID BETWEEN @s AND @e` — SUM `TotalVolume` |
| Volume by instrument type | `GROUP BY DateID, InstrumentTypeID` — SUM `TotalVolume`, `NetInvestedAmount` |
| Copy vs manual trading volumes | `GROUP BY DateID, IsCopy` — SUM volume and amount measures |
| Daily traded count | `GROUP BY DateID` — SUM `CountTotalTransactions` |
| IBAN-originated trading | `WHERE IsOpenedFromIBAN = 1 GROUP BY DateID` |
| Leveraged vs unleveraged volume | `GROUP BY DateID, IsLeverage` — SUM `TotalVolume` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_InstrumentType` | `ON v.InstrumentTypeID = dit.InstrumentTypeID` | Instrument class name |
| `DWH_dbo.Dim_Customer` | `ON v.RealCID = dc.RealCID` | Customer demographics |
| `BI_DB_dbo.BI_DB_DDR_CID_Level` | `ON v.RealCID = cl.RealCID AND v.DateID = cl.DateID` | Full DDR daily picture per customer |

### 3.4 Gotchas

- **793M rows** — always filter by `DateID`.
- **IsOpenedFromIBAN is VARCHAR(100)** — DDL defines this as `varchar(100)`, not `int` like other boolean flags. Compare as string `'1'` or `'0'`, not integer. This is likely a DDL artifact.
- **IsLeverage vs IsLeveraged** — this table uses `IsLeverage` (no 'd'), unlike other DDR tables that use `IsLeveraged`. Same semantics.
- **VolumeOpen/VolumeClose are BIGINT** — not decimal. These represent notional volume in the instrument's native units × FX rate, expressed as whole numbers.
- **InvestedAmountOpen/Closed are MONEY** — Synapse `money` type, not `decimal`. Be aware of potential precision differences.
- **Partial-close children** — excluded from open counts and invested amounts to avoid double-counting. They appear only on the close side.
- **TotalVolume ≠ VolumeOpen + VolumeClose at aggregated level** — `TotalVolume` is SUM of per-position (VolumeOpen + VolumeClose), which equals SUM(VolumeOpen) + SUM(VolumeClose) only when the same positions aren't counted in both columns within the same group.
- **QA dump** — `BI_DB_VolumeQA` receives position-level detail for data validation. It's not consumed by downstream reporting.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code / function) | `(Tier 2 — ...)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date key in YYYYMMDD format. DELETE/INSERT partition key. Direct from `Function_Trading_Volume_PositionLevel.DateID` (open or close date). (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 2 | Date | date | YES | Calendar date. `CONVERT(DATE, CONVERT(VARCHAR(8), ftv.DateID), 112)`. Derived from DateID in SP. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 3 | RealCID | int | YES | Customer identifier. Renamed from `Function_Trading_Volume_PositionLevel.CID`. Distribution key. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 4 | InstrumentTypeID | int | YES | Instrument asset class ID. Key values: **1=Currencies/Forex, 2=Commodities, 4=Indices, 5=Stocks, 6=ETFs, 9=Options, 10=Crypto.** Combine with IsSettled: ID=5+IsSettled=1 = real stocks; ID=10+IsSettled=0 = crypto CFD; ID=10+IsSettled=1 = real crypto; ID=9 = Options (always real). JOIN to DWH_dbo.Dim_InstrumentType for name. Source: Dim_Instrument via Function_Trading_Volume_PositionLevel. (Tier 1 — Function_Trading_Volume_PositionLevel) |
| 5 | IsSettled | int | YES | **Real-asset settlement flag.** 1 = real/settled ownership (actual transfer of ownership: real crypto, real stocks/ETFs). 0 = CFD (Contract for Difference — synthetic price exposure, no ownership). Critical for volume reporting: regulators and management track CFD vs real volumes separately. Also used in DDR Active Trader segmentation for crypto real vs CFD breakdown. Source: Dim_Position.IsSettled via Function_Trading_Volume_PositionLevel. (Tier 1 — Function_Trading_Volume_PositionLevel) |
| 6 | IsCopy | int | YES | **Copy-trade flag.** CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END. 1 = position created as part of copying another trader (MirrorID links to a copy relationship in Dim_Mirror). 0 = manual/self-directed trade. Does not distinguish CopyFund (Smart Portfolio) from regular copy — use IsCopyFund for that. Source: Dim_Position.MirrorID via Function_Trading_Volume_PositionLevel. (Tier 1 — Function_Trading_Volume_PositionLevel) |
| 7 | IsBuy | int | YES | Trade direction. 1=buy/long, 0=sell/short. Direct from function → `Dim_Position.IsBuy`. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 8 | IsLeverage | int | YES | Leverage flag. `CASE WHEN ftv.Leverage > 1 THEN 1 ELSE 0 END`. Note: named `IsLeverage` (not `IsLeveraged`). (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 9 | IsFuture | int | YES | Futures contract flag. Direct from function → `Dim_Instrument.IsFuture`. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 10 | IsCopyFund | int | YES | **CopyFund / Smart Portfolio flag.** 1 = position belongs to a managed Smart Portfolio (CopyFund) product where a portfolio manager allocates across assets on the customer's behalf. Distinct from regular copy-trading: CopyFunds are discretionary managed products, not peer-to-peer copying. Lookup via BI_DB_CopyFund_Positions. Source: Function_Trading_Volume_PositionLevel. (Tier 1 — Function_Trading_Volume_PositionLevel) |
| 11 | IsOpenedFromIBAN | varchar(100) | YES | Position opened from eMoney IBAN flag. `CASE WHEN BI_DB_Positions_Opened_From_IBAN.PositionID IS NOT NULL THEN 1 ELSE 0 END` in function. **DDL is varchar(100), stores '0'/'1' as strings.** (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 12 | IsClosedToIBAN | int | YES | Position closed to eMoney IBAN flag. `CASE WHEN BI_DB_Positions_Closed_To_IBAN.PositionID IS NOT NULL THEN 1 ELSE 0 END` in function. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 13 | IsRecurring | int | YES | **Recurring investment flag.** 1 = position opened via the Recurring Investment auto-invest feature (customer schedules automated periodic investments). Lookup via BI_DB_RecurringInvestment_Positions. Useful for segmenting auto-investing behaviour vs manual trading. Source: Function_Trading_Volume_PositionLevel. (Tier 1 — Function_Trading_Volume_PositionLevel) |
| 14 | IsAirDrop | int | YES | AirDrop (free share) flag. Direct from function → `Dim_Position.IsAirDrop`. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 15 | VolumeOpen | bigint | YES | **Aggregated notional volume from position opens on this date (BIGINT).** SUM of CAST(Dim_Position.Volume AS BIGINT) for open legs. Partial-close children are excluded (their VolumeOpen=0) to avoid double-counting. BIGINT represents native instrument units × FX rate. Primary KPI for new positions opened. Source: Dim_Position.Volume via Function_Trading_Volume_PositionLevel. (Tier 1 — Function_Trading_Volume_PositionLevel) |
| 16 | VolumeClose | bigint | YES | **Aggregated notional volume from position closes on this date (BIGINT).** SUM of CAST(Dim_Position.VolumeOnClose AS BIGINT) for close legs. Source: Dim_Position.VolumeOnClose via Function_Trading_Volume_PositionLevel. (Tier 1 — Function_Trading_Volume_PositionLevel) |
| 17 | InvestedAmountOpen | money | YES | Aggregated invested amount from position opens. `SUM(ftv.InvestedAmountOpen)`. Source: `InitialAmountCents / 100.0` (0 for partial-close children). (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 18 | InvestedAmountClosed | money | YES | Aggregated invested amount from position closes. `SUM(ftv.InvestedAmountClosed)`. Source: `CAST(Dim_Position.Amount AS FLOAT)` on close legs. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 19 | TotalVolume | bigint | YES | **Combined notional volume: open + close on this date (BIGINT).** SUM of per-position (VolumeOpen+VolumeClose). A position opened AND closed on the same day contributes to both open and close sides. This is the primary trading volume KPI used in eToro management and regulatory reporting. Source: Function_Trading_Volume_PositionLevel. (Tier 1 — Function_Trading_Volume_PositionLevel) |
| 20 | NetInvestedAmount | money | YES | Net investment flow. `SUM(ftv.NetInvestedAmount)`. Per position: `InvestedAmountOpen - InvestedAmountClosed`. Positive = net new investment. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 21 | CountOpenTransactions | int | YES | Count of position opens (excl. partial-close children). `SUM(ftv.CountOpenTransactions)`. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 22 | CountCloseTransactions | int | YES | Count of position closes. `SUM(ftv.CountCloseTransactions)`. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 23 | CountTotalTransactions | int | YES | Total open + close count. `SUM(ftv.CountTotalTransactions)`. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 24 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()` at SP execution time. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 25 | IsSQF | int | YES | Sustainable & Quality-Focused instrument flag. From `Function_Instrument_Snapshot_Enriched` in the source function. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 26 | IsMarginTrade | int | YES | Margin trade flag. `CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END` in function. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 27 | IsC2P | int | YES | **Copy-to-Portfolio (C2P) flag.** 1 = position was migrated from a copy relationship into the customer's own self-directed portfolio after they stopped copying a trader. Allows customers to keep holding a position without the ongoing copy overhead. Lookup via V_C2P_Positions. Source: Function_Trading_Volume_PositionLevel. (Tier 1 — Function_Trading_Volume_PositionLevel) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RealCID | Dim_Position (via function) | CID | rename |
| IsLeverage | Dim_Position (via function) | Leverage | CASE WHEN > 1 |
| VolumeOpen | Dim_Position (via function) | Volume | SUM(CAST AS BIGINT) |
| VolumeClose | Dim_Position (via function) | VolumeOnClose | SUM(CAST AS BIGINT) |
| InvestedAmountOpen | Dim_Position (via function) | InitialAmountCents | SUM(/ 100.0, excl. partial-close) |
| InvestedAmountClosed | Dim_Position (via function) | Amount | SUM(CAST AS FLOAT) |
| IsCopy | Dim_Position (via function) | MirrorID | CASE WHEN > 0 |
| IsMarginTrade | Dim_Position (via function) | SettlementTypeID | CASE WHEN = 5 |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (position opens + closes for date range)
  + DWH_dbo.Dim_Instrument (InstrumentTypeID, IsFuture)
  + BI_DB enrichment tables (CopyFund, C2P, Recurring, IBAN open/close, SQF)
  |
  |-- Function_Trading_Volume_PositionLevel(@dateID, @dateID, 0)
  |     → 32 columns per position event (open leg + close leg UNIONed)
  |
  |-- SP_DDR_Fact_Trading_Volumes_And_Amounts(@date):
  |     #data = full function output
  |     GROUP BY 14 dimension columns, SUM 9 measure columns
  |     DELETE/INSERT by DateID
  |     + QA dump to BI_DB_VolumeQA
  v
BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts (793M rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Dim_Position, Dim_Instrument, enrichment tables | Position-level trading data |
| TVF | Function_Trading_Volume_PositionLevel | 32-column position-level volume and amount output |
| ETL | SP_DDR_Fact_Trading_Volumes_And_Amounts | GROUP BY aggregation, DELETE/INSERT, QA dump |
| Target | BI_DB_DDR_Fact_Trading_Volumes_And_Amounts | Aggregated trading volume fact |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| InstrumentTypeID | DWH_dbo.Dim_InstrumentType | Instrument class name |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_DDR_CID_Level | — | CID-level daily DDR aggregation |
| BI_DB_dbo.Function_DDR_Aggregation_* | — | Time-range aggregation functions |

---

## 7. Sample Queries

### 7.1 Daily volume by instrument type

```sql
SELECT DateID,
       dit.Name AS InstrumentType,
       SUM(TotalVolume) AS TotalVolume,
       SUM(NetInvestedAmount) AS NetInvested,
       SUM(CountTotalTransactions) AS Transactions
FROM BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts v
JOIN DWH_dbo.Dim_InstrumentType dit ON v.InstrumentTypeID = dit.InstrumentTypeID
WHERE v.DateID = 20260309
GROUP BY v.DateID, dit.Name
ORDER BY TotalVolume DESC;
```

### 7.2 Customer trading activity summary

```sql
SELECT DateID,
       SUM(VolumeOpen) AS VolOpen,
       SUM(VolumeClose) AS VolClose,
       SUM(InvestedAmountOpen) AS InvestedOpen,
       SUM(InvestedAmountClosed) AS InvestedClosed,
       SUM(CountOpenTransactions) AS Opens,
       SUM(CountCloseTransactions) AS Closes
FROM BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts
WHERE RealCID = 12345678
  AND DateID BETWEEN 20260301 AND 20260309
GROUP BY DateID
ORDER BY DateID;
```

### 7.3 Copy vs manual volume comparison

```sql
SELECT CASE WHEN IsCopy = 1 THEN 'CopyTrade' ELSE 'Manual' END AS TradeType,
       SUM(TotalVolume) AS Volume,
       SUM(CountTotalTransactions) AS Transactions
FROM BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts
WHERE DateID = 20260309
GROUP BY IsCopy
ORDER BY IsCopy;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-26 | Quality: 8.5/10 (★★★★☆) | Phases: 14/14*
*Tiers: 0 T1, 27 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts | Type: Table | Production Source: Function_Trading_Volume_PositionLevel → Dim_Position + Dim_Instrument*
