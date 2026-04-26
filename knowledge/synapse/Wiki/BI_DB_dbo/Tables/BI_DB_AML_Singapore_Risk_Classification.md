# BI_DB_dbo.BI_DB_AML_Singapore_Risk_Classification

**Generated**: 2026-04-22  
**Schema**: BI_DB_dbo  
**Object Type**: Table  
**Writer SP**: SP_AML_Singapore_Risk_Classification  
**Load Pattern**: TRUNCATE + INSERT daily (@Date parameter)  
**Distribution**: ROUND_ROBIN  
**Index**: HEAP  
**Column Count**: 45  
**Row Count**: 1,355  
**Population**: MAS (Monetary Authority of Singapore) customers only  
**Priority**: 0 (OpsDB)  
**Frequency**: Daily  
**UC Migration**: Not Migrated  

---

## 1. Overview

Daily AML risk classification table for **Singapore-regulated (MAS) customers**. Each row represents one MAS customer scored against the Singapore AML risk model, producing a composite `Final_Score` and a `Risk_Score` category (Low / Medium / High / Blocked).

**Population**: Customers with `RegulationID = 13 (MAS)`, `VerificationLevelID >= 2` (partially or fully KYC-verified), `IsDepositor = 1`, and `PlayerStatusID NOT IN (2, 4)`. Population state is read from `Fact_SnapshotCustomer` (point-in-time snapshot for the @Date run parameter), not from the current `Dim_Customer` state.

**Score Architecture** — The Final_Score is a sum of 10 components:

| Component | Source | Max Score |
|---|---|---|
| ScreeningStauts_Final_Score | Screening outcome (Domestic PEP=50, Foreign PEP/Risk Match=200) | 200 |
| Sources_of_funds_Final_Score | KYC Q26 SOF answer (Inheritance/Other/Family=50, Lottery/Gambling=100) | 100 |
| Occupation_Final_Score | KYC Q18 occupation by answer ID (high-risk list=50, moderate list=25) | 50 |
| Employment_Status_Final_Score | KYC Q216 (Self-employed/Not Employed/Retired=50) | 50 |
| Annual_Income_Final_Score | KYC Q10 ('$1M-$5M'=50, else 0) | 50 |
| Liquid_Assets_Final_Score | KYC Q11 ('Over $1M' or '$1M-$5M'=50, else 0) | 50 |
| Net_Deposits_Final_Score | Net deposits (Total deposits − cashouts) > $1M → 100 | 100 |
| Max_Country_Score* | MAX(Nationality, POB, KYC_Country, Second_Citizenship scores) | 300 |
| Redeem_Score | Has redeem cashout (IsRedeem=1) → 100 | 100 |
| Instrument_Risk_Score | Has settled crypto position → 50 | 50 |

*Max_Country_Score = MAX of 4 country-risk lookups against `External_Fivetran_google_sheets_risk_score_country` (sg_country_aml_rank: Low=0, Medium=50, High=100, Blocked=300). **Not stored as a separate column** — only used in Final_Score.

**Risk_Score classification**:

| Risk_Score | Condition | Count | % |
|---|---|---|---|
| Blocked | Any block flag triggered (Sanctions Match, or Blocked-ranked country for Nationality/POB/KYC/Second Citizenship) | 1 | 0.1% |
| High | Final_Score ≥ 200 (and not Blocked) | 16 | 1.2% |
| Medium | 100 ≤ Final_Score ≤ 199 (and not Blocked) | 356 | 26.3% |
| Low | Final_Score < 100 (and not Blocked) | 982 | 72.5% |

---

## 2. Column Inventory

