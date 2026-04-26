# BI_DB_dbo.BI_DB_AML_KYC_SOF

> AML Source of Funds (SOF) compliance table cross-referencing all VL3 depositors' actual deposit totals against their KYC-stated planned investment amounts — identifying customers whose deposits approach or exceed their Q14 declared ceiling and flagging them for SOF documentation review, with enrichment for position activity, proof of income documents, equity, and manager assignment.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Column Count** | 40 |
| **Row Count** | 5,371,229 (as of 2026-04-12) |
| **Grain** | One row per CID (customers with at least one KYC questionnaire response) |
| **Refresh** | Daily (OpsDB Priority 0 — base layer) |
| **Writer SP** | BI_DB_dbo.SP_AML_KYC_SOF |
| **ETL Pattern** | TRUNCATE + INSERT (full refresh) |
| **PII Columns** | UserName, Gender, Age (derived), ManagerFullName |
| **UC Target** | Pending |

---

## 1. Business Meaning

`BI_DB_AML_KYC_SOF` is the AML team's Source of Funds (SOF) monitoring table. During KYC onboarding, customers answer questionnaire questions about their annual income (Q10), liquid assets (Q11), and how much they plan to invest (Q14). This table compares each customer's **actual cumulative deposits** against their **Q14 stated planned investment ceiling** to detect when deposits are approaching, reaching, or exceeding the declared amount — a regulatory trigger for requesting Source of Funds documentation.

The table covers all VL3 (fully verified) depositors who have completed the KYC questionnaire. Unlike `BI_DB_AML_KYC_Process`, there is no filter on document proof status or player status — Blocked accounts are included. The population is 5.37M rows (all VL3 depositors with KYC panel records), which is the broadest AML monitoring scope in the BI_DB schema.

### SOF Decision Logic

| SOF_Predication | Condition | Count | % |
|----------------|-----------|-------|---|
| Do not check SOF | Deposits well within Q14 cap | 4,609,432 | 85.8% |
| SOF | Deposits ≥ 85% of Q14 cap, or exceed cap | 731,695 | 13.6% |
| SOF should be checked | Q14 answer = 'Above $1M' (HNWI track) | 30,102 | 0.6% |

### Business Usage

- **SOF Case Initiation**: Primary daily input for AML analysts opening SOF review cases. Filtered by SOF_Predication = 'SOF' or 'SOF should be checked'.
- **Business Potential Scoring**: HasBusinessPotential=1 flags customers who still have ≥85% of their stated investment ceiling remaining — high growth potential customers who are SOF-safe.
- **Proof of Income Tracking**: DocumentType, HasProofOfIncome, and HasSOFLast6Months track whether customers have already submitted income proof documents.
- **Manager Accountability**: ManagerFullName links each case to the assigned account manager.

---

## 2. Business Logic

### 2.1 Population Filter

**What**: All VL3 customers who have completed the KYC questionnaire. No document proof or player status restriction.

**Rules** (applied to DWH_dbo.Dim_Customer):
- `VerificationLevelID = 3` — fully verified
- `IsValidCustomer = 1` — standard valid accounts (no internal, bot, or excluded-market accounts)
- `IsDepositor = 1` — must have at least one deposit
- **No PlayerStatus exclusion** — unlike KYC_Process, Blocked accounts appear (e.g., see sample row with PlayerStatus='Blocked')

The INNER JOIN to `BI_DB_KYC_Panel` limits the population to customers who have answered at least one KYC question (KYC Panel deletes rows with all-NULL KYC answers).

### 2.2 SOF Prediction Logic

**What**: Determines whether the customer's deposit behavior triggers a Source of Funds documentation request.

**Computation**:
1. `Max_Q14_Answer` — map Q14_AnswerText to a numeric upper bound (e.g., '$1k-$5k' → 5,000; 'Above $1M' → 1,000,000)
2. `RemainingAmount = Max_Q14_Answer - Total_Deposit`
3. `%RemainingAmount = (RemainingAmount / Max_Q14_Answer) × 100` (NULL-safe)

