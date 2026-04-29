# BI_DB_dbo.BI_DB_Unsettled_Trades_Risk

> 20.6K-row BNY Mellon unsettled trades risk monitoring table tracking stock/ETF trades that failed to settle by their contractual settlement date, from October 2023 to present. Each row represents one unsettled trade with fail reason, local currency amount, and USD-converted value. Refreshed daily via SP_Unsettled_Trades_Risk with DELETE+INSERT by report run date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging.LP_BNY_Unsettled_Trades_UnsettledTrades (BNY Mellon LP report) + DWH_dbo.Dim_Instrument + DWH_dbo.Fact_CurrencyPriceWithSplit (FX conversion) |
| **Refresh** | Daily (SP_Unsettled_Trades_Risk, DELETE+INSERT by Report_Run_Date, SB_Daily, Priority 0) |
| **Synapse Distribution** | HASH(Reference_Number) |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Unsettled_Trades_Risk` is a 20.6K-row risk monitoring table that tracks stock and ETF trades executed through the BNY Mellon liquidity provider (LP) that have failed to settle by their contractual settlement date. Each row represents one unsettled trade identified from BNY Mellon's daily unsettled trades report, with the fail reason code, trade details, and both local-currency and USD-converted amounts.

The table only contains trades where the Report Run Date exceeds the Contractual Settlement Date (i.e., actually late), and excludes non-trade movements (SECURITY DEPOSIT, SECURITY WITHDRAWAL, CORPORATE ACTION). This gives a clean view of genuine settlement failures.

The SP converts local currency amounts to USD using DWH_dbo.Dim_Instrument (to identify the correct USD/local currency pair) and DWH_dbo.Fact_CurrencyPriceWithSplit (for the Ask rate on the trade date). Ten currencies are supported (EUR, USD, GBP, NOK, AED, SEK, HKD, AUD, CHF, DKK).

The daily load deletes existing records matching both Report_Run_Date=@Date and Reference_Number+Trade_Date combinations found in the new data, then inserts fresh records — handling both reprocessing and updated settlement status.

---

## 2. Business Logic

### 2.1 Settlement Failure Detection

**What**: Only trades past their contractual settlement date are included.
**Columns Involved**: `Report_Run_Date`, `Contractual_Settle_Date`, `Age_Days`
**Rules**:
- Included: WHERE Report_Run_Date > Contractual_Settle_Date (report date is after settlement was due)
- Age_Days = DATEDIFF(day, Report_Run_Date, Contractual_Settle_Date) — always negative (contractual date is in the past)
- Example: Report_Run_Date=2026-04-09, Contractual_Settle_Date=2026-04-08 → Age_Days = -1

### 2.2 FX Conversion to USD

**What**: Local currency amounts are converted to USD using trade-date FX rates.
**Columns Involved**: `Local_Net_Amount`, `Local_Currency`, `Amount_USD`
**Rules**:
- Ind=1 (USD is buy currency, e.g., EURUSD): Amount_USD = Local_Net_Amount / Ask
- Ind=2 (USD is sell currency, e.g., USDEUR): Amount_USD = Local_Net_Amount × Ask
- Local_Currency='USD': Amount_USD = Local_Net_Amount (passthrough)
- Other currencies: Amount_USD = Local_Net_Amount × 1,000,000,000 (sentinel flag — unconverted)
- Supported currencies: AED, AUD, CHF, CZK, DKK, EUR, GBP, HKD, NOK, SEK

### 2.3 Transaction Type Filtering

**What**: Non-trade movements are excluded from the unsettled trades report.
**Columns Involved**: `Transaction_Name`
**Rules**:
- Excluded: SECURITY DEPOSIT, SECURITY WITHDRAWAL, CORPORATE ACTION
- Included: BUY (91%), SELL (9%), INTERNAL MOVEMENT (<1%)

### 2.4 Fail Reason Codes

**What**: BNY Mellon standard fail reason codes identify why settlement failed.
**Columns Involved**: `Fail_Reason_Code`
**Rules**:
- PRCY (53%): Counterparty unable to deliver (price discrepancy or pending confirmation)
- CLAC (35%): Client account issue (clearing-related)
- LACK (7%): Lack of securities
- MACH (2%): Matching issue between counterparties
- 26 additional codes at <1% each (CYCL, CMIS, AWSH, NARR, FUTU, PART, etc.)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(Reference_Number) distribution — optimized for per-trade lookups and dedup JOINs. HEAP (no clustered index) — for date-range queries, add explicit WHERE on Report_Run_Date.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily unsettled trade exposure | `SELECT Report_Run_Date, SUM(Amount_USD) FROM ... GROUP BY Report_Run_Date` |
| Trades unsettled > 5 days | `WHERE Age_Days < -5` |
| Breakdown by fail reason | `GROUP BY Fail_Reason_Code` |
| Currency exposure breakdown | `GROUP BY Local_Currency` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ISIN matching | Get instrument name/details for the unsettled security |

### 3.4 Gotchas

- **Age_Days is negative**: DATEDIFF(Report_Run_Date, Contractual_Settle_Date) — since report date > settle date, result is always negative. More negative = older unsettled trade
- **Amount_USD sentinel**: If Local_Currency is not in the 10 supported currencies, Amount_USD = Local_Net_Amount × 1,000,000,000. Filter these with `WHERE Amount_USD < 1000000000` or check `Local_Currency NOT IN ('USD','EUR',...)` 
- **Negative amounts**: BUY transactions have negative Local_Net_Amount (cash outflow), SELL transactions have positive. Amount_USD preserves the sign
- **Shares_Par sign**: Negative for SELL (delivering shares), positive for BUY (receiving shares)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data + context |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL infrastructure / standard metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Client_Reference | varchar(max) | YES | BNY Mellon client reference identifier for the trade. Format: numeric string + 'C' suffix (e.g., "177544108242C"). Identifies the eToro client account at the LP. (Tier 2 — SP_Unsettled_Trades_Risk, Dealing_staging.LP_BNY_Unsettled_Trades) |
| 2 | Reference_Number | bigint | YES | BNY Mellon trade reference number. Unique per trade instruction. Used as distribution key and for dedup on reload (DELETE JOIN on Reference_Number + Trade_Date). (Tier 2 — SP_Unsettled_Trades_Risk, Dealing_staging.LP_BNY_Unsettled_Trades) |
| 3 | Report_Run_Date | date | YES | Date the BNY Mellon unsettled trades report was generated. Used as the primary date filter for daily load (DELETE WHERE Report_Run_Date=@Date). Only rows where this exceeds Contractual_Settle_Date are included. Range: 2023-10-27 to present. (Tier 2 — SP_Unsettled_Trades_Risk, Dealing_staging.LP_BNY_Unsettled_Trades) |
| 4 | Contractual_Settle_Date | date | YES | Original contractual settlement date for the trade. Always earlier than Report_Run_Date (by definition of unsettled). Used with Report_Run_Date to compute Age_Days. (Tier 2 — SP_Unsettled_Trades_Risk, Dealing_staging.LP_BNY_Unsettled_Trades) |
| 5 | Trade_Date | date | YES | Date the trade was originally executed. Used with Reference_Number for dedup on reload. (Tier 2 — SP_Unsettled_Trades_Risk, Dealing_staging.LP_BNY_Unsettled_Trades) |
| 6 | Local_Currency | varchar(20) | YES | ISO currency code for the trade's settlement currency. 10 distinct values: EUR (59%), USD (18%), GBP (17%), NOK, AED, SEK, HKD, AUD, CHF, DKK. Used for FX conversion to Amount_USD. (Tier 2 — SP_Unsettled_Trades_Risk, Dealing_staging.LP_BNY_Unsettled_Trades) |
| 7 | Transaction_Name | varchar(100) | YES | Trade direction/type. BUY (91%), SELL (9%), INTERNAL MOVEMENT (<1%). SECURITY DEPOSIT, SECURITY WITHDRAWAL, and CORPORATE ACTION are filtered out by the SP. (Tier 2 — SP_Unsettled_Trades_Risk, Dealing_staging.LP_BNY_Unsettled_Trades) |
| 8 | Fail_Reason_Code | varchar(100) | YES | BNY Mellon standard settlement fail reason code. 30 distinct values. PRCY=counterparty unable to deliver (53%), CLAC=client account/clearing issue (35%), LACK=lack of securities (7%), MACH=matching issue (2%). (Tier 2 — SP_Unsettled_Trades_Risk, Dealing_staging.LP_BNY_Unsettled_Trades) |
| 9 | Shares_Par | float | YES | Number of shares or par value of the security in the trade. Positive for BUY (receiving shares), negative for SELL (delivering shares). (Tier 2 — SP_Unsettled_Trades_Risk, Dealing_staging.LP_BNY_Unsettled_Trades) |
| 10 | Local_Net_Amount | numeric(18,6) | YES | Net settlement amount in local currency. Negative for BUY (cash outflow), positive for SELL (cash inflow). (Tier 2 — SP_Unsettled_Trades_Risk, Dealing_staging.LP_BNY_Unsettled_Trades) |
| 11 | ISIN | varchar(max) | YES | International Securities Identification Number for the traded instrument. Standard 12-character ISIN (e.g., "US42727R2031", "DE000A0D9PT0"). (Tier 2 — SP_Unsettled_Trades_Risk, Dealing_staging.LP_BNY_Unsettled_Trades) |
| 12 | Age_Days | int | YES | Days between report run date and contractual settlement date. DATEDIFF(day, Report_Run_Date, Contractual_Settle_Date). Always negative since Report_Run_Date > Contractual_Settle_Date. More negative = older unsettled trade. (Tier 2 — SP_Unsettled_Trades_Risk) |
| 13 | Amount_USD | numeric(18,6) | YES | Net settlement amount converted to USD. FX conversion via Dim_Instrument currency pair identification + Fact_CurrencyPriceWithSplit Ask rate on Trade_Date. Sentinel: 1,000,000,000 × Local_Net_Amount for unsupported currencies. (Tier 2 — SP_Unsettled_Trades_Risk) |
| 14 | UpdateDate | datetime | NOT NULL | ETL metadata: timestamp when this row was inserted by SP_Unsettled_Trades_Risk (GETDATE()). (Tier 5 — SP_Unsettled_Trades_Risk) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Client_Reference | LP_BNY_Unsettled_Trades | [Client Reference] | Rename |
| Reference_Number | LP_BNY_Unsettled_Trades | [Reference Number] | Rename |
| Report_Run_Date | LP_BNY_Unsettled_Trades | [Report Run Date] | Rename |
| Contractual_Settle_Date | LP_BNY_Unsettled_Trades | [Contractual Settle Date] | Rename |
| Trade_Date | LP_BNY_Unsettled_Trades | [Trade Date] | Rename |
| Local_Currency | LP_BNY_Unsettled_Trades | [Local Currency Code] | Rename |
| Transaction_Name | LP_BNY_Unsettled_Trades | [Transaction Name] | Rename |
| Fail_Reason_Code | LP_BNY_Unsettled_Trades | [Fail Reason Code] | Rename |
| Shares_Par | LP_BNY_Unsettled_Trades | [Shares/Par] | Rename |
| Local_Net_Amount | LP_BNY_Unsettled_Trades | [Local Net Amount] | Rename |
| ISIN | LP_BNY_Unsettled_Trades | [ISIN] | Passthrough |
| Age_Days | Derived | Report_Run_Date - Contractual_Settle_Date | DATEDIFF(day, ...) |
| Amount_USD | Derived | Local_Net_Amount × FX rate | CASE on currency pair direction |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

### 5.2 ETL Pipeline

```
BNY Mellon LP (Unsettled Trades Report)
  |-- Data Lake ingestion ---|
  v
