# apex.EXT765_AccountMaster

> Account master data from Apex Clearing EXT765 extract: customer accounts with addresses, tax info, IRA status, margin settings, and option levels.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (1 PK + 2 NC) |

---

## 1. Business Meaning

This table stores the daily account master snapshot from Apex Clearing's EXT765 extract. Each row represents the current state of a customer account at the clearing firm, including identifying information (account number, tax ID), address details, account configuration flags (IRA type, margin eligibility, option level), and regulatory codes. This is the most comprehensive account-level reference file provided by Apex.

The EXT765 data is critical for reconciliation operations because it provides the authoritative view of every account's configuration at Apex. It enables eToro to verify that account settings (margin, options, IRA status) match internal records and to detect changes such as address updates, restriction codes, or account closures.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT765 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Account Identification Composite

**What**: Account identity is established through multiple fields.

**Columns Involved**: `AccountNumber`, `FederalIDIndicator`, `TaxIdNumber`, `ShortName`, `AccountName`

**Rules**:
- AccountNumber is the primary Apex account identifier (masked for PII protection)
- FederalIDIndicator distinguishes SSN vs EIN (individual vs entity)
- TaxIdNumber holds the SSN or EIN (masked)
- ShortName and AccountName provide human-readable identifiers

### 2.2 Account Status and Restrictions

**What**: Multiple flags combine to determine account operational status.

**Columns Involved**: `RestrictReasonCode`, `ClosedDate`, `RestrDate`, `AccountClass`, `Margin`, `OptionCode`, `OptionLevel`

**Rules**:
- RestrictReasonCode indicates why an account may be restricted
- ClosedDate being non-NULL indicates a closed account
- AccountClass, Margin, OptionCode, and OptionLevel together define the trading capabilities

---

## 3. Data Overview

