# BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report

> FCA compliance reporting table for the CDIM (Client Data Integrity Monitoring) programme -- one row per FCA-regulated, fully verified (Level 3), depositing customer who has opened or closed a position in the past year. Consolidates customer demographics, KYC questionnaire answers (29 pivoted fields), appropriateness test results, negative market status, demo account usage, average CFD leverage, and lifetime P&L split by asset class (CFD/Stocks/Crypto) and trading mode (Copy/Manual). Refreshed daily via SP_M_Compliance_CDIM_Report (TRUNCATE + INSERT). Currently 0 rows (table may not have been refreshed recently).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Compliance Report) |
| **Production Source** | Multi-source: Dim_Customer, Dim_Position, BI_DB_PositionPnL, BI_DB_CIDFirstDates, BI_DB_KYCUserRawDataLeveled, BI_DB_Scored_Appropriateness_Negative_Market, BI_DB_Demo_CID_Panel, BI_DB_First5Actions, Fact_CustomerAction + 6 dimension lookups via SP_M_Compliance_CDIM_Report |
| **Refresh** | Daily (TRUNCATE + INSERT via SP_M_Compliance_CDIM_Report) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_M_Compliance_CDIM_Report` is a compliance analytics table built for the FCA (Financial Conduct Authority) CDIM programme. It provides a single-row-per-customer snapshot of every FCA-regulated client who meets all of the following criteria:

1. **IsValidCustomer = 1** (not PlayerLevelID=4, not LabelID 26/30, not CountryID=250)
2. **RegulationID = 2** (FCA only)
3. **VerificationLevelID = 3** (fully KYC-verified)
4. **IsDepositor = 1** (has deposited at least once)
5. **PlayerStatusID NOT IN (2, 4)** (not Blocked or Blocked Upon Request)
6. **Opened or closed at least one position in the past year**

The table consolidates data from 16 source objects into 51 columns covering:
- **Customer demographics** (10 columns): CID, regulation, status, club tier, desk, manager, MiFID categorisation, country, birth date, affiliate flag
- **KYC questionnaire answers** (29 columns): Pivoted from `BI_DB_KYCUserRawDataLeveled` covering trading experience, risk appetite, investment plans, regulatory disclosures
- **Compliance assessments** (3 columns): Appropriateness test status, negative market block reason, demo usage before live
- **Trading metrics** (8 columns): Average CFD leverage, lifetime P&L split by asset class (CFD/Stocks/Crypto) and mode (Copy/Manual)
- **Metadata** (1 column): UpdateDate

The ETL is a full daily TRUNCATE + INSERT. The SP first builds the eligible population (#pop), filters to those with recent trading activity (#pop2), then enriches with KYC answers (pivoted), appropriateness/negative market status, demo usage, CFD leverage, and combined realised+unrealised P&L (net of rollover fees for CFD positions).

The table is consumed by the FCA compliance team (complianceuk@etoro.com) for regulatory reporting on client outcomes, appropriateness assessment coverage, and P&L monitoring.

---

## 2. Business Logic

### 2.1 Population Filter (FCA CDIM Scope)

**What**: Multi-criteria filter restricting the population to FCA-regulated, verified, active depositors.

**Columns Involved**: All (determines which CIDs appear)

**Rules**:
- `Dim_Customer.IsValidCustomer = 1` -- excludes Popular Investor (PlayerLevelID=4), labels 26/30, CountryID=250
- `Dim_Regulation.DWHRegulationID = 2` -- FCA regulation only
- `Dim_Customer.VerificationLevelID = 3` -- fully verified (Level 3 KYC)
- `Dim_Customer.IsDepositor = 1` -- must have deposited
- `Dim_PlayerStatus.PlayerStatusID NOT IN (2, 4)` -- not blocked or self-blocked
- Must have opened or closed at least one position in Dim_Position within the past year (`OpenDateID >= @1yearagoid OR CloseDateID >= @1yearagoid`)

### 2.2 CameFromAffiliate Flag

**What**: Binary flag indicating whether the customer was acquired through specific affiliate sub-channels.

**Columns Involved**: `CameFromAffiliate`

**Rules**:
- `CASE WHEN Dim_Customer.SubChannelID IN (20, 31) THEN 1 ELSE 0 END`
- SubChannelID 20 and 31 are specific affiliate-related sub-channels in Dim_Channel

### 2.3 UsedDemoBeforeLivePlatform Flag

**What**: Whether the customer traded on a demo account before their first live trade.

**Columns Involved**: `UsedDemoBeforeLivePlatform`, `IsTradedDemo`

**Rules**:
- NULL when `IsTradedDemo = 0` (never traded demo)
- 1 when `FirstDemoTrade < FirstActionDate` (demo trade preceded first live action)
- 0 when `FirstDemoTrade >= FirstActionDate` (live trade came first or same day)
- Sources: `BI_DB_Demo_CID_Panel.FirstDemoTrade` and `BI_DB_First5Actions.FirstActionDate`

### 2.4 Lifetime P&L Calculation (CFD, Stocks, Crypto)

**What**: Combined realised + unrealised P&L per asset class and trading mode, net of rollover fees for CFD.

**Columns Involved**: `CFD_Copy_PnL`, `CFD_Manual_PnL`, `Stocks_Copy_PnL`, `Stocks_Manual_PnL`, `Crypto_Copy_PnL`, `Crypto_Manual_PnL`

**Rules**:
- **Realised PnL**: SUM(NetProfit) from Dim_Position grouped by MirrorID (copy vs manual), IsSettled (CFD vs real), and InstrumentType (Stocks/ETF vs Crypto)
- **Unrealised PnL**: SUM(PositionPnL) from BI_DB_PositionPnL for yesterday's date (DateID = @PnLDateid), same grouping
- **Rollover fees**: SUM(Amount) from Fact_CustomerAction WHERE ActionTypeID=35 AND IsFeeDividend=1, split by IsCopy flag
- **CFD PnL formula**: `(Realised + Unrealised) - Rollover fees` -- rollover fees are subtracted only from CFD P&L
- **Stocks/Crypto PnL**: `Realised + Unrealised` (no rollover deduction)
- Asset class mapping: CFD = `IsSettled=0`; Stocks = `IsSettled=1 AND InstrumentType IN ('Stocks','ETF')`; Crypto = `IsSettled=1 AND InstrumentType='Crypto Currencies'`
- Copy vs Manual: `MirrorID <> 0` = Copy; `MirrorID = 0` = Manual

### 2.5 KYC Answer Pivot

**What**: 29 KYC questionnaire answers pivoted from rows to columns.

**Columns Involved**: Occupation, RiskRewardSc, AnnualInc, CashLiquAst, PurposeTrad, PlanInvAmt, KnowledgeAsst, RelevKnowl, Inv10Income, EduTools, NotCrimea, ReadRisks, InvAmtCFD, WhichInst, IsraeliQlf, RiskDiscl, RiskReview, SuitExpHigh, SuitExpLow, SuitObjHigh, SuitObjLow, ExpCrypto, ExpEquities, ExpCFD, TradingFreq, SourceIncome, TradExp, MktsTraded, SourceFunds

**Rules**:
- Source: `BI_DB_KYCUserRawDataLeveled` (QuestionText, AnswerText per CID)
- Each column maps to a specific QuestionText string via SQL PIVOT
- MAX(AnswerText) used as aggregation (one answer per question per CID expected)
- NULL if the customer has not answered that particular question

### 2.6 Average CFD Leverage

**What**: Mean leverage used across all CFD positions for each customer.

**Columns Involved**: `AVG_CFD_Leverage`

**Rules**:
- `AVG(CASE WHEN IsSettled = 0 THEN Leverage * 1.00 END)` from Dim_Position
- Only CFD positions (IsSettled=0) contribute; real/settled positions excluded
- NULL if the customer has no CFD positions

### 2.7 Negative Market Status

**What**: Whether the customer has been blocked from CFD trading due to failing the appropriateness test.

**Columns Involved**: `NegativeMarket`

**Rules**:
- Source: `BI_DB_Scored_Appropriateness_Negative_Market.BlockReasonDesc`
- Filtered to `BlockReasonID = 12 AND RestrictionStatusDesc = 'Failed'`
- NULL if the customer was not blocked for this specific reason

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with HEAP. No clustered index or distribution key optimisation. The table is designed for full-scan compliance reporting, not point lookups. With the FCA population filter, expected row count is in the hundreds of thousands (not millions), making full scans acceptable.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Appropriateness test pass/fail rate | `SELECT Appropriateness_Status, COUNT(*) GROUP BY Appropriateness_Status` |
| P&L by asset class | `SELECT SUM(CFD_Copy_PnL + CFD_Manual_PnL) AS CFD_Total, SUM(Stocks_Copy_PnL + Stocks_Manual_PnL) AS Stocks_Total, SUM(Crypto_Copy_PnL + Crypto_Manual_PnL) AS Crypto_Total` |
| High-leverage CFD users | `WHERE AVG_CFD_Leverage > 10` |
| KYC coverage gaps | `WHERE Occupation IS NULL OR AnnualInc IS NULL` |
| Negative market blocked customers | `WHERE NegativeMarket IS NOT NULL` |
| Demo-to-live conversion | `WHERE UsedDemoBeforeLivePlatform = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Extended customer attributes not in this report |
| DWH_dbo.Dim_Country | ON CountryOfResidence = Name | Country details (though CountryOfResidence is already the decoded name) |
| BI_DB_dbo.BI_DB_CIDFirstDates | ON CID = CID | Additional lifecycle milestones |

