# BI_DB_dbo.BI_DB_Reg_UK_Compliance_KYC_Weekly_Export

> Weekly KYC questionnaire export for UK (FCA) and CySEC regulated depositors in Gold/Platinum/Platinum Plus/Diamond clubs — 400,591 customer rows as of 2026-04-07, refreshed every Tuesday. Each row is one CID with 29 pivoted KYC answers, open CFD position count, last CFD activity date, club/desk/manager context, and MiFID II categorisation. Created by DSR-1848 for the UK compliance team (Edward Drake and Bradley Roberts) to automate weekly file delivery. Writer: `SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + BI_DB_CIDFirstDates + BI_DB_KYCUserRawDataLeveled (via SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export) |
| **Refresh** | Weekly — every Tuesday (SB_Daily, TRUNCATE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Reg_UK_Compliance_KYC_Weekly_Export` is a weekly snapshot of KYC (Know Your Customer) questionnaire responses for high-value customers regulated under CySEC or FCA who hold Gold or higher club tier. Created in March 2022 under DSR-1848, the table automates a weekly file export for the UK compliance team to review customer suitability, appropriateness, and risk understanding across CySEC and FCA jurisdictions.

The table contains **400,591 rows** as of 2026-04-07 (one row per customer, since all rows share the same UpdateDate). The population is segmented as: CySEC=262,151 (65%), FCA=138,440 (35%). MiFID II categorisation: Retail Pending (52%), Retail (47%), with small Elective Professional (194), Pending (1,360), and Professional (4) segments. 128 countries of residence are represented.

Each row provides the customer's last recorded answer for 29 KYC questionnaire questions (using PIVOT MAX on `BI_DB_KYCUserRawDataLeveled`), alongside current open CFD positions, last CFD trade activity within the past year, club membership tier, account manager, country/desk routing, and MiFID II classification. A customer without any open CFDs will have NULL for OpenCFDPositions.

The TRUNCATE + INSERT pattern means this table always reflects the **current week's snapshot** — no historical rows are retained. The SP runs every Tuesday.

---

## 2. Business Logic

### 2.1 Eligibility Filter (High-Value Compliant Depositors)

**What**: Only regulated, active depositors with high club tier are included.
**Columns Involved**: Regulation, Club
**Rules**:
- DesignatedRegulationID IN (1=CySEC, 2=FCA) — excludes ASIC, FSA Seychelles, etc.
- IsValidCustomer = 1 — excludes test, blocked, or invalid accounts
- IsDepositor = 1 — must have deposited
- Club IN ('Platinum', 'Platinum Plus', 'Diamond', 'Gold') — minimum Gold tier

### 2.2 KYC Answer Pivoting

**What**: 29 KYC questionnaire questions are transformed from a long format (one row per question per customer) into wide format (one column per question per customer).
**Columns Involved**: RelevKnowl through RiskRewardSc (29 columns)
**Rules**:
- Source: `BI_DB_KYCUserRawDataLeveled` — contains one row per CID per question
- Mechanism: PIVOT(MAX(AnswerText) FOR QuestionText IN (...))
- MAX is used to pick the most recent or only answer value
- NULL means the customer has not answered that question
- Answers are stored as nvarchar(250) free text — may be 'Yes', 'No', a numeric range, or a multi-value selection

### 2.3 Open CFD Position Count

**What**: Count of currently open direct CFD positions (non-copy, non-settled) from Dim_Position.
**Columns Involved**: OpenCFDPositions
**Rules**:
- IsSettled = 0 (CFD, not real asset)
- CloseDateID = 0 (still open)
- MirrorID = 0 (not a copy position)
- NULL in this column means no open CFDs

### 2.4 Last CFD Activity Window

**What**: Most recent CFD position open date within the past year.
**Columns Involved**: LastPosOpCFD, DaysLastPosOpCFD
**Rules**:
- From Dim_Position: MAX(OpenOccurred) WHERE MirrorID=0 AND IsSettled=0 AND OpenDateID >= @1yearagoid
- @1yearagoid = CAST(CONVERT(VARCHAR(8), DATEADD(year,-1,GETDATE()), 112) AS INT) — rolling 1-year lookback
- DaysLastPosOpCFD = DATEDIFF(day, LastPosOpCFD, GETDATE()) — age in days at time of SP run
- NULL if no CFD positions opened in the past year

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Aspect | Detail |
|--------|--------|
| **Distribution** | ROUND_ROBIN — suitable for this modestly-sized weekly export |
| **Index** | HEAP — no clustering needed for this scan-heavy compliance report |
| **Size** | ~400K rows; HEAP is efficient for full-scan compliance queries |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| UK FCA customers with low trading experience | `WHERE Regulation = 'FCA' AND TradExp IN ('Never traded', 'Less than 1 year')` |
| Customers without KYC risk score answer | `WHERE RiskRewardSc IS NULL` |
| Most recent cohort review | `WHERE UpdateDate = (SELECT MAX(UpdateDate) FROM ...)` — all rows share single UpdateDate per week |
| Elective professional opt-up pipeline | `WHERE MifidCategorisation = 'Retail Pending'` |
| Desk-level breakdown for account managers | `GROUP BY Desk, Manager` with COUNT(*) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_CIDFirstDates | RealCID = CID | Additional customer lifecycle data |
| DWH_dbo.Dim_Customer | RealCID = RealCID | Full customer attributes not in this table |

