# Wallet.FinanceReportRecords

> Primary table storing individual wallet-crypto reconciliation results for the current reconciliation system, linking each balance comparison outcome to its parent run.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 4 active (PK + 3 NC) |

---

## 1. Business Meaning

Wallet.FinanceReportRecords is the core data table for the current crypto wallet balance reconciliation system. Each row represents the reconciliation result for a single wallet-crypto pair within a specific run -- capturing the wallet's send/receive totals from the blockchain, computed balance from eToro's ledger, whether a discrepancy was detected, and the classification level of any mismatch.

This table exists as the central evidence store for the reconciliation pipeline. It allows operations teams to investigate which wallets have balance discrepancies, what the specific numbers were at the time of comparison, and how discrepancies evolve over time (via Retries and LastChecked). Without it, there would be no audit trail of reconciliation results.

Data is created by Wallet.CreateNewReportRun, which pulls all wallet balances from the external table Wallet.vu_GetWalletBalanceReport and inserts one record per wallet-crypto pair. Initial records have FindDiscrepancy=0, BitgoValue=0, BloxValue=0, and a preliminary LevelId (100 if the balance difference exceeds the threshold, NULL otherwise). The application then processes each record, calling Wallet.UpdateReportRecords with a Wallet.BalanceType TVP containing the verified reconciliation results (actual BitGo/Blox values, final classification level, error messages). Wallet.GetFinanceReportRunDiscrepancies and Wallet.GetFinanceSnapshot read the data for reporting and analysis.

---

## 2. Business Logic

### 2.1 Two-Phase Reconciliation Pattern

**What**: Records go through an initial creation phase (preliminary classification) followed by an update phase (verified results).

**Columns/Parameters Involved**: `ReportId`, `FindDiscrepancy`, `LevelId`, `BitgoValue`, `BloxValue`, `ErrorMsg`, `Retries`, `LastChecked`

**Rules**:
- **Phase 1 (Creation by CreateNewReportRun)**: Each record is inserted with preliminary data from the external table. LevelId is set to 100 (InitialDiscrepancy) if `ABS(TotalAmount - TotalBalance) > @Threshold`, or NULL if balances match. FindDiscrepancy=0, BitgoValue=0, BloxValue=0.
- **Phase 2 (Update by UpdateReportRecords)**: The application verifies each discrepancy by calling BitGo and Blox APIs directly. Results are sent via the Wallet.BalanceType TVP: FindDiscrepancy is set to true/false, LevelId is refined (1=EventualyConsolidated, 2=AllDiff, 3=EtoroDiffBoth, etc.), BitgoValue and BloxValue receive the actual provider balances, LastChecked is set to GETUTCDATE().
- **Pruning logic**: If ProcessAllRecords=false in the run's Parameters JSON, UpdateReportRecords compares each record to its predecessor (same WalletId+CryptoId, earlier Created). If all key fields are unchanged, the new record is deleted to save space.

**Diagram**:
```
CreateNewReportRun                    UpdateReportRecords
  |                                     |
  | INSERT with preliminary data        | UPDATE with verified results
  | LevelId = 100 or NULL              | LevelId = 1-12 (refined)
  | FindDiscrepancy = 0                | FindDiscrepancy = 0 or 1
  | BitgoValue = 0                     | BitgoValue = actual
  | BloxValue = 0                      | BloxValue = actual
  | LastChecked = NULL                 | LastChecked = GETUTCDATE()
  |                                     |
  v                                     v
  Record created ---------> Record verified and classified
                    (optionally pruned if unchanged from previous run)
```

### 2.2 Discrepancy Classification Distribution

**What**: The LevelId values reveal the reconciliation health of the wallet portfolio.

**Columns/Parameters Involved**: `LevelId`