**Decision rules** (`SOF_Predication`):
- `'SOF should be checked'`: Q14_AnswerText = 'Above $1M' (HNWI — always check regardless of deposits)
- `'SOF'`: RemainingAmount < 0 (deposits exceed declared plan) OR RemainingAmount/Max_Q14_Answer < 0.15 (less than 15% remaining)
- `'Do not check SOF'`: all other cases

**ReasonType breakdown** (categorizes _why_ SOF was triggered):

| ReasonType | HasBusinessPotential | Count | Interpretation |
|-----------|---------------------|-------|---------------|
| Normal | 1 | 2,796,069 | ≥85% remaining — strong future potential |
| Normal | 0 | 1,824,655 | 15-84% remaining — moderate, no action |
| More then decleared deposit | 0 | 588,350 | Deposits exceed Q14 cap |
| Less then 15% left | 0 | 132,053 | <15% remaining — SOF triggered |
| HNWI | 1 | 29,165 | Above $1M, ≥85% remaining |
| HNWI | 0 | 937 | Above $1M, <85% remaining |

*Note*: 'More then decleared deposit' and 'Less then 15% left' contain spelling errors originating from the SP code — they are the exact stored string values.

### 2.3 HasBusinessPotential Flag

**What**: Identifies customers who still have significant "investment headroom" relative to their stated Q14 plan — business development signal alongside compliance signal.

**Rule**: `HasBusinessPotential = 1` when `%RemainingAmount >= 85` (85% or more of stated plan not yet deposited).

### 2.4 KYC Questionnaire Structure

Q10, Q11, and Q14 store two columns each: the question text and the answer text. Based on live data:
- `Q10_Annual_Income` = full question text: "What is your net annual income?"
- `Q10_AnswerText` = customer's selected answer: "$10K-$50K", "$50K-$200K", etc.
- `Q11_Liquid_Assets` = full question text: "What is your total cash and liquid assets?"
- `Q11_AnswerText` = customer's selected answer: "Up to $10K", "$10K-$50K", etc.
- `Q14_Planned_Invested_Amount` = full question text: "How much money do you plan to invest in your eToro account in the next year?"
- `Q14_AnswerText` = customer's selected answer: "Up to $1k", "$1k-$5k", "$5k-$20k", "Up to $20K", "$20k-$50k", "$50k-$200k", "$200k-$500k", "$500k-$1M", "Above $1M"

**Q14 answer range distribution** (as of 2026-04-12):

| Q14_AnswerText | Mapped Cap | Count |
|---------------|-----------|-------|
| Up to $20K | $20,000 | 2,325,757 |
| Up to $1k | $1,000 | 1,047,297 |
| $1k - $5k | $5,000 | 844,235 |
| $5k - $20k | $20,000 | 493,066 |
| $20k - $50k | $50,000 | 397,234 |
| $50k-$200k | $200,000 | 170,286 |
| $200k - $500k | $500,000 | 40,756 |
| Above $1M | $1,000,000 | 30,102 |
| $500k - $1M | $1,000,000 | 20,869 |
| $20k-$100k | 0 (unmapped) | 979 |
| More than $100k | 0 (unmapped) | 526 |

### 2.5 Proof of Income Documents

**What**: The most recent proof of income document submitted by the customer, if any.

**Rule**: From BackOffice CustomerDocument, the latest document (by DocumentDateAdded DESC) where DocumentType = 'Proof of Income' OR (DocumentType = 'Not Accepted' AND SuggestedDocumentType = 'Proof of Income').
- `HasProofOfIncome = 1` if this condition is met; 0 otherwise
- `HasSOFLast6Months = 1` if a qualifying document was added within the last 6 months

In practice, the vast majority of rows have DocumentStatus = 'N/A' (no documents found or document check returned no result) with HasProofOfIncome = 0.

### 2.6 Age Calculation

**What**: Customer age as of the SP run date. Computed from Dim_Customer.BirthDate.

**Formula**: `DATEDIFF(YEAR, dc.BirthDate, GETDATE())`

Note: This is a simple year-difference, not an exact age — it may be off by 1 year for customers whose birthday hasn't occurred yet in the current year.

