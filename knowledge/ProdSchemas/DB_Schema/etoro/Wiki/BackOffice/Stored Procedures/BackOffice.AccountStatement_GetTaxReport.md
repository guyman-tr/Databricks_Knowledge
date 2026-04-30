# BackOffice.AccountStatement_GetTaxReport

> Generates a tax-categorized financial summary for a customer's account activity over a date range, returning P&L by asset class plus withholding-tax/interest data per jurisdiction.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary data source for generating a customer's annual tax report or account statement. It classifies all closed-position profits, dividends, fees, and compensation events into the tax categories required by most jurisdictions: CFD P&L, Crypto P&L, Real Stock P&L, ETF P&L, dividends, and commissions. Each category maps to a distinct tax treatment under European and global retail trading regulations.

The procedure exists because different asset classes and event types are taxed differently in most jurisdictions. A CFD profit, a real stock gain, a dividend payment, and a compensation bonus each require separate reporting lines on a tax statement. Without this aggregation, BackOffice agents and the customer-facing statement system would need to perform complex classification logic on raw `History.Credit` data every time a report is generated.

Data flows as follows: BackOffice queries this procedure for a specific customer and date range (typically a tax year). The procedure reads from `History.Credit` (actual cash events), joins to `Trade.GetPositionData` to resolve asset class (via `Dictionary.Currency.CurrencyTypeID` and `IsSettled`), and joins to `Dictionary.CreditType` for event classification. A second result set separately handles withholding-tax obligations by parsing structured text from `History.ActiveCredit` and cross-referencing with the customer's regulation history. This procedure has four versioned variants (`_v1`, `_v2`, `_v2_withDBLogs`, `_v3`) reflecting its evolution; this is the current canonical version.

---

## 2. Business Logic

### 2.1 Asset Class Classification via IsSettled + CurrencyTypeID

**What**: The SP distinguishes four taxable asset classes using two position attributes from `Trade.GetPositionData`.

**Columns/Parameters Involved**: `IsSettled`, `CurrencyTypeID` (from `Dictionary.Currency` via instrument lookup)

**Rules**:
- `IsSettled=0` (or NULL) = CFD position (Contract for Difference) - reported as CFDPnL or DividendsFromCFD
- `IsSettled=1` AND `CurrencyTypeID=5` = Real Stocks (8,600+ instruments e.g. AAPL, TSLA) - reported as RealStocksPnL
- `IsSettled=1` AND `CurrencyTypeID=6` = Real ETFs (650+ instruments) - reported as RealETFPnL
- `IsSettled=1` AND `CurrencyTypeID=10` = Crypto (630+ instruments e.g. BTC, ETH) - reported as CryptoPnL
- RedeemID is checked for CFD P&L: positions with a RedeemID (not 0/NULL) are excluded from CFDPnL (redeem events are reported separately)

**Diagram**:
```
CreditTypeID=4 (Close Position) row in History.Credit
        |
        v (join to Trade.GetPositionData -> Dictionary.Currency)
   IsSettled=0/NULL  ->  CurrencyTypeID irrelevant  ->  CFDPnL
   IsSettled=1       ->  CurrencyTypeID=5            ->  RealStocksPnL
   IsSettled=1       ->  CurrencyTypeID=6            ->  RealETFPnL
   IsSettled=1       ->  CurrencyTypeID=10           ->  CryptoPnL
```

### 2.2 CreditType-Based Event Classification

**What**: Financial events are routed to different output columns based on `Dictionary.CreditType.CreditTypeID`.

**Columns/Parameters Involved**: `CreditTypeID`, `Description`, `CompensationReasonID`

**Rules**:
- `CreditTypeID=4` (Close Position): source of all P&L and commission columns
- `CreditTypeID=6` (Compensation) with `CompensationReasonID<>57`: regular compensation payments to the customer (trading errors, satisfaction, promotions) - reported as Compensation
- `CreditTypeID=6` with `CompensationReasonID=57`: withholding tax/interest events - excluded from Result Set 1 Compensation, reported in Result Set 2
- `CreditTypeID=14` (End Of Week Fee) where `Description='Payment caused by dividend'`: dividend income - classified as DividendsFromReal or DividendsFromCFD based on IsSettled
- `CreditTypeID=14` where `Description<>'Payment caused by dividend'` AND `CreditTypeID=15` (Cashout Fee): operational fees - reported as Fees

### 2.3 Withholding Tax / Interest by Jurisdiction (Result Set 2)

**What**: A separate interest and withholding-tax summary per jurisdiction (regulation), required for customers in tax-treaty countries where eToro withholds tax at source.

**Columns/Parameters Involved**: `CompensationReasonID` (=57), `Description` (structured text), `History.BackOfficeCustomer.RegulationID`

