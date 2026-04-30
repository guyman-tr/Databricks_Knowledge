# apex.EXT1034_NewAccountFinancialInformation

> KYC/AML data from Apex Clearing EXT1034 extract: income, net worth, investment experience, risk tolerance, and employment per account.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily Know Your Customer (KYC) and Anti-Money Laundering (AML) data from Apex Clearing's EXT1034 extract. Each row represents an account's financial profile as collected during account opening or subsequent updates, including annual income, net worth, liquid net worth, investment experience, investment objectives, risk tolerance, liquidity needs, and time horizon. It also includes employment information and affiliated/control person disclosures.

The EXT1034 data supports regulatory compliance with FINRA Rule 2111 (Suitability) and SEC Regulation Best Interest. It provides the customer's self-reported financial profile that determines what investments are suitable for the account. This data must be kept current and is subject to audit by FINRA and the SEC.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT1034 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Suitability Profile

**What**: Multiple fields combine to form the customer's investment suitability profile.

**Columns Involved**: `AnnualIncome`, `NetWorth`, `LiquidNetWorth`, `InvestmentExperience`, `InvestmentObjective`, `RiskTolerance`, `LiquidityNeeds`, `TimeHorizon`

**Rules**:
- These fields together determine what investment products and strategies are suitable for the customer
- InvestmentObjective ranges from income/preservation to speculation
- RiskTolerance indicates the customer's comfort with potential losses
- TimeHorizon affects suitable investment types (short-term vs long-term)

### 2.2 Affiliated/Control Person Disclosures

**What**: Regulatory disclosures for industry-affiliated or company control persons.

**Columns Involved**: `AffiliatedPerson`, `AffiliatedPersonDetail`, `AffiliatedApprovalSnapIDs`, `ControlPerson`, `ControlPersonCompany`

