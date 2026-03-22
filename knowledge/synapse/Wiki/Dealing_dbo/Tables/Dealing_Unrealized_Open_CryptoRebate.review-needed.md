# Review Notes — Dealing_dbo.Dealing_Unrealized_Open_CryptoRebate

**Status**: Active ✅ (monthly, Priority 0, SB_Daily)

## Items Requiring Human Review

1. **Column name typo `UPdatedate`**: The DDL defines the ETL timestamp column as `UPdatedate` (capital P). This typo is preserved in the live table. Confirm whether a DDL rename is planned — any downstream consumers must use the exact misspelled name until corrected.

2. **`ClosedVolume` naming is misleading**: Despite the name, `ClosedVolume` represents the **mark-to-market value** of still-open positions at month-end (using BidSpreaded × ConvertRateIsBuy_1), NOT the value of closed positions. Confirm whether renaming to `MarkToMarketVolume` or similar is planned to avoid user confusion.

3. **Hardcoded country exclusion list**: Austria, France, Finland, Greece, Luxembourg, Malta, Portugal, Sweden, and United Kingdom are hardcoded in the SP. If regulatory requirements change (e.g., a country is added to or removed from the exclusion list), the SP must be manually updated. Confirm whether this list is current and who is responsible for maintaining it.

4. **Cross-schema dependency on BI_DB_dbo**: The SP sources position data from `BI_DB_dbo.BI_DB_PositionPnL` (a BI_DB table, not DWH). This creates an implicit dependency on BI_DB processing being complete before this SP runs. Confirm that this ordering is enforced in the SB_Daily orchestration.

5. **Rebate program start date hardcoded**: `OpenDateID >= 20220308` is hardcoded in the SP. If the program start date ever changes (e.g., for a retroactive adjustment), the SP must be updated. Confirm this date is intentional and immutable.

6. **`Markup` column purpose**: `TotalVolume × 0.01` (1% reference markup) is stored but appears to be an informational intermediate — the actual rebate is computed from the bracket rates (0.15%/0.25%/0.50%), not from `Markup`. Confirm whether `Markup` is used in any downstream reports.
