# BI_DB_dbo.BI_DB_DailyCommisionReport

**Schema**: BI_DB_dbo | **Object Type**: Table | **Batch**: 20 | **Generated**: 2026-04-21

## Purpose

Foundational daily commission and trading revenue report at customer × instrument × position-type grain. The primary revenue truth table for BI_DB_dbo: aggregates all commission, rollover, and fee types (9 distinct revenue categories) for every active customer-instrument combination on each reporting date. Grain: RealCID × FullDate × InstrumentID × IsSettled × IsMirror × IsBuy × IsLeverage × IsLeverageMoreThen20 × IsAirDrop × SettlementTypeID × IsMarginTrade.

Revenue metrics are sourced from a suite of foundation-layer TVFs (`Function_Revenue_FullCommissions`, `Function_Revenue_Commissions`, `Function_Revenue_RolloverFee`, etc.), abstracting the raw Fact_CustomerAction logic. Customer dimensions are sourced from `BI_DB_Client_Balance_CID_Level_New` (point-in-time as of @DateID).

This table is the upstream dependency for: `BI_DB_DailyCommisionReport_Instrument_Agg`, `BI_DB_DailyCommisionReport_Last2weeks`, `BI_DB_DailyCommisionReport_ThisMonth`, `BI_DB_DailyCommisionReport_LastYear`, `BI_DB_DailyCommisionReport_Yesterday`, and downstream objects including user-segment and equity snapshots.

## Properties

| Property | Value |
|----------|-------|
| Full Name | BI_DB_dbo.BI_DB_DailyCommisionReport |
| Writer SP | SP_DailyCommisionReport |
| Refresh Pattern | DELETE WHERE DateID=@DateID + INSERT (incremental by date, @Date parameter) |
| Row Count | ~179K rows per date (2026-04-12 sample: 179,538); count(*)>2B total, overflows INT |
| Date Range | 2018-01-01 to 2026-04-12 (3,024 distinct dates) |
| Distribution | ROUND_ROBIN |
| Index | CLUSTERED INDEX (DateID ASC, RealCID ASC) |
| UC Target | _Not_Migrated |
| SP Author | Multiple (original author unknown; Guy M 2023, 2024-07, 2025-07 overhaul, 2026-01) |

## Elements