| # | Column | Type | Nullable | Tier | Source |
|---|--------|------|----------|------|--------|
| 1 | CID | int | YES | T1 | DWH_dbo.Fact_SnapshotCustomer.RealCID |
| 2 | GCID | int | YES | T1 | DWH_dbo.Dim_Customer.GCID |
| 3 | Regulation | varchar(250) | YES | T1 | DWH_dbo.Dim_Regulation.Name (always 'MAS') |
| 4 | PlayerStatus | varchar(250) | YES | T1 | DWH_dbo.Dim_PlayerStatus.Name |
| 5 | Club | varchar(250) | YES | T1 | DWH_dbo.Dim_PlayerLevel.Name |
| 6 | Country | varchar(250) | YES | T1 | DWH_dbo.Dim_Country.Name (via Fact_SnapshotCustomer.CountryID — snapshot country) |
| 7 | Nationality_Country | varchar(250) | YES | T1 | DWH_dbo.Dim_Country.Name (via Dim_Customer.CitizenshipCountryID) |
| 8 | ScreeningStatus | varchar(250) | YES | T2 | Enriched from Dim_ScreeningStatus: 'No Match' / 'Domestic PEP' / 'Foreign PEP' / other statuses |
| 9 | SOF_Answer_KYC | varchar(250) | YES | T2 | BI_DB_KYC_Panel.Q26_AnswerText (Source of Funds) |
| 10 | Occupation_KYC | varchar(250) | YES | T2 | BI_DB_KYC_Panel.Q18_AnswerText (Occupation) |
| 11 | Annual_Income_Answer | varchar(250) | YES | T2 | BI_DB_KYC_Panel.Q10_AnswerText (Net Annual Income bracket) |
| 12 | Q11_Liquid_Assets_Answer | varchar(250) | YES | T2 | BI_DB_KYC_Panel.Q11_AnswerText (Total Cash and Liquid Assets bracket) |
| 13 | Net_Deposits | money | YES | T2 | SUM(deposits) − SUM(cashouts) from DWH_dbo.Fact_CustomerAction |
| 14 | ScreeningStauts_Final_Score | int | YES | T2 | Score: 0 (No Match), 50 (Domestic PEP), 200 (Foreign PEP or Risk Match) |
| 15 | Screening_Block_Final | varchar(250) | YES | T2 | 'Blocked' if ScreeningStatusID=7 (Sanctions Match); NULL otherwise |
| 16 | Occupation_Final_Score | int | YES | T2 | Score per Q18 answer ID: 50 / 25 / 0 |
| 17 | Sources_of_funds_Final_Score | int | YES | T2 | Score per Q26 answer: 0 / 50 / 100 (MAX when multiple answers) |
| 18 | Nationality_Final_Score | int | YES | T2 | SG GRC score for Nationality_Country: 0 / 50 / 100 / 300 |
| 19 | NationalityB_Final_Score | varchar(250) | YES | T2 | 'Blocked' if Nationality_Country is Blocked-ranked in SG GRC sheet |
| 20 | Annual_Income_Final_Score | int | YES | T2 | Score per Q10: 50 if '$1M-$5M'; 0 otherwise |
| 21 | Liquid_Assets_Final_Score | int | YES | T2 | Score per Q11: 50 if 'Over $1M' or '$1M-$5M'; 0 otherwise |
| 22 | Net_Deposits_Final_Score | int | YES | T2 | 100 if Net_Deposits > $1,000,000; 0 otherwise |
| 23 | UpdateDate | datetime | YES | — | ETL metadata: GETDATE() at insert time |
| 24 | RegisteredReal | datetime | YES | T1 | DWH_dbo.Dim_Customer.RegisteredReal |
| 25 | FirstDepositDate | datetime | YES | T1 | DWH_dbo.Dim_Customer.FirstDepositDate |
| 26 | Final_Score | int | YES | T2 | Sum of all 10 score components (see Overview) |
| 27 | Risk_Score | varchar(250) | YES | T2 | 'Blocked' / 'High' / 'Medium' / 'Low' classification |
| 28 | Report_Date | date | YES | T2 | Run date = @Date parameter value |
| 29 | POB_Final_Score | int | YES | T2 | SG GRC score for POBCountry: 0 / 50 / 100 / 300 |
| 30 | POB_B_Final_Score | varchar(250) | YES | T2 | 'Blocked' if POBCountry is Blocked-ranked in SG GRC sheet |
| 31 | POBCountry | varchar(250) | YES | T1 | DWH_dbo.Dim_Country.Name (via Dim_Customer.POBCountryID) |
| 32 | TIN_CountryName | varchar(250) | YES | T2 | Tax country name from TIN declaration (External_UserApiDB_Customer_ExtendedUserField FieldId=6); '()' values converted to NULL |
| 33 | VerificationLevel3Date | datetime | YES | T2 | BI_DB_dbo.BI_DB_CIDFirstDates.VerificationLevel3Date (date customer reached full KYC verification) |
| 34 | Redeem_Score | int | YES | T2 | 100 if customer has a redemption cashout (ActionTypeID=8, IsRedeem=1); 0 otherwise |
| 35 | Instrument_Risk_Score | int | YES | T2 | 50 if customer has at least one settled crypto position (InstrumentTypeID=10, IsSettled=1); 0 otherwise |
| 36 | CountryIDByIP | nvarchar(250) | YES | T2 | DWH_dbo.Dim_Country.Name resolved from Dim_Customer.CountryIDByIP (country of last known login IP) |
| 37 | KYC_Country_Final_Score | int | YES | T2 | SG GRC score for Country (KYC/snapshot country): 0 / 50 / 100 / 300 |
| 38 | KYC_Country_Final_Score_B_Final_Score | nvarchar(250) | YES | T2 | 'Blocked' if KYC Country is Blocked-ranked in SG GRC sheet |
| 39 | Employment_Status | nvarchar(250) | YES | T2 | KYC Q216 employment status answer text (from BI_DB_KYC_Questions_Answers_Row_Data) |
| 40 | Employment_Status_Final_Score | int | YES | T2 | 50 if Self-employed / Not Employed / Retired; 0 otherwise |
| 41 | Citizenship_Sec_Final_Score | int | YES | T2 | SG GRC score for Second_Citizenship country: 0 / 50 / 100 / 300 |
| 42 | Citizenship_Sec_Final_Score_B_Final_Score | nvarchar(250) | YES | T2 | 'Blocked' if Second Citizenship country is Blocked-ranked |
| 43 | Second_Citizenship | varchar(250) | YES | T2 | DWH_dbo.Dim_Country.Name (via External_UserApiDB_Customer_AdditionalCitizenship) |
| 44 | VerificationLevelID | int | YES | T2 | DWH_dbo.Fact_SnapshotCustomer.VerificationLevelID (snapshot value; >= 2 in all rows) |
| 45 | VerificationLevel2Date | datetime | YES | T2 | BI_DB_dbo.BI_DB_CIDFirstDates.VerificationLevel2Date (date customer reached partial KYC verification) |

