# Lineage: BI_DB_dbo.BI_DB_InvestorsKPI

**Writer SP**: `BI_DB_dbo.SP_InvestorKPI`  
**Load Pattern**: Conditional incremental — days 1–3 of month: DELETE WHERE DateID>=@DateID AND ActiveMonth=@StartOfMonth + INSERT start-of-month snapshot; days 4+: DELETE WHERE DateID>=@DateID AND IsStartOfMonth=0 AND ActiveMonth=@StartOfMonth + INSERT new/ongoing; monthly IsFullMonth/IsEndOfMonth rolling UPDATE  
**Primary Sources**: `DWH_dbo.Fact_SnapshotCustomer` (customer population), `BI_DB_dbo.BI_DB_CID_DailyPanel_Club` (club tier filter), `BI_DB_dbo.BI_DB_PositionPnL` (AUA amounts)  
**Secondary Sources**: `DWH_dbo.Dim_Manager`, `DWH_dbo.Dim_Range`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_PlayerLevel`, `BI_DB_dbo.BI_DB_Guru_Copiers`, `DWH_dbo.V_Liabilities`, `DWH_dbo.Fact_CustomerAction`, `DWH_dbo.Dim_Date`

**Population Filter**: Only customers who are (1) `IsValidCustomer=1` at @DateID per Fact_SnapshotCustomer + Dim_Range SCD, (2) have PlayerLevelID IN (2,3,6,7) (Gold through Diamond) in BI_DB_CID_DailyPanel_Club, and (3) are assigned to an Account Manager.

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | DateID | SP_InvestorKPI | @Date parameter | CAST(CONVERT(CHAR(8),@Date,112) AS INT) | Tier 2 |
| 2 | Date | SP_InvestorKPI | @Date parameter | Direct date parameter | Tier 2 |
| 3 | ReportingMonth | SP_InvestorKPI | @StartOfMonth | Days 1–3: @StartOfMonth (current); new customers day 4+: DATEADD(MONTH,1,@StartOfMonth) (next month) | Tier 2 |
| 4 | ActiveMonth | SP_InvestorKPI | @StartOfMonth | First day of current month (always same-month) | Tier 2 |
| 5 | CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Population filter via BI_DB_CID_DailyPanel_Club; = RealCID (customer ID) | Tier 2 |
| 6 | AM | DWH_dbo.Dim_Manager | FirstName, LastName | FirstName + ' ' + LastName — concatenated display name of assigned Account Manager | Tier 2 |
| 7 | AccountManagerID | DWH_dbo.Fact_SnapshotCustomer | AccountManagerID | Passthrough ← BackOffice.Manager via Dim_Manager | Tier 2 |
| 8 | Investment | BI_DB_dbo.BI_DB_PositionPnL | Amount | SUM(Amount) WHERE MirrorID=0 AND (InstrumentTypeID=6 OR (InstrumentTypeID IN (4,5) AND Leverage<3)) — real/low-leverage investment positions | Tier 2 |
| 9 | Crypto | BI_DB_dbo.BI_DB_PositionPnL | Amount | SUM(Amount) WHERE MirrorID=0 AND InstrumentTypeID=10 — crypto positions | Tier 2 |
| 10 | Trade | BI_DB_dbo.BI_DB_PositionPnL | Amount | SUM(Amount) WHERE MirrorID=0 AND all other InstrumentTypeIDs — CFD/leveraged positions | Tier 2 |
| 11 | InvestedAmountCopy | BI_DB_dbo.BI_DB_Guru_Copiers | Investment, Cash | MAX(SUM(Investment + Cash)) at TimestampID = next day's YYYYMMDD — total copy portfolio AUM | Tier 2 |
| 12 | Balance | DWH_dbo.V_Liabilities | Credit | MAX(Credit) at @DateID — customer credit/balance from V_Liabilities | Tier 2 |
| 13 | Deposit | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=7 AND DateID=@DateID — deposits on reporting day | Tier 2 |
| 14 | Withdrawal | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=8 AND DateID=@DateID — withdrawals on reporting day | Tier 2 |
| 15 | IsStartOfMonth | SP_InvestorKPI | OUTER APPLY logic | 1 if this row is the first occurrence of CID+AccountManagerID in this ActiveMonth; 0 otherwise | Tier 2 |
| 16 | IsEndOfMonth | SP_InvestorKPI | Rolling UPDATE | Starts 0; rolling UPDATE sets 1 for the most-recently-loaded records of the month; prior records reset to 0 | Tier 2 |
| 17 | IsFullMonth | SP_InvestorKPI | Rolling UPDATE | 1 if CID+AccountManagerID appears both as IsStartOfMonth=1 AND in the latest day's load for this ActiveMonth | Tier 2 |
| 18 | IsBlocked | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | CASE WHEN PlayerStatusID IN (2,4,6,7,8,14) THEN 1 ELSE 0 — blocked/restricted customer status at @DateID | Tier 2 |
| 19 | Classification | ETL | NULL | Always NULL — column was commented out in SP and never implemented | Tier 4 |
| 20 | UpdateDate | ETL | GETDATE() | Batch timestamp (also updated on rolling IsFullMonth/IsEndOfMonth UPDATE) | Tier 3 |
| 21 | Club | DWH_dbo.Dim_PlayerLevel | Name | CASE IsDowngrade: if 1 → LastTier, else CurrentTier from BI_DB_CID_DailyPanel_Club → JOIN Dim_PlayerLevel.Name | Tier 2 |

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + DWH_dbo.Dim_Range (SCD)
  + BI_DB_dbo.BI_DB_CID_DailyPanel_Club (PlayerLevelID filter 2,3,6,7)
  + DWH_dbo.Dim_Manager (AM name)
  + DWH_dbo.Dim_PlayerLevel (Club name)
         |-- population (#startPopFinal / #DailyPop) ---|
         v
BI_DB_dbo.BI_DB_PositionPnL (+ DWH_dbo.Dim_Instrument)
  --> Investment / Crypto / Trade amounts
BI_DB_dbo.BI_DB_Guru_Copiers (next day TimestampID)
  --> InvestedAmountCopy (AUM copy portfolio)
DWH_dbo.V_Liabilities (Credit at @DateID)
  --> Balance
DWH_dbo.Fact_CustomerAction (ActionTypeID 7=Deposit, 8=Withdrawal)
  --> Deposit / Withdrawal
         |-- SP_InvestorKPI @Date (conditional monthly logic) ---|
         v
BI_DB_dbo.BI_DB_InvestorsKPI (~322M rows, Apr 2021–Apr 2026)
  |-- (No UC target — Not Migrated) ---|
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 19 | DateID, Date, ReportingMonth, ActiveMonth, CID, AM, AccountManagerID, Investment, Crypto, Trade, InvestedAmountCopy, Balance, Deposit, Withdrawal, IsStartOfMonth, IsEndOfMonth, IsFullMonth, IsBlocked, Club |
| Tier 3 | 1 | UpdateDate |
| Tier 4 | 1 | Classification (always NULL — not implemented) |
