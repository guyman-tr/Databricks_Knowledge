# BI_DB_dbo.BI_DB_Reg_UK_Compliance_Professional_OptUp

> Weekly professional investor opt-up eligibility report for CySEC and FCA regulated depositors in Gold/Platinum/Platinum Plus/Diamond clubs — 908,698 rows (400,591 distinct customers, avg 2.27 rows per customer) as of 2026-04-07, refreshed every Tuesday. Each row is one CID × Holding type combination with 12-month position activity (opened/closed count, net profit, average notional), current MTM equity, last position dates by asset class, verification status, and club/desk/manager context. Created under DSR-1848 for the UK compliance team. Writer: `SP_W_Tue_Reg_UK_Compliance_Professional_OptUp`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + BI_DB_CIDFirstDates + Dim_Position + BI_DB_PositionPnL (via SP_W_Tue_Reg_UK_Compliance_Professional_OptUp) |
| **Refresh** | Weekly — every Tuesday (SB_Daily, TRUNCATE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Reg_UK_Compliance_Professional_OptUp` is a weekly snapshot supporting the UK compliance team's professional investor opt-up workflow. It surfaces CySEC and FCA regulated Gold+ club customers alongside their 12-month trading activity, equity, and verification status — the data points used to assess whether a retail customer qualifies to opt up to Professional investor status under MiFID II (requiring demonstrated trading frequency, portfolio size, and financial sector experience).

The table contains **908,698 rows** as of 2026-04-07 covering **400,591 distinct customers** (CySEC: 262,151; FCA: 138,440). Each customer appears in **multiple rows** — one row per Holding type (up to 9 values: Real Stocks, Real Crypto, Real ETF, CFD Stocks, CFD Crypto Currencies, CFD Indices, CFD ETF, CFD Commodities, CFD Currencies). Customers with no positions in the past 12 months appear once with Holding = NULL.

The SP builds five temp tables: #Clients (eligibility), #Positions (12-month activity by CID × Holding), #Tests (verification/date data from CIDFirstDates), #Equity (yesterday's MTM by CID × Holding from BI_DB_PositionPnL), and #LastPos (last position open dates per asset class). These are LEFT JOINed onto #Clients — a customer in #Clients without a matching #Positions row gets NULL for all position-derived columns.

The TRUNCATE + INSERT pattern means this table always reflects the **current week's snapshot**.

---

## 2. Business Logic

### 2.1 Eligibility Filter (High-Value Compliant Depositors)

**What**: Same population filter as the KYC weekly export — CySEC/FCA regulated, active depositors, Gold+ club tier.
**Columns Involved**: Regulation, Club
**Rules**:
- DesignatedRegulationID IN (1=CySEC, 2=FCA)
- IsValidCustomer = 1
- IsDepositor = 1
- Club IN ('Gold', 'Platinum', 'Platinum Plus', 'Diamond') — Gold tier added 2022-04-07 per Bradley's request

### 2.2 Holding Type Derivation (CID × Asset Class Segmentation)

**What**: Position activity is broken down by the combination of settlement type (real vs. CFD) and instrument type. Each customer appears once per Holding type they traded in the past 12 months.
**Columns Involved**: Holding
**Rules**:
- Holding is derived from CASE WHEN `dp.IsSettled` × `di.InstrumentType`:
  - IsSettled=1 + Stocks → 'Real Stocks'
  - IsSettled=1 + Crypto Currencies → 'Real Crypto'
  - IsSettled=1 + ETF → 'Real ETF'
  - IsSettled=0 + Stocks → 'CFD Stocks'
  - IsSettled=0 + Crypto Currencies → 'CFD Crypto Currencies'
  - IsSettled=0 + Indices → 'CFD Indices'
  - IsSettled=0 + ETF → 'CFD ETF'
  - IsSettled=0 + Commodities → 'CFD Commodities'
  - IsSettled=0 + Currencies → 'CFD Currencies'
- NULL = customer is in #Clients but has no positions in #Positions (no activity in last 12 months, or all positions are copy positions)
- MirrorID ≠ 0 positions (copy positions) are excluded from Holding computation

### 2.3 Position Activity Metrics (Last 12 Months, Non-Copy)

**What**: OpenedPositions, ClosedPositions, NetProfit, and AVGNotionalAmount cover solo (non-copy) trading activity in the past 12 months.
**Columns Involved**: OpenedPositions, ClosedPositions, NetProfit, AVGNotionalAmount
**Rules**:
- @1yearagoid = YYYYMMDD int of 1 year ago from run date
- OpenedPositions: COUNT(DISTINCT PositionID) WHERE OpenDateID >= @1yearagoid AND MirrorID=0
- ClosedPositions: COUNT(DISTINCT PositionID) WHERE CloseDateID >= @1yearagoid AND MirrorID=0
- NetProfit: SUM(dp.NetProfit) from closed positions leg only (opened positions contribute 0)
- AVGNotionalAmount: SUM(Amount * Leverage) / SUM(TotalPositions) across UNION ALL of opened + closed legs — the denominator counts each position in each leg it appears in

### 2.4 MTM Equity Snapshot (Yesterday)

**What**: MTMEquity captures the mark-to-market equity for currently open positions as of yesterday, per CID × Holding type.
**Columns Involved**: MTMEquity
**Rules**:
- Source: `BI_DB_PositionPnL` WHERE DateID = @PnLDate (yesterday's YYYYMMDD) AND MirrorID=0
- Computed as: ISNULL(SUM(PositionPnL + Amount), 0)
- Grouped by CID × Holding (same CASE expression as #Positions)
- If a customer has no open positions yesterday, they get no row in #Equity → MTMEquity = NULL in the final table (LEFT JOIN)

### 2.5 Last Position Open Dates by Asset Class

**What**: Three separate columns capture when the customer last opened a solo position, broken out by CFD vs. real crypto vs. real stock.
**Columns Involved**: LastPositionOpenDateCFD, LastPositionOpenDateRealCrypto, LastPositionOpenDateRealStock
**Rules**:
- All three: non-mirror (MirrorID=0), within last 12 months (OpenDateID >= @1yearagoid)
- LastPositionOpenDateCFD: MAX(CONVERT(date, OpenOccurred)) WHERE IsSettled=0
- LastPositionOpenDateRealCrypto: MAX(CONVERT(date, OpenOccurred)) WHERE IsSettled=1 AND InstrumentType='Crypto Currencies'
- LastPositionOpenDateRealStock: MAX(CONVERT(date, OpenOccurred)) WHERE IsSettled=1 AND InstrumentType='Stocks'
- Note: there is no LastPositionOpenDateRealETF — ETF positions are captured in OpenedPositions but not separately tracked

### 2.6 ApproprietnessTest — Placeholder Column

**What**: `ApproprietnessTest` (note spelling — should be "Appropriateness") is always an empty string.
**Columns Involved**: ApproprietnessTest
**Rules**:
- SP inserts `'' AS ApproprietnessTest` — hardcoded empty string constant
- Column is NOT NULL varchar(1) in DDL; always contains ''
- Likely a reserved placeholder for a future appropriateness test result that was never implemented

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Aspect | Detail |
|--------|--------|
| **Distribution** | ROUND_ROBIN — no skew concern. |
| **Clustered Index** | HEAP — full scan for any query. 908K rows; apply CID or Regulation filter. |
| **Multi-row per CID** | Always GROUP BY or aggregate when working at customer level, not Holding level. |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| FCA customers with 12m closed CFD positions for professional opt-up | `WHERE Regulation = 'FCA' AND Holding LIKE 'CFD%' AND ClosedPositions > 0` |
| High-notional FCA customers never having traded recently | `WHERE Regulation = 'FCA' AND LastPositionOpenDateCFD IS NULL` |
| Customer-level summary (collapse Holding rows) | `GROUP BY CID` with `SUM(OpenedPositions), SUM(ClosedPositions), SUM(NetProfit)` |
| Customers verified to level 3 | `WHERE VerificationLevel3Date IS NOT NULL` |
| Elective Professional customers | `WHERE MifidCategorisation = 'Elective Professional'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Regulation | Regulation = Name | (already resolved; join only needed for regulation metadata) |
| BI_DB_dbo.BI_DB_CIDFirstDates | CID = CID | Additional customer attributes (email, registration date, etc.) |

### 3.4 Gotchas

- **Multiple rows per CID**: GROUP BY or aggregate when analysis is at customer level.
- **ApproprietnessTest is always ''**: Do not filter or derive meaning from this column.
- **ClosedPositions includes all close events in 12m**: A position opened 18 months ago that closed last week is counted in ClosedPositions (CloseDateID >= @1yearagoid) but NOT in OpenedPositions (OpenDateID < @1yearagoid).
- **NetProfit is from closed positions only**: NetProfit in #Positions is set to 0 for the opened-positions leg and SUM(NetProfit) for the closed leg — it reflects realized P&L on positions closed in the last 12 months, not unrealized.
- **MTMEquity NULL vs 0**: ISNULL in the equity formula means NULL MTMEquity indicates no row in #Equity (no open positions yesterday), not zero equity. Zero would be an actual zero-equity open position.
- **12-month window shifts weekly**: The @1yearagoid variable is recalculated at SP runtime each Tuesday, so OpenedPositions/ClosedPositions will change even without new trading activity as old positions age out of the window.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki or DWH_dbo wiki (exact copy, no paraphrase) |
| Tier 2 | Derived from SP code and writer stored procedure analysis |
| Tier 3 | ETL metadata or system-generated columns confirmed from SP |
| Tier 4 | Inferred from context, sample data, or naming convention |
| Tier 5 | Expert review required — uncertain semantics |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Regulation | varchar(50) | YES | Customer's designated regulation name. Resolved from DWH_dbo.Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID. Values: CySEC (619,412 rows), FCA (289,286 rows). (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_Regulation) |
| 2 | CID | int | NO | Customer ID — platform-internal primary key. Passthrough from Dim_Customer.RealCID. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_Customer) |
| 3 | VerificationLevel3Date | date | YES | First date customer reached verification level 3 (fully verified). CONVERT(date, BI_DB_CIDFirstDates.VerificationLevel3Date). Source in CIDFirstDates: MIN(FromDateID) WHERE VerificationLevelID=3 via Fact_SnapshotCustomer. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 4 | CashCredit | money | YES | Customer credit balance as of yesterday's snapshot. Passthrough from BI_DB_CIDFirstDates.Credit (column renamed Credit→CashCredit). Source in CIDFirstDates: V_Liabilities.Credit, only updated when @date=@yesterday. (Tier 2 — SP_CIDFirstDates, V_Liabilities) |
| 5 | ApproprietnessTest | varchar(1) | NO | Appropriateness test result. ALWAYS empty string '' — hardcoded constant in SP (`'' AS ApproprietnessTest`). Placeholder column, never populated. Note: column name has spelling error (should be "AppropriatenessTest"). (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp) |
| 6 | FirstPosOpenDate | date | YES | First position open date (manual or copy). CONVERT(date, BI_DB_CIDFirstDates.FirstPosOpenDate). Source in CIDFirstDates: MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 7 | LastPosOpenDate | date | YES | Last position open date (manual or copy). CONVERT(date, BI_DB_CIDFirstDates.LastPosOpenDate). Source in CIDFirstDates: MAX(Occurred) WHERE ActionTypeID IN (1,2). (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 8 | LastPositionOpenDateCFD | date | YES | Most recent CFD (leveraged) position open date within the last 12 months (non-copy only). MAX(CONVERT(date, OpenOccurred)) WHERE IsSettled=0 AND MirrorID=0 AND OpenDateID >= @1yearagoid. NULL if no CFD positions opened in 12 months. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_Position) |
| 9 | LastPositionOpenDateRealCrypto | date | YES | Most recent real (settled) crypto position open date within the last 12 months (non-copy). MAX(CONVERT(date, OpenOccurred)) WHERE IsSettled=1 AND InstrumentType='Crypto Currencies' AND MirrorID=0 AND OpenDateID >= @1yearagoid. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_Position + Dim_Instrument) |
| 10 | LastPositionOpenDateRealStock | date | YES | Most recent real (settled) stocks position open date within the last 12 months (non-copy). MAX(CONVERT(date, OpenOccurred)) WHERE IsSettled=1 AND InstrumentType='Stocks' AND MirrorID=0 AND OpenDateID >= @1yearagoid. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_Position + Dim_Instrument) |
| 11 | Club | varchar(500) | YES | Customer experience tier name. Passthrough from BI_DB_CIDFirstDates.Club. Source in CIDFirstDates: Dim_PlayerLevel.Name via PlayerLevelID. Values in this table: Gold, Platinum, Platinum Plus, Diamond (eligibility filter). (Tier 2 — SP_CIDFirstDates, Dim_PlayerLevel) |
| 12 | Holding | varchar(21) | YES | Asset class and settlement type combination for this row's position metrics. Derived from CASE WHEN dp.IsSettled × di.InstrumentType. Values: 'Real Stocks' (242K rows), 'Real Crypto' (219K), 'CFD ETF' (79K), 'CFD Stocks' (78K), 'CFD Commodities' (77K), 'Real ETF' (46K), 'CFD Indices' (41K), 'CFD Crypto Currencies' (39K), 'CFD Currencies' (17K), NULL (70K, no positions). (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp) |
| 13 | OpenedPositions | int | YES | Count of distinct solo positions opened in the last 12 months. COUNT(DISTINCT PositionID) WHERE OpenDateID >= @1yearagoid AND MirrorID=0, per CID × Holding. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_Position) |
| 14 | ClosedPositions | int | YES | Count of distinct solo positions closed in the last 12 months. COUNT(DISTINCT PositionID) WHERE CloseDateID >= @1yearagoid AND MirrorID=0, per CID × Holding. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_Position) |
| 15 | NetProfit | money | YES | Realized net profit on positions closed in the last 12 months (non-copy). SUM(dp.NetProfit) from the closed-positions UNION leg only; opened-positions leg contributes 0. Per CID × Holding. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_Position) |
| 16 | AVGNotionalAmount | money | YES | Average full notional value per position (opened + closed combined, last 12 months, non-copy). SUM(Amount × Leverage) / SUM(TotalPositions) across UNION ALL of opened and closed legs, per CID × Holding. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_Position) |
| 17 | MTMEquity | decimal(38,4) | YES | Mark-to-market equity of open positions as of yesterday. ISNULL(SUM(PositionPnL + Amount), 0) from BI_DB_PositionPnL WHERE DateID = @PnLDate (yesterday's YYYYMMDD) AND MirrorID=0, per CID × Holding. NULL when customer has no open positions yesterday (LEFT JOIN miss). (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, BI_DB_PositionPnL) |
| 18 | Desk | nvarchar(50) | YES | Sales desk assignment. From DWH_dbo.Dim_Country.Desk via Dim_Customer.CountryID. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_Country) |
| 19 | Manager | nvarchar(500) | YES | Account manager full name. Passthrough from BI_DB_CIDFirstDates.Manager. Source in CIDFirstDates: FirstName+' '+LastName from Dim_Manager via AccountManagerID. (Tier 2 — SP_CIDFirstDates, Dim_Manager) |
| 20 | MifidCategorisation | varchar(50) | NO | MiFID II investor categorisation. Resolved from DWH_dbo.Dim_MifidCategorization.Name via Dim_Customer.MifidCategorizationID. Values: Retail Pending, Retail, Pending, Elective Professional, Professional, None. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_MifidCategorization) |
| 21 | CountryOfResidence | varchar(50) | NO | Customer country of residence name. From DWH_dbo.Dim_Country.Name via Dim_Customer.CountryID. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp, Dim_Country) |
| 22 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the SP (GETDATE() at insert time). (Tier 3 — SP_W_Tue_Reg_UK_Compliance_Professional_OptUp) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Regulation | DWH_dbo.Dim_Regulation | Name | Via Dim_Customer.DesignatedRegulationID |
| CID | DWH_dbo.Dim_Customer | RealCID | Passthrough |
| VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date | CONVERT(date, …) |
| CashCredit | BI_DB_dbo.BI_DB_CIDFirstDates | Credit | Passthrough (renamed) |
| ApproprietnessTest | — | — | Hardcoded '' |
| FirstPosOpenDate | BI_DB_dbo.BI_DB_CIDFirstDates | FirstPosOpenDate | CONVERT(date, …) |
| LastPosOpenDate | BI_DB_dbo.BI_DB_CIDFirstDates | LastPosOpenDate | CONVERT(date, …) |
| LastPositionOpenDateCFD | DWH_dbo.Dim_Position | OpenOccurred | MAX WHERE IsSettled=0, 12m window |
| LastPositionOpenDateRealCrypto | DWH_dbo.Dim_Position | OpenOccurred | MAX WHERE IsSettled=1, Crypto, 12m window |
| LastPositionOpenDateRealStock | DWH_dbo.Dim_Position | OpenOccurred | MAX WHERE IsSettled=1, Stocks, 12m window |
| Club | BI_DB_dbo.BI_DB_CIDFirstDates | Club | Passthrough; filtered to Gold+ |
| Holding | DWH_dbo.Dim_Position + Dim_Instrument | IsSettled, InstrumentType | CASE derivation |
| OpenedPositions | DWH_dbo.Dim_Position | PositionID | COUNT DISTINCT WHERE OpenDateID in 12m |
| ClosedPositions | DWH_dbo.Dim_Position | PositionID | COUNT DISTINCT WHERE CloseDateID in 12m |
| NetProfit | DWH_dbo.Dim_Position | NetProfit | SUM from closed leg |
| AVGNotionalAmount | DWH_dbo.Dim_Position | Amount, Leverage | SUM(A×L)/SUM(positions) |
| MTMEquity | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL, Amount | SUM(PnL+Amount) WHERE DateID=yesterday |
| Desk | DWH_dbo.Dim_Country | Desk | Via Dim_Customer.CountryID |
| Manager | BI_DB_dbo.BI_DB_CIDFirstDates | Manager | Passthrough |
| MifidCategorisation | DWH_dbo.Dim_MifidCategorization | Name | Via Dim_Customer.MifidCategorizationID |
| CountryOfResidence | DWH_dbo.Dim_Country | Name | Via Dim_Customer.CountryID |
| UpdateDate | ETL metadata | — | GETDATE() at insert |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (CySEC+FCA, IsValidCustomer=1, IsDepositor=1)
  + DWH_dbo.Dim_Regulation, Dim_MifidCategorization, Dim_Country
  + BI_DB_dbo.BI_DB_CIDFirstDates (Club IN Gold/Platinum/PlatPlus/Diamond → eligibility gate)
    → #Clients (400,591 CIDs)
