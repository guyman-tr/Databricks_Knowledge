# Review Sidecar: DWH_dbo.Fact_BillingWithdraw

## Confidence Summary

| Tier | Count | Description |
|------|-------|-------------|
| Tier 1 (Upstream Wiki) | 19 | Columns with descriptions inherited from Billing.Withdraw and Billing.WithdrawToFunding upstream wikis |
| Tier 2 (SP Code) | 46 | Columns described from ETL SP logic (XML extraction, transforms) |
| Tier 3 (DDL/Inference) | 18 | Columns described from DDL type and naming patterns |
| Tier 4 (Unverified) | 0 | — |

## Items Requiring Human Review

### 1. XML Column Semantic Types
- **Issue**: ~40 columns extracted from XML are stored as `nvarchar(max)` regardless of semantic type. Some (e.g., `BinCountryIDAsInteger`, `CardTypeIDAsInteger`, `BankIDAsInteger`) contain integer values but are stored as strings. `AccountIDAsDecimal` and `SecureIDAsDecimal` contain decimal values as strings.
- **Question**: Should downstream consumers CAST these to their semantic types? Are there data quality issues (non-numeric values in "AsInteger" columns)?
- **Columns**: BinCountryIDAsInteger, CardTypeIDAsInteger, CountryIDAsInteger, BankIDAsInteger, ACHBankAccountIDAsInteger, AccountIDAsDecimal, SecureIDAsDecimal, InstrumentIDAsInteger

### 2. BIN Code Enrichment Gaps
- **Issue**: `BankName` and `CardCategory` are populated via `CAST(BinCodeAsString AS INT) = Dim_CountryBin.BinCode`. If `BinCodeAsString` is NULL, non-numeric, or contains a BIN not in `Dim_CountryBin`, these columns will be NULL.
- **Question**: What percentage of rows have NULL BankName/CardCategory? Is the Dim_CountryBin coverage sufficient for regulatory reporting use cases?

### 3. ExpirationDateID Computation
- **Issue**: The ETL computes ExpirationDateID as `200000 + RIGHT(ExpirationDate,2)*100 + LEFT(ExpirationDate,2)`. This appears to parse MM/YY format as YYYYMM, but the arithmetic produces `2000YY + MM` which seems like a YYYYMM key. For ExpirationDate "0126" (Jan 2026): `200000 + 26*100 + 01 = 202601`. For invalid/NULL: 190001.
- **Question**: Confirm the ExpirationDate string format is consistently MMYY across all providers. Are there providers that use YYMM or MM/YY with separators?

### 4. LEFT JOIN Behavior
- **Issue**: Both staging JOINs are LEFT JOINs (`bw LEFT JOIN wtf ON WithdrawID`, `wtf LEFT JOIN bf ON FundingID`). This means rows may exist where all WTF columns are NULL (withdrawal request without a payment leg) or all BF columns are NULL (payment leg without a funding instrument record).
- **Question**: How common are NULL WTF/BF columns? Do analytics consumers need to account for these NULLs?

### 5. Synapse MCP Unavailable
- **Issue**: Phases 2 (Live Data Sampling) and 3 (Distribution Analysis) were skipped because Synapse MCP was not available during documentation.
- **Impact**: No live row counts, value distributions, or NULL rate statistics for DWH columns. Statistics cited are from the upstream production wikis.

### 6. No Views Reference This Table
- **Observation**: No DWH views were found referencing Fact_BillingWithdraw. All consumption appears to be direct table queries from BI tools and reporting queries (Confluence examples).
