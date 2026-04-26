# BI_DB_dbo.BI_DB_DDR_CID_Level_Auxiliary_Metrics

> 23-column daily CID-level auxiliary reporting table that supplements `BI_DB_DDR_CID_Level` with fee-specific metrics that cannot be added to the main DDR without a full rerun. One row per fee-incurring customer per day — only customers with DormantFee, ConversionFees, InterestFees, SDRT, TradingFees, or TicketFees activity appear. 492M rows total; ~5.23M distinct CIDs; DateID range 20201227–20260412. Written by SP_DDR_Auxiliary_Metrics.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction + Fact_SnapshotCustomer + Fact_FirstCustomerAction + Dim_Customer + BI_DB_DepositWithdrawFee + BI_DB_Daily_CreditLine via SP_DDR_Auxiliary_Metrics |
| **Refresh** | Daily (SB_Daily); DELETE+INSERT per DateID — idempotent rerun |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC, CID ASC) |
| **UC Target** | Not migrated — no Generic Pipeline mapping entry |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_DDR_CID_Level_Auxiliary_Metrics` is a daily supplementary fact table that extends the main DDR (`BI_DB_DDR_CID_Level`) with six additional fee-type metrics that were added after the DDR was initially built. Rather than rerunning the heavyweight SP_DDR, these metrics are computed by the lighter `SP_DDR_Auxiliary_Metrics` and stored separately for downstream JOIN.

Each row represents one customer (`CID`) on one day (`DateID`) where the customer incurred at least one of:
- **DormantFee** — maintenance fee charged to inactive accounts (ActionTypeID=36, CompensationReasonID=30)
- **ConversionFees** — currency conversion fees on deposits/withdrawals (from BI_DB_DepositWithdrawFee.PIPsCalculation)
- **InterestFees** — daily credit line interest (from BI_DB_Daily_CreditLine.DailyFee)
- **SDRT** — Stamp Duty Reserve Tax, a UK regulatory tax on stock purchases (ActionTypeID=35, IsFeeDividend=3)
- **TradingFees** — ticket fees on stock trades + Islamic account fees (ActionTypeID=35 IsFeeDividend=4 OR ActionTypeID=36 CompensationReasonID IN (117,118))
- **TicketFees** — per-trade ticket fee only, a subset of TradingFees excluding the Islamic fee component

The table repeats most of the customer attribute columns from `BI_DB_DDR_CID_Level` (Regulation, Country, Label, etc.) to enable grouping and filtering without requiring a JOIN to the main DDR. These shared attribute columns are sourced fresh from Fact_SnapshotCustomer — not read from the main DDR table.

**Important**: This table also shares the same SP run with `BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics`. SP_DDR_Auxiliary_Metrics writes both tables in a single execution: the CID-level table from `#CIDAgg` and the daily aggregated table from `#RegAgg` (a GROUP BY of the same #CIDAgg).

**CID universe difference from main DDR**: A customer appears in `BI_DB_DDR_CID_Level` if they had any action or client balance on @date. They appear in `BI_DB_DDR_CID_Level_Auxiliary_Metrics` ONLY if they incurred one of the six specific fee types. Customers with no fee activity on a given day do not appear — this table is not a full customer universe.

---

## 2. Business Logic

### 2.1 DormantFee Sign Inversion

**What**: Dormant fee is stored as a positive amount in this table even though it is recorded as a negative action in Fact_CustomerAction.

**Rules**:
- Source: `SUM(-fca.Amount)` WHERE ActionTypeID=36 AND CompensationReasonID=30
- The SP negates the sign because Fact_CustomerAction records fee charges as negative amounts
- Result: DormantFee in this table is positive = the fee amount charged to the customer

### 2.2 SDRT (Stamp Duty Reserve Tax)

**What**: UK regulatory tax charged on purchases of UK stocks. Computed from a specific fee action type.

**Rules**:
- `SUM(Amount)` WHERE ActionTypeID=35 AND IsFeeDividend=3
- Only applies to UK-listed stock purchases by customers subject to UK regulations

### 2.3 TradingFees vs TicketFees

**What**: Two overlapping fee columns for stock trading costs.

**Rules**:
- `TradingFees` = SUM(Amount) WHERE (ActionTypeID=35 AND IsFeeDividend=4) OR (ActionTypeID=36 AND CompensationReasonID IN (117,118))
  - IsFeeDividend=4 component = TicketFees (per-trade ticket charge)
  - CompensationReasonID 117/118 component = Islamic account trading fees
