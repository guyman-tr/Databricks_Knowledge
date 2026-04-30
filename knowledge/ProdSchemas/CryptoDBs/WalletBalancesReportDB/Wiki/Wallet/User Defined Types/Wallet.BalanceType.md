# Wallet.BalanceType

> Table-valued parameter type used for batch-updating crypto wallet balance reconciliation results across report records.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | Composite: ReportId + WalletId + CryptoId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.BalanceType is a table-valued parameter (TVP) that carries batch reconciliation results from the application layer into SQL Server in a single call. Each row represents the reconciliation outcome for one wallet-crypto pair within a specific report run, including whether a discrepancy was found, what classification level applies, any error message, and the balance values from BitGo (custody) and Blox (portfolio tracker).

This type exists to enable efficient bulk updates. Without it, the application would need to issue individual UPDATE statements for each wallet-crypto combination per reconciliation run -- potentially thousands of calls per run. The TVP allows the application to pack all results into a single structured parameter and pass it to the stored procedure in one round-trip.

The application populates instances of this type after performing balance comparisons across eToro, BitGo, and Blox. The populated TVP is then passed to Wallet.UpdateReportRecord (which updates Wallet.FinanceReportsBalances) or Wallet.UpdateReportRecords (which updates Wallet.FinanceReportRecords and optionally prunes unchanged records). Both procedures JOIN the TVP to the target table on (ReportId, WalletId, CryptoId) to apply the reconciliation results.

---

## 2. Business Logic

### 2.1 Batch Reconciliation Result Delivery

**What**: A structured container for delivering reconciliation outcomes from the application to the database in bulk.

**Columns/Parameters Involved**: `ReportId`, `WalletId`, `CryptoId`, `FindDiscrepancy`, `LevelId`, `BitgoValue`, `BloxValue`, `ErrorMsg`, `Retries`

**Rules**:
- Each row uniquely identifies a wallet-crypto pair within a report run via (ReportId, WalletId, CryptoId)
- FindDiscrepancy indicates whether the balance comparison found a mismatch (1) or not (0)
- LevelId classifies the reconciliation outcome using the Dictionary.FinanceReportLevel lookup (values 1-12, 100)
- BitgoValue and BloxValue capture the actual balance amounts from each external provider at the time of reconciliation
- ErrorMsg captures any API or processing error encountered during the comparison
- Retries tracks how many times this specific wallet-crypto pair has been re-checked

**Diagram**:
```
Application (balance comparison engine)
       |
       | Populates Wallet.BalanceType TVP
       | (one row per wallet-crypto pair)
       |
       v
  +-----------------------------+
  | Wallet.UpdateReportRecord   |  --> Updates Wallet.FinanceReportsBalances
  +-----------------------------+
  | Wallet.UpdateReportRecords  |  --> Updates Wallet.FinanceReportRecords
  +-----------------------------+
       |
       | JOINs on (ReportId, WalletId, CryptoId)
       | SETs: FindDiscrepancy, LevelId, ErrorMsg,
       |       BitgoValue, BloxValue, Retries
       v
  Target table rows updated in bulk
```

---

## 3. Data Overview

