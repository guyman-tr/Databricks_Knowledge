# BI_DB_Compliance_Surveillance_KYC_PnL_Monitoring

## 1. Purpose
Compliance Surveillance report comparing each fully-verified customer's **declared KYC financials** (annual income, liquid savings, planned investment amount) against their **actual trading behavior** (lifetime PnL, current equity, invested amounts, open positions). Covers all active, non-blocked Level-3 KYC clients who have traded, deposited, or hold open positions within the last 12 months. One row per customer. Used by the Compliance team to detect suitability/appropriateness anomalies — e.g., clients whose trading losses exceed their declared income, or whose invested capital far exceeds declared savings.

## 2. Grain & Size
| Property | Value |
|----------|-------|
| **Grain** | One row per customer (`RealCID`) |
| **Row Count** | ~2,736,020 (as of 2026-04-12) |
| **Unique RealCIDs** | 2,736,020 (1:1) |
| **Refresh** | Daily, full refresh (TRUNCATE + INSERT) via `SP_D_Compliance_Surveillance_KYC_PnL_Monitoring` |
| **Last UpdateDate** | 2026-04-12 |

## 3. Key Business Rules
- **Population**: Only customers with `VerificationLevelID = 3` (fully KYC-verified), `IsDepositor = 1`, `IsValidCustomer = 1`, not blocked (`PlayerStatusID NOT IN (2, 4)`)
- **Activity gate**: Final output only includes clients active in the past 12 months — i.e., `LastTradeDate >= DATEADD(MONTH, -12, NOW)` OR `LastDepositDate >= NOW-12mo` OR `Has_Open_Position = 1`
- **Equity gate**: Clients with `UnrealisedEquity <= 0` are excluded (inner JOIN to #EquityIncCash WHERE UnrealisedEquity > 0)
- **KYC snapshot**: Declared financial values are the **most recent** answer per customer per question (`ROW_NUMBER() OVER PARTITION BY RealCID ORDER BY OccurredAt DESC = 1`)
- **PnL split**: Self-directed vs copy positions distinguished by `MirrorID = 0` (self-directed) vs `MirrorID > 0` (copy trade)
- **Date fields as varchar**: BirthDate, FirstDepositDate, LastTradeDate, VerificationLevel3Date, UpdateDate are stored as `varchar(50)` using SQL Server `FORMAT 120` (YYYY-MM-DD HH:MM:SS)

## 4. Regulation Distribution
| Regulation | Rows | % |
|------------|------|---|
| CySEC | 1,500,550 | 54.8% |
| FCA | 748,192 | 27.3% |
| FinCEN+FINRA | 157,983 | 5.8% |
| ASIC & GAML | 128,073 | 4.7% |
| FSA Seychelles | 118,756 | 4.3% |
| FSRA | 60,400 | 2.2% |
| Other (FinCEN, ASIC, MAS, BVI, NYDFS+FINRA, eToroUS, None) | ~22,066 | 0.8% |

## 5. Column Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. HASH distribution key. (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer) |
| 2 | FirstName | nvarchar(50) | YES | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). PII field. (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer) |
| 3 | LastName | nvarchar(50) | YES | Legal last name in Unicode. PII field. (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer) |
| 4 | BirthDate | datetime | YES | Customer date of birth. Used in KYC age verification. Stored as varchar(50) in source SP using CONVERT(varchar,BirthDate,120) before insert. PII field. (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer) |
| 5 | Regulation | varchar(50) | YES | Regulatory entity governing this account. Resolved from DWH_dbo.Dim_Regulation.Name via Dim_Customer.RegulationID. 13 values observed; CySEC=54.8%, FCA=27.3% top two. (Tier 1 — DWH_dbo.Dim_Regulation.Name) |
| 6 | DeclaredNetIncome | varchar(200) | YES | Customer's declared net annual income band from KYC (QuestionId=10: "What is your net annual income?"). Most recent answer per customer. Observed values: "Up to $10K", "$10K-$50K", "$50K-$200K", "$200K-$1M", "$500K-$1M", "$1M-$5M", and other historical bands. NULL if customer never answered this KYC question. (Tier 2 — BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data, QuestionId=10) |
| 7 | DeclaredSavings | varchar(200) | YES | Customer's declared total cash and liquid assets band from KYC (QuestionId=11: "What is your total cash and liquid assets?"). Most recent answer per customer. Same band taxonomy as DeclaredNetIncome. NULL if never answered. (Tier 2 — BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data, QuestionId=11) |
| 8 | RealisedEquity | money | YES | Customer's realized equity as of yesterday's snapshot. Computed as `ISNULL(Credit, 0) + SUM(CurrentInvestedAmount across all open positions)`. Credit sourced from BI_DB_CIDFirstDates; position amounts from BI_DB_PositionPnL. Only rows with UnrealisedEquity > 0 are included. (Tier 2 — SP_D_Compliance_Surveillance_KYC_PnL_Monitoring, BI_DB_CIDFirstDates.Credit + BI_DB_PositionPnL.Amount) |
| 9 | UnrealisedEquity | money | YES | Customer's unrealized equity as of yesterday, including open position PnL. Computed as `ISNULL(Credit, 0) + SUM(PositionPnL + Amount)` across all open positions. Minimum value is > 0 (gate condition for inclusion). (Tier 2 — SP_D_Compliance_Surveillance_KYC_PnL_Monitoring, BI_DB_CIDFirstDates.Credit + BI_DB_PositionPnL) |
| 10 | LifetimeRealisedPnL_SelfDirected | money | YES | Lifetime total realized PnL (NetProfit) from self-directed positions (MirrorID = 0) in DWH_dbo.Dim_Position. Negative = lifetime losses on manual trades. All historical closed positions included. (Tier 2 — SP_D_Compliance_Surveillance_KYC_PnL_Monitoring, DWH_dbo.Dim_Position.NetProfit WHERE MirrorID=0) |
| 11 | LifetimeRealisedPnL_Copy | money | YES | Lifetime total realized PnL from copy-trade positions (MirrorID > 0) in DWH_dbo.Dim_Position. NULL if customer never used copy trading. (Tier 2 — SP_D_Compliance_Surveillance_KYC_PnL_Monitoring, DWH_dbo.Dim_Position.NetProfit WHERE MirrorID>0) |
| 12 | UnrealisedPnL_SelfDirected | money | YES | Unrealized PnL on currently open self-directed positions as of yesterday. From BI_DB_PositionPnL.PositionPnL WHERE MirrorID = 0. NULL if no self-directed open positions. (Tier 2 — BI_DB_dbo.BI_DB_PositionPnL.PositionPnL WHERE MirrorID=0) |
| 13 | UnrealisedPnL_Copy | money | YES | Unrealized PnL on currently open copy-trade positions as of yesterday. From BI_DB_PositionPnL.PositionPnL WHERE MirrorID > 0. NULL if no copy positions open. (Tier 2 — BI_DB_dbo.BI_DB_PositionPnL.PositionPnL WHERE MirrorID>0) |
| 14 | CurrentInvestedAmount_SelfDirected | money | YES | Total dollar amount currently invested in open self-directed positions as of yesterday. From BI_DB_PositionPnL.Amount WHERE MirrorID = 0. NULL if no self-directed open positions. (Tier 2 — BI_DB_dbo.BI_DB_PositionPnL.Amount WHERE MirrorID=0) |
| 15 | CurrentInvestedAmount_Copy | money | YES | Total dollar amount currently invested in open copy-trade positions as of yesterday. From BI_DB_PositionPnL.Amount WHERE MirrorID > 0. NULL if no copy positions open. (Tier 2 — BI_DB_dbo.BI_DB_PositionPnL.Amount WHERE MirrorID>0) |
| 16 | LifetimeNetDeposits | money | YES | Lifetime accumulated net deposits (deposits minus cashouts). Sourced from ACC_NetDeposits in BI_DB_CID_MonthlyPanel_FullData at its latest ActiveDate snapshot. NULL if customer not in monthly panel. (Tier 2 — BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData.ACC_NetDeposits, latest ActiveDate) |
| 17 | LastTradeDate | varchar(50) | YES | Timestamp of the most recent trade action. MAX(Fact_CustomerAction.Occurred) WHERE ActionTypeID BETWEEN 1 AND 6. Stored as varchar(50) using CONVERT(varchar(50), Occurred, 120). NULL if no trade actions found. (Tier 2 — SP_D_Compliance_Surveillance_KYC_PnL_Monitoring, DWH_dbo.Fact_CustomerAction.Occurred) |
| 18 | Manager | nvarchar(500) | YES | Account manager full name (FirstName + ' ' + LastName) resolved from Dim_Manager via AccountManagerID. "System" for automated/unassigned accounts. (Tier 2 — BI_DB_dbo.BI_DB_CIDFirstDates.Manager) |
| 19 | Email | varchar(50) | YES | Customer email address. Unique per customer. PII field. (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer) |
| 20 | FirstDepositDate | varchar(50) | YES | Date of first deposit. Stored as varchar(50) using CONVERT(varchar(50), FirstDepositDate, 120). Sourced from Dim_Customer.FirstDepositDate. PII-adjacent. (Tier 2 — SP_D_Compliance_Surveillance_KYC_PnL_Monitoring, DWH_dbo.Dim_Customer.FirstDepositDate) |
| 21 | Gender | char(1) | YES | Gender: M, F, or U (Unknown). (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer) |
| 22 | VerificationLevel3Date | varchar(50) | YES | First date customer reached KYC verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3 from Fact_SnapshotCustomer. Stored as varchar(50). (Tier 2 — BI_DB_dbo.BI_DB_CIDFirstDates.VerificationLevel3Date) |
| 23 | DeclaredPlannedInvestmentAmount | varchar(200) | YES | Customer's declared planned investment amount band for next year from KYC (QuestionId=14: "How much money do you plan to invest in your eToro account in the next year?"). Most recent answer. Observed values: "Up to $20K", "$1k - $5k", and similar bands. NULL if never answered. (Tier 2 — BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data, QuestionId=14) |
| 24 | LanguageName | varchar(50) | YES | Customer preferred language name resolved from DWH_dbo.Dim_Language via Dim_Customer.LanguageID. Example values: "French", "English", "German", "Spanish". (Tier 1 — DWH_dbo.Dim_Language.Name via DWH_dbo.Dim_Customer.LanguageID) |
| 25 | UpdateDate | varchar(50) | YES | ETL metadata: SP execution timestamp (GETDATE() at run time) stored as varchar(50). Indicates when this daily snapshot was last refreshed. (Tier 3 — ETL metadata, SP_D_Compliance_Surveillance_KYC_PnL_Monitoring) |
| 26 | LastDepositDate | datetime | YES | Most recent deposit date. From BI_DB_CIDFirstDates.LastDepositDate. Used in the 12-month activity filter. (Tier 2 — BI_DB_dbo.BI_DB_CIDFirstDates.LastDepositDate) |
| 27 | Has_Open_Position | int | YES | Binary flag: 1 = customer has at least one open position as of yesterday (DateID = yesterday in BI_DB_PositionPnL), 0 = no open positions. Part of the activity gate — clients with Has_Open_Position=1 are included regardless of recent trade/deposit dates. (Tier 2 — SP_D_Compliance_Surveillance_KYC_PnL_Monitoring, BI_DB_PositionPnL WHERE DateID=yesterday) |