DWH_dbo.Dim_Position + Dim_Instrument (non-mirror, OpenDateID >= @1yearagoid)
  UNION ALL
DWH_dbo.Dim_Position + Dim_Instrument (non-mirror, CloseDateID >= @1yearagoid)
    → #Positions (OpenedPositions, ClosedPositions, NetProfit, AVGNotionalAmount per CID×Holding)
BI_DB_dbo.BI_DB_CIDFirstDates (VerificationLevel3Date, FirstPosOpenDate, LastPosOpenDate, Credit)
    → #Tests
BI_DB_dbo.BI_DB_PositionPnL (DateID=yesterday, MirrorID=0)
  + DWH_dbo.Dim_Instrument
    → #Equity (MTMEquity per CID×Holding)
DWH_dbo.Dim_Position + Dim_Instrument (non-mirror, OpenDateID >= @1yearagoid)
    → #LastPos (LastPositionOpenDateCFD, LastPositionOpenDateRealCrypto, LastPositionOpenDateRealStock)
    |-- SP_W_Tue_Reg_UK_Compliance_Professional_OptUp (Weekly/Tuesday, Priority 21, SB_Daily) ---|
    v                                                                       [TRUNCATE + INSERT]
BI_DB_dbo.BI_DB_Reg_UK_Compliance_Professional_OptUp
  (908,698 rows | 400,591 CIDs | 2026-04-07 | ROUND_ROBIN HEAP)
    |-- UC: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Regulation | DWH_dbo.Dim_Regulation | Sourced at write time |
