# Review Needed: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdrawfulldata

## 1. Tier 3 Columns -- No Upstream Wiki Available

The following 9 columns are sourced from AlertServiceDB external tables which have no upstream wiki documentation. Descriptions are inferred from SP code, column names, and live data sampling.

- **AlertID** -- sourced from `External_AlertServiceDB_Alert_Alert.Id`. No upstream wiki for AlertServiceDB schema.
- **CreationDate** -- sourced from `External_AlertServiceDB_Alert_Alert.CreationDate`. No upstream wiki.
- **ModificationDate** -- sourced from `External_AlertServiceDB_Alert_Alert.ModificationDate`. No upstream wiki.
- **AlertType** -- resolved from `External_AlertServiceDB_Dictionary_AlertType.Name`. No upstream wiki.
- **AlertTypeDescription** -- resolved from `External_AlertServiceDB_Dictionary_AlertType.Description`. No upstream wiki.
- **CategoryName** -- resolved from `External_AlertServiceDB_Dictionary_Category.Name`. No upstream wiki.
- **TriggerType** -- resolved from `External_AlertServiceDB_Dictionary_TriggerType.Name`. No upstream wiki.
- **StatusType** -- resolved from `External_AlertServiceDB_Dictionary_StatusType.Name`. No upstream wiki.
- **StatusReason** -- resolved from `External_AlertServiceDB_Dictionary_StatusReason.Name`. No upstream wiki.

**Action**: If AlertServiceDB wiki documentation becomes available, upgrade these columns to Tier 1 or Tier 2 with verbatim descriptions.

## 2. Data Freshness

- **UpdateDate** shows `2025-03-13` for all sampled rows -- the table may not be refreshing daily as expected. Verify SP_AML_Multiple_Accounts scheduling.

## 3. eMoney AccountProgram Coverage

- Only ~14% of rows (6,678 / 48,529) have a non-empty `AccountProgram`. This is expected -- most customers in this AML screening table do not have eToro Money accounts.

## 4. PlayerStatus Trailing Spaces

- Live data confirms trailing spaces in PlayerStatus values (e.g., `"Blocked Upon Request                               "`). This is inherited from Dim_PlayerStatus and is a known upstream characteristic.

## 5. DDL vs SP Type Mismatch

- **BirthDate**: SP casts to DATE but DDL stores as datetime. The cast is effectively a no-op at the storage layer since datetime can hold date-only values.
- **Gender**: DDL is nvarchar(250) but upstream Dim_Customer stores as char(1). The wider type is safe but wastes storage.

## 6. Unresolved External Tables

The 8 `External_AlertServiceDB_*` tables (source objects #13-#20 in lineage) are BI_DB external tables pointing to the AlertServiceDB microservice database. These have no DDL in the DataPlatform repo and no wiki coverage. A future documentation pass should:
1. Obtain AlertServiceDB schema definitions
2. Document the 7-table JOIN chain: Alert -> AlertTemplate -> AlertType/Category/TriggerType, Alert -> AlertStatus -> StatusType/StatusReason
3. Upgrade the 9 Tier 3 columns accordingly