### 3.4 Gotchas

- **Single UpdateDate per load**: All rows have the same `UpdateDate` — the weekly truncate means there is no history. Never use this table for trend analysis across weeks.
- **DaysLastPosOpCFD staleness**: DaysLastPosOpCFD is computed at SP run time, not at query time. A row from 2026-04-07 with DaysLastPosOpCFD=10 means 10 days as of 2026-04-07, not today.
- **KYC NULLs are meaningful**: NULL in any KYC column means the customer has not answered that question — this is distinct from answering "No" or "None". In compliance, unanswered is different from answered negatively.
- **LastPosOpCFD is year-bounded**: Only CFD positions opened within the past calendar year are considered. Customers who last traded CFDs >1 year ago will show NULL.
- **Eligibility drift**: A customer may appear in one week and disappear the next if their club tier drops below Gold or they become invalid. No change log is maintained.
- **OpenCFDPositions NULL vs 0**: NULL = no open CFD positions; column is not set to 0 for non-traders.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki or DWH_dbo wiki (exact copy, no paraphrase) |
| Tier 2 | Derived from SP code and writer stored procedure analysis |
| Tier 3 | ETL metadata or system-generated columns confirmed from SP |
| Tier 4 | Inferred from context, sample data, or naming convention |
| Tier 5 | Expert review required — uncertain semantics |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Regulation | varchar(50) | YES | Regulatory jurisdiction. Values: CySEC (CySEC-regulated, 65% of rows), FCA (UK FCA-regulated, 35%). Resolved from DWH_dbo.Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, DWH_dbo.Dim_Regulation) |
| 2 | RealCID | int | NO | Customer ID — primary key of this export. One row per customer per weekly snapshot. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, DWH_dbo.Dim_Customer.RealCID) |
| 3 | RelevKnowl | nvarchar(250) | YES | KYC answer: "Do you have relevant knowledge in trading?" NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 4 | Inv10Income | nvarchar(250) | YES | KYC answer: "Does the total amount invested by you represent 10% or more of your annual income?" NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 5 | EduTools | nvarchar(250) | YES | KYC answer: "Educational tools reviewed." Records which eToro educational materials the customer completed. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 6 | PlanInvAmt | nvarchar(250) | YES | KYC answer: "How much money do you plan to invest in your eToro account in the next year?" NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 7 | NotCrimea | nvarchar(250) | YES | KYC answer: "I am Not From Crimea region." Regulatory compliance declaration. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 8 | ReadRisks | nvarchar(250) | YES | KYC answer: "I have read and understood the Risks involved in CFD's products and I am Above 18." Risk acknowledgement. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 9 | InvAmtCFD | nvarchar(250) | YES | KYC answer: "Invested amount-Leveraged CFDs." Customer's declared CFD investment amount range. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 10 | WhichInst | nvarchar(250) | YES | KYC answer: "In which instruments do you plan To trade?" NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 11 | IsraeliQlf | nvarchar(250) | YES | KYC answer: "Israeli Qualified and Classified statement." Regulatory declaration for Israeli-regulated customers. NULL if unanswered or non-Israeli. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 12 | RiskDiscl | nvarchar(250) | YES | KYC answer: "Risk disclosure disclaimer." CFD risk disclosure acceptance. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 13 | RiskReview | nvarchar(250) | YES | KYC answer: "Risk disclosure reviewed." Confirms customer reviewed risk materials. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 14 | SuitExpHigh | nvarchar(250) | YES | KYC answer: "Suitability Assessment Experience High Tier disclaimer." High-experience suitability assessment outcome. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 15 | SuitExpLow | nvarchar(250) | YES | KYC answer: "Suitability Assessment Experience Low Tier disclaimer." Low-experience suitability outcome. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 16 | SuitObjHigh | nvarchar(250) | YES | KYC answer: "Suitability Assessment Objectives High Tier disclaimer." High-objective suitability outcome. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 17 | SuitObjLow | nvarchar(250) | YES | KYC answer: "Suitability Assessment Objectives Low Tier disclaimer." Low-objective suitability outcome. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 18 | ExpCrypto | nvarchar(250) | YES | KYC answer: "Trading Experience-Crypto Assets." Customer's declared crypto trading experience level. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 19 | ExpEquities | nvarchar(250) | YES | KYC answer: "Trading Experience-Equities." Customer's declared equities trading experience. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 20 | ExpCFD | nvarchar(250) | YES | KYC answer: "Trading Experience-Leveraged CFDs." Customer's declared CFD trading experience. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 21 | TradingFreq | nvarchar(250) | YES | KYC answer: "Trading frequency." Customer's declared trading frequency. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 22 | KnowledgeAsst | nvarchar(250) | YES | KYC answer: "Trading Knowledge Assessment." Outcome of the platform's knowledge assessment. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 23 | SourceIncome | nvarchar(250) | YES | KYC answer: "What are your main sources of income?" Customer-declared income source. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 24 | SourceFunds | nvarchar(250) | YES | KYC answer: "What are your sources of funds." Customer-declared source of invested funds. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 25 | PurposeTrad | nvarchar(250) | YES | KYC answer: "What best describes your primary purpose of trading with us?" NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 26 | TradExp | nvarchar(250) | YES | KYC answer: "What is your level of trading experience?" Customer-declared overall experience level. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 27 | AnnualInc | nvarchar(250) | YES | KYC answer: "What is your net annual income?" Customer-declared income bracket. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 28 | Occupation | nvarchar(250) | YES | KYC answer: "What Is your occupation?" Customer-declared occupation. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 29 | CashLiquAst | nvarchar(250) | YES | KYC answer: "What is your total cash and liquid assets?" Customer-declared liquid asset bracket. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 30 | MktsTraded | nvarchar(250) | YES | KYC answer: "Which markets have you traded?" Customer-declared markets experience. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 31 | RiskRewardSc | nvarchar(250) | YES | KYC answer: "Which risk/reward scenario best describes your expectations with respect to your annual investments with us?" Risk tolerance self-classification. NULL if unanswered. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_KYCUserRawDataLeveled PIVOT) |
| 32 | OpenCFDPositions | int | YES | Count of currently open direct (non-copy) CFD positions from DWH_dbo.Dim_Position (IsSettled=0, CloseDateID=0, MirrorID=0). NULL if no open CFD positions. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, DWH_dbo.Dim_Position) |
| 33 | LastPosOpCFD | datetime | YES | Most recent CFD position open date (non-copy, non-settled) within the past year. MAX(OpenOccurred) WHERE MirrorID=0 AND IsSettled=0 AND OpenDateID >= 1-year-ago. NULL if no CFD opened in past year. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, DWH_dbo.Dim_Position) |
| 34 | DaysLastPosOpCFD | int | YES | Days since LastPosOpCFD as of the SP run date (DATEDIFF(day, LastPosOpCFD, GETDATE())). Staleness warning: computed at insert time, not query time. NULL if LastPosOpCFD is NULL. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export) |
| 35 | Club | varchar(500) | YES | Customer experience tier: Gold, Platinum, Platinum Plus, or Diamond (eligibility filter — lower tiers are excluded). Customer experience tier name from Dim_PlayerLevel via BI_DB_CIDFirstDates. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_CIDFirstDates.Club) |
| 36 | Desk | nvarchar(50) | YES | Country-based sales desk routing. Resolved from DWH_dbo.Dim_Country.Desk via Dim_Customer.CountryID. Indicates which sales/account management team handles this country. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, DWH_dbo.Dim_Country.Desk) |
| 37 | Manager | nvarchar(500) | YES | Account manager full name (FirstName + ' ' + LastName from Dim_Manager). From BI_DB_CIDFirstDates.Manager. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, BI_DB_CIDFirstDates.Manager) |
| 38 | MifidCategorisation | varchar(50) | NO | Customer's MiFID II regulatory category. Values: Retail Pending (52%), Retail (47%), Pending (0.3%), Elective Professional (<0.1%), Professional (<0.1%), None (<0.1%). Resolved from DWH_dbo.Dim_MifidCategorization.Name. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, DWH_dbo.Dim_MifidCategorization) |
| 39 | CountryOfResidence | varchar(50) | NO | Customer's country of residence (text name). Resolved from DWH_dbo.Dim_Country.Name via Dim_Customer.CountryID. (Tier 2 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export, DWH_dbo.Dim_Country.Name) |
| 40 | UpdateDate | datetime | NOT NULL | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert. All rows in a given weekly load share the same UpdateDate (Tuesday run). (Tier 3 — SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export) |