---

## 3. Query Advisory

### 3.1 Size and Distribution

ROUND_ROBIN HEAP, 5.37M rows. No hash key — all queries require full scan. For targeted queries, filter on `SOF_Predication` or `ReasonType` first to reduce result set.

### 3.2 Special Column Name Warning

**`[%RemainingAmount]`** must always be quoted as `[%RemainingAmount]` in SQL queries — the `%` character is a SQL wildcard in LIKE expressions. Failure to quote will cause syntax errors.

```sql
-- CORRECT
SELECT [%RemainingAmount] FROM [BI_DB_dbo].[BI_DB_AML_KYC_SOF]

-- WRONG
SELECT %RemainingAmount FROM [BI_DB_dbo].[BI_DB_AML_KYC_SOF]
```

### 3.3 Last_Login_Date Type

`Last_Login_Date` is stored as an **INT** (DateID format: YYYYMMDD), not as datetime. For date comparisons, cast appropriately:

```sql
WHERE Last_Login_Date >= 20260101  -- treat as integer
-- or
WHERE CAST(CAST(Last_Login_Date AS VARCHAR(8)) AS DATE) >= '2026-01-01'
```

### 3.4 ReasonType String Matching

ReasonType values have spelling errors — match them exactly as stored:

| Intended | Stored (match this exactly) |
|----------|---------------------------|
| More than declared deposit | `'More then decleared deposit'` |
| Less than 15% left | `'Less then 15% left'` |
| HNWI | `'HNWI'` |
| Normal | `'Normal'` |

### 3.5 Q14 Unmapped Answers

For Q14_AnswerText = '$20k-$100k' or 'More than $100k' (~1,505 rows), Max_Q14_Answer = 0. This makes `%RemainingAmount` NULL (NULLIF prevents division by zero) and `RemainingAmount` = -Total_Deposit (negative). These rows may be incorrectly classified as 'More then decleared deposit' in ReasonType.

### 3.6 Common Query Patterns

| Question | Approach |
|----------|----------|
| Active SOF queue by regulation | `WHERE SOF_Predication = 'SOF' GROUP BY Regulation` |
| HNWI customers | `WHERE ReasonType = 'HNWI' ORDER BY Total_Deposit DESC` |
| High-value customers with income docs | `WHERE HasProofOfIncome = 1 AND Equity > X` |
| Customers without income docs needing SOF | `WHERE SOF_Predication = 'SOF' AND HasProofOfIncome = 0` |
| Business potential pipeline | `WHERE HasBusinessPotential = 1 AND ReasonType = 'Normal'` |

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source |
|------|--------|
| Tier 1 | Upstream DWH wiki verbatim copy |
| Tier 2 | SP code derivation / BI_DB source table |
| Propagation | ETL metadata |

