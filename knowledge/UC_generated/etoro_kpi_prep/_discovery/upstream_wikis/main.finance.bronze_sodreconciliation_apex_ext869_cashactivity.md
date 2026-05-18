# apex.EXT869_CashActivity

> Cash transaction activity from Apex Clearing EXT869 extract: debits, credits, dividends, interest, and fees per account.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (1 PK + 2 NC) |

---

## 1. Business Meaning

This table stores daily cash activity transactions from Apex Clearing's EXT869 extract. Each row represents an individual cash movement on a customer account -- debits, credits, dividend payments, interest accruals, fees, checks, and ACAT transfers. The data provides a complete audit trail of all monetary activity flowing through accounts at the clearing firm.

The EXT869 cash activity data is essential for reconciling cash balances between Apex and eToro's internal ledger. It enables tracking of all money-in/money-out events, matching dividends and interest to expected payments, and identifying unexpected fees or adjustments.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT869 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Cash Transaction Classification

**What**: Transactions are classified by multiple code fields.

**Columns Involved**: `BatchCode`, `EntryTypeCode`, `RecTypeCode`, `ActivityIndicator`, `PayTypeCode`

**Rules**:
- BatchCode identifies the processing batch type (e.g., dividends, interest, fees)
- EntryTypeCode classifies the type of cash entry
- RecTypeCode indicates the record type within the batch
- ActivityIndicator flags the nature of the activity
- PayTypeCode determines how the payment is processed

### 2.2 Dividend and Withholding

**What**: Dividend-related fields track tax treatment.

**Columns Involved**: `DivTaxTypeCode`, `WithholdTaxIndicator`, `WithholdTaxTypeCode`

**Rules**:
- DivTaxTypeCode classifies the dividend for tax purposes (qualified, ordinary, return of capital, etc.)
- WithholdTaxIndicator and WithholdTaxTypeCode track whether tax was withheld and what type

---

## 3. Data Overview