### Customer / Population Columns

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 1 | RealCID | Platform-internal customer ID (primary key). Sourced from BI_DB_Client_Balance_CID_Level_New.CID. Hash distribution key in temp tables. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 2 | UserName | Customer username from Dim_Customer.UserName as of @DateID. | DWH_dbo.Dim_Customer | Tier 2 — SP_DailyCommisionReport |
| 7 | CountryID | Integer country key from Fact_SnapshotCustomer.CountryID as of @DateID. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 8 | Country | Full country name — sourced from BI_DB_Client_Balance_CID_Level_New.Country (traces to Dim_Country.Name). | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 9 | Region | Marketing region label — Dim_Country.MarketingRegionManualName via direct JOIN on Fact_SnapshotCustomer.CountryID. NOT geographic region — uses eToro marketing territory classification. | DWH_dbo.Dim_Country | Tier 2 — SP_DailyCommisionReport |
| 10 | Manager | Account manager full name — Dim_Manager.FirstName + ' ' + LastName via Fact_SnapshotCustomer.AccountManagerID. | DWH_dbo.Dim_Manager | Tier 2 — SP_DailyCommisionReport |
| 11 | Club | Customer club tier label (Diamond, Platinum Plus, Platinum, Gold, Silver, etc.) as of @DateID. From BI_DB_Client_Balance_CID_Level_New.Club. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 20 | FirstDepositDate | Customer's very first deposit date from Dim_Customer. Used for cohort (FTD Year) analysis in the Instrument_Agg satellite. | DWH_dbo.Dim_Customer | Tier 2 — SP_DailyCommisionReport |
| 21 | Regulation | Regulatory jurisdiction label as of @DateID — from BI_DB_Client_Balance_CID_Level_New.ToRegulation (e.g., FCA, CySEC, FSA Seychelles). | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 22 | Mifid | MiFID categorization label as of @DateID — from BI_DB_Client_Balance_CID_Level_New.MifidCategory. Values: Retail, Professional, Retail Pending, etc. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 29 | RegulationID | Integer regulation key from Fact_SnapshotCustomer.RegulationID as of @DateID. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 30 | PlayerLevelID | Integer player level key (1=Silver, 2=Gold, 3=Platinum, 4=Demo, etc.) from Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 31 | MifidCategorizationID | Integer MiFID categorization key from Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 32 | IsValidCustomer | 1 if customer meets eToro's valid customer criteria (non-demo, depositor, active) as of @DateID. From Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 33 | IsCreditReportValidCB | Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). From Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 34 | Label | Customer segment label as of @DateID (e.g., 'Proprietary', internal classification). From BI_DB_Client_Balance_CID_Level_New.Label. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 35 | PlayerStatusID | Integer player status key from Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 36 | PlayerStatus | Player status name (Normal, Blocked, etc.) as of @DateID. From BI_DB_Client_Balance_CID_Level_New.PlayerStatus. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 37 | AccountStatusID | Integer account status key from Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 38 | AccountStatusName | Account status name from Dim_AccountStatus via LEFT JOIN. | DWH_dbo.Dim_AccountStatus | Tier 2 — SP_DailyCommisionReport |
| 39 | AccountTypeID | Integer account type key (1=Personal, 2=Corporate, 14=SMSF, etc.) from Fact_SnapshotCustomer. | DWH_dbo.Fact_SnapshotCustomer | Tier 2 — SP_DailyCommisionReport |
| 40 | AccountType | Account type name as of @DateID. From BI_DB_Client_Balance_CID_Level_New.AccountType. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 44 | IsEtoroTradingCID | Flag for internal eToro trading/housekeeping accounts. From BI_DB_Client_Balance_CID_Level_New. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 45 | IsGlenEagleAccount | Flag for Glen Eagle Securities subsidiary accounts. From BI_DB_Client_Balance_CID_Level_New. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 46 | eToroTradingGroupUser | eToro trading group identifier string. From BI_DB_Client_Balance_CID_Level_New. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |
| 50 | US_State | US state/province short name for US-regulated customers — Dim_State_and_Province.ShortName via LEFT JOIN (RegionByIP_ID, CountryID=219). NULL for non-US customers. | DWH_dbo.Dim_State_and_Province | Tier 2 — SP_DailyCommisionReport |
| 70 | IsDLTUser | Distributed Ledger Technology user flag. From BI_DB_Client_Balance_CID_Level_New. Added 2024-07-30. | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Tier 2 — SP_DailyCommisionReport |

### Date / Identifier Columns

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 12 | FullDate | Reporting date — the @Date SP input parameter. Matches the DELETE key for idempotent reload. | @Date parameter | Tier 2 — SP_DailyCommisionReport |
| 13 | DateID | YYYYMMDD integer — CAST(CONVERT(CHAR(8),@Date,112) AS INT). Clustering key for date-range scans. | @Date parameter | Tier 2 — SP_DailyCommisionReport |
| 18 | UpdateDate | GETDATE() at ETL execution time. | — | Tier 2 — SP_DailyCommisionReport |

### Instrument / Position Dimension Columns

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 3 | InstrumentID | Instrument integer key from Dim_Instrument, propagated through revenue TVFs. | DWH_dbo.Dim_Instrument | Tier 2 — SP_DailyCommisionReport |
| 4 | Instrument | Instrument name from Dim_Instrument.Name (e.g., EUR/USD, AAPL, BTC/USD). | DWH_dbo.Dim_Instrument | Tier 2 — SP_DailyCommisionReport |
| 5 | InstrumentTypeID | Instrument type integer key (1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 10=Crypto Currencies, etc.). | DWH_dbo.Dim_Instrument | Tier 2 — SP_DailyCommisionReport |
| 6 | InstrumentType | Instrument type label from Dim_Instrument.InstrumentType. | DWH_dbo.Dim_Instrument | Tier 2 — SP_DailyCommisionReport |
| 23 | IsSettled | 1=real/settled position (customer owns underlying asset), 0=CFD. From Fact_CustomerAction/Dim_Position. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 24 | IsMirror | 1=copy-trading position (MirrorID>0), 0=manual trade. CASE WHEN MirrorID>0 THEN 1 ELSE 0. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 63 | IsBuy | 1=long (buy) position, 0=short (sell) position. From Dim_Position.IsBuy. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 64 | IsLeverage | 1 if position Leverage > 1, else 0. From Dim_Position.Leverage. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 65 | IsLeverageMoreThen20 | 1 if position Leverage > 20, else 0. High-leverage flag with regulatory significance (ESMA/MiFID leverage limits). | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 66 | IsAirDrop | 1 for positions created via crypto airdrop distributions. From Dim_Position.IsAirDrop. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 67 | SettlementTypeID | Position settlement type: CASE WHEN SettlementTypeID IS NULL THEN IsSettled ELSE SettlementTypeID END. Key values: 0=CFD, 1=Real, 5=Margin trade. | DWH_dbo.Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 77 | IsMarginTrade | 1 if SettlementTypeID=5 (margin-funded position) in Fact_CustomerAction. Added 2025-10-23. | DWH_dbo.Fact_CustomerAction | Tier 2 — SP_DailyCommisionReport |

