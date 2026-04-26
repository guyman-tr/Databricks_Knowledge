# BI_DB_dbo.BI_DB_Depositors_By_Managers — Review Needed

## Open Questions

1. Excluded ManagerIDs (0, 342, 787, 283, 887) — what do these represent? System accounts, test accounts, or decommissioned managers?
2. The SP also writes to BI_DB_NewBonusReport (daily) — is that the primary output, with this table being a monthly summary companion?
3. NoOfCustomers uses Fact_SnapshotCustomer at month start — if a customer is transferred mid-month, they appear under the original manager. Is this the intended behavior for bonus calculation?
4. Manager name is stored as a concatenated string, not just ManagerID. If a manager's name changes, historical data becomes inconsistent. Is this tracked?

## Cross-Object Consistency

- ManagerID from DWH_dbo.Dim_Manager — consistent with other BI_DB tables ✓
