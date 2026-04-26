# BI_DB_dbo.BI_DB_Index_Dividend_TaxReport

> 934K-row daily index dividend tax report aggregating position-level dividends into instrument×regulation×tax-code grain (Jan 2019–Apr 2026, 22 cols). Written by `SP_Index_Divident_TaxReport` (note: "Divident" typo in SP name) from `BI_DB_DailyDividendsByPosition` grouped by dividend event, enriched with instrument metadata and ex-date from `etoro.Trade.IndexDividends`. Supports tax-reporting and dividend reconciliation workflows.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_DailyDividendsByPosition` ← `etoro.Trade.IndexDividends` via SP_Index_Divident_TaxReport |
| **Refresh** | Daily SB_Daily (DELETE WHERE DateID=@DateID + INSERT, date-keyed incremental) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Dana Shamsutdinova (2020-12-14) |
| **Row Count** | ~934K (Jan 2019 – Apr 2026) |

---

## 1. Business Meaning

`BI_DB_Index_Dividend_TaxReport` is the daily dividend tax-reporting table for the BI/Finance team. Each row represents one dividend event (DividendID) for an instrument, aggregated across all customer positions that received a dividend credit on that date, broken down by regulation entity and position type (CFD vs. REAL). It answers: "How many positions received this dividend on this date, and what was the total amount paid, by instrument, regulation, tax code, and event type?"

The table spans Jan 2019 to Apr 2026 (~934K rows). The grain is: `DateID` + `DividendID` + `Regulation` (implied by the GROUP BY in the SP — each combination gets its own row). `CountPositions` is the count of individual position-level rows in `BI_DB_DailyDividendsByPosition`, and `TotalDividendPaid` is the SUM of customer action amounts. Status=2 (97%) means dividend completed/paid; Status=1 (0.2%) means in-progress; NULL (2.5%) means no IndexDividend match (early 2019 rows before full index dividend tracking).

Early rows (2019) have NULL for TaxCode, EventType, BuyTax, Status, IsBuy, ExDate, and `[Currency Name]` — these columns were added to the SP on 2021-10-07. The SP name contains a known typo ("Divident" instead of "Dividend") that has been carried forward since creation.

---

## 2. Business Logic

### 2.1 Grain and Aggregation

**What**: The report aggregates position-level rows from `BI_DB_DailyDividendsByPosition` into a summary grain per dividend event.

**Columns Involved**: DividendID, InstrumentID, Regulation, IsValidCustomer, IsCreditReportValidCB, DateID, CountPositions, TotalDividendPaid

**Rules**:
- `CountPositions = ISNULL(COUNT(PositionID), 0)` — positions that received the dividend on @DateID
- `TotalDividendPaid = ISNULL(SUM(Amount), 0)` — total dividend credited across those positions (can be negative for adjustments)
- GROUP BY includes all non-aggregated columns (DividendID, InstrumentID, Regulation, PositionType, TaxCode, EventType, etc.)
- ROUND_ROBIN distribution means analysts should join on DividendID or DateID for best performance

### 2.2 Status and Event Lifecycle

**What**: Status reflects the index dividend processing lifecycle from `Trade.IndexDividends`.

**Columns Involved**: Status, EventType, PositionType, ExDate, PaymentDate

**Rules**:
- Status=2 (97%): Dividend completed and paid to positions
- Status=1 (0.2%): Dividend in-progress at time of snapshot
- Status=NULL (2.5%): Row had no `etoro_Trade_IndexDividends` match (early 2019 data, or non-indexed dividends)
- `BI_DB_DailyDividendsByPosition` already filters `etoro_Trade_IndexDividends.Status = 2` at source — so Status=1 rows in this table likely come from rows that were in-progress at `BI_DB_DailyDividendsByPosition` load time
- EventType distribution: Cash Dividend (86%), Special Dividend (1.2%), Dividend with Option (0.8%), Return of Capital (0.3%), Shares Premium Dividend (0.2%)

### 2.3 Tax and Position Type

**What**: TaxCode and PositionType drive tax reporting logic per jurisdiction.

**Columns Involved**: TaxCode, BuyTax, PositionType, IsBuy, DividendCurrencyID, DividendValueInCurrency

**Rules**:
- PositionType=1 (54%): REAL stock positions (actual stock holders)
- PositionType=0 (46%): CFD positions (synthetic holders)
- BuyTax: fraction rate 0.0–1.0 (e.g., 0.15 = 15% withholding). CHECK in production: 0 to 1.
- IsBuy=1 (90%): long positions received dividend; IsBuy=0 (10%): short positions
- `[Currency Name]`: abbreviation of the dividend currency (USD, EUR, GBP, GBX, etc.) from `Dim_Currency.Abbreviation`
- TaxCode is a varchar jurisdiction code (e.g., '6', '40', '0', '999', '8') — values from upstream; '999'/'998'/'997'/'996' appear to be special/error codes

### 2.4 Column Addition History

**What**: Not all columns were present at launch; NULL columns in early rows reveal the addition timeline.

**Rules**:
- 2020-12-14: Initial columns (DividendID through TotalDividendPaid, IsValidCustomer, IsCreditReportValidCB, UpdateDate)
- 2021-10-07: Added IsBuy, ExDate, `[Currency Name]`
- Rows before the addition date will have NULL for the later-added columns

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution: ROUND_ROBIN — no data-locality benefit from any join column. Clustered index on DateID provides efficient date-range scans. For best performance, always filter on DateID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Total dividends paid by regulation for a date | `SELECT Regulation, SUM(TotalDividendPaid) WHERE DateID=@D GROUP BY Regulation` |
| Dividend events for an instrument YTD | `SELECT DISTINCT DividendID, PaymentDate, TotalDividendPaid WHERE InstrumentID=@I AND DateID >= 20260101` |
| Positions receiving dividends by EventType | `SELECT EventType, SUM(CountPositions), SUM(TotalDividendPaid) WHERE DateID >= 20260101 GROUP BY EventType` |
| Tax report by TaxCode and Regulation | `SELECT TaxCode, Regulation, BuyTax, SUM(TotalDividendPaid) GROUP BY TaxCode, Regulation, BuyTax` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Symbol, InstrumentType (already denormalized as InstrumentDisplayName) |
| DWH_dbo.Dim_Date | DateID = DateID | Calendar attributes |
| BI_DB_DailyDividendsByPosition | DividendID + DateID | Drill down to position-level detail |
| DWH_dbo.Dim_Currency | DividendCurrencyID = CurrencyID | Full currency name (already denormalized as [Currency Name]) |

### 3.4 Gotchas

- **SP name typo**: SP is `SP_Index_Divident_TaxReport` ("Divident" missing 'e') — do not search for "Dividend" when looking for the writer SP
- **`[Currency Name]` column has a space**: Must use bracket quoting: `[Currency Name]` — not a standard identifier
- **NULL columns in early 2019 rows**: IsBuy, ExDate, `[Currency Name]`, TaxCode, EventType, BuyTax, Status are NULL for rows before 2021-10-07 enrichment. Filter DateID > 20210101 for complete data.
- **TotalDividendPaid can be negative**: BT Group example (-27.65) shows dividend adjustments/corrections flow as negative amounts
- **Grain is DividendID×DateID×Regulation×PositionType**: Same DividendID can appear multiple times if positions span multiple regulations
- **ROUND_ROBIN with no unique key**: Duplicate DividendID+DateID rows exist for different Regulation values — do not de-duplicate carelessly

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from production source wiki (`etoro.Trade.IndexDividends`) — passthrough |
| Tier 2 | From ETL SP code, DWH dimensions, or BI_DB intermediate tables |
| Tier 3 | ETL infrastructure (GETDATE(), system columns) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DividendID | int | YES | Corporate action / index dividend event identifier. FK to `etoro.Trade.IndexDividends`. Groups positions that share the same dividend declaration. (Tier 2 — SP_Index_Divident_TaxReport via BI_DB_DailyDividendsByPosition) |
| 2 | InstrumentID | int | YES | Instrument (stock/index) for which the dividend was declared. FK to `DWH_dbo.Dim_Instrument`. (Tier 2 — SP_Index_Divident_TaxReport via BI_DB_DailyDividendsByPosition) |
| 3 | InstrumentDisplayName | varchar(100) | YES | Display name of the instrument. Joined from `DWH_dbo.Dim_Instrument.InstrumentDisplayName` on InstrumentID. (Tier 2 — Dim_Instrument) |
| 4 | ISINCode | varchar(30) | YES | International Securities Identification Number. Joined from `DWH_dbo.Dim_Instrument.ISINCode` on InstrumentID. NULL for instruments without ISIN. (Tier 2 — Dim_Instrument) |
| 5 | PositionType | varchar(max) | YES | FK to Dictionary.PositionType. 0=CFD, 1=REAL, 255=ILLEGAL. Dividends split by position ownership model. See Section 2.1. Distribution: 1=54%, 0=46%. (Tier 1 — Trade.IndexDividends) |
| 6 | TaxCode | varchar(40) | YES | Tax code/label for withholding. Passed from InsertIndexDividend; may map to jurisdiction. Top values: 6, 40, 0, 999, 8. NULL for pre-2021-10-07 rows. (Tier 1 — Trade.IndexDividends) |
| 7 | EventType | varchar(40) | YES | Type of corporate action (e.g., dividend, special dividend). Passed from InsertIndexDividend. Values: Cash Dividend, Special Dividend, Dividend with Option, Return of Capital, Shares Premium Dividend. NULL for pre-2021 rows. (Tier 1 — Trade.IndexDividends) |
| 8 | PaymentDate | datetime | YES | Date when the dividend was paid to customer positions, derived from `CAST(Fact_CustomerAction.Occurred AS DATE)` for ActionTypeID=35 on @DateID. Renamed from `[Date]` in source. Aligns with `Trade.IndexDividends.PaymentDate` conceptually. (Tier 2 — SP_Index_Divident_TaxReport via BI_DB_DailyDividendsByPosition) |
| 9 | DividendValueInCurrency | money | YES | Dividend amount per share/unit in DividendCurrencyID. (Tier 1 — Trade.IndexDividends) |
| 10 | DividendCurrencyID | int | YES | FK to Dictionary.Currency. Currency of DividendValueInCurrency (USD, EUR, GBX, NOK, etc.). See [Currency Name] for display. (Tier 1 — Trade.IndexDividends) |
| 11 | BuyTax | decimal(6,4) | YES | Tax rate for buy-side (long) positions. CHECK: 0 to 1. Fraction, e.g., 0.15 = 15%. NULL for pre-2021-10-07 rows. (Tier 1 — Trade.IndexDividends) |
| 12 | Status | tinyint | YES | Lifecycle: 0=Pending, 4=Correction Pending, 1=In Progress, 2=Completed. See Section 2.1. DWH note: predominantly 2 (completed) since BI_DB_DailyDividendsByPosition filters Status=2 at source. NULL rows had no IndexDividend match. Distribution: 2=97%, NULL=2.5%, 1=0.2%. (Tier 1 — Trade.IndexDividends) |
| 13 | DateID | int | YES | YYYYMMDD integer of the dividend payment date. Partition/cluster key for date-range queries. Range: 20190101–20260411. (Tier 2 — SP_Index_Divident_TaxReport) |
| 14 | Regulation | varchar(40) | YES | Regulatory entity for the customer positions in this group (e.g., CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, BVI). From `Dim_Regulation.Name` via `BI_DB_DailyDividendsByPosition`. (Tier 2 — Dim_Regulation) |
| 15 | CountPositions | int | YES | Number of customer positions that received this dividend on @DateID. ISNULL(COUNT(PositionID), 0) from `BI_DB_DailyDividendsByPosition`. (Tier 2 — SP_Index_Divident_TaxReport) |
| 16 | TotalDividendPaid | money | YES | Total dividend amount credited across all positions (SUM of Fact_CustomerAction.Amount). ISNULL(SUM(Amount), 0). Can be negative for adjustments/corrections. (Tier 2 — SP_Index_Divident_TaxReport) |
| 17 | IsValidCustomer | bit | YES | Customer validity flag from snapshot at @DateID. True=84.5%, False=15.5%. From `Fact_SnapshotCustomer.IsValidCustomer` at report date. (Tier 2 — Fact_SnapshotCustomer via BI_DB_DailyDividendsByPosition) |
| 18 | IsCreditReportValidCB | bit | YES | Credit-report validity for CB regulatory reporting. From `Fact_SnapshotCustomer.IsCreditReportValidCB` at report date. Distribution aligned with IsValidCustomer (84.5% True). (Tier 2 — Fact_SnapshotCustomer via BI_DB_DailyDividendsByPosition) |
| 19 | UpdateDate | datetime | YES | Batch timestamp set to GETDATE() at INSERT time. Reflects when SP ran, not when dividend occurred. (Tier 3 — GETDATE()) |
| 20 | IsBuy | int | YES | Position side: 1=Long/Buy, 0=Short/Sell. From `Dim_Position.IsBuy`. NULL for pre-2021-10-07 rows. Distribution: 1=89.7%, 0=10.3%. (Tier 2 — Dim_Position via BI_DB_DailyDividendsByPosition) |
| 21 | ExDate | date | YES | Ex-dividend date. Holder must own position on this date to receive dividend. CHECK: PaymentDate >= ExDate. Joined directly from `etoro_Trade_IndexDividends.ExDate` on DividendID. NULL for pre-2021-10-07 rows. (Tier 1 — Trade.IndexDividends) |
| 22 | [Currency Name] | varchar(20) | YES | Currency abbreviation for dividend denomination (USD, EUR, GBP, GBX, NOK, etc.). Joined from `DWH_dbo.Dim_Currency.Abbreviation` on DividendCurrencyID. Column name contains a space — always bracket-quote: `[Currency Name]`. NULL for pre-2021-10-07 rows. (Tier 2 — Dim_Currency) |

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
| DividendID | etoro.Trade.IndexDividends (via Fact_CustomerAction) | DividendID | FK reference |
| CountPositions | Fact_CustomerAction | PositionID | COUNT() |
| TotalDividendPaid | Fact_CustomerAction | Amount | SUM() |
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
  |-- SP_Index_Divident_TaxReport @Date (GROUP BY + JOIN Dim_Instrument, Dim_Currency) ---|
  v
BI_DB_dbo.BI_DB_Index_Dividend_TaxReport (~934K rows, Jan 2019–Apr 2026)
  |-- (No UC target — Not Migrated) ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DividendID | BI_DB_DailyDividendsByPosition.DividendID | Source of position-level aggregation |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| DividendCurrencyID | DWH_dbo.Dim_Currency | Currency for dividend value |

### 6.2 Referenced By (other objects point to this)

| Object | How Used |
|--------|----------|
| SP_IndexDividend_Alert | Reads BuyTax NULL indicator for 30-day monitoring window; writes to BI_DB_IndexDividends_Alert |
| Finance/Tax reporting | Downstream tax reporting and reconciliation |

---

## 7. Sample Queries

### 7.1 Dividend summary by regulation for a specific date
```sql
SELECT Regulation, EventType, SUM(CountPositions) AS TotalPositions, SUM(TotalDividendPaid) AS TotalPaid
FROM [BI_DB_dbo].[BI_DB_Index_Dividend_TaxReport]
WHERE DateID = 20260411
GROUP BY Regulation, EventType
ORDER BY TotalPaid DESC;
```

### 7.2 Real stock dividends with tax details (2026 YTD)
```sql
SELECT InstrumentDisplayName, ISINCode, PaymentDate, ExDate,
       TaxCode, BuyTax, DividendValueInCurrency, [Currency Name],
       SUM(CountPositions) AS Positions, SUM(TotalDividendPaid) AS TotalPaid
FROM [BI_DB_dbo].[BI_DB_Index_Dividend_TaxReport]
WHERE DateID >= 20260101
  AND PositionType = '1'  -- REAL positions
  AND IsValidCustomer = 1
GROUP BY InstrumentDisplayName, ISINCode, PaymentDate, ExDate, TaxCode, BuyTax, DividendValueInCurrency, [Currency Name]
ORDER BY PaymentDate DESC;
```

### 7.3 Negative dividend adjustments (corrections)
```sql
SELECT DividendID, InstrumentDisplayName, Regulation, PaymentDate,
       CountPositions, TotalDividendPaid
FROM [BI_DB_dbo].[BI_DB_Index_Dividend_TaxReport]
WHERE TotalDividendPaid < 0
ORDER BY TotalDividendPaid ASC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this table.

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 8 T1, 12 T2, 1 T3, 0 T4, 0 T5 | Elements: 22/22, Logic: 4 subsections*
*Object: BI_DB_dbo.BI_DB_Index_Dividend_TaxReport | Type: Table | Production Source: etoro.Trade.IndexDividends via BI_DB_DailyDividendsByPosition*
