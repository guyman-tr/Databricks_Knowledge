# BI_DB_dbo.BI_DB_IFRS_15_Daily_Positions

> 317.5M-row position-level IFRS 15 crypto detail table (Jan 2022–Apr 2026, 1,563 dates). Each row is one crypto position active on a given date — opened, closed, or carrying forward — classified by settlement type, direction, position timing, and outlier/DLT custody status. Scope: crypto instruments only (InstrumentTypeID=10 OR InstrumentID=624). Written FIRST by SP_IFRS_15_Balance; the sister table BI_DB_IFRS15_Daily_Balance reads from this table to aggregate IFRS 15 balance and flow metrics. The two-day retroactive WHILE loop ensures late-materializing redeems are captured on the correct date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_PositionPnL + Dim_Position (via SP_IFRS_15_Balance @date) |
| **Refresh** | Daily (SB_Daily, Priority 20); DELETE WHERE DateID=@startDateInt + INSERT; WHILE loop @date-1 to @date (2-day retroactive window for late-materializing redeems) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | 317,515,102 (as of 2026-04-12) |
| **Date Range** | 20220101 – 20260412 |
| **Distinct CIDs** | 3,145,490 |
| **Distinct Dates** | 1,563 |

---

## 1. Business Meaning

BI_DB_IFRS_15_Daily_Positions is the position-level detail feed for IFRS 15 crypto reconciliation. Each row represents one crypto position's activity on a specific date: whether it was opened, closed, or a carry-forward position that was held through the day. The table covers ONLY crypto assets (InstrumentTypeID=10, e.g., BTC, XRP, ETH) plus the crypto index instrument (InstrumentID=624 added 2025-05-15 per SR-314556).

The table's grain is (DateID, PositionID) — a single position can appear on multiple dates as it carries forward. The **PositionTiming** column classifies each appearance: positions opened today ('Opened_In_Period_Not_Closed'), positions opened and closed on the same day ('Opened_And_Closed_In_Period'), positions closed today that were opened earlier ('Opened_Before_Period_Closed_InPeriod'), and carry-forward positions open through the day ('bla' — a placeholder value in the ETL code for positions not opened or closed on this date; these are the opening/closing balance spine for the IFRS metrics).

The **two-day WHILE loop** (from @date-1 to @date) exists because Billing redeems can materialize in the system the next day after the actual redeem event. By re-running for the previous date, the SP ensures the prior day's position data reflects any late-arriving redeem status changes. Only the very last date in the series may be slightly off pending the next day's run.

This table is the primary input for BI_DB_IFRS15_Daily_Balance, which reads position rows back and aggregates them into 29 UNION ALL metric branches (ExcelOrder 1–29) plus two DLT transition rows (ExcelOrder 32–33). Analysts needing position-level IFRS detail query this table directly; analysts needing the IFRS metric output query BI_DB_IFRS15_Daily_Balance.

The two always-NULL columns — **Changed_CFD_Real** and **Change_Type** — are populated by a separate changelog branch within SP_IFRS_15_Balance (from Dim_PositionChangeLog ChangeTypeID 12/13) but are always NULL for the standard #relpos INSERT branch. In recent April 2026 data, all rows show OutlierTransition='NoTransition' (no outlier events on sampled dates).

---

## 2. Business Logic

### 2.1 Crypto Scope Filter

**What**: The table is exclusively crypto assets — no equity, FX, or commodity positions.
**Columns Involved**: `InstrumentID`, `Name`
**Rules**:
- Include: `Dim_Instrument.InstrumentTypeID = 10` (all crypto) OR `InstrumentID = 624` (crypto index, added 2025-05-15 per SR-314556)
- `Name` = Dim_Instrument.BuyCurrency (the base currency code: 'BTC', 'XRP', 'ETH', 'XLM', etc.)

### 2.2 Settlement Classification (CFD vs Real)