| Club, Manager, dates, CashCredit | BI_DB_dbo.BI_DB_CIDFirstDates | Passthrough columns |
| MTMEquity | BI_DB_dbo.BI_DB_PositionPnL | Yesterday's open P&L snapshot |
| CountryOfResidence, Desk | DWH_dbo.Dim_Country | Sourced at write time |
| MifidCategorisation | DWH_dbo.Dim_MifidCategorization | Sourced at write time |

### 6.2 Referenced By (other objects point to this)

No downstream objects identified in `opsdb-procedure-dependencies.json` that read this table. Consumed directly by the UK compliance team for professional opt-up review.

---

## 7. Sample Queries

### FCA Customers with Significant CFD Activity (Professional Opt-Up Candidates)

```sql
SELECT 
    CID,
    Club,
    Manager,
    CountryOfResidence,
    MifidCategorisation,
    SUM(OpenedPositions)    AS total_opened_12m,
    SUM(ClosedPositions)    AS total_closed_12m,
    SUM(NetProfit)          AS total_net_profit,
    SUM(MTMEquity)          AS total_mtm_equity
FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_Professional_OptUp]
WHERE Regulation = 'FCA'
  AND MifidCategorisation = 'Retail'
GROUP BY CID, Club, Manager, CountryOfResidence, MifidCategorisation
HAVING SUM(OpenedPositions) + SUM(ClosedPositions) >= 10
ORDER BY total_mtm_equity DESC
```

