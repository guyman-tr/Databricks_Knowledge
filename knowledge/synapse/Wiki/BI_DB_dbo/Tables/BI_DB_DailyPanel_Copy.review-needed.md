# Review Needed: BI_DB_dbo.BI_DB_DailyPanel_Copy

## Items for Human Review

### 1. BuyPercent / SellPercent Column Name Swap
The SP computes `BuyPercent` as `SUM(CASE WHEN IsBuy = 0 THEN IsBuyPercent ELSE 0 END)` -- this is actually the SELL ratio stored in a column named "BuyPercent". And `SellPercent = 1 - BuyPercent` is actually the BUY ratio. This appears to be a long-standing naming bug in the SP. Confirm whether this is intentional or a defect that should be corrected.

### 2. PreviousGuruStatus Data Type
The DDL defines `PreviousGuruStatus` as `varchar(max)`, but the SP stores the raw `GuruStatusID` integer from the historical snapshot, not the human-readable name. Confirm whether this should be the numeric ID or the text name. The SP code clearly stores `sc.GuruStatusID as PreviousGuruStatus`, meaning values like '2', '3', etc. appear as strings.

### 3. Unresolved Upstream Sources
The following source tables have no wiki documentation in the bundle:
- `general.etoroGeneral_History_GuruCopiers` -- core source for CopyAUC, CopyPnL, NumOfCopiers
- `BI_DB_dbo.External_etoroGeneral_Customer_Settings` -- source for AllowDisplayFullName
- `BI_DB_dbo.External_etoro_Internal_RiskScore` -- risk score bucket definitions
- `BI_DB_dbo.External_etoro_History_BlockedCustomerOperations` -- blocked operations history
- `BI_DB_dbo.External_etoro_Customer_BlockedCustomerOperations` -- current blocked operations
- `BI_DB_dbo.External_etoro_Dictionary_BlockUnBlockReason` -- block reason lookup
- `BI_DB_dbo.External_UserApiDB_dbo_Publications` -- PI biography text

### 4. Region Column Source
The SP uses `Dim_Country.MarketingRegionManualName` (NOT `Dim_Country.Region`). MarketingRegionManualName is a manual override from Ext_Dim_Country and may differ from the automated MarketingRegion label. Confirm this is the intended region field for the PI panel.

### 5. UC Migration Status
This table is not migrated to Unity Catalog (`_Not_Migrated`). Confirm whether migration is planned or if the table is intended to remain Synapse-only.

### 6. TotalDaysInCurrentStatus Scope
The SP only computes TotalDaysInCurrentStatus for `CopyType='PI'` (not Portfolio or RemovedPI). This means the column is always NULL for ~68% of rows. Confirm this is by design.

### 7. DDL Column Count vs SP Output
The DDL has 57 columns (excluding Date and DateID which are present in DDL). The SP INSERT lists exactly match the DDL. Column count verified: 57 data columns in the DDL, 57 documented in the wiki Elements table.

---

*Generated: 2026-04-30 | Reviewer: pending*
