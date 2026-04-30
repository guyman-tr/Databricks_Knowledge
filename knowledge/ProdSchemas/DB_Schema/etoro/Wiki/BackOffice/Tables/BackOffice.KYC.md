# BackOffice.KYC

> US and regulated-entity KYC (Know Your Customer) questionnaire responses for customers, capturing financial profile, trading experience, regulatory disclosures, and document data required by NFA/CFTC and other regulators.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CID (BIGINT, CLUSTERED PK - one row per customer) |
| **Partition** | No |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.KYC stores the detailed Know Your Customer (KYC) regulatory questionnaire responses for customers who must complete enhanced due diligence under US (NFA/CFTC) and other regulated entity requirements. Each row represents the complete KYC profile for one customer, with a one-row-per-customer design enforced by the clustered primary key on CID.

The questionnaire covers three compliance domains: (1) financial suitability assessment (income, net worth, liquid assets, investment experience, trading experience across FX/commodities/indices/equities); (2) US regulatory disclosures (Social Security Number, citizenship, permanent US residency, driver's license, employer information, bankruptcy history, counterparty relationships); and (3) agreement confirmations (client agreement, risk disclosures, electronic signature, CFTC-required disclosures). The Citizenship and MailingAddress columns carry dynamic data masking (default()) for privacy protection.

BackOffice.AddKYC implements an upsert pattern (INSERT if no record exists, UPDATE if it does). The KycAddILQ procedure handles the ILQ regulatory variant. The table is empty in the current database environment (0 rows) - this schema serves a US-regulated eToro entity or a specific regulatory jurisdiction that maintains its data separately.

---

## 2. Business Logic

### 2.1 Suitability Assessment Fields

**What**: The regulatory suitability questionnaire captures a customer's financial profile and trading experience to assess whether they are suitable for retail forex/derivatives trading.

**Columns Involved**: `Income`, `NetWorth`, `LiquidAssets`, `AnnualInvest`, `PlanningToInvest`, `TradingExperience`, `InvestExperience`, `WorkExperience`, `CurrenciesPeriod`, `CurrenciesAmount`, `CommodityPeriod`, `CommodityAmount`, `IndicesPeriod`, `IndicesAmount`, `OtherInstrumentsPeriod`, `OtherInstrumentsAmount`

**Rules**:
- All suitability fields are stored as free-text strings (nvarchar) matching the questionnaire's radio-button/dropdown options (e.g., Income = "Under $25,000", "25,000-50,000", etc.)
- Period/Amount pairs capture trading frequency and volume per asset class: CurrenciesPeriod + CurrenciesAmount = forex trading history
- TradingExperience, InvestExperience, WorkExperience capture years/level in respective domains
- InvestRisk captures the customer's stated risk tolerance

### 2.2 US Regulatory Disclosure Confirmations

**What**: Boolean flags capturing the customer's acknowledgment of required CFTC/NFA disclosures.

**Columns Involved**: `ClientAgreement`, `RiskDisclosure`, `AdditionalRiskDisclosure`, `CounterpartyRiskDisclosure`, `HighRiskInvestment`, `ElectronicSignatureAndRecords`, `ConfirmIdentity`, `IsRiskDesclaimed`, `SlippageExecutionPolicy`

**Rules**:
- Each confirmation flag is NULL until the customer completes that specific step, then set to 1 (true)
- IsRiskDesclaimed (NOT NULL, DEFAULT 0) and SlippageExecutionPolicy (NOT NULL, DEFAULT 0) are the only flags with NOT NULL constraint - they are mandatory for all records
- The Signature column stores the customer's typed electronic signature name alongside the ConfirmIdentity flag
- AddKYC only sets IsRiskDesclaimed and leaves other disclosure flags unset - a separate process likely handles the full disclosure confirmations

### 2.3 Counterparty and Relationship Disclosures

**What**: Three sets of bit+explain fields capture required conflict-of-interest disclosures that regulators require customers to self-disclose.

**Columns Involved**: `HasFamilyRelationWithPersonAssociatedWithUs`, `IsRelatedToRetailForexCounterParty`, `IsCommodityPoolOrInvestmentVehicleOrIntermediary`, `OtherPersonHasFinancialInterest` (+ corresponding Explain fields)

**Rules**:
- Each disclosure is a bit (yes/no) paired with a text explanation field (nvarchar(256))
- True (1) triggers the corresponding Explain field to be required
- These disclosures are NFA Rule 2-36 and CFTC Regulation 5.18 compliance requirements

---

## 3. Data Overview

This table is empty (0 rows) in the current database environment. It is populated in the US-regulated eToro entity database. The schema represents:

| Column Group | Examples | Regulatory Basis |
|---|---|---|
| Financial suitability | Income, NetWorth, TradingExperience | NFA/CFTC suitability requirements |
| Identity verification | SocialSecurityNumber, DriversLicenseOrStateIdCard, Citizenship (masked) | US AML/BSA requirements |
| Conflict disclosures | HasFamilyRelationWithPersonAssociatedWithUs | NFA Rule 2-36 |
| Agreement confirmations | ClientAgreement, RiskDisclosure, SlippageExecutionPolicy | CFTC Rule 5.18 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | bigint | NO | - | VERIFIED | Customer ID. PK (one row per customer). Links to Customer.CustomerStatic. Stored as bigint (vs int in other tables) - may reflect a different customer ID space for the US entity. |
| 2 | ManagerID | bigint | YES | - | CODE-BACKED | BackOffice manager who last updated this record. NULL for customer self-submitted forms. FK to BackOffice.Manager (no constraint). |
| 3 | JobTitle | nvarchar(200) | YES | - | CODE-BACKED | Customer's job title / occupation, as entered in the KYC questionnaire. Part of the employment section of the suitability assessment. |
| 4 | Gender | nvarchar(50) | YES | - | CODE-BACKED | Customer's self-identified gender. Collected as part of the US regulatory profile. |
| 5 | Income | nvarchar(200) | YES | - | CODE-BACKED | Annual income range selected by the customer (e.g., "Under $25,000", "$25,000-$50,000"). Free-text string matching questionnaire dropdown options. Used in suitability determination. |
| 6 | PlanningToInvest | nvarchar(200) | YES | - | CODE-BACKED | Amount the customer plans to invest/deposit. Questionnaire range selection (e.g., "Under $1,000", "$1,000-$5,000"). Part of suitability assessment. |
| 7 | BusinessRelationship | nvarchar(200) | YES | - | NAME-INFERRED | Nature of the business relationship the customer has with eToro. Exact values not determinable from empty table. |
| 8 | PositionLevel | nvarchar(300) | YES | - | NAME-INFERRED | Customer's seniority/position level in their organization. Part of employment section. |
| 9 | CurrenciesPeriod | nvarchar(200) | YES | - | CODE-BACKED | How frequently the customer has traded currencies (e.g., "Rarely", "Monthly", "Weekly"). Part of FX trading experience assessment. |
| 10 | CurrenciesAmount | nvarchar(200) | YES | - | CODE-BACKED | Volume of past currency trades (e.g., "Under $5,000", "$5,000-$25,000"). Paired with CurrenciesPeriod for FX experience rating. |
| 11 | CommodityPeriod | nvarchar(200) | YES | - | CODE-BACKED | Frequency of past commodity trading. Paired with CommodityAmount for commodity experience. |
| 12 | CommodityAmount | nvarchar(200) | YES | - | CODE-BACKED | Volume of past commodity trades. |
| 13 | IndicesPeriod | nvarchar(200) | YES | - | CODE-BACKED | Frequency of past indices/ETF trading. |
| 14 | IndicesAmount | nvarchar(200) | YES | - | CODE-BACKED | Volume of past indices trades. |
| 15 | OtherInstrumentsPeriod | nvarchar(200) | YES | - | CODE-BACKED | Frequency of trading in other instruments not covered above. |
| 16 | OtherInstrumentsAmount | nvarchar(200) | YES | - | CODE-BACKED | Volume of other instrument trades. |
| 17 | TradingTools | nvarchar(200) | YES | - | NAME-INFERRED | Trading tools/platforms the customer has used previously. |
| 18 | UpdateDate | datetime | NO | - | VERIFIED | Timestamp of last INSERT or UPDATE via AddKYC procedure. Always set by the application on every write. |
| 19 | HasFiledBankruptcy | bit | YES | - | CODE-BACKED | Whether the customer has filed for bankruptcy. US credit/financial background disclosure. Paired with BankruptcyDischargeDate. |
| 20 | BankruptcyDischargeDate | datetime | YES | - | CODE-BACKED | Date bankruptcy was discharged, if applicable. Populated when HasFiledBankruptcy=1. |
| 21 | Title | nvarchar(5) | YES | - | CODE-BACKED | Honorific title (Mr., Mrs., Ms., Dr., etc.). |
| 22 | Citizenship | nvarchar(50) | YES | - | VERIFIED | Customer's citizenship/nationality. Masked with dynamic data masking (default() function) - hidden from non-privileged queries. US AML requirement for non-US-citizen customers. |
| 23 | SocialSecurityNumber | nvarchar(9) | YES | - | VERIFIED | US Social Security Number (9 digits, no dashes stored). US AML/BSA identity verification requirement. Highly sensitive PII. |
| 24 | MailingAddress | nvarchar(50) | YES | - | VERIFIED | Customer's mailing address for US regulatory correspondence. Masked with dynamic data masking (default() function). |
| 25 | PermanentUsResident | bit | YES | - | CODE-BACKED | Whether the customer is a permanent US resident (green card holder). Affects regulatory disclosure requirements. |
| 26 | DriversLicenseOrStateIdCard | nvarchar(20) | YES | - | CODE-BACKED | US driver's license or state ID card number. Alternative identity document for customers without passport. |
| 27 | IssuingState | nvarchar(50) | YES | - | CODE-BACKED | US state that issued the driver's license or state ID. Required with DriversLicenseOrStateIdCard. |
| 28 | EmploymentStatus | nvarchar(25) | YES | - | CODE-BACKED | Customer's employment status (e.g., "Employed", "Self-Employed", "Retired", "Student", "Unemployed"). |
| 29 | EmployerName | nvarchar(50) | YES | - | CODE-BACKED | Name of the customer's employer. Populated when EmploymentStatus = "Employed". |
| 30 | BusinessType | nvarchar(60) | YES | - | CODE-BACKED | Type of business/industry of the employer. Supports AML source-of-funds assessment. |
| 31 | SourceOfFunds | nvarchar(256) | YES | - | CODE-BACKED | Declared primary source of funds for trading (e.g., "Salary", "Savings", "Business Income", "Investment Returns"). AML/BSA requirement. |
| 32 | SourceOfFundsExplain | nvarchar(256) | YES | - | CODE-BACKED | Free-text explanation of source of funds when the selection requires elaboration. Paired with SourceOfFunds. |
| 33 | NetWorth | nvarchar(30) | YES | - | CODE-BACKED | Customer's total net worth range. Part of financial suitability assessment. |
| 34 | LiquidAssets | nvarchar(30) | YES | - | CODE-BACKED | Customer's liquid assets range (cash and easily liquidated investments). Suitability assessment component. |
| 35 | HasFileForBankruptcy | bit | YES | - | CODE-BACKED | Duplicate of HasFiledBankruptcy (note: different spelling). May be a legacy/renamed version of the same field. |
| 36 | DischargeDate | datetime | YES | - | CODE-BACKED | Duplicate of BankruptcyDischargeDate. May be a legacy/renamed field. |
| 37 | InterbankOrOTCForeignExchange | nvarchar(30) | YES | - | CODE-BACKED | Experience with interbank or OTC foreign exchange markets. Part of prior trading experience disclosure. |
| 38 | StocksBondFuturesOptions | nvarchar(30) | YES | - | CODE-BACKED | Experience with stocks, bonds, futures, or options trading. |
| 39 | HasFamilyRelationWithPersonAssociatedWithUs | bit | YES | - | CODE-BACKED | Whether the customer has a family member associated with eToro. NFA Rule 2-36 conflict disclosure. |
| 40 | HasFamilyRelationWithPersonAssociatedWithUsExplain | nvarchar(256) | YES | - | CODE-BACKED | Explanation when HasFamilyRelationWithPersonAssociatedWithUs=1. |
| 41 | IsRelatedToRetailForexCounterParty | bit | YES | - | CODE-BACKED | Whether the customer is related to a retail forex dealer/counterparty. NFA regulatory disclosure. |
| 42 | IsRelatedToRetailForexCounterPartyExplain | nvarchar(256) | YES | - | CODE-BACKED | Explanation when IsRelatedToRetailForexCounterParty=1. |
| 43 | IsCommodityPoolOrInvestmentVehicleOrIntermediary | bit | YES | - | CODE-BACKED | Whether the account is a commodity pool, investment vehicle, or intermediary. CFTC disclosure requirement. |
| 44 | IsCommodityPoolOrInvestmentVehicleOrIntermediaryExplain | nvarchar(256) | YES | - | CODE-BACKED | Explanation when IsCommodityPoolOrInvestmentVehicleOrIntermediary=1. |
| 45 | OtherPersonHasFinancialInterest | bit | YES | - | CODE-BACKED | Whether a third party has financial interest in or control over the account. AML beneficial ownership disclosure. |
| 46 | OtherPersonHasFinancialInterestExplain | nvarchar(256) | YES | - | CODE-BACKED | Identity and relationship of the third party with financial interest. |
| 47 | ClientAgreement | bit | YES | - | CODE-BACKED | Confirms the customer has read and agreed to the eToro client agreement. NULL until step is completed; 1=agreed. |
| 48 | RiskDisclosure | bit | YES | - | CODE-BACKED | Confirms acknowledgment of the standard risk disclosure document. CFTC-required disclosure. |
| 49 | AdditionalRiskDisclosure | bit | YES | - | CODE-BACKED | Confirms acknowledgment of additional/supplemental risk disclosures. |
| 50 | CounterpartyRiskDisclosure | bit | YES | - | CODE-BACKED | Confirms acknowledgment of counterparty risk (eToro as the dealing counterparty). |
| 51 | HighRiskInvestment | bit | YES | - | CODE-BACKED | Confirms acknowledgment that retail forex is a high-risk investment. |
| 52 | ElectronicSignatureAndRecords | bit | YES | - | CODE-BACKED | Confirms consent to use of electronic signatures and record-keeping. E-Sign Act requirement. |
| 53 | ConfirmIdentity | bit | YES | - | CODE-BACKED | Confirms the customer has verified their identity information is accurate. |
| 54 | Signature | nvarchar(50) | YES | - | CODE-BACKED | Customer's typed electronic signature (their full name as entered). Associated with ConfirmIdentity. |
| 55 | AnnualInvest | nvarchar(200) | YES | - | CODE-BACKED | Annual investment amount the customer plans to make. |
| 56 | Purpose | nvarchar(200) | YES | - | CODE-BACKED | Stated investment purpose (e.g., "Speculation", "Hedging", "Long-term investment"). |
| 57 | WorkExperience | nvarchar(200) | YES | - | CODE-BACKED | Years or level of general work/professional experience. |
| 58 | TradingExperience | nvarchar(200) | YES | - | CODE-BACKED | Years or level of trading experience across financial instruments. |
| 59 | InvestExperience | nvarchar(200) | YES | - | CODE-BACKED | Level of investment experience (e.g., "None", "Limited", "Good", "Extensive"). |
| 60 | InvestRisk | nvarchar(200) | YES | - | CODE-BACKED | Customer's stated risk tolerance for investments. |
| 61 | InfoClear | nvarchar(200) | YES | - | CODE-BACKED | Confirms the information provided is clear and complete. |
| 62 | IsRiskDesclaimed | bit | NO | (0) | VERIFIED | Mandatory flag confirming the customer has disclaimed/acknowledged the risk of trading. NOT NULL with DEFAULT 0. Set by AddKYC as a required parameter. 0=not yet disclaimed. 1=risk disclaimer accepted. |
| 63 | SlippageExecutionPolicy | bit | NO | (0) | VERIFIED | Mandatory flag confirming customer acceptance of the slippage and execution policy (how orders may execute at different prices in fast markets). NOT NULL with DEFAULT 0. Required CFTC/NFA disclosure for retail forex. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Links KYC profile to the customer account |
| ManagerID | BackOffice.Manager | Implicit FK | BackOffice agent who last updated the record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.AddKYC | CID | WRITER / MODIFIER | Upserts KYC record for a customer |
| BackOffice.KycAddILQ | CID | WRITER / MODIFIER | ILQ regulatory variant upsert |
| BackOffice.KycIlqGetByCid | CID | READER | Retrieves KYC/ILQ record by customer ID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.KYC (table)
- No FK constraints; CID + ManagerID are implicit references
```

### 6.1 Objects This Depends On

No dependencies (no FK constraints declared).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AddKYC | Procedure | WRITER/MODIFIER - upserts full KYC record |
| BackOffice.KycAddILQ | Procedure | WRITER/MODIFIER - ILQ regulatory variant |
| BackOffice.KycIlqGetByCid | Procedure | READER - retrieves record by CID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYC | CLUSTERED PK | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed) | DEFAULT | IsRiskDesclaimed = 0 |
| (unnamed) | DEFAULT | SlippageExecutionPolicy = 0 |
| Dynamic Data Masking | MASKING | Citizenship: default() - hidden from non-privileged users |
| Dynamic Data Masking | MASKING | MailingAddress: default() - hidden from non-privileged users |

---

## 8. Sample Queries

### 8.1 Get customers who have completed the core KYC disclosures
```sql
SELECT
    CID,
    EmploymentStatus,
    Income,
    NetWorth,
    IsRiskDesclaimed,
    SlippageExecutionPolicy,
    ClientAgreement,
    UpdateDate
FROM BackOffice.KYC WITH (NOLOCK)
WHERE IsRiskDesclaimed = 1
  AND SlippageExecutionPolicy = 1
ORDER BY UpdateDate DESC
```

### 8.2 Get customers with pending bankruptcy disclosures
```sql
SELECT
    CID,
    HasFiledBankruptcy,
    BankruptcyDischargeDate,
    EmploymentStatus,
    UpdateDate
FROM BackOffice.KYC WITH (NOLOCK)
WHERE HasFiledBankruptcy = 1
ORDER BY UpdateDate DESC
```

### 8.3 Get customers with third-party financial interest disclosures
```sql
SELECT
    CID,
    OtherPersonHasFinancialInterest,
    OtherPersonHasFinancialInterestExplain,
    IsRelatedToRetailForexCounterParty,
    IsRelatedToRetailForexCounterPartyExplain,
    UpdateDate
FROM BackOffice.KYC WITH (NOLOCK)
WHERE OtherPersonHasFinancialInterest = 1
   OR IsRelatedToRetailForexCounterParty = 1
ORDER BY UpdateDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8.6/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 45 CODE-BACKED, 0 ATLASSIAN-ONLY, 14 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Note: Table empty (0 rows) in current environment - this schema serves a US-regulated or specific-jurisdiction eToro entity.*
*Object: BackOffice.KYC | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.KYC.sql*