---

## 3. ETL Pipeline

```
@Date parameter → @DateID via BI_DB_dbo.DateToDateID()

[Population — MAS snapshot]
Fact_SnapshotCustomer (IsValidCustomer=1, VerificationLevelID>=2, RegulationID=13, IsDepositor=1)
  JOIN Dim_Range (point-in-time date filter)
  JOIN Dim_Customer, Dim_Regulation, Dim_Country (×4), Dim_PlayerLevel, Dim_PlayerStatus
  LEFT JOIN Dim_ScreeningStatus, BI_DB_CIDFirstDates
→ #pop

[Score Enrichment]
BI_DB_KYC_Panel (Q10, Q11, Q18, Q26) → income, assets, occupation, SOF scores
BI_DB_KYC_Questions_Answers_Row_Data (Q216) → employment status score
External_Fivetran_google_sheets_risk_score_country → country risk scores (4 dimensions)
External_UserApiDB_Customer_AdditionalCitizenship → second citizenship country score
External_UserApiDB_Customer_ExtendedUserField (FieldId=6) → TIN country
Fact_CustomerAction (deposits + cashouts) → Net_Deposits, Net_Deposits_Final_Score
Fact_CustomerAction (IsRedeem=1) → Redeem_Score
Dim_Position + Dim_Instrument (InstrumentTypeID=10, IsSettled=1) → Instrument_Risk_Score

[Assembly → #final → #final_Country (max country score) → #FinalScore → #riskscore → #riskscore2]

TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Singapore_Risk_Classification
INSERT FROM #riskscore2
```

SP author information not recorded in SP header.

---

## 4. Column Descriptions

### CID
**Type**: int NULL  
**Tier**: T1 — DWH_dbo.Fact_SnapshotCustomer (Tier 1 — Customer.CustomerStatic)  
**Description**: Customer ID — platform-internal primary key. The point-in-time population is built from `Fact_SnapshotCustomer.RealCID`, but CID is equivalent to `Dim_Customer.RealCID`.

---

### GCID
**Type**: int NULL  
**Tier**: T1 — DWH_dbo.Dim_Customer  
**Description**: Group Customer ID. Used for TIN lookups (ExtendedUserField) and KYC question answers (BI_DB_KYC_Questions_Answers_Row_Data). Shared across group-level services.

---

### Regulation
**Type**: varchar(250) NULL  
**Tier**: T1 — DWH_dbo.Dim_Regulation.Name (Tier 1 — BackOffice.Customer)  
**Description**: Regulatory jurisdiction. **Always 'MAS'** in this table — the population filter enforces `RegulationID = 13`. Stored for audit/consistency with other AML tables.

---

### PlayerStatus
**Type**: varchar(250) NULL  
**Tier**: T1 — DWH_dbo.Dim_PlayerStatus.Name (Tier 1 — BackOffice.Customer)  
**Description**: Customer's current account status. All rows are Normal or Warning — PlayerStatusID 2 (Blocked) and 4 (Blocked Upon Request) are excluded from the population.

---

### Club
**Type**: varchar(250) NULL  
**Tier**: T1 — DWH_dbo.Dim_PlayerLevel.Name (Tier 1 — BackOffice.Customer)  
**Description**: Customer's loyalty/experience tier (Bronze, Silver, Gold, Platinum, Diamond, etc.). Context indicator for the AML risk review.

---

