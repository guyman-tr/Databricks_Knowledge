# BackOffice.AccountStatement_GetTaxReport_v1

> Generates a single-result-set tax summary for a customer, returning one row per jurisdiction (regulation) with P&L by asset class, dividends, fees, and withholding-tax data merged into each jurisdiction row.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is an earlier version of the tax report generation pipeline. It covers the same financial data as the canonical `BackOffice.AccountStatement_GetTaxReport`: classifying closed-position P&L by asset class (CFD, Crypto, Real Stocks, Real ETF), dividends, fees, and compensation credits for a customer and date range. Unlike the canonical version's two-result-set design, v1 merges jurisdiction/withholding-tax data into a single result set - one row per jurisdiction (regulation) the customer was active under during the period, plus one NULL-jurisdiction row that carries the aggregate financial summary.

This version was the production implementation through mid-2020, when the COFKV-787/765 improvement project (July 2020) likely introduced the two-result-set design seen in the canonical version. The modification history on the file records bug fixes by Adi (Aug 2019, Jan 2020) and performance improvements (May 2020), culminating in Yulia's COFKV redesign (Jul 2020) and Ivan's COFKV-2658 fix (Dec 2021). It is superseded by `BackOffice.AccountStatement_GetTaxReport` (canonical) and `_v2`, but is retained as a reference and for any consumer that depends on the single-result-set contract.

Data flows as follows: BackOffice queries this procedure with a customer ID and date range. The procedure reads from `History.CreditWithFee` (the fee-inclusive credit view) as its primary source - this is the key structural difference from later versions which use `History.Credit`. It joins to `Dictionary.CreditType` for event classification and `Trade.GetPositionData` for asset-class resolution. Withholding-tax data is separately parsed from `History.ActiveCredit` (CompensationReasonID=57) and cross-referenced via `History.BackOfficeCustomer` to determine which jurisdictions applied during the period. All of this is merged into a single GROUP BY `i.ID` (regulation) output.

---

## 2. Business Logic

### 2.1 Asset Class Classification via IsSettled + CurrencyTypeID

**What**: Distinguishes four taxable asset classes using position attributes from `Trade.GetPositionData`.

**Columns/Parameters Involved**: `IsSettled`, `CurrencyTypeID` (from `Dictionary.Currency` via instrument lookup)

**Rules**:
- `IsSettled=0` (or NULL) = CFD position - reported as CFDPnL or DividendsFromCFD
- `IsSettled=1` AND `CurrencyTypeID=5` = Real Stocks - reported as RealStocksPnL / RealStocksFullCommissionOnClose
- `IsSettled=1` AND `CurrencyTypeID=6` = Real ETFs - reported as RealETFPnL / RealETFFullCommissionOnClose
- `IsSettled=1` AND `CurrencyTypeID=10` = Crypto - reported as CryptoPnL / CryptoFullCommissionOnClose
- RedeemID is checked for CFDPnL: positions with an active RedeemID (not 0/NULL, or RedeemStatus not 6) are excluded from CFDPnL; for CryptoPnL RedeemStatus=6 is included

**Diagram**:
```
CreditTypeID=4 (Close Position) in History.CreditWithFee
        |
        v (join to Trade.GetPositionData -> Dictionary.Currency)
   IsSettled=0/NULL  ->  any CurrencyTypeID  ->  CFDPnL / CFDFullCommissionOnClose
   IsSettled=1       ->  CurrencyTypeID=5    ->  RealStocksPnL / RealStocksFullCommissionOnClose
   IsSettled=1       ->  CurrencyTypeID=6    ->  RealETFPnL / RealETFFullCommissionOnClose
   IsSettled=1       ->  CurrencyTypeID=10   ->  CryptoPnL / CryptoFullCommissionOnClose
```

### 2.2 CreditType-Based Event Classification

**What**: Routes financial events to different output columns based on `CreditTypeID` and `Description`.

**Columns/Parameters Involved**: `CreditTypeID`, `Description`, `CompensationReasonID`