### 3.4 Gotchas

- **FCA only**: This table only contains RegulationID=2 (FCA) customers. For other regulations, see `SP_W_Mon_Compliance_CDIM_Report` (weekly/monthly variant).
- **Table may be empty**: TRUNCATE + INSERT pattern means the table is empty between the TRUNCATE and the INSERT. If queried mid-ETL, returns 0 rows.
- **Regulation column is always 'FCA'**: Hardcoded filter `DWHRegulationID = 2` means all rows have Regulation = 'FCA'. The column exists for schema consistency with the weekly variant.
- **CFD PnL is net of rollover fees**: CFD_Copy_PnL and CFD_Manual_PnL subtract overnight/weekend fees (rollover). Stocks and Crypto PnL do NOT deduct rollover.
- **KYC columns are free-text answers**: The 29 KYC columns contain the customer's verbatim answer text, not coded values. Some answers may be very long or contain special characters.
- **PlayerStatus excludes Blocked (2) and Blocked Upon Request (4)**: But includes other restricted statuses like Under Investigation (6), Scalpers Block (7), etc. Only full blocks are excluded.
- **NegativeMarket is only BlockReasonID=12**: Other block reasons from the appropriateness table are not captured. NULL does not mean "not blocked" -- it means "not blocked specifically for reason 12 with Failed restriction status".
- **AVG_CFD_Leverage can be NULL**: Customers who have only traded real stocks/crypto (IsSettled=1) will have NULL leverage.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki verbatim (description inherited from documented source) |
| Tier 2 | SP code / ETL logic |
| Tier 3 | Live data / no upstream wiki |

