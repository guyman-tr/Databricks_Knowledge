# eMoney_dbo.eMoney_UserData_Marketing — Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|---------------|-----------|------|
| 1 | GCID | eMoney_dbo.eMoney_Dim_Account | GCID | Passthrough | 1 |
| 2 | RealCID | eMoney_dbo.eMoney_Dim_Account | CID | Passthrough rename | 1 |
| 3 | Date_Inserted | eMoney_dbo.eMoney_Dim_Account | AccountCreateDate | Passthrough rename (eTM account creation date) | 2 |
| 4 | Program | eMoney_dbo.eMoney_Dim_Account | AccountProgram | Passthrough rename | 2 |
| 5 | CardId | eMoney_dbo.eMoney_Dim_Account | CardID | Passthrough rename | 1 |
| 6 | CardUsage | eMoney_dbo.eMoney_Dim_Transaction | CID | 1 if customer has any tx with TxTypeID IN (1,2,3,4,9); else 0 | 2 |
| 7 | IBANUsage | eMoney_dbo.eMoney_Dim_Transaction | CID | 1 if customer has any tx with TxTypeID IN (5,6,7,8,13); else 0 | 2 |
| 8 | LastCardStatus | eMoney_dbo.eMoney_Dim_Account | CardStatus, CardCreateDate | CASE WHEN CardCreateDate IS NULL THEN 'NotOrdered' ELSE CardStatus END | 2 |
| 9 | IBANUsed | eMoney_dbo.eMoney_Dim_Transaction | CID | Identical to IBANUsage: CASE WHEN IBANUsage=1 THEN 1 ELSE 0 END (redundant column) | 2 |
| 10 | HasTransactionsLast3Months | eMoney_dbo.eMoney_Dim_Transaction | CID | 1 if any tx with TxLocalDateID >= 90 days ago; else 0 | 2 |
| 11 | CardCreatedDate | eMoney_dbo.eMoney_Dim_Account | CardCreateDate | Passthrough rename | 2 |
| 12 | UpdateDate | SP_eMoney_UserData_Marketing | GETDATE() | ETL load timestamp | 2 |
| 13 | SubProgram | eMoney_dbo.eMoney_Dim_Account | AccountSubProgram | Passthrough rename | 2 |

## ETL Chain Summary

```
eMoney_dbo.eMoney_Dim_Account (primary source — non-test primary accounts)
  + eMoney_dbo.eMoney_Dim_Transaction (usage flags: CardUsage, IBANUsage, HasTransactionsLast3Months)
    |-- SP_eMoney_UserData_Marketing (TRUNCATE + INSERT daily idempotent guard) ---|
    |   Orchestrated via: SP_eMoney_Execute_Group_One (SP 11)                       |
    |   STATUS: Currently commented out — table last refreshed 2026-04-12           |
    v
eMoney_dbo.eMoney_UserData_Marketing
  (2,010,838 rows, one per GCID, last updated 2026-04-12)
  |-- UC Gold: _Not_Migrated ---|
```

## Source Objects

- `eMoney_dbo.eMoney_Dim_Account` (GCID, CID, AccountCreateDate, AccountProgram, AccountSubProgram, CardID, CardStatus, CardCreateDate; filter: GCID<>0, GCID_Unique_Count=1, IsTestAccount=0, CurrencyBalanceStatusID<>4)
- `eMoney_dbo.eMoney_Dim_Transaction` (CardUsage: TxTypeID 1-4,9; IBANUsage: TxTypeID 5-8,13; HasTransactionsLast3Months: last 90 days)