**Rules**:
- `CreditTypeID=4` (Close Position): source of all P&L and CommissionOnClose aggregations
- `CreditTypeID=6` with `CompensationReasonID<>57`: regular compensation - reported as Compensation
- `CreditTypeID=6` with `CompensationReasonID=57`: withholding tax events - excluded from Compensation; their structured data is parsed separately in the InterestRawData CTE
- `CreditTypeID=14` where `Description='Payment caused by dividend'`: dividend payments, split by IsSettled
- `CreditTypeID IN (15, 14)` where `Description<>'Payment caused by dividend'`: operational fees - reported as Fees

### 2.3 Single Result Set with Per-Jurisdiction Row Design

**What**: Unlike the canonical version's two-result-set design, v1 merges the jurisdiction/withholding-tax summary into the financial aggregation rows via GROUP BY regulation.

**Columns/Parameters Involved**: `i.ID` (RegulationID), `J` (JurisdictionName), `GrossAmount`, `TaxRate`

**Rules**:
- The LEFT JOIN to `InterestSummary` produces one row per regulation the customer was active under
- An additional row with `i.ID = NULL` is produced for credit events not matched to any regulation row
- For regulation rows (`i.ID <> 0`): J = jurisdiction name, GrossAmount = withholding-tax gross amount, TaxRate = tax rate
- For the NULL row: J = NULL, GrossAmount = 0, TaxRate = 0
- Callers must sum across all rows for financial totals or filter by i.ID for per-jurisdiction tax data

**Diagram**:
```
Result row 1: i.ID=NULL  -> all financial totals (CFDPnL, etc.) + J=NULL, GrossAmount=0, TaxRate=0
Result row 2: i.ID=5     -> same financial totals (LEFT JOIN, repeated) + J='Germany', GrossAmount=X, TaxRate=25%
Result row 3: i.ID=12    -> same financial totals (repeated) + J='Italy', GrossAmount=Y, TaxRate=20%
```

### 2.4 CreditWithFee as Primary Source (vs History.Credit)

**What**: v1 reads from `History.CreditWithFee` rather than `History.Credit`, providing fee-inclusive data in a single source.

**Rules**:
- `History.CreditWithFee` presumably includes the raw credit records with the `CommissionOnClose` and fee columns pre-joined or pre-computed
- Bug fix note (Aug 2019): "Using TotalCashChange instead of payment, because when fees are caused by mirrored position payment is 0, but TotalCashChange is not" - this is encoded in the CTE logic and was a driver for the CreditWithFee approach

### 2.5 Withholding Tax Parsing from Description String

**What**: Withholding-tax amounts, rates, and regulation IDs are embedded as structured text in `History.ActiveCredit.Description` and parsed at query time.

**Rules**:
- Source: `History.ActiveCredit` where `CreditTypeID=6` AND `CompensationReasonID=57` AND `Description LIKE 'Gross amount: %Tax rate: %RegulationID:%'`
- PATINDEX + SUBSTRING extracts three fields: `Gross amount: {X}`, `Tax rate: {Y}`, `RegulationID: {Z}`
- Bug fix (Jan 2020): descriptions with unexpected structure no longer cause runtime errors; malformed entries are silently skipped
- Aggregated by TaxRate and RegulationID before joining to `Dictionary.Regulation`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to generate the tax report for. Filters all History.CreditWithFee, History.ActiveCredit, and History.BackOfficeCustomer records. |
| 2 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting period (inclusive: `Occurred >= @StartDate`). Typically the first day of a tax year (e.g., 2023-01-01). |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the reporting period (exclusive: `Occurred < @EndDate`). Typically the first day of the following tax year (e.g., 2024-01-01). |

