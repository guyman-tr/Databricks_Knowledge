# BI_DB_dbo.BI_DB_GST_Report

> Daily per-customer revenue breakdown for Singapore-based eToro depositors, covering close-side commissions by asset class (Real vs CFD), overnight fees, cashout fees, conversion fees, dormant fees, staking RevShare, ticket fees, and Islamic fees. ~3.3M rows across ~29.9K distinct customers, data from 2023-01-01 to present. Loaded daily by SP_GST_Report via DELETE+INSERT per Date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: Fact_SnapshotCustomer (population), Fact_CustomerAction (commissions, Islamic fee, staking), BI_DB_DDR_CID_Level (overnight/cashout/dormant fees), BI_DB_DepositWithdrawFee (conversion fee), Function_Revenue_TicketFee, Function_Revenue_TicketFeeByPercent, Dim_Position (airdrops) via SP_GST_Report |
| **Refresh** | Daily via SP_GST_Report @Date (DELETE+INSERT per Date) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_GST_Report` is a Singapore-specific daily revenue report table used for GST (Goods and Services Tax) regulatory reporting. It contains one row per customer per day, breaking down all revenue-generating activities by asset class and fee type. The table is scoped exclusively to **Singapore depositors** — the population is built from `Fact_SnapshotCustomer` filtered on `CountryID=183` (Singapore), `IsCreditReportValidCB=1`, `IsValidCustomer=1`, and `IsDepositor=1`.

For each qualifying customer, the SP calculates:
- **Close-side commissions** split into 12 columns: 6 asset classes (Stocks, ETF, Indices, Commodities, Crypto Currencies, Currencies) x 2 settlement types (Real vs CFD)
- **Fees**: overnight, cashout (including transfer coin fees), conversion (PIPs), dormant, ticket (flat + percentage-based), Islamic (administration fee + spot price adjustment compensation)
- **Staking RevShare**: eToro's revenue share from staking rewards, computed as `Amount * (1-RevShare)/RevShare` where RevShare varies by Club tier (Bronze=0.45 to Diamond=0.90)

Each customer row also carries their Regulation (from Dim_Regulation), Club tier (from Dim_PlayerLevel), Entity (mapped from RegulationID: ASIC/ASIC&GAML → eToro Capital Australia, FCA → eToro UK, others → NULL), and an Is_eToro Group Trading flag.

As of 2026-04-26: ~3.3M rows, 29,902 distinct customers, data spanning 2023-01-01 to 2026-04-26. 8 distinct regulations observed, 6 Club tiers, 3 Entity values (eToro UK, eToro Capital Australia, NULL). Rows with zero across all fee and commission columns are excluded by the SP's final WHERE filter.

---

## 2. Business Logic

### 2.1 Population Filter — Singapore Depositors Only

**What**: The report population is restricted to Singapore-based, valid, depositing customers with credit report eligibility.

**Columns Involved**: `RealCID`, `Regulation`, `Club`, `Entity`, `Is_eToro Group Trading`

**Rules**:
- `CountryID = 183` (Singapore only — hardcoded in SP)
- `IsCreditReportValidCB = 1`
- `IsValidCustomer = 1`
- `IsDepositor = 1`
- Customer snapshot determined via `Dim_Range` date-range filter: `@DateID BETWEEN dr.FromDateID AND dr.ToDateID`

### 2.2 Entity Mapping

**What**: Maps RegulationID to the eToro legal entity name for regulatory reporting.

**Columns Involved**: `Entity`

**Rules**:
- RegulationID IN (4, 10) → 'eToro Capital Australia' (ASIC, ASIC & GAML)
- RegulationID = 2 → 'eToro UK' (FCA)
- All other regulations → NULL

Distribution: eToro UK=2,091,484 rows, eToro Capital Australia=902,696, NULL=334,762.

### 2.3 Is_eToro Group Trading Flag

**What**: Binary flag indicating whether the customer's regulation falls under the eToro Group Trading umbrella.

**Columns Involved**: `Is_eToro Group Trading`

**Rules**:
- RegulationID IN (1, 2, 4, 10, 9) → 1 (CySEC, FCA, ASIC, ASIC & GAML, FSA Seychelles)
- All other regulations → 0

### 2.4 Commission Split — Real vs CFD by Asset Class

**What**: Close-side commissions are split into 12 columns by settlement type (Real/CFD) and instrument type.

**Columns Involved**: `Real Stocks`, `Real ETF`, `Real Indices`, `Real Commodities`, `Real Crypto Currencies`, `Real Currenciess`, `CFD Stocks`, `CFD ETF`, `CFD Indices`, `CFD Commodities`, `CFD Crypto Currencies`, `CFD Currenciess`

**Rules**:
- Real columns: `SUM(CommissionOnClose) WHERE IsSettled=1` from Fact_CustomerAction
- CFD columns: `SUM(CommissionOnClose) WHERE IsSettled=0` from Fact_CustomerAction
- Grouped by `Dim_Instrument.InstrumentType` (Stocks, ETF, Indices, Commodities, Crypto Currencies, Currencies)
- Note: column name `Currenciess` has a typo (double 's') — use as-is

### 2.5 CashoutFee — Composite Column

**What**: CashoutFee in this table is the sum of cashout fees AND transfer coin fees from DDR.

**Columns Involved**: `CashoutFee`

**Rules**:
- `CashoutFee = SUM(DDR.CashoutFee) + SUM(DDR.TransferCoinFees)`
- This is NOT the same as DDR.CashoutFee alone — it includes transfer coin fees

### 2.6 Staking RevShare Computation

**What**: Calculates eToro's revenue share from customer staking rewards, using a tier-based RevShare percentage.

**Columns Involved**: `Staking_Revshare`, `Club` (via PlayerLevelID)

**Rules**:
- Two staking income sources are UNIONed:
  1. **Compensation**: Fact_CustomerAction WHERE ActionTypeID=36, CompensationReasonID=3 (Technical Problem)
  2. **Airdrops**: Dim_Position WHERE IsAirDrop=1 on staking-eligible instruments (from Dealing_Staking_Parameters)
- RevShare by Club tier:
  - Bronze (PlayerLevelID=1) → 0.45
  - Silver (PlayerLevelID=5) → 0.55
  - Gold (PlayerLevelID=3) → 0.65
  - Platinum (PlayerLevelID=2) → 0.75
  - Platinum Plus (PlayerLevelID=6) → 0.85
  - Diamond (PlayerLevelID=7) → 0.90
  - Other → 1.00
- Formula: `eToro RevShare = SUM(Amount * (1 - RevShare) / RevShare)`
- Staking-eligible instruments are dynamically resolved from `Dealing_Staking_Parameters WHERE DailyPool_StartDate <= @Date`

### 2.7 Zero-Activity Row Exclusion

**What**: Rows where all commission and fee columns are zero are excluded from the final INSERT.

**Rules**:
- The SP's final WHERE clause requires at least one non-zero value across all 12 commission columns, OvernightFee, CashoutFee, ConversionFee, TotalDormantFee, Staking_Revshare, IslamicFee, TicketingFee, and TicketingFeeByPercent
- A customer with activity on @Date but zero revenue in all categories will NOT appear

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a HEAP index. No clustered index exists, so queries without filters will scan all data. Always filter on `[Date]` for efficient date-range queries. ROUND_ROBIN means JOINs on RealCID will require data movement — consider local aggregation before joining to other HASH-distributed tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total revenue by regulation for a date | `WHERE [Date] = @date GROUP BY Regulation` |
| Customer's daily revenue breakdown | `WHERE RealCID = @cid AND [Date] = @date` |
| Monthly staking RevShare by Club tier | `WHERE [Date] BETWEEN @start AND @end GROUP BY Club, DATEPART(MONTH, [Date])` |
| Total commission by asset class for a period | `WHERE [Date] BETWEEN @start AND @end` then SUM each commission column |
| Identify customers with Islamic fees | `WHERE IslamicFee <> 0 AND [Date] = @date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON g.RealCID = dc.RealCID | Additional customer attributes (email, KYC, etc.) |
| DWH_dbo.Dim_Regulation | ON g.Regulation = dr.Name | RegulationID, ClusterRegulationID |
| DWH_dbo.Dim_PlayerLevel | ON g.Club = dpl.Name | PlayerLevelID, CashoutPendingHours, Sort order |
| DWH_dbo.Dim_Date | ON CONVERT(int, CONVERT(varchar(8), g.[Date], 112)) = dd.DateKey | Calendar attributes |