### Country
**Type**: varchar(250) NULL  
**Tier**: T1 — DWH_dbo.Dim_Country.Name (Tier 1 — BackOffice.Customer)  
**Description**: Customer's country of residence **as of the snapshot date** (`Fact_SnapshotCustomer.CountryID`). For a Singapore (MAS) population this is predominantly Singapore. Because this comes from the snapshot table, it reflects the customer's country at @Date rather than today's Dim_Customer value. Used for `KYC_Country_Final_Score`.

---

### Nationality_Country
**Type**: varchar(250) NULL  
**Tier**: T1 — DWH_dbo.Dim_Country.Name (Tier 1 — BackOffice.Customer)  
**Description**: Customer's citizenship country (`Dim_Customer.CitizenshipCountryID → Dim_Country.Name`). Distinct from Country (residence). Used for `Nationality_Final_Score`. NULL if no citizenship country on record. Sample includes Singapore, India, Lithuania and other nationalities for MAS-regulated customers.

---

### ScreeningStatus
**Type**: varchar(250) NULL  
**Tier**: T2 — enriched from DWH_dbo.Dim_ScreeningStatus  
**Description**: AML screening outcome, enriched beyond the raw Dim_ScreeningStatus values to distinguish Singapore-local PEPs:
- `No Match` — ScreeningStatusID=1 (1,354 rows, 99.9%)
- `Domestic PEP` — ScreeningStatusID=3 AND Nationality_Country = Singapore (CountryID=183)
- `Foreign PEP` — ScreeningStatusID=3 AND Nationality_Country ≠ Singapore
- Other Dim_ScreeningStatus.Name values (RiskMatch, PendingInvestigation, etc.)
- Sanctions Match (ScreeningStatusID=7) customers are **excluded from this column** — they appear in `Screening_Block_Final = 'Blocked'` instead; their ScreeningStatus here is NULL.

**Profile**: No Match 1,354 (99.9%), PendingInvestigation 1 (0.07%).

---

### SOF_Answer_KYC
**Type**: varchar(250) NULL  
**Tier**: T2 — BI_DB_KYC_Panel.Q26_AnswerText  
**Description**: KYC questionnaire answer to Q26 "What is your source of funds?". May contain comma-separated multiple answers (e.g., "Savings, Salary, Investments"). Drives `Sources_of_funds_Final_Score`. NULL if no KYC panel record.

---

### Occupation_KYC
**Type**: varchar(250) NULL  
**Tier**: T2 — BI_DB_KYC_Panel.Q18_AnswerText  
**Description**: KYC questionnaire answer to Q18 "What is your occupation?". Drives `Occupation_Final_Score` (via Q18_AnswerID). NULL if no KYC panel record.  
**Profile**: Occupation_Final_Score > 0 in 576 rows (42.5%).

---

### Annual_Income_Answer
**Type**: varchar(250) NULL  
**Tier**: T2 — BI_DB_KYC_Panel.Q10_AnswerText  
**Description**: KYC questionnaire answer to Q10 "What is your net annual income?". Stored as raw text bracket (e.g., '$50K-100K', '$1M-$5M'). Only the '$1M-$5M' bracket triggers a risk score contribution (`Annual_Income_Final_Score = 50`). NULL if no KYC panel record.

---

### Q11_Liquid_Assets_Answer
**Type**: varchar(250) NULL  
**Tier**: T2 — BI_DB_KYC_Panel.Q11_AnswerText  
**Description**: KYC questionnaire answer to Q11 "What is your total cash and liquid assets?". Stored as raw bracket text. 'Over $1M' and '$1M-$5M' both trigger `Liquid_Assets_Final_Score = 50`. NULL if no KYC panel record.

---

### Net_Deposits
**Type**: money NULL  
**Tier**: T2 — DWH_dbo.Fact_CustomerAction  
**Description**: Lifetime net deposits = SUM(deposit amounts, ActionTypeID=7) − SUM(cashout amounts, ActionTypeID=8). Represents the customer's net lifetime capital inflow. Customers with Net_Deposits > $1,000,000 receive `Net_Deposits_Final_Score = 100` (High Net Worth indicator).  
**Profile**: Net_Deposits_Final_Score > 0 in 0 rows — no MAS customers currently exceed the $1M threshold.

---

### ScreeningStauts_Final_Score
**Type**: int NULL  
**Tier**: T2 — computed from Dim_ScreeningStatus  
**Description**: Risk score component from screening outcome. Note: column name has a typo ("Stauts" instead of "Status") — this is carried from the DDL into production.
- `0` — No Match
- `50` — Domestic PEP (Singapore national with PEP status)
- `200` — Foreign PEP or Risk Match

Sanctions Match customers (ScreeningStatusID=7) are handled by `Screening_Block_Final` instead and **do not contribute** to this score column.  
**Profile**: ScreeningStauts_Final_Score > 0 in 0 rows (the 1 PendingInvestigation customer scores 0).

---

