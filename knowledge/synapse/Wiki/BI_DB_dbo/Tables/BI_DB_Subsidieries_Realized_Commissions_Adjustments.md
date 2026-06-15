# BI_DB_dbo.BI_DB_Subsidieries_Realized_Commissions_Adjustments

**Schema**: BI_DB_dbo | **Type**: Table | **Batch**: 34 | **Generated**: 2026-04-22

| Property | Value |
|---|---|
| **Writer SP** | `BI_DB_dbo.SP_M_Subsidieries_Realized_Commissions_Adjustments` |
| **Frequency** | Monthly (SB_Daily process) |
| **Priority** | P20 |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Grain** | EOMonth × CreditValidClose × CreditValidOpen × RegulationOnClose × RegulationOnOpen × PeriodOpen × PeriodClose × InstrumentType × IsSettled |
| **Date Range** | 2007-08-31 – 2026-03-31 |
| **Rows/Month (recent)** | ~424 |
| **Total Rows** | ~34,973 |
| **ETL Pattern** | DELETE WHERE EOMonth=@Date + INSERT |

---

## 1. Business Meaning

Monthly aggregate of realized commissions from the group's subsidiary-company customers, collected since company inception (2007) to support adjustment of EU entity client balance calculations. The table classifies each commission amount by the regulatory jurisdiction at both position open and close, the customer's credit validity status at each snapshot date, the intra-year period of the position (opened/closed in the current year vs. prior year), the instrument type, and the settlement type (real asset vs. CFD).

Created by Adi Meidan in August 2022. The SP filters for positions where at least one snapshot (open-date or close-date) has `IsCreditReportValidCB = 1`, ensuring that only Client_Balance-eligible customers are included in the subsidiary commission adjustment.

The "subsidiaries" reference in the name refers to the trading entities regulated outside the primary EU/UK framework. Historical data (2007–2022) was backfilled when the SP was created.

---

## 2. Business Logic

### ETL Population

```sql
-- Monthly pattern (SP_M_Subsidieries_Realized_Commissions_Adjustments, @Date parameter)
-- @sdate = first day of month; @sdateID, @edateID = INT(YYYYMMDD)

-- Step 1: collect closed positions for the month
SELECT dp.PositionID, dp.IsSettled,
  CASE WHEN YEAR(dp.OpenOccurred)  = YEAR(@Date) THEN 'Current_Period_Open'  ELSE 'Previos_Period_Open'   END AS PeriodOpen,
  CASE WHEN YEAR(dp.CloseOccurred) = YEAR(@Date) THEN 'Current_Period_Close' ELSE 'Previous_Period_Close' END AS PeriodClose,
  CASE WHEN fsc.IsCreditReportValidCB = 1 THEN 'CreditValidClose' ELSE 'CreditInvalidClose' END AS CreditValidClose,
  CASE WHEN fsc1.IsCreditReportValidCB = 1 THEN 'CreditValidOpen' ELSE 'CreditInvalidOpen' END AS CreditValidOpen,
  fsc.RegulationID AS RegulationClose, dp.RegulationIDOnOpen,
  FullCommissionByUnits, FullCommissionOnClose, CommissionByUnits, CommissionOnClose,
  di.InstrumentType
INTO #relPos2
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Fact_SnapshotCustomer fsc  -- close-date snapshot
  ON fsc.RealCID = dp.CID
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID
  AND dp.CloseDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc1  -- open-date snapshot
  ON fsc1.RealCID = dp.CID
JOIN DWH_dbo.Dim_Range dr1 ON fsc1.DateRangeID = dr1.DateRangeID
  AND dp.OpenDateID BETWEEN dr1.FromDateID AND dr1.ToDateID
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
WHERE (fsc.IsCreditReportValidCB = 1 OR fsc1.IsCreditReportValidCB = 1)
  AND dp.CloseDateID BETWEEN @sdateID AND @edateID;

-- Step 2: aggregate to reporting grain + resolve regulation IDs to names
SELECT YEAR(@sdate) AS Year, ... EOMONTH(@Date) AS EOMonth,
  SUM(FullCommissionByUnits), SUM(FullCommissionOnClose),
  SUM(CommissionByUnits), SUM(CommissionOnClose),
  dr.Name AS RegulationOnOpen, dr1.Name AS RegulationOnClose
INTO #summary
FROM #relPos2 p
LEFT JOIN DWH_dbo.Dim_Regulation dr  ON p.RegulationIDOnOpen = dr.DWHRegulationID
LEFT JOIN DWH_dbo.Dim_Regulation dr1 ON p.RegulationClose   = dr1.DWHRegulationID
GROUP BY [all dimension columns];

-- Step 3: replace current month's data
DELETE FROM BI_DB_dbo.BI_DB_Subsidieries_Realized_Commissions_Adjustments WHERE EOMonth = @Date;
INSERT INTO BI_DB_dbo.BI_DB_Subsidieries_Realized_Commissions_Adjustments SELECT ... FROM #summary;
```