**Rules**:
- Source: `History.ActiveCredit` where `CreditTypeID=6` AND `CompensationReasonID=57` AND `Description LIKE 'Gross amount: %Tax rate: %RegulationID:%'`
- The Description field contains structured data: `"Gross amount: {X}; Tax rate: {Y}; RegulationID: {Z}"`  - the SP uses SUBSTRING + PATINDEX to parse these three values
- Aggregated by TaxRate and RegulationID, then joined to `Dictionary.Regulation` for JurisdictionName
- Customer regulation history (`History.BackOfficeCustomer`) is checked to confirm the customer was active under each regulation during the date range
- Only regulations with a non-NULL JurisdictionName are returned (filters internal or placeholder regulations)

### 2.4 Placeholder Columns in Result Set 1

**What**: Result Set 1 contains three placeholder output columns that always return fixed values.

**Rules**:
- `J`: always NULL (VARCHAR(15)) - reserved column, no current business use
- `GrossAmount`: always CAST(0 AS MONEY) - placeholder, per-jurisdiction gross amounts are in Result Set 2
- `TaxRate`: always CAST(0 AS MONEY) - placeholder, per-jurisdiction tax rates are in Result Set 2
- These columns are vestigial from an earlier design where interest data was going to be included in Result Set 1

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to generate the tax report for. Filters all History.Credit, History.ActiveCredit, and History.BackOfficeCustomer records. Must match a valid customer. |
| 2 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting period (inclusive: `Occurred >= @StartDate`). Typically the first day of a tax year (e.g., 2023-01-01). |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the reporting period (exclusive: `Occurred < @EndDate`). Typically the first day of the following tax year (e.g., 2024-01-01). |

**Result Set 1 - Aggregate Tax Summary (one row):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | CFDPnL | MONEY | YES | - | VERIFIED | Sum of NetProfit from closed CFD positions (CreditTypeID=4, IsSettled=0/NULL, no redeem). Taxable as derivative/CFD income in most jurisdictions. |
| 5 | CryptoPnL | MONEY | YES | - | VERIFIED | Sum of NetProfit from closed real crypto positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=10). Taxable as capital gains on digital assets. |
| 6 | RealStocksPnL | MONEY | YES | - | VERIFIED | Sum of NetProfit from closed real stock positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=5). Taxable as equity capital gains. |
| 7 | RealETFPnL | MONEY | YES | - | VERIFIED | Sum of NetProfit from closed real ETF positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=6). Taxable as fund capital gains. |
| 8 | DividendsFromReal | MONEY | YES | - | VERIFIED | Sum of TotalCashChange from dividend payments on real stock/ETF positions (CreditTypeID=14, Description='Payment caused by dividend', IsSettled=1). Cash dividends from actual share ownership. |
| 9 | DividendsFromCFD | MONEY | YES | - | VERIFIED | Sum of TotalCashChange from dividend-equivalent adjustments on CFD positions (CreditTypeID=14, Description='Payment caused by dividend', IsSettled=0/NULL). CFD dividend adjustments (not actual dividends). |
| 10 | Compensation | MONEY | YES | - | VERIFIED | Sum of Payment from compensation credits (CreditTypeID=6, CompensationReasonID<>57). Excludes withholding tax entries (CompensationReasonID=57). Covers trading error refunds, satisfaction bonuses, etc. |
| 11 | CFDFullCommissionOnClose | MONEY | YES | - | VERIFIED | Sum of CommissionOnClose from closed CFD positions (CreditTypeID=4, IsSettled=0/NULL). Spread/overnight fees charged at position close. |
| 12 | CryptoFullCommissionOnClose | MONEY | YES | - | VERIFIED | Sum of CommissionOnClose from closed crypto positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=10). |
| 13 | RealStocksFullCommissionOnClose | MONEY | YES | - | VERIFIED | Sum of CommissionOnClose from closed real stock positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=5). |
| 14 | RealETFFullCommissionOnClose | MONEY | YES | - | VERIFIED | Sum of CommissionOnClose from closed real ETF positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=6). |
| 15 | Fees | MONEY | YES | - | VERIFIED | Sum of TotalCashChange from fee events (CreditTypeID IN (15,14)) excluding dividend payments. Covers Cashout Fees (CreditTypeID=15) and End-Of-Week fees not classified as dividends. |
| 16 | J | VARCHAR(15) | YES | NULL | CODE-BACKED | Placeholder column. Always returns NULL. Vestigial from earlier design; no current business use. |
| 17 | GrossAmount | MONEY | NO | 0 | CODE-BACKED | Placeholder column. Always returns 0. Per-jurisdiction gross amounts appear in Result Set 2. |
| 18 | TaxRate | MONEY | NO | 0 | CODE-BACKED | Placeholder column. Always returns 0. Per-jurisdiction tax rates appear in Result Set 2. |