### Screening_Block_Final
**Type**: varchar(250) NULL  
**Tier**: T2 — computed  
**Description**: Set to 'Blocked' if the customer has `ScreeningStatusID = 7` (Sanctions Match). NULL for all other screening outcomes. **Triggers Risk_Score = 'Blocked'** regardless of Final_Score. This column captures sanctions-matched customers who are excluded from the #Screening score table.

---

### Occupation_Final_Score
**Type**: int NULL  
**Tier**: T2 — computed from BI_DB_KYC_Panel.Q18_AnswerID  
**Description**: Risk score component from occupation. Scored by Q18_AnswerID (not free-text) against two risk lists:
- **Score 50**: 29 high-risk occupation answer IDs (industries including defence/arms, mining, gambling, manufacturing/heavy industry, and others)
- **Score 25**: 4 moderate-risk occupation answer IDs
- **Score 0**: All other occupations (including 'Computer/IT Services', 'Real estate', 'Finance Industry')

**Profile**: Occupation_Final_Score > 0 in 576 rows (42.5%).

---

### Sources_of_funds_Final_Score
**Type**: int NULL  
**Tier**: T2 — computed from BI_DB_KYC_Panel.Q26_AnswerText  
**Description**: Risk score component from source of funds declaration. Each Q26 answer keyword is scored individually; the MAX score across all applicable keywords is taken (not sum). Score mapping:
- `0`: Savings, Salary, Investments, Pension, Severance
- `50`: Inheritance, Other, Family financial support
- `100`: Lottery, Gambling

If a customer answers 'Salary, Inheritance', the score is 50 (MAX). NULL answers not matched yield no score contribution.  
**Profile**: Sources_of_funds_Final_Score > 0 in 105 rows (7.7%).

---

### Nationality_Final_Score
**Type**: int NULL  
**Tier**: T2 — External_Fivetran_google_sheets_risk_score_country  
**Description**: Singapore AML country risk score for the customer's citizenship country (Nationality_Country). Sourced from the Singapore GRC Google Sheet via Fivetran (`sg_country_aml_rank`):
- Low = 0, Medium = 50, High = 100, Blocked = 300

NULL if Nationality_Country is not in the GRC sheet. This score is **one of 4 inputs to the max-country-score logic** — only the MAX of (Nationality, POB, KYC_Country, Second_Citizenship) contributes to Final_Score.

---

### NationalityB_Final_Score
**Type**: varchar(250) NULL  
**Tier**: T2 — computed  
**Description**: 'Blocked' if the customer's Nationality_Country has `sg_country_aml_rank = 'Blocked'` in the Singapore GRC sheet. NULL otherwise. **Contributes to Risk_Score = 'Blocked'** when set.

---

### Annual_Income_Final_Score
**Type**: int NULL  
**Tier**: T2 — computed from BI_DB_KYC_Panel.Q10_AnswerText  
**Description**: Risk score contribution from declared annual income. 50 if Q10 answer is exactly '$1M-$5M'; 0 for all other answers including NULL. The threshold captures Ultra High Net Worth customers as a specific risk segment.

---

### Liquid_Assets_Final_Score
**Type**: int NULL  
**Tier**: T2 — computed from BI_DB_KYC_Panel.Q11_AnswerText  
**Description**: Risk score contribution from declared liquid assets. 50 if Q11 answer is 'Over $1M' or '$1M-$5M'; 0 otherwise. Complements Annual_Income_Final_Score for high-wealth customers.

---

### Net_Deposits_Final_Score
**Type**: int NULL  
**Tier**: T2 — computed from DWH_dbo.Fact_CustomerAction  
**Description**: Risk score contribution from lifetime net capital flow. 100 if `Net_Deposits > $1,000,000`; 0 otherwise. A score of 100 from this component alone is enough to push a customer to Medium risk (Final_Score ≥ 100).  
**Profile**: Currently 0 in all rows — no MAS customers exceed $1M net deposits.

---

### UpdateDate
**Type**: datetime NULL  
**Tier**: Propagation blacklist  
**Description**: ETL metadata timestamp. Set to `GETDATE()` at INSERT time. Reflects when the table was last refreshed.

---

### RegisteredReal
**Type**: datetime NULL  
**Tier**: T1 — DWH_dbo.Dim_Customer.RegisteredReal (Tier 1 — Customer.CustomerStatic)  
**Description**: Timestamp when the customer created a real-money account. Provides registration tenure context for AML review.

---

### FirstDepositDate
**Type**: datetime NULL  
**Tier**: T1 — DWH_dbo.Dim_Customer.FirstDepositDate (Tier 1 — CustomerFinanceDB.Customer.FirstTimeDeposits)  
**Description**: Date and time of the customer's first deposit. Provides deposit tenure context.