### Commission Metric Columns

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 14 | Commissions | Net commission — SUM(TotalCommission) from Function_Revenue_Commissions. Commission on opens (ActionTypeID IN 1,2,3,39) + CommissionOnClose adjustment on closes (ActionTypeID IN 4,5,6,28,40). The "net to eToro" commission figure. | BI_DB_dbo.Function_Revenue_Commissions | Tier 2 — SP_DailyCommisionReport |
| 15 | FullCommissions | Gross full commission — SUM(TotalFullCommission) from Function_Revenue_FullCommissions. Used for MIFID regulatory revenue reporting. Includes the full spread-embedded commission without adjustments. | BI_DB_dbo.Function_Revenue_FullCommissions | Tier 2 — SP_DailyCommisionReport |
| 25 | CommissionOnOpen | Commission on position opens (ActionTypeID IN 1,2,3,39). Component of Commissions. | BI_DB_dbo.Function_Revenue_Commissions | Tier 2 — SP_DailyCommisionReport |
| 26 | CommissionOnCloseAdjustment | Commission close adjustment — SUM(CommissionOnClose - CommissionByUnits) for close actions. Net of unit-based component on close. | BI_DB_dbo.Function_Revenue_Commissions | Tier 2 — SP_DailyCommisionReport |
| 27 | FullCommissionOnOpen | Gross full commission for open actions. Component of FullCommissions. | BI_DB_dbo.Function_Revenue_FullCommissions | Tier 2 — SP_DailyCommisionReport |
| 28 | FullCommissionOnCloseAdjustment | Gross full commission adjustment on close — SUM(FullCommissionOnClose - FullCommissionByUnits) for close actions. | BI_DB_dbo.Function_Revenue_FullCommissions | Tier 2 — SP_DailyCommisionReport |
| 51 | CommissionOnClose | Raw commission on closed positions (ActionTypeID IN 4,5,6,28,40) before unit adjustment. | BI_DB_dbo.Function_Revenue_Commissions | Tier 2 — SP_DailyCommisionReport |
| 56 | UnrealizedCommissionChange | Daily change in unrealized spread commission embedded in open positions: new positions opened on @DateID gain unrealized commission; positions closed on @DateID release it. Computed as (CommissionOnOpen for new opens) minus (CommissionByUnitsAtClose for closes on positions opened prior to @DateID). | DWH_dbo.Fact_CustomerAction + Dim_Position | Tier 2 — SP_DailyCommisionReport |
| 57 | FullCommissionOnClose | Gross full commission on closed positions. | BI_DB_dbo.Function_Revenue_FullCommissions | Tier 2 — SP_DailyCommisionReport |
| 61 | RealizedFullCommission | Gross realized full commission — SUM(FullCommissionOnClose) for positions closed on @DateID. | BI_DB_dbo.Function_Revenue_FullCommissions | Tier 2 — SP_DailyCommisionReport |
| 52 | CommissionByUnitsAtClose | **Always NULL** — set to NULL in INSERT since 2025-07-16 overhaul. Legacy column. | — | Tier 4 — Legacy/Deprecated |
| 53 | UnrealizedCommissionNew | **Always NULL** — legacy unrealized commission decomposition, not populated. | — | Tier 4 — Legacy/Deprecated |
| 54 | UnrealizedCommissionOldClosing | **Always NULL** — legacy unrealized commission decomposition, not populated. | — | Tier 4 — Legacy/Deprecated |
| 55 | RealizedCommission | **Always NULL** — computed in intermediate temp table but explicitly set to NULL in the INSERT since 2025-07-16. Do not use. | — | Tier 4 — Legacy/Deprecated |
| 58 | FullCommissionByUnitsAtClose | **Always NULL** — legacy gross commission by units at close, not populated. | — | Tier 4 — Legacy/Deprecated |
| 59 | UnrealizedFullCommissionNew | **Always NULL** — legacy gross unrealized decomposition, not populated. | — | Tier 4 — Legacy/Deprecated |
| 60 | UnrealizedFullCommissionOldClosing | **Always NULL** — legacy gross unrealized decomposition, not populated. | — | Tier 4 — Legacy/Deprecated |
| 62 | UnealizedFullCommissionChange | **Always NULL** — legacy gross unrealized change, not populated. **"Un*e*alized" is a persisted DDL typo** (missing 'r'); actual column name in the database contains the misspelling. | — | Tier 4 — Legacy/Deprecated |

