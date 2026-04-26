# BI_DB_dbo.BI_DB_ClubChangeLog — Column Lineage

> Club change event log. One row per upgrade/downgrade/first-club event per customer. Post-2023 sources: Fact_SnapshotCustomer + V_Liabilities + FiatDwhDB EOD balance + Dim_PlayerLevel. Pre-2023: max equity over 3-month window from BI_DB_CustomerDTDAggregatedData/Fact_SnapshotEquity.

| Column | Source Table | Source Column | Transform |
|--------|-------------|---------------|-----------|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough |
| CreateDate | SP_ClubChangeLog | @dd (parameter) | Run date — the date being processed |
| CurrentLevel | BI_DB_dbo.BI_DB_ClubChangeLog (self-ref) | NewLevel (latest row) | Most recent NewLevel from prior log entries; NULL for first-ever club assignment |
| NewLevel | DWH_dbo.Dim_PlayerLevel | PlayerLevelID | CASE on RealizedEquityNoCFD thresholds: Bronze=1, Silver=5, Gold=3, Platinum=2, Platinum+=6, Diamond=7 |
| PLChangeType | SP_ClubChangeLog logic | — | 'Upgrade' if NewSort > CurrentSort; 'Downgrade' if NewSort < CurrentSort (pre-2023 only, month-end only); 'First Club' if CurrentLevel IS NULL |
| CurrentClub | DWH_dbo.Dim_PlayerLevel | Name | Resolved from CurrentLevel via Dim_PlayerLevel.PlayerLevelID; NULL for first-ever assignment |
| NewClub | DWH_dbo.Dim_PlayerLevel | Name | Resolved from new computed PlayerLevelID |
| CurrentSort | DWH_dbo.Dim_PlayerLevel | Sort | Ordinal sort order of prior club; NULL for first-ever assignment |
| NewSort | DWH_dbo.Dim_PlayerLevel | Sort | Ordinal sort order of new club |
| IsDepositor | DWH_dbo.Fact_SnapshotCustomer | IsDepositor | Passthrough — has the customer ever made a successful deposit? |
| UpdateDate | SP_ClubChangeLog | — | GETDATE() at INSERT or UPDATE (IsFTC backfill) |
| IsFTC | SP_ClubChangeLog logic | — | First Time Club: 1=first time customer ever reached a non-Bronze level (NewLevel>1 count=1 over all their history); 0=returned to this level; NULL→0 if never reached above Bronze |

## Upstream Chain (post-2023)

```
DWH_dbo.Fact_SnapshotCustomer (all valid customers for @dd)
  + DWH_dbo.V_Liabilities (non-CFD equity: stocks + crypto + cash + in-process cashouts)
  + BI_DB_dbo.External_Gold_DE_FiatDwhDB_CustomerEODBalance_ClubChange (eToroMoney EOD balance in USD)
  → RealizedEquityNoCFD = TotalRealStocks + TotalRealCrypto + TotalCash + EODBalance + InProcessCashouts
  → ClubTier via CASE on equity thresholds
  + DWH_dbo.Dim_PlayerLevel (club name + sort)
  + BI_DB_dbo.BI_DB_ClubChangeLog (self-ref: #CurrentClub = latest club per CID)
  |
  v [SP_ClubChangeLog @dd — Priority 0, Daily, SB_Daily]
    1. DELETE WHERE CreateDate >= @dd
    2. #CurrentClub = latest club per CID from existing log rows
    3. Compute new club tier per customer (equity-based CASE)
    4. INSERT Upgrades (NewSort > CurrentSort)
    5. INSERT First Club (no prior log entry)
    6. UPDATE IsFTC (backfill: 1=first time above Bronze)
BI_DB_dbo.BI_DB_ClubChangeLog (ROUND_ROBIN, CLUSTERED CID)
```

## T1 Verbatim Copy Verification Log

No upstream wiki columns available. All columns Tier 2 (SP logic + DWH dim lookups).
