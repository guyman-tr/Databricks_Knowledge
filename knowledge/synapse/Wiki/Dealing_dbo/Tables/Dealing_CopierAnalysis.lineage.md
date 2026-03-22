# Lineage — Dealing_dbo.Dealing_CopierAnalysis

## Writer
**SP_CopierAnalysis** (`Dealing_dbo.SP_CopierAnalysis`) — daily run, @date = yesterday. DELETE+INSERT pattern (deletes target date before inserting).

## Source Tables

| Source | Purpose |
|---|---|
| CopyFromLake.etoro_History_Mirror | Copy relationship history; latest row per MirrorID before @date |
| DWH_dbo.Dim_Mirror | InitialInvestment, OpenOccurred, CloseOccurred per mirror |
| DWH_dbo.Dim_Customer | CID identity, Gender, BirthDate (Age calculation) |
| DWH_dbo.Fact_SnapshotCustomer | Daily snapshot for GCID, PlayerLevelID, CountryID, AccountManagerID, GuruStatusID, AccountTypeID |
| DWH_dbo.Dim_Range | Date-range join for Fact_SnapshotCustomer (DateRangeID) |
| DWH_dbo.Dim_Country | Region, Country name |
| DWH_dbo.Dim_Language | Language name |
| DWH_dbo.Dim_PlayerLevel | Club name (Bronze/Silver/Gold/Platinum/Diamond) |
| DWH_dbo.Dim_Manager | AccountManager full name (FirstName + LastName) |
| DWH_dbo.V_Liabilities | TotalEquity = ABS(ActualNWA + Liabilities) |
| BI_DB_dbo.BI_DB_DailyPanel_Copy | PI demographics: Classification, TraderType, Region, Country, RiskScore |
| BI_DB_dbo.BI_DB_PositionPnL | Open positions for Num_Instruments, UnrealisedAmount, PIUnrealisedAmount |
| BI_DB_dbo.DWH_CIDsDailyRisk | Daily risk scores for 7-day RiskScore averaging |
| general.etoroGeneral_History_GuruCopiers | Cash, Investment, PnL (CopyPnL), AUM per copy relationship |

## Column Lineage

| Column | Source | Tier | Notes |
|---|---|---|---|
| Date | SP parameter (@date) | Tier 2 | |
| DateID | DWH_dbo.DateToDateID(@date) | Tier 2 | |
| MirrorID | etoro_History_Mirror.MirrorID | Tier 2 | Copy relationship identifier |
| CID | etoro_History_Mirror.CID | Tier 2 | Copier CID |
| ParentCID | etoro_History_Mirror.ParentCID | Tier 2 | PI or CopyFund CID |
| ParentUserName | etoro_History_Mirror.ParentUserName | Tier 2 | |
| GCID | Fact_SnapshotCustomer.GCID | Tier 2 | |
| ID | Dim_Customer.ID | Tier 1 | Encoded varbinary identifier |
| PI/CP | Computed: AccountTypeID=9 → CopyFund; GuruStatusID IN (2-6) → PI | Tier 2 | |
| UserName | Dim_Customer.UserName | Tier 1 | Copier username |
| IsActive | etoro_History_Mirror.IsActive | Tier 2 | 1=active (all stored rows are active) |
| InitialInvestment | Dim_Mirror.InitialInvestment | Tier 2 | |
| DepositSummary | etoro_History_Mirror.DepositSummary | Tier 2 | |
| WithdrawalSummary | etoro_History_Mirror.WithdrawalSummary | Tier 2 | |
| DaysCopying | DATEDIFF(day, OpenOccurred, @date) if active | Tier 2 | Days since copy relationship opened |
| OpenOccurred | Dim_Mirror.OpenOccurred | Tier 2 | |
| CloseOccurred | Dim_Mirror.CloseOccurred | Tier 2 | |
| CopySL | etoro_History_Mirror.MirrorSL | Tier 2 | Copy stop-loss percentage |
| Age | DATEDIFF(year, Dim_Customer.BirthDate, @date) | Tier 2 | Copier age in years |
| Club | Dim_PlayerLevel.Name | Tier 2 | |
| TotalEquity | ABS(V_Liabilities.ActualNWA + V_Liabilities.Liabilities) | Tier 2 | |
| RiskScore | Rounded 7-day avg of DWH_CIDsDailyRisk.AvgSTD mapped to 1-10 | Tier 2 | |
| Region | Dim_Country.Region | Tier 1 | Copier region |
| Country | Dim_Country.Name | Tier 1 | Copier country |
| Language | Dim_Language.Name | Tier 1 | |
| TraderType | Computed from avg holding time of copy relationship | Tier 2 | Day trader / Swing / Medium term / Long term investor |
| CopyPnL | etoroGeneral_History_GuruCopiers.PnL | Tier 2 | Unrealised PnL in the copy portfolio |
| Amount | etoroGeneral_History_GuruCopiers.Investment | Tier 2 | Invested amount in copy |
| Gender | Dim_Customer.Gender | Tier 1 | |
| Classification | Computed from BI_DB_PositionPnL asset-type allocation % | Tier 2 | Long Equity / Currencies / Crypto / Multi-Strategy / etc. |
| DaysCopyingGroup | Banded from DaysCopying | Tier 2 | Under 30 / 31-90 / 91-180 / 181-365 / 366-730 / Above 730 |
| CopyingAmountGroup | Banded from Amount | Tier 2 | 0-200 / 201-500 / 501-1000 / 1001-5000 / 5001-20000 / Above 20000 |
| PIClassification | BI_DB_DailyPanel_Copy.Classification | Tier 4 | PI classification label |
| PITraderType | BI_DB_DailyPanel_Copy.TraderType | Tier 4 | PI trader type |
| PIRegion | BI_DB_DailyPanel_Copy.Region | Tier 4 | PI region |
| PICountry | BI_DB_DailyPanel_Copy.Country | Tier 4 | PI country |
| PILanguage | Dim_Language.Name (via PI LanguageID) | Tier 4 | PI language |
| PIRiskScore | BI_DB_DailyPanel_Copy.RiskScore | Tier 4 | PI risk score |
| PIAge | DATEDIFF(year, PI BirthDate, @date) | Tier 2 | PI age in years |
| Positive/NegativePnL | CopyPnL >= 0 → Positive | Tier 2 | |
| AgeGroup | Banded from Age | Tier 2 | 18-24 / 25-30 / 31-40 / 41-50 / 51-60 / Above 60 |
| PIAgeGroup | Banded from PIAge | Tier 2 | |
| UnrealisedAmount | SUM(BI_DB_PositionPnL.Amount) for copier MirrorID | Tier 2 | |
| PIUnrealisedAmount | SUM(BI_DB_PositionPnL.Amount) for PI CID | Tier 2 | |
| Num_Instruments | COUNT(DISTINCT InstrumentID) in copier open positions | Tier 2 | |
| PI_NumPositions | COUNT(DISTINCT InstrumentID) in PI open positions | Tier 2 | |
| Cash | etoroGeneral_History_GuruCopiers.Cash | Tier 2 | Cash balance in copy portfolio |
| AUM | Cash + Investment + PnL | Tier 2 | Total copy portfolio value |
| AccountManager | Dim_Manager.FirstName + LastName | Tier 2 | Copier account manager |
| FirstName | NULL (hardcoded) | Tier 2 | Privacy-redacted — always NULL |
| Email | NULL (hardcoded) | Tier 2 | Privacy-redacted — always NULL |
| UpdateDate | GETDATE() | Tier 2 | ETL metadata |
