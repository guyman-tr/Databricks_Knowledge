# BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level

> 175M-row customer-level index dividend tax report expanding `BI_DB_Index_Dividend_TaxReport` to per-customer (RealCID) grain (Jan 2022–Apr 2026, 24 cols). Written by `SP_Index_Divident_TaxReport_CID_Level` (note: "Divident" typo in SP name) from `BI_DB_DailyDividendsByPosition` grouped per customer, enriched with Country from `Fact_SnapshotCustomer`→`Dim_Country`. Extends the parent aggregate table to support per-customer dividend tax reporting and compliance workflows.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_DailyDividendsByPosition` ← `etoro.Trade.IndexDividends` via SP_Index_Divident_TaxReport_CID_Level |
| **Refresh** | Daily SB_Daily (DELETE WHERE DateID=@DateID + INSERT, date-keyed incremental) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Tal Buhnik (2022-09-08) |
| **Row Count** | ~175M (Jan 2022 – Apr 2026) |

---

## 1. Business Meaning

`BI_DB_Index_Dividend_TaxReport_CID_Level` is the customer-level companion to `BI_DB_Index_Dividend_TaxReport`. Where the parent table aggregates to instrument×regulation×tax-code grain (~934K rows total), this table breaks each dividend event down to the individual customer (RealCID), adding Country for per-jurisdiction customer identification. Each row represents one customer's dividends for a given DividendID on a given date, grouped by regulation and position type.

At 175M rows (vs. 934K in parent), the expansion factor (~188×) reflects the average number of customers per dividend event. The grain is: `DateID` + `DividendID` + `RealCID` + `Regulation` + `PositionType`. `CountPositions` here counts positions for that specific customer only — not all customers. `TotalDividendPaid` is that customer's total dividend credited for the event.

The table covers Jan 2022–Apr 2026 (SP created Sep 2022 with backfill to Jan 2022). Country is resolved via `Fact_SnapshotCustomer` → `Dim_Range` → `Dim_Country` at @DateID, providing the customer's regulatory country on the dividend payment date. UK is the top country, followed by Germany, Italy, France, and Spain.

---

## 2. Business Logic

### 2.1 Grain and Customer-Level Aggregation

**What**: The report aggregates position-level rows from `BI_DB_DailyDividendsByPosition` into a per-customer grain per dividend event.

**Columns Involved**: DividendID, InstrumentID, RealCID, Regulation, IsValidCustomer, IsCreditReportValidCB, DateID, CountPositions, TotalDividendPaid

**Rules**:
- `CountPositions = ISNULL(COUNT(PositionID), 0)` — positions held by this specific RealCID that received the dividend on @DateID
- `TotalDividendPaid = ISNULL(SUM(Amount), 0)` — total dividend credited to this customer for this event (can be negative for adjustments)
- GROUP BY includes all non-aggregated columns including RealCID (key difference from parent)
- ROUND_ROBIN + HEAP: no query-time data locality benefit; always filter on DateID

### 2.2 Country Resolution

**What**: Country is added to this table (not present in parent) to support per-customer jurisdiction identification for compliance.

**Columns Involved**: Country, RealCID

**Rules**:
- Country resolved via: `Fact_SnapshotCustomer` (customer snapshot at @DateID) → `Dim_Range` (SCD: CountryID resolved via `BETWEEN FromDateID AND ToDateID`) → `Dim_Country.Name`
- Country is the customer's registered country on the dividend payment date — not necessarily country at position open
- Top countries (by row volume): UK, Germany, Italy, France, Spain
- Small number of rows have Country='None' (~1 row in 2026 data) — likely a Dim_Range resolution gap

### 2.3 Status and Event Lifecycle

**What**: Status reflects the index dividend processing lifecycle, identical to parent table.

**Columns Involved**: Status, EventType, PositionType, ExDate, PaymentDate

**Rules**:
- Status=2 (predominant): Dividend completed and paid to positions
- Status=1: Dividend in-progress at time of snapshot
- Status=NULL: Row had no `etoro_Trade_IndexDividends` match
- `BI_DB_DailyDividendsByPosition` already filters `etoro_Trade_IndexDividends.Status = 2` at source
- EventType distribution: Cash Dividend (dominant), Special Dividend, Dividend with Option, Return of Capital, Shares Premium Dividend

### 2.4 Tax and Position Type

**What**: TaxCode and PositionType drive per-customer tax reporting logic per jurisdiction.

**Columns Involved**: TaxCode, BuyTax, PositionType, IsBuy, DividendCurrencyID, DividendValueInCurrency, Country

**Rules**:
- PositionType=1: REAL stock positions; PositionType=0: CFD positions
- BuyTax: fraction rate 0.0–1.0 (e.g., 0.15 = 15% withholding)
- Country+TaxCode+Regulation together drive per-jurisdiction tax logic
- `[Currency Name]`: abbreviation of the dividend currency (USD, EUR, GBP, GBX, etc.) from `Dim_Currency.Abbreviation`
- TaxCode special values: '999'/'998'/'997'/'996' appear to be special/error codes

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution: ROUND_ROBIN, HEAP — no clustered index and no data-locality benefit from any join column. At 175M rows, always filter on DateID and preferably RealCID to limit scan cost. Avoid full-table scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| All dividends for a customer on a date | `SELECT * WHERE DateID=@D AND RealCID=@CID` |
| Total customer dividends by country for a date | `SELECT Country, COUNT(DISTINCT RealCID), SUM(TotalDividendPaid) WHERE DateID=@D GROUP BY Country` |
| Per-customer tax report by TaxCode and Country | `SELECT RealCID, Country, TaxCode, BuyTax, SUM(TotalDividendPaid) GROUP BY RealCID, Country, TaxCode, BuyTax` |
| Customer dividend history YTD | `SELECT DividendID, InstrumentDisplayName, PaymentDate, TotalDividendPaid WHERE RealCID=@CID AND DateID >= 20260101 ORDER BY PaymentDate` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Index_Dividend_TaxReport | DividendID + DateID + Regulation + PositionType | Compare aggregate vs. customer-level |
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Symbol, InstrumentType |
| DWH_dbo.Dim_Date | DateID = DateID | Calendar attributes |
| BI_DB_DailyDividendsByPosition | DividendID + DateID + RealCID | Drill to individual position rows |

### 3.4 Gotchas

- **SP name typo**: SP is `SP_Index_Divident_TaxReport_CID_Level` ("Divident" missing 'e') — do not search for "Dividend" when looking for the writer SP
- **`[Currency Name]` column has a space**: Must use bracket quoting: `[Currency Name]` — not a standard identifier
- **Table starts Jan 2022, not 2019**: Unlike parent (`BI_DB_Index_Dividend_TaxReport` from 2019), this table has no pre-2022 history
- **HEAP — no clustered index**: Unlike parent (clustered on DateID), this table is a HEAP. Full-scans are expensive at 175M rows; always filter on DateID
- **CountPositions is per-customer**: Not comparable to parent's CountPositions (which sums across all customers). Sum this column across all RealCID for a dividend to replicate parent's CountPositions
- **TotalDividendPaid can be negative**: Dividend adjustments/corrections flow as negative amounts
- **Country='None' rows**: Small number (~1 per period) where Dim_Range resolution fails for the customer at @DateID
- **Grain includes RealCID**: Same DividendID+DateID+Regulation+PositionType will have one row per customer — do not de-duplicate carelessly

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from production source wiki (`etoro.Trade.IndexDividends` or `Customer.CustomerStatic` / `Dictionary.Country`) — passthrough |
| Tier 2 | From ETL SP code, DWH dimensions, or BI_DB intermediate tables |
| Tier 3 | ETL infrastructure (GETDATE(), system columns) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DividendID | int | YES | Corporate action / index dividend event identifier. FK to `etoro.Trade.IndexDividends`. Groups positions that share the same dividend declaration. (Tier 2 — SP_Index_Divident_TaxReport_CID_Level via BI_DB_DailyDividendsByPosition) |
| 2 | InstrumentID | int | YES | Instrument (stock/index) for which the dividend was declared. FK to `DWH_dbo.Dim_Instrument`. (Tier 2 — SP_Index_Divident_TaxReport_CID_Level via BI_DB_DailyDividendsByPosition) |
| 3 | InstrumentDisplayName | varchar(100) | YES | Display name of the instrument. Joined from `DWH_dbo.Dim_Instrument.InstrumentDisplayName` on InstrumentID. (Tier 2 — Dim_Instrument) |
| 4 | ISINCode | varchar(30) | YES | International Securities Identification Number. Joined from `DWH_dbo.Dim_Instrument.ISINCode` on InstrumentID. NULL for instruments without ISIN. (Tier 2 — Dim_Instrument) |
| 5 | PositionType | varchar(max) | YES | FK to Dictionary.PositionType. 0=CFD, 1=REAL, 255=ILLEGAL. Dividends split by position ownership model. See Section 2.4. (Tier 1 — Trade.IndexDividends) |
| 6 | TaxCode | varchar(40) | YES | Tax code/label for withholding. Passed from InsertIndexDividend; may map to jurisdiction. Top values: 6, 40, 0, 999, 8. (Tier 1 — Trade.IndexDividends) |
| 7 | EventType | varchar(40) | YES | Type of corporate action (e.g., dividend, special dividend). Values: Cash Dividend, Special Dividend, Dividend with Option, Return of Capital, Shares Premium Dividend. (Tier 1 — Trade.IndexDividends) |
| 8 | PaymentDate | datetime | YES | Date when the dividend was paid to customer positions, derived from `CAST(Fact_CustomerAction.Occurred AS DATE)` for ActionTypeID=35 on @DateID. Renamed from `[Date]` in source. (Tier 2 — SP_Index_Divident_TaxReport_CID_Level via BI_DB_DailyDividendsByPosition) |
| 9 | DividendValueInCurrency | money | YES | Dividend amount per share/unit in DividendCurrencyID. (Tier 1 — Trade.IndexDividends) |
| 10 | DividendCurrencyID | int | YES | FK to Dictionary.Currency. Currency of DividendValueInCurrency (USD, EUR, GBX, NOK, etc.). See [Currency Name] for display. (Tier 1 — Trade.IndexDividends) |
| 11 | BuyTax | decimal(6,4) | YES | Tax rate for buy-side (long) positions. CHECK: 0 to 1. Fraction, e.g., 0.15 = 15%. (Tier 1 — Trade.IndexDividends) |
| 12 | Status | tinyint | YES | Lifecycle: 0=Pending, 4=Correction Pending, 1=In Progress, 2=Completed. Predominantly 2 (completed) since BI_DB_DailyDividendsByPosition filters Status=2 at source. (Tier 1 — Trade.IndexDividends) |
| 13 | DateID | int | YES | YYYYMMDD integer of the dividend payment date. Primary filter key for date-range queries. Range: 20220101–20260411. (Tier 2 — SP_Index_Divident_TaxReport_CID_Level) |
| 14 | Regulation | varchar(40) | YES | Regulatory entity for the customer positions in this group (e.g., CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, BVI). From `Dim_Regulation.Name` via `BI_DB_DailyDividendsByPosition`. (Tier 2 — Dim_Regulation) |
| 15 | CountPositions | int | YES | Number of positions held by this specific RealCID that received this dividend on @DateID. ISNULL(COUNT(PositionID), 0) from `BI_DB_DailyDividendsByPosition`. Per-customer count (not across all customers). (Tier 2 — SP_Index_Divident_TaxReport_CID_Level) |
| 16 | TotalDividendPaid | money | YES | Total dividend amount credited to this customer for this event (SUM of Fact_CustomerAction.Amount for RealCID). ISNULL(SUM(Amount), 0). Can be negative for adjustments/corrections. (Tier 2 — SP_Index_Divident_TaxReport_CID_Level) |
| 17 | IsValidCustomer | bit | YES | Customer validity flag from snapshot at @DateID. From `Fact_SnapshotCustomer.IsValidCustomer` at report date. (Tier 2 — Fact_SnapshotCustomer via BI_DB_DailyDividendsByPosition) |
| 18 | IsCreditReportValidCB | bit | YES | Credit-report validity for CB regulatory reporting. From `Fact_SnapshotCustomer.IsCreditReportValidCB` at report date. (Tier 2 — Fact_SnapshotCustomer via BI_DB_DailyDividendsByPosition) |
| 19 | UpdateDate | datetime | YES | Batch timestamp set to GETDATE() at INSERT time. Reflects when SP ran, not when dividend occurred. (Tier 3 — GETDATE()) |
| 20 | IsBuy | int | YES | Position side: 1=Long/Buy, 0=Short/Sell. From `Dim_Position.IsBuy`. (Tier 2 — Dim_Position via BI_DB_DailyDividendsByPosition) |
| 21 | ExDate | date | YES | Ex-dividend date. Holder must own position on this date to receive dividend. CHECK: PaymentDate >= ExDate. Joined from `etoro_Trade_IndexDividends.ExDate` on DividendID. (Tier 1 — Trade.IndexDividends) |
| 22 | [Currency Name] | varchar(20) | YES | Currency abbreviation for dividend denomination (USD, EUR, GBP, GBX, NOK, etc.). Joined from `DWH_dbo.Dim_Currency.Abbreviation` on DividendCurrencyID. Column name contains a space — always bracket-quote: `[Currency Name]`. (Tier 2 — Dim_Currency) |
| 23 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Key differentiator from parent table — adds per-customer grain. (Tier 1 — Customer.CustomerStatic) |
| 24 | Country | varchar(100) | YES | Full country name in English of the customer's registered country at @DateID. Resolved via Fact_SnapshotCustomer → Dim_Range (SCD via BETWEEN FromDateID/ToDateID) → Dim_Country.Name. Top values: UK, Germany, Italy, France, Spain. Small number of 'None' rows where resolution fails. (Tier 1 — Dictionary.Country via Dim_Country) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| PositionType | etoro.Trade.IndexDividends | PositionType | Passthrough |
| TaxCode | etoro.Trade.IndexDividends | TaxCode | Passthrough |
| EventType | etoro.Trade.IndexDividends | EventType | Passthrough |
| DividendValueInCurrency | etoro.Trade.IndexDividends | DividendValueInCurrency | Passthrough |
| DividendCurrencyID | etoro.Trade.IndexDividends | DividendCurrencyID | Passthrough |
| BuyTax | etoro.Trade.IndexDividends | BuyTax | Passthrough |
| Status | etoro.Trade.IndexDividends | Status | Passthrough |
| ExDate | etoro.Trade.IndexDividends | ExDate | LEFT JOIN on DividendID |
| RealCID | Customer.CustomerStatic | CID | FK reference via Fact_CustomerAction |
| Country | Dictionary.Country | Name | JOIN Fact_SnapshotCustomer → Dim_Range → Dim_Country |
| DividendID | etoro.Trade.IndexDividends (via Fact_CustomerAction) | DividendID | FK reference |
| CountPositions | Fact_CustomerAction | PositionID | COUNT() per RealCID |
| TotalDividendPaid | Fact_CustomerAction | Amount | SUM() per RealCID |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | JOIN |
| ISINCode | DWH_dbo.Dim_Instrument | ISINCode | JOIN |
| [Currency Name] | DWH_dbo.Dim_Currency | Abbreviation | JOIN |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via BI_DB_DailyDividendsByPosition |
| UpdateDate | ETL | GETDATE() | Batch timestamp |

### 5.2 ETL Pipeline

```
etoro.Trade.IndexDividends (production OLTP — eToro DB)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_dbo.etoro_Trade_IndexDividends (External Table, Bronze/etoro/Trade/IndexDividends/)
                    |
                    +-- LEFT JOIN on DividendID (ExDate) --|
                    v
