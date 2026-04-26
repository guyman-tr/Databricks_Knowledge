# BI_DB_DepositSnapshots — Column Lineage

**Schema**: BI_DB_dbo  
**Object Type**: Table  
**Writer SP**: SP_User_Segment_Snapshot  
**Generated**: 2026-04-22

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | DateID | SP_User_Segment_Snapshot | @Date parameter | CONVERT(INT, @Date) passthrough | Tier 2 |
| 2 | CID | DWH_dbo.Fact_CustomerAction | RealCID | GROUP BY RealCID (passthrough key) | Tier 1 |
| 3 | TotalDeposit | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=7 AND DateID=@Date | Tier 2 |
| 4 | UpdateDate | SP_User_Segment_Snapshot | — | GETDATE() at INSERT time | Tier 2 |

---

## ETL Pipeline

```
etoro.History.Credit (CreditTypeID=1 deposit transactions)
  → DWH_dbo.Fact_CustomerAction (ActionTypeID=7, Amount in USD)
  |-- SP_User_Segment_Snapshot @Date (DELETE WHERE DateID=@Date + INSERT) --|
  v
BI_DB_dbo.BI_DB_DepositSnapshots (38.4M rows, 2013–2026)
  |-- UC: Not Migrated --|
  |-- Downstream: BI_DB_User_Segment_Snapshot (DepositGroup classification) --|
```

---

## Source Objects

| Source Schema | Source Object | Role |
|---|---|---|
| DWH_dbo | Fact_CustomerAction | Deposit events (ActionTypeID=7); provides RealCID and Amount per deposit transaction |

---

## UC External Lineage

UC Target: **Not Migrated** — no UC entry exists for this table.
