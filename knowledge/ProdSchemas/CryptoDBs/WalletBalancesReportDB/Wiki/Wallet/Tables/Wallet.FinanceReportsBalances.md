# Wallet.FinanceReportsBalances

> Partitioned table storing wallet-crypto balance reconciliation results for the legacy reconciliation system, with date-based partitioning on the Occurred column for historical data management.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: ReportId + Id + Occurred (CLUSTERED) |
| **Partition** | Yes - DatesToFilegroup on Occurred |
| **Indexes** | 4 active (PK + 3 NC) |

---

## 1. Business Meaning

Wallet.FinanceReportsBalances is the partitioned child table for the legacy reconciliation system (paired with Wallet.FinanceReports as the parent run table). Each row represents the reconciliation result for one wallet-crypto pair within a legacy run, capturing send/receive totals, computed balance, discrepancy status, and classification level. It is structurally identical to Wallet.FinanceReportRecords (the current system's equivalent) but uses Occurred instead of Created and is partitioned by date.

This table holds the historical bulk of reconciliation data spanning from April 2019 through December 2024. With IDs exceeding 1.8 billion, it is by far the largest table in the schema. The date-based partitioning (DatesToFilegroup) enables efficient partition switching and archival of old reconciliation data.

Data was created by three legacy stored procedures: Wallet.CreateNewReports (bulk INSERT of all wallets from the external table), Wallet.GetWalletBalanceReport (INSERT of wallets below the discrepancy threshold), and Wallet.AddReport (single-row INSERT). Updates were applied by Wallet.UpdateReportRecord using the Wallet.BalanceType TVP. Discrepancies were read by Wallet.GetFinanceReportDiscrepancies. The table stopped receiving new data in December 2024 when the system migrated to Wallet.FinanceReportRecords.

---

## 2. Business Logic

### 2.1 Legacy Two-Phase Reconciliation

**What**: Same two-phase pattern as the current system (preliminary insert then verified update), but using the legacy run table (FinanceReports) as parent.

**Columns/Parameters Involved**: `ReportId`, `FindDiscrepancy`, `LevelId`, `BitgoValue`, `BloxValue`, `ErrorMsg`, `Retries`

**Rules**:
- Phase 1: Records inserted by CreateNewReports or GetWalletBalanceReport with preliminary balance data. LevelId=100 if discrepancy exceeds threshold, NULL otherwise.
- Phase 2: Records updated by UpdateReportRecord via BalanceType TVP with verified BitGo/Blox values and refined LevelId classification.
- Unlike the current system (UpdateReportRecords), the legacy UpdateReportRecord does NOT prune unchanged records or check ProcessAllRecords parameters.
- No explicit FK constraints on ReportId (due to partitioning constraints), unlike FinanceReportsBalances_old which has explicit FKs.

### 2.2 Date-Based Partitioning Strategy

**What**: Table is partitioned by Occurred to enable efficient historical data management.

**Columns/Parameters Involved**: `Occurred`, `ReportId`, `Id`

**Rules**:
- The PK is composite: (ReportId, Id, Occurred) with Occurred included to align with the partition scheme
- The DatesToFilegroup partition function distributes rows by Occurred date
- This enables partition switching for archival (moving old months to archive filegroups)
- The Occurred column defaults to GETUTCDATE(), same as Created in FinanceReportRecords

---

## 3. Data Overview

| Id | ReportId | WalletId | CryptoId | BloxBalance | ComputedAmount | FindDiscrepancy | LevelId | Occurred | Meaning |
|----|----------|----------|----------|-------------|----------------|-----------------|---------|----------|---------|
| 1802010429 | 2141 | 91896FEC-... | 21 | 0 | 0 | 0 | NULL | 2024-12-09 | One of the last records in the table -- part of the final legacy run (ReportId 2141). Zero balances, no discrepancy. |
| 1802010425 | 2141 | B4EDCB68-... | 21 | 0 | 0 | 0 | NULL | 2024-12-09 | Another final-run record. All records from this run share Occurred = 2024-12-09, the last day the legacy system operated. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate key. Part of the composite PK (ReportId, Id, Occurred) to support the partitioning scheme. Sequence reaches ~1.8 billion, reflecting the massive volume of reconciliation data over 5+ years. |
| 2 | ReportId | bigint | NO | - | CODE-BACKED | Implicit FK to Wallet.FinanceReports.Id identifying the parent run. No explicit FK constraint exists (partitioning prevents FK on non-partition-aligned columns). Indexed in composite with LevelId and with WalletId+CryptoId. |
| 3 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | Crypto wallet identifier (GUID). Part of the composite business key (ReportId, WalletId, CryptoId). |
| 4 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID -- identifies the wallet owner. Denormalized from the external table for efficient customer-level querying. |
| 5 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency asset identifier. Completes the composite business key. |
| 6 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address for this wallet-crypto pair. Passed through from the external table for traceability. |
| 7 | BitgoWalletId | nvarchar(100) | NO | - | CODE-BACKED | BitGo custody platform's wallet identifier for cross-referencing during discrepancy investigation. |
| 8 | BloxAccountId | nvarchar(50) | YES | - | CODE-BACKED | Blox portfolio tracker's account identifier. Appears unused in production (always NULL in sampled data). |
| 9 | TotalReceive | decimal(38,18) | YES | - | CODE-BACKED | Total received amount for this wallet-crypto pair from blockchain data. Sourced from vu_GetWalletBalanceReport.TotalRecive. |
| 10 | TotalSend | decimal(38,18) | YES | - | CODE-BACKED | Total sent amount for this wallet-crypto pair from blockchain data. |
| 11 | BloxBalance | decimal(38,18) | YES | - | CODE-BACKED | Blockchain-reported net balance. Despite the name, this is the blockchain balance (TotalReceive - TotalSend), not the Blox provider balance. Legacy naming. |
| 12 | ComputedAmount | decimal(38,18) | YES | - | CODE-BACKED | eToro ledger's computed expected balance. Compared against BloxBalance: `ABS(ComputedAmount - BloxBalance) > @Threshold` for discrepancy detection. |
| 13 | FindDiscrepancy | bit | NO | - | CODE-BACKED | Whether reconciliation found a balance mismatch: 0=no discrepancy (or not yet verified), 1=confirmed discrepancy. Initially 0; updated by UpdateReportRecord. |
| 14 | BitgoValue | decimal(38,18) | YES | - | CODE-BACKED | BitGo custody provider's actual balance from the verification phase. Initially 0; updated by UpdateReportRecord via BalanceType TVP. |
| 15 | BloxValue | decimal(38,18) | YES | - | CODE-BACKED | Blox portfolio tracker's actual balance from the verification phase. Initially 0; updated by UpdateReportRecord via BalanceType TVP. |
| 16 | ErrorMsg | nvarchar(256) | YES | - | CODE-BACKED | Error message from reconciliation verification. Contains API error details. NULL when successful. |
| 17 | LevelId | int | YES | - | CODE-BACKED | Classification of the reconciliation outcome. Implicit reference to Dictionary.FinanceReportLevel (no explicit FK due to partitioning). See [Finance Report Level](../../_glossary.md#finance-report-level). |
| 18 | Occurred | datetime2(7) | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when this record was created. Partition column for DatesToFilegroup. Default constraint DF_FinanceReportsBalances_Occurred. Equivalent to FinanceReportRecords.Created. |
| 19 | Retries | tinyint | YES | - | CODE-BACKED | Number of verification re-attempts. Set via the BalanceType TVP. NULL on initial creation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReportId | Wallet.FinanceReports | Implicit | Links to parent legacy run (no explicit FK due to partitioning) |
| LevelId | Dictionary.FinanceReportLevel | Implicit | Classifies reconciliation outcome (no explicit FK due to partitioning) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.CreateNewReports | INSERT | Writer | Bulk-inserts records from external table for each legacy run |
| Wallet.GetWalletBalanceReport | INSERT | Writer | Inserts below-threshold records during legacy reconciliation |
| Wallet.AddReport | INSERT | Writer | Single-row insert for individual balance records |
| Wallet.UpdateReportRecord | UPDATE | Modifier | Updates with verified BitGo/Blox values via BalanceType TVP |
| Wallet.GetFinanceReportDiscrepancies | SELECT | Reader | Reads discrepancies (LevelId=100) for reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.FinanceReportsBalances (table)
+-- Wallet.FinanceReports (table) [implicit ref on ReportId]
+-- Dictionary.FinanceReportLevel (table) [implicit ref on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReports | Table | Implicit FK target for ReportId -- parent legacy run |
| Dictionary.FinanceReportLevel | Table | Implicit lookup for LevelId -- reconciliation classification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CreateNewReports | Stored Procedure | WRITER - bulk inserts from external table |
| Wallet.GetWalletBalanceReport | Stored Procedure | WRITER - inserts below-threshold records |
| Wallet.AddReport | Stored Procedure | WRITER - single-row insert |
| Wallet.UpdateReportRecord | Stored Procedure | MODIFIER - updates with verified results |
| Wallet.GetFinanceReportDiscrepancies | Stored Procedure | READER - reads discrepancies |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_History_FinanceReportsBalances | CLUSTERED PK | ReportId ASC, Id ASC, Occurred ASC | - | - | Active (partitioned on DatesToFilegroup) |
| ix_FinanceReportsBalances_Occurred | NC | Occurred ASC | - | - | Active (DATA_COMPRESSION=PAGE) |
| IX_FinanceReportsBalances_ReportId_LevelId | NC | ReportId ASC, LevelId ASC | - | - | Active (DATA_COMPRESSION=PAGE) |
| IX_FinanceReportsBalances_ReportId_WalletId_CryptoId | NC | ReportId ASC, WalletId ASC, CryptoId ASC | - | - | Active (DATA_COMPRESSION=PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_History_FinanceReportsBalances | PRIMARY KEY | Composite clustered on (ReportId, Id, Occurred). Partitioned on DatesToFilegroup(Occurred). |
| DF_FinanceReportsBalances_Occurred | DEFAULT | Occurred defaults to GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Records for the most recent legacy run
```sql
SELECT TOP 10 Id, ReportId, WalletId, CryptoId, BloxBalance, ComputedAmount,
       FindDiscrepancy, LevelId, Occurred
FROM Wallet.FinanceReportsBalances WITH (NOLOCK)
WHERE ReportId = 2141
ORDER BY Id DESC;
```

### 8.2 Partition-aligned query for a date range
```sql
SELECT TOP 10 *
FROM Wallet.FinanceReportsBalances WITH (NOLOCK)
WHERE Occurred >= '2024-12-01' AND Occurred < '2025-01-01'
ORDER BY Occurred DESC;
```

### 8.3 Discrepancies with level names for a specific run
```sql
SELECT frb.Id, frb.WalletId, frb.CryptoId, frb.BloxBalance, frb.ComputedAmount,
       frb.BitgoValue, frb.BloxValue, l.Name AS LevelName
FROM Wallet.FinanceReportsBalances frb WITH (NOLOCK)
LEFT JOIN Dictionary.FinanceReportLevel l WITH (NOLOCK) ON frb.LevelId = l.Id
WHERE frb.ReportId = 2141 AND frb.LevelId IS NOT NULL
ORDER BY frb.LevelId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.FinanceReportsBalances | Type: Table | Source: WalletBalancesReportDB/Wallet/Tables/Wallet.FinanceReportsBalances.sql*
