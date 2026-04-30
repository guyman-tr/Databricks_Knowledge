# Wallet.FinanceReportsBalances_old

> Non-partitioned predecessor of Wallet.FinanceReportsBalances, storing legacy wallet-crypto reconciliation results with lower decimal precision (20,8 vs 38,18) and explicit FK constraints.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: ReportId + Id (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (PK + 3 NC) |

---

## 1. Business Meaning

Wallet.FinanceReportsBalances_old is the original, non-partitioned version of the reconciliation results table. It predates Wallet.FinanceReportsBalances (the partitioned version) and stores wallet-crypto balance comparison results with lower decimal precision -- decimal(20,8) instead of decimal(38,18). The "_old" suffix indicates this is a retained copy of the original table after the partitioned replacement was created.

This table exists as a historical archive. The migration to FinanceReportsBalances (partitioned) was likely driven by the need for date-based partition management on a table that grows by millions of rows. The original table with its non-partitioned structure became too large for efficient maintenance (no partition switching for archival or backups).

Unlike its partitioned successor, this table retains explicit FK constraints to both Wallet.FinanceReports (via ReportId) and Dictionary.FinanceReportLevel (via LevelId). These FKs were dropped from the partitioned version because SQL Server requires partition-aligned indexes for FK constraints on partitioned tables, and the partitioning column (Occurred) is not part of the FK relationship.

---

## 2. Business Logic

### 2.1 Pre-Partition Legacy Data Store

**What**: The original non-partitioned reconciliation results table, superseded by the partitioned FinanceReportsBalances.

**Columns/Parameters Involved**: All columns mirror FinanceReportsBalances but with decimal(20,8) precision.

**Rules**:
- Same two-phase reconciliation pattern as FinanceReportsBalances (preliminary insert, then verified update)
- Uses decimal(20,8) precision for balance columns (TotalReceive, TotalSend, BloxBalance, ComputedAmount, BitgoValue, BloxValue) -- sufficient for early crypto volumes but insufficient for high-precision tokens
- Has explicit FK to Wallet.FinanceReports.Id on ReportId (unnamed constraint)
- Has explicit FK to Dictionary.FinanceReportLevel.Id on LevelId (unnamed constraint)
- PK is (ReportId, Id) without Occurred -- simpler than the partitioned version's (ReportId, Id, Occurred)

---

## 3. Data Overview

N/A -- table is too large for live queries (all queries time out). Data mirrors the same pattern as FinanceReportsBalances: one row per wallet-crypto pair per reconciliation run, with preliminary balance data followed by verified results.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate key. Part of composite PK (ReportId, Id). |
| 2 | ReportId | bigint | NO | - | CODE-BACKED | FK to Wallet.FinanceReports.Id identifying the parent legacy run. Has an explicit unnamed FK constraint (unlike the partitioned version). |
| 3 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | Crypto wallet identifier (GUID). |
| 4 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID -- identifies the wallet owner. |
| 5 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency asset identifier. |
| 6 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address for this wallet-crypto pair. |
| 7 | BitgoWalletId | nvarchar(100) | NO | - | CODE-BACKED | BitGo custody platform's wallet identifier. |
| 8 | BloxAccountId | nvarchar(50) | YES | - | CODE-BACKED | Blox portfolio tracker's account identifier. Likely unused (always NULL). |
| 9 | TotalReceive | decimal(20,8) | YES | - | CODE-BACKED | Total received amount. Lower precision (20,8) vs (38,18) in the partitioned version -- the original precision before high-precision crypto tokens required wider columns. |
| 10 | TotalSend | decimal(20,8) | YES | - | CODE-BACKED | Total sent amount. Lower precision (20,8). |
| 11 | BloxBalance | decimal(20,8) | YES | - | CODE-BACKED | Blockchain-reported net balance. Lower precision (20,8). Legacy naming (see FinanceReportsBalances for full explanation). |
| 12 | ComputedAmount | decimal(20,8) | YES | - | CODE-BACKED | eToro ledger's computed expected balance. Lower precision (20,8). |
| 13 | FindDiscrepancy | bit | NO | - | CODE-BACKED | Whether reconciliation found a balance mismatch: 0=no discrepancy, 1=confirmed. |
| 14 | BitgoValue | decimal(20,8) | YES | - | CODE-BACKED | BitGo provider's actual balance from verification. Lower precision (20,8). |
| 15 | BloxValue | decimal(20,8) | YES | - | CODE-BACKED | Blox provider's actual balance from verification. Lower precision (20,8). |
| 16 | ErrorMsg | nvarchar(256) | YES | - | CODE-BACKED | Error message from verification phase. NULL when successful. |
| 17 | LevelId | int | YES | - | CODE-BACKED | FK to Dictionary.FinanceReportLevel classifying the outcome. Has explicit unnamed FK constraint. See [Finance Report Level](../../_glossary.md#finance-report-level). |
| 18 | Occurred | datetime2(7) | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when the record was created. Default constraint DF_FinanceReportsBalances_Occurred_old. Unlike the partitioned version, this is NOT a partition column -- just a regular datetime. |
| 19 | Retries | tinyint | YES | - | CODE-BACKED | Number of verification re-attempts via BalanceType TVP. NULL on initial creation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReportId | Wallet.FinanceReports | FK (explicit) | Links to parent legacy run. Unnamed FK constraint. |
| LevelId | Dictionary.FinanceReportLevel | FK (explicit) | Classifies reconciliation outcome. Unnamed FK constraint. |

### 5.2 Referenced By (other objects point to this)

No stored procedures in the current codebase directly reference this table by name. It was the active table before being replaced by FinanceReportsBalances (partitioned).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.FinanceReportsBalances_old (table)
+-- Wallet.FinanceReports (table) [FK on ReportId]
+-- Dictionary.FinanceReportLevel (table) [FK on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReports | Table | FK target for ReportId -- parent legacy run |
| Dictionary.FinanceReportLevel | Table | FK target for LevelId -- reconciliation classification |

### 6.2 Objects That Depend On This

No dependents found in current codebase. This is a retired archive table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FinanceReportsBalances | CLUSTERED PK | ReportId ASC, Id ASC | - | - | Active (DATA_COMPRESSION=PAGE) |
| ix_FinanceReportsBalances_Occurred | NC | Occurred ASC | - | - | Active |
| IX_FinanceReportsBalances_ReportId_LevelId | NC | ReportId ASC, LevelId ASC | - | - | Active |
| IX_FinanceReportsBalances_ReportId_WalletId_CryptoId | NC | ReportId ASC, WalletId ASC, CryptoId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FinanceReportsBalances | PRIMARY KEY | Composite clustered on (ReportId, Id). DATA_COMPRESSION = PAGE. |
| (unnamed) | FOREIGN KEY | ReportId references Wallet.FinanceReports(Id) |
| (unnamed) | FOREIGN KEY | LevelId references Dictionary.FinanceReportLevel(Id) |
| DF_FinanceReportsBalances_Occurred_old | DEFAULT | Occurred defaults to GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Check row count for a specific report
```sql
SELECT COUNT(*) AS RecordCount
FROM Wallet.FinanceReportsBalances_old WITH (NOLOCK)
WHERE ReportId = 1;
```

### 8.2 Discrepancies with level names for a specific run
```sql
SELECT frb.Id, frb.WalletId, frb.CryptoId, frb.BloxBalance, frb.ComputedAmount,
       l.Name AS LevelName
FROM Wallet.FinanceReportsBalances_old frb WITH (NOLOCK)
INNER JOIN Dictionary.FinanceReportLevel l WITH (NOLOCK) ON frb.LevelId = l.Id
WHERE frb.ReportId = 1
ORDER BY frb.LevelId;
```

### 8.3 Compare precision between old and current tables
```sql
SELECT 'Old (20,8)' AS Version, MAX(LEN(CAST(TotalReceive AS VARCHAR(50)))) AS MaxReceiveLen
FROM Wallet.FinanceReportsBalances_old WITH (NOLOCK)
WHERE ReportId = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.FinanceReportsBalances_old | Type: Table | Source: WalletBalancesReportDB/Wallet/Tables/Wallet.FinanceReportsBalances_old.sql*