- `TicketFees` = SUM(Amount) WHERE ActionTypeID=35 AND IsFeeDividend=4 ONLY
- Therefore: `TradingFees ≥ TicketFees` always. The difference (TradingFees - TicketFees) is the Islamic fees component.

### 2.4 ConversionFees Source

**What**: Currency conversion fees from a separate BI_DB table, not from Fact_CustomerAction.

**Rules**:
- Source: `BI_DB_DepositWithdrawFee.PIPsCalculation` WHERE Date = @date (Date is the indexed field)
- Groups by CID and DateID
- This is the only column sourced from BI_DB_DepositWithdrawFee

### 2.5 WalletBalanceUSD — Always NULL

**What**: Column exists in the DDL but is always NULL in production.

**Rules**:
- SP_DDR_Auxiliary_Metrics hardcodes `NULL AS WalletBalanceUSD` in all SELECT statements
- The wallet balance data source was planned but the implementation was commented out
- Do not use this column for any analysis

### 2.6 FirstActionType Classification

**What**: Customer lifetime first action type — same logic as in SP_DDR.

**Rules**:
- 'Forex' = ActionTypeID IN (1,39) AND InstrumentTypeID IN (1,2,4)
- 'Stocks' = ActionTypeID IN (1,39) AND InstrumentTypeID IN (5,6)
- 'Crypto' = ActionTypeID IN (1,39) AND InstrumentTypeID=10
- 'CopyFund' = ActionTypeID=17 AND first copy is a Copy Fund (MirrorTypeID=4)
- 'Copy' = ActionTypeID=17 AND not a Copy Fund
- 'NoAction' = no qualifying first action found (default via UPDATE after CTE)

### 2.7 ETL Idempotency

**What**: Daily refresh is safe to rerun.

**Rules**:
- `DELETE FROM BI_DB_DDR_CID_Level_Auxiliary_Metrics WHERE DateID = @dateID` before INSERT
- Same pattern applied to `BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics` in the same SP run

---

## 3. Query Advisory

### 3.1 Distribution & Index

