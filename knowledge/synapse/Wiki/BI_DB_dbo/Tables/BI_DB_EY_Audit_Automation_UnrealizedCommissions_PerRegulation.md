# BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation

> 9.8M-row daily EY audit table storing per-regulation, per-instrument unrealized commission and PnL changes since 2024-07-13, computed by SP_EY_Audit_Auditor_Unrealized_Calculations from position-level audit data aggregated through Fact_SnapshotCustomer regulation mapping.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact -- EY audit reporting layer) |
| **Production Source** | Derived -- SP_EY_Audit_Auditor_Unrealized_Calculations aggregates position-level unrealized metrics by regulation |
| **Refresh** | Daily (DELETE+INSERT per DateID) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| | |
| **UC Target** | _Not confirmed in generic pipeline mapping_ |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation` is an EY (Ernst & Young) external audit automation table that stores the daily change in unrealized commissions and PnL, broken down by regulatory jurisdiction and instrument. It was added on 2024-07-10 (Guy Manova) because auditors required a by-regulation breakdown of the unrealized commission calculations that was previously only available at aggregate level.

The table is populated daily by `SP_EY_Audit_Auditor_Unrealized_Calculations`, which:
1. Computes per-position unrealized commission and PnL changes between consecutive days (end date vs start date = day before)
2. Aggregates these position-level changes by CID, then maps each CID to its regulation via `Fact_SnapshotCustomer` + `Dim_Range` + `Dim_Regulation`
3. Inserts one row per (DateID, Regulation, InstrumentID, InstrumentType) combination

As of 2025-04-14: ~9.8M rows spanning DateID 20240713 to 20250414. 12 distinct regulations (CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, FinCEN+FINRA, BVI, ASIC, FinCEN, eToroUS, None, NFA) and 6 instrument types (Stocks, ETF, Crypto Currencies, Currencies, Commodities, Indices).

The companion table `BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results` stores the aggregate-level comparison metrics (audit vs client balance), while this table provides the regulation-level detail required by regulators.

---

## 2. Business Logic

### 2.1 Daily Change Computation (Position Level)

**What**: Each day, the SP computes unrealized changes by comparing end-of-day positions at @edate vs @sdate (day before).

**Columns Involved**: `UnrealizedCommissionChange`, `UnrealizedFullCommissionChange`, `UnrealizedPnLChange`

**Rules**:
- `UnrealizedCommissionChange` = `ISNULL(ed.EY_UnrealizedCommission, 0) - ISNULL(sd.EY_UnrealizedCommission, 0)` per position
- `UnrealizedFullCommissionChange` = `ISNULL(ed.EY_UnrealizedFullCommission, 0) - ISNULL(sd.EY_UnrealizedFullCommission, 0)` per position
- `UnrealizedPnLChange` = `ISNULL(ed.EY_PnL_Calculation, 0) - ISNULL(sd.EY_PnL_Calculation, 0)` per position
- Position-level values are computed using a complex PnL formula branching on PnLVersion, IsBuy, SellCurrencyID, and BuyCurrencyID
- Commission calculations use spread config (Ask, Bid, ReferenceAsk, ReferenceBid) with fallback logic choosing the closest match to eToro's recorded commission

### 2.2 Regulation Assignment via Customer Snapshot

**What**: Position-level metrics are mapped to regulations through the customer snapshot pipeline.

**Columns Involved**: `Regulation`

**Rules**:
- Position CID is joined to `Fact_SnapshotCustomer` on `RealCID`
- `Dim_Range` filters to the snapshot row active on the computation date: `p.DateID BETWEEN dr.FromDateID AND dr.ToDateID`
- `Dim_Regulation` resolves `fsc.RegulationID` to `dr1.Name` via `DWHRegulationID`
- A customer's regulation is their end-of-day jurisdiction per the snapshot SCD2 pattern

### 2.3 DELETE+INSERT Load Pattern

**What**: The SP replaces data for a single date on each run.

**Rules**:
- `DELETE FROM ... WHERE DateID = @edateID` runs before the INSERT
- Only one day's data is refreshed per execution
- The SP also manages the underlying `BI_DB_EY_Audit_Opened_Positions` table, ensuring prerequisite data exists and cleaning up dates no longer needed

### 2.4 Commission Calculation Best-Fit Logic

**What**: The SP tries multiple commission calculation methods and picks the one closest to eToro's recorded commission.

**Columns Involved**: `UnrealizedCommissionChange`, `UnrealizedFullCommissionChange`

**Rules**:
- Three methods computed: `EY_CommissionOpen_Calc` (Ask/Bid), `EY_CommissionOpen_Calc_RefAskBid` (ReferenceAsk/ReferenceBid), `EY_CommissionOpen_Calc_LastOpRate`
- `UseReferenceAskBid = 1` when RefAskBid method is closer to recorded Commission
- `UseLastOpPriceRate = 1` when LastOpRate method is closer
- Final unrealized commission = `EY_Commission_Calc_Final * OutstandingUnitsRatio` where `OutstandingUnitsRatio = Units / InitialUnits`
- If `FullCommission < Commission`, FullCommission is corrected to equal Commission
- IsDiscounted=1 positions get commission=0; IsReOpen=1 positions get commission=0

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN**: No hash key; full scans on broad date ranges. Filter on `DateID` to leverage the clustered index.

**CLUSTERED INDEX (DateID ASC)**: Date-filtered queries are efficient. Always include `WHERE DateID = @d` or a bounded range.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily unrealized commission change by regulation | `WHERE DateID = @d GROUP BY Regulation` |
| Monthly total unrealized PnL change by regulation | `WHERE DateID BETWEEN @start AND @end GROUP BY Regulation` with `SUM(UnrealizedPnLChange)` |
| Specific instrument audit trail | `WHERE InstrumentID = @id AND DateID BETWEEN @start AND @end` |
| Regulation-level audit reconciliation | Compare `SUM(UnrealizedCommissionChange)` here vs `BI_DB_Client_Balance_Aggregate_Level_New` for the same DateID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve instrument name, asset class |
| DWH_dbo.Dim_Regulation | ON Regulation = Name | Resolve RegulationID (if needed for further joins) |
| BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results | ON Date | Compare regulation-level detail to aggregate audit results |

### 3.4 Gotchas

- **Regulation is a VARCHAR name, not an ID**: Unlike most DWH tables that store RegulationID (int), this table stores `Dim_Regulation.Name` (varchar). Join on Name, not ID.
- **InstrumentType is a string classification**: Values are "Stocks", "ETF", "Crypto Currencies", "Currencies", "Commodities", "Indices" — not an FK to any dimension.
- **9.8M rows**: Large for an audit table; this is because it stores one row per (DateID, Regulation, InstrumentID, InstrumentType) combination daily.
- **Data starts 2024-07-13**: The table was added mid-2024; no historical data before that date.
- **DELETE+INSERT per day**: Re-running the SP for a past date replaces that day's data. The SP also cleans up intermediate data in `BI_DB_EY_Audit_Opened_Positions` for dates no longer needed.
- **UpdateDate is batch-level**: All rows for a given DateID share the same UpdateDate (GETDATE() at insert time).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 | Upstream wiki verbatim (dim-lookup passthrough) |
| 3 stars | Tier 2 | From Synapse SP code (SP_EY_Audit_Auditor_Unrealized_Calculations) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | YYYYMMDD integer representing the computation end date (@edate). Derived from SP parameter: `CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)`. Clustered index column. Range: 20240713 to 20250414. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 2 | Date | date | YES | Calendar date corresponding to DateID (@edate). Direct assignment from SP parameter. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 3 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. 12 distinct values: CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, FinCEN+FINRA, BVI, ASIC, FinCEN, eToroUS, None, NFA. Resolved via `JOIN Dim_Regulation dr1 ON fsc.RegulationID = dr1.DWHRegulationID; SELECT dr1.Name`. (Tier 1 -Dictionary.Regulation) |
| 4 | InstrumentID | int | YES | FK to Trade.Instrument. Financial instrument being traded. Passthrough from position-level audit data (BI_DB_EY_Audit_Opened_Positions), ultimately from Dim_Position.InstrumentID. (Tier 1 -Trade.PositionTbl) |
| 5 | InstrumentType | varchar(50) | YES | Instrument asset class category. 6 distinct values: Stocks, ETF, Crypto Currencies, Currencies, Commodities, Indices. Passthrough from BI_DB_EY_Audit_Opened_Positions (populated by SP_EY_Audit_Opened_Positions). (Tier 2 -SP_EY_Audit_Opened_Positions) |
| 6 | UnrealizedCommissionChange | decimal(16,6) | YES | Daily change in unrealized commission per regulation and instrument. Computed as `SUM` of per-position `ISNULL(ed.EY_UnrealizedCommission, 0) - ISNULL(sd.EY_UnrealizedCommission, 0)`, where EY_UnrealizedCommission = EY_Commission_Calc_Final * OutstandingUnitsRatio (Units/InitialUnits). Aggregated by regulation via Fact_SnapshotCustomer + Dim_Regulation join. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 7 | UnrealizedFullCommissionChange | decimal(16,6) | YES | Daily change in unrealized full commission (including spread component) per regulation and instrument. Computed as `SUM` of per-position `ISNULL(ed.EY_UnrealizedFullCommission, 0) - ISNULL(sd.EY_UnrealizedFullCommission, 0)`, where EY_UnrealizedFullCommission = EY_FullCommissionOpen_Calc * OutstandingUnitsRatio. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 8 | UnrealizedPnLChange | decimal(16,6) | YES | Daily change in unrealized PnL per regulation and instrument. Computed as `SUM` of per-position `ISNULL(ed.EY_PnL_Calculation, 0) - ISNULL(sd.EY_PnL_Calculation, 0)`. PnL calculation branches on PnLVersion, IsBuy, SellCurrencyID, and BuyCurrencyID using rate-based formulas with USD conversion. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 9 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to `GETDATE()` at insert time. All rows for a given DateID share the same UpdateDate. Not a business date. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| DateID | SP parameter @date | @edate | `CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)` |
| Date | SP parameter @date | @edate | Direct assignment |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough via JOIN on DWHRegulationID from Fact_SnapshotCustomer.RegulationID |
| InstrumentID | BI_DB_EY_Audit_Opened_Positions → Dim_Position | InstrumentID | Passthrough through temp tables |
| InstrumentType | BI_DB_EY_Audit_Opened_Positions | InstrumentType | Passthrough through temp tables |
| UnrealizedCommissionChange | #testresults → #regPrep → #byRegulation | EY_UnrealizedCommission (end - start) | SUM of position-level daily change, aggregated by regulation |
| UnrealizedFullCommissionChange | #testresults → #regPrep → #byRegulation | EY_UnrealizedFullCommission (end - start) | SUM of position-level daily change, aggregated by regulation |
| UnrealizedPnLChange | #testresults → #regPrep → #byRegulation | EY_PnL_Calculation (end - start) | SUM of position-level daily change, aggregated by regulation |
| UpdateDate | ETL-computed | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (closed commissions)
BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions (daily open snapshots)
BI_DB_dbo.EY_Audit_Automation_LastOpRate (last op prices)
BI_DB_dbo.EY_Audit_Automation_Opened_Positions_End_2022_Baseline (pre-2023 baseline)
BI_DB_dbo.EY_Audit_Automation_Position_Open_Configs (spread configs)
  |
  |-- SP_EY_Audit_Auditor_Unrealized_Calculations @date
  |   (builds #StartDateReady, #EndDateReady, computes PnL + commissions,
  |    produces #testresults with per-position daily changes)
  |
  v
#testresults → #regPrep (GROUP BY CID, InstrumentID, InstrumentType)
  |
  |-- JOIN DWH_dbo.Fact_SnapshotCustomer (CID → RegulationID via Dim_Range)
  |-- JOIN DWH_dbo.Dim_Regulation (RegulationID → Name)
  |
  v
#byRegulation (GROUP BY Regulation, InstrumentID, InstrumentType)
  |
  |-- DELETE + INSERT per DateID
  |
  v
BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation (~9.8M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Resolve instrument name and asset class |
| Regulation | DWH_dbo.Dim_Regulation.Name | Regulation jurisdiction name (joined as varchar, not FK) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_EY_Audit_Auditor_Unrealized_Calculations | Writer | DELETE+INSERT per DateID |

---

## 7. Sample Queries

### 7.1 Daily unrealized changes by regulation for a specific date

```sql
SELECT
    Regulation,
    SUM(UnrealizedCommissionChange) AS TotalUnrealizedCommChange,
    SUM(UnrealizedFullCommissionChange) AS TotalUnrealizedFullCommChange,
    SUM(UnrealizedPnLChange) AS TotalUnrealizedPnLChange