### Key Design Notes

- **Dual snapshot join**: Each position is joined to `Fact_SnapshotCustomer` twice — once for the close-date customer state and once for the open-date state. This allows tracking whether the customer's credit or regulation changed between open and close.
- **Credit filter**: `IsCreditReportValidCB = 1` on *either* snapshot is required. Positions where both snapshots are credit-invalid are excluded.
- **PeriodOpen typo**: The SP produces `'Previos_Period_Open'` (missing the second 'u'). This typo is present in the production data and should not be corrected when querying.
- **DELETE key**: The DELETE uses `@Date` directly, not `EOMONTH(@Date)`. Since `FrequencySP = Monthly`, the SP is expected to be called on the last day of each month, where `@Date = EOMONTH(@Date)` and the delete is idempotent.

---

## 3. Query Advisory

| Concern | Guidance |
|---|---|
| **No clustered index (HEAP)** | Full scan for any query. Always filter by EOMonth for monthly lookups. |
| **ROUND_ROBIN distribution** | No data locality advantage — queries are broadcast across all nodes. |
| **PeriodOpen typo** | The value `'Previos_Period_Open'` (typo for "Previous") is the actual data value. Filter accordingly. |
| **Dual credit columns** | CreditValidClose/CreditValidOpen are independent — a position can be credit-valid at open but invalid at close. |
| **No PK or unique constraint** | The table is a HEAP with no enforced uniqueness. Confirm the natural grain before joining. |
| **UpdateDate is DATE (not DATETIME)** | The DDL defines UpdateDate as DATE, despite the SP inserting GETDATE(). Truncated to day precision. |
| **LEFT JOIN for regulations** | Regulation names are resolved via LEFT JOIN — RegulationOnClose/RegulationOnOpen may be NULL if regulation ID has no Dim_Regulation match. |

---

## 4. Elements

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | Year | INT | NULL | T2 | Calendar year of the month start date (YEAR of first day of month of @Date). E.g., 2026 for any month in 2026. |
| 2 | YearMonth | INT | NULL | T2 | Year-month as a 6-digit integer in YYYYMM format (CONVERT(VARCHAR(6), first_day_of_month, 112)). E.g., 202603 for March 2026. |
| 3 | EOMonth | DATE | NULL | T2 | Last calendar day of the reporting month (EOMONTH(@Date)). Serves as the primary partition key; the DELETE step removes rows matching this date before each monthly run. |
| 4 | CreditValidClose | VARCHAR(50) | NULL | T2 | Customer credit validity at the close-date snapshot. Derived from Fact_SnapshotCustomer.IsCreditReportValidCB: 1 → 'CreditValidClose', 0 → 'CreditInvalidClose'. |
| 5 | CreditValidOpen | VARCHAR(50) | NULL | T2 | Customer credit validity at the open-date snapshot. Derived from Fact_SnapshotCustomer.IsCreditReportValidCB: 1 → 'CreditValidOpen', 0 → 'CreditInvalidOpen'. |
| 6 | RegulationOnClose | VARCHAR(50) | NULL | T1 | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Sourced via Fact_SnapshotCustomer.RegulationID → Dim_Regulation.Name. |
| 7 | RegulationOnOpen | VARCHAR(50) | NULL | T1 | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Sourced via Dim_Position.RegulationIDOnOpen → Dim_Regulation.Name. |
| 8 | PeriodOpen | VARCHAR(50) | NULL | T2 | Whether the position was opened in the current calendar year: YEAR(OpenOccurred)=YEAR(@Date) → 'Current_Period_Open'; otherwise → 'Previos_Period_Open' (note: typo in SP — single 'u' in "Previos"). |
| 9 | PeriodClose | VARCHAR(50) | NULL | T2 | Whether the position was closed in the current calendar year: YEAR(CloseOccurred)=YEAR(@Date) → 'Current_Period_Close'; otherwise → 'Previous_Period_Close'. |
| 10 | FullCommissionByUnits | MONEY | NULL | T1 | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. Aggregated via SUM over all positions in the dimension group. (Source: Dim_Position.md) |
| 11 | FullCommissionOnClose | MONEY | NULL | T1 | Full commission on close. DWH note: adjusted by SP_Dim_Position when position is reopened; FullCommissionOnCloseOrig stores the pre-adjustment value. Aggregated via SUM. (Source: Dim_Position.md) |
| 12 | CommissionByUnits | MONEY | NULL | T1 | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. Aggregated via SUM. (Source: Dim_Position.md) |
| 13 | CommissionOnClose | MONEY | NULL | T1 | Commission charged on close. DWH note: adjusted by SP_Dim_Position when position is reopened; CommissionOnCloseOrig stores the pre-adjustment value. Aggregated via SUM. (Source: Dim_Position.md) |
| 14 | InstrumentType | VARCHAR(100) | NULL | T1 | Asset class of the traded instrument. CASE-computed from InstrumentTypeID in SP_Dim_Instrument: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. All six categories are present in this table. (Source: Dim_Instrument.md) |
| 15 | UpdateDate | DATE | NULL | T2 | ETL execution date (GETDATE() cast to DATE). Note: DDL type is DATE (not DATETIME), so time component is truncated. |
| 16 | IsSettled | INT | NULL | T1 | 1 = real asset, 0 = CFD asset. (Source: Dim_Position.md — Tier 5 Expert Review in source; consult SME for full definition) |