### 3.4 Gotchas

- **Singapore only**: This table contains ONLY Singapore customers (CountryID=183). Do not use it for global revenue analysis.
- **CashoutFee includes TransferCoinFees**: Unlike DDR where these are separate columns, here CashoutFee = DDR.CashoutFee + DDR.TransferCoinFees.
- **Column name typo**: `Real Currenciess` and `CFD Currenciess` have a double 's' — this is intentional (matches production naming).
- **Entity is NULL for most regulations**: Only ASIC/ASIC&GAML (eToro Capital Australia) and FCA (eToro UK) have Entity values. CySEC, FSA Seychelles, MAS, etc. are NULL.
- **TicketingFee and TicketingFeeByPercent are negated**: The SP applies `-SUM(TicketFee)`, so positive values in these columns represent costs to the company (revenue perspective).
- **Zero rows excluded**: Customers with zero across all revenue columns on a given date are not present — absence does not mean the customer was inactive, only that they generated no revenue.
- **Staking RevShare is eToro's share, not the customer's**: The formula calculates `Amount * (1-RevShare)/RevShare`, which is the company's portion of the staking reward.
- **Commission columns are close-side only**: These columns contain `CommissionOnClose`, not full commissions (open+close). For full commission analysis, use BI_DB_DDR_CID_Level.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 | `(Tier 1 — upstream wiki, source)` |
| ★★★☆☆ | Tier 2 | `(Tier 2 — source table)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Real (funded) customer ID. The primary customer identifier in the DWH ecosystem. (Tier 1 — Fact_SnapshotCustomer) |
| 2 | Regulation | varchar(20) | YES | Short code for the regulation. Values match production Dictionary.Regulation.Name. 8 values observed: FCA, ASIC & GAML, FSA Seychelles, ASIC, CySEC, MAS, FSRA, BVI. (Tier 1 — Dictionary.Regulation) |
| 3 | Club | varchar(20) | YES | Tier display name from eToro Club loyalty program. 6 values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. IDs are NOT in rank order — use Dim_PlayerLevel.Sort for ordering. (Tier 1 — Dictionary.PlayerLevel) |
| 4 | Entity | varchar(50) | YES | eToro legal entity name for regulatory reporting. CASE on RegulationID: 4,10 (ASIC, ASIC & GAML) → 'eToro Capital Australia'; 2 (FCA) → 'eToro UK'; all others → NULL. (Tier 2 — Fact_SnapshotCustomer) |
| 5 | Is_eToro Group Trading | int | YES | 1 if the customer's regulation falls under the eToro Group Trading umbrella (CySEC=1, FCA=2, ASIC=4, ASIC&GAML=10, FSA Seychelles=9), else 0. (Tier 2 — Fact_SnapshotCustomer) |
| 6 | Date | date | YES | Business date for the report row. One row per customer per date. Derived from SP parameter @Date. Used as the DELETE+INSERT partition key. (Tier 2 — SP_GST_Report) |
| 7 | Real Stocks | float | YES | Close-side commission from real (settled) stock positions on this date. SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='Stocks'. (Tier 2 — Fact_CustomerAction) |
| 8 | Real ETF | float | YES | Close-side commission from real (settled) ETF positions on this date. SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='ETF'. (Tier 2 — Fact_CustomerAction) |
| 9 | Real Indices | float | YES | Close-side commission from real (settled) index positions on this date. SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='Indices'. (Tier 2 — Fact_CustomerAction) |
| 10 | Real Commodities | float | YES | Close-side commission from real (settled) commodity positions on this date. SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='Commodities'. (Tier 2 — Fact_CustomerAction) |
| 11 | Real Crypto Currencies | float | YES | Close-side commission from real (settled) crypto positions on this date. SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='Crypto Currencies'. (Tier 2 — Fact_CustomerAction) |
| 12 | Real Currenciess | float | YES | Close-side commission from real (settled) FX/currency positions on this date. SUM(CommissionOnClose) WHERE IsSettled=1 AND InstrumentType='Currencies'. Note: column name typo (double 's') — use as-is. (Tier 2 — Fact_CustomerAction) |
| 13 | CFD Stocks | float | YES | Close-side commission from CFD stock positions on this date. SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='Stocks'. (Tier 2 — Fact_CustomerAction) |
| 14 | CFD ETF | float | YES | Close-side commission from CFD ETF positions on this date. SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='ETF'. (Tier 2 — Fact_CustomerAction) |
| 15 | CFD Indices | float | YES | Close-side commission from CFD index positions on this date. SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='Indices'. (Tier 2 — Fact_CustomerAction) |
| 16 | CFD Commodities | float | YES | Close-side commission from CFD commodity positions on this date. SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='Commodities'. (Tier 2 — Fact_CustomerAction) |
| 17 | CFD Crypto Currencies | float | YES | Close-side commission from CFD crypto positions on this date. SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='Crypto Currencies'. (Tier 2 — Fact_CustomerAction) |
| 18 | CFD Currenciess | float | YES | Close-side commission from CFD FX/currency positions on this date. SUM(CommissionOnClose) WHERE IsSettled=0 AND InstrumentType='Currencies'. Note: column name typo (double 's') — use as-is. (Tier 2 — Fact_CustomerAction) |
| 19 | OvernightFee | float | YES | Overnight (rollover) fee charged for holding CFD positions overnight on this date. SUM from BI_DB_DDR_CID_Level. (Tier 2 — BI_DB_DDR_CID_Level) |
| 20 | CashoutFee | float | YES | Cashout fee PLUS transfer coin fees combined. Computed as SUM(DDR.CashoutFee) + SUM(DDR.TransferCoinFees). Not identical to DDR.CashoutFee alone. (Tier 2 — BI_DB_DDR_CID_Level) |
| 21 | ConversionFee | float | YES | Currency conversion fee (PIPs-based). SUM(ISNULL(PIPsCalculation,0)) from BI_DB_DepositWithdrawFee for the customer on this date. (Tier 2 — BI_DB_DepositWithdrawFee) |
| 22 | TotalDormantFee | float | YES | Dormant account maintenance fee charged on this date. SUM(ISNULL(DormantFee,0)) from BI_DB_DDR_CID_Level. (Tier 2 — BI_DB_DDR_CID_Level) |
| 23 | Staking_Revshare | float | YES | eToro's revenue share from customer staking rewards. Computed as SUM(Amount * (1-RevShare)/RevShare) from compensation (CompensationReasonID=3) + airdrop positions on staking-eligible instruments. RevShare varies by Club tier: Bronze=0.45, Silver=0.55, Gold=0.65, Platinum=0.75, Platinum Plus=0.85, Diamond=0.90. (Tier 2 — Fact_CustomerAction / Dim_Position) |
| 24 | UpdateDate | date | YES | The @Date parameter value passed to SP_GST_Report. Represents the business date of the data load, NOT an ETL timestamp. (Tier 2 — SP_GST_Report) |
| 25 | TicketingFee | float | YES | Flat ticket fee revenue. Negated SUM from Function_Revenue_TicketFee: -SUM(ISNULL(TicketFee,0)). Positive values represent company revenue. (Tier 2 — Function_Revenue_TicketFee) |
| 26 | IslamicFee | float | YES | Islamic account fee (administration fee + spot price adjustment). SUM(Amount) from Fact_CustomerAction WHERE ActionTypeID=36 (Compensation) AND CompensationReasonID IN (117=Administration fee, 118=Spot price adjustment). (Tier 2 — Fact_CustomerAction) |
| 27 | TicketingFeeByPercent | float | YES | Percentage-based ticket markup revenue. Negated SUM from Function_Revenue_TicketFeeByPercent: -SUM(ISNULL(TicketFeeByPercent,0)). Positive values represent company revenue. Separate from flat TicketingFee. (Tier 2 — Function_Revenue_TicketFeeByPercent) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| RealCID | Fact_SnapshotCustomer | RealCID | Passthrough (Singapore depositors only) |
| Regulation | Dim_Regulation | Name | Dim-lookup via RegulationID |
| Club | Dim_PlayerLevel | Name | Dim-lookup via PlayerLevelID |
| Entity | Fact_SnapshotCustomer | RegulationID | CASE: 4,10→'eToro Capital Australia'; 2→'eToro UK'; else NULL |
| Is_eToro Group Trading | Fact_SnapshotCustomer | RegulationID | CASE: 1,2,4,10,9→1; else 0 |
| Date | SP_GST_Report | @Date | CONVERT(date, @DateID) |
| Real Stocks..Real Currenciess | Fact_CustomerAction | CommissionOnClose | SUM WHERE IsSettled=1, grouped by InstrumentType |
| CFD Stocks..CFD Currenciess | Fact_CustomerAction | CommissionOnClose | SUM WHERE IsSettled=0, grouped by InstrumentType |
| OvernightFee | BI_DB_DDR_CID_Level | OvernightFee | SUM |
| CashoutFee | BI_DB_DDR_CID_Level | CashoutFee + TransferCoinFees | SUM of both columns |
| ConversionFee | BI_DB_DepositWithdrawFee | PIPsCalculation | SUM(ISNULL(...,0)) |
| TotalDormantFee | BI_DB_DDR_CID_Level | DormantFee | SUM(ISNULL(...,0)) |
| Staking_Revshare | Fact_CustomerAction + Dim_Position | Amount | UNION (compensation + airdrops) then SUM(Amount*(1-RevShare)/RevShare) |
| UpdateDate | SP_GST_Report | @Date | @Date parameter |
| TicketingFee | Function_Revenue_TicketFee | TicketFee | -SUM(ISNULL(...,0)) |
| IslamicFee | Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=36, CompensationReasonID IN (117,118) |
| TicketingFeeByPercent | Function_Revenue_TicketFeeByPercent | TicketFeeByPercent | -SUM(ISNULL(...,0)) |

### 5.2 ETL Pipeline

```
Population:
  DWH_dbo.Fact_SnapshotCustomer (CountryID=183, IsDepositor=1, IsValidCustomer=1, IsCreditReportValidCB=1)
    + Dim_Range (date validity)
    + Dim_Regulation (Name → Regulation)
    + Dim_PlayerLevel (Name → Club)
    + Dim_Country (filter only)
    → #pop (Singapore depositor population)

