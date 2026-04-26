# BI_DB_dbo.BI_DB_Investment_Monthly_Data — Column Lineage

## Source Systems

| Source | Type | Description |
|--------|------|-------------|
| DWH_dbo.Dim_Mirror | DWH Dimension | Copy-trading relationships |
| DWH_dbo.Dim_Position | DWH Dimension | Position-level trading data |
| DWH_dbo.Fact_SnapshotCustomer | DWH Fact | Customer SCD snapshot |
| DWH_dbo.Dim_Customer | DWH Dimension | Customer master (UserName) |
| DWH_dbo.Dim_GuruStatus | DWH Dimension | Popular Investor status |
| DWH_dbo.Dim_Fund / Dim_FundType | DWH Dimension | Smart Portfolio fund type |
| DWH_dbo.Dim_Range | DWH Dimension | Date range helper |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB Table | Daily position PnL |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| Year_Month | — | — | YEAR(@date)*100+MONTH(@date) |
| Month | — | — | DATEFROMPARTS(YEAR,MONTH,1) — first of month |
| CID | Dim_Mirror | CID | Copier CID |
| ParentUserName | Dim_Customer | UserName | Copied person's username |
| ParentCID | Dim_Mirror | ParentCID | Copied person's CID |
| MirrorID | Dim_Mirror | MirrorID | Copy relationship ID |
| StartCopy | Dim_Mirror | OpenDateID | Copy start date |
| EndCopy | Dim_Mirror | CloseDateID | Copy end date (0=active) |
| CopyType | Fact_SnapshotCustomer + Dim_Mirror | AccountTypeID, GuruStatusID | CASE: 9=Portfolio, GuruStatus>=2=PI, else=Non-PI |
| Type | Dim_FundType + Dim_GuruStatus | FundTypeName, GuruStatusName | Portfolio→FundTypeName, PI→GuruStatusName, else='Other' |
| StartEquity_copy | BI_DB_PositionPnL + Dim_Position | Amount, PositionPnL | SUM of copier position start equity across 7 lifecycle scenarios |
| FinalEquity_copy | BI_DB_PositionPnL + Dim_Position | Amount, PositionPnL, NetProfit | SUM of copier position final equity |
| %PnL_copy | Computed | StartEquity_copy, FinalEquity_copy | ((Final-Start)/Start)*100 |
| StartEquity_copied | BI_DB_PositionPnL + Dim_Position | Amount, PositionPnL | SUM of copied person's position start equity |
| FinalEquity_copied | BI_DB_PositionPnL + Dim_Position | Amount, PositionPnL, NetProfit | SUM of copied person's position final equity |
| %PnL_copied | Computed | StartEquity_copied, FinalEquity_copied | ((Final-Start)/Start)*100 |
| Num_CopyInstruments | Dim_Position | InstrumentID | COUNT(DISTINCT InstrumentID) in copier positions |
| Num_CopiedInstruments | Dim_Position | InstrumentID | COUNT(InstrumentID) in copied positions |
| %ofCopiedInstruments | Computed | Num_CopyInstruments, Num_CopiedInstruments | (Copy/Copied)*100 — replication ratio |
| UpdateDate | — | — | GETDATE() |

## Pipeline

```
DWH_dbo.Dim_Mirror (copy relationships, open or closed during month)
  + DWH_dbo.Fact_SnapshotCustomer (valid depositors at month start)
  + DWH_dbo.Dim_Position (positions in copy relationships)
  + BI_DB_dbo.BI_DB_PositionPnL (daily position equity snapshots)
  + DWH_dbo.Dim_Customer (ParentUserName)
  + DWH_dbo.Dim_GuruStatus (PI status labels)
  + DWH_dbo.Dim_Fund + Dim_FundType (Smart Portfolio type)
    |-- SP_Investment_Monthly_Data @date (monthly EOM, delete-insert) --|
    |   7 position lifecycle scenarios per side (copy + copied):        |
    |   full-month / opened / closed / opened-and-closed / last-day /  |
    |   same-day / partial-close + detach                              |
    |   UNION ALL → aggregate per mirror relationship                  |
    v
BI_DB_dbo.BI_DB_Investment_Monthly_Data (2.11M rows, monthly)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```