**What**: Classifies positions by settlement type at open and at latest date.
**Columns Involved**: `CFD_Real_On_Open`, `CFD_Real_Latest`, `Changed_CFD_Real`, `Change_Type`
**Rules**:
- `CFD_Real_On_Open`: CASE WHEN StartDayIsSettled=1 THEN 'RealOnOpen' ELSE 'CFDOnOpen' — settlement status at the position open date
- `CFD_Real_Latest`: CASE WHEN EndDayIsSettled=1 THEN 'Real' ELSE 'CFD' — current settlement status
- April 2026: CFDOnOpen=55.6%, RealOnOpen=44.4%; Real=50.7%, CFD=49.3%
- `Changed_CFD_Real` and `Change_Type`: Always NULL in the standard insert branch; populated from Dim_PositionChangeLog (ChangeTypeID 12=Real_to_CFD, 13=CFD_to_Real) in a separate INSERT not tracked by this position-level entry

### 2.3 Position Timing Classification

**What**: Indicates what happened to this position on the report date.
**Columns Involved**: `PositionTiming`
**Rules**:
- `'Opened_In_Period_Not_Closed'`: OpenDateID=@date AND CloseDateID>@date OR CloseDateID=0 — opened today, still open (25% of April 2026 rows)
- `'Opened_And_Closed_In_Period'`: OpenDateID=@date AND CloseDateID=@date — same-day open and close (3% of rows)
- `'Opened_Before_Period_Closed_InPeriod'`: OpenDateID<@date AND CloseDateID=@date — pre-existing position closed today (25% of rows)
- `'bla'`: All other positions — carry-forward positions open through the day, neither opened nor closed on this date (47% of rows — the largest group; ETL placeholder value, not a meaningful business label)

### 2.4 Volume Computation

**What**: USD-equivalent trading volume computed from instrument prices.
**Columns Involved**: `ComputedVolumeOpen`, `ComputedVolumeClose`
**Rules**:
- `ComputedVolumeOpen`: Only non-zero for positions opened today — `InitialUnits × InitForexRate × COALESCE(InitForex_USDConversionRate, InitConversionRate, LastOpConversionRate)`. For partial-close child positions (IsPartialCloseChild=1), forced to 0 to avoid double-counting
- `ComputedVolumeClose`: Only non-zero for positions closed today — `AmountInUnitsDecimal × EndForexRate × ISNULL(LastOpConversionRate, 1)`
- Both are 0 for carry-forward ('bla') positions

### 2.5 DLT / Tangany Custody Classification

**What**: Tracks positions in Distributed Ledger Technology (real blockchain) custody versus eToro internal custody.
**Columns Involved**: `TanganyStatus`, `IsDLTUser`
**Rules**:
- `TanganyStatus` from BI_DB_Client_Balance_CID_Level_New: NULL (91.9% — standard internal custody), 'Inactive', 'MicaCustomer', 'Internal', 'Customer', 'ConsentCustomer'
- `IsDLTUser`: 1 = customer is in DLT status (Fact_SnapshotCustomer.DltStatusID=4); 0 = standard. April 2026: 67,988 DLT users in Inactive TanganyStatus
- These fields feed ExcelOrder 32/33 in BI_DB_IFRS15_Daily_Balance to handle customers who enter or exit DLT status (creating gaps in the balance aggregation)

### 2.6 Ticket Fee Percentages

**What**: The fee percentage applied at open/close for crypto positions (added 2025-05-15 per SR-315125).
**Columns Involved**: `TicketFeePercentOpen`, `TicketFeePercentClose`
**Rules**:
- Sourced from `Function_Revenue_TicketFeeByPercent(@endDateInt, @endDateInt, 0)` — LEFT JOIN on PositionID
- NULL when no ticket fee applies (most positions); fee expressed as a decimal (e.g., 5.00000000 = 5%)
- Only applicable to positions that have a ticket fee in the revenue function for that date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** with CLUSTERED INDEX on DateID. No co-location on PositionID or CID. JOINs to HASH-distributed tables (Dim_Position on PositionID, Dim_Customer on CID) require data movement.