Commission:
  DWH_dbo.Fact_CustomerAction (DateID=@DateID)
    + Fact_SnapshotCustomer (IsCreditReportValidCB=1)
    + Dim_Instrument (InstrumentType classification)
    → #commisions01 (12 commission columns: Real/CFD x 6 asset classes)

Fees:
  BI_DB_dbo.BI_DB_DDR_CID_Level (DateID=@DateID) → #commision02 (OvernightFee, CashoutFee, DormantFee, TransferCoinFee)
  BI_DB_dbo.BI_DB_DepositWithdrawFee (DateID=@DateID) → #commision03 (ConversionFee)
  BI_DB_dbo.Function_Revenue_TicketFee(@DateID, @DateID, 1) → #commision04 (TicketingFee)
  BI_DB_dbo.Function_Revenue_TicketFeeByPercent(@DateID, @DateID, 1) → #commision04_Extra (TicketingFeeByPercent)
  DWH_dbo.Fact_CustomerAction (ActionTypeID=36, CompensationReasonID IN 117,118) → #commision05 (IslamicFee)

Staking:
  DWH_dbo.Fact_CustomerAction (ActionTypeID=36, CompensationReasonID=3) → #comp_data
  DWH_dbo.Dim_Position (IsAirDrop=1) + Dealing_dbo.Dealing_Staking_Parameters → #airdrops_pos
    → UNION → #union_staking (with RevShare by PlayerLevelID)
    → #staking_revshare (SUM(Amount*(1-RevShare)/RevShare))

