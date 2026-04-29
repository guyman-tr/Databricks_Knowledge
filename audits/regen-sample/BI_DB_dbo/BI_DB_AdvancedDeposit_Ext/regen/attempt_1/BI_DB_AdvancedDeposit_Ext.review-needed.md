# Review Needed: BI_DB_dbo.BI_DB_AdvancedDeposit_Ext

## Critical: Table is Dormant — No Active Writer

1. **0 rows**: Table has no data. Confirmed via live Synapse query.
2. **No direct writer SP**: SP_H_Deposits creates `#AdvancedDeposit_Ext` temp table with identical structure but writes to `BI_DB_Deposits`, not this table.
3. **Backup cleanup**: `BI_DB_AdvancedDeposit_Ext_Backup_20241117` was cleaned up on 2024-12-01, suggesting decommissioning around November 2024.

## Lineage Confidence

- Column lineage is **indirect**: traced from SP_H_Deposits temp table construction, not from a direct writer to this table. The temp table `#AdvancedDeposit_Ext` matches this table's DDL for 47 of 52 temp columns (the extra 5 — ResponseName, ResponseRN, Date, DateID, UpdateDate — are not in this table's DDL).
- **22 Tier 1 columns** inherited from Fact_BillingDeposit wiki (origin: Billing.Deposit). Descriptions copied verbatim with snapshot stats stripped.
- **2 Tier 1 columns** inherited from Dim_Customer wiki (origin: Customer.CustomerStatic). Registered and SerialID.
- **10 Tier 1 columns** inherited from dim-lookup passthroughs with root production origins: Dictionary.PaymentStatus (2), Dictionary.Country (2), Dictionary.Funnel (3), Dictionary.FundingType (1), Dictionary.CardType (1), Billing.Depot (1).
- **13 Tier 2 columns** traced from SP code: external table lookups without upstream wikis (RiskManagementStatus, MarketingRegion, BackOffice.CustomerAllTimeAggregatedData), DWH-computed channels (Dim_Channel is itself Tier 2), XML-extracted renames (TransactionID, BinCode), staging passthroughs (CardSubType, CardCategory via Dim_CountryBin), and hardcoded NULLs (OldPaymentID, Code).

## Questions for Reviewer

- **Decommission decision**: Should this DDL be removed from SSDT? The table has been empty since ~Nov 2024 with no active writer.
- **Relationship to BI_DB_Deposits**: Is `BI_DB_Deposits` the formal replacement? The SP writes to BI_DB_Deposits with the same column set plus ResponseName, ResponseRN, Date, DateID, UpdateDate.
- **CID type discrepancy**: The current DDL defines CID as `int`, but the backup table defines it as `bigint`. Was the DDL modified after decommissioning?
- **IsFTD type narrowing**: Fact_BillingDeposit stores IsFTD as `int`; this DDL uses `bit`. Confirm no data loss occurred historically.
- **PII fields**: IPAddress (numeric representation of IP) and BinCode are present. If the table is ever repopulated, ensure PII classification and masking are applied.

## Decommission Candidate

Strong candidate for DDL removal based on:
- 0 rows since at least November 2024
- No active writer SP targets this table
- Backup already cleaned up
- Active replacement exists (`BI_DB_Deposits`)
- Wide schema (47 columns) suggests purpose-built analysis table, not a core pipeline component