**Result Set - Combined Tax Summary (one row per jurisdiction + one NULL row):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | ID | INT | YES | - | CODE-BACKED | RegulationID from Dictionary.Regulation / InterestSummary CTE. NULL on the base aggregate row. Non-NULL rows each represent a jurisdiction under which withholding tax was applied. Grouped on in the final SELECT. |
| 5 | CFDPnL | MONEY | YES | - | VERIFIED | Sum of NetProfit from closed CFD positions (CreditTypeID=4, IsSettled=0/NULL, RedeemID=0 or NULL). Taxable as derivative/CFD income. |
| 6 | CryptoPnL | MONEY | YES | - | VERIFIED | Sum of NetProfit from closed real crypto positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=10, RedeemID=0/NULL or RedeemStatus=6). Taxable as capital gains on digital assets. |
| 7 | RealStocksPnL | MONEY | YES | - | VERIFIED | Sum of NetProfit from closed real stock positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=5). Taxable as equity capital gains. |
| 8 | RealETFPnL | MONEY | YES | - | VERIFIED | Sum of NetProfit from closed real ETF positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=6). Taxable as fund capital gains. |
| 9 | DividendsFromReal | MONEY | YES | - | VERIFIED | Sum of TotalCashChange from dividend payments on real positions (CreditTypeID=14, Description='Payment caused by dividend', IsSettled=1). Cash dividends from actual share ownership. |
| 10 | DividendsFromCFD | MONEY | YES | - | VERIFIED | Sum of TotalCashChange from dividend-equivalent adjustments on CFD positions (CreditTypeID=14, Description='Payment caused by dividend', IsSettled=0/NULL). CFD dividend adjustments. |
| 11 | Compensation | MONEY | YES | - | VERIFIED | Sum of Payment from compensation credits (CreditTypeID=6, CompensationReasonID<>57). Excludes withholding-tax entries (CompensationReasonID=57). Covers trading error refunds, satisfaction bonuses. |
| 12 | CFDFullCommissionOnClose | MONEY | YES | - | VERIFIED | Sum of CommissionOnClose from closed CFD positions (CreditTypeID=4, IsSettled=0/NULL). Spread and overnight fees charged at close. |
| 13 | CryptoFullCommissionOnClose | MONEY | YES | - | VERIFIED | Sum of CommissionOnClose from closed crypto positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=10). |
| 14 | RealStocksFullCommissionOnClose | MONEY | YES | - | VERIFIED | Sum of CommissionOnClose from closed real stock positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=5). |
| 15 | RealETFFullCommissionOnClose | MONEY | YES | - | VERIFIED | Sum of CommissionOnClose from closed real ETF positions (CreditTypeID=4, IsSettled=1, CurrencyTypeID=6). |
| 16 | Fees | MONEY | YES | - | VERIFIED | Sum of TotalCashChange from fee events (CreditTypeID IN (15,14)) excluding dividend payments. Covers Cashout Fees (CreditTypeID=15) and End-Of-Week fees not classified as dividends. |
| 17 | J | VARCHAR(15) | YES | NULL | CODE-BACKED | JurisdictionName for the row's regulation when ID <> 0. NULL on the aggregate row or when no regulation matched. Uses `MAX(CASE WHEN isnull(i.ID,0)<>0 THEN i.JurisdictionName)`. |
| 18 | GrossAmount | MONEY | YES | 0 | CODE-BACKED | Sum of gross interest/dividend amounts (before withholding tax) for the row's jurisdiction when ID <> 0. 0 on the NULL-jurisdiction aggregate row. |
| 19 | TaxRate | MONEY | YES | 0 | CODE-BACKED | Sum of parsed tax rates for the row's jurisdiction when ID <> 0. 0 on the NULL-jurisdiction aggregate row. Note: TaxRate is parsed as string in InterestRawData CTE and CAST to MONEY in the aggregate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | History.CreditWithFee | Implicit | Primary source of all cash events (fee-inclusive) for the customer in the date range |
| CreditTypeID | Dictionary.CreditType | Lookup (JOIN) | Joined in RawData CTE to get event type name; CreditTypeID used in CASE classification logic |
| @CID / PositionID | Trade.GetPositionData | Lookup (LEFT JOIN) | Retrieves InstrumentID, IsSettled, NetProfit, CommissionOnClose, CurrencyTypeID, RedeemID for position-close events |
| InstrumentID | Dictionary.Currency | Lookup (LEFT JOIN) | Resolves instrument CurrencyTypeID to distinguish stocks (5), ETFs (6), crypto (10) from CFDs |
| CompensationReasonID=57 | History.ActiveCredit | Implicit | Source for withholding-tax/interest records parsed in InterestRawData CTE |
| @CID | History.BackOfficeCustomer | Lookup | Gets customer's active regulation(s) during the report period (UserRegulation CTE) |
| RegulationID | Dictionary.Regulation | Lookup (JOIN) | Resolves regulation to JurisdictionName for the merged output |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found in SSDT. Called directly from the BackOffice application layer as an older version of the tax report pipeline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AccountStatement_GetTaxReport_v1 (procedure)
|- History.CreditWithFee (table/view) [CTE HistoryCreditRecords - primary source, fee-inclusive]
|- Dictionary.CreditType (table) [JOIN in RawData CTE for event classification]
|- Trade.GetPositionData (view) [LEFT JOIN for asset class, P&L, IsSettled, CurrencyTypeID]
|- Dictionary.Currency (table) [LEFT JOIN ON InstrumentID=CurrencyID for CurrencyTypeID]
|- History.ActiveCredit (table) [CTE InterestRawData - withholding tax source]
|- History.BackOfficeCustomer (table) [CTE UserRegulation - regulation history]
+-- Dictionary.Regulation (table) [JOIN for JurisdictionName in InterestSummary CTE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CreditWithFee | Table/View | Primary source: fee-inclusive cash events for @CID in date range |
| Dictionary.CreditType | Table | JOIN in RawData CTE to get event type name; CreditTypeID used in all CASE logic |
| Trade.GetPositionData | View | LEFT JOIN to get InstrumentID, IsSettled, NetProfit, CommissionOnClose, CurrencyTypeID, RedeemID, CloseOccurred |
| Dictionary.Currency | Table | LEFT JOIN ON InstrumentID=CurrencyID to get CurrencyTypeID (5=stocks, 6=ETF, 10=crypto) |
| History.ActiveCredit | Table | Source for CompensationReasonID=57 withholding-tax entries in InterestRawData CTE |
| History.BackOfficeCustomer | Table | Customer regulation history for UserRegulation CTE (date range overlap logic) |
| Dictionary.Regulation | Table | JOIN to get JurisdictionName for merged jurisdiction rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Called as older tax report generation endpoint; superseded by canonical version |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Date range | Application | Inclusive-start, exclusive-end: `Occurred >= @StartDate AND Occurred < @EndDate` |
| Description format | Application | Withholding-tax CTE only processes Description matching `'Gross amount: %Tax rate: %RegulationID:%'`; malformed entries silently skipped (bug fixed 2020-01-29) |
| Jurisdiction filter | Application | InterestSummary CTE: `WHERE JurisdictionName IS NOT NULL` - only returned jurisdictions with valid names |
| Single result set | Design | All data merged into one SELECT grouped by i.ID; callers must handle the NULL-jurisdiction aggregate row |

---

## 8. Sample Queries

### 8.1 Get tax report for a customer for tax year 2023

```sql
-- Returns one row per jurisdiction + one NULL row aggregate
EXEC BackOffice.AccountStatement_GetTaxReport_v1
    @CID = 12345,
    @StartDate = '2023-01-01',
    @EndDate = '2024-01-01'
```

### 8.2 Sum all P&L across jurisdiction rows (correct aggregation pattern)

```sql
-- Because the LEFT JOIN to InterestSummary repeats financial data per jurisdiction,
-- aggregate only the NULL row for the financial totals, or SUM and divide by row count
-- The safest approach is to filter on the aggregate (NULL) jurisdiction row:
EXEC BackOffice.AccountStatement_GetTaxReport_v1 @CID = 12345, @StartDate = '2023-01-01', @EndDate = '2024-01-01'
-- Then filter result: WHERE ID IS NULL for financial totals, WHERE ID IS NOT NULL for tax jurisdiction data
```

### 8.3 Compare CreditType classifications used in both result sets

```sql
SELECT CreditTypeID, Name
FROM Dictionary.CreditType WITH (NOLOCK)
WHERE CreditTypeID IN (4, 6, 14, 15)
ORDER BY CreditTypeID
-- 4=Close Position, 6=Compensation, 14=End Of Week Fee, 15=Cashout Fee
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 11 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AccountStatement_GetTaxReport_v1 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AccountStatement_GetTaxReport_v1.sql*
