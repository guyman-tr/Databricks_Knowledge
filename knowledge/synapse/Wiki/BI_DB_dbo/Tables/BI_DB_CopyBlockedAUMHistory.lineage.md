# BI_DB_dbo.BI_DB_CopyBlockedAUMHistory — Column Lineage

Generated: 2026-04-23 | Schema: BI_DB_dbo | Object: BI_DB_CopyBlockedAUMHistory

## ETL Chain

```
etoro.Customer.History_BlockedCustomerOperations (OperationTypeID=2, all block events)
  |-- SP_CopyBlockedAUM (Dan, 2021-11-22; Synapse: Tom Boksenbojm, 2023-12-18) ---|
  |   + #blockedusers (CID filter: currently blocked PIs only)
  |     → etoro.Customer.BlockedCustomerOperations (current blocks)
  |     → DWH_dbo.Dim_Customer (UserName, GuruStatusID, CountryID)
  |     → DWH_dbo.Dim_Country (Country Name)
  |   + External_etoro_Dictionary_BlockUnBlockReason (Reason)
  v
BI_DB_dbo.BI_DB_CopyBlockedAUMHistory (TRUNCATE+INSERT daily)
  |-- Not in Generic Pipeline (no UC target) ---|
  v
UC Target: _Not_Migrated
```

**Critical behavior:** History is filtered via JOIN to `#blockedusers`. Only CIDs currently blocked appear in this table. When a PI is unblocked, ALL their history rows are dropped on the next daily refresh.

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| CID | External_etoro_Customer_BlockedCustomerOperations (via #blockedusers) | CID | Passthrough from current block list | Tier 1 |
| UserName | DWH_dbo.Dim_Customer (via #blockedusers) | UserName | Current enrichment at time of load | Tier 1 |
| Country | DWH_dbo.Dim_Country (via #blockedusers) | Name | Current enrichment at time of load | Tier 1 |
| GuruStatusID | DWH_dbo.Dim_Customer (via #blockedusers) | GuruStatusID | Current enrichment at time of load | Tier 1 |
| OperationTypeID | External_etoro_History_BlockedCustomerOperations | OperationTypeID | Passthrough; always 2 (Copy PI block) | Tier 2 |
| Reason | External_etoro_Dictionary_BlockUnBlockReason | Reason | Passthrough via dictionary lookup | Tier 2 |
| BlockStart | External_etoro_History_BlockedCustomerOperations | BlockStart | Passthrough (historical event datetime) | Tier 2 |
| BlockEnd | External_etoro_History_BlockedCustomerOperations | BlockEnd | Passthrough (historical event datetime, NULL if ongoing) | Tier 2 |
| DaysBlocked | External_etoro_History_BlockedCustomerOperations | BlockStart, BlockEnd | DATEDIFF(DAY, BlockStart, BlockEnd) | Tier 2 |
| UpdateDate | ETL metadata | (none) | GETDATE() | Propagation |

## Source Objects

- `External_etoro_History_BlockedCustomerOperations` — historical block/unblock event log (BlockStart, BlockEnd pairs)
- `External_etoro_Customer_BlockedCustomerOperations` — current active block list (CID filter via #blockedusers)
- `External_etoro_Dictionary_BlockUnBlockReason` — block reason dictionary
- `DWH_dbo.Dim_Customer` — current customer master (UserName, GuruStatusID, CountryID)
- `DWH_dbo.Dim_Country` — country name lookup

## UC External Lineage

UC Target: _Not_Migrated — not in Generic Pipeline mapping
