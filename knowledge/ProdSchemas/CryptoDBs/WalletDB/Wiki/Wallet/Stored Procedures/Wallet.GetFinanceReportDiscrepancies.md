# Wallet.GetFinanceReportDiscrepancies

> Retrieves balance discrepancies between BitGo and Blox wallet systems for the most recent finance reconciliation report.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns discrepancy rows with amount, wallet, crypto, and provider |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies mismatches between BitGo (blockchain custody provider) and Blox (internal accounting/balance tracking system) for the latest finance reconciliation report. Each row returned represents a wallet where the balance recorded by BitGo differs from the balance recorded by Blox, ordered by the largest discrepancy first. This is a critical reconciliation tool that helps the finance team detect and investigate balance drift between the two systems.

Without this procedure, the finance team would have no automated way to detect discrepancies between external custody balances and internal accounting records. Balance mismatches can indicate missed transactions, failed syncs, double-counted transfers, or more serious issues like unauthorized movements.

Data flows from an external table `Wallet.FinanceReportRecords` (sourced from the `WalletBalancesReportDB` via elastic query), joined with `Wallet.CryptoTypes` for crypto names, `Wallet.CustomerWalletsView` to resolve BitGo wallet IDs to internal wallet records, and `Dictionary.WalletProvider` for provider names. The procedure is parameterless - it always returns discrepancies from the most recent report (MAX ReportId).

---

## 2. Business Logic

### 2.1 Discrepancy Detection

**What**: Identifies wallets where the BitGo-reported balance differs from the Blox-reported balance.

**Columns/Parameters Involved**: `BitgoValue`, `BloxValue`, `LevelId`, `ReportId`

**Rules**:
- A discrepancy exists when `BitgoValue != BloxValue` - any non-zero difference is flagged
- Only records with a non-NULL `LevelId` are included (records without a level assignment are excluded from reconciliation)
- Only the most recent report is analyzed (`ReportId = MAX(ReportId)`)
- Results are ordered by absolute discrepancy amount descending, so the largest mismatches appear first for priority investigation

**Diagram**:
```
FinanceReportRecords (External - WalletBalancesReportDB)
    |
    |-- Filter: BitgoValue != BloxValue AND LevelId IS NOT NULL
    |-- Filter: ReportId = MAX(ReportId) [latest report only]
    |
    +-- JOIN CryptoTypes ON CryptoID -> CryptoName
    +-- JOIN CustomerWalletsView ON BitgoWalletId -> internal wallet context
    +-- JOIN WalletProvider ON WalletProviderId -> ProviderName
    |
    v
Result: DiscrepancyAmount (DESC), WalletId, CryptoName, ProviderName
```

### 2.2 Cross-System Reconciliation Architecture

**What**: The procedure bridges an external data source (WalletBalancesReportDB) with internal wallet metadata.

**Columns/Parameters Involved**: `BitgoWalletId`, `CryptoID`, `WalletProviderId`