**Rules**:
- NULL (75.6% of records): No discrepancy detected -- balance comparison passed the threshold
- LevelId=3 / EtoroDiffBoth (22.6%): Most common discrepancy type -- eToro ledger differs from BitGo+Blox consensus. Suggests systematic ledger sync issues
- LevelId=1 / EventualyConsolidated (1.1%): Temporary discrepancies that self-resolved
- LevelId=2 / AllDiff (0.5%): Full three-way mismatches requiring investigation
- LevelId=9,10,11 / API errors (<0.2%): Provider API failures during reconciliation
- See [Finance Report Level](../../_glossary.md#finance-report-level) for complete classification details

---

## 3. Data Overview

| Id | ReportId | WalletId | CryptoId | BloxBalance | ComputedAmount | FindDiscrepancy | LevelId | Meaning |
|----|----------|----------|----------|-------------|----------------|-----------------|---------|---------|
| 2613462 | 622 | 749DB5AA-... | 64 | 0.006981 | 0.006981 | 0 | NULL | Clean record -- blockchain balance matches computed amount. No discrepancy. Typical for the majority of wallet-crypto pairs. |
| 2613466 | 622 | 58F66320-... | 64 | 0 | 0 | 0 | NULL | Zero-balance wallet -- both sources agree on zero. Common for dormant or newly created wallets. |
| (verified) | - | - | - | - | - | 1 | 2 | Verified AllDiff discrepancy -- after Phase 2 processing, BitgoValue=391.20 and BloxValue=391.20 are populated, Retries=0, LastChecked set. All three systems disagree. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing primary key. Part of unique index IX_FinanceReportRecords__ReportId_WalletId_CryptoId for efficient lookups. |
| 2 | ReportId | bigint | NO | - | CODE-BACKED | FK to Wallet.FinanceReportRuns.Id identifying which reconciliation run produced this record. Constraint: FK__FinanceReportRecords__ReportId. Indexed in composite with LevelId and with WalletId+CryptoId. |
| 3 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | Crypto wallet identifier (GUID). Part of the composite business key (ReportId, WalletId, CryptoId). Used in CROSS APPLY joins by CreateNewReportRun and GetFinanceSnapshot to correlate with external table data. |
| 4 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID -- identifies the wallet owner. Carried from the external table for denormalized customer-level querying without joining back to WalletDB. |
| 5 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency asset identifier. Completes the composite business key. Same CryptoId may appear multiple times per run if a customer has multiple wallets for the same crypto. |
| 6 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address associated with this wallet-crypto pair. Passed through from the external table for traceability during discrepancy investigation. NULL for wallets without dedicated on-chain addresses. |
| 7 | BitgoWalletId | nvarchar(100) | NO | - | CODE-BACKED | BitGo custody platform's wallet identifier. Enables cross-referencing with BitGo's API for discrepancy investigation. Aliased as ProviderWalletId in GetFinanceReportRunDiscrepancies output. |
| 8 | BloxAccountId | nvarchar(50) | YES | - | CODE-BACKED | Blox portfolio tracker's account identifier. Always NULL in production data -- the current reconciliation system (CreateNewReportRun) does not populate this field, suggesting Blox account mapping was deprecated or moved to the application layer. |
| 9 | TotalReceive | decimal(38,18) | YES | - | CODE-BACKED | Total amount received into this wallet-crypto pair. Sourced from vu_GetWalletBalanceReport.TotalRecive (note: mapped from the misspelled column). Represents the cumulative incoming blockchain transactions. |
| 10 | TotalSend | decimal(38,18) | YES | - | CODE-BACKED | Total amount sent from this wallet-crypto pair. Sourced from vu_GetWalletBalanceReport.TotalSend. Represents the cumulative outgoing blockchain transactions. |
| 11 | BloxBalance | decimal(38,18) | YES | - | CODE-BACKED | Blockchain-reported net balance (TotalReceive - TotalSend). Despite the name suggesting "Blox balance," this is actually the blockchain/computed balance from the external table's TotalBalance column. The naming reflects the legacy system where Blox was the primary comparison source. |
| 12 | ComputedAmount | decimal(38,18) | YES | - | CODE-BACKED | Internally computed expected balance from eToro's ledger system. Sourced from vu_GetWalletBalanceReport.TotalAmount. The reconciliation threshold check compares this against BloxBalance: `ABS(ComputedAmount - BloxBalance) > @Threshold`. |
| 13 | FindDiscrepancy | bit | NO | - | CODE-BACKED | Whether the final reconciliation result found a balance mismatch: 0 = no discrepancy (or not yet verified), 1 = confirmed discrepancy. Initially set to 0 by CreateNewReportRun; updated to 1 by UpdateReportRecords when verification confirms a mismatch. |
| 14 | BitgoValue | decimal(38,18) | YES | - | CODE-BACKED | Balance amount reported by BitGo custody provider during the verification phase. Initially 0 (set by CreateNewReportRun). Updated by UpdateReportRecords with the actual BitGo API response. NULL/0 until the verification phase processes this record. |
| 15 | BloxValue | decimal(38,18) | YES | - | CODE-BACKED | Balance amount reported by Blox portfolio tracker during the verification phase. Initially 0 (set by CreateNewReportRun). Updated by UpdateReportRecords with the actual Blox API response. NULL/0 until verification. |
| 16 | ErrorMsg | nvarchar(256) | YES | - | CODE-BACKED | Error message from the reconciliation verification phase. Contains API error details from BitGo or Blox when their endpoints fail. NULL when verification completes successfully. Set by UpdateReportRecords via the BalanceType TVP. |
| 17 | LevelId | int | YES | - | CODE-BACKED | FK to Dictionary.FinanceReportLevel classifying the reconciliation outcome. Initially set to 100 (InitialDiscrepancy) if balance exceeds threshold, NULL otherwise. Refined by UpdateReportRecords: 1=EventualyConsolidated, 2=AllDiff, 3=EtoroDiffBoth, 5-11=API errors, 12=InternalError. See [Finance Report Level](../../_glossary.md#finance-report-level). |
| 18 | Created | datetime2(7) | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when this record was inserted by CreateNewReportRun. Default constraint DF_FinanceReportRecords_Created. Indexed in ix_FinanceReportRecords__WalletId_CryptoId_Created (DESC) for efficient "latest record per wallet" lookups used by CreateNewReportRun's incremental processing. |
| 19 | LastChecked | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp of the most recent verification check for this record. NULL until the record is processed by UpdateReportRecords, which sets it to GETUTCDATE(). Used by CreateNewReportRun's incremental logic: `DATEDIFF(DAY, ISNULL(LastChecked, '2000-01-01'), GETUTCDATE()) >= @RetryDays` to determine if the record should be rechecked. |
| 20 | Retries | tinyint | YES | - | CODE-BACKED | Number of times this wallet-crypto pair has been re-verified. Set by UpdateReportRecords via the BalanceType TVP. NULL on initial creation; 0+ after verification. Used to track persistent discrepancies that don't resolve after multiple attempts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReportId | Wallet.FinanceReportRuns | FK (explicit) | Links each record to its parent reconciliation run. Constraint: FK__FinanceReportRecords__ReportId |
| LevelId | Dictionary.FinanceReportLevel | FK (explicit) | Classifies the reconciliation outcome. Constraint: FK__FinanceReportRecords__LevelId |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.CreateNewReportRun | INSERT/SELECT | Writer | Creates records from external table data during reconciliation runs |
| Wallet.UpdateReportRecords | UPDATE/DELETE | Modifier | Updates records with verified results; optionally prunes unchanged records |
| Wallet.GetFinanceReportRunDiscrepancies | SELECT | Reader | Reads discrepancies (LevelId=100) for a given run |
| Wallet.GetFinanceSnapshot | CROSS APPLY | Reader | Reads latest record per wallet for point-in-time snapshots |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.FinanceReportRecords (table)
+-- Wallet.FinanceReportRuns (table) [FK on ReportId]
+-- Dictionary.FinanceReportLevel (table) [FK on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReportRuns | Table | FK target for ReportId -- parent run |
| Dictionary.FinanceReportLevel | Table | FK target for LevelId -- reconciliation classification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CreateNewReportRun | Stored Procedure | WRITER - inserts records from external table data |
| Wallet.UpdateReportRecords | Stored Procedure | MODIFIER - updates with verified results, prunes unchanged |
| Wallet.GetFinanceReportRunDiscrepancies | Stored Procedure | READER - retrieves discrepancies for a run |
| Wallet.GetFinanceSnapshot | Stored Procedure | READER - reads latest record per wallet for snapshots |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FinanceReportRecords | CLUSTERED PK | Id ASC | - | - | Active |
| IX_FinanceReportRecords__ReportId_LevelId | NC | ReportId ASC, LevelId ASC | - | - | Active |
| IX_FinanceReportRecords__ReportId_WalletId_CryptoId | NC UNIQUE | ReportId ASC, WalletId ASC, CryptoId ASC | - | - | Active |
| ix_FinanceReportRecords__WalletId_CryptoId_Created | NC UNIQUE | WalletId ASC, CryptoId ASC, Created DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FinanceReportRecords | PRIMARY KEY | Clustered on Id. DATA_COMPRESSION = PAGE. |
| FK__FinanceReportRecords__ReportId | FOREIGN KEY | ReportId references Wallet.FinanceReportRuns(Id) |
| FK__FinanceReportRecords__LevelId | FOREIGN KEY | LevelId references Dictionary.FinanceReportLevel(Id) |
| DF_FinanceReportRecords_Created | DEFAULT | Created defaults to GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Get discrepancies for the latest run with level names
```sql
SELECT frr.Id, frr.WalletId, frr.CryptoId, frr.BloxBalance, frr.ComputedAmount,
       frr.BitgoValue, frr.BloxValue, frr.LevelId, l.Name AS LevelName, frr.Retries
FROM Wallet.FinanceReportRecords frr WITH (NOLOCK)
INNER JOIN Dictionary.FinanceReportLevel l WITH (NOLOCK) ON frr.LevelId = l.Id
WHERE frr.ReportId = (SELECT MAX(Id) FROM Wallet.FinanceReportRuns WITH (NOLOCK))
ORDER BY frr.LevelId, frr.Id;
```

### 8.2 Find the latest reconciliation record for a specific wallet
```sql
SELECT TOP 1 *
FROM Wallet.FinanceReportRecords WITH (NOLOCK)
WHERE WalletId = '749DB5AA-3724-47DA-A540-41D3DB8402DC'
  AND CryptoId = 64
ORDER BY Created DESC;
```

### 8.3 Discrepancy summary by level for the latest run
```sql
SELECT ISNULL(l.Name, 'No Discrepancy') AS LevelName, COUNT(*) AS RecordCount
FROM Wallet.FinanceReportRecords frr WITH (NOLOCK)
LEFT JOIN Dictionary.FinanceReportLevel l WITH (NOLOCK) ON frr.LevelId = l.Id
WHERE frr.ReportId = (SELECT MAX(Id) FROM Wallet.FinanceReportRuns WITH (NOLOCK))
GROUP BY l.Name
ORDER BY RecordCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.FinanceReportRecords | Type: Table | Source: WalletBalancesReportDB/Wallet/Tables/Wallet.FinanceReportRecords.sql*
