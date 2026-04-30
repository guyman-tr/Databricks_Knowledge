# apex.EXT596_TradesMovedToAnErrorAccount

> Trades moved to error accounts from Apex Clearing EXT596 extract for investigation.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily data from Apex Clearing's EXT596 extract identifying trades that have been moved to an error account. When a trade cannot be properly settled or allocated to the intended customer account (due to restrictions, compliance issues, or processing errors), Apex moves it to a designated error account for investigation and resolution.

The EXT596 data is important for operations and compliance teams. Error account trades require manual investigation and resolution -- the trade must either be corrected and moved back to the proper customer account, or reversed entirely. Unresolved error account trades may indicate systemic issues with order routing, account restrictions, or compliance checks.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT596 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Error Account Tracking

**What**: Each error trade tracks both the original and error accounts.

**Columns Involved**: `AccountNumber`, `ErrorAccount`, `RestrictedDesc`

**Rules**:
- AccountNumber is the original intended account for the trade (MASKED - PII)
- ErrorAccount is the designated error account where the trade was placed
- RestrictedDesc explains the reason the trade was moved to the error account

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT596 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Original intended customer account number. MASKED (PII). |
| 4 | ErrorAccount | varchar(8) | YES | - | CODE-BACKED | Designated error account where the trade was moved. |
| 5 | AccountType | varchar(1) | YES | - | CODE-BACKED | Account type code. |
| 6 | Quantity | decimal(28,10) | YES | - | CODE-BACKED | Number of shares/units in the error trade. |
| 7 | Price | decimal(28,10) | YES | - | CODE-BACKED | Execution price per share/unit. |
| 8 | SecurityNumber | varchar(12) | YES | - | CODE-BACKED | Security identifier (CUSIP or similar). MASKED (PII). |
| 9 | BuySell | varchar(2) | YES | - | CODE-BACKED | Buy or sell direction for the error trade. |
| 10 | TradeDate | smalldatetime | YES | - | CODE-BACKED | Date the trade was originally executed. |
| 11 | TradeNumber | varchar(5) | YES | - | CODE-BACKED | Apex trade number for the error trade. |
| 12 | RestrictedDesc | varchar(50) | YES | - | CODE-BACKED | Description of the restriction or reason the trade was moved to the error account. |

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
apex.EXT596_TradesMovedToAnErrorAccount (table)
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
| PK_EXT596_TradesMovedToAnErrorAccount | CLUSTERED PK | Id | - | - | Active |
| IX_EXT596_TradesMovedToAnErrorAccount_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT596_TradesMovedToAnErrorAccount | PRIMARY KEY | Unique Id per row |
| FK_EXT596_TradesMovedToAnErrorAccount_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get error trades from the latest import

```sql
SELECT AccountNumber, ErrorAccount, SecurityNumber, BuySell, Quantity, Price,
       TradeDate, TradeNumber, RestrictedDesc
FROM apex.EXT596_TradesMovedToAnErrorAccount WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 596 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY TradeDate DESC, AccountNumber;
```

### 8.2 Summarize error trades by restriction reason

```sql
SELECT RestrictedDesc, COUNT(*) AS TradeCount, SUM(Quantity * Price) AS TotalValue
FROM apex.EXT596_TradesMovedToAnErrorAccount WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 596 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY RestrictedDesc
ORDER BY TradeCount DESC;
```

### 8.3 Find error trades by error account

```sql
SELECT ErrorAccount, COUNT(*) AS TradeCount,
       COUNT(DISTINCT AccountNumber) AS AffectedAccounts
FROM apex.EXT596_TradesMovedToAnErrorAccount WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 596 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY ErrorAccount
ORDER BY TradeCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT596_TradesMovedToAnErrorAccount | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT596_TradesMovedToAnErrorAccount.sql*