~376 million rows. The largest table in the Sodreconciliation database. Contains a full daily snapshot of all Apex account master records per import, accumulating rapidly over time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT765 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). Primary account identifier at the clearing firm. |
| 4 | OfficeCode | varchar(3) | YES | - | CODE-BACKED | Apex office/branch code associated with the account. |
| 5 | RegisteredRepCode | varchar(3) | YES | - | CODE-BACKED | Registered representative code assigned to the account. |
| 6 | FederalIDIndicator | varchar(1) | YES | - | NAME-INFERRED | Indicates the type of federal tax ID: SSN for individuals, EIN for entities. |
| 7 | TaxIdNumber | varchar(9) | YES | - | CODE-BACKED | Federal tax identification number (SSN or EIN). MASKED (PII). |
| 8 | ShortName | varchar(10) | YES | - | CODE-BACKED | Abbreviated account holder name. |
| 9 | RelatedParty | varchar(5) | YES | - | NAME-INFERRED | Code indicating related party status for regulatory reporting. |
| 10 | AccountName | varchar(40) | YES | - | CODE-BACKED | Full account holder name. MASKED (PII). |
| 11 | AddressLine1 | varchar(40) | YES | - | CODE-BACKED | Primary address line. MASKED (PII). |
| 12 | AddressLine2 | varchar(40) | YES | - | CODE-BACKED | Secondary address line. MASKED (PII). |
| 13 | AddressLine3 | varchar(40) | YES | - | CODE-BACKED | Third address line. MASKED (PII). |
| 14 | AddressLine4 | varchar(40) | YES | - | CODE-BACKED | Fourth address line. MASKED (PII). |
| 15 | City | varchar(20) | YES | - | CODE-BACKED | City of the account holder's address. MASKED (PII). |
| 16 | State | varchar(2) | YES | - | CODE-BACKED | State code of the account holder's address. |
| 17 | ZipCode | varchar(9) | YES | - | CODE-BACKED | ZIP code (5 or 9 digits). MASKED (PII). |
| 18 | IRSControl | varchar(4) | YES | - | NAME-INFERRED | IRS control code for tax reporting purposes. |
| 19 | MMSweep | varchar(1) | YES | - | NAME-INFERRED | Money market sweep enrollment flag. |
| 20 | Pay | varchar(1) | YES | - | NAME-INFERRED | Payment instruction code for the account. |
| 21 | Div | varchar(1) | YES | - | NAME-INFERRED | Dividend instruction code (reinvest, cash, etc.). |
| 22 | AccountClass | varchar(1) | YES | - | NAME-INFERRED | Account classification code (e.g., cash, margin, DVP). |
| 23 | PrintStatment | varchar(1) | YES | - | NAME-INFERRED | Statement printing preference flag. Note: column name has typo ("Statment"). |
| 24 | Discretion | varchar(30) | YES | - | NAME-INFERRED | Discretionary authority indicator or description. |
| 25 | PortfolioIndicator | varchar(1) | YES | - | NAME-INFERRED | Flag indicating portfolio margin eligibility or enrollment. |
| 26 | IRA | varchar(1) | YES | - | NAME-INFERRED | IRA account type code (Traditional, Roth, SEP, etc.). |
| 27 | CreditInterestSweep | varchar(1) | YES | - | NAME-INFERRED | Credit interest sweep program enrollment flag. |
| 28 | MoneySweep | varchar(1) | YES | - | NAME-INFERRED | Money sweep program enrollment flag. |
| 29 | OptionLevel | varchar(1) | YES | - | NAME-INFERRED | Options trading approval level (0-5 typically). |
| 30 | Exposure | smallint | YES | - | NAME-INFERRED | Account exposure level or risk rating. |
| 31 | NYTax | varchar(1) | YES | - | NAME-INFERRED | New York state tax withholding indicator. |
| 32 | StateTax | varchar(1) | YES | - | NAME-INFERRED | State tax withholding indicator. |
| 33 | IRSCode | varchar(1) | YES | - | NAME-INFERRED | IRS reporting code for the account. |
| 34 | NonObjecting | nvarchar(1) | YES | - | NAME-INFERRED | Non-Objecting Beneficial Owner (NOBO) status flag for proxy communications. |
| 35 | IRSExempt | nvarchar(1) | YES | - | NAME-INFERRED | IRS tax exemption indicator. |
| 36 | ForeignCode | varchar(1) | YES | - | NAME-INFERRED | Foreign account indicator code. |
| 37 | OptionLimit | smallint | YES | - | NAME-INFERRED | Maximum number of option contracts allowed. |
| 38 | SuppressConfirm | varchar(1) | YES | - | NAME-INFERRED | Flag to suppress trade confirmation mailings. |
| 39 | RestrictReasonCode | varchar(1) | YES | - | CODE-BACKED | Restriction reason code if the account is restricted. |
| 40 | W8 | varchar(1) | YES | - | NAME-INFERRED | W-8 form status indicator for foreign account holders. |
| 41 | Joint | varchar(1) | YES | - | NAME-INFERRED | Joint account indicator. |
| 42 | Margin | varchar(1) | YES | - | NAME-INFERRED | Margin account eligibility/status flag. |
| 43 | OptionCode | varchar(1) | YES | - | NAME-INFERRED | Option trading authorization code. |
| 44 | PowerAttorney | varchar(1) | YES | - | NAME-INFERRED | Power of attorney indicator on the account. |
| 45 | DVP | varchar(1) | YES | - | NAME-INFERRED | Delivery vs. Payment settlement indicator. |
| 46 | Sweep | varchar(1) | YES | - | NAME-INFERRED | Cash sweep program enrollment flag. |
| 47 | Instituion | varchar(5) | YES | - | NAME-INFERRED | Institution code. Note: column name has typo ("Instituion"). |
| 48 | AgentBank | varchar(5) | YES | - | NAME-INFERRED | Agent bank code for the account. |
| 49 | TelcoExtension1 | varchar(4) | YES | - | NAME-INFERRED | Primary phone extension. |
| 50 | TelcoExtension2 | varchar(4) | YES | - | NAME-INFERRED | Secondary phone extension. |
| 51 | RestrDate | datetime | YES | - | NAME-INFERRED | Date the restriction was applied to the account. |
| 52 | OpenDDate | datetime | YES | - | NAME-INFERRED | Account open date. |
| 53 | LastChangeDate | datetime | YES | - | NAME-INFERRED | Date the account record was last modified at Apex. |
| 54 | LastActivtyDate | datetime | YES | - | NAME-INFERRED | Date of last activity on the account. Note: column name has typo ("Activty"). |
| 55 | AddressIndicator | varchar(1) | YES | - | NAME-INFERRED | Address type or validation indicator. |
| 56 | TelcoCode1 | varchar(1) | YES | - | NAME-INFERRED | Primary phone type code (home, work, mobile). |
| 57 | TelcoCode2 | varchar(1) | YES | - | NAME-INFERRED | Secondary phone type code. |
| 58 | TelcoAreaCode1 | varchar(3) | YES | - | NAME-INFERRED | Primary phone area code. |
| 59 | TelcoExchange1 | varchar(3) | YES | - | NAME-INFERRED | Primary phone exchange digits. |
| 60 | TelcoBase1 | varchar(4) | YES | - | NAME-INFERRED | Primary phone base number digits. |
| 61 | TelcoAreaCode2 | varchar(3) | YES | - | NAME-INFERRED | Secondary phone area code. |
| 62 | TelcoExchange2 | varchar(3) | YES | - | NAME-INFERRED | Secondary phone exchange digits. |
| 63 | TelcoBase2 | varchar(4) | YES | - | NAME-INFERRED | Secondary phone base number digits. |
| 64 | OldSystemAccountNumber | varchar(10) | YES | - | NAME-INFERRED | Account number from a prior clearing system (legacy migration reference). |
| 65 | ClosedDate | datetime | YES | - | CODE-BACKED | Date the account was closed. NULL if the account is active. |
| 66 | TefraChangeYY | datetime | YES | - | NAME-INFERRED | Date of last TEFRA (Tax Equity and Fiscal Responsibility Act) status change. |
| 67 | ProcessDate | datetime | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 68 | AccountNature | varchar(2) | YES | - | NAME-INFERRED | Account nature code describing the ownership type or purpose. |
| 69 | CATAccountType | varchar(1) | YES | - | NAME-INFERRED | Consolidated Audit Trail (CAT) account type classification. |
| 70 | FDID | varchar(40) | YES | - | NAME-INFERRED | Firm Designated ID for CAT reporting (SEC Rule 613). |
| 71 | MPID | varchar(4) | YES | - | NAME-INFERRED | Market Participant Identifier for regulatory reporting. |
| 72 | OATSAccountType | varchar(1) | YES | - | NAME-INFERRED | OATS (Order Audit Trail System) account type code (legacy, replaced by CAT). |

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
apex.EXT765_AccountMaster (table)
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
| PK_EXT765_AccountMaster | CLUSTERED PK | Id | - | - | Active |
| IX_EXT765_AccountMaster_SodFileId | NC | SodFileId | - | - | Active |
| IX_ProcessDate | NC | ProcessDate | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT765_AccountMaster | PRIMARY KEY | Unique Id per row |
| FK_EXT765_AccountMaster_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get all accounts from the latest import

```sql
SELECT AccountNumber, AccountName, OfficeCode, Margin, OptionLevel, IRA, ProcessDate
FROM apex.EXT765_AccountMaster WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 765 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber;
```

### 8.2 Find restricted or closed accounts

```sql
SELECT AccountNumber, ShortName, RestrictReasonCode, ClosedDate, RestrDate, ProcessDate
FROM apex.EXT765_AccountMaster WITH (NOLOCK)
WHERE (RestrictReasonCode IS NOT NULL OR ClosedDate IS NOT NULL)
  AND ProcessDate >= '2026-04-01'
ORDER BY ProcessDate DESC;
```

### 8.3 Count accounts by option level and margin status

```sql
SELECT OptionLevel, Margin, COUNT(*) AS AccountCount
FROM apex.EXT765_AccountMaster WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 765 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY OptionLevel, Margin
ORDER BY OptionLevel, Margin;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 62 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT765_AccountMaster | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT765_AccountMaster.sql*
