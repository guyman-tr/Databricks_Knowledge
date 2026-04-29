# BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers

> Daily aggregated zero (P&L) and exposure table for **invalid customers only** (IsValidCustomer=0), with ~6.18M rows from 2021-01-01 to 2025-06-29. Grain is one row per (Date, HedgeServerID, Copy, InstrumentID, TreeSize_Units, TreeSize_USD, Leverage, IsCFD, Regulation, MifID, InstrumentType, InstrumentName, Country, PlayerLevel, GuruStatus, SettlementType, IsValidCustomer, IsCreditReportValidCB). Written daily by SP_DailyZero_TreeSize_NEW_InvalidCustomers via DELETE+INSERT for a single date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Fact_SnapshotCustomer + dimension lookups via SP_DailyZero_TreeSize_NEW_InvalidCustomers |
| **Refresh** | Daily (DELETE for @start date + INSERT aggregated rows) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |

---

## 1. Business Meaning

BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers is the invalid-customer counterpart of `BI_DB_DailyZero_TreeSize_NEW`. It captures daily realized commissions, realized zero (P&L on closed positions), change in unrealized zero (daily PnL on open positions), total zero, NOP (net open position), and open position values — all aggregated by instrument, hedge server, copy-trade status, tree-size bucket, leverage, settlement type, regulation, MiFID categorization, country, player level, and guru status. The table filters exclusively for `Fact_SnapshotCustomer.IsValidCustomer = 0`, covering demo accounts, internal/blocked labels, and blocked-country customers. ~6.18M rows spanning 2021-01-01 to 2025-06-29; last ETL run 2025-07-03.

---

## 2. Business Logic

### 2.1 Copy-Trade Flag

**What**: Classifies each position's copy-trade relationship into a three-state integer.

**Columns Involved**: `Copy`, sourced from `MirrorID`, `OrigParentPositionID`

**Rules**:
- 1 = copied position (MirrorID > 0)
- -1 = parent/guru position (OrigParentPositionID > 0)
- 0 = manual (non-copy) position

### 2.2 Instrument Grouping (Stocks/ETF Bucketing)

**What**: Stocks and ETFs are collapsed into a single bucket (InstrumentID=1000, name='Stocks/ETF').

**Columns Involved**: `InstrumentID`, `InstrumentName`, `InstrumentType`

**Rules**:
- If InstrumentTypeID IN (5,6): InstrumentID→1000, InstrumentName→'Stocks/ETF', InstrumentType→'Stocks/ETF'
- All other asset classes retain their original InstrumentID and names

### 2.3 IsCFD / SettlementType Reconciliation

**What**: Determines whether a position is CFD or Real by reconciling IsSettled between Dim_Position and BI_DB_PositionPnL.

**Columns Involved**: `IsCFD`, `SettlementType`

**Rules**:
- When Dim_Position.IsSettled=0 AND BI_DB_PositionPnL.IsSettled=1 → IsCFD=0 (Real)
- When Dim_Position.IsSettled=1 AND BI_DB_PositionPnL.IsSettled=0 → IsCFD=1 (CFD)
- Else: IsCFD = inverse of Dim_Position.IsSettled
- SettlementType derived from IsCFD: 0→'Real'; 1→'CFD'/'TRS'/'CMT' based on SettlementTypeID (0=CFD, 2=TRS, 3=CMT)

### 2.4 TreeSize Bucketing

**What**: Positions are grouped into size buckets at the copy-tree level (by TreeID).

**Columns Involved**: `TreeSize_Units`, `TreeSize_USD`

**Rules**:
- Tree-level units = SUM(ISNULL(NOP_Units, AmountInUnitsDecimal)) per TreeID
- Tree-level USD = SUM(ISNULL(OpenPosition, OP_Realized)) per TreeID
- Buckets: Smaller, 10+, 25+, 50+, 100+, 250+, 500+, 1K+, 5K+, 10K+, 50K+, 100K+, 500K+, 1M+, 2M+ (units); Smaller, 1K+, 10K+, 100K+, 250K+, 500K+, 1000K+ (USD)

### 2.5 Zero Calculation

**What**: "Zero" = P&L excluding commissions for closed (realized) and open (unrealized) positions.