- **HASH(CID)**: Co-located joins with `BI_DB_DDR_CID_Level` (also HASH(CID)) are efficient — no data movement on CID JOIN.
- **CLUSTERED INDEX (DateID, CID)**: Filter by DateID first for range scans; add CID for point lookups.
- **Sparse population**: This table has ~492M rows vs ~10.6B in the main DDR — it is populated only for fee-incurring customers. Do not expect a 1:1 match with DDR_CID_Level rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily dormant fee revenue | `WHERE DateID = X GROUP BY Regulation — SUM(DormantFee)` |
| SDRT by country | `WHERE DateID BETWEEN X AND Y GROUP BY Country — SUM(SDRT)` |
| Trading fees trend | `WHERE DateID BETWEEN X AND Y GROUP BY DateID — SUM(TradingFees)` |
| Customers with conversion fees | `WHERE DateID = X AND ConversionFees > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_DDR_CID_Level | CID = CID AND DateID = DateID | Merge auxiliary fees into main DDR row |
| DWH_dbo.Dim_Date | DateID = DateKey | Resolve DateID to calendar attributes |

### 3.4 Gotchas

- **WalletBalanceUSD is always NULL**: Do not include in any metric computation.
- **TradingFees includes Islamic fees**: If you need pure ticket fees only, use `TicketFees`. If you need total trading cost including Islamic fees, use `TradingFees`.
- **DormantFee is positive**: Unlike other compensation/fee types that may appear negative, DormantFee has been sign-inverted in the SP to appear as a positive value.
- **Sparse table**: Most customers will NOT appear on any given day. This is expected — it is a fee-events table, not a full customer snapshot.
- **Duplicate CIDs possible in theory**: If a CID appears in multiple fee source tables for the same day, it gets one aggregated row in #CIDAgg (via LEFT JOIN pattern). There should be one row per CID per DateID.
- **DateID is bigint**: Unlike the main DDR where DateID is int, here it is bigint. Account for this in type comparisons.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (canonical source) |
| Tier 2 | Derived from ETL SP code analysis (SP_DDR_Auxiliary_Metrics logic) |
| Tier 3 | Inferred from column name, type, and context |
| Tier 4 | Best-guess — limited evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | bigint | YES | Customer identifier. Sourced from UNION of distinct CIDs across all fee sub-queries (#fca, #conversionFees, #IneterstFees, #SDRT, #TradingFees, #TicketFees). Only appears if customer incurred ≥1 fee type on @date. (Tier 2 — SP_DDR_Auxiliary_Metrics #allUsers) |
| 2 | DateID | bigint | YES | YYYYMMDD integer representing the data date. Note: bigint type (vs int in the main DDR). (Tier 2 — SP_DDR_Auxiliary_Metrics) |
| 3 | Regulation | varchar(100) | YES | Regulatory regime name (e.g., 'ASIC', 'FCA', 'CySEC'). Resolved from Fact_SnapshotCustomer.RegulationID via Dim_Regulation for @dateID. (Tier 2 — SP_DDR_Auxiliary_Metrics #fsc) |
| 4 | IsBlocked | int | YES | 1 if the customer's account is in a blocked state, else 0. CASE WHEN PlayerStatusID NOT IN (1,3,5,7) THEN 1 ELSE 0. (Tier 2 — SP_DDR_Auxiliary_Metrics) |
| 5 | IsCreditReportValidCB | int | YES | Flag indicating whether the customer's credit report is valid in the CB system. Passthrough from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Auxiliary_Metrics #fsc) |
| 6 | IsGermanBaFin | int | YES | 1 if the customer falls under German BaFin regulatory reporting scope. LEFT JOIN on V_GermanBaFin for @dateID. (Tier 2 — SP_DDR_Auxiliary_Metrics) |
| 7 | IsValidCustomer | int | YES | 1 if the customer is considered valid per DWH criteria. Passthrough from Fact_SnapshotCustomer.IsValidCustomer. (Tier 2 — SP_DDR_Auxiliary_Metrics #fsc) |
| 8 | MifidCategory | varchar(100) | YES | MiFID II customer category (e.g., 'Retail', 'Professional'). Resolved via Dim_MifidCategorization from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Auxiliary_Metrics #fsc) |
| 9 | PlayerLevel | varchar(100) | YES | Customer experience level. Resolved via Dim_PlayerLevel from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Auxiliary_Metrics #fsc) |
| 10 | PlayerStatus | varchar(100) | YES | Customer account status name. Resolved via Dim_PlayerStatus from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Auxiliary_Metrics #fsc) |
| 11 | FirstActionType | varchar(100) | YES | Customer's lifetime first action classification: 'Forex', 'Stocks', 'Crypto', 'Copy', 'CopyFund', or 'NoAction'. Computed from Fact_FirstCustomerAction + Dim_Position + Dim_Instrument + Dim_Mirror. (Tier 2 — SP_DDR_Auxiliary_Metrics #FirstActionsFinal) |
| 12 | Region | varchar(100) | YES | Geographic region name (e.g., 'Europe', 'Asia Pacific'). From Dim_Country.MarketingRegionManualName via Fact_SnapshotCustomer join. (Tier 2 — SP_DDR_Auxiliary_Metrics #fsc) |
| 13 | Country | varchar(100) | YES | Customer's registered country name. Resolved via Dim_Country from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Auxiliary_Metrics #fsc) |
| 14 | Label | varchar(100) | YES | Customer label/tier name. Resolved via Dim_Label from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Auxiliary_Metrics #fsc) |
| 15 | FTDCurrentYear | int | YES | 1 if the customer's first time deposit (FTD) occurred in the same calendar year as @date, else 0. CASE WHEN Dim_Customer.FirstDepositDate >= start-of-year. (Tier 2 — SP_DDR_Auxiliary_Metrics) |
| 16 | DormantFee | money | YES | Dormant account maintenance fee charged on @date. SUM(-Amount) WHERE ActionTypeID=36 AND CompensationReasonID=30. Sign negated — stored as positive amount despite being a negative action in Fact_CustomerAction. (Tier 2 — SP_DDR_Auxiliary_Metrics #fcaprep) |
| 17 | ConversionFees | money | YES | Currency conversion fees on deposits/withdrawals on @date. SUM(PIPsCalculation) from BI_DB_DepositWithdrawFee WHERE Date = @date. (Tier 2 — SP_DDR_Auxiliary_Metrics #conversionFees) |
| 18 | WalletBalanceUSD | money | YES | Always NULL. Wallet balance feature was planned but commented out in SP_DDR_Auxiliary_Metrics. Do not use. (Tier 2 — SP_DDR_Auxiliary_Metrics hardcoded NULL) |
| 19 | InterestFees | money | YES | Daily credit line interest charged on @date. SUM(DailyFee) from BI_DB_Daily_CreditLine WHERE DateID = @dateID. (Tier 2 — SP_DDR_Auxiliary_Metrics #IneterstFees) |
| 20 | UpdateDate | date | YES | Date (not datetime) when SP_DDR_Auxiliary_Metrics executed the INSERT. GETDATE() cast to date. ETL run timestamp — not a business date. (Tier 2 — SP_DDR_Auxiliary_Metrics) |
| 21 | SDRT | float | YES | Stamp Duty Reserve Tax charged on @date. SUM(Amount) WHERE ActionTypeID=35 AND IsFeeDividend=3. UK regulatory tax on purchases of UK-listed stocks. (Tier 2 — SP_DDR_Auxiliary_Metrics #SDRT_prep) |
| 22 | TradingFees | float | YES | Total trading fees on @date. SUM(Amount) WHERE (ActionTypeID=35 AND IsFeeDividend=4) OR (ActionTypeID=36 AND CompensationReasonID IN (117,118)). Includes TicketFees (per-trade) + Islamic account fees. Always ≥ TicketFees. (Tier 2 — SP_DDR_Auxiliary_Metrics #TradingFees_prep) |
| 23 | TicketFees | money | YES | Per-trade ticket fee on @date. SUM(Amount) WHERE ActionTypeID=35 AND IsFeeDividend=4. Subset of TradingFees — excludes Islamic fees component. (Tier 2 — SP_DDR_Auxiliary_Metrics #TicketFees_prep) |

---

## 5. Lineage

See `BI_DB_DDR_CID_Level_Auxiliary_Metrics.lineage.md` for full column-level source mapping.

### 5.1 Production Sources (Summary)

| Column Group | Primary Source | Transform |
|-------------|----------------|-----------|
| CID, DateID, UpdateDate | SP_DDR_Auxiliary_Metrics parameters + GETDATE() | Computed from @date |
| Regulation, IsBlocked, IsValidCustomer, IsCreditReportValidCB, MifidCategory, PlayerLevel, PlayerStatus, Region, Country, Label | Fact_SnapshotCustomer + Dim tables | Snapshot for @dateID via #fsc |
| IsGermanBaFin | V_GermanBaFin | LEFT JOIN for @dateID |
| FirstActionType | Fact_FirstCustomerAction + Dim_Position + Dim_Instrument + Dim_Mirror | CASE classification via #FirstActionsFinal |
| FTDCurrentYear | Dim_Customer | CASE WHEN FirstDepositDate >= start-of-year |
| DormantFee | Fact_CustomerAction (ActionTypeID=36 CR=30) | SUM(-Amount) |
| ConversionFees | BI_DB_DepositWithdrawFee | SUM(PIPsCalculation) |
| WalletBalanceUSD | — | NULL (hardcoded) |
| InterestFees | BI_DB_Daily_CreditLine | SUM(DailyFee) |
| SDRT | Fact_CustomerAction (ActionTypeID=35 IFD=3) | SUM(Amount) |
| TradingFees | Fact_CustomerAction (ActionTypeID=35 IFD=4 OR ActionTypeID=36 CR=117/118) | SUM(Amount) |
| TicketFees | Fact_CustomerAction (ActionTypeID=35 IFD=4) | SUM(Amount) |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_* ───→ #fsc (customer attributes for @dateID)
DWH_dbo.Fact_CustomerAction (ActionTypeID=36 CR=30) → #fcaprep → #fca (DormantFee)
DWH_dbo.Fact_CustomerAction (ActionTypeID=35 IFD=3) → #SDRT
DWH_dbo.Fact_CustomerAction (35/IFD=4, 36/CR=117-118)→ #TradingFees
DWH_dbo.Fact_CustomerAction (35/IFD=4 only) ────────→ #TicketFees
BI_DB_DepositWithdrawFee ────────────────────────────→ #conversionFees
BI_DB_Daily_CreditLine ──────────────────────────────→ #IneterstFees

UNION of fee CIDs → #allUsers (fee-incurring customers only)

Fact_FirstCustomerAction + Dim_Position + Dim_Instrument + Dim_Mirror
  → #allDepositors → #firstActions → #CF_mirrors → #FirstActionsFinal (FirstActionType)

DWH_dbo.Dim_Customer → FTDCurrentYear

#allUsers LEFT JOIN all temp tables → #CIDAgg

DELETE FROM BI_DB_DDR_CID_Level_Auxiliary_Metrics WHERE DateID = @dateID
INSERT INTO BI_DB_DDR_CID_Level_Auxiliary_Metrics SELECT FROM #CIDAgg  (CID-level)

GROUP BY #CIDAgg → #RegAgg

DELETE FROM BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics WHERE DateID = @dateID
INSERT INTO BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics SELECT FROM #RegAgg  (aggregate)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DateID | DWH_dbo.Dim_Date.DateKey | Date dimension lookup |
| CID | DWH_dbo.Dim_Customer.CID | Customer master |

### 6.2 Referenced By (other objects point to this)

| Object | Reference Type | Description |
|--------|---------------|-------------|
| BI_DB_dbo.BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics | Source (same SP run, #RegAgg) | Daily aggregated view of auxiliary metrics |

---

## 7. Sample Queries

### Daily dormant fee revenue by regulation

```sql
SELECT DateID, Regulation, SUM(DormantFee) AS TotalDormantFee, COUNT(*) AS AffectedCustomers
FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level_Auxiliary_Metrics]
WHERE DateID BETWEEN 20260101 AND 20260331
GROUP BY DateID, Regulation
ORDER BY DateID, TotalDormantFee DESC
```

### SDRT by country for UK customers

```sql
SELECT DateID, Country, SUM(SDRT) AS TotalSDRT
FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level_Auxiliary_Metrics]
WHERE DateID BETWEEN 20260101 AND 20260331
  AND SDRT IS NOT NULL
