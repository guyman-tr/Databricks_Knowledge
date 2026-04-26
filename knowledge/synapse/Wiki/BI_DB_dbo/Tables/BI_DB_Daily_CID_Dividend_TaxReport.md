# BI_DB_dbo.BI_DB_Daily_CID_Dividend_TaxReport

> 723.5M-row dividend tax report tracking per-position dividend payments with tax codes and rates for 2.6M distinct customers and 104K distinct dividend events across January 2019 to present. Refreshed daily by SP_Daily_CID_Dividend_TaxReport via DELETE+INSERT for the execution date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_DailyDividendsByPosition (dividend details) + DWH_dbo.Dim_Instrument (instrument metadata) via SP_Daily_CID_Dividend_TaxReport |
| **Refresh** | Daily (SB_Daily, Priority 0). DELETE PaymentDate=@Date → INSERT aggregated dividends |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (PaymentDate ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_Daily_CID_Dividend_TaxReport` is the core dividend tax reporting table, aggregating dividend payments per customer, per position, per dividend event, with tax classification. It is built from `BI_DB_DailyDividendsByPosition` (the position-level dividend detail) with instrument enrichment from `Dim_Instrument` (display name, ISIN code).

The grain is (RealCID, DividendID, PositionID, TaxCode) — one row per customer per position per dividend event per tax code. The TotalDividendPaid column is the SUM of individual dividend amounts (the only aggregation applied). This table supports tax reporting, withholding tax calculations, and regulatory dividend disclosure requirements.

The SP is straightforward: it filters `BI_DB_DailyDividendsByPosition` for a single DateID, joins to `Dim_Instrument` for display name and ISIN, aggregates by all non-amount columns, and performs DELETE+INSERT for the payment date.

---

## 2. Business Logic

### 2.1 Tax Classification

**What**: Each dividend payment is tagged with a TaxCode and BuyTax rate that determine withholding tax treatment.
**Columns Involved**: `TaxCode`, `BuyTax`
**Rules**:
- TaxCode: Identifies the tax jurisdiction/classification (e.g., '6', '33', '999', '0')
- BuyTax: Decimal rate applied to the dividend (e.g., 0.3000=30%, 0.1500=15%, 0.2500=25%, 0.0000=0%)
- Both are passthrough from BI_DB_DailyDividendsByPosition

### 2.2 Position Type Classification

**What**: Positions are classified by type and settlement status.
**Columns Involved**: `PositionType`, `IsSettled`
**Rules**:
- PositionType: '0' (CFD), '1' (Real/Settled), '' (empty/legacy)
- IsSettled: True=real asset (stocks held), False=CFD (contract for difference)
- Real (settled) and CFD positions may have different tax treatment

### 2.3 Dividend Aggregation

**What**: Individual dividend amounts are summed per unique combination of all dimension columns.
**Columns Involved**: `TotalDividendPaid`
**Rules**:
- `SUM(bdddbp.Amount)` grouped by all other columns
- This means if a customer has multiple dividend line items for the same position/dividend/tax code, they are aggregated

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on PaymentDate. Date-range queries are very efficient. This is a large table (723M rows) — always filter by PaymentDate.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total dividends paid on a date | `SELECT SUM(TotalDividendPaid) WHERE PaymentDate = @date` |
| Tax withholding by regulation | `SELECT Regulation, SUM(TotalDividendPaid * BuyTax) WHERE PaymentDate = @date GROUP BY Regulation` |
| Customer dividend history | `WHERE RealCID = @cid ORDER BY PaymentDate DESC` — limit by date range |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Customer profile for tax reporting |
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Extended instrument details |
| DWH_dbo.Dim_Position | PositionID = PositionID | Full position details |

### 3.4 Gotchas

- **Very large table**: 723M rows — always include PaymentDate filter in queries.
- **TaxCode is varchar**: Not an integer — some values are numeric strings, others may be codes.
- **PositionType values inconsistent**: Mix of '0', '1', and empty string '' (legacy rows pre-PositionType addition).
- **RequestorComments column**: Not in DDL — if referenced elsewhere, it does not exist here.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis | High |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID receiving the dividend payment. Passthrough from BI_DB_DailyDividendsByPosition. FK to Dim_Customer.RealCID. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 2 | DividendID | int | YES | Unique identifier for the dividend event (e.g., a specific company's quarterly dividend). Passthrough from source. 104K distinct values. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 3 | PaymentDate | datetime | YES | Date the dividend was paid. Passthrough from BI_DB_DailyDividendsByPosition.Date. Range: 2019-01-01 to 2026-04-11. Part of clustered index. Used for DELETE+INSERT partitioning. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 4 | Regulation | varchar(40) | YES | Regulatory entity governing the customer at time of dividend payment. Passthrough from source (pre-resolved in BI_DB_DailyDividendsByPosition). (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 5 | PositionID | bigint | YES | Unique identifier of the position that generated the dividend. FK to Dim_Position. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 6 | PositionType | varchar(max) | YES | Position type classification. Values: '0' (CFD), '1' (Real/Settled), '' (empty/legacy). Passthrough from source. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 7 | IsSettled | bit | YES | Whether the position is a settled (real) asset. True=real stock ownership, False=CFD. Passthrough from source. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 8 | InstrumentID | int | YES | Financial instrument identifier. FK to Dim_Instrument. Passthrough from source. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 9 | InstrumentDisplayName | varchar(100) | YES | Human-readable instrument name (e.g., 'Oracle Corporation', 'iShares 20+ Year Treasury Bond ETF'). From Dim_Instrument.InstrumentDisplayName via InstrumentID JOIN. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 10 | ISINCode | varchar(30) | YES | International Securities Identification Number (e.g., US68389X1054). From Dim_Instrument.ISINCode via InstrumentID JOIN. Used for regulatory reporting. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 11 | TaxCode | varchar(40) | YES | Tax classification code for withholding tax purposes. Passthrough from source. Values vary by jurisdiction. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 12 | BuyTax | decimal(6,4) | YES | Withholding tax rate applied to the dividend (decimal, e.g., 0.3000 = 30%). Passthrough from source. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 13 | TotalDividendPaid | money | YES | Total dividend amount paid for this (CID, Position, Dividend, TaxCode) combination. SUM(Amount) aggregated from source. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 14 | IsValidCustomer | bit | YES | Whether the customer is a valid account. Passthrough from source. True=valid. (Tier 2 — SP_Daily_CID_Dividend_TaxReport) |
| 15 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | BI_DB_DailyDividendsByPosition | RealCID | Passthrough |
| DividendID | BI_DB_DailyDividendsByPosition | DividendID | Passthrough |
| PaymentDate | BI_DB_DailyDividendsByPosition | Date | Passthrough |
| TotalDividendPaid | BI_DB_DailyDividendsByPosition | Amount | SUM(Amount) |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough |
| ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Passthrough |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_DailyDividendsByPosition (DateID=@DateID)
  + DWH_dbo.Dim_Instrument (InstrumentDisplayName, ISINCode)
  |-- #final (GROUP BY all dims, SUM Amount) ---|
  v
BI_DB_dbo.BI_DB_Daily_CID_Dividend_TaxReport (DELETE+INSERT for PaymentDate)

UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension |
| PositionID | DWH_dbo.Dim_Position | Position dimension |

### 6.2 Referenced By (other objects point to this)

No known consumers identified in this batch.

---

## 7. Sample Queries

### 7.1 Total Dividends Paid by Date

```sql
SELECT CAST(PaymentDate AS DATE) AS payment_date,
       COUNT(DISTINCT RealCID) AS customers,
       SUM(TotalDividendPaid) AS total_paid
FROM BI_DB_dbo.BI_DB_Daily_CID_Dividend_TaxReport
WHERE PaymentDate >= '2026-04-01'
GROUP BY CAST(PaymentDate AS DATE)
ORDER BY payment_date
```

### 7.2 Tax Withholding Summary by Regulation

```sql
SELECT Regulation,
       SUM(TotalDividendPaid) AS gross_dividends,
       SUM(TotalDividendPaid * BuyTax) AS estimated_tax
FROM BI_DB_dbo.BI_DB_Daily_CID_Dividend_TaxReport
WHERE PaymentDate >= '2026-01-01'
GROUP BY Regulation
ORDER BY gross_dividends DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 14 T2, 0 T3, 0 T4, 1 T5 | Elements: 15/15, Logic: 8/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_Daily_CID_Dividend_TaxReport | Type: Table | Production Source: BI_DB_DailyDividendsByPosition + Dim_Instrument via SP_Daily_CID_Dividend_TaxReport*