| # | Column | Type | Nullable | PII | Description |
|---|--------|------|----------|-----|-------------|
| 1 | CID | int | YES | No | Customer ID — platform-internal primary key. Assigned at registration. Universal customer identifier across all DWH tables. (Tier 1 — DWH_dbo.Dim_Customer.RealCID) |
| 2 | GCID | int | YES | No | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — DWH_dbo.Dim_Customer.GCID) |
| 3 | Regulation | nvarchar(500) | YES | No | Short code for the regulatory jurisdiction. CySEC (54.2%), FCA (25.8%), FinCEN+FINRA (6.1%), ASIC & GAML (5.2%), FSA Seychelles (4.5%), others. (Tier 1 — DWH_dbo.Dim_Regulation.Name) |
| 4 | PlayerStatus | nvarchar(500) | YES | No | Human-readable account restriction state label. Unlike KYC_Process, this table includes Blocked accounts. Values: Normal (majority), Blocked, and other restriction states. (Tier 1 — DWH_dbo.Dim_PlayerStatus.Name) |
| 5 | Club | nvarchar(500) | YES | No | Customer experience tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Determines platform features and permissions. (Tier 1 — DWH_dbo.Dim_PlayerLevel.Name) |
| 6 | Country | nvarchar(500) | YES | No | Full country name in English for the customer's country of residence. (Tier 1 — DWH_dbo.Dim_Country.Name) |
| 7 | Region | nvarchar(500) | YES | No | Marketing region label for the customer's country. Loaded from etoro.Dictionary.MarketingRegion.Name. Examples: German, UK, French, USA, Arabic Other, Eastern Europe, ROW. NOT a geographic region. (Tier 2 — DWH_dbo.Dim_Country.Region via SP_Dictionaries_Country_DL_To_Synapse) |
| 8 | FirstDepositDate | datetime | YES | No | Date of first deposit. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate override logic. DEFAULT='19000101' for customers who have not deposited. (Tier 1 — DWH_dbo.Dim_Customer.FirstDepositDate) |
| 9 | FirstDepositAmount | money | YES | No | Amount of first deposit in USD. (Tier 1 — DWH_dbo.Dim_Customer.FirstDepositAmount) |
| 10 | RegisteredReal | datetime | YES | No | Account registration date (renamed from Registered in production). (Tier 1 — DWH_dbo.Dim_Customer.RegisteredReal) |
| 11 | Gender | nvarchar(500) | YES | **Yes** | Gender: M, F, or U (Unknown). PII column from Dim_Customer. (Tier 1 — DWH_dbo.Dim_Customer.Gender) |
| 12 | Age | int | YES | **Yes** | Customer age in years as of the SP run date. Computed as DATEDIFF(YEAR, BirthDate, GETDATE()). May be off by 1 year for pre-birthday dates. (Tier 2 — SP_AML_KYC_SOF, Dim_Customer.BirthDate) |
| 13 | UserName | nvarchar(500) | YES | **Yes** | Customer login username. PII column from Dim_Customer. (Tier 1 — DWH_dbo.Dim_Customer.UserName) |
| 14 | ManagerFullName | nvarchar(500) | YES | No | Full name of the assigned account manager: FirstName + ' ' + LastName from Dim_Manager. 'System  ' (with trailing spaces) for system-assigned accounts. (Tier 2 — SP_AML_KYC_SOF, DWH_dbo.Dim_Manager) |
| 15 | Q10_Annual_Income | nvarchar(500) | YES | No | Question text for Q10 (annual income): "What is your net annual income?" Stores the question label, not a code. Sourced from BI_DB_KYC_Panel. (Tier 2 — BI_DB_dbo.BI_DB_KYC_Panel.Q10_Annual_Income) |
| 16 | Q10_AnswerText | nvarchar(500) | YES | No | Customer's selected answer text for Q10 annual income bracket. Values: "Up to $10K", "$10K-$50K", "$50K-$200K", "$200K+". Sourced from BI_DB_KYC_Panel. (Tier 2 — BI_DB_dbo.BI_DB_KYC_Panel.Q10_AnswerText) |
| 17 | Q11_Liquid_Assets | nvarchar(500) | YES | No | Question text for Q11 (liquid assets): "What is your total cash and liquid assets?" Stores the question label. Sourced from BI_DB_KYC_Panel. (Tier 2 — BI_DB_dbo.BI_DB_KYC_Panel.Q11_Liquid_Assets) |
| 18 | Q11_AnswerText | nvarchar(500) | YES | No | Customer's selected answer text for Q11 liquid assets bracket. Values: "Up to $10K", "$10K-$50K", "$50K-$200K", "$200K+". Sourced from BI_DB_KYC_Panel. (Tier 2 — BI_DB_dbo.BI_DB_KYC_Panel.Q11_AnswerText) |
| 19 | Q14_Planned_Invested_Amount | nvarchar(500) | YES | No | Question text for Q14 (planned investment): "How much money do you plan to invest in your eToro account in the next year?" Stores the question label. The key SOF trigger column. Sourced from BI_DB_KYC_Panel. (Tier 2 — BI_DB_dbo.BI_DB_KYC_Panel.Q14_Planned_Invested_Amount) |
| 20 | Q14_AnswerText | nvarchar(500) | YES | No | Customer's selected answer text for Q14 planned investment bracket. Values: "Up to $1k", "$1k-$5k", "$5k-$20k", "Up to $20K", "$20k-$50k", "$50k-$200k", "$200k-$500k", "$500k-$1M", "Above $1M". This drives Max_Q14_Answer and SOF logic. (Tier 2 — BI_DB_dbo.BI_DB_KYC_Panel.Q14_AnswerText) |
| 21 | Max_Q14_Answer | int | YES | No | Numeric upper bound mapped from Q14_AnswerText via CASE statement. Values: 1000, 5000, 20000, 50000, 200000, 500000, 1000000. 0 for unmapped answers ('$20k-$100k', 'More than $100k' — ~1,505 rows affected). (Tier 2 — SP_AML_KYC_SOF CASE mapping) |
| 22 | Total_Deposit | money | YES | No | All-time sum of approved deposits (USD). SUM(Fact_CustomerAction.Amount WHERE ActionTypeID=7). The value compared against Max_Q14_Answer to compute the SOF signal. (Tier 2 — SP_AML_KYC_SOF, DWH_dbo.Fact_CustomerAction) |
| 23 | RemainingAmount | money | YES | No | Max_Q14_Answer minus Total_Deposit. Positive = headroom remaining; negative = customer deposited more than declared Q14 plan. (Tier 2 — SP_AML_KYC_SOF: Max_Q14_Answer - Total_Deposit) |
| 24 | %RemainingAmount | decimal(18,0) | YES | No | Percentage of Q14 planned amount not yet deposited, rounded to integer: (RemainingAmount / Max_Q14_Answer) × 100. NULL when Max_Q14_Answer = 0 (unmapped Q14 answers). **Column name contains a % character — must be quoted as `[%RemainingAmount]` in SQL.** (Tier 2 — SP_AML_KYC_SOF) |
| 25 | SOF_Predication | nvarchar(500) | YES | No | Source of Funds review decision. Values: 'Do not check SOF' (85.8%), 'SOF' (13.6% — deposits close to/exceeding cap), 'SOF should be checked' (0.6% — HNWI track). Note: column name may be a variant spelling of "Prediction." (Tier 2 — SP_AML_KYC_SOF business logic) |
| 26 | ReasonType | nvarchar(500) | YES | No | Detailed reason behind the SOF_Predication. Values: 'Normal' (85.2%), 'More then decleared deposit' (10.9%), 'Less then 15% left' (2.5%), 'HNWI' (0.6%). Note: strings contain spelling errors preserved from SP code — match exactly. (Tier 2 — SP_AML_KYC_SOF) |
| 27 | HasBusinessPotential | int | YES | No | 1 if %RemainingAmount ≥ 85 (customer has ≥85% of stated plan not yet deposited — high growth potential). 0 otherwise. 2,796,069 customers have HasBusinessPotential=1 with ReasonType='Normal'. (Tier 2 — SP_AML_KYC_SOF) |
| 28 | HasOpenPosition | int | YES | No | 1 if the customer had at least one open position as of yesterday (from BI_DB_PositionPnL); 0 otherwise. (Tier 2 — SP_AML_KYC_SOF, BI_DB_dbo.BI_DB_PositionPnL) |
| 29 | Last_Open_Position_Date | date | YES | No | Date of the customer's most recently opened trading position. MAX(Dim_Position.OpenOccurred). NULL if no positions ever opened. (Tier 2 — SP_AML_KYC_SOF, DWH_dbo.Dim_Position) |
| 30 | Last_Close_Position_Date | date | YES | No | Date of the customer's most recently closed trading position. MAX(Dim_Position.CloseOccurred). NULL if no positions ever closed. (Tier 2 — SP_AML_KYC_SOF, DWH_dbo.Dim_Position) |
| 31 | Equity | money | YES | No | Net equity (USD) as of yesterday: ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) from DWH_dbo.V_Liabilities. (Tier 2 — SP_AML_KYC_SOF, DWH_dbo.V_Liabilities) |
| 32 | Last_Login_Date | int | YES | No | DateID (YYYYMMDD integer) of the customer's most recent login. MAX(Fact_CustomerAction.DateID WHERE ActionTypeID=14). **Stored as INT, not as datetime.** (Tier 2 — SP_AML_KYC_SOF, DWH_dbo.Fact_CustomerAction) |
| 33 | DocumentType | nvarchar(500) | YES | No | Document type name of the customer's most recent qualifying document from BackOffice (latest by DateAdded). NULL if no relevant document found. (Tier 2 — SP_AML_KYC_SOF, External_etoro_BackOffice_CustomerDocument) |
| 34 | DocumentDateAdded | datetime | YES | No | Date and time when the most recent qualifying document was submitted to BackOffice. NULL if no document. (Tier 2 — SP_AML_KYC_SOF, External_etoro_BackOffice_CustomerDocument) |
| 35 | SuggestedDocumentType | nvarchar(500) | YES | No | Suggested document type for 'Not Accepted' documents where the system suggested 'Proof of Income'. Used in HasProofOfIncome logic. (Tier 2 — SP_AML_KYC_SOF, External_etoro_BackOffice_CustomerDocument) |
| 36 | RejectReasonName | nvarchar(500) | YES | No | Reason a document was rejected. From External_etoro_Dictionary_DocumentRejectReason. NULL for most rows (no rejection recorded or filter: RejectReasonID IS NULL). (Tier 2 — SP_AML_KYC_SOF) |
| 37 | DocumentStatus | nvarchar(500) | YES | No | Status of the document submission from BackOffice. 'N/A' if no document on file for this customer; actual status values (e.g., 'Pending', 'Approved') when a document exists. (Tier 2 — SP_AML_KYC_SOF, External_etoro_Dictionary_DocumentStatus) |
| 38 | HasProofOfIncome | int | YES | No | 1 if a 'Proof of Income' document is on file (either as DocumentType='Proof of Income' or as a 'Not Accepted' document with SuggestedDocumentType='Proof of Income'); 0 otherwise. 0 for the vast majority of current rows. (Tier 2 — SP_AML_KYC_SOF) |
| 39 | HasSOFLast6Months | int | YES | No | 1 if a qualifying proof of income document was submitted within the last 6 months (DocumentDateAdded >= DATEADD(MONTH,-6,GETDATE())); 0 otherwise. Indicates whether recent SOF documentation is available. (Tier 2 — SP_AML_KYC_SOF) |
| 40 | UpdateDate | datetime | YES | No | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at each full refresh. (Propagation — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Chain

```
UserApiDB.KYC.CustomerAnswers (Q10/Q11/Q14 questionnaire responses)
  → External_V_CustomerAnswers_Range_KYC_Panel → BI_DB_KYC_Panel → Q10/Q11/Q14 columns

DWH_dbo.Dim_Customer + Dim_Regulation/PlayerStatus/PlayerLevel/Country
  → Base population (VL3, depositors, valid)

DWH_dbo.Fact_CustomerAction (ActionTypeID=7) → Total_Deposit
DWH_dbo.V_Liabilities → Equity
BI_DB_dbo.BI_DB_PositionPnL → HasOpenPosition
DWH_dbo.Dim_Position → Last_Open/Close_Position_Date
DWH_dbo.Fact_CustomerAction (ActionTypeID=14) → Last_Login_Date

etoro.BackOffice.CustomerDocument → External_etoro_BackOffice_CustomerDocument
  → DocumentType, DocumentDateAdded, HasProofOfIncome, HasSOFLast6Months

SP_AML_KYC_SOF (TRUNCATE + INSERT)
  → BI_DB_dbo.BI_DB_AML_KYC_SOF
```

### 5.2 Regulation Distribution

| Regulation | Count | % |
|-----------|-------|---|
| CySEC | 2,911,922 | 54.2% |
| FCA | 1,383,486 | 25.8% |
| FinCEN+FINRA | 329,776 | 6.1% |
| ASIC & GAML | 281,046 | 5.2% |
| FSA Seychelles | 241,579 | 4.5% |
| FinCEN | 100,528 | 1.9% |
| FSRA | 79,070 | 1.5% |
| ASIC | 42,308 | 0.8% |
| Others | 1,514 | <0.1% |

---

## 6. Relationships

### 6.1 Sources (this table reads from)

| Source | Join | Purpose |
|--------|------|---------|
| DWH_dbo.Dim_Customer | RealCID = CID | Population base, identity, financials |
| DWH_dbo.Dim_Regulation | RegulationID = DWHRegulationID | Regulation name |
| DWH_dbo.Dim_PlayerStatus | PlayerStatusID = PlayerStatusID | Status name |
| DWH_dbo.Dim_PlayerLevel | PlayerLevelID = PlayerLevelID | Club name |
| DWH_dbo.Dim_Country | CountryID = DWHCountryID | Country + Region |
| DWH_dbo.Dim_Manager | AccountManagerID = ManagerID | Manager name |
| BI_DB_dbo.BI_DB_KYC_Panel | RealCID = CID | KYC questionnaire answers |
| DWH_dbo.Fact_CustomerAction | RealCID = CID, ActionTypeID=7 | Total deposits |
| DWH_dbo.V_Liabilities | CID = CID, DateID=yesterday | Equity |
| BI_DB_dbo.BI_DB_PositionPnL | CID = CID, DateID=yesterday | HasOpenPosition |
| DWH_dbo.Dim_Position | CID = CID | Last position dates |
| DWH_dbo.Fact_CustomerAction (ActionTypeID=14) | RealCID = CID | Last login DateID |
| External_etoro_BackOffice_CustomerDocument | CID = CID | Proof of income documents |
| External_etoro_Dictionary_DocumentType | DocumentTypeID | Document type name |
| External_etoro_Dictionary_DocumentStatus | DocumentStatusID | Document status name |
| External_etoro_Dictionary_DocumentRejectReason | RejectReasonID | Reject reason name |

### 6.2 Downstream Consumers

Consumed by AML SOF review workflow and case management tools. BI_DB_SF_Cases_Panel is referenced in the SP for HasOpenTicket (computed but not stored — orphaned join).

---

## 7. Sample Queries

### 7.1 Active SOF queue by regulation

```sql
SELECT
    Regulation,
    SOF_Predication,
    ReasonType,
    COUNT(*) AS CustomerCount,
    AVG(Equity) AS AvgEquity,
    AVG(Total_Deposit) AS AvgTotalDeposit
FROM [BI_DB_dbo].[BI_DB_AML_KYC_SOF]
WHERE SOF_Predication IN ('SOF', 'SOF should be checked')
GROUP BY Regulation, SOF_Predication, ReasonType
ORDER BY CustomerCount DESC;
```

### 7.2 SOF customers without proof of income documentation

```sql
SELECT
    CID,
    Regulation,
    Country,
    Q14_AnswerText,
    Total_Deposit,
    Max_Q14_Answer,
    [%RemainingAmount],
    ReasonType,
    Equity,
    Last_Login_Date
FROM [BI_DB_dbo].[BI_DB_AML_KYC_SOF]
WHERE SOF_Predication = 'SOF'
  AND HasProofOfIncome = 0
ORDER BY Equity DESC;
```

### 7.3 Business potential pipeline (high investment headroom)

```sql
SELECT
    Regulation,
    Q14_AnswerText,
    AVG(CAST([%RemainingAmount] AS FLOAT)) AS AvgPctRemaining,
    SUM(Total_Deposit) AS TotalDeposited,
    COUNT(*) AS CustomerCount
FROM [BI_DB_dbo].[BI_DB_AML_KYC_SOF]
WHERE HasBusinessPotential = 1
  AND ReasonType = 'Normal'
  AND Max_Q14_Answer > 0
GROUP BY Regulation, Q14_AnswerText
ORDER BY TotalDeposited DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian Confluence sources identified for this specific object.

---

*Generated: 2026-04-22 | Quality: 8.1/10 | Batch: 46*
*Tiers: 11 T1, 28 T2, 0 T3, 0 T4, 0 T5, 1 propagation | Columns: 40/40*
*Object: BI_DB_dbo.BI_DB_AML_KYC_SOF | Writer SP: SP_AML_KYC_SOF | Priority: 0*