### 4.1 Customer Identity & Demographics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID. (Tier 1 -Customer.CustomerStatic) |
| 2 | Regulation | varchar(250) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Always 'FCA' in this table (filtered to DWHRegulationID=2). Dim-lookup from Dim_Regulation.Name. (Tier 1 -Dictionary.Regulation) |
| 3 | PlayerStatus | varchar(250) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Excludes Blocked (2) and Blocked Upon Request (4) in this table. Dim-lookup from Dim_PlayerStatus.Name. (Tier 1 -Dictionary.PlayerStatus) |
| 4 | Club | varchar(250) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID. (Tier 1 -Dictionary.PlayerLevel) |
| 5 | Desk | nvarchar(250) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping for this marketing region. Dim-lookup from Dim_Country.Desk via CountryID. (Tier 1 -Ext_Dim_Country_Region_Desk) |
| 6 | Manager | nvarchar(250) | YES | Assigned account manager full name. ETL-computed: Dim_Manager.FirstName + ' ' + Dim_Manager.LastName via AccountManagerID. NULL if no manager assigned. Passthrough from BI_DB_CIDFirstDates. (Tier 2 -BI_DB_CIDFirstDates) |
| 7 | MifidCategorisation | nvarchar(250) | YES | Human-readable MiFID II classification label. Used in compliance dashboards and regulatory reports. Dim-lookup from Dim_MifidCategorization.Name via MifidCategorizationID. (Tier 1 -Dictionary.MifidCategorization) |
| 8 | CountryOfResidence | nvarchar(250) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup from Dim_Country.Name via CountryID. (Tier 1 -Dictionary.Country) |
| 9 | BirthDate | datetime | YES | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 -Customer.CustomerStatic) |
| 10 | CameFromAffiliate | int | YES | Whether the customer was acquired via specific affiliate sub-channels. ETL-computed: `CASE WHEN SubChannelID IN (20, 31) THEN 1 ELSE 0 END`. 1=affiliate-sourced, 0=non-affiliate. (Tier 2 -Dim_Customer) |
| 11 | VerificationLevel3Date | date | YES | Date customer first reached KYC verification level 3 (full KYC). From Fact_SnapshotCustomer + Dim_Range: MIN(FromDateID) WHERE VerificationLevelID=3. Passthrough from BI_DB_CIDFirstDates (CONVERT to DATE). (Tier 2 -BI_DB_CIDFirstDates) |