Assembly:
  #pop LEFT JOIN #commisions01, #commision02, #commision03, #commision04, #commision04_Extra, #commision05, #staking_revshare
    → #final → #final_2 (ISNULL defaults, CashoutFee+TransferCoinFee composite, zero-row filter)

Load:
  DELETE FROM BI_DB_dbo.BI_DB_GST_Report WHERE [Date] = @Date
  INSERT INTO BI_DB_dbo.BI_DB_GST_Report FROM #final_2
```

| Step | Object | Description |
|------|--------|-------------|
| Population | SP_GST_Report #pop | Singapore depositors from Fact_SnapshotCustomer + dims |
| Commission | SP_GST_Report #commisions01 | 12 commission columns from Fact_CustomerAction by InstrumentType and IsSettled |
| Fees | SP_GST_Report #commision02-05 | OvernightFee, CashoutFee, ConversionFee, TicketingFee, IslamicFee from DDR, DepositWithdrawFee, TVFs, FCA |
| Staking | SP_GST_Report #staking_revshare | eToro RevShare from compensation + airdrops |
| Assembly | SP_GST_Report #final, #final_2 | LEFT JOIN all components, apply ISNULL defaults, exclude zero rows |
| Target | BI_DB_dbo.BI_DB_GST_Report | DELETE+INSERT per @Date (~3.3M total rows) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension (implicit FK) |
| Regulation | DWH_dbo.Dim_Regulation (Name) | Regulation name — join on Name to resolve RegulationID |
| Club | DWH_dbo.Dim_PlayerLevel (Name) | Club tier name — join on Name to resolve PlayerLevelID |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified in this regen run.

---

## 7. Sample Queries

### 7.1 Total revenue by regulation for a given date

```sql
SELECT
    Regulation,
    Entity,
    COUNT(DISTINCT RealCID) AS customer_count,
    SUM([Real Stocks] + [Real ETF] + [Real Indices] + [Real Commodities] + [Real Crypto Currencies] + [Real Currenciess]) AS total_real_commission,
    SUM([CFD Stocks] + [CFD ETF] + [CFD Indices] + [CFD Commodities] + [CFD Crypto Currencies] + [CFD Currenciess]) AS total_cfd_commission,
    SUM(OvernightFee) AS total_overnight,
    SUM(CashoutFee) AS total_cashout_fee,
    SUM(Staking_Revshare) AS total_staking