~4.2 million rows. Daily cash transaction activity from Apex across all accounts.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT869 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | AccountType | varchar(1) | YES | - | CODE-BACKED | Account type code (e.g., cash, margin, short). |
| 5 | Amount | decimal(28,10) | YES | - | CODE-BACKED | Transaction amount. Positive for credits, negative for debits. |
| 6 | Description | varchar(30) | YES | - | CODE-BACKED | Free-text description of the cash activity. |
| 7 | CurrencyCode | varchar(3) | YES | - | CODE-BACKED | ISO currency code for the transaction (e.g., USD). |
| 8 | ProcessDate | date | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 9 | BatchCode | varchar(3) | YES | - | NAME-INFERRED | Apex batch processing code identifying the transaction category. |
| 10 | Cusip | varchar(10) | YES | - | CODE-BACKED | CUSIP of the related security (for dividends, interest on bonds, etc.). |
| 11 | EntryDate | smalldatetime | YES | - | CODE-BACKED | Date the transaction was entered in Apex's system. |
| 12 | SourceProgram | varchar(6) | YES | - | NAME-INFERRED | Apex source program that generated the transaction. |
| 13 | UserID | varchar(8) | YES | - | CODE-BACKED | User ID of the operator who entered or approved the transaction. |
| 14 | ActivityIndicator | varchar(1) | YES | - | NAME-INFERRED | Code indicating the type of cash activity. |
| 15 | OfficeCode | varchar(3) | YES | - | CODE-BACKED | Apex office/branch code associated with the account. |
| 16 | ACATSControlNumber | varchar(14) | YES | - | NAME-INFERRED | ACATS (Automated Customer Account Transfer Service) control number for account transfer transactions. |
| 17 | CheckNumber | varchar(5) | YES | - | CODE-BACKED | Check number for check-based disbursements. |
| 18 | DivTaxTypeCode | varchar(1) | YES | - | NAME-INFERRED | Dividend tax classification code (qualified, ordinary, etc.). |
| 19 | EffectiveDate | smalldatetime | YES | - | CODE-BACKED | Effective date of the transaction for settlement purposes. |
| 20 | EnteredBy | varchar(3) | YES | - | CODE-BACKED | Operator code who entered the transaction. |
| 21 | EntryTypeCode | varchar(2) | YES | - | NAME-INFERRED | Code classifying the type of cash entry. |
| 22 | Firm | varchar(2) | YES | - | CODE-BACKED | Clearing firm identifier. |
| 23 | GLPostStatusCode | varchar(1) | YES | - | NAME-INFERRED | General Ledger posting status code. |
| 24 | HistoryEntryCode | varchar(1) | YES | - | NAME-INFERRED | Code indicating if the entry is a historical correction or adjustment. |
| 25 | InterestEffectiveDate | datetime2(7) | YES | - | NAME-INFERRED | Effective date for interest calculation purposes. |
| 26 | MoneyMarketCode | varchar(3) | YES | - | NAME-INFERRED | Money market fund code for sweep-related transactions. |
| 27 | OriginalQuantity | decimal(19,5) | YES | - | NAME-INFERRED | Original share quantity related to the cash activity (e.g., shares for a dividend). |
| 28 | OverrideIndicator | varchar(1) | YES | - | NAME-INFERRED | Flag indicating if the transaction was manually overridden. |
| 29 | PasMergeEntryCode | varchar(1) | YES | - | NAME-INFERRED | PAS (Portfolio Accounting System) merge entry code. |
| 30 | PayTypeCode | varchar(1) | YES | - | NAME-INFERRED | Payment type code (check, wire, ACH, etc.). |
| 31 | Price | decimal(19,10) | YES | - | CODE-BACKED | Price per unit related to the transaction (e.g., dividend rate per share). |
| 32 | RecTypeCode | varchar(1) | YES | - | NAME-INFERRED | Record type code within the batch. |
| 33 | RegisteredRepCode | varchar(6) | YES | - | CODE-BACKED | Registered representative code assigned to the account. |
| 34 | SequenceNumber | int | YES | - | CODE-BACKED | Sequence number for ordering transactions within a batch. |
| 35 | TerminalID | varchar(15) | YES | - | CODE-BACKED | Terminal or workstation identifier where the transaction originated. |
| 36 | TradeDate | smalldatetime | YES | - | CODE-BACKED | Trade date for the related transaction. |
| 37 | Tradenumber | varchar(5) | YES | - | CODE-BACKED | Trade number linking the cash activity to a specific trade. |
| 38 | UserEntryDate | datetime2(7) | YES | - | NAME-INFERRED | Date the user entered the transaction (may differ from system entry date). |
| 39 | WithholdTaxIndicator | varchar(1) | YES | - | NAME-INFERRED | Flag indicating if tax withholding was applied. |
| 40 | WithholdTaxTypeCode | varchar(1) | YES | - | NAME-INFERRED | Type of tax withholding applied (federal, state, foreign). |
| 41 | CorrespondentOfficeID | int | YES | - | CODE-BACKED | Correspondent firm office identifier. |
| 42 | CorrespondentID | int | YES | - | CODE-BACKED | Correspondent firm identifier. |

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
apex.EXT869_CashActivity (table)
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
| PK_EXT869_CashActivity | CLUSTERED PK | Id | - | - | Active |
| IX_EXT869_CashActivity_ProcessDate_TerminalID | NC | ProcessDate, TerminalID | - | - | Active |
| IX_EXT869_CashActivity_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT869_CashActivity | PRIMARY KEY | Unique Id per row |
| FK_EXT869_CashActivity_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get cash activity for a specific import date

```sql
SELECT AccountNumber, Amount, Description, CurrencyCode, BatchCode, EntryTypeCode, TradeDate
FROM apex.EXT869_CashActivity WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 869 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber, SequenceNumber;
```

### 8.2 Summarize cash activity by batch code

```sql
SELECT BatchCode, COUNT(*) AS TransactionCount, SUM(Amount) AS TotalAmount
FROM apex.EXT869_CashActivity WITH (NOLOCK)
WHERE ProcessDate >= '2026-04-01'
GROUP BY BatchCode
ORDER BY TotalAmount DESC;
```

### 8.3 Find dividend-related cash activity with withholding

```sql
SELECT AccountNumber, Amount, Cusip, DivTaxTypeCode, WithholdTaxIndicator, WithholdTaxTypeCode, ProcessDate
FROM apex.EXT869_CashActivity WITH (NOLOCK)
WHERE DivTaxTypeCode IS NOT NULL
  AND ProcessDate >= '2026-04-01'
ORDER BY ProcessDate DESC, AccountNumber;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 25 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT869_CashActivity | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT869_CashActivity.sql*