### 4.2 KYC Questionnaire Answers

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 12 | Occupation | nvarchar(250) | YES | Customer's stated occupation. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='What Is your occupation?'. Free-text answer. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 13 | RiskRewardSc | nvarchar(250) | YES | Customer's risk/reward expectation scenario. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Which risk/reward scenario best describes your expectations with respect to your annual investments with us?'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 14 | AnnualInc | nvarchar(250) | YES | Customer's stated net annual income bracket. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='What is your net annual income?'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 15 | CashLiquAst | nvarchar(250) | YES | Customer's stated total cash and liquid assets bracket. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='What is your total cash and liquid assets?'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 16 | PurposeTrad | nvarchar(250) | YES | Customer's primary purpose of trading. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='What best describes your primary purpose of trading with us?'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 17 | PlanInvAmt | nvarchar(250) | YES | Planned investment amount in the next year. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='How much money do you plan to invest in your eToro account in the next year?'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 18 | Appropriateness_Status | nvarchar(250) | YES | Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Distribution: 'Failed', 'Passed', blank, 'Borderline Pass'. Passthrough from BI_DB_Scored_Appropriateness_Negative_Market.ApproprietnessScore_Status (renamed). (Tier 1 -BI_DB_Scored_Appropriateness_Negative_Market) |
| 19 | AVG_CFD_Leverage | money | YES | Mean leverage used across all CFD positions (IsSettled=0) for this customer. AVG(Leverage * 1.00) from Dim_Position. NULL if no CFD positions. (Tier 2 -Dim_Position) |
| 20 | IsTradedDemo | int | YES | Whether the user has traded on demo. 1=traded, 0=registered but never traded. Passthrough from BI_DB_Demo_CID_Panel. (Tier 2 — BI_DB_Demo_CID_Panel) |
| 21 | UsedDemoBeforeLivePlatform | int | YES | Whether the customer traded demo before their first live trade. 1=demo preceded live, 0=live first or same day, NULL=never traded demo. ETL-computed: CASE on BI_DB_Demo_CID_Panel.FirstDemoTrade vs BI_DB_First5Actions.FirstActionDate. (Tier 2 -BI_DB_Demo_CID_Panel / BI_DB_First5Actions) |
| 22 | KnowledgeAsst | nvarchar(250) | YES | Trading Knowledge Assessment answer. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Trading Knowledge Assessment'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 23 | RelevKnowl | nvarchar(250) | YES | Whether the customer has relevant trading knowledge. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Do you have relevant knowledge in trading?'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 24 | Inv10Income | nvarchar(250) | YES | Whether total invested amount represents 10%+ of annual income. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Does the total amount invested by you represent 10% or more of your annual income?'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 25 | EduTools | nvarchar(250) | YES | Educational tools reviewed by the customer. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Educational tools reviewed'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 26 | NotCrimea | nvarchar(250) | YES | Customer declaration of not being from Crimea region. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='I am Not From Crimea region.'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 27 | ReadRisks | nvarchar(250) | YES | Customer acknowledgement of CFD risks and age confirmation. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='I have read and understood the Risks involved in CFD\'s products and I am Above 18.'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 28 | InvAmtCFD | nvarchar(250) | YES | Intended investment amount in leveraged CFDs. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Invested amount-Leveraged CFDs'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 29 | WhichInst | nvarchar(250) | YES | Instruments the customer plans to trade. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='In which instruments do you plan To trade?'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 30 | IsraeliQlf | nvarchar(250) | YES | Israeli Qualified and Classified statement response. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Israeli Qualified and Classified statement'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 31 | RiskDiscl | nvarchar(250) | YES | Risk disclosure disclaimer acknowledgement. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Risk disclosure disclaimer'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 32 | RiskReview | nvarchar(250) | YES | Risk disclosure review confirmation. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Risk disclosure reviewed'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 33 | SuitExpHigh | nvarchar(250) | YES | Suitability Assessment Experience High Tier disclaimer response. Pivoted from BI_DB_KYCUserRawDataLeveled. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 34 | SuitExpLow | nvarchar(250) | YES | Suitability Assessment Experience Low Tier disclaimer response. Pivoted from BI_DB_KYCUserRawDataLeveled. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 35 | SuitObjHigh | nvarchar(250) | YES | Suitability Assessment Objectives High Tier disclaimer response. Pivoted from BI_DB_KYCUserRawDataLeveled. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 36 | SuitObjLow | nvarchar(250) | YES | Suitability Assessment Objectives Low Tier disclaimer response. Pivoted from BI_DB_KYCUserRawDataLeveled. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 37 | ExpCrypto | nvarchar(250) | YES | Trading experience with crypto assets. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Trading Experience-Crypto Assets'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 38 | ExpEquities | nvarchar(250) | YES | Trading experience with equities. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Trading Experience-Equities'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 39 | ExpCFD | nvarchar(250) | YES | Trading experience with leveraged CFDs. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Trading Experience-Leveraged CFDs'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 40 | TradingFreq | nvarchar(250) | YES | Customer's stated trading frequency. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Trading frequency'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 41 | SourceIncome | nvarchar(250) | YES | Customer's main sources of income. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='What are your main sources of income?'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 42 | TradExp | nvarchar(250) | YES | Customer's self-assessed level of trading experience. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='What is your level of trading experience?'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 43 | MktsTraded | nvarchar(250) | YES | Markets the customer has previously traded. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='Which markets have you traded?'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |
| 44 | SourceFunds | nvarchar(250) | YES | Customer's sources of funds for trading. Pivoted from BI_DB_KYCUserRawDataLeveled: QuestionText='What are your sources of funds'. (Tier 2 -BI_DB_KYCUserRawDataLeveled) |