**Rules**:
- `Wallet.FinanceReportRecords` is an EXTERNAL TABLE using elastic database query against `WalletBalancesReportDB` - the report data lives in a separate database
- The join to `CustomerWalletsView` via `BlockchainProviderWalletId = BitgoWalletId` resolves the external BitGo wallet identifier to the internal wallet record
- The compound join condition (`WalletProviderId = wp.Id AND CryptoID = cwv.CryptoID`) ensures the provider is matched for the correct crypto asset

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DiscrepancyAmount | decimal(38,18) | YES | - | CODE-BACKED | Absolute difference between BitGo and Blox balances: `ABS(BitgoValue - BloxValue)`. Represents the magnitude of the balance mismatch in the native crypto unit. Larger values indicate more significant reconciliation issues requiring priority investigation. |
| 2 | WalletId | nvarchar(100) | YES | - | CODE-BACKED | The BitGo wallet identifier (`BitgoWalletId` from FinanceReportRecords). This is the external custody provider's wallet ID, not the internal WalletDB wallet GUID. Used to identify which specific BitGo wallet has the discrepancy. |
| 3 | CryptoName | varchar(50) | NO | - | CODE-BACKED | Human-readable cryptocurrency name from `Wallet.CryptoTypes`. Resolves the numeric CryptoID to a name (e.g., "Bitcoin", "Ethereum") for report readability. |
| 4 | ProviderName | varchar(64) | NO | - | CODE-BACKED | Wallet custody provider name from `Dictionary.WalletProvider`: 1=Bitgo, 2=CUG, 3=None. Identifies which provider manages the wallet with the discrepancy. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoID | Wallet.CryptoTypes | JOIN | Resolves CryptoID to crypto name for report readability |
| BitgoWalletId | Wallet.CustomerWalletsView | JOIN | Maps external BitGo wallet ID to internal wallet records via BlockchainProviderWalletId |
| WalletProviderId | Dictionary.WalletProvider | JOIN | Resolves provider ID to provider name (Bitgo, CUG, None) |
| - | Wallet.FinanceReportRecords | External Table | Primary data source - external table querying WalletBalancesReportDB via elastic query |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. This procedure is likely called by external reporting tools or scheduled jobs outside the database layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetFinanceReportDiscrepancies (procedure)
+-- Wallet.FinanceReportRecords (external table)
+-- Wallet.CryptoTypes (table)
+-- Wallet.CustomerWalletsView (view)
|     +-- Wallet.Wallets (table)
|     +-- Wallet.WalletAddresses (table)
|     +-- Wallet.WalletBalances (table)
|     +-- Wallet.BlockchainCryptoProviders (table)
+-- Dictionary.WalletProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReportRecords | External Table | FROM - primary data source for report records |
| Wallet.CryptoTypes | Table | INNER JOIN on CryptoID - crypto name resolution |
| Wallet.CustomerWalletsView | View | INNER JOIN on BitgoWalletId - wallet metadata resolution |
| Dictionary.WalletProvider | Table | INNER JOIN on WalletProviderId - provider name resolution |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure to view current discrepancies
```sql
EXEC Wallet.GetFinanceReportDiscrepancies;
```

### 8.2 Find discrepancies for a specific crypto by wrapping the result
```sql
SELECT * FROM (
    SELECT ABS(frb.BitgoValue - frb.BloxValue) AS DiscrepancyAmount,
           frb.BitgoWalletId AS WalletId,
           ct.Name AS CryptoName,
           wp.Name AS ProviderName
    FROM Wallet.FinanceReportRecords frb WITH (NOLOCK)
        INNER JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON frb.CryptoID = ct.CryptoID
        INNER JOIN Wallet.CustomerWalletsView cwv WITH (NOLOCK) ON cwv.BlockchainProviderWalletId = frb.BitgoWalletId
        INNER JOIN Dictionary.WalletProvider wp WITH (NOLOCK) ON cwv.WalletProviderId = wp.Id AND frb.CryptoID = cwv.CryptoID
    WHERE frb.BitgoValue != frb.BloxValue
        AND frb.LevelId IS NOT NULL
        AND frb.ReportId = (SELECT MAX(f.ReportId) FROM Wallet.FinanceReportRecords f WITH (NOLOCK))
) discrepancies
WHERE CryptoName = 'Bitcoin'
ORDER BY DiscrepancyAmount DESC;
```

### 8.3 Check the latest report ID and total record count
```sql
SELECT MAX(ReportId) AS LatestReportId,
       COUNT(*) AS TotalRecords,
       SUM(CASE WHEN BitgoValue != BloxValue AND LevelId IS NOT NULL THEN 1 ELSE 0 END) AS DiscrepancyCount
FROM Wallet.FinanceReportRecords WITH (NOLOCK)
WHERE ReportId = (SELECT MAX(ReportId) FROM Wallet.FinanceReportRecords WITH (NOLOCK));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetFinanceReportDiscrepancies | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetFinanceReportDiscrepancies.sql*
