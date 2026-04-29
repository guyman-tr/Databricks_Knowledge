# BI_DB_dbo.BI_DB_W_Mon_Compliance_CDIM_Report

> 575,272-row FCA compliance CDIM (Consumer Duty Information Model) report capturing verified FCA depositors who traded in the past year. Combines customer demographics, KYC questionnaire answers (15 questions), appropriateness test results, MiFID categorisation, demo usage, knowledge assessment, negative market outcomes, and lifetime PnL split by asset class (CFD/Stocks/Crypto) and trading mode (Copy/Manual). Refreshed daily via TRUNCATE+INSERT by SP_W_Mon_Compliance_CDIM_Report (SB_Daily).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: Dim_Customer (primary) + 5 dim lookups + CIDFirstDates + KYC_Panel + Demo_CID_Panel + Scored_Appropriateness + KYC_Knowledge_Assessment + Dim_Position + BI_DB_PositionPnL + Fact_CustomerAction via SP_W_Mon_Compliance_CDIM_Report |
| **Refresh** | Daily TRUNCATE+INSERT via SB_Daily |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a comprehensive FCA Consumer Duty compliance snapshot. Each row represents one FCA-regulated customer who is verified, depositing, not blocked/blocked-upon-request, and has opened or closed at least one position in the past year. It consolidates ~16 data sources into a single denormalized report for the FCA Compliance team.

The report serves the FCA's Consumer Duty Information Model (CDIM) requirements by providing:
- **Customer profile**: regulation, club tier, desk, MiFID classification, country, age (via BirthDate)
- **KYC questionnaire answers**: 15 questions covering occupation, income, investment amount, trading experience, risk tolerance, trading strategy, knowledge assessment
- **Appropriateness testing**: pass/fail/borderline outcomes from the scored appropriateness assessment
- **Demo experience**: whether the client used demo before live trading
- **Knowledge assessment**: 142-146 version pass/fail with total score
- **Lifetime PnL**: realised + unrealised profit/loss split into 6 buckets (CFD Copy, CFD Manual, Stocks Copy, Stocks Manual, Crypto Copy, Crypto Manual), with CFD PnL adjusted for rollover fees
- **Negative market**: whether the client failed the negative market block (BlockReasonID=12)

Population: ~575K FCA customers (RegulationID=2). Dominated by UK desk (81%), Bronze tier (70%), Retail MiFID classification (65%).

---

## 2. Business Logic

### 2.1 FCA Active Trader Population

**What**: Restricts to FCA-regulated verified depositors who traded in the past year.
**Columns Involved**: CID, Regulation
**Rules**:
- Dim_Customer.IsValidCustomer = 1
- Dim_Customer.VerificationLevelID = 3
- Dim_Customer.IsDepositor = 1
- Dim_Regulation.DWHRegulationID = 2 (FCA)
- Dim_PlayerStatus.PlayerStatusID NOT IN (2, 4) — excludes Blocked and Blocked Upon Request
- Must have at least one position opened or closed in the past year (Dim_Position.OpenDateID or CloseDateID >= 1 year ago)

### 2.2 Lifetime PnL Calculation (6 Buckets)

**What**: Combines realised PnL (from Dim_Position.NetProfit) with unrealised PnL (from BI_DB_PositionPnL.PositionPnL as of yesterday) split by asset class and copy/manual.
**Columns Involved**: CFD_Copy_PnL, CFD_Manual_PnL, Stocks_Copy_PnL, Stocks_Manual_PnL, Crypto_Copy_PnL, Crypto_Manual_PnL
**Rules**:
- CFD = IsSettled=0 (non-settled instruments)
- Stocks = IsSettled=1 AND InstrumentType IN ('Stocks', 'ETF')
- Crypto = IsSettled=1 AND InstrumentType = 'Crypto Currencies'
- Copy = MirrorID <> 0; Manual = MirrorID = 0
- CFD PnL is adjusted: subtracted by rollover fees (Fact_CustomerAction.ActionTypeID=35, IsFeeDividend=1)

### 2.3 Demo Before Live Check