BI_DB_dbo.BI_DB_DailyDividendsByPosition (position-level dividends, also from Fact_CustomerAction)
  |-- SP_Index_Divident_TaxReport_CID_Level @Date (GROUP BY RealCID + JOIN Dim_Instrument, Dim_Currency) ---|
  |   (second JOIN step: Fact_SnapshotCustomer + Dim_Range + Dim_Country → Country)
  v
BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level (~175M rows, Jan 2022–Apr 2026)
  |-- (No UC target — Not Migrated) ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DividendID | BI_DB_DailyDividendsByPosition.DividendID | Source of per-customer position-level aggregation |
| RealCID | Customer.CustomerStatic.CID | Customer identity (via Fact_CustomerAction) |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| DividendCurrencyID | DWH_dbo.Dim_Currency | Currency for dividend value |
| Country (resolved) | DWH_dbo.Dim_Country.Name | Customer country at @DateID via Fact_SnapshotCustomer + Dim_Range |

### 6.2 Referenced By (other objects point to this)

| Object | How Used |
|--------|----------|
| BI_DB_Index_Dividend_TaxReport | Parent aggregate — same data without RealCID/Country breakdown |
| Finance/Tax/Compliance reporting | Per-customer dividend tax statements and regulatory reporting |

---

## 7. Sample Queries

