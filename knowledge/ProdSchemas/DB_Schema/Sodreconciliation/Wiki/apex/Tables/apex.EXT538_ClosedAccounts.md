# apex.EXT538_ClosedAccounts

> Closed accounts from Apex Clearing EXT538 extract with restriction reason codes, balances, and equity values.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores the daily closed accounts list from Apex Clearing's EXT538 extract. Each row represents an account that has been closed at Apex, including the reason for closure, the currency, and remaining financial values (market value, cash balance, total equity). This data provides a snapshot of all closed accounts and any residual balances.

The EXT538 data is important for account lifecycle management and compliance. When accounts are closed at the clearing firm, eToro must update internal records accordingly, handle any remaining balances, and ensure regulatory reporting is complete. The restriction reason code provides insight into why the account was closed (voluntary, compliance-driven, etc.).

This table is specifically consumed by the `apex.GetClosedAccounts` stored procedure, which filters the data by SodFileId to return closed account details for downstream processing.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT538 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

No complex multi-column business logic. See individual element descriptions.

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT538 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | AccountName | varchar(40) | YES | - | CODE-BACKED | Account holder name. MASKED (PII). |
| 5 | RestrictReasonCode | varchar(1) | YES | - | CODE-BACKED | Restriction reason code indicating why the account was closed. |
| 6 | OfficeCurrency | varchar(3) | YES | - | CODE-BACKED | Currency code for the office/account. |
| 7 | MarketValue | decimal(28,10) | YES | - | CODE-BACKED | Remaining market value of securities in the closed account. |
| 8 | CashBalance | decimal(28,10) | YES | - | CODE-BACKED | Remaining cash balance in the closed account. |
| 9 | TotalEquity | decimal(28,10) | YES | - | CODE-BACKED | Total equity remaining (MarketValue + CashBalance). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| apex.GetClosedAccounts | @SodFileId parameter | Stored Procedure | SP queries this table filtered by SodFileId, returns AccountNumber (as ApexId) and RestrictReasonCode |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT538_ClosedAccounts (table)
  └── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| apex.GetClosedAccounts | Stored Procedure | Queries data by SodFileId parameter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT538_ClosedAccounts | CLUSTERED PK | Id | - | - | Active |
| IX_EXT538_ClosedAccounts_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT538_ClosedAccounts | PRIMARY KEY | Unique Id per row |
| FK_EXT538_ClosedAccounts_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get closed accounts from the latest import

```sql
SELECT AccountNumber, AccountName, RestrictReasonCode, OfficeCurrency,
       MarketValue, CashBalance, TotalEquity
FROM apex.EXT538_ClosedAccounts WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 538 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber;
```

### 8.2 Find closed accounts with remaining balances

```sql
SELECT AccountNumber, AccountName, RestrictReasonCode, MarketValue, CashBalance, TotalEquity
FROM apex.EXT538_ClosedAccounts WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 538 AND Status = 2 ORDER BY ProcessDate DESC)
  AND (MarketValue <> 0 OR CashBalance <> 0)
ORDER BY ABS(TotalEquity) DESC;
```

### 8.3 Count closed accounts by restriction reason

```sql
SELECT RestrictReasonCode, COUNT(*) AS AccountCount,
       SUM(TotalEquity) AS TotalRemainingEquity
FROM apex.EXT538_ClosedAccounts WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 538 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY RestrictReasonCode
ORDER BY AccountCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT538_ClosedAccounts | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT538_ClosedAccounts.sql*