**Columns Involved**: `RealizedZero`, `ChangeInUnrealizedZero`, `TotalZero`, `RealizedCommission`

**Rules**:
- Realized (closed on @RepDate): CalculatedZero = NetProfit - prior-day PositionPnL + FullCommissionOnClose - FullCommissionByUnits (same-day opens: NetProfit + FullCommissionOnClose)
- Unrealized (still open): CalculatedZero = DailyPnL (same-day opens: + FullCommissionByUnits)
- TotalZero = SUM of both

---

## 3. Query Advisory

### 3.1 Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on [Date] ASC. Always filter by Date range for efficient scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily zero for a date | `WHERE [Date] = @dt` |
| Zero by regulation | `GROUP BY Regulation WHERE [Date] BETWEEN ...` |
| Real vs CFD exposure | `GROUP BY SettlementType` or `WHERE IsCFD = 0/1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_DailyZero_TreeSize_NEW | Same grain (valid customers) | Compare valid vs invalid customer exposure |
| DWH_dbo.Dim_Instrument | ON InstrumentID (skip 1000 bucket) | Resolve non-Stocks/ETF instrument details |

### 3.4 Gotchas

- **IsValidCustomer is always 0**: This table only contains invalid customers (filtered in SP WHERE clause). The valid-customer counterpart is `BI_DB_DailyZero_TreeSize_NEW`.
- **RiskIndex, RiskGroup, DepositGroup are always empty strings**: Hardcoded '' in the SP INSERT — placeholder columns not populated.
- **InstrumentID=1000 is synthetic**: All Stocks (TypeID=5) and ETFs (TypeID=6) are collapsed to InstrumentID=1000 with name 'Stocks/ETF'.
- **TreeSize columns are varchar buckets, not numeric values**: Use string comparison, not numeric.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 | (Tier 1 — upstream production source) |
| Tier 2 | (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| Tier 3 | (Tier 3 — SP parameter / ETL timestamp) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | Snapshot calendar date, the reporting date for this aggregation row. (Tier 3 — SP parameter @start) |
| 2 | HedgeServerID | int | NO | FK to Trade.HedgeServer. Hedge server managing the positions in this aggregation bucket. (Tier 1 — Trade.PositionTbl) |
| 3 | Copy | int | NO | Copy-trade classification: 1=copied position (MirrorID>0), -1=parent/guru position (OrigParentPositionID>0), 0=manual. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 4 | InstrumentID | int | NO | Instrument identifier; Stocks (TypeID=5) and ETFs (TypeID=6) are collapsed to synthetic ID 1000. All other asset classes retain the original InstrumentID. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 5 | RiskIndex | int | NO | Placeholder column, always 0 (empty string cast to int in DDL context). Not populated by the SP. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 6 | TreeSize_Units | varchar(50) | NO | Copy-tree size bucket by units: Smaller, 10+, 25+, 50+, 100+, 250+, 500+, 1K+, 5K+, 10K+, 50K+, 100K+, 500K+, 1M+, 2M+. Bucketed from SUM of AmountInUnitsDecimal/NOP_Units per TreeID. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 7 | TreeSize_USD | varchar(50) | NO | Copy-tree size bucket by USD: Smaller, 1K+, 10K+, 100K+, 250K+, 500K+, 1000K+. Bucketed from SUM of OpenPosition/OP_Realized per TreeID. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 8 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) |
| 9 | RiskGroup | nvarchar(50) | YES | Placeholder column, always empty string. Not populated by the SP. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 10 | DepositGroup | nvarchar(50) | YES | Placeholder column, always empty string. Not populated by the SP. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 11 | RealizedCommission | money | YES | SUM of commissions on positions closed on this date: FullCommissionOnClose minus prorated FullCommissionByUnits for positions opened before the report date. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 12 | RealizedZero | money | YES | SUM of realized zero (P&L excluding commissions) for positions closed on this date: NetProfit minus prior-day PositionPnL plus FullCommissionOnClose minus FullCommissionByUnits. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 13 | ChangeInUnrealizedZero | money | YES | SUM of unrealized zero (daily P&L change) for open positions: DailyPnL for pre-existing positions, DailyPnL plus FullCommissionByUnits for same-day opens. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 14 | TotalZero | money | YES | SUM of all CalculatedZero across realized and unrealized positions; equals RealizedZero + ChangeInUnrealizedZero at the row level before aggregation. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 15 | NOP | money | YES | SUM of net open position in USD from BI_DB_PositionPnL, signed by direction (positive for long, negative for short). Zero for closed positions. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 16 | OpenPositions | money | YES | SUM of directional open position value (NOP × IsBuy direction sign). Represents net long exposure. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 17 | Nop_Units | money | YES | SUM of AmountInUnitsDecimal from BI_DB_PositionPnL for open positions. Represents aggregate unit exposure. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 18 | VolumeAtOpen | money | YES | SUM of ETL-computed USD volume for positions opened on this date (Volume from Dim_Position where OpenDateID matches). Zero for pre-existing positions. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 19 | VolumeAtClose | money | YES | SUM of ETL-computed USD volume for positions closed on this date (VolumeOnClose from Dim_Position where CloseDateID matches). Zero for open positions. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 20 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() at insert time. (Tier 3 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 21 | IsCFD | tinyint | YES | 1=CFD position, 0=Real asset position. Reconciled from Dim_Position.IsSettled and BI_DB_PositionPnL.IsSettled with precedence logic. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 22 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. ISNULL defaults to 'Unknown'. (Tier 1 — Dictionary.Regulation) |
| 23 | MifID | int | YES | MiFID II client categorization (Retail/Professional/Eligible Counterparty) from Fact_SnapshotCustomer.MifidCategorizationID. Renamed in SP. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 24 | InstrumentType | varchar(50) | YES | Asset class label; Stocks (TypeID=5) and ETFs (TypeID=6) collapsed to 'Stocks/ETF'. Other values: Currencies, Commodities, Indices, Crypto Currencies. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 25 | InstrumentName | varchar(50) | YES | Instrument display name; Stocks/ETFs collapsed to 'Stocks/ETF'. Other instruments retain original Name from Dim_Instrument (e.g., EUR/USD, NSDQ100/USD). (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 26 | OpenPositionValue | money | YES | SUM of (Amount + PositionPnL) from BI_DB_PositionPnL for open positions. Represents total market value of open positions. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 27 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country via Fact_SnapshotCustomer.CountryID. (Tier 1 — Dictionary.Country) |
| 28 | PlayerLevel | varchar(100) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel via Fact_SnapshotCustomer.PlayerLevelID. (Tier 1 — Dictionary.PlayerLevel) |
| 29 | GuruStatus | nvarchar(100) | YES | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus via Fact_SnapshotCustomer.GuruStatusID. (Tier 1 — Dictionary.GuruStatus) |
| 30 | Long_OP | decimal(18,6) | YES | SUM of NOP for long (IsBuy=1) positions only. Represents gross long exposure in USD. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 31 | Short_OP | decimal(18,6) | YES | SUM of NOP for short (IsBuy=0) positions only. Represents gross short exposure in USD. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 32 | SettlementType | varchar(10) | YES | Settlement classification: 'Real' (non-CFD), 'CFD' (SettlementTypeID=0), 'TRS' (SettlementTypeID=2), 'CMT' (SettlementTypeID=3). Derived from IsCFD and Dim_Position.SettlementTypeID. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 33 | IsValidCustomer | int | YES | Always 0 in this table (SP filters WHERE IsValidCustomer=0). 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 34 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. Passthrough from Fact_SnapshotCustomer. (Tier 2 — SP_Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| Date | SP parameter | @start | CAST to DATE |
| HedgeServerID | Dim_Position | HedgeServerID | Passthrough |
| Copy | Dim_Position | MirrorID, OrigParentPositionID | CASE: 1/-1/0 |
| InstrumentID | Dim_Position + Dim_Instrument | InstrumentID, InstrumentTypeID | Stocks/ETF→1000 |
| Leverage | Dim_Position | Leverage | Passthrough |
| Regulation | Dim_Regulation | Name | ISNULL(Name,'Unknown') |
| Country | Dim_Country | Name | Passthrough |
| PlayerLevel | Dim_PlayerLevel | Name | Passthrough |
| GuruStatus | Dim_GuruStatus | GuruStatusName | Passthrough |
| MifID | Fact_SnapshotCustomer | MifidCategorizationID | Rename |
| IsValidCustomer | Fact_SnapshotCustomer | IsValidCustomer | Passthrough (filtered to 0) |
| IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough |
| IsCFD / SettlementType | Dim_Position + BI_DB_PositionPnL | IsSettled, SettlementTypeID | Reconciliation CASE |
| RealizedCommission/Zero/etc. | Computed | Multiple sources | Aggregation (SUM) |
| NOP, OpenPositions, Nop_Units | BI_DB_PositionPnL | NOP, AmountInUnitsDecimal | SUM with direction sign |
| TreeSize_Units/USD | Computed | OpenPosition, AmountInUnitsDecimal | Tree-level SUM then bucket |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (positions open/closed on @dt)
BI_DB_dbo.BI_DB_PositionPnL (open position PnL snapshot for @dt)
DWH_dbo.Fact_SnapshotCustomer (customer state, WHERE IsValidCustomer=0)
  + Dim_Range (SCD2 date range filter)
  + Dim_Instrument, Dim_Regulation, Dim_Country, Dim_PlayerLevel, Dim_GuruStatus (lookups)
  |-- SP_DailyZero_TreeSize_NEW_InvalidCustomers @start ---|
  |   #Positions → #Pos_with_Vol → #TreeSize → #NewPositions → #Realized + #UnRealized → #Final
  |   DELETE WHERE Date=@start, then INSERT aggregated rows
  v
BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers (~6.18M rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_dbo.Dim_Position | Open/closed positions for @dt |
| Source | BI_DB_dbo.BI_DB_PositionPnL | Daily PnL snapshot (NOP, DailyPnL) |
| Source | DWH_dbo.Fact_SnapshotCustomer | Customer attributes (IsValidCustomer=0 filter) |
| Lookups | Dim_Range, Dim_Instrument, Dim_Regulation, Dim_Country, Dim_PlayerLevel, Dim_GuruStatus | Dimension joins |
| ETL | SP_DailyZero_TreeSize_NEW_InvalidCustomers @start | DELETE+INSERT for single date |
| Target | BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers | Aggregated daily zero/exposure |

---

## 6. Relationships

### 6.1 References To (this object reads from)

| Element | Related Object | Description |
|---------|---------------|-------------|
| HedgeServerID | DWH_dbo.Dim_Position | Hedge server identifier |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument (1000=Stocks/ETF bucket) |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name via Fact_SnapshotCustomer |
| Country | DWH_dbo.Dim_Country | Country name via Fact_SnapshotCustomer |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Loyalty tier name via Fact_SnapshotCustomer |
| GuruStatus | DWH_dbo.Dim_GuruStatus | Popular Investor status via Fact_SnapshotCustomer |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (None identified) | — | No known consumers in the bundle |

---

## 7. Sample Queries

### 7.1 Daily total zero and NOP by regulation for a specific date

```sql
SELECT Regulation,
       SUM(TotalZero) AS TotalZero,
       SUM(NOP) AS TotalNOP,
       SUM(OpenPositionValue) AS TotalOPV
FROM BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers
WHERE [Date] = '2025-06-29'
GROUP BY Regulation
ORDER BY TotalNOP DESC;
```

### 7.2 Real vs CFD exposure breakdown by settlement type

```sql
SELECT [Date], SettlementType,
       SUM(OpenPositions) AS NetOpenPosition,
       SUM(Long_OP) AS LongExposure,
       SUM(Short_OP) AS ShortExposure
FROM BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers
WHERE [Date] >= '2025-06-01'
GROUP BY [Date], SettlementType
ORDER BY [Date], SettlementType;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode).

---

*Generated: 2026-04-28 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 6 T1, 26 T2, 2 T3, 0 T4, 0 T5 | Elements: 34/34, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers | Type: Table | Production Source: DWH_dbo.Dim_Position + BI_DB_PositionPnL + Fact_SnapshotCustomer via SP_DailyZero_TreeSize_NEW_InvalidCustomers*