**Result Set 2 - Withholding Tax by Jurisdiction (one row per regulation):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 19 | ID | INT | NO | - | CODE-BACKED | RegulationID from Dictionary.Regulation. Identifies the jurisdiction under which the withholding tax was applied. |
| 20 | JurisdictionName | NVARCHAR | YES | - | CODE-BACKED | Human-readable jurisdiction name from Dictionary.Regulation. Only rows with non-NULL JurisdictionName are returned. |
| 21 | Amount | MONEY | YES | - | VERIFIED | Sum of gross interest/dividend amounts (before tax) parsed from History.ActiveCredit Description string for CompensationReasonID=57 events under this regulation. |
| 22 | TaxRate | NVARCHAR | YES | - | VERIFIED | Tax rate (as string, e.g., "25.00") parsed from the structured Description field of History.ActiveCredit. Varies by regulation/treaty. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | History.Credit | Implicit | Filters all credit/debit events for the customer in the date range |
| CreditTypeID | Dictionary.CreditType | Lookup (JOIN) | Joins to get event type name; also used for CASE classification |
| @CID / PositionID | Trade.GetPositionData | Lookup (LEFT JOIN) | Retrieves instrument type (CurrencyTypeID), IsSettled, NetProfit, CommissionOnClose for position-close events |
| InstrumentID | Dictionary.Currency | Lookup (LEFT JOIN) | Resolves instrument CurrencyTypeID to distinguish stocks (5), ETFs (6), crypto (10) from CFDs |
| CompensationReasonID=57 | History.ActiveCredit | Implicit | Source of withholding-tax/interest records for Result Set 2 |
| @CID | History.BackOfficeCustomer | Lookup | Gets customer's regulation(s) active during the report period |
| RegulationID | Dictionary.Regulation | Lookup (JOIN) | Resolves regulation to JurisdictionName for Result Set 2 |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called directly from the BackOffice application layer to generate customer tax statements. Versioned variants (v1, v2, v2_withDBLogs, v3) exist as historical references.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AccountStatement_GetTaxReport (procedure)
|- History.Credit (table) [CTE HistoryCreditRecords - primary source]
|- Dictionary.CreditType (table) [JOIN for event classification]
|- Trade.GetPositionData (view/function) [LEFT JOIN for position data, asset class, P&L]
|- Dictionary.Currency (table) [LEFT JOIN to classify instrument type via CurrencyTypeID]
|- History.ActiveCredit (table) [CTE InterestRawData - withholding tax source]
|- History.BackOfficeCustomer (table) [CTE UserRegulation - customer regulation history]
+-- Dictionary.Regulation (table) [JOIN for JurisdictionName]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | Primary source: all cash events for @CID in date range (Result Set 1) |
| Dictionary.CreditType | Table | JOIN to get event type name; CASE logic classifies by CreditTypeID |
| Trade.GetPositionData | View/Function | LEFT JOIN to get InstrumentID, IsSettled, NetProfit, CommissionOnClose, CurrencyTypeID, RedeemID, CloseOccurred |
| Dictionary.Currency | Table | LEFT JOIN ON InstrumentID=CurrencyID to get CurrencyTypeID (5=stocks, 6=ETF, 10=crypto) |
| History.ActiveCredit | Table | Source for CompensationReasonID=57 (withholding tax) entries (Result Set 2) |
| History.BackOfficeCustomer | Table | Gets customer's active regulation(s) during the report period |
| Dictionary.Regulation | Table | JOIN to get JurisdictionName for each regulation in Result Set 2 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Called to generate customer tax reports and annual account statements |
| BackOffice.AccountStatement_GetTaxReport_v1 | Procedure | Older version (Pending documentation) |
| BackOffice.AccountStatement_GetTaxReport_v2 | Procedure | Older version (Pending documentation) |
| BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs | Procedure | Variant with DB logging (Pending documentation) |
| BackOffice.AccountStatement_GetTaxReport_v3 | Procedure | Newer version (Pending documentation) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Date range | Application | Date range is inclusive-start, exclusive-end: Occurred >= @StartDate AND Occurred < @EndDate |
| Description format | Application | Result Set 2 only processes Description matching 'Gross amount: %Tax rate: %RegulationID:%'; malformed entries are silently skipped (bug fixed 2020-01-29) |
| Jurisdiction filter | Application | Result Set 2 only returns jurisdictions with non-NULL JurisdictionName (WHERE JurisdictionName IS NOT NULL) |

---

## 8. Sample Queries

### 8.1 Get tax report for a customer for tax year 2023

```sql
-- Returns two result sets: aggregate P&L summary + withholding tax by jurisdiction
EXEC BackOffice.AccountStatement_GetTaxReport
    @CID = 12345,
    @StartDate = '2023-01-01',
    @EndDate = '2024-01-01'
```

### 8.2 Verify CreditType classifications used in this report

```sql
SELECT CreditTypeID, Name
FROM Dictionary.CreditType WITH (NOLOCK)
WHERE CreditTypeID IN (4, 6, 14, 15)
ORDER BY CreditTypeID
-- 4=Close Position, 6=Compensation, 14=End Of Week Fee, 15=Cashout Fee
```

### 8.3 Check instrument type distribution (stocks vs ETF vs crypto vs CFD)

```sql
SELECT CurrencyTypeID, COUNT(*) AS InstrumentCount
FROM Dictionary.Currency WITH (NOLOCK)
WHERE CurrencyTypeID IN (1, 2, 4, 5, 6, 10)
GROUP BY CurrencyTypeID
-- 1=Currency/Forex, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 14 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AccountStatement_GetTaxReport | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AccountStatement_GetTaxReport.sql*
