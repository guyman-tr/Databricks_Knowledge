# DWH_dbo.Fact_Deposit_Fees — Review Needed

## Summary

- **Total columns**: 47
- **Tier 1**: 0 (no upstream wiki available)
- **Tier 2**: 2 (ModificationDateID, UpdateDate — ETL-computed)
- **Tier 3**: 45 (passthrough from BackOffice.BillingDepositsPCIVersion, no upstream wiki)
- **Tier 4**: 0

## Items Requiring Human Review

### 1. Table Dormancy

The table has no data after 2024-06-30. Confirm whether this table has been intentionally decommissioned or if data loading was moved to a different pipeline/table. The DELETE block in the SP is commented out — unclear if this was intentional.

### 2. No Upstream Wiki — All Passthrough Columns are Tier 3

BackOffice.BillingDepositsPCIVersion has no documented wiki in DB_Schema or any other upstream repo. All 45 passthrough columns are Tier 3 (grounded in DDL + SP code + live data, but lacking authoritative production-side documentation). If a wiki for BackOffice.BillingDepositsPCIVersion is created in the future, these should be upgraded to Tier 1.

### 3. Currency Code Anomalies

Some Currency values are compound codes (e.g. "AEDUSD", "USDRON") rather than standard ISO 4217 codes. Confirm whether these represent cross-currency deposit pairs or data quality issues in the source system.

### 4. DepositCollarAmount Semantics

The column name "Collar" is unusual. From data inspection, it appears to be a USD-equivalent conversion of DepositAmount, but the exact business definition (whether it includes fees, spreads, or is a pure FX conversion) should be confirmed by the billing team.

### 5. PCI Scope

The source is `BillingDepositsPCIVersion` — a PCI-compliant view. Confirm which sensitive fields are stripped or masked at the source level. The `UserName` column appears to contain PII (eToro usernames).

### 6. Duplicate Risk

The SP's DELETE block is commented out, running in append-only mode. If the SP was ever re-run for overlapping date ranges, duplicate rows may exist. A deduplication check on DepositID would confirm data integrity.

### 7. Commented-Out DELETE Logic

```sql
/*DELETE FROM [DWH_dbo].[Fact_Deposit_Fees]
WHERE ModificationDateID >= convert(INT,convert(varchar, @Yesterday ,112))
and ModificationDateID < convert(INT,convert(varchar, @CurrentDate ,112))*/
```

The original design intended daily delete-and-reload by ModificationDateID. The commented-out state suggests a shift to append-only loading. Confirm whether this was intentional.

### 8. Relationship to Other Deposit Tables

Fact_Deposit_Fees coexists with other deposit-related tables (e.g. Fact_BillingDeposit, Fact_Deposit_State). The relationship and overlap between these tables should be clarified — are they complementary views or partially redundant?