**What**: Determines if customer used demo platform before making their first live action.
**Columns Involved**: IsTradedDemo, UsedDemoBeforeLivePlatform
**Rules**:
- If IsTradedDemo=0 → UsedDemoBeforeLivePlatform = NULL
- If FirstDemoTrade < FirstActionDate → 1 (used demo first)
- If FirstDemoTrade >= FirstActionDate → 0 (did not use demo first)

### 2.4 Knowledge Assessment Encoding

**What**: Converts numeric pass flag to text.
**Columns Involved**: Knowledge_Assessment_Pass, Knowledge_Assessment_Score
**Rules**:
- Is_Assessment_142_146_Pass = -1 → 'No Answer'
- Is_Assessment_142_146_Pass = 1 → 'Yes'
- Otherwise → 'No'

### 2.5 Affiliate Origin Flag

**What**: Identifies customers who came through affiliate channels.
**Columns Involved**: CameFromAffiliate
**Rules**:
- SubChannelID IN (20, 31) → 1 (affiliate), else 0

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — 575K rows, no distribution key optimization. Full table scan is fast at this size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PnL distribution by club tier | `SELECT Club, AVG(CFD_Copy_PnL + CFD_Manual_PnL) ... GROUP BY Club` |
| Appropriateness pass rate by desk | `SELECT Desk, Appropriateness_Status, COUNT(*) ... GROUP BY Desk, Appropriateness_Status` |
| Demo usage impact on PnL | `GROUP BY UsedDemoBeforeLivePlatform`, compare average PnL |
| KYC answer distribution | `SELECT Occupation, COUNT(*) ... GROUP BY Occupation` for any KYC column |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile |
| BI_DB_dbo.BI_DB_KYC_Panel | CID = RealCID | Full KYC questionnaire details |
| BI_DB_dbo.BI_DB_CIDFirstDates | CID = CID | First dates and milestone data |

### 3.4 Gotchas