FROM [BI_DB_dbo].[BI_DB_GST_Report]
WHERE [Date] = '2026-04-26'
GROUP BY Regulation, Entity
ORDER BY total_real_commission + total_cfd_commission DESC;
```

### 7.2 Monthly staking RevShare by Club tier

```sql
SELECT
    Club,
    DATEPART(YEAR, [Date]) AS yr,
    DATEPART(MONTH, [Date]) AS mo,
    SUM(Staking_Revshare) AS monthly_staking_revshare,
    COUNT(DISTINCT RealCID) AS customer_count
FROM [BI_DB_dbo].[BI_DB_GST_Report]
WHERE [Date] BETWEEN '2026-01-01' AND '2026-03-31'
  AND Staking_Revshare <> 0
GROUP BY Club, DATEPART(YEAR, [Date]), DATEPART(MONTH, [Date])
ORDER BY yr, mo, monthly_staking_revshare DESC;
```

### 7.3 Customer-level revenue breakdown for a specific customer

```sql
SELECT
    [Date],
    [Real Stocks] + [Real ETF] + [Real Indices] + [Real Commodities] + [Real Crypto Currencies] + [Real Currenciess] AS total_real_commission,
    [CFD Stocks] + [CFD ETF] + [CFD Indices] + [CFD Commodities] + [CFD Crypto Currencies] + [CFD Currenciess] AS total_cfd_commission,
    OvernightFee,
    CashoutFee,
    ConversionFee,
    TotalDormantFee,
    Staking_Revshare,
    TicketingFee,
    TicketingFeeByPercent,
    IslamicFee
FROM [BI_DB_dbo].[BI_DB_GST_Report]
WHERE RealCID = 8199498
ORDER BY [Date] DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — Phase 10 skipped).

---

*Generated: 2026-04-29 | Quality: 8.5/10 (★★★★☆) | Phases: 11/14*
*Tiers: 3 T1, 24 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 27/27, Logic: 9/10, Relationships: 6/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_GST_Report | Type: Table | Production Source: Multi-source via SP_GST_Report*