---

### Final_Score
**Type**: int NULL  
**Tier**: T2 — computed sum  
**Description**: The composite AML risk score. Sum of all 10 score components (see Overview table). Drives the Risk_Score classification:
- < 100 → 'Low'
- 100–199 → 'Medium'
- ≥ 200 → 'High'
- Any Blocked flag → 'Blocked' (overrides score)

Note: The **country risk contribution** to Final_Score is `MAX(Nationality_Final_Score, POB_Final_Score, KYC_Country_Final_Score, Citizenship_Sec_Final_Score)`, not their sum. This means multiple high-risk country indicators do not multiply the country risk penalty.

---

### Risk_Score
**Type**: varchar(250) NULL  
**Tier**: T2 — computed classification  
**Description**: AML risk category derived from Final_Score and block flags:
- `Blocked` — checked first; triggered when Screening_Block_Final='Blocked' OR any of the 4 country block flags is 'Blocked'. Overrides score-based classification.
- `High` — Final_Score ≥ 200 (and not Blocked). Requires AML review.
- `Medium` — 100 ≤ Final_Score ≤ 199 (and not Blocked).
- `Low` — Final_Score < 100 (and not Blocked).

**Profile**: Blocked 1, High 16 (1.2%), Medium 356 (26.3%), Low 982 (72.5%).

---

### Report_Date
**Type**: date NULL  
**Tier**: T2 — @Date SP parameter  
**Description**: The run date for this batch. Set to the `@Date` parameter value passed to the SP. Represents the snapshot date — data reflects customer state as of this date. Current value: 2026-04-11.

---

### POB_Final_Score
**Type**: int NULL  
**Tier**: T2 — External_Fivetran_google_sheets_risk_score_country  
**Description**: Singapore AML country risk score for the customer's country of birth (POBCountry). Same scoring scale as Nationality_Final_Score (0/50/100/300). NULL if POBCountry is not in the GRC sheet. One of 4 inputs to the max-country-score calculation.

---

### POB_B_Final_Score
**Type**: varchar(250) NULL  
**Tier**: T2 — computed  
**Description**: 'Blocked' if POBCountry has `sg_country_aml_rank = 'Blocked'`. NULL otherwise. Triggers Risk_Score = 'Blocked' when set.

---

### POBCountry
**Type**: varchar(250) NULL  
**Tier**: T1 — DWH_dbo.Dim_Country.Name (Tier 1 — BackOffice.Customer)  
**Description**: Customer's country of birth (`Dim_Customer.POBCountryID → Dim_Country.Name`). NULL if not recorded. Used for POB country risk scoring.

---

### TIN_CountryName
**Type**: varchar(250) NULL  
**Tier**: T2 — External_UserApiDB_Customer_ExtendedUserField  
**Description**: Tax residency country name from TIN (Tax Identification Number) declaration (FieldId=6 in ExtendedUserField, joined via GCID to the `External_UserApiDB_KYC_CountryTaxType` validation table). NULL if no TIN declared, or if the raw stored value is '()' (cleaned to NULL by the SP). Informational context — not used in score computation.

---

### VerificationLevel3Date
**Type**: datetime NULL  
**Tier**: T2 — BI_DB_dbo.BI_DB_CIDFirstDates  
**Description**: Date the customer first reached VerificationLevel 3 (full KYC verification). Sourced from `BI_DB_CIDFirstDates.VerificationLevel3Date`. NULL if the customer has not reached full KYC (note: the population filter allows VerificationLevelID ≥ 2, so partial-KYC customers are included and may have NULL here).

---

### Redeem_Score
**Type**: int NULL  
**Tier**: T2 — computed from DWH_dbo.Fact_CustomerAction  
**Description**: 100 if the customer has at least one redemption cashout (`Fact_CustomerAction WHERE ActionTypeID = 8 AND IsRedeem = 1`); 0 otherwise. Redemption cashouts represent conversion of trading positions to fiat — a potential money-movement risk indicator.  
**Profile**: Redeem_Score > 0 in 0 rows currently.

---

### Instrument_Risk_Score
**Type**: int NULL  
**Tier**: T2 — computed from DWH_dbo.Dim_Position + DWH_dbo.Dim_Instrument  
**Description**: 50 if the customer has at least one settled cryptocurrency position (`Dim_Position.InstrumentTypeID = 10, IsSettled = 1`). 0 otherwise. Only settled positions are considered; open positions are excluded. The SP filters instruments to relevant types (InstrumentTypeID IN 1,2,4,5,6,10) before checking crypto.  
**Profile**: Instrument_Risk_Score > 0 in 1 row (0.07%).

---