GROUP BY DateID, Country
ORDER BY DateID
```

### Ticket vs Islamic fee breakdown for trading fees

```sql
SELECT
    DateID,
    SUM(TicketFees)              AS TotalTicketFees,
    SUM(TradingFees)             AS TotalTradingFees,
    SUM(TradingFees - ISNULL(TicketFees, 0)) AS IslamicFees
FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level_Auxiliary_Metrics]
WHERE DateID = 20260410
GROUP BY DateID
```

### Join auxiliary to main DDR for comprehensive revenue

```sql
SELECT
    d.CID,
    d.DateID,
    d.Revenue,
    ISNULL(a.DormantFee, 0)      AS DormantFee,
    ISNULL(a.ConversionFees, 0)  AS ConversionFees,
    ISNULL(a.InterestFees, 0)    AS InterestFees,
    ISNULL(a.SDRT, 0)            AS SDRT,
    ISNULL(a.TradingFees, 0)     AS TradingFees,
    d.Revenue + ISNULL(a.DormantFee,0) + ISNULL(a.ConversionFees,0)
      + ISNULL(a.InterestFees,0) + ISNULL(a.SDRT,0) + ISNULL(a.TradingFees,0) AS TotalRevenue
FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level] d
LEFT JOIN [BI_DB_dbo].[BI_DB_DDR_CID_Level_Auxiliary_Metrics] a
    ON d.CID = a.CID AND d.DateID = a.DateID
WHERE d.DateID = 20260410
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources were accessible during Phase 10 (MCP not available). SP_DDR_Auxiliary_Metrics header comment (Guy Manova, 2020-12-07) describes its purpose: "this proc adds new metrics to the DDR. it's not possible to add them to the DDR without rerunning it, which is too inefficient." Change history documents additions: SDRT (Adi Meidan, 2023-09-13), TradingFees (Artyom Bogomolsky, 2024-02-25), Islamic fees inclusion (2024-03-18), TicketFees as separate column (2024-05-08).

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 12/14*
*Tiers: 0 T1, 23 T2, 0 T3, 0 T4 | Elements: 23/23, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_DDR_CID_Level_Auxiliary_Metrics | Type: Table | Production Source: Fact_CustomerAction + Fact_SnapshotCustomer + BI_DB_DepositWithdrawFee + BI_DB_Daily_CreditLine via SP_DDR_Auxiliary_Metrics*