## 6. ETL Summary

```
DWH_dbo.Dim_Customer (L3 KYC, active depositors)
    + DWH_dbo.Dim_Regulation, Dim_Language
    + BI_DB_dbo.BI_DB_CIDFirstDates
    + BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (Q10/Q11/Q14, latest)
    + BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData (latest month)
    + DWH_dbo.Fact_CustomerAction (MAX trade Occurred)
    + BI_DB_dbo.BI_DB_PositionPnL (yesterday snapshot)
    + DWH_dbo.Dim_Position (lifetime realized PnL)
        ↓  TRUNCATE + INSERT (full daily refresh)
BI_DB_Compliance_Surveillance_KYC_PnL_Monitoring
```

- **OpsDB**: Priority 0, `SP_D_Compliance_Surveillance_KYC_PnL_Monitoring`, daily

## 7. Usage Notes
- **Compliance surveillance**: Primary use case is comparing declared vs actual financial exposure per customer. DeclaredNetIncome/DeclaredSavings/DeclaredPlannedInvestmentAmount should be compared against LifetimeRealisedPnL, CurrentInvestedAmount, and LifetimeNetDeposits.
- **PnL NULLs**: NULL in LifetimeRealisedPnL_Copy, UnrealisedPnL_Copy, CurrentInvestedAmount_Copy means the customer has never copied another trader — NOT a zero value. Use ISNULL(x, 0) when aggregating.
- **Equity gate**: Clients with zero or negative unrealized equity are excluded. The ~2.74M population represents active, positive-equity Level-3 clients only.
- **Date varchar fields**: BirthDate, FirstDepositDate, LastTradeDate, VerificationLevel3Date, UpdateDate are `varchar(50)` — cast to DATETIME before date arithmetic: `CAST(LastTradeDate AS DATETIME)`.
- **KYC answer bands vary by era**: DeclaredNetIncome values include legacy bands ("$10K-25K", "Less than $25K") from older questionnaire versions alongside current bands — normalize before analysis.

## 8. Tier Breakdown
| Tier | Column Count | Source |
|------|-------------|--------|
| Tier 1 | 8 | Customer.CustomerStatic (RealCID, FirstName, LastName, BirthDate, Email, Gender), Dim_Regulation (Regulation), Dim_Language (LanguageName) |
| Tier 2 | 18 | BI_DB_CIDFirstDates (Manager, VerificationLevel3Date, LastDepositDate, Credit→Equity), BI_DB_PositionPnL (PnL/equity/invested splits, Has_Open_Position), Dim_Position (LifetimePnL splits), Fact_CustomerAction (LastTradeDate), BI_DB_CID_MonthlyPanel_FullData (LifetimeNetDeposits), BI_DB_KYC_Questions_Answers_Row_Data (3 declared fields), SP transforms (FirstDepositDate varchar, RealisedEquity, UnrealisedEquity) |
| Tier 3 | 1 | UpdateDate (ETL metadata) |