### CountryIDByIP
**Type**: nvarchar(250) NULL  
**Tier**: T2 — DWH_dbo.Dim_Country.Name (via Dim_Customer.CountryIDByIP)  
**Description**: Country name resolved from the customer's last known login IP address (`Dim_Customer.CountryIDByIP → Dim_Country.Name`). Informational context — not used in score computation but provides a geographic discrepancy indicator if it differs from Country (KYC country).

---

### KYC_Country_Final_Score
**Type**: int NULL  
**Tier**: T2 — External_Fivetran_google_sheets_risk_score_country  
**Description**: Singapore AML country risk score for the customer's KYC/snapshot country (Country). Scored from the Singapore GRC sheet (0/50/100/300). One of 4 inputs to the max-country-score calculation.

---

### KYC_Country_Final_Score_B_Final_Score
**Type**: nvarchar(250) NULL  
**Tier**: T2 — computed  
**Description**: 'Blocked' if the customer's KYC Country has `sg_country_aml_rank = 'Blocked'`. NULL otherwise. Triggers Risk_Score = 'Blocked' when set.

---

### Employment_Status
**Type**: nvarchar(250) NULL  
**Tier**: T2 — BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data  
**Description**: Employment status from KYC Question 216. Sourced from `BI_DB_KYC_Questions_Answers_Row_Data` (joined via GCID, QuestionId=216) — a different source than the other KYC answers which come from BI_DB_KYC_Panel. Values include: Employed, Self-employed, Not Employed, Retired, and others. Drives `Employment_Status_Final_Score`.

---

### Employment_Status_Final_Score
**Type**: int NULL  
**Tier**: T2 — computed from BI_DB_KYC_Questions_Answers_Row_Data  
**Description**: 50 if Employment_Status is 'Self-employed', 'Not Employed', or 'Retired'. 0 for all other employment statuses. These are considered higher-risk income profiles under the Singapore AML model.

---

### Citizenship_Sec_Final_Score
**Type**: int NULL  
**Tier**: T2 — External_Fivetran_google_sheets_risk_score_country  
**Description**: Singapore AML country risk score for the customer's second (additional) citizenship, sourced from `External_UserApiDB_Customer_AdditionalCitizenship`. Scored using the same Singapore GRC sheet scale (0/50/100/300). NULL if the customer has no second citizenship on record. One of 4 inputs to the max-country-score calculation.

---

### Citizenship_Sec_Final_Score_B_Final_Score
**Type**: nvarchar(250) NULL  
**Tier**: T2 — computed  
**Description**: 'Blocked' if the customer's second citizenship country has `sg_country_aml_rank = 'Blocked'`. NULL otherwise. Triggers Risk_Score = 'Blocked' when set.

---

### Second_Citizenship
**Type**: varchar(250) NULL  
**Tier**: T2 — External_UserApiDB_Customer_AdditionalCitizenship  
**Description**: Country name of the customer's additional citizenship, resolved via `External_UserApiDB_Customer_AdditionalCitizenship → Fivetran GRC sheet → Dim_Country`. NULL if no second citizenship declared. Used as one of the 4 country-risk inputs.

---

### VerificationLevelID
**Type**: int NULL  
**Tier**: T2 — DWH_dbo.Fact_SnapshotCustomer.VerificationLevelID  
**Description**: KYC verification level **as of the snapshot date** (@Date). Population filter requires VerificationLevelID ≥ 2 (partial or full verification). Unlike the MR/HR/AR tables which require VerificationLevelID = 3, MAS customers with partial KYC (level 2) are included. Value range in this table: 2 or 3.

---

### VerificationLevel2Date
**Type**: datetime NULL  
**Tier**: T2 — BI_DB_dbo.BI_DB_CIDFirstDates  
**Description**: Date the customer first reached VerificationLevel 2 (partial KYC verification). Sourced from `BI_DB_CIDFirstDates.VerificationLevel2Date`. Provides the partial-KYC date for customers who have not yet completed full verification.

---

## 5. Relationships

| Relationship | Object | Join Key | Notes |
|---|---|---|---|
| Source (snapshot) | DWH_dbo.Fact_SnapshotCustomer | CID = RealCID | Point-in-time customer state; population base |
| Source (current attributes) | DWH_dbo.Dim_Customer | CID = RealCID | GCID, citizenship, POB, IP country, reg/FTD dates |
| Source (dimensions) | DWH_dbo.Dim_Regulation, Dim_Country, Dim_PlayerLevel, Dim_PlayerStatus, Dim_ScreeningStatus, Dim_Range | various | Name and attribute lookups |
| Source (transactions) | DWH_dbo.Fact_CustomerAction | CID = RealCID | Deposits/cashouts (Net_Deposits) and redemptions (Redeem_Score) |
| Source (positions) | DWH_dbo.Dim_Position + Dim_Instrument | CID, InstrumentID | Crypto position detection |
| Source (KYC panel) | BI_DB_dbo.BI_DB_KYC_Panel | CID = RealCID | Q10, Q11, Q18, Q26 answers |
| Source (employment) | BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data | GCID | Q216 employment status |
| Source (verification dates) | BI_DB_dbo.BI_DB_CIDFirstDates | CID | VerificationLevel2Date, VerificationLevel3Date |
| Source (country risk) | BI_DB_dbo.External_Fivetran_google_sheets_risk_score_country | country ID | Singapore-specific GRC risk scores |
| Source (TIN) | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | GCID | TIN declaration (FieldId=6) |
| Source (second citizenship) | BI_DB_dbo.External_UserApiDB_Customer_AdditionalCitizenship | GCID | Additional citizenship country |

