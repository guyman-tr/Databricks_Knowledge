# Wallet.AddReport

> Inserts a single wallet-crypto balance reconciliation record into the legacy FinanceReportsBalances table with pre-computed values from the application.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReportId + @WalletId + @CryptoId composite key |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.AddReport is a single-row INSERT procedure for the legacy reconciliation system. It adds one wallet-crypto balance record directly into Wallet.FinanceReportsBalances with all reconciliation values pre-computed by the application (balances, discrepancy flag, classification level, error message). This contrasts with the bulk-INSERT approach used by Wallet.CreateNewReports, which inserts all wallet records in a batch from the external table.

This procedure exists to support individual record insertion scenarios in the legacy reconciliation pipeline -- likely used for retries, manual corrections, or adding records that were missed in the bulk run. Its counterpart in the current system is Wallet.UpdateReportRecords (which uses the BalanceType TVP for bulk operations instead of individual calls).

The application provides all 15 parameter values and the procedure performs a straightforward INSERT with no business logic, no validation, and no transaction management. The @LevelId and @ErrorMsg parameters have NULL defaults, allowing insertion of clean records (no discrepancy) without specifying those values.

---

## 2. Business Logic

### 2.1 Direct Record Insertion (No Computation)

**What**: A pass-through INSERT that accepts all column values from the caller -- no server-side computation, threshold checking, or classification logic.

**Columns/Parameters Involved**: All 15 parameters

**Rules**:
- Unlike Wallet.CreateNewReports (which computes LevelId from threshold comparison), AddReport trusts the caller to provide the correct LevelId
- The @LevelId parameter defaults to NULL, meaning clean records (no discrepancy) don't need to specify a classification
- The @ErrorMsg parameter defaults to NULL for successful reconciliations
- No transaction wrapping -- the INSERT either succeeds or fails atomically on its own
- No duplicate checking -- calling with the same @ReportId + @WalletId + @CryptoId that already exists will fail on the unique index IX_FinanceReportsBalances_ReportId_WalletId_CryptoId

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReportId | bigint | NO | - | CODE-BACKED | FK to Wallet.FinanceReports.Id identifying the parent legacy reconciliation run this record belongs to. |
| 2 | @WalletId | uniqueidentifier | NO | - | CODE-BACKED | Crypto wallet identifier (GUID). Part of the composite business key (ReportId, WalletId, CryptoId). |
| 3 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID -- identifies the wallet owner. Denormalized for efficient customer-level querying. |
| 4 | @CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency asset identifier. Completes the composite business key with WalletId and ReportId. |
| 5 | @Address | nvarchar(100) | NO | - | CODE-BACKED | Blockchain address for this wallet-crypto pair. Truncated to 100 chars (vs 512 in the table) -- may lose data for long addresses. |
| 6 | @BitgoWalletId | nvarchar(100) | NO | - | CODE-BACKED | BitGo custody platform's wallet identifier for cross-referencing during discrepancy investigation. |
| 7 | @TotalReceive | decimal(20,8) | NO | - | CODE-BACKED | Total received amount for this wallet-crypto pair from blockchain data. Lower precision (20,8) than the table column (38,18) -- adequate for most balances but may lose precision for very large or very small amounts. |
| 8 | @TotalSend | decimal(20,8) | NO | - | CODE-BACKED | Total sent amount for this wallet-crypto pair from blockchain data. |
| 9 | @BloxBalance | decimal(20,8) | NO | - | CODE-BACKED | Blockchain-reported net balance (despite the name, this is the on-chain balance, not the Blox provider balance). |
| 10 | @ComputedAmount | decimal(20,8) | NO | - | CODE-BACKED | eToro ledger's internally computed expected balance. Compared against BloxBalance for discrepancy detection. |
| 11 | @FindDiscrepancy | int | NO | - | CODE-BACKED | Whether reconciliation found a balance mismatch. Stored as INT parameter but the target column is BIT -- SQL Server auto-converts non-zero to 1. 0 = no discrepancy, non-zero = discrepancy found. |
| 12 | @BitgoValue | decimal(20,8) | NO | - | CODE-BACKED | Actual balance from BitGo custody provider's API. 0 if not yet verified or if BitGo API was not queried. |
| 13 | @BloxValue | decimal(20,8) | NO | - | CODE-BACKED | Actual balance from Blox portfolio tracker's API. 0 if not yet verified or if Blox API was not queried. |
| 14 | @LevelId | int | YES | NULL | CODE-BACKED | Classification of the reconciliation outcome. References Dictionary.FinanceReportLevel: 1=EventualyConsolidated, 2=AllDiff, 3=EtoroDiffBoth, 5-11=API errors, 100=InitialDiscrepancy. NULL for clean records with no discrepancy. See [Finance Report Level](../../_glossary.md#finance-report-level). |
| 15 | @ErrorMsg | nvarchar(250) | YES | NULL | CODE-BACKED | Error message from reconciliation verification. Contains API error details from BitGo or Blox. NULL when reconciliation completes without errors. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ReportId | Wallet.FinanceReports | Implicit FK | Identifies the parent legacy run (no explicit FK due to partitioning on target table) |
| @LevelId | Dictionary.FinanceReportLevel | Implicit FK | Classifies the reconciliation outcome |
| (INSERT) | Wallet.FinanceReportsBalances | WRITER | Target table for the INSERT operation |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Was called by the application layer for individual record insertion.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddReport (procedure)
+-- Wallet.FinanceReportsBalances (table)
    +-- Wallet.FinanceReports (table) [implicit ref on ReportId]
    +-- Dictionary.FinanceReportLevel (table) [implicit ref on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReportsBalances | Table | INSERT INTO - inserts a single reconciliation result record |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Insert a clean record (no discrepancy)
```sql
EXEC Wallet.AddReport
    @ReportId = 2141,
    @WalletId = '749DB5AA-3724-47DA-A540-41D3DB8402DC',
    @Gcid = 12345678,
    @CryptoId = 64,
    @Address = '0xAbC123...',
    @BitgoWalletId = 'bitgo-wallet-001',
    @TotalReceive = 10.50000000,
    @TotalSend = 2.30000000,
    @BloxBalance = 8.20000000,
    @ComputedAmount = 8.20000000,
    @FindDiscrepancy = 0,
    @BitgoValue = 8.20000000,
    @BloxValue = 8.20000000;
```

### 8.2 Insert a discrepancy record
```sql
EXEC Wallet.AddReport
    @ReportId = 2141,
    @WalletId = 'B4EDCB68-1234-5678-ABCD-EF1234567890',
    @Gcid = 87654321,
    @CryptoId = 21,
    @Address = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
    @BitgoWalletId = 'bitgo-wallet-002',
    @TotalReceive = 100.00000000,
    @TotalSend = 50.00000000,
    @BloxBalance = 50.00000000,
    @ComputedAmount = 48.50000000,
    @FindDiscrepancy = 1,
    @BitgoValue = 50.00000000,
    @BloxValue = 50.00000000,
    @LevelId = 3,
    @ErrorMsg = NULL;
```

### 8.3 Verify the inserted record
```sql
SELECT TOP 1 *
FROM Wallet.FinanceReportsBalances WITH (NOLOCK)
WHERE ReportId = 2141
  AND WalletId = '749DB5AA-3724-47DA-A540-41D3DB8402DC'
  AND CryptoId = 64
ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddReport | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.AddReport.sql*