### Fee / Volume Columns

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 16 | VolumeOnOpen | USD trading volume for positions opened on @DateID — SUM(VolumeOpen) from Function_Trading_Volume. | BI_DB_dbo.Function_Trading_Volume | Tier 2 — SP_DailyCommisionReport |
| 17 | VolumeOnClose | USD trading volume for positions closed on @DateID — SUM(VolumeClose) from Function_Trading_Volume. | BI_DB_dbo.Function_Trading_Volume | Tier 2 — SP_DailyCommisionReport |
| 19 | RollOverFee | Daily overnight rollover/carry fee — SUM(RolloverFee) from Function_Revenue_RolloverFee. Charged for holding leveraged positions overnight. | BI_DB_dbo.Function_Revenue_RolloverFee | Tier 2 — SP_DailyCommisionReport |
| 68 | RollOverFee_SDRT | UK Stamp Duty Reserve Tax — SUM(SDRT) from Function_Revenue_SDRT. Applies to UK equity transactions. Added 2023-10-31. | BI_DB_dbo.Function_Revenue_SDRT | Tier 2 — SP_DailyCommisionReport |
| 69 | TradingFees | Composite trading fee total — ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0). Added 2024-02-25 as "Ticket Fee + Islamic Fee" summary. | Multiple Function_Revenue_* | Tier 2 — SP_DailyCommisionReport |
| 71 | TicketFee | Per-ticket transaction fee — SUM(TicketFee) from Function_Revenue_TicketFee. Fixed fee per trade. | BI_DB_dbo.Function_Revenue_TicketFee | Tier 2 — SP_DailyCommisionReport |
| 72 | TicketFeeByPercent | Percentage-based ticket fee — SUM(TicketFeeByPercent) from Function_Revenue_TicketFeeByPercent. Alternative percentage fee structure. | BI_DB_dbo.Function_Revenue_TicketFeeByPercent | Tier 2 — SP_DailyCommisionReport |
| 73 | AdminFee | Islamic finance / administration fee — SUM(AdminFee) from Function_Revenue_AdminFee. Charged to swap-free (Islamic-compliant) accounts in lieu of rollover. | BI_DB_dbo.Function_Revenue_AdminFee | Tier 2 — SP_DailyCommisionReport |
| 74 | SpotAdjustFee | Spot price adjustment fee — SUM(SpotAdjustFee) from Function_Revenue_SpotAdjustFee. Adjustment for real/settled position pricing. | BI_DB_dbo.Function_Revenue_SpotAdjustFee | Tier 2 — SP_DailyCommisionReport |
| 75 | InvestedAmountOpen | USD invested amount for positions opened on @DateID — SUM(InvestedAmountOpen) from Function_Trading_Volume. | BI_DB_dbo.Function_Trading_Volume | Tier 2 — SP_DailyCommisionReport |
| 76 | CountUU | Count of unique customers in this grain combination — COUNT(DISTINCT CID) from Function_Trading_Volume. Typically 1 per row (grain includes RealCID), but may be >1 in aggregated contexts. | BI_DB_dbo.Function_Trading_Volume | Tier 2 — SP_DailyCommisionReport |

### Legacy / Deprecated Columns (Always NULL)

| # | Column | Description | Source | Tier |
|---|--------|-------------|--------|------|
| 41 | IsOutlier | **Always NULL** — not populated since 2025-07-16 SP overhaul. Was previously used to flag statistical outlier customers. | — | Tier 4 — Legacy/Deprecated |
| 42 | Transition | **Always NULL** — legacy column for regulation transition tracking. Not populated. | — | Tier 4 — Legacy/Deprecated |
| 43 | IsGermanBaFIN | **Always NULL** — legacy flag for German BaFin-regulated customers. Not populated (replaced by Regulation column logic). | — | Tier 4 — Legacy/Deprecated |
| 47 | RegulationIDPrev | **Always NULL** — legacy tracking for previous regulation ID before a regulation change. Not populated. | — | Tier 4 — Legacy/Deprecated |
| 48 | RegulationPrev | **Always NULL** — legacy previous regulation name. Not populated. | — | Tier 4 — Legacy/Deprecated |
| 49 | IsCreditReportValidCBPrev | **Always NULL** — legacy previous credit report validity. Not populated. | — | Tier 4 — Legacy/Deprecated |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (@DateID)
  + DWH_dbo.Fact_SnapshotCustomer (via Dim_Range DateRangeID)
  + DWH_dbo.Dim_Manager, Dim_Customer, Dim_Country, Dim_AccountStatus, Dim_State_and_Province
  → #pop (customer universe as of @DateID — hash distributed by RealCID)

