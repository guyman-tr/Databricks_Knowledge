# BI_DB_dbo.BI_DB_Investment_PIMeetup — Column Lineage

## Source Systems

| Source | Type | Description |
|--------|------|-------------|
| CopyFromLake.etoro_History_Mirror | CopyFromLake | Mirror operations (money in/out/adjustments) |
| DWH_dbo.Dim_Position | DWH Dimension | Position-level data (open positions) |
| DWH_dbo.Dim_Mirror | DWH Dimension | Copy relationship (mirror amount, open date) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| DateID | — | — | Yesterday's date as YYYYMMDD varchar |
| RunDateID | — | — | Today's date as YYYYMMDD varchar |
| CID | Dim_Position | CID | Copier CID (varchar cast) |
| MirrorID | Dim_Position / Dim_Mirror | MirrorID | Copy relationship ID (varchar cast) |
| MirrorOpenID | Dim_Mirror | OpenDateID | Mirror open date (varchar cast) |
| ParentCID | Dim_Mirror | ParentCID | Copied person CID (varchar cast) |
| Calc1 | Dim_Mirror | Amount | Initial mirror allocation amount |
| Calc2 | Dim_Position | Amount, PnLInDollars | SUM(Amount + PnLInDollars) for open positions |
| NMI | etoro_History_Mirror | Amount, MirrorOperationID | Net Money Invested: SUM(CASE: op=2→-1*Amount, else Amount) for ops 1,2,3 |
| MoneyOut | etoro_History_Mirror | Amount, MirrorOperationID | SUM where op=2 or (op=3 AND Amount<=0) |
| MoneyIn | etoro_History_Mirror | Amount, MirrorOperationID | SUM where op=1 or (op=3 AND Amount>0) |
| Platform_NetValue | Computed | Calc1, Calc2 | SUM(Calc1) + SUM(Calc2) |
| Platform_Pnl | Computed | Calc1, Calc2, NMI | SUM(Calc1) + SUM(Calc2) - SUM(NMI) |

## Pipeline

```
CopyFromLake.etoro_History_Mirror (mirror operations: in/out/adjust)
  + DWH_dbo.Dim_Position (open positions, OpenDateID >= 20250801)
  + DWH_dbo.Dim_Mirror (mirror amount, open date, ParentCID)
    |-- SP_CID_Investment_PIMeetup @date (daily, delete-insert by DateID) --|
    |   Filter: CloseDateID=0 (open positions), OpenDateID>=20250801       |
    |   NMI/MoneyIn/MoneyOut from History_Mirror operations 1,2,3          |
    |   Platform_NetValue = Calc1 + Calc2; Platform_Pnl = NetValue - NMI   |
    v
BI_DB_dbo.BI_DB_Investment_PIMeetup (121.4M rows, daily snapshot)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```