FROM [BI_DB_dbo].[BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation]
WHERE DateID = 20250414
GROUP BY Regulation
ORDER BY ABS(SUM(UnrealizedPnLChange)) DESC;
```

### 7.2 Monthly trend for a specific regulation and instrument type

```sql
SELECT
    DateID,
    SUM(UnrealizedPnLChange) AS DailyPnLChange,
    SUM(UnrealizedCommissionChange) AS DailyCommChange
FROM [BI_DB_dbo].[BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation]
WHERE Regulation = 'FCA'
  AND InstrumentType = 'Stocks'
  AND DateID BETWEEN 20250301 AND 20250331
GROUP BY DateID
ORDER BY DateID;
```

### 7.3 Reconciliation check against aggregate client balance

```sql
SELECT
    'AuditPerReg' AS Source,
    SUM(UnrealizedCommissionChange) AS UnrealizedCommChange,
    SUM(UnrealizedPnLChange) AS UnrealizedPnLChange
FROM [BI_DB_dbo].[BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation]
WHERE DateID = 20250414

UNION ALL

SELECT
    'ClientBalanceAgg' AS Source,
    SUM(UnrealizedCommissionChange),
    SUM(UnrealizedPnLChange)
FROM [BI_DB_dbo].[BI_DB_Client_Balance_Aggregate_Level_New]
WHERE DateID = 20250414;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in regen harness.)

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 2 T1, 7 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/9, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation | Type: Table | Production Source: SP_EY_Audit_Auditor_Unrealized_Calculations (derived)*