Revenue TVFs → individual revenue temp tables → FULL OUTER JOIN → #allMetrics:
  Function_Revenue_FullCommissions  → #FullComm
  Function_Revenue_Commissions      → #Comm
  Function_Revenue_RolloverFee      → #Rollovers
  Function_Revenue_TicketFee        → #TicketFee
  Function_Revenue_TicketFeeByPercent → #TicketFeeByPercent
  Function_Revenue_AdminFee         → #AdminFee
  Function_Revenue_SpotAdjustFee    → #SpotAdjustFee
  Function_Revenue_SDRT             → #sdrt
  Function_Trading_Volume           → #volumes
  Fact_CustomerAction + Dim_Position → #addUnrealizedChange → #unrealizedCommChange

#pop LEFT JOIN #allMetrics → #final (filtered: WHERE NOT all metrics IS NULL)

  |-- SP_DailyCommisionReport @Date
  |     DELETE FROM BI_DB_DailyCommisionReport WHERE DateID=@DateID
  |     INSERT INTO BI_DB_DailyCommisionReport FROM #final
  |     DELETE FROM BI_DB_DailyCommisionReport_Instrument_Agg WHERE DateID=@DateID
  |     INSERT INTO BI_DB_DailyCommisionReport_Instrument_Agg (instrument-grouped aggregation)
  v
BI_DB_dbo.BI_DB_DailyCommisionReport
  (2018-01-01 – 2026-04-12 | 3,024 dates | ~179K rows/date | COUNT(*)>2B | CLUSTERED INDEX DateID,RealCID | ROUND_ROBIN)
  |-- UC Target: _Not_Migrated ---|

Downstream satellite tables (read from this table):
  BI_DB_DailyCommisionReport_Last2weeks
  BI_DB_DailyCommisionReport_ThisMonth
  BI_DB_DailyCommisionReport_MonthlyData
  BI_DB_DailyCommisionReport_LastYear
  BI_DB_DailyCommisionReport_ThisYear
  BI_DB_DailyCommisionReport_Yesterday
```

## Gotchas

**14 always-NULL legacy columns**: Columns 41-43 (IsOutlier, Transition, IsGermanBaFIN), 47-49 (RegulationIDPrev, RegulationPrev, IsCreditReportValidCBPrev), and 52-55 / 58-60 / 62 (various unrealized commission decompositions) are ALWAYS NULL in current inserts. The SP explicitly sets them to NULL since the 2025-07-16 overhaul. Do not rely on these for analysis.

**"Un*e*alized" DDL typo**: Column 62 `UnealizedFullCommissionChange` contains a persisted misspelling (missing 'r' in 'Unrealized'). This is the actual column name in the DDL. It is also always NULL. Reference it as `[UnealizedFullCommissionChange]` in queries (though since it's always NULL, this rarely matters).

**Commissions vs FullCommissions**: These are two distinct revenue measures. `Commissions` is the net eToro-earned commission. `FullCommissions` is the gross commission (including the portion that may flow to other parties under MIFID/regulatory reporting). For P&L analysis use `Commissions`; for regulatory reporting use `FullCommissions`.

**COUNT(*) overflows INT**: The table has more than 2 billion rows total (spans 2018–2026, ~179K rows/day). `SELECT COUNT(*) FROM BI_DB_DailyCommisionReport` returns an arithmetic overflow error. Use `COUNT_BIG(*)` or `CAST(COUNT(*) AS BIGINT)` to avoid. For date-filtered queries this is not an issue.

**Row count filter**: The #final step filters out rows where ALL metric columns are NULL (`WHERE NOT (FullCommissions IS NULL AND Commissions IS NULL AND ... CountUU IS NULL)`). This means only customers with actual activity on @DateID (via any of the 9 revenue TVFs) appear. The population (#pop) may be larger than the final insert.

**Same-SP dual-write**: SP_DailyCommisionReport writes both BI_DB_DailyCommisionReport AND BI_DB_DailyCommisionReport_Instrument_Agg in a single execution. These two tables are always in sync for the same @DateID.

**Foundation TVF dependency**: All revenue metrics depend on the foundation TVFs (`Function_Revenue_FullCommissions`, etc.) being up to date. If these functions contain bugs or are modified, all downstream DDR metrics are affected simultaneously. The 2025-07-16 overhaul aligned this table to "foundation functions" — prior SP versions used direct Fact_CustomerAction queries.

**IsDLTUser flag (2024-07-30)**: DLT (Distributed Ledger Technology) users have different regulatory treatment for real crypto positions. Historical rows before 2024-07-30 will have NULL for IsDLTUser.

**IsMarginTrade flag (2025-10-23)**: Rows before 2025-10-23 will have NULL for IsMarginTrade.

## Sample Queries

```sql
-- Daily revenue by instrument type for a specific date
SELECT
    FullDate,
    InstrumentType,
    SUM(Commissions)       AS Net_Commissions,
    SUM(FullCommissions)   AS Gross_FullCommissions,
    SUM(RollOverFee)       AS Rollover_Revenue,
    SUM(TradingFees)       AS Trading_Fees,
    SUM(RollOverFee_SDRT)  AS SDRT,
    SUM(VolumeOnOpen)      AS Volume_Opened