Dealing_staging.LP_BNY_Unsettled_Trades_UnsettledTrades
  |                                              |
  |  + DWH_dbo.Dim_Instrument (currency pairs)   |
  |  + DWH_dbo.Fact_CurrencyPriceWithSplit (FX)  |
  |                                              |
  |-- SP_Unsettled_Trades_Risk @date (daily) ----|
  v
BI_DB_dbo.BI_DB_Unsettled_Trades_Risk (20.6K rows)
  |
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Local_Currency, Amount_USD | DWH_dbo.Dim_Instrument | Currency pair identification for FX conversion |
| Amount_USD | DWH_dbo.Fact_CurrencyPriceWithSplit | Ask rate for USD conversion on trade date |
| All trade columns | Dealing_staging.LP_BNY_Unsettled_Trades_UnsettledTrades | BNY Mellon LP source report |

### 6.2 Referenced By (other objects point to this)

No known consumers in BI_DB_dbo or DWH_dbo SPs.

---

## 7. Sample Queries

### 7.1 Daily Unsettled Trade Exposure Summary

```sql
SELECT
    Report_Run_Date,
    COUNT(*) AS TradeCount,
    SUM(CASE WHEN Amount_USD < 1000000000 THEN ABS(Amount_USD) ELSE 0 END) AS TotalExposureUSD,
    AVG(Age_Days) AS AvgAgeDays
FROM BI_DB_dbo.BI_DB_Unsettled_Trades_Risk
WHERE Report_Run_Date >= DATEADD(MONTH, -1, GETDATE())
GROUP BY Report_Run_Date
ORDER BY Report_Run_Date DESC
```

### 7.2 Fail Reason Breakdown with USD Exposure

```sql
SELECT
    Fail_Reason_Code,
    COUNT(*) AS TradeCount,
    SUM(CASE WHEN Amount_USD < 1000000000 THEN ABS(Amount_USD) ELSE 0 END) AS TotalExposureUSD
FROM BI_DB_dbo.BI_DB_Unsettled_Trades_Risk
WHERE Report_Run_Date = (SELECT MAX(Report_Run_Date) FROM BI_DB_dbo.BI_DB_Unsettled_Trades_Risk)
GROUP BY Fail_Reason_Code
ORDER BY TotalExposureUSD DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 13 T2, 0 T3, 0 T4, 1 T5 | Elements: 14/14, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Unsettled_Trades_Risk | Type: Table | Production Source: BNY Mellon LP Unsettled Trades Report*