### Activity by Holding Type (FCA Only)

```sql
SELECT 
    Holding,
    COUNT(DISTINCT CID)    AS customer_count,
    SUM(OpenedPositions)   AS total_opened,
    SUM(ClosedPositions)   AS total_closed,
    SUM(NetProfit)         AS total_net_profit,
    AVG(AVGNotionalAmount) AS avg_notional
FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_Professional_OptUp]
WHERE Regulation = 'FCA'
  AND Holding IS NOT NULL
GROUP BY Holding
ORDER BY customer_count DESC
```

### Customers with No Recent CFD Activity

```sql
SELECT 
    CID,
    Regulation,
    Club,
    Manager,
    VerificationLevel3Date,
    LastPositionOpenDateCFD
FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_Professional_OptUp]
WHERE LastPositionOpenDateCFD IS NULL
  AND Holding IS NULL
  AND Regulation = 'FCA'
ORDER BY Club DESC
```

---

## 8. Atlassian Knowledge Sources

Jira ticket: **DSR-1848** — created this table (March 2022, Nir Weber). Requested by UK compliance team members Edward Drake and Bradley Roberts to automate weekly professional opt-up eligibility review. Gold club tier was added 2022-04-07 following a request from Bradley Roberts. Migrated to Synapse by Slavane in June 2023. Same DSR as the other three UK Compliance tables in this batch.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 14/14 | P16: PASS*
*Tiers: 0 T1, 21 T2, 1 T3, 0 T4, 0 T5 | Elements: 22/22, Logic: 9/10, ETL: confirmed*
*Object: BI_DB_dbo.BI_DB_Reg_UK_Compliance_Professional_OptUp | Type: Table | Production Source: Dim_Position + CIDFirstDates + BI_DB_PositionPnL via SP_W_Tue_Reg_UK_Compliance_Professional_OptUp*