---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Regulation | DWH_dbo.Dim_Regulation | Name | Lookup via DesignatedRegulationID |
| RealCID | DWH_dbo.Dim_Customer | RealCID | Direct |
| RelevKnowl…RiskRewardSc (29 cols) | BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX per QuestionText |
| OpenCFDPositions | DWH_dbo.Dim_Position | PositionID | COUNT(DISTINCT) |
| LastPosOpCFD | DWH_dbo.Dim_Position | OpenOccurred | MAX with 1-year window |
| DaysLastPosOpCFD | Computed | LastPosOpCFD | DATEDIFF at insert |
| Club | BI_DB_CIDFirstDates | Club | Passthrough |
| Desk | DWH_dbo.Dim_Country | Desk | Via CountryID |
| Manager | BI_DB_CIDFirstDates | Manager | Passthrough |
| MifidCategorisation | DWH_dbo.Dim_MifidCategorization | Name | Via MifidCategorizationID |
| CountryOfResidence | DWH_dbo.Dim_Country | Name | Via CountryID |
| UpdateDate | ETL metadata | — | GETDATE() at insert |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (CySEC/FCA depositors, IsValidCustomer=1)
  + DWH_dbo.Dim_Regulation, Dim_MifidCategorization, Dim_Country
  + BI_DB_dbo.BI_DB_CIDFirstDates (Gold/Platinum/PlatPlus/Diamond filter)
    → #Clients (identity, demographics, club)