---

## 6. Data Profile

| Metric | Value |
|---|---|
| Row count | 1,355 |
| Grain | One row per MAS-regulated customer per run date |
| Report_Date | 2026-04-11 |
| Last UpdateDate | 2026-04-12 07:32:35 |
| Regulation | 100% MAS |
| Risk_Score = Low | 982 (72.5%) |
| Risk_Score = Medium | 356 (26.3%) |
| Risk_Score = High | 16 (1.2%) |
| Risk_Score = Blocked | 1 (0.07%) |
| ScreeningStatus = No Match | 1,354 (99.9%) |
| ScreeningStatus = PendingInvestigation | 1 (0.07%) |
| Occupation_Final_Score > 0 | 576 (42.5%) |
| Sources_of_funds_Final_Score > 0 | 105 (7.7%) |
| Instrument_Risk_Score > 0 | 1 (0.07%) |
| Net_Deposits_Final_Score > 0 | 0 (no HNW net depositors) |
| Redeem_Score > 0 | 0 (no redemption cashouts) |

---

## 7. Quality Notes

- **Column name typo**: `ScreeningStauts_Final_Score` — "Stauts" should be "Status". The typo is present in both the DDL and the SP and has propagated to the production column name. Any downstream query must use the typo spelling.
- **Sanctions Match ScreeningStatus = NULL**: Customers with ScreeningStatusID=7 (Sanctions Match) are excluded from the #Screening table and therefore have NULL `ScreeningStatus` in this table. Their status is captured in `Screening_Block_Final = 'Blocked'`. Consumers should check Screening_Block_Final when looking for sanctions-matched customers.
- **Max country score not stored**: The `Max_Final_Score` (MAX of Nationality, POB, KYC_Country, Citizenship_Sec scores) is computed in `#final_Country` and used in `Final_Score`, but is **not persisted as a column** in the output table. The 4 individual country scores are stored, so downstream consumers can recompute it as MAX(Nationality_Final_Score, POB_Final_Score, KYC_Country_Final_Score, Citizenship_Sec_Final_Score).
- **1 customer with Final_Score=300, Risk_Score='High' (not Blocked)**: This customer has a score of 300 (consistent with a Blocked country rank contributing 300 to the country score) but Risk_Score='High' instead of 'Blocked'. This may indicate a discrepancy between the #natinonality scoring (which uses an intermediate Dim_Country JOIN) and the #natinonalityB blocked flag (which uses a direct e_toro_country_id join). If the join fails in the _B table but succeeds in the numeric score table, the score captures the country risk but the block flag is not set. See the .review-needed file.
- **@Yesterday unused**: SP declares `@Yesterday = CAST(GETDATE()-2 AS DATE)` (note: 2 days ago, not 1) but this variable does not appear to be used anywhere in the SP logic. It is not a functional concern but is misleading.
- **VerificationLevelID ≥ 2, not = 3**: Unlike the MR/HR/AR tables, this table includes partially-KYC-verified customers (level 2). Some columns that require full KYC (e.g., occupation from KYC Panel) may be NULL for level-2 customers.
- **Uses Fact_SnapshotCustomer, not Dim_Customer**: The base population (Country, VerificationLevelID, RegulationID, PlayerLevelID, PlayerStatusID) is read from the snapshot table at @Date, not from current Dim_Customer state. This means the risk classification reflects historical customer attributes, not necessarily today's values. The INNER JOIN to Dim_Customer is for current attributes (GCID, CitizenshipCountryID, etc.).
- **Singapore-specific GRC sheet**: Country risk uses `External_Fivetran_google_sheets_risk_score_country` (Singapore risk sheet) — different from the general `External_Fivetran_google_sheets_grc_list` used by other AML tables. The sg_country_aml_rank values and country coverage may differ.

---

## 8. UC Migration Status

**Status**: Not Migrated  
**Reason**: AML compliance operational table for Singapore (MAS) regulatory team. No Unity Catalog target exists or is planned.