FROM BI_DB_dbo.BI_DB_DailyCommisionReport
WHERE DateID = 20260412
GROUP BY FullDate, InstrumentType
ORDER BY Gross_FullCommissions DESC;
```

```sql
-- Customer revenue by regulation — prior 30 days (use DateID range for performance)
SELECT
    Regulation,
    Club,
    SUM(Commissions)     AS Net_Commissions,
    SUM(FullCommissions) AS Gross_FullCommissions,
    SUM(RollOverFee)     AS Rollover,
    SUM(AdminFee)        AS Islamic_Fee
FROM BI_DB_dbo.BI_DB_DailyCommisionReport
WHERE DateID BETWEEN 20260313 AND 20260412
  AND IsValidCustomer = 1
GROUP BY Regulation, Club
ORDER BY Gross_FullCommissions DESC;
```

```sql
-- Crypto real vs CFD commission breakdown
SELECT
    FullDate,
    CASE WHEN IsSettled = 1 THEN 'Real' ELSE 'CFD' END AS Position_Type,
    CASE WHEN IsMirror = 1 THEN 'Copy' ELSE 'Manual' END AS Trade_Origin,
    SUM(FullCommissions)         AS FullCommissions,
    SUM(UnrealizedCommissionChange) AS UnrealizedChange,
    SUM(RollOverFee)             AS Rollover
FROM BI_DB_dbo.BI_DB_DailyCommisionReport
WHERE DateID = 20260412
  AND InstrumentTypeID = 10  -- Crypto
GROUP BY FullDate, IsSettled, IsMirror
ORDER BY FullCommissions DESC;
```

## Related Objects

| Object | Relationship |
|--------|-------------|
| SP_DailyCommisionReport | Writer stored procedure |
| BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg | Instrument-aggregated satellite; written by same SP execution |
| BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks | Rolling 2-week window subset |
| BI_DB_dbo.BI_DB_DailyCommisionReport_ThisMonth | Current-month subset |
| BI_DB_dbo.BI_DB_DailyCommisionReport_MonthlyData | Monthly aggregation |
| BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear | Prior-year subset |
| BI_DB_dbo.BI_DB_DailyCommisionReport_Yesterday | Yesterday-only snapshot |
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Population source (customer dimensions) |
| BI_DB_dbo.Function_Revenue_FullCommissions | Foundation TVF for FullCommissions |
| BI_DB_dbo.Function_Revenue_Commissions | Foundation TVF for Commissions |
| BI_DB_dbo.Function_Revenue_RolloverFee | Foundation TVF for RollOverFee |
| BI_DB_dbo.Function_Revenue_SDRT | Foundation TVF for SDRT (UK stamp duty) |
| BI_DB_dbo.Function_Trading_Volume | Foundation TVF for VolumeOnOpen/Close, InvestedAmountOpen, CountUU |
| DWH_dbo.Fact_CustomerAction | Raw action source for commission TVFs and UnrealizedCommissionChange |
| DWH_dbo.Fact_SnapshotCustomer | Customer snapshot source for population dimensions |
