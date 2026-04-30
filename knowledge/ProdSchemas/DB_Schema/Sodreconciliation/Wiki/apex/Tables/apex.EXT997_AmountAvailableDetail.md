# apex.EXT997_AmountAvailableDetail

> Available funds detail from Apex Clearing EXT997 extract: gross/net available, pending transfers, recent deposits, and withheld amounts per account.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores the daily available funds detail from Apex Clearing's EXT997 extract. Each row represents an account's breakdown of available funds, showing gross funds available, various holds and pending items that reduce availability, and the resulting net funds available. This is a critical data source for determining how much cash a customer can actually withdraw or use.

The EXT997 data enables eToro to accurately display available-to-trade and available-to-withdraw amounts. It also helps explain discrepancies between total cash balances and available funds by itemizing the specific holds: pending transfers, recent deposits (subject to hold periods), pending interest, pending dividends, unsettled balances, and withheld amounts.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT997 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Net Funds Calculation

**What**: Net available funds are derived from gross funds minus various holds.

**Columns Involved**: `GrossFundsAvailable`, `PendingTransfer`, `RecentDeposit`, `PendingDebitInterest`, `PendingDebitDividend`, `FullyPaidUnsettledBalance`, `NetFundsAvailable`, `AmountWithheld`

**Rules**:
- GrossFundsAvailable is the total funds before any holds are applied
- PendingTransfer, RecentDeposit, PendingDebitInterest, PendingDebitDividend, FullyPaidUnsettledBalance, and AmountWithheld are deducted
- NetFundsAvailable = GrossFundsAvailable minus all holds
- Recent deposits are typically held for several business days per Reg CC

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT997 file import. CASCADE DELETE. |
| 3 | ProcessDate | smalldatetime | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 4 | OfficeCode | varchar(3) | YES | - | CODE-BACKED | Apex office/branch code. |
| 5 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 6 | GrossFundsAvailable | decimal(28,10) | YES | - | CODE-BACKED | Total funds available before any holds or deductions. |
| 7 | PendingTransfer | decimal(28,10) | YES | - | CODE-BACKED | Amount held for pending incoming/outgoing transfers. |
| 8 | RecentDeposit | decimal(28,10) | YES | - | CODE-BACKED | Amount held for recently deposited funds (subject to hold period). |
| 9 | PendingDebitInterest | decimal(28,10) | YES | - | CODE-BACKED | Amount held for pending interest debits. |
| 10 | PendingDebitDividend | decimal(28,10) | YES | - | CODE-BACKED | Amount held for pending dividend debits (e.g., short positions). |
| 11 | FullyPaidUnsettledBalance | decimal(28,10) | YES | - | CODE-BACKED | Unsettled balance for fully paid securities (not yet settled). |
| 12 | NetFundsAvailable | decimal(28,10) | YES | - | CODE-BACKED | Net funds available after all holds and deductions. |
| 13 | AmountWithheld | decimal(28,10) | YES | - | CODE-BACKED | Amount specifically withheld (e.g., for regulatory or operational reasons). |

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
apex.EXT997_AmountAvailableDetail (table)
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
| PK_EXT997_AmountAvailableDetail | CLUSTERED PK | Id | - | - | Active |
| IX_EXT997_AmountAvailableDetail_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT997_AmountAvailableDetail | PRIMARY KEY | Unique Id per row |
| FK_EXT997_AmountAvailableDetail_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get available funds from the latest import

```sql
SELECT AccountNumber, GrossFundsAvailable, NetFundsAvailable, PendingTransfer,
       RecentDeposit, AmountWithheld, ProcessDate
FROM apex.EXT997_AmountAvailableDetail WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 997 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber;
```

### 8.2 Find accounts with significant holds

```sql
SELECT AccountNumber, GrossFundsAvailable, NetFundsAvailable,
       (GrossFundsAvailable - NetFundsAvailable) AS TotalHolds,
       PendingTransfer, RecentDeposit, AmountWithheld
FROM apex.EXT997_AmountAvailableDetail WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 997 AND Status = 2 ORDER BY ProcessDate DESC)
  AND (GrossFundsAvailable - NetFundsAvailable) > 10000
ORDER BY (GrossFundsAvailable - NetFundsAvailable) DESC;
```

### 8.3 Summarize hold types across all accounts

```sql
SELECT COUNT(*) AS AccountCount,
       SUM(GrossFundsAvailable) AS TotalGross,
       SUM(NetFundsAvailable) AS TotalNet,
       SUM(PendingTransfer) AS TotalPendingTransfers,
       SUM(RecentDeposit) AS TotalRecentDeposits,
       SUM(AmountWithheld) AS TotalWithheld
FROM apex.EXT997_AmountAvailableDetail WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 997 AND Status = 2 ORDER BY ProcessDate DESC);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT997_AmountAvailableDetail | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT997_AmountAvailableDetail.sql*