### 7.1 Customer dividend summary for a specific date
```sql
SELECT RealCID, Country, Regulation, InstrumentDisplayName,
       SUM(CountPositions) AS Positions,
       SUM(TotalDividendPaid) AS TotalPaid
FROM [BI_DB_dbo].[BI_DB_Index_Dividend_TaxReport_CID_Level]
WHERE DateID = 20260411
GROUP BY RealCID, Country, Regulation, InstrumentDisplayName
ORDER BY TotalPaid DESC;
```

### 7.2 Per-country dividend totals YTD (REAL positions only)
```sql
SELECT Country, COUNT(DISTINCT RealCID) AS Customers,
       SUM(CountPositions) AS TotalPositions,
       SUM(TotalDividendPaid) AS TotalPaid
FROM [BI_DB_dbo].[BI_DB_Index_Dividend_TaxReport_CID_Level]
WHERE DateID >= 20260101
  AND PositionType = '1'  -- REAL positions
  AND IsValidCustomer = 1
GROUP BY Country
ORDER BY TotalPaid DESC;
```

### 7.3 Full dividend history for a specific customer (2026)
```sql
SELECT DividendID, InstrumentDisplayName, ISINCode,
       PaymentDate, ExDate, TaxCode, BuyTax,
       DividendValueInCurrency, [Currency Name],
       Regulation, CountPositions, TotalDividendPaid
FROM [BI_DB_dbo].[BI_DB_Index_Dividend_TaxReport_CID_Level]
WHERE RealCID = @CustomerCID
  AND DateID >= 20260101
ORDER BY PaymentDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this table.

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 10 T1, 13 T2, 1 T3, 0 T4, 0 T5 | Elements: 24/24, Logic: 4 subsections*
*Object: BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level | Type: Table | Production Source: etoro.Trade.IndexDividends via BI_DB_DailyDividendsByPosition (+ Country via Fact_SnapshotCustomer/Dim_Country)*
