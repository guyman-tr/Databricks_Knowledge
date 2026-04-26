# Lineage: BI_DB_Compliance_Surveillance_KYC_PnL_Monitoring

## Writer
`BI_DB_dbo.SP_D_Compliance_Surveillance_KYC_PnL_Monitoring` — runs daily, TRUNCATE + INSERT (full refresh).

## ETL Flow

```
DWH_dbo.Dim_Customer (VerificationLevelID=3, IsDepositor=1, not blocked)
  └─► #Clients  ──────────────────────────────────────────────────────────────────────────────────────────────┐
                                                                                                              │
DWH_dbo.Dim_Regulation ─────────────────────────────────────────────────────────────────► Regulation name    │
DWH_dbo.Dim_Language ───────────────────────────────────────────────────────────────────► LanguageName       │
BI_DB_dbo.BI_DB_CIDFirstDates ──────────────────────────────────────────────────────────► Manager, dates,    │
                                                                                          Credit, RealizedEq │
BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (Q10, Q11, Q14, latest per CID) ─────────► Declared financial │
BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData (latest ActiveDate) ──────────────────────────► LifetimeNetDeposits│
DWH_dbo.Fact_CustomerAction (ActionTypeID 1-6, MAX Occurred) ───────────────────────────► LastTradeDate      │
BI_DB_dbo.BI_DB_PositionPnL (DateID = yesterday) ───────────────────────────────────────► Unrealized PnL,    │
                                                                                          Equity, Has_Open   │
DWH_dbo.Dim_Position (all closed positions, MirrorID split) ────────────────────────────► Lifetime PnL split │
                                                                                              │               │
                          ┌───────────────────────────────────────────────────────────────────┘               │
                          ▼                                                                                   │
                    Activity filter: LastTradeDate >= NOW-12mo OR LastDepositDate >= NOW-12mo OR Has_Open=1   │
                          │                                                                                   │
                          └──────────────────────────────────────────────────────────────────────────────────►
                                                    BI_DB_Compliance_Surveillance_KYC_PnL_Monitoring
```

## Source Tables

| Tier | Source | Columns Derived |
|------|--------|----------------|
| Tier 1 | `DWH_dbo.Dim_Customer` | RealCID, FirstName, LastName, BirthDate, Email, Gender, FirstDepositDate, RegulationID, LanguageID |
| Tier 1 | `DWH_dbo.Dim_Regulation` | Regulation (Name) |
| Tier 1 | `DWH_dbo.Dim_Language` | LanguageName |
| Tier 1 | `DWH_dbo.Dim_Position` | LifetimeRealisedPnL_SelfDirected, LifetimeRealisedPnL_Copy |
| Tier 1 | `DWH_dbo.Fact_CustomerAction` | LastTradeDate |
| Tier 2 | `BI_DB_dbo.BI_DB_CIDFirstDates` | Manager, VerificationLevel3Date, LastDepositDate, Credit (→ RealisedEquity/UnrealisedEquity base) |
| Tier 2 | `BI_DB_dbo.BI_DB_PositionPnL` | UnrealisedPnL_SelfDirected, UnrealisedPnL_Copy, CurrentInvestedAmount_SelfDirected, CurrentInvestedAmount_Copy, Has_Open_Position, RealisedEquity, UnrealisedEquity |
| Tier 2 | `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` | LifetimeNetDeposits (ACC_NetDeposits, latest ActiveDate) |
| Tier 2 | `BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data` | DeclaredNetIncome (Q10), DeclaredSavings (Q11), DeclaredPlannedInvestmentAmount (Q14) |

## Key Transformations
- **Population filter**: `VerificationLevelID = 3` (fully KYC-verified), `IsDepositor = 1`, `IsValidCustomer = 1`, `PlayerStatusID NOT IN (2, 4)` (exclude Blocked and Blocked Upon Request)
- **Activity filter** (final output gate): row included only if `LastTradeDate >= NOW-12mo` OR `LastDepositDate >= NOW-12mo` OR `Has_Open_Position = 1`
- **KYC answers**: latest answer per CID per question via `ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY OccurredAt DESC) = 1`; linked via GCID→RealCID join
- **PnL split**: self-directed vs copy determined by `MirrorID = 0` (self) vs `MirrorID > 0` (copy) on both Dim_Position and BI_DB_PositionPnL
- **Equity calculation**: `RealisedEquity = ISNULL(Credit, 0) + SUM(CurrentInvestedAmount)`; `UnrealisedEquity = ISNULL(Credit, 0) + SUM(UnrealisedEquityOnPositions)` — only clients with UnrealisedEquity > 0 pass the equity gate
- **Date storage**: BirthDate, FirstDepositDate, VerificationLevel3Date, LastTradeDate, UpdateDate stored as varchar(50) using `CONVERT(varchar(50), ..., 120)` format

## Downstream (Known)
No known downstream BI_DB tables depend on this table. Used directly by Compliance Surveillance dashboards and reports.