### 4.3 Compliance Assessments

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 45 | NegativeMarket | nvarchar(250) | YES | Block reason description for customers blocked from CFD trading due to failing the appropriateness test. From BI_DB_Scored_Appropriateness_Negative_Market.BlockReasonDesc WHERE BlockReasonID=12 AND RestrictionStatusDesc='Failed'. NULL if not blocked for this specific reason. (Tier 1 -BI_DB_Scored_Appropriateness_Negative_Market) |

### 4.4 Trading Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 46 | CFD_Copy_PnL | money | YES | Lifetime combined realised + unrealised P&L for CFD copy-trading positions (MirrorID<>0, IsSettled=0), net of overnight/weekend rollover fees. Realised from Dim_Position.NetProfit; unrealised from BI_DB_PositionPnL.PositionPnL (yesterday); rollover from Fact_CustomerAction (ActionTypeID=35, IsFeeDividend=1, IsCopy=1). (Tier 2 -Dim_Position / BI_DB_PositionPnL / Fact_CustomerAction) |
| 47 | CFD_Manual_PnL | money | YES | Lifetime combined realised + unrealised P&L for CFD manual positions (MirrorID=0, IsSettled=0), net of overnight/weekend rollover fees. Same sources as CFD_Copy_PnL but for manual (IsCopy=0). (Tier 2 -Dim_Position / BI_DB_PositionPnL / Fact_CustomerAction) |
| 48 | Stocks_Copy_PnL | money | YES | Lifetime combined realised + unrealised P&L for copy-trading real stock/ETF positions (MirrorID<>0, IsSettled=1, InstrumentType IN ('Stocks','ETF')). No rollover deduction. Realised from Dim_Position.NetProfit; unrealised from BI_DB_PositionPnL.PositionPnL. (Tier 2 -Dim_Position / BI_DB_PositionPnL) |
| 49 | Stocks_Manual_PnL | money | YES | Lifetime combined realised + unrealised P&L for manual real stock/ETF positions (MirrorID=0, IsSettled=1, InstrumentType IN ('Stocks','ETF')). No rollover deduction. (Tier 2 -Dim_Position / BI_DB_PositionPnL) |
| 50 | Crypto_Copy_PnL | money | YES | Lifetime combined realised + unrealised P&L for copy-trading real crypto positions (MirrorID<>0, IsSettled=1, InstrumentType='Crypto Currencies'). No rollover deduction. (Tier 2 -Dim_Position / BI_DB_PositionPnL) |
| 51 | Crypto_Manual_PnL | money | YES | Lifetime combined realised + unrealised P&L for manual real crypto positions (MirrorID=0, IsSettled=1, InstrumentType='Crypto Currencies'). No rollover deduction. (Tier 2 -Dim_Position / BI_DB_PositionPnL) |