---

## 5. Lineage

**Writer SP**: `BI_DB_dbo.SP_M_Subsidieries_Realized_Commissions_Adjustments`
**Root Sources**: `DWH_dbo.Dim_Position`, `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_Instrument`

```
DWH_dbo.Dim_Position (commissions + regulation at open + settlement)
  + DWH_dbo.Fact_SnapshotCustomer × 2 (close-date + open-date credit/regulation snapshots)
  + DWH_dbo.Dim_Regulation × 2 (resolve regulation IDs to names)
  + DWH_dbo.Dim_Instrument (InstrumentType)
  |-- SP: filter + GROUP BY → monthly aggregate --|
  v
BI_DB_dbo.BI_DB_Subsidieries_Realized_Commissions_Adjustments
```

See `BI_DB_Subsidieries_Realized_Commissions_Adjustments.lineage.md` for full column-level lineage.

---

## 6. Relationships

| Relationship | Object | Join / Notes |
|---|---|---|
| **Source** | `DWH_dbo.Dim_Position` | PositionID, commission amounts, IsSettled, RegulationIDOnOpen, OpenOccurred/CloseOccurred, CloseDateID |
| **Source** | `DWH_dbo.Fact_SnapshotCustomer` | IsCreditReportValidCB, RegulationID; joined twice (close-date + open-date) via Dim_Range SCD2 |
| **Source** | `DWH_dbo.Dim_Regulation` | Resolves RegulationIDOnOpen and Fact_SnapshotCustomer.RegulationID to Name; joined twice |
| **Source** | `DWH_dbo.Dim_Instrument` | InstrumentType via Dim_Position.InstrumentID |
| **Downstream** | Unknown | No SP or table references found in SSDT scan. Likely consumed by BI tools or Excel reporting for EU finance reconciliation. |

---

## 7. Sample Queries

```sql
-- Latest completed month by regulation and instrument type
SELECT RegulationOnClose, InstrumentType,
       SUM(CommissionOnClose) AS net_commission,
       SUM(FullCommissionOnClose) AS gross_commission
FROM BI_DB_dbo.BI_DB_Subsidieries_Realized_Commissions_Adjustments
WHERE EOMonth = '2026-03-31'
GROUP BY RegulationOnClose, InstrumentType
ORDER BY net_commission DESC;

-- Year-to-date commission by credit validity and settlement type
SELECT Year, CreditValidClose, IsSettled,
       SUM(CommissionOnClose) AS net_commission_on_close,
       SUM(CommissionByUnits) AS net_commission_by_units
FROM BI_DB_dbo.BI_DB_Subsidieries_Realized_Commissions_Adjustments
WHERE Year = 2026
GROUP BY Year, CreditValidClose, IsSettled;

-- Count rows per month (check for duplicates from mid-month runs)
SELECT EOMonth, COUNT(*) AS rows
FROM BI_DB_dbo.BI_DB_Subsidieries_Realized_Commissions_Adjustments
GROUP BY EOMonth
ORDER BY EOMonth DESC;
```

---

## 8. Atlassian

No Confluence page found for this table. The SP description references adjusting EU client balance calculations using subsidiary commission data. Finance or compliance teams may have documentation on the subsidiary commission reconciliation process. Recommended search terms: "subsidiary commissions adjustment", "EU client balance", "SP_M_Subsidieries".