- **FCA only**: Regulation column is always 'FCA' — this table is not multi-regulation
- **PlayerStatus trailing spaces**: Apply RTRIM() for string comparisons
- **Appropriateness_Status blank values**: 356 rows have empty string (not NULL) — likely missing assessment
- **NegativeMarket mostly NULL**: Only populated for customers who failed BlockReasonID=12
- **CFD PnL includes rollover adjustment**: CFD_Copy_PnL and CFD_Manual_PnL subtract rollover fees; Stocks/Crypto PnL does not
- **Knowledge_Assessment_Pass text encoding**: 'No Answer' (-1), 'Yes' (1), 'No' (0/NULL) — not boolean
- **KYC columns are answer text**: Abbreviated column names (e.g., RiskRewardSc = Q9 Risk/Reward Scenario answer text, CashLiquAst = Q11 Cash Liquid Assets answer text)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data sampling |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Standard ETL metadata or infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Regulation | varchar(250) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Always 'FCA' in this table due to DWHRegulationID=2 filter. (Tier 1 — Dictionary.Regulation) |
| 3 | PlayerStatus | varchar(250) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. Excludes Blocked (2) and Blocked Upon Request (4). (Tier 1 — Dictionary.PlayerStatus) |
| 4 | Club | varchar(250) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel. (Tier 1 — Dictionary.PlayerLevel) |
| 5 | Desk | nvarchar(250) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. Examples: UK, Asia, South & Central America, Arabic, ROW, Other EU, French, Spain, Australia, German, Italian. Passthrough from Dim_Country. (Tier 3 — Ext_Dim_Country_Region_Desk via SP) |
| 6 | Manager | nvarchar(250) | YES | Account manager full name. Resolved from Dim_Manager: FirstName+' '+LastName via AccountManagerID. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates, Dim_Manager) |
| 7 | MifidCategorisation | nvarchar(250) | YES | Human-readable MiFID II classification label. Used in compliance dashboards and regulatory reports. Values: Retail, Retail Pending, Pending, Elective professional. Passthrough from Dim_MifidCategorization. (Tier 1 — Dictionary.MifidCategorization) |
| 8 | CountryOfResidence | nvarchar(250) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 9 | BirthDate | datetime | YES | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic) |
| 10 | CameFromAffiliate | int | YES | 1 if SubChannelID IN (20, 31) indicating affiliate acquisition channel, 0 otherwise. (Tier 2 — SP_W_Mon_Compliance_CDIM_Report) |
| 11 | VerificationLevel3Date | date | YES | First date customer reached verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3. Backfills levels 1 and 2 if not already set. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 12 | Occupation | nvarchar(250) | YES | KYC Q18 answer text — customer's stated occupation. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 13 | RiskRewardSc | nvarchar(250) | YES | KYC Q9 answer text — customer's risk/reward scenario preference. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 14 | AnnualInc | nvarchar(250) | YES | KYC Q10 answer text — customer's stated annual income range. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 15 | CashLiquAst | nvarchar(250) | YES | KYC Q11 answer text — customer's stated cash and liquid assets range. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 16 | PurposeTrad | nvarchar(250) | YES | KYC Q8 answer text — customer's primary purpose of trading. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 17 | PlanInvAmt | nvarchar(250) | YES | KYC Q14 answer text — customer's planned investment amount. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 18 | Appropriateness_Status | nvarchar(250) | YES | Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Values: Failed, Passed, Borderline Pass, blank. Passthrough from BI_DB_Scored_Appropriateness_Negative_Market. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched) |
| 19 | AVG_CFD_Leverage | money | YES | Mean average CFD leverage used across all non-settled (CFD) positions to date. AVG(Leverage) WHERE IsSettled=0 from Dim_Position. NULL if no CFD positions. (Tier 2 — SP_W_Mon_Compliance_CDIM_Report) |
| 20 | IsTradedDemo | int | YES | Whether the user has traded on demo. 1 = traded, 0 = registered but never traded. Passthrough from BI_DB_Demo_CID_Panel. (Tier 2 — SP_Demo_CID_Panel) |
| 21 | UsedDemoBeforeLivePlatform | int | YES | 1 if customer's first demo trade was before their first live action, 0 if after, NULL if no demo trading. Computed from BI_DB_Demo_CID_Panel.FirstDemoTrade vs BI_DB_First5Actions.FirstActionDate. (Tier 2 — SP_W_Mon_Compliance_CDIM_Report) |
| 22 | KnowledgeAsst | nvarchar(250) | YES | KYC Q23 answer text — customer's self-assessed investment knowledge. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 23 | RelevKnowl | nvarchar(250) | YES | Composite STRING_AGG of Q3 credential flags (e.g., "Professional Experience, Academic Degree"). Not a single answer text. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 24 | InvAmtCFD | nvarchar(500) | YES | KYC Q45 answer text — customer's planned investment amount in CFDs. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 25 | InvAmtCrypto | nvarchar(500) | YES | KYC Q48 answer text — customer's planned investment amount in crypto. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 26 | Knowledge_Assessment_Pass | nvarchar(500) | YES | Knowledge assessment 142-146 version pass result. Encoded: 'Yes' if passed (total points > -3), 'No' if failed, 'No Answer' if version not taken (-1). (Tier 2 — SP_W_Mon_Compliance_CDIM_Report via BI_DB_KYC_Knowledge_Assessment) |
| 27 | Knowledge_Assessment_Score | int | YES | Total score for 142-146 knowledge assessment version. Range: -10 to +10. Each of 5 questions contributes +2 or -2. -100 sentinel if version not taken. Passthrough from BI_DB_KYC_Knowledge_Assessment. (Tier 2 — SP_KYC_Panel) |
| 28 | Trading_Strategy | nvarchar(500) | YES | KYC Q5 answer text — customer's stated trading strategy. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 29 | ExpCrypto | nvarchar(250) | YES | KYC Q34 answer text — customer's crypto trading experience level. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 30 | ExpEquities | nvarchar(250) | YES | KYC Q33 answer text — customer's equities trading experience level. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 31 | ExpCFD | nvarchar(250) | YES | KYC Q35 answer text — customer's CFD trading experience level. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 32 | SourceIncome | nvarchar(250) | YES | STRING_AGG of all selected income source answer texts (multi-select Q15). Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 33 | SourceFunds | nvarchar(250) | YES | STRING_AGG of all selected fund source answer texts (multi-select Q26). Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |
| 34 | NegativeMarket | nvarchar(250) | YES | Negative market block reason description. Populated only for customers who failed BlockReasonID=12 (negative market block). NULL if not failed. Passthrough from BI_DB_Scored_Appropriateness_Negative_Market.BlockReasonDesc. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 35 | CFD_Copy_PnL | money | YES | Lifetime copy-trading CFD PnL (realised + unrealised) minus rollover fees. MirrorID<>0, IsSettled=0. Realised from Dim_Position.NetProfit, unrealised from BI_DB_PositionPnL as of yesterday, rollover from Fact_CustomerAction ActionTypeID=35. (Tier 2 — SP_W_Mon_Compliance_CDIM_Report) |
| 36 | CFD_Manual_PnL | money | YES | Lifetime manual CFD PnL (realised + unrealised) minus rollover fees. MirrorID=0, IsSettled=0. Same calculation as CFD_Copy_PnL but for manual trades. (Tier 2 — SP_W_Mon_Compliance_CDIM_Report) |
| 37 | Stocks_Copy_PnL | money | YES | Lifetime copy-trading stocks/ETF PnL (realised + unrealised). MirrorID<>0, IsSettled=1, InstrumentType IN ('Stocks','ETF'). No rollover adjustment. (Tier 2 — SP_W_Mon_Compliance_CDIM_Report) |
| 38 | Stocks_Manual_PnL | money | YES | Lifetime manual stocks/ETF PnL (realised + unrealised). MirrorID=0, IsSettled=1, InstrumentType IN ('Stocks','ETF'). No rollover adjustment. (Tier 2 — SP_W_Mon_Compliance_CDIM_Report) |
| 39 | Crypto_Copy_PnL | money | YES | Lifetime copy-trading crypto PnL (realised + unrealised). MirrorID<>0, IsSettled=1, InstrumentType='Crypto Currencies'. No rollover adjustment. (Tier 2 — SP_W_Mon_Compliance_CDIM_Report) |
| 40 | Crypto_Manual_PnL | money | YES | Lifetime manual crypto PnL (realised + unrealised). MirrorID=0, IsSettled=1, InstrumentType='Crypto Currencies'. No rollover adjustment. (Tier 2 — SP_W_Mon_Compliance_CDIM_Report) |
| 41 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |
| 42 | InvAmtEquities | nvarchar(500) | YES | KYC Q47 answer text — customer's planned investment amount in equities. Passthrough from BI_DB_KYC_Panel. (Tier 2 — BI_DB_KYC_Panel, CODE-BACKED) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | Rename from RealCID via Dim_Customer |
| Regulation | Dictionary.Regulation | Name | Dim lookup (always FCA) |
| PlayerStatus | Dictionary.PlayerStatus | Name | Dim lookup |
| Club | Dictionary.PlayerLevel | Name | Dim lookup via Dim_PlayerLevel |
| Desk | Ext_Dim_Country_Region_Desk | Desk | Via Dim_Country MarketingRegionID |
| Manager | Dim_Manager | FirstName+LastName | Via BI_DB_CIDFirstDates |
| MifidCategorisation | Dictionary.MifidCategorization | Name | Dim lookup |
| CountryOfResidence | Dictionary.Country | Name | Dim lookup via Dim_Country |
| BirthDate | Customer.CustomerStatic | BirthDate | Passthrough via Dim_Customer |
| KYC columns (12) | UserApiDB KYC_Questions_Answers | Answer texts | Via BI_DB_KYC_Panel pivot |
| PnL columns (6) | Trade.PositionTbl + BI_DB_PositionPnL | NetProfit, PositionPnL | Aggregated by asset/mode |
| Appropriateness_Status | ComplianceStateDB | RestrictionStatus.Name | Via BI_DB_Scored_Appropriateness |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (FCA, verified, depositors, not blocked)
  + Dim_Country, Dim_PlayerStatus, Dim_PlayerLevel, Dim_Regulation, Dim_MifidCategorization
  + BI_DB_CIDFirstDates (Manager, VL3Date)
    |-- #pop (base population, ~575K FCA customers) ---|
    |
  + DWH_dbo.Dim_Position (active trader filter: traded in past year)
    |-- #pop2 (active traders) ---|
    |
  + BI_DB_KYC_Panel (15 KYC answers) → #KYC_Output
  + BI_DB_Demo_CID_Panel + BI_DB_First5Actions → #Demo
  + BI_DB_Scored_Appropriateness_Negative_Market → #Appropriateness + #NegativeMarket
  + BI_DB_KYC_Knowledge_Assessment → #KYC_Knowledge_Assessment
  + DWH_dbo.Dim_Position + Dim_Instrument → #RealisedPnL (6 buckets)
  + BI_DB_PositionPnL + Dim_Instrument → #UnrealisedPnL (6 buckets)
  + Fact_CustomerAction (ActionTypeID=35) → #Rollover (copy/manual)
    |
    |-- #LifetimePnL (realised + unrealised, CFD adjusted for rollover) ---|
    |-- #CFD_Leverage (AVG CFD leverage) ---|
    |
    |-- #CD_Final (all temp tables joined) ---|
    v
  TRUNCATE TABLE BI_DB_dbo.BI_DB_W_Mon_Compliance_CDIM_Report
  INSERT INTO BI_DB_dbo.BI_DB_W_Mon_Compliance_CDIM_Report
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Primary customer dimension |
| Club | DWH_dbo.Dim_PlayerLevel.Name | Customer loyalty tier |
| MifidCategorisation | DWH_dbo.Dim_MifidCategorization.Name | MiFID II classification |
| KYC columns | BI_DB_dbo.BI_DB_KYC_Panel | Full KYC questionnaire |
| Appropriateness_Status | BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | Appropriateness assessment |
| PnL columns | DWH_dbo.Dim_Position, BI_DB_dbo.BI_DB_PositionPnL | Trading P&L data |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| (none identified) | — | Table appears to be a terminal compliance report |