### 4.5 Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 52 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() at INSERT time. Identical for all rows in a given daily load. (Tier 2 -SP_M_Compliance_CDIM_Report) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | Passthrough via Dim_Customer.RealCID (renamed) |
| Regulation | Dictionary.Regulation | Name | Dim-lookup via Dim_Regulation |
| PlayerStatus | Dictionary.PlayerStatus | Name | Dim-lookup via Dim_PlayerStatus |
| Club | Dictionary.PlayerLevel | Name | Dim-lookup via Dim_PlayerLevel |
| Desk | Ext_Dim_Country_Region_Desk | Desk | Dim-lookup via Dim_Country |
| Manager | BI_DB_CIDFirstDates | Manager | Passthrough (itself ETL-computed from Dim_Manager) |
| MifidCategorisation | Dictionary.MifidCategorization | Name | Dim-lookup via Dim_MifidCategorization |
| CountryOfResidence | Dictionary.Country | Name | Dim-lookup via Dim_Country |
| BirthDate | Customer.CustomerStatic | BirthDate | Passthrough via Dim_Customer |
| CameFromAffiliate | -- | -- | ETL-computed: CASE on Dim_Customer.SubChannelID |
| VerificationLevel3Date | BI_DB_CIDFirstDates | VerificationLevel3Date | CONVERT(DATE, ...) |
| Occupation..SourceFunds (29 cols) | BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText |
| Appropriateness_Status | BI_DB_Scored_Appropriateness_Negative_Market | ApproprietnessScore_Status | Passthrough (renamed) |
| AVG_CFD_Leverage | Dim_Position | Leverage | AVG(CASE WHEN IsSettled=0 THEN Leverage END) |
| IsTradedDemo | BI_DB_Demo_CID_Panel | IsTradedDemo | Passthrough |
| UsedDemoBeforeLivePlatform | BI_DB_Demo_CID_Panel + BI_DB_First5Actions | FirstDemoTrade, FirstActionDate | CASE comparison |
| NegativeMarket | BI_DB_Scored_Appropriateness_Negative_Market | BlockReasonDesc | Filtered passthrough (BlockReasonID=12, Failed) |
| CFD_Copy_PnL | Dim_Position + BI_DB_PositionPnL + Fact_CustomerAction | NetProfit, PositionPnL, Amount | SUM(realised+unrealised) - rollover |
| CFD_Manual_PnL | Dim_Position + BI_DB_PositionPnL + Fact_CustomerAction | NetProfit, PositionPnL, Amount | SUM(realised+unrealised) - rollover |
| Stocks_Copy_PnL | Dim_Position + BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) |
| Stocks_Manual_PnL | Dim_Position + BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) |
| Crypto_Copy_PnL | Dim_Position + BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) |
| Crypto_Manual_PnL | Dim_Position + BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (population base: FCA, verified L3, depositors)
  + DWH_dbo.Dim_Country (Desk, CountryOfResidence)
  + DWH_dbo.Dim_PlayerStatus (PlayerStatus name, filter NOT IN 2,4)
  + DWH_dbo.Dim_PlayerLevel (Club name)
  + DWH_dbo.Dim_Regulation (Regulation name, filter FCA=2)
  + DWH_dbo.Dim_MifidCategorization (MifidCategorisation name)
  + BI_DB_dbo.BI_DB_CIDFirstDates (Manager, VerificationLevel3Date)
  + DWH_dbo.Dim_Channel (SubChannelID decode -- used for filter only)
  → #pop (demographics)
  
