# BI_DB_dbo.BI_DB_Crypto_Dashboard

> 69.3M-row daily crypto trading dashboard (2020-01-01 to 2026-04-12, 2,294 dates) capturing aggregated position-level metrics for all active crypto instruments (InstrumentTypeID=10). Each row represents a unique Date × Regulation × Country × BuyCurrency × Real/CFD × Manual/Copy segment for valid, depositing, non-demo customers. Rebuilt daily via SP_CryptoDashboard (DELETE WHERE DateID=@dateID + INSERT). Covers AUA, PnL, Revenue, First-Action investors, open/opened position counts, and active customer holder counts across 120+ crypto assets.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (population) + DWH_dbo.Dim_Position + BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Fact_CustomerAction + DWH_dbo.Fact_FirstCustomerAction + DWH_dbo.Dim_Date via SP_CryptoDashboard |
| **Refresh** | Daily incremental (SP_CryptoDashboard, DELETE WHERE DateID=@dateID + INSERT, SB_Daily orchestration) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([DateID] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Crypto_Dashboard is the primary daily crypto trading analytics table supporting Business Intelligence dashboards for crypto business performance. It aggregates position-level crypto data at the grain of **Date × Regulation × Country × BuyCurrency × Real/CFD type × Manual/Copy type** — 69.3M rows spanning 2020-01-01 to 2026-04-12 across 2,294 unique dates.

**Population**: Active, depositing, non-demo customers visible in Fact_SnapshotCustomer on @date (IsValidCustomer=1, IsDepositor=1, PlayerLevelID≠4 — demo accounts excluded). Instruments filtered to InstrumentTypeID=10 (crypto assets) only.

**Crypto universe**: 120+ distinct BuyCurrency tickers (BTC, ETH, ADA, XRP, SOL, DOGE, LTC, LINK, XLM, TRX, BNB, UNI, BCH, DOT, SHIBxM, etc.). Covers both real crypto (IsSettled=1 — actual crypto ownership) and crypto CFDs (IsSettled=0 — derivative contracts).

**Key metrics per segment**:
- **AUA** (Assets Under Administration): invested amount + unrealized PnL — total crypto exposure
- **Revenue**: trading commissions (open + close) plus rollover fees — daily monetization from crypto
- **# of FA Crypto** / **FA Amount Total**: new-to-crypto investor acquisition tracking (FirstEver=1)
- **Opened/Open Positions**: daily crypto position flow vs. outstanding inventory
- **Acvtive Hold** variants: distinct customer headcount by scope (note: "Acvtive" is a persisted typo in DDL and SP — preserved for schema compatibility)

**Distribution by segment (2026-01-01 to 2026-04-12)**:
- Real/CFD: Real=~57%, Copy=~29%, CFD Manual=9%, CFD Copy=5%
- Regulations: CySEC=33%, FCA=32%, FSA Seychelles=28%, ASIC & GAML=3%, FSRA=2%, others=2%
- UpdateDate ranges 2021-08-02 to present — rows before 2021-08-02 originate from historical backfill at SP creation.

---

## 2. Business Logic

### 2.1 Crypto Population Filter

**What**: Only valid, depositing, non-demo customers holding crypto are included.

**Columns Involved**: `Regulation`, `Country`, `[Real/CFD]`, `[Manual/Copy]`

**Rules**:
- Fact_SnapshotCustomer filter: `IsValidCustomer=1 AND IsDepositor=1 AND PlayerLevelID≠4`
- PlayerLevelID=4 = Demo account — explicitly excluded from all crypto metrics
- DateRangeID must span @dateID — only customers active on the reporting date are included
- The #pop temp table is HASH distributed on CID for efficient JOIN performance

### 2.2 Real vs. CFD Classification

**What**: Crypto positions are split between real ownership and CFD derivatives based on the IsSettled flag in Dim_Position.

**Columns Involved**: `[Real/CFD]`

**Rules**:
- `[Real/CFD]='Real'`: IsSettled=1 — customer actually owns the crypto units (regulated real crypto market)
- `[Real/CFD]='CFD'`: IsSettled=0 — customer holds a Contract for Difference (leveraged derivative, no actual crypto ownership)
- Real positions dominate: ~74% of rows in 2026 are Real crypto
- Only 2 distinct values — never NULL in practice

### 2.3 Manual vs. Copy Classification

**What**: Positions are split by whether the customer traded manually or via the copy-trading system.

**Columns Involved**: `[Manual/Copy]`

**Rules**:
- `[Manual/Copy]='Manual'`: MirrorID=0 in Dim_Position — customer self-initiated the trade
- `[Manual/Copy]='Copy'`: MirrorID≠0 — position was opened as part of a copy-trading relationship (following a Popular Investor)
- Manual dominates: ~67% of rows are Manual
- Only 2 distinct values — never NULL in practice

### 2.4 AUA Computation (Assets Under Administration)

**What**: AUA represents total crypto exposure — invested capital plus floating PnL.

**Columns Involved**: `AUA`, `[Amount in Units]`, `PnL`

**Rules**:
- `AUA` = SUM(ppnl.Amount + ppnl.PositionPnL) from BI_DB_PositionPnL where DateID=@dateID and InstrumentTypeID=10
- `[Amount in Units]` = SUM(ppnl.AmountInUnitsDecimal) — native crypto quantity (e.g., 0.224609 BTC)
- `PnL` = SUM(ppnl.PositionPnL) — unrealized profit/loss component only
- AUA > 0 even when PnL < 0 (because Amount ≫ |PnL| for most positions)

### 2.5 Revenue Computation

**What**: Revenue aggregates all trading monetization events on @date for the segment.

**Columns Involved**: `Revenue`

**Rules**:
- Revenue = SUM(open commissions: ActionTypeID IN 1,2,3,39, FullCommissionByUnits + FullCommission) + SUM(close commissions: ActionTypeID IN 4,5,6,40, FullCommissionOnClose - FullCommissionByUnits) + SUM(rollover fees: ActionTypeID=35, IsFeeDividend=1, Amount*-1)
- All filtered to CIDs in #pop (valid depositing non-demo crypto holders) and InstrumentTypeID=10
- Revenue=0 for many segment rows (especially large-volume dates with ISNULL(c.FullTotalCommission,0)+ISNULL(r.RollOver,0))

### 2.6 Date-Level vs. Segment-Level Columns

**What**: Three "Acvtive Hold" columns are date-level aggregates repeated for every segment row, NOT segment-level metrics.

**Columns Involved**: `[Acvtive Hold]`, `[Active Hold Real]`, `[Active Hold CFD]`

**Rules**:
- These come from #activehold: `COUNT(DISTINCT CID)` from #positionpnl grouped ONLY by DateID
- They have NO dimension segmentation (no Country/Regulation/BuyCurrency breakdown)
- Same value repeated for ALL rows with the same DateID — do NOT sum across rows
- `[Acvtive Hold by Inst]` IS segment-level (from #activeholdins) — different computation
- "Acvtive" is a typo in both DDL and SP code — preserved in schema, never corrected

### 2.7 First Action (FA) Crypto Tracking

**What**: FA metrics count new-to-crypto customers making their very first crypto position open.

**Columns Involved**: `[# of FA Crypto]`, `[FA Amount Total]`

**Rules**:
- Source: Fact_FirstCustomerAction WHERE ActionTypeID=1 AND FirstEver=1 AND DateID=@dateID
- Joined to #firstactiondate (MIN(FirstOccurred) per CID) to identify the exact first crypto event
- `[FA Amount Total]` = SUM(-ffca.Amount) — negative sign applied in SP to convert from cost to investment amount
- Both can be 0 for most segment rows (FA events are rare — only on new investor's first open date)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID. At 69.3M rows with heavy date-slicing:
- DateID is the primary filter key — clustering supports efficient range scans by date
- ROUND_ROBIN means JOINs to HASH-distributed tables (Dim_Position, Fact_SnapshotCustomer) will shuffle — prefer aggregating first before joining
- For date-range queries, always filter on `DateID` (int) rather than `Date` (date) for clustering benefit

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Daily crypto AUA by regulation | `WHERE DateID=20260412 GROUP BY Regulation ORDER BY SUM(AUA) DESC` |
| Crypto revenue trend by asset type | `WHERE DateID BETWEEN 20260101 AND 20260412 AND [Real/CFD]='Real' GROUP BY Date, BuyCurrency` |
| BTC Real vs CFD comparison | `WHERE BuyCurrency='BTC' GROUP BY Date, [Real/CFD] ORDER BY Date DESC` |
| Total active crypto holders (date-level) | `SELECT DISTINCT DateID, [Acvtive Hold], [Active Hold Real], [Active Hold CFD] FROM BI_DB_Crypto_Dashboard WHERE DateID=20260412` — use DISTINCT to avoid summing repeated values |
| New crypto investors by regulation | `WHERE DateID>=20260101 AND [# of FA Crypto]>0 GROUP BY Date, Regulation ORDER BY SUM([# of FA Crypto]) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `ON BuyCurrency = di.BuyCurrency AND di.InstrumentTypeID=10` | Get full instrument metadata |
| DWH_dbo.Dim_Country | `ON Country = dc.Name` | Get CountryID for further country filtering |
| DWH_dbo.Dim_Regulation | `ON Regulation = dr.Name` | Get RegulationID for regulation filtering |

### 3.4 Gotchas

- **Acvtive Hold MUST NOT be summed**: `[Acvtive Hold]`, `[Active Hold Real]`, `[Active Hold CFD]` are date-level metrics repeated for all segment rows. Summing them across rows will massively over-count. Use `SELECT DISTINCT DateID, [Acvtive Hold]` or filter to one row per date.
- **"Acvtive" typo in column names**: Columns 22 (`[Acvtive Hold by Inst]`) and 24 (`[Acvtive Hold]`) have a persistent typo — must be referenced as-is in SQL.
- **Column names with special characters**: `[Real/CFD]`, `[Manual/Copy]`, `[# of FA Crypto]`, `[FA Amount Total]`, `[Amount in Units]`, `[Opened Positions]`, `[Open Positions]`, `[Acvtive Hold by Inst]`, `[Acvtive Hold]`, `[Active Hold Real]`, `[Active Hold CFD]` — must use square brackets in SQL.
- **Revenue=0 for FA-only segments**: Rows where the customer opened their first position but generated no commission (e.g., no open spread on real crypto) will have Revenue=0 but [# of FA Crypto]>0.
- **FA Amount Total is negated**: The SP applies SUM(-Amount) — the value in the table is positive (representing dollars invested), not the raw negative Amount from Fact_FirstCustomerAction.
- **DateID is NOT NULL but Date is NULL-capable**: DateID is declared NOT NULL in DDL. Date is nullable but never actually NULL in practice.
- **Historical rows without UpdateDate**: Rows from 2020-01-01 to 2021-08-01 may have UpdateDate earlier than 2021-08-02 or different timestamp patterns — the SP was created 2021-06-13 and historical backfill was done.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★★ | Tier 1 | Upstream production wiki verbatim |
| ★★★ | Tier 2 | DWH SP code / ETL derivation |
| ★★ | Tier 3 | DWH dimension passthrough / structural inference |
| ★ | Tier 4 — Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date (input parameter to SP_CryptoDashboard). The date for which all crypto metrics are aggregated. Range: 2020-01-01 to 2026-04-12. (Tier 2 — SP_CryptoDashboard) |
| 2 | DateID | int | NO | Integer date key in YYYYMMDD format (e.g., 20260412). Derived via CONVERT(CHAR(8),@date,112). Clustered index key — primary filter for date-range queries. (Tier 2 — SP_CryptoDashboard) |
| 3 | DayName | varchar(10) | YES | Day of week name (e.g., 'Sunday', 'Monday', ..., 'Saturday'). From DWH_dbo.Dim_Date.DayName via LEFT JOIN on DateKey=@dateID. (Tier 3 — DWH_dbo.Dim_Date) |
| 4 | SSWeekNumberOfMonth | tinyint | YES | eToro fiscal week number within the calendar month (SS = Sales Support convention, range 1–5). From Dim_Date.SSWeekNumberOfMonth. Differs from ISO week numbering. (Tier 3 — DWH_dbo.Dim_Date) |
| 5 | YearWeek | int | YES | Composite year+week key: YEAR(@date)*100 + Dim_Date.SSWeekNumberOfYear (e.g., 202616 = week 16 of 2026). Used for weekly trend grouping. (Tier 2 — SP_CryptoDashboard) |
| 6 | DayNumberOfWeek_Sun_Start | tinyint | YES | Day of week number where Sunday=1 and Saturday=7. From Dim_Date.DayNumberOfWeek_Sun_Start. Useful for identifying weekday/weekend patterns in crypto trading. (Tier 3 — DWH_dbo.Dim_Date) |
| 7 | WeekofMonth | int | YES | Composite week-of-month key: YEAR*10000 + MONTH*100 + SSWeekNumberOfMonth (e.g., 20260403 = third week of April 2026). Enables monthly-within-week slicing. (Tier 2 — SP_CryptoDashboard) |
| 8 | IsLastDayOfMonth | char(1) | YES | Month-end flag: 'Y' if this date is the last calendar day of the month, 'N' otherwise. From Dim_Date.IsLastDayOfMonth. Useful for month-end AUA and PnL snapshots. (Tier 3 — DWH_dbo.Dim_Date) |
| 9 | Regulation | varchar(50) | YES | Regulatory entity name governing the customer segment (e.g., 'CySEC', 'FCA', 'FSA Seychelles', 'ASIC & GAML', 'FSRA', 'FinCEN+FINRA', 'FinCEN', 'BVI', 'MAS'). Lookup from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. 9 distinct values observed in 2026. (Tier 2 — SP_CryptoDashboard) |
| 10 | Country | varchar(50) | YES | Full country name in English. Unique per row. Loaded from etoro.Dictionary.Country.Name via DWH_dbo.Dim_Country JOIN on CountryID. (Tier 1 — Dictionary.Country) |
| 11 | BuyCurrency | varchar(50) | YES | Crypto asset ticker symbol identifying the specific cryptocurrency being reported (e.g., 'BTC', 'ETH', 'ADA', 'XRP', 'SOL', 'DOGE', 'LTC', 'LINK', 'XLM', 'TRX'). From Dim_Instrument.BuyCurrency for instruments filtered to InstrumentTypeID=10. 120+ distinct values. (Tier 2 — SP_CryptoDashboard) |
| 12 | [Real/CFD] | varchar(4) | YES | Settlement type classification: 'Real' (IsSettled=1 in Dim_Position — customer owns actual crypto units) or 'CFD' (IsSettled=0 — Contract for Difference derivative). CASE WHEN dp.IsSettled=1 THEN 'Real' ELSE 'CFD'. Only 2 distinct values. (Tier 2 — SP_CryptoDashboard) |
| 13 | [Manual/Copy] | varchar(6) | YES | Trade origin type: 'Manual' (MirrorID=0 in Dim_Position — customer self-initiated) or 'Copy' (MirrorID≠0 — opened as part of a copy-trading relationship following a Popular Investor). Only 2 distinct values. (Tier 2 — SP_CryptoDashboard) |
| 14 | AUA | decimal(38,4) | YES | Assets Under Administration in USD: total invested amount plus unrealized PnL for open crypto positions in this segment on @dateID. SUM(ppnl.Amount + ppnl.PositionPnL) from BI_DB_PositionPnL. Represents total current exposure. Can be 0 for segments with no open positions at EOD. (Tier 2 — SP_CryptoDashboard) |
| 15 | [Amount in Units] | numeric(38,6) | YES | Total cryptocurrency units held across open positions in this segment. SUM(ppnl.AmountInUnitsDecimal) from BI_DB_PositionPnL. Native crypto quantity (e.g., 0.224609 BTC, 4000.0 ANKR). Precision varies by asset (BTC: small fractions; SHIB: large integers). (Tier 2 — SP_CryptoDashboard) |
| 16 | PnL | decimal(38,4) | YES | Total unrealized profit/loss in USD on open crypto positions for this date+segment. SUM(ppnl.PositionPnL) from BI_DB_PositionPnL. Negative = unrealized loss (AUA still positive as Amount > |PnL| typically). (Tier 2 — SP_CryptoDashboard) |
| 17 | Revenue | decimal(38,2) | YES | Total trading revenue in USD from crypto activity in this date+segment: sum of open commissions (ActionTypeID IN 1,2,3,39) + close commissions (ActionTypeID IN 4,5,6,40) + rollover fees (ActionTypeID=35, IsFeeDividend=1). All from Fact_CustomerAction. Revenue=0 for segments where no commission-generating events occurred on @date. (Tier 2 — SP_CryptoDashboard) |
| 18 | [# of FA Crypto] | int | YES | Count of customers making their very first-ever crypto position open on @dateID (Fact_FirstCustomerAction WHERE ActionTypeID=1, FirstEver=1, DateID=@dateID). New-to-crypto investor acquisition metric. 0 for most segment rows; positive only when a customer in this segment made their debut crypto investment on this date. (Tier 2 — SP_CryptoDashboard) |
| 19 | [FA Amount Total] | decimal(38,2) | YES | Total USD amount invested by first-action crypto customers in this segment on @dateID. SUM(-ffca.Amount) from Fact_FirstCustomerAction (negated in SP — value in table is positive, representing investment size). 0 when [# of FA Crypto]=0. (Tier 2 — SP_CryptoDashboard) |
| 20 | [Opened Positions] | int | YES | Count of new crypto positions opened by customers in this segment on @dateID (Dim_Position WHERE OpenDateID=@dateID AND ISNULL(IsPartialCloseChild,0)=0). Excludes partial-close child positions. 0 for segments with no new positions on @date. (Tier 2 — SP_CryptoDashboard) |
| 21 | [Open Positions] | int | YES | Count of crypto positions still open at end-of-day on @dateID (positions present in BI_DB_PositionPnL with DateID=@dateID and InstrumentTypeID=10 in this segment). Running inventory of outstanding crypto positions. (Tier 2 — SP_CryptoDashboard) |
| 22 | [Acvtive Hold by Inst] | int | YES | Count of distinct customer accounts (CID) holding open crypto positions in this specific Date × Regulation × Country × BuyCurrency × Real/CFD × Manual/Copy segment. COUNT(DISTINCT ppnl.CID) from #activeholdins. Note: "Acvtive" is a persisted typo from the SP — preserved in schema for compatibility. (Tier 2 — SP_CryptoDashboard) |
| 23 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last written by SP_CryptoDashboard (GETDATE() at INSERT execution time). Ranges from 2021-08-02 to 2026-04-13. Rows from 2020-2021 may have earlier or NULL UpdateDate from historical backfill. (Tier 2 — SP_CryptoDashboard) |
| 24 | [Acvtive Hold] | int | YES | Total count of distinct customers holding ANY open crypto position on @dateID — NOT segmented by dimensions. COUNT(DISTINCT CID) from #positionpnl grouped by DateID only. Same value repeated for ALL segment rows sharing the same DateID. ⚠ DO NOT SUM across rows — use SELECT DISTINCT DateID, [Acvtive Hold] for date-level queries. "Acvtive" is a persisted typo. (Tier 2 — SP_CryptoDashboard) |
| 25 | [Active Hold Real] | int | YES | Count of distinct customers holding open REAL crypto positions (IsSettled=1) on @dateID. COUNT(DISTINCT CID WHERE IsSettled=1) from #positionpnl. Date-level aggregate — same value repeated for all segment rows with the same DateID. Subset of [Acvtive Hold]. ⚠ DO NOT SUM across rows. (Tier 2 — SP_CryptoDashboard) |
| 26 | [Active Hold CFD] | int | YES | Count of distinct customers holding open crypto CFD positions (IsSettled≠1) on @dateID. COUNT(DISTINCT CID WHERE IsSettled≠1) from #positionpnl. Date-level aggregate — same value repeated for all segment rows with the same DateID. Subset of [Acvtive Hold]. ⚠ DO NOT SUM across rows. Note: [Active Hold Real] + [Active Hold CFD] may not equal [Acvtive Hold] if a customer holds both types. (Tier 2 — SP_CryptoDashboard) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Date | SP input parameter | @date | Direct assignment |
| DateID | SP input parameter | @date | CONVERT(CHAR(8),@date,112) |
| DayName | DWH_dbo.Dim_Date | DayName | Passthrough via DateKey=@dateID |
| SSWeekNumberOfMonth | DWH_dbo.Dim_Date | SSWeekNumberOfMonth | Passthrough |
| YearWeek | DWH_dbo.Dim_Date | SSWeekNumberOfYear | YEAR(@date)*100 + SSWeekNumberOfYear |
| DayNumberOfWeek_Sun_Start | DWH_dbo.Dim_Date | DayNumberOfWeek_Sun_Start | Passthrough |
| WeekofMonth | DWH_dbo.Dim_Date | SSWeekNumberOfMonth | YEAR*10000+MONTH*100+SSWeekNumberOfMonth |
| IsLastDayOfMonth | DWH_dbo.Dim_Date | IsLastDayOfMonth | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Lookup via Fact_SnapshotCustomer.RegulationID |
| Country | etoro.Dictionary.Country (via Dim_Country) | Name | Lookup via Fact_SnapshotCustomer.CountryID |
| BuyCurrency | DWH_dbo.Dim_Instrument | BuyCurrency | Filter InstrumentTypeID=10, passthrough |
| [Real/CFD] | DWH_dbo.Dim_Position | IsSettled | CASE WHEN IsSettled=1 THEN 'Real' ELSE 'CFD' |
| [Manual/Copy] | DWH_dbo.Dim_Position | MirrorID | CASE WHEN MirrorID=0 THEN 'Manual' ELSE 'Copy' |
| AUA | BI_DB_dbo.BI_DB_PositionPnL | Amount + PositionPnL | SUM(Amount+PositionPnL) at DateID=@dateID |
| [Amount in Units] | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM(AmountInUnitsDecimal) |
| PnL | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | SUM(PositionPnL) |
| Revenue | DWH_dbo.Fact_CustomerAction | FullCommission + Amount | SUM(commissions) + SUM(rollover fees) |
| [# of FA Crypto] | DWH_dbo.Fact_FirstCustomerAction | — | COUNT(CID WHERE FirstEver=1, ActionTypeID=1, @dateID) |
| [FA Amount Total] | DWH_dbo.Fact_FirstCustomerAction | Amount | SUM(-Amount) for first-ever crypto investors |
| [Opened Positions] | DWH_dbo.Dim_Position | — | COUNT(positions opened on @dateID, non-partial) |
| [Open Positions] | BI_DB_dbo.BI_DB_PositionPnL | — | COUNT(positions at DateID=@dateID) |
| [Acvtive Hold by Inst] | BI_DB_dbo.BI_DB_PositionPnL | CID | COUNT DISTINCT CID per full dimension segment |
| UpdateDate | SP metadata | — | GETDATE() at INSERT time |
| [Acvtive Hold] | BI_DB_dbo.BI_DB_PositionPnL | CID | COUNT DISTINCT CID by DateID only (repeated) |
| [Active Hold Real] | BI_DB_dbo.BI_DB_PositionPnL | CID | COUNT DISTINCT CID WHERE IsSettled=1 (repeated) |
| [Active Hold CFD] | BI_DB_dbo.BI_DB_PositionPnL | CID | COUNT DISTINCT CID WHERE IsSettled≠1 (repeated) |

### 5.2 ETL Pipeline

```
etoro.Trade.Instrument (InstrumentTypeID=10, crypto assets)
  → DWH_dbo.Dim_Instrument (BuyCurrency, SymbolFull, InstrumentDisplayName)

etoro.Customer.Customer + UserApiDB.Customer.CustomerIdentification
  → DWH_dbo.Fact_SnapshotCustomer (population: IsValidCustomer=1, IsDepositor=1, PlayerLevelID≠4)
  → DWH_dbo.Dim_Country, Dim_Regulation (Country/Regulation name lookups)

etoro.Trade.PositionTbl
  → DWH_dbo.Dim_Position (open crypto positions: IsSettled, MirrorID)

BI_DB_dbo.BI_DB_PositionPnL (daily PnL snapshot by DateID)

DWH_dbo.Fact_CustomerAction (commissions + rollover fees, ActionTypeID filters)
DWH_dbo.Fact_FirstCustomerAction (FirstEver=1, crypto FA tracking)
DWH_dbo.Dim_Date (calendar attributes: DayName, SSWeekNumber, etc.)

  |-- SP_CryptoDashboard @date (DELETE WHERE DateID=@dateID + INSERT, daily, SB_Daily, Priority 20) ---|
  v
BI_DB_dbo.BI_DB_Crypto_Dashboard
  (69.3M rows, 2020-01-01 to 2026-04-12, 2,294 dates, ROUND_ROBIN CLUSTERED(DateID))
  |-- UC Target: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Country | DWH_dbo.Dim_Country | Country name lookup via Fact_SnapshotCustomer.CountryID |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name lookup via Fact_SnapshotCustomer.RegulationID |
| BuyCurrency | DWH_dbo.Dim_Instrument | Crypto ticker via InstrumentTypeID=10 filter |
| AUA, Amount in Units, PnL | BI_DB_dbo.BI_DB_PositionPnL | Daily position PnL snapshot source |
| Revenue | DWH_dbo.Fact_CustomerAction | Commission and rollover fee aggregation source |
| # of FA Crypto, FA Amount Total | DWH_dbo.Fact_FirstCustomerAction | First-ever crypto investor tracking |
| Opened Positions | DWH_dbo.Dim_Position | Position open count on @dateID |
| Date fields | DWH_dbo.Dim_Date | Calendar attribute denormalization |

### 6.2 Referenced By (other objects point to this)

No known downstream BI_DB_dbo tables consume BI_DB_Crypto_Dashboard directly. Table is consumed directly by Power BI reports and analytical dashboards for the crypto business line.

---

## 7. Sample Queries

### Daily Crypto AUA and Revenue by Asset on Latest Date

```sql
SELECT
    BuyCurrency,
    [Real/CFD],
    SUM(AUA) AS TotalAUA,
    SUM(PnL) AS TotalPnL,
    SUM(Revenue) AS TotalRevenue,
    SUM([Open Positions]) AS OpenPositions
FROM [BI_DB_dbo].[BI_DB_Crypto_Dashboard]
WHERE DateID = 20260412
GROUP BY BuyCurrency, [Real/CFD]
ORDER BY TotalAUA DESC;
```

### Weekly Crypto Revenue Trend by Regulation (2026)

```sql
SELECT
    YearWeek,
    Regulation,
    SUM(Revenue) AS WeeklyRevenue,
    SUM([# of FA Crypto]) AS NewCryptoInvestors,
    SUM([FA Amount Total]) AS FAInvestedAmount
FROM [BI_DB_dbo].[BI_DB_Crypto_Dashboard]
WHERE DateID BETWEEN 20260101 AND 20260412
GROUP BY YearWeek, Regulation
ORDER BY YearWeek DESC, WeeklyRevenue DESC;
```

### Total Active Crypto Holders per Date (Avoid Double-Counting)

```sql
SELECT DISTINCT
    DateID,
    Date,
    [Acvtive Hold] AS TotalCryptoHolders,
    [Active Hold Real] AS RealCryptoHolders,
    [Active Hold CFD] AS CFDCryptoHolders
FROM [BI_DB_dbo].[BI_DB_Crypto_Dashboard]
WHERE DateID BETWEEN 20260301 AND 20260412
ORDER BY DateID DESC;
-- Note: DISTINCT required — [Acvtive Hold] is repeated for every segment row per DateID
```

---

## 8. Atlassian Knowledge Sources

No Atlassian (Confluence/Jira) sources searched in this batch. The table's purpose and business logic are fully defined by the SP_CryptoDashboard code — a crypto trading analytics aggregation table created in 2021 by Dan Iliescu for Business Intelligence crypto dashboards.

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 1 T1, 21 T2, 4 T3, 0 T4 | Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 9.0/10*
*Object: BI_DB_dbo.BI_DB_Crypto_Dashboard | Type: Table | Production Source: BI_DB_PositionPnL + Dim_Position + Fact_CustomerAction + Fact_SnapshotCustomer + Dim_Instrument (InstrumentTypeID=10)*
