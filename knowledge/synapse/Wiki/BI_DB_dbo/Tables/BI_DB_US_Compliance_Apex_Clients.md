# BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients

> 403K-row US compliance and Apex brokerage client profile table covering all VerificationLevel3 customers who are either closed US accounts (CountryID=219 or RegulationID IN 6,7,8) or active US Reg8 accounts, with full PII (name, address, DOB, phone, email), KYC questionnaire answers (12 pivoted questions), FINRA disclosure flags, and Apex Clearing brokerage status. Refreshed daily via `SP_US_Compliance_Apex_Clients` (TRUNCATE+INSERT). Registrations span 2010 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: DWH_dbo.Dim_Customer (primary), USABroker.Apex.ApexData/UserData (Apex brokerage), BI_DB_KYC_Questions_Answers_Row_Data (KYC), BI_DB_CIDFirstDates (VL3 date + email). Writer SP: `BI_DB_dbo.SP_US_Compliance_Apex_Clients` |
| **Refresh** | Daily — TRUNCATE+INSERT full reload (SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_us_compliance_apex_clients` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline Override) |

---

## 1. Business Meaning

This table is the primary US compliance profile for Apex Clearing integration. Each row represents one eToro customer who has reached KYC VerificationLevel3 and meets at least one of two criteria: (1) the account was closed while under US jurisdiction (CountryID=219 or RegulationID IN 6,7,8), or (2) the account is active with CountryID=219 and RegulationID=8 (FinCEN+FINRA).

The table aggregates data from four distinct domains:
- **Customer demographics** (from `Dim_Customer`): full name, mailing address (country, state, city, street, building, zip), date of birth, phone, citizenship — PII-heavy
- **KYC questionnaire responses** (from `BI_DB_KYC_Questions_Answers_Row_Data`): 12 questions pivoted from row data to columns via MAX+CASE WHEN, covering experience (Q2), investment purpose (Q8), risk tolerance (Q9), income/assets (Q10/Q11/Q14), income sources (Q15), occupation (Q18), time frame (Q29), FINRA disclosure flags (Q30: shareholder, broker employee, public official, none-apply), US permanent residency (Q36), and W9 certification (Q40)
- **Apex brokerage data** (from `External_USABroker_Apex_ApexData/UserData/ApexStatus`): Apex account ID, lifecycle status (COMPLETE/RESTRICTED/REJECTED/SUSPENDED/ACTION_REQUIRED/ERROR/BACK_OFFICE), approver name, and approval date
- **Account lifecycle** (from `BI_DB_CIDFirstDates` + `Fact_SnapshotCustomer`): VL3 date, email, first closure date

The population is 99.7% FinCEN+FINRA regulation, 99.7% Open accounts. 96.7% have an Apex account. Of those with Apex, 87% are COMPLETE, 8% RESTRICTED, 1.7% REJECTED. FINRA disclosure: 0.2% shareholders, 0.2% broker employees, 0.08% public officials.

The ETL runs daily as a full reload (TRUNCATE+INSERT) in Service Broker process `SB_Daily` at Priority 0. Step 1 identifies closed US/VL3 accounts via `Fact_SnapshotCustomer` (AccountStatusID=2). Step 2 pulls Apex data from 3 external tables (USABroker). Step 3 pivots KYC answers for 12 questions. Step 4 assembles the final table from `Dim_Customer` joined with all intermediate results.

---

## 2. Business Logic

### 2.1 Population Filter

**What**: Identifies the eligible customer population for US compliance monitoring.
**Columns Involved**: `CID`, `VerificationLevelID`, `CloseDate`, `Regulation`, `AccountStatusName`
**Rules**:
- Customer must have `IsValidCustomer=1` AND `VerificationLevelID=3` in Dim_Customer
- Must satisfy at least one condition: (a) account was ever closed under US jurisdiction (CountryID=219 OR RegulationID IN (6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA)), OR (b) currently CountryID=219 AND RegulationID=8
- Closed accounts have their earliest closure date captured via `Fact_SnapshotCustomer` (MIN of FromDateID where AccountStatusID=2)

### 2.2 KYC Questionnaire Pivot

**What**: Transforms row-per-answer KYC data into one-row-per-customer columnar format.
**Columns Involved**: `Q2_Experience` through `Q40_W9_Certification`
**Rules**:
- Source is `BI_DB_KYC_Questions_Answers_Row_Data` — each row has one GCID+QuestionId+AnswerText/AnswerId
- Pivot uses `MAX(CASE WHEN QuestionId = N THEN AnswerText END)` grouped by GCID — takes the latest answer if multiple exist
- Text questions (Q2, Q8, Q9, Q10, Q11, Q14, Q15, Q18, Q29, Q36, Q40): NULL defaults to 'N/A' via ISNULL
- FINRA Q30 (multi-select): decoded from AnswerId to individual bit flags — 93=Shareholder, 94=Broker Employee, 95=Public Official, 96=None Apply

### 2.3 Apex Brokerage Integration

**What**: Links eToro customers to their Apex Clearing brokerage accounts.
**Columns Involved**: `ApexID`, `ApexStatus`, `ApproverName`, `ApexApprovedDate`
**Rules**:
- Apex data comes from 3 external tables pointing to `USABroker` production database
- `ApexData` provides the account ID and status; `UserData` provides CID mapping and approval info; `Dictionary.ApexStatus` provides status name
- LEFT JOIN — not all customers have Apex accounts (3.3% NULL)
- ApexStatus values: COMPLETE (87%), RESTRICTED (8%), NULL (3.3%), REJECTED (1.7%), SUSPENDED (0.2%), ACTION_REQUIRED, ERROR, BACK_OFFICE

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — no distribution key or clustered index. Full table scan for all queries. Table is 403K rows so performance is acceptable for any query pattern.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All clients with a specific Apex status | `WHERE ApexStatus = 'RESTRICTED'` |
| KYC questionnaire analysis for FINRA | `WHERE Q30_Is_Shareholder = 1 OR Q30_Is_Employed_By_Broker = 1 OR Q30_Is_Public_Official = 1` |
| Closed US accounts by state | `WHERE CloseDate IS NOT NULL GROUP BY Address_State` |
| Accounts pending W9 certification | `WHERE Q40_W9_Certification IS NULL OR Q40_W9_Certification = 'N/A'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks | CID = CID | Add stock/crypto balance and equity data for depositors |
| DWH_dbo.Dim_Customer | CID = RealCID | Additional customer attributes not in this table |
| BI_DB_dbo.BI_DB_CIDFirstDates | CID = CID | Additional first-date milestones |

### 3.4 Gotchas

- **PII table**: Contains full name, address, DOB, phone, email — handle with care per data classification policies
- **CloseDate is NULL for open accounts**: Only populated for accounts that were ever closed (1,313 out of 403K)
- **Q columns default to NULL or 'N/A'**: ISNULL converts NULL AnswerText to 'N/A', but if the customer never answered the question at all, the entire KYC temp row is NULL → final value is NULL (not 'N/A')
- **ApexID/ApexStatus NULL**: 3.3% of customers lack Apex accounts — LEFT JOIN from #apexdata
- **FullName is CONCAT**: FirstName + ' ' + LastName, may have extra spaces if either is empty
- **Regulation vs DesignatedRegulation**: Regulation is the current governing entity; DesignatedRegulation is the secondary/override jurisdiction — they differ for dual-regulated accounts

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki — description copied verbatim |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge — limited confidence |
| Tier 5 | Standard ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 2 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Sourced from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 3 | FullName | nvarchar(101) | YES | Customer full name assembled from FirstName + ' ' + LastName. Both components are legal names in Unicode (nvarchar supports non-Latin scripts). (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 4 | Address_Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country via CountryID. (Tier 1 — Dictionary.Country) |
| 5 | Address_State | varchar(100) | YES | Full human-readable geographic name of the region — state, province, or territory. Examples: "California", "New York", "Ontario". Passthrough from Dim_State_and_Province via RegionID+CountryID. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 6 | Address_City | nvarchar(50) | YES | City in Unicode. Sourced from Dim_Customer.City. (Tier 1 — Customer.CustomerStatic) |
| 7 | Address_Street | nvarchar(100) | YES | Street address in Unicode. Sourced from Dim_Customer.Address. (Tier 1 — Customer.CustomerStatic) |
| 8 | Address_BuildingNumber | nvarchar(30) | YES | Building/apartment number. Separate from Address for structured address storage. Sourced from Dim_Customer.BuildingNumber. (Tier 1 — Customer.CustomerStatic) |
| 9 | Address_ZipCode | nvarchar(50) | YES | Postal code. Sourced from Dim_Customer.Zip. (Tier 1 — Customer.CustomerStatic) |
| 10 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. All rows have value 3 (fully verified) due to population filter. (Tier 1 — BackOffice.Customer) |
| 11 | VerificationLevel3Date | date | YES | First date customer reached verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3. Backfills levels 1 and 2 if not already set. Sourced from BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 12 | Regulation | varchar(50) | YES | Short code for the regulation. Used in analytics dashboards. Values: FinCEN+FINRA, FinCEN, eToroUS, CySEC, NFA, FINRAONLY, NYDFS+FINRA. Passthrough from Dim_Regulation via RegulationID. (Tier 1 — Dictionary.Regulation) |
| 13 | DesignatedRegulation | varchar(50) | YES | Short code for the designated/secondary regulation. Used for dual-regulated accounts. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation via DesignatedRegulationID. (Tier 1 — Dictionary.Regulation) |
| 14 | DOB | date | YES | Customer date of birth. Used in KYC age verification. Sourced from Dim_Customer.BirthDate (CAST to DATE). (Tier 1 — Customer.CustomerStatic) |
| 15 | Phone | varchar(30) | YES | Phone number from production Customer.CustomerStatic. (Tier 1 — Customer.CustomerStatic) |
| 16 | Email | varchar(500) | YES | Customer email address. PII. Sourced from BI_DB_CIDFirstDates. (Tier 1 — Customer.CustomerStatic) |
| 17 | RegisteredReal | date | YES | Account registration date. Sourced from Dim_Customer.RegisteredReal (CAST to DATE). (Tier 1 — Customer.CustomerStatic) |
| 18 | CloseDate | date | YES | First date customer's account was closed. Computed as MIN(CAST(Dim_Range.FromDateID AS DATE)) from Fact_SnapshotCustomer WHERE AccountStatusID=2. NULL for accounts that were never closed. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 19 | AccountStatusName | varchar(50) | YES | Human-readable label for the account state: 'Open', 'Closed', or 'N/A'. Sourced directly from Dictionary.AccountStatus.AccountStatusName. Passthrough from Dim_AccountStatus. (Tier 1 — Dictionary.AccountStatus) |
| 20 | Q2_Experience | varchar(200) | YES | KYC Q2: trading experience level. Pivoted from BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=2. Values: 'Never traded', 'Less than 1 Year', 'Between 1-3 Years', 'More than 3 years'. NULL/N/A if not answered. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 21 | Q8_Trading_Primary_Purpose | varchar(200) | YES | KYC Q8: primary purpose of trading. Pivoted from BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=8. Values: 'Future Planning(Save For kids education/retirement)', 'Additional revenues', 'Saving For home', 'Short term returns'. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 22 | Q9_Risk_Reward_Scenario | varchar(200) | YES | KYC Q9: preferred risk/reward ratio. Pivoted from BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=9. Values: '80% / -48%', '20% / -12%', '40% / -24%'. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 23 | Q10_Annual_Income | varchar(200) | YES | KYC Q10: annual income bracket. Pivoted from BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=10. Values: '$10K-$50K', '$50K-$200K', '$200K-$500k', '$500K-$1M', '$1M-$5M', 'Over $5M', 'Up to $10K'. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 24 | Q11_Liquid_Assets | varchar(200) | YES | KYC Q11: liquid net worth bracket. Pivoted from BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=11. Values: same bracket scale as Q10. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 25 | Q14_Planned_Invested_Amount | varchar(200) | YES | KYC Q14: planned investment amount. Pivoted from BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=14. Values: 'Up to $1k', '$1k - $5k', '$5k - $20k', '$20k - $50k', '$50k-$200k', '$200k - $500k', '$500k - $1M'. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 26 | Q15_Sources_of_Income | varchar(200) | YES | KYC Q15: main source of income. Pivoted from BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=15. Values: 'Salary', 'Savings', 'Investments', 'Social Security', etc. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 27 | Q18_Occupation | varchar(200) | YES | KYC Q18: customer occupation. Pivoted from BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=18. Values: various industry categories (Retail, Construction/Carpentry, Food and beverage, Arts/Design, Retired, etc.). (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 28 | Q29_Time_Frame_Investing | varchar(200) | YES | KYC Q29: planned investment time horizon. Pivoted from BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=29. Values: '1 Year To 3 years', 'above 3 years'. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 29 | Q30_Is_Shareholder | bit | YES | FINRA disclosure Q30: whether customer is a 10%+ shareholder of a publicly traded company. 1 if AnswerId=93 for QuestionId=30, else 0. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 30 | Q30_Is_Employed_By_Broker | bit | YES | FINRA disclosure Q30: whether customer is employed by a registered broker-dealer. 1 if AnswerId=94 for QuestionId=30, else 0. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 31 | Q30_Is_Public_Official | bit | YES | FINRA disclosure Q30: whether customer is a public official (PEP). 1 if AnswerId=95 for QuestionId=30, else 0. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 32 | Q30_Is_None_Apply_To_me | bit | YES | FINRA disclosure Q30: customer confirmed none of the FINRA disclosure categories apply. 1 if AnswerId=96 for QuestionId=30, else 0. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 33 | Q36_US_Permanent_Resident | varchar(200) | YES | KYC Q36: US permanent residency status. Pivoted from BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=36. Values: 'Yes', 'No'. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 34 | Q40_W9_Certification | varchar(200) | YES | KYC Q40: W9 tax certification status. Pivoted from BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=40. Values: 'W9 Document created'. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 35 | ApexID | varchar(8) | YES | The unique account identifier assigned by Apex Clearing. Format: "3" prefix + alphanumeric sequence (e.g., "3FN28343"). Maximum 8 characters. Immutably bound to one GCID. NULL if customer has no Apex account. Passthrough from External_USABroker_Apex_ApexData. (Tier 1 — USABroker.Apex.ApexData) |
| 36 | ApexStatus | varchar(128) | YES | High-level lifecycle status of the Apex brokerage account. Values: COMPLETE, RESTRICTED, REJECTED, SUSPENDED, ACTION_REQUIRED, ERROR, BACK_OFFICE. NULL if customer has no Apex account. Passthrough from External_USABroker_Dictionary_ApexStatus.Name via StatusID. (Tier 1 — USABroker.Dictionary.ApexStatus) |
| 37 | ApproverName | varchar(128) | YES | Name of the compliance officer who manually approved this Apex account. NULL for auto-approved accounts or customers without Apex. Passthrough from External_USABroker_Apex_UserData. (Tier 1 — USABroker.Apex.UserData) |
| 38 | ApexApprovedDate | date | YES | Date of manual Apex account approval. NULL for auto-approved accounts or customers without Apex. Sourced from External_USABroker_Apex_UserData.ApprovedByDate. (Tier 1 — USABroker.Apex.UserData) |
| 39 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |
| 40 | Citizenship | varchar(250) | YES | Full country name in English for the customer's country of citizenship (may differ from Address_Country/residence). Passthrough from Dim_Country via CitizenshipCountryID. (Tier 1 — Dictionary.Country) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-----------------|---------------|-----------|
| GCID | Customer.CustomerStatic | GCID | Passthrough via Dim_Customer |
| CID | Customer.CustomerStatic | CID (as RealCID) | Rename via Dim_Customer |
| FullName | Customer.CustomerStatic | FirstName, LastName | CONCAT via SP |
| Address_Country | Dictionary.Country | Name | Dim-lookup via CountryID |
| Address_State | Dictionary.RegionByIP/RegionName | Name | Dim-lookup via RegionID |
| Address_City | Customer.CustomerStatic | City | Rename via Dim_Customer |
| Address_Street | Customer.CustomerStatic | Address | Rename via Dim_Customer |
| Address_BuildingNumber | Customer.CustomerStatic | BuildingNumber | Rename via Dim_Customer |
| Address_ZipCode | Customer.CustomerStatic | Zip | Rename via Dim_Customer |
| VerificationLevelID | BackOffice.Customer | VerificationLevelID | Passthrough via Dim_Customer |
| VerificationLevel3Date | Fact_SnapshotCustomer | MIN(FromDateID) | Computed in SP_CIDFirstDates |
| Regulation | Dictionary.Regulation | Name | Dim-lookup via RegulationID |
| DesignatedRegulation | Dictionary.Regulation | Name | Dim-lookup via DesignatedRegulationID |
| DOB | Customer.CustomerStatic | BirthDate | Rename + CAST |
| Phone | Customer.CustomerStatic | Phone | Passthrough |
| Email | Customer.CustomerStatic | Email | Via BI_DB_CIDFirstDates |
| RegisteredReal | Customer.CustomerStatic | RegisteredReal | CAST to DATE |
| CloseDate | Fact_SnapshotCustomer + Dim_Range | FromDateID | MIN aggregation |
| AccountStatusName | Dictionary.AccountStatus | AccountStatusName | Dim-lookup |
| Q2-Q40 columns | UserApiDB KYC | AnswerText/AnswerId | Pivot via BI_DB_KYC_Questions_Answers_Row_Data |
| ApexID | USABroker.Apex.ApexData | ApexID | Passthrough via External table |
| ApexStatus | USABroker.Dictionary.ApexStatus | Name | Dim-lookup via External table |
| ApproverName | USABroker.Apex.UserData | ApproverName | Passthrough via External table |
| ApexApprovedDate | USABroker.Apex.UserData | ApprovedByDate | Rename via External table |
| Citizenship | Dictionary.Country | Name | Dim-lookup via CitizenshipCountryID |

### 5.2 ETL Pipeline

```
Production Sources:
  etoro.Customer.CustomerStatic (customer demographics)
  etoro.BackOffice.Customer (verification, regulation)
  etoro.Dictionary.Country/Regulation/AccountStatus (lookups)
  USABroker.Apex.ApexData/UserData (Apex brokerage)
  USABroker.Dictionary.ApexStatus (Apex status)
  UserApiDB.KYC (questionnaire answers)
    |-- Generic Pipeline (Bronze export) ---|
    v
  DWH_staging.* (staging tables)
    |-- SP_Dim_Customer / SP_Dictionaries / etc. ---|
    v
  DWH_dbo.Dim_Customer + Dim_Country + Dim_Regulation + Dim_AccountStatus + Dim_State_and_Province
  BI_DB_dbo.BI_DB_CIDFirstDates + BI_DB_KYC_Questions_Answers_Row_Data
  BI_DB_dbo.External_USABroker_Apex_* (direct external tables)
    |-- SP_US_Compliance_Apex_Clients (TRUNCATE+INSERT, daily) ---|
    v
  BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients (403K rows)
    |-- Generic Pipeline (Override, delta) ---|
    v
  dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_us_compliance_apex_clients
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Primary customer dimension |
| GCID | DWH_dbo.Dim_Customer.GCID | Group customer ID |
| VerificationLevelID | DWH_dbo.Dim_VerificationLevel | KYC verification level lookup |
| Regulation | DWH_dbo.Dim_Regulation.Name | Regulatory entity |
| AccountStatusName | DWH_dbo.Dim_AccountStatus.AccountStatusName | Account status |
| ApexID | USABroker.Apex.ApexData.ApexID | Apex brokerage account |

### 6.2 Referenced By (other objects point to this)

| Object | Join Key | Purpose |
|--------|----------|---------|
| BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks | CID | Companion table with stock/crypto balances for US depositors |

---

## 7. Sample Queries

### 7.1 US Compliance Overview by State

```sql
SELECT Address_State,
       COUNT(*) AS total_clients,
       SUM(CASE WHEN ApexStatus = 'COMPLETE' THEN 1 ELSE 0 END) AS apex_complete,
       SUM(CASE WHEN ApexStatus = 'RESTRICTED' THEN 1 ELSE 0 END) AS apex_restricted,
       SUM(CASE WHEN CloseDate IS NOT NULL THEN 1 ELSE 0 END) AS closed_accounts
FROM [BI_DB_dbo].[BI_DB_US_Compliance_Apex_Clients]
WHERE Address_Country = 'United States'
GROUP BY Address_State
ORDER BY total_clients DESC
```

### 7.2 FINRA Disclosure Flag Analysis

```sql
SELECT SUM(CAST(Q30_Is_Shareholder AS int)) AS shareholders,
       SUM(CAST(Q30_Is_Employed_By_Broker AS int)) AS broker_employees,
       SUM(CAST(Q30_Is_Public_Official AS int)) AS public_officials,
       SUM(CAST(Q30_Is_None_Apply_To_me AS int)) AS none_apply,
       COUNT(*) AS total
FROM [BI_DB_dbo].[BI_DB_US_Compliance_Apex_Clients]
WHERE ApexStatus = 'COMPLETE'
```

### 7.3 Clients with Balances (Join with Crypto_Stocks)

```sql
SELECT c.CID, c.FullName, c.ApexStatus, cs.StocksBalance, cs.CryptoBalance, cs.RealizedEquity
FROM [BI_DB_dbo].[BI_DB_US_Compliance_Apex_Clients] c
INNER JOIN [BI_DB_dbo].[BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks] cs ON c.CID = cs.CID
WHERE cs.StocksBalance > 0 OR cs.CryptoBalance > 0
ORDER BY cs.RealizedEquity DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-27 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 20 T1, 19 T2, 0 T3, 0 T4, 1 T5 | Elements: 40/40, Logic: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients | Type: Table | Production Source: Multi-source (Dim_Customer + USABroker + KYC)*