N/A for User Defined Type. This is a parameter type -- it holds transient data during procedure execution and is not persisted.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReportId | bigint | NO | - | CODE-BACKED | Identifies which reconciliation report run these results belong to. Used as a JOIN key to match against target table rows. References Wallet.FinanceReportRuns.Id (via FinanceReportRecords) or Wallet.FinanceReports.Id (via FinanceReportsBalances). |
| 2 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | The crypto wallet's unique identifier (GUID). Together with ReportId and CryptoId, forms the composite key for matching against target table rows during bulk updates. |
| 3 | CryptoId | int | NO | - | CODE-BACKED | Identifies the cryptocurrency asset within the wallet. Together with ReportId and WalletId, completes the three-part key for row matching. Values reference an external crypto asset catalog (not defined in this database). |
| 4 | FindDiscrepancy | bit | NO | - | CODE-BACKED | Whether the reconciliation detected a balance mismatch: 1 = discrepancy found between systems, 0 = balances match or within threshold. Set by the application after comparing eToro, BitGo, and Blox balances. |
| 5 | LevelId | int | NO | - | CODE-BACKED | Classification of the reconciliation outcome. References Dictionary.FinanceReportLevel: 1=EventualyConsolidated, 2=AllDiff, 3=EtoroDiffBoth, 5=BitgoError, 6=BloxError, 7=InvalidBloxAccount, 100=InitialDiscrepancy. See [Finance Report Level](../../_glossary.md#finance-report-level) for full definitions. |
| 6 | ErrorMsg | nvarchar(256) | YES | - | CODE-BACKED | Error message captured when the reconciliation for this wallet-crypto pair fails. Contains API error details from BitGo or Blox, or internal processing errors. NULL when reconciliation completes without errors. |
| 7 | BitgoValue | decimal(20,8) | YES | - | CODE-BACKED | Balance amount reported by the BitGo custody provider for this wallet-crypto pair. NULL if the BitGo API call failed (LevelId 5, 9, 10). Used to update the target table's BitgoValue column for comparison tracking. |
| 8 | BloxValue | decimal(20,8) | YES | - | CODE-BACKED | Balance amount reported by the Blox portfolio tracker for this wallet-crypto pair. NULL if the Blox API call failed (LevelId 6, 8, 11). Used to update the target table's BloxValue column for comparison tracking. |
| 9 | Retries | tinyint | YES | - | CODE-BACKED | Number of times this wallet-crypto pair has been re-checked in reconciliation attempts. Incremented by the application on each retry. NULL on first attempt. Used to track persistence of discrepancies and trigger escalation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LevelId | Dictionary.FinanceReportLevel | Lookup | Classifies the reconciliation outcome for each wallet-crypto pair |
| ReportId | Wallet.FinanceReportRuns / Wallet.FinanceReports | Implicit | Identifies the parent report run; target depends on which consumer SP is called |
| WalletId | (external - WalletDB) | Implicit | References a crypto wallet defined in the WalletDB system |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.UpdateReportRecord | @BalanceUpdates | Parameter (TVP) | Receives batch reconciliation results to update Wallet.FinanceReportsBalances |
| Wallet.UpdateReportRecords | @BalanceUpdates | Parameter (TVP) | Receives batch reconciliation results to update Wallet.FinanceReportRecords |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.UpdateReportRecord | Stored Procedure | Accepts as READONLY TVP parameter for bulk-updating FinanceReportsBalances |
| Wallet.UpdateReportRecords | Stored Procedure | Accepts as READONLY TVP parameter for bulk-updating FinanceReportRecords |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type. TVPs do not support persistent indexes; consuming procedures create temp indexes after materializing the data.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOT NULL on ReportId, WalletId, CryptoId, FindDiscrepancy, LevelId | Column constraint | Core identification and result fields are mandatory -- every batch row must have a complete key and reconciliation outcome |
| COLLATE SQL_Latin1_General_CP1_CI_AS on ErrorMsg | Collation | Explicit collation ensures error messages are case-insensitive and compatible with the database collation |

---

## 8. Sample Queries

### 8.1 Declare and populate a BalanceType variable
```sql
DECLARE @Updates Wallet.BalanceType;

INSERT INTO @Updates (ReportId, WalletId, CryptoId, FindDiscrepancy, LevelId, ErrorMsg, BitgoValue, BloxValue, Retries)
VALUES
    (12345, 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890', 1, 1, 100, NULL, 1.50000000, 1.49000000, 0),
    (12345, 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890', 2, 0, NULL, NULL, 0.00500000, 0.00500000, NULL);
```

### 8.2 Pass to UpdateReportRecords for bulk update
```sql
DECLARE @Updates Wallet.BalanceType;
-- (populate @Updates as above)

EXEC Wallet.UpdateReportRecords @BalanceUpdates = @Updates;
```

### 8.3 Inspect TVP contents with level names before calling the procedure
```sql
DECLARE @Updates Wallet.BalanceType;
-- (populate @Updates)

SELECT u.ReportId, u.WalletId, u.CryptoId, u.FindDiscrepancy,
       u.LevelId, l.Name AS LevelName,
       u.BitgoValue, u.BloxValue, u.Retries, u.ErrorMsg
FROM @Updates u
LEFT JOIN Dictionary.FinanceReportLevel l WITH (NOLOCK) ON u.LevelId = l.Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.1/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.BalanceType | Type: User Defined Type | Source: WalletBalancesReportDB/Wallet/User Defined Types/Wallet.BalanceType.sql*