Date-range queries benefit from the clustered index on DateID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Crypto volume for a date | `WHERE DateID = X AND PositionTiming IN ('Opened_In_Period_Not_Closed', 'Opened_And_Closed_In_Period')` to count opens; add ComputedVolumeOpen |
| Real vs CFD position count | `GROUP BY CFD_Real_Latest` |
| Active open positions on a date | `WHERE DateID = X AND CFD_Real_Latest IN ('Real','CFD') AND PositionTiming IN ('bla','Opened_In_Period_Not_Closed')` |
| Redeem activity | `WHERE IsRedeem = 'Redeem'` (only 0.2% of rows) |
| Staking positions | `WHERE Staking = 'Staking'` (21.9% of recent rows) |
| DLT custody positions | `WHERE IsDLTUser = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | ON PositionID | Get full position details (P&L, dates, etc.) |
| DWH_dbo.Dim_Instrument | ON InstrumentID | Instrument metadata (asset class, full name) |
| DWH_dbo.Dim_Customer | ON CID | Customer demographics, regulation, country |
| BI_DB_dbo.BI_DB_IFRS15_Daily_Balance | DateID+ExcelOrder | Aggregated IFRS metrics for the same date |
| BI_DB_dbo.BI_DB_PositionPnL | ON PositionID + DateID | Underlying PnL data for positions |

### 3.4 Gotchas

- **'bla' PositionTiming** (47% of rows): This is a placeholder value in the ETL for carry-forward open positions (open before the date, still open after). It is NOT a recognizable business value — ETL code uses it as an ELSE default. Always handle 'bla' explicitly in your CASE statements or it will be included/excluded unexpectedly.
- **317M rows — always filter by DateID**: Never run an unfiltered COUNT or GROUP BY without a date predicate. Even date-filtered queries can be slow given the ROUND_ROBIN distribution.
- **Changed_CFD_Real and Change_Type always NULL**: These columns are never populated by the standard position insert. They are reserved for CFD↔Real changelog rows (a separate code path in the SP) that appear to INSERT additional rows. In practice, these columns serve as metadata for the balance table's CFD_to_Real_Conversion metric (ExcelOrder 18-21).
- **Retroactive correction window**: The prior day's data is re-run as part of every daily execution. If you're reading data for yesterday, wait 24 hours to ensure the correction pass has completed.
- **NOLOCK on BI_DB_PositionPnL and Dim_Position**: The SP uses NOLOCK hints. In rare cases, dirty reads could cause inconsistent data on the loading day.
- **IsAirDrop → Staking naming**: The column `Staking` reflects `Dim_Position.IsAirDrop`. The semantic shift from "airdrop" to "staking" was a business classification change — these positions are now considered staking positions for IFRS purposes.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (Dim_Position, Dim_Instrument, Dim_Customer) |
| Tier 2 | Derived from SP code analysis (SP_IFRS_15_Balance) |
| Tier 3 | ETL infrastructure metadata |
| Tier 4 | Unverified / always NULL — observed from data |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | ETL date integer (YYYYMMDD) for the report date. CAST(CONVERT(VARCHAR(8), @startDate, 112) AS INT). Clustered index key. (Tier 2 — SP_IFRS_15_Balance) |
| 2 | PositionID | bigint | YES | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough via BI_DB_PositionPnL. (Tier 1 — Trade.PositionTbl via Dim_Position) |
| 3 | CID | int | YES | Customer ID. References Customer.Customer. Passthrough via BI_DB_PositionPnL. Only IsValidCustomer=1 AND IsCreditReportValidCB=1 customers are included per Fact_SnapshotCustomer JOIN. (Tier 1 — Trade.PositionTbl via Dim_Position) |
| 4 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Crypto only: InstrumentTypeID=10 or InstrumentID=624. FK to Dim_Instrument. (Tier 1 — Trade.Instrument via Dim_Instrument) |
| 5 | Name | varchar(100) | YES | Instrument base currency code (BuyCurrency from Dim_Instrument). Examples: 'BTC', 'XRP', 'ETH', 'XLM', 'NEAR'. NOT the full instrument display name. (Tier 1 — Trade.Instrument via Dim_Instrument.BuyCurrency) |
| 6 | CFD_Real_On_Open | varchar(100) | YES | Settlement type at the position's open date. 'RealOnOpen'=position was settled as real crypto at open (IsSettled=1); 'CFDOnOpen'=was CFD at open. April 2026: CFDOnOpen=55.6%, RealOnOpen=44.4%. (Tier 2 — SP_IFRS_15_Balance) |
| 7 | CFD_Real_Latest | varchar(100) | YES | Settlement type at the current report date. 'Real'=currently settled as real crypto; 'CFD'=currently CFD. A position can change from CFDOnOpen to Real via CFD_to_Real conversion (see Changed_CFD_Real). April 2026: Real=50.7%, CFD=49.3%. (Tier 2 — SP_IFRS_15_Balance) |
| 8 | Long_Short | varchar(100) | YES | Trade direction. 'Long'=bought (IsBuy=1, 97.8% of rows); 'Short'=sold (IsBuy=0, 2.2% of rows). Crypto positions are predominantly long. (Tier 2 — SP_IFRS_15_Balance) |
| 9 | IsRedeem | varchar(100) | YES | Redemption flag. 'Redeem'=position was closed via crypto redeem (ActionTypeID=28 in Fact_CustomerAction AND Closed=1, 0.2% of rows); 'Not_Redeem'=standard close or still open. (Tier 2 — SP_IFRS_15_Balance) |
| 10 | Staking | varchar(100) | YES | Staking (airdrop) classification. 'Staking'=position comes from a staking/airdrop event (Dim_Position.IsAirDrop=1, 21.9% of April 2026 rows); 'Not_Staking'=regular trading position (78.1%). Column name reflects business re-classification of IsAirDrop as staking for IFRS purposes. (Tier 2 — SP_IFRS_15_Balance) |
| 11 | PositionTiming | varchar(100) | YES | Position lifecycle classification relative to the report date. 'Opened_In_Period_Not_Closed'=opened today, still open (25.2%); 'Opened_And_Closed_In_Period'=opened and closed same day (3.4%); 'Opened_Before_Period_Closed_InPeriod'=pre-existing, closed today (24.5%); 'bla'=carry-forward position, open through the day without opening or closing on this date (47.0% — ETL placeholder ELSE value, not a meaningful business label). (Tier 2 — SP_IFRS_15_Balance) |
| 12 | InitialUnits | decimal(38,8) | YES | Original unit count at open. Used for partial close ratio. Passthrough via BI_DB_PositionPnL. (Tier 1 — Trade.PositionTbl via Dim_Position) |
| 13 | AmountInUnitsDecimal | decimal(38,8) | YES | Position size in units/shares. Fractional lots. Passthrough via BI_DB_PositionPnL. (Tier 1 — Trade.PositionTbl via Dim_Position) |
| 14 | IsPartialCloseParent | int | YES | 1=this position was partially closed (is the parent in a partial close event). ISNULL(Dim_Position.IsPartialCloseParent, 0). (Tier 1 — Trade.PositionTbl via Dim_Position) |
| 15 | IsPartialCloseChild | int | YES | 1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. ISNULL(Dim_Position.IsPartialCloseChild, 0). (Tier 1 — Trade.PositionTbl via Dim_Position) |
| 16 | IsPartialCloseChildFromReOpen | int | YES | 1=partial close child that was created via a ReOpen flow. ISNULL(Dim_Position.IsPartialCloseChildFromReOpen, 0). (Tier 1 — Trade.PositionTbl via Dim_Position) |
| 17 | Leverage | int | YES | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Real crypto positions require Leverage=1. Passthrough via BI_DB_PositionPnL. (Tier 1 — Trade.PositionTbl via Dim_Position) |
| 18 | ComputedVolumeOpen | decimal(38,8) | YES | ETL-computed USD volume at open. Non-zero only for positions opened on DateID: InitialUnits × InitForexRate × COALESCE(InitForex_USDConversionRate, InitConversionRate, LastOpConversionRate). Forced to 0 for IsPartialCloseChild=1 positions to avoid double-counting. Zero for carry-forward ('bla') and closed-only positions. (Tier 2 — SP_IFRS_15_Balance) |
| 19 | ComputedVolumeClose | decimal(38,8) | YES | ETL-computed USD volume at close. Non-zero only for positions closed on DateID: AmountInUnitsDecimal × EndForexRate × ISNULL(LastOpConversionRate, 1). Zero for positions opened-today-not-closed and carry-forward ('bla') positions. (Tier 2 — SP_IFRS_15_Balance) |
| 20 | FullCommission | decimal(38,8) | YES | Net commission for this position on this date. Computed differently by PositionTiming: 'Opened_In_Period_Not_Closed'→ISNULL(FullCommissionByUnits, CommissionByUnits); 'Opened_And_Closed_In_Period'→ISNULL(FullCommissionOnClose, CommissionOnClose); 'Opened_Before_Period_Closed_InPeriod'→FullCommissionOnClose - FullCommissionByUnits (net of reopen adjustments). (Tier 2 — SP_IFRS_15_Balance) |
| 21 | IsValidCustomer | int | YES | Customer validity flag at report date. From Fact_SnapshotCustomer: 1 = valid customer; 0 = invalid. Used to separate valid vs. invalid customer book in IFRS reconciliation. DWH-computed: 1 when not Internal (PlayerLevelID≠4), not label 30/26, and not CountryID=250. (Tier 1 — DWH_dbo.Dim_Customer) |
| 22 | IsCreditReportValidCB | int | YES | Credit bureau validity flag at report date. From Fact_SnapshotCustomer: 1 = customer has valid credit bureau check; 0 = invalid. Separates credit-valid from credit-invalid sub-books in IFRS reports. DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250. (Tier 1 — DWH_dbo.Dim_Customer) |
| 23 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_IFRS_15_Balance (GETDATE() at load time). (Tier 3 — ETL metadata) |
| 24 | Regulation | varchar(50) | YES | Customer regulation name at the time of the action. Joined from Dim_Regulation via Fact_SnapshotCustomer.RegulationID at the SCD-valid date range. Represents the regulatory jurisdiction of the customer's positions. April 2026: CySEC=58.4%, FCA=25.2%, FSA Seychelles=4.8%, FinCEN+FINRA=4.8%. (Tier 2 — SP_IFRS_15_Balance) |
| 25 | Changed_CFD_Real | int | YES | CFD↔Real conversion flag from Dim_PositionChangeLog. Always NULL in the standard position insert branch (#relpos); populated by a separate changelog INSERT (ChangeTypeID 12=Real_to_CFD, 13=CFD_to_Real) not visible in April 2026 sample. Used by BI_DB_IFRS15_Daily_Balance ExcelOrder 18-21 conversion metrics. (Tier 4 — always NULL in sampled data) |
| 26 | Change_Type | varchar(50) | YES | CFD↔Real change type description. Always NULL in the standard position insert branch. Populated alongside Changed_CFD_Real by the changelog INSERT. Values: 'CFD_to_Real', 'Real_to_CFD', 'NotRelevant'. (Tier 4 — always NULL in sampled data) |
| 27 | IsOutlier | int | YES | Statistical outlier flag. From BI_DB_Outliers_New: 1 = customer is a position-size outlier (large unusual position that could distort aggregate metrics); 0 = normal customer. NULL for DLT balance rows (ExcelOrder 32, 33). Note: BI_DB_Outliers_New is filtered WHERE Transition NOT LIKE '%dlt%' to exclude DLT-specific outlier classifications. (Tier 2 — SP_IFRS_15_Balance) |
| 28 | OutlierTransition | varchar(50) | YES | Outlier transition description from BI_DB_Outliers_New.Transition. 'NoTransition' = customer is not an outlier or has no transition. Specific transition names describe what kind of outlier event occurred. NULL for DLT balance rows. April 2026: 100% 'NoTransition' (no outlier events on sampled dates). (Tier 2 — SP_IFRS_15_Balance) |
| 29 | TanganyStatus | varchar(20) | YES | Crypto custody status from BI_DB_Client_Balance_CID_Level_New. Tangany is eToro's crypto custody provider. MAX(TanganyStatus) per CID at the report date. Values: NULL (91.9% — standard internal custody), 'Inactive' (6.8%), 'MicaCustomer' (1.2%), 'Internal', 'Customer', 'ConsentCustomer'. Added 2024-02-28. (Tier 2 — SP_IFRS_15_Balance) |
| 30 | IsDLTUser | int | YES | Distributed Ledger Technology user flag from BI_DB_Client_Balance_CID_Level_New. MAX(IsDLTUser) per CID at report date. 1 = customer holds real crypto in DLT/blockchain custody (Fact_SnapshotCustomer.DltStatusID=4); 0 = standard crypto position. DLT users appear or disappear from balance aggregations when their DLT status changes. Added 2024-07-30. (Tier 2 — SP_IFRS_15_Balance) |
| 31 | TicketFeePercentOpen | decimal(16,8) | YES | Ticket fee percentage at position open from Function_Revenue_TicketFeeByPercent(@endDateInt, @endDateInt, 0) WHERE TicketFeeByPercentAction='Open'. NULL when no ticket fee applies (most rows). Added 2025-05-15 per SR-314556. (Tier 2 — SP_IFRS_15_Balance) |
| 32 | TicketFeePercentClose | decimal(16,8) | YES | Ticket fee percentage at position close from Function_Revenue_TicketFeeByPercent(@endDateInt, @endDateInt, 0) WHERE TicketFeeByPercentAction='Close'. NULL for open positions or positions without a ticket fee. Added 2025-05-15 per SR-314556. (Tier 2 — SP_IFRS_15_Balance) |
| 33 | IsC2P | int | YES | Copy-to-Portfolio position flag. 1 = position was created as part of a C2P compensation (CompensationReasonID=134 in External_Bronze_etoro_Trade_AdminPositionLog); 0 = standard position. April 2026: 645 C2P positions (0.05% of rows). Added 2025-11-25 per SR-344696. (Tier 2 — SP_IFRS_15_Balance) |
| 34 | IsTransferOut | int | YES | Transfer-out position flag. 1 = position was closed via portfolio transfer (Dim_Position.ClosePositionReasonID=22); 0 = standard close or still open. April 2026: 102 transfer-out positions (0.01% of rows). Added 2025-12-15 per SR-347921. (Tier 2 — SP_IFRS_15_Balance) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|--------------|-----------|
| PositionID | etoro.Trade.PositionTbl (via Dim_Position → BI_DB_PositionPnL) | PositionID | Passthrough |
| CID | etoro.Trade.PositionTbl (via Dim_Position → BI_DB_PositionPnL) | CID | Passthrough |
| InstrumentID | etoro.Trade.Instrument (via Dim_Instrument) | InstrumentID | Passthrough |
| Name | etoro.Trade.Instrument (via Dim_Instrument.BuyCurrency) | BuyCurrency | Passthrough |
| InitialUnits | etoro.Trade.PositionTbl (via Dim_Position → BI_DB_PositionPnL) | InitialUnits | Passthrough |
| AmountInUnitsDecimal | etoro.Trade.PositionTbl (via Dim_Position → BI_DB_PositionPnL) | AmountInUnitsDecimal | Passthrough |
| Leverage | etoro.Trade.PositionTbl (via Dim_Position → BI_DB_PositionPnL) | Leverage | Passthrough |
| IsPartialCloseParent/Child/ChildFromReOpen | etoro.Trade.PositionTbl (via Dim_Position) | IsPartialClose* | ISNULL(..., 0) |
| IsValidCustomer | BackOffice.Customer (via Dim_Customer/Fact_SnapshotCustomer) | computed | DWH-computed |
| IsCreditReportValidCB | BackOffice.Customer (via Dim_Customer/Fact_SnapshotCustomer) | computed | DWH-computed |
| PositionTiming | etoro.Trade.PositionTbl (via Dim_Position) | OpenDateID, CloseDateID | CASE classification |
| IsRedeem | etoro.Trade.PositionTbl (via Fact_CustomerAction) | IsRedeem | CASE WHEN |

### 5.2 ETL Pipeline

```
etoro.Trade.PositionTbl (production, etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ------------|
  v
DWH_staging.etoro_Trade_PositionTbl
  |-- SP_Dim_Position_DL_To_Synapse @dt ----------|
  v
DWH_dbo.Dim_Position
  |-- SP_PositionPnL_DL_To_Synapse @dt -----------|
  v
BI_DB_dbo.BI_DB_PositionPnL (daily PnL per position)
  |
  +-- Additional sources: BI_DB_Outliers_New, BI_DB_Client_Balance_CID_Level_New,
  |   Function_Revenue_TicketFeeByPercent, External_Bronze_etoro_Trade_AdminPositionLog
  |
  |-- SP_IFRS_15_Balance @date (WHILE @date-1 to @date) --|
  |   DELETE WHERE DateID=@startDateInt                     |
  |   INSERT INTO                                           |
  v
BI_DB_dbo.BI_DB_IFRS_15_Daily_Positions (317.5M rows, crypto-only position detail)
  |
  v [read back by same SP for aggregation]
BI_DB_dbo.BI_DB_IFRS15_Daily_Balance (20-col IFRS 15 metric aggregations)
  |
  v [UC: Not Migrated]
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PositionID | DWH_dbo.Dim_Position | Full position lifecycle details, PnL, dates |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata (type, exchange, currencies) |
| CID | DWH_dbo.Dim_Customer | Customer demographics, tier, country |
| CID | DWH_dbo.Fact_SnapshotCustomer | Customer SCD2 snapshot for validity/regulation |
| IsOutlier/OutlierTransition | BI_DB_dbo.BI_DB_Outliers_New | Outlier classification source |
| TanganyStatus/IsDLTUser | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Crypto custody status source |
| PositionID | BI_DB_dbo.BI_DB_PositionPnL | Primary position data source |
| PositionID | BI_DB_dbo.Function_Revenue_TicketFeeByPercent | Ticket fee computation |
| IsC2P | BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog | C2P compensation positions |

### 6.2 Referenced By (other objects point to this)

| Object | Reference | Notes |
|--------|-----------|-------|
| BI_DB_dbo.BI_DB_IFRS15_Daily_Balance | Reads BI_DB_IFRS_15_Daily_Positions via same SP_IFRS_15_Balance | 29 UNION ALL metric branches aggregate from this table |

---

## 7. Sample Queries

### Crypto positions active on a date by settlement type
```sql
SELECT
    CFD_Real_Latest,
    CFD_Real_On_Open,
    COUNT(*) AS position_count,
    SUM(AmountInUnitsDecimal) AS total_units,
    SUM(ComputedVolumeOpen) AS open_volume_usd
FROM [BI_DB_dbo].[BI_DB_IFRS_15_Daily_Positions]
WHERE DateID = 20260412
GROUP BY CFD_Real_Latest, CFD_Real_On_Open
ORDER BY position_count DESC;
```

### Positions opened today (volume flow)
```sql
SELECT
    Name AS crypto,
    Regulation,
    COUNT(*) AS opened_positions,
    SUM(ComputedVolumeOpen) AS total_usd_volume,
    SUM(FullCommission) AS total_commission
FROM [BI_DB_dbo].[BI_DB_IFRS_15_Daily_Positions]
WHERE DateID = 20260412
  AND PositionTiming IN ('Opened_In_Period_Not_Closed', 'Opened_And_Closed_In_Period')
GROUP BY Name, Regulation
ORDER BY total_usd_volume DESC;
```

### DLT custody breakdown by Tangany status
```sql
SELECT
    TanganyStatus,
    COUNT(*) AS positions,
    COUNT(DISTINCT CID) AS distinct_customers,
    SUM(IsDLTUser) AS dlt_user_positions
FROM [BI_DB_dbo].[BI_DB_IFRS_15_Daily_Positions]
WHERE DateID = 20260412
GROUP BY TanganyStatus
ORDER BY positions DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this position-level IFRS detail table. See the change history in SP_IFRS_15_Balance for ticket references:
- SR-314556 (2025-05-15): Added crypto index instrument (InstrumentID=624) and ticket fee percentages
- SR-315125 (2025-05-21): Bug fix on instrument 624 (missing from position opens/close)
- SR-333553 (2025-09-18): Updated Tangany statuses
- SR-344696 (2025-11-25): Added DLT/Tangany from Client Balance snapshot, added C2P flag
- SR-347921 (2025-12-15): Added IsTransferOut and Regulation columns

---

*Generated: 2026-04-22 | Quality: 9.0/10 | Phases: 13/14*
*Tiers: 11 T1, 19 T2, 1 T3, 2 T4, 0 T5 | Elements: 34/34, Logic: 6 groups*
*Object: BI_DB_dbo.BI_DB_IFRS_15_Daily_Positions | Type: Table | Production Source: SP_IFRS_15_Balance (BI_DB_PositionPnL + Dim_Position)*