---

## 7. Sample Queries

### 7.1 Appropriateness Pass Rate by MiFID Category

```sql
SELECT MifidCategorisation,
       COUNT(*) AS Total,
       SUM(CASE WHEN Appropriateness_Status = 'Passed' THEN 1 ELSE 0 END) AS Passed,
       CAST(SUM(CASE WHEN Appropriateness_Status = 'Passed' THEN 1.0 ELSE 0 END) / COUNT(*) * 100 AS DECIMAL(5,1)) AS Pass_Rate_Pct
FROM BI_DB_dbo.BI_DB_W_Mon_Compliance_CDIM_Report
GROUP BY MifidCategorisation
ORDER BY Total DESC
```

### 7.2 Average PnL by Club Tier and Trading Mode

```sql
SELECT Club,
       AVG(CFD_Copy_PnL) AS Avg_CFD_Copy,
       AVG(CFD_Manual_PnL) AS Avg_CFD_Manual,
       AVG(Stocks_Copy_PnL) AS Avg_Stocks_Copy,
       AVG(Stocks_Manual_PnL) AS Avg_Stocks_Manual
FROM BI_DB_dbo.BI_DB_W_Mon_Compliance_CDIM_Report
GROUP BY Club
ORDER BY Club
```

### 7.3 Demo Usage Impact on Trading Outcomes

```sql
SELECT UsedDemoBeforeLivePlatform,
       COUNT(*) AS Customers,
       AVG(CFD_Copy_PnL + CFD_Manual_PnL + Stocks_Copy_PnL + Stocks_Manual_PnL + Crypto_Copy_PnL + Crypto_Manual_PnL) AS Avg_Total_PnL,
       SUM(CASE WHEN Appropriateness_Status = 'Passed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS Appropriateness_Pass_Pct
FROM BI_DB_dbo.BI_DB_W_Mon_Compliance_CDIM_Report
GROUP BY UsedDemoBeforeLivePlatform
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found specific to this table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 7 T1, 33 T2, 1 T3, 0 T4, 1 T5 | Elements: 42/42, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_W_Mon_Compliance_CDIM_Report | Type: Table | Production Source: Multi-source via SP_W_Mon_Compliance_CDIM_Report*