BI_DB_dbo.BI_DB_KYCUserRawDataLeveled
    → #kyc PIVOT(29 KYC question columns)
DWH_dbo.Dim_Position (open CFD count + last date)
    → #opencfd + #lastposcfd
    |-- SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export (Weekly/Tue, P21, SB_Daily) ---|
    v                                                    [TRUNCATE + INSERT]
BI_DB_dbo.BI_DB_Reg_UK_Compliance_KYC_Weekly_Export
  (400,591 rows | snapshot 2026-04-07 | ROUND_ROBIN HEAP)
    |-- UC: _Not_Migrated
    |-- DSR-1848: weekly file → UK Compliance team (Edward Drake, Bradley Roberts)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | BI_DB_dbo.BI_DB_CIDFirstDates | Customer milestone data source |
| KYC columns | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | KYC question/answer source |
| Club, Manager | BI_DB_dbo.BI_DB_CIDFirstDates | Club tier and manager from customer master |
| OpenCFDPositions, LastPosOpCFD | DWH_dbo.Dim_Position | Open position data |
| Regulation | DWH_dbo.Dim_Regulation | Regulatory regime resolution |
| MifidCategorisation | DWH_dbo.Dim_MifidCategorization | MiFID II classification |
| CountryOfResidence, Desk | DWH_dbo.Dim_Country | Country and desk routing |

### 6.2 Referenced By (other objects point to this)

No downstream SP or view references found in SSDT repo scan. Table is consumed directly by the UK compliance team via scheduled file export.

---

## 7. Sample Queries

### FCA Customers with High-Risk Self-Declared Profile

```sql
SELECT RealCID, Club, MifidCategorisation, TradExp, RiskRewardSc, OpenCFDPositions
FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_KYC_Weekly_Export]
WHERE Regulation = 'FCA'
  AND TradExp IS NOT NULL
  AND RiskRewardSc IS NOT NULL
ORDER BY OpenCFDPositions DESC
```

### KYC Completeness by Regulation

```sql
SELECT 
    Regulation,
    COUNT(*) AS total,
    SUM(CASE WHEN TradExp IS NOT NULL THEN 1 ELSE 0 END) AS has_trading_exp,
    SUM(CASE WHEN AnnualInc IS NOT NULL THEN 1 ELSE 0 END) AS has_annual_income,
    SUM(CASE WHEN MktsTraded IS NOT NULL THEN 1 ELSE 0 END) AS has_markets_traded
FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_KYC_Weekly_Export]
GROUP BY Regulation
```

### Recent CFD Inactive Platinum+ Customers (FCA)

```sql
SELECT RealCID, Club, Manager, CountryOfResidence,
       LastPosOpCFD, DaysLastPosOpCFD, OpenCFDPositions
FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_KYC_Weekly_Export]
WHERE Regulation = 'FCA'
  AND Club IN ('Platinum Plus', 'Diamond')
  AND (OpenCFDPositions IS NULL OR OpenCFDPositions = 0)
  AND (DaysLastPosOpCFD > 90 OR LastPosOpCFD IS NULL)
ORDER BY Club DESC
```

---

## 8. Atlassian Knowledge Sources

Jira ticket: **DSR-1848** — created this table (March 2022, Nir Weber). Requested by UK compliance team members Edward Drake and Bradley Roberts to automate weekly KYC review file delivery. Migrated to Synapse by Slavane in June 2023.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 14/14 | P16: PASS*
*Tiers: 0 T1, 39 T2, 1 T3, 0 T4, 0 T5 | Elements: 40/40, Logic: 9/10, ETL: confirmed*
*Object: BI_DB_dbo.BI_DB_Reg_UK_Compliance_KYC_Weekly_Export | Type: Table | Production Source: KYCUserRawDataLeveled PIVOT via SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export*