DWH_dbo.Dim_Position (OpenDateID/CloseDateID >= @1yearagoid)
  → #pop2 (active traders filter)

BI_DB_dbo.BI_DB_First5Actions → #FA (FirstActionDate)
BI_DB_dbo.BI_DB_Demo_CID_Panel + #FA → #Demo (IsTradedDemo, UsedDemoBeforeLivePlatform)
BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market → #Appropriateness + #NegativeMarket
DWH_dbo.Dim_Position + DWH_dbo.Dim_Instrument → #RealisedPnL
BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Instrument → #UnrealisedPnL
DWH_dbo.Fact_CustomerAction (ActionTypeID=35, IsFeeDividend=1) → #Rollover
#RealisedPnL UNION ALL #UnrealisedPnL → #LifetimePnL
DWH_dbo.Dim_Position (AVG CFD Leverage) → #CFD_Leverage
BI_DB_dbo.BI_DB_KYCUserRawDataLeveled → PIVOT → #KYC_Output

#pop + #pop2 + #CFD_Leverage + #Demo + #NegativeMarket + #LifetimePnL + #KYC_Output + #Appropriateness + #Rollover
  |-- SP_M_Compliance_CDIM_Report (TRUNCATE + INSERT, daily) --|
  v
BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension (population source) |
| Regulation | DWH_dbo.Dim_Regulation | Regulatory jurisdiction (always FCA) |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Account restriction state |
| Club | DWH_dbo.Dim_PlayerLevel | Loyalty tier name |
| MifidCategorisation | DWH_dbo.Dim_MifidCategorization | MiFID II classification |
| CountryOfResidence | DWH_dbo.Dim_Country | Country name |

### 6.2 Referenced By (other objects point to this)

No downstream consumers found in the SSDT project. This table is consumed directly by FCA compliance reporting (complianceuk@etoro.com).

---

## 7. Sample Queries

### 7.1 Appropriateness test distribution

```sql
SELECT Appropriateness_Status,
       COUNT(*) AS CustomerCount,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS Pct
FROM [BI_DB_dbo].[BI_DB_M_Compliance_CDIM_Report]
GROUP BY Appropriateness_Status
ORDER BY CustomerCount DESC;
```

### 7.2 P&L summary by asset class (copy vs manual)

```sql
SELECT 'CFD' AS AssetClass,
       SUM(CFD_Copy_PnL) AS CopyPnL,
       SUM(CFD_Manual_PnL) AS ManualPnL
FROM [BI_DB_dbo].[BI_DB_M_Compliance_CDIM_Report]
UNION ALL
SELECT 'Stocks',
       SUM(Stocks_Copy_PnL),
       SUM(Stocks_Manual_PnL)
FROM [BI_DB_dbo].[BI_DB_M_Compliance_CDIM_Report]
UNION ALL
SELECT 'Crypto',
       SUM(Crypto_Copy_PnL),
       SUM(Crypto_Manual_PnL)
FROM [BI_DB_dbo].[BI_DB_M_Compliance_CDIM_Report];
```

### 7.3 High-leverage CFD users with negative market block

```sql
SELECT CID,
       Club,
       CountryOfResidence,
       AVG_CFD_Leverage,
       NegativeMarket,
       Appropriateness_Status,
       CFD_Manual_PnL + CFD_Copy_PnL AS TotalCFDPnL
FROM [BI_DB_dbo].[BI_DB_M_Compliance_CDIM_Report]
WHERE AVG_CFD_Leverage > 10
  AND NegativeMarket IS NOT NULL
ORDER BY AVG_CFD_Leverage DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode -- Phase 10 skipped). The SP contains a comment referencing `complianceuk@etoro.com` as the primary consumer.

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14 (P3 skipped -- empty table, P7 no views, P10 regen harness)*
*Tiers: 11 T1, 41 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 52/52, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report | Type: Table | Production Source: Multi-source via SP_M_Compliance_CDIM_Report*