**Rules**:
- AffiliatedPerson indicates if the account holder is affiliated with a broker-dealer
- ControlPerson indicates if the holder is a control person (10%+ owner, officer, director) of a public company
- These require additional compliance monitoring and pre-approval for certain trades

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT1034 file import. CASCADE DELETE. |
| 3 | Correspondent | varchar(59) | YES | - | CODE-BACKED | Correspondent firm identifier/name. |
| 4 | Branch | varchar(7) | YES | - | CODE-BACKED | Branch/office code. |
| 5 | RepCode | varchar(7) | YES | - | CODE-BACKED | Registered representative code. |
| 6 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 7 | TaxIDNumber | nvarchar(max) | YES | - | CODE-BACKED | Federal tax identification number (SSN or EIN). MASKED (PII). |
| 8 | CustomerCode | int | YES | - | NAME-INFERRED | Apex customer classification code. |
| 9 | CodeDescription | varchar(255) | YES | - | CODE-BACKED | Description of the customer code. |
| 10 | AccountType | varchar(8) | YES | - | CODE-BACKED | Account type classification. |
| 11 | OpenDate | datetime | YES | - | CODE-BACKED | Date the account was opened. |
| 12 | DateOfBirth | datetime | YES | - | CODE-BACKED | Account holder's date of birth. MASKED (PII). |
| 13 | AccountName1 | varchar(35) | YES | - | CODE-BACKED | Account holder name. MASKED (PII). |
| 14 | AddressLine1 | varchar(35) | YES | - | CODE-BACKED | Primary address line. MASKED (PII). |
| 15 | AddressLine2 | varchar(35) | YES | - | CODE-BACKED | Secondary address line. MASKED (PII). |
| 16 | City | varchar(30) | YES | - | CODE-BACKED | City. MASKED (PII). |
| 17 | State | varchar(2) | YES | - | CODE-BACKED | State code. |
| 18 | ZipCode | varchar(5) | YES | - | CODE-BACKED | ZIP code. MASKED (PII). |
| 19 | LegalAddressindicator | varchar(3) | YES | - | NAME-INFERRED | Indicator for whether the address is the legal/mailing address. |
| 20 | CountryCode | varchar(2) | YES | - | CODE-BACKED | Country code for the address. |
| 21 | EmailAddress | varchar(50) | YES | - | CODE-BACKED | Email address. MASKED (PII). |
| 22 | AnnualIncome | varchar(21) | YES | - | CODE-BACKED | Self-reported annual income range or amount (stored as string). |
| 23 | NetWorth | varchar(23) | YES | - | CODE-BACKED | Self-reported total net worth range or amount (stored as string). |
| 24 | LiquidNetWorth | varchar(23) | YES | - | CODE-BACKED | Self-reported liquid net worth range or amount (stored as string). |
| 25 | InvestmentExperience | varchar(9) | YES | - | CODE-BACKED | Level of investment experience (none, limited, good, extensive). |
| 26 | InvestmentObjective | varchar(20) | YES | - | CODE-BACKED | Primary investment objective (income, growth, speculation, etc.). |
| 27 | RiskTolerance | varchar(6) | YES | - | CODE-BACKED | Risk tolerance level (low, medium, high). |
| 28 | LiquidityNeeds | varchar(18) | YES | - | CODE-BACKED | Liquidity needs (very important, somewhat important, not important). |
| 29 | TimeHorizon | varchar(7) | YES | - | CODE-BACKED | Investment time horizon (short, medium, long). |
| 30 | AffiliatedPerson | varchar(100) | YES | - | CODE-BACKED | Affiliated person disclosure (broker-dealer affiliation). |
| 31 | AffiliatedPersonDetail | varchar(61) | YES | - | CODE-BACKED | Details about the affiliated person relationship. |
| 32 | AffiliatedApprovalSnapIDs | uniqueidentifier | YES | - | NAME-INFERRED | Reference ID for affiliated person approval snapshots. |
| 33 | ControlPerson | varchar(100) | YES | - | CODE-BACKED | Control person disclosure (officer, director, 10%+ shareholder). |
| 34 | ControlPersonCompany | varchar(20) | YES | - | CODE-BACKED | Company name for which the account holder is a control person. |
| 35 | Employer | varchar(40) | YES | - | CODE-BACKED | Account holder's employer name. |
| 36 | EmploymentStatus | varchar(10) | YES | - | CODE-BACKED | Employment status (employed, self-employed, retired, student, etc.). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT1034_NewAccountFinancialInformation (table)
  └── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT1034_NewAccountFinancialInformation | CLUSTERED PK | Id | - | - | Active |
| IX_EXT1034_NewAccountFinancialInformation_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT1034_NewAccountFinancialInformation | PRIMARY KEY | Unique Id per row |
| FK_EXT1034_NewAccountFinancialInformation_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get KYC profiles from the latest import

```sql
SELECT AccountNumber, AnnualIncome, NetWorth, LiquidNetWorth, InvestmentExperience,
       InvestmentObjective, RiskTolerance, TimeHorizon
FROM apex.EXT1034_NewAccountFinancialInformation WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1034 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber;
```

### 8.2 Find accounts with control person or affiliated person disclosures

```sql
SELECT AccountNumber, AccountName1, AffiliatedPerson, AffiliatedPersonDetail,
       ControlPerson, ControlPersonCompany
FROM apex.EXT1034_NewAccountFinancialInformation WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1034 AND Status = 2 ORDER BY ProcessDate DESC)
  AND (AffiliatedPerson IS NOT NULL OR ControlPerson IS NOT NULL)
ORDER BY AccountNumber;
```

### 8.3 Summarize accounts by risk tolerance and investment objective

```sql
SELECT RiskTolerance, InvestmentObjective, COUNT(*) AS AccountCount
FROM apex.EXT1034_NewAccountFinancialInformation WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1034 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY RiskTolerance, InvestmentObjective
ORDER BY AccountCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT1034_NewAccountFinancialInformation | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.sql*
