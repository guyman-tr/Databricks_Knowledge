# History.FinanceReportsBalances

> Archive table storing historical snapshots of crypto wallet balance reconciliation results, preserving each report run's comparison of eToro, BitGo, and Blox balances for audit and trend analysis.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: ReportId + Id + Occurred (BIGINT + BIGINT + DATETIME2, CLUSTERED) |
| **Partition** | Yes - DatesToFilegroup(Occurred), monthly partitions (DatePartitionFunctionByMonth, RIGHT boundary, 254 partitions from 2019-01 to 2040-01) |
| **Indexes** | 2 (1 clustered PK + 1 nonclustered) |

---

## 1. Business Meaning

History.FinanceReportsBalances is the long-term archive of crypto wallet balance reconciliation results. Each row represents one wallet's balance snapshot taken during a specific reconciliation report run, recording balances as reported by three independent systems: eToro's internal ledger (ComputedAmount), BitGo custody provider (BitgoValue), and Blox portfolio tracker (BloxBalance/BloxValue). The table captures whether these three sources agreed, and if not, what type of discrepancy was detected.

This table exists because reconciliation data must be retained for audit, compliance, and trend analysis long after the active reconciliation cycle completes. Without this archive, the operations team would lose visibility into historical balance discrepancy patterns across wallets and cryptocurrencies. The table enables retroactive analysis of reconciliation reliability, identification of wallets with recurring discrepancies, and evidence for financial audits.

Data originates in the active Wallet.FinanceReportsBalances table, where the reconciliation engine creates rows during each report run via Wallet.CreateNewReports or Wallet.GetWalletBalanceReport. The reconciliation application then enriches each row by calling external APIs (BitGo, Blox) and updating BitgoValue, BloxValue, FindDiscrepancy, LevelId, and ErrorMsg via Wallet.UpdateReportRecord. After the active data reaches a retention threshold, partitions are switched from Wallet.FinanceReportsBalances to History.FinanceReportsBalances using the shared partition scheme (DatesToFilegroup). No stored procedures in this database directly reference the History table - archival is managed via partition switch operations at the infrastructure level. The table contains data spanning April 2019 through December 2022 across approximately 876 million rows.

---

## 2. Business Logic

### 2.1 Crypto Wallet Balance Reconciliation

**What**: A three-way comparison process that verifies crypto wallet balances across eToro's internal ledger, BitGo custody, and Blox portfolio tracking to detect discrepancies.

**Columns/Parameters Involved**: `ComputedAmount`, `BloxBalance`, `BitgoValue`, `BloxValue`, `TotalReceive`, `TotalSend`, `FindDiscrepancy`, `LevelId`

**Rules**:
- The reconciliation engine fetches wallet data from WalletDB via the external table Wallet.vu_GetWalletBalanceReport. TotalReceive and TotalSend come from blockchain transaction totals, BloxBalance from Blox's running balance, and ComputedAmount from eToro's computed expected amount.
- On initial insertion, FindDiscrepancy is set to 0 (false), and BitgoValue/BloxValue are set to 0. LevelId is set to 100 (InitialDiscrepancy) if `ABS(ComputedAmount - BloxBalance) > @Threshold` OR either value is negative. Otherwise LevelId is NULL (no discrepancy).
- The application then calls BitGo and Blox APIs for wallets flagged with LevelId=100, updating BitgoValue, BloxValue, and refining LevelId to a specific classification (1-12) from Dictionary.FinanceReportLevel.

**Diagram**:
```
External View (WalletDB)          Reconciliation Engine          History Archive
         |                                 |                           |
         v                                 v                           v
  vu_GetWalletBalanceReport    CreateNewReports / GetWalletBalanceReport
  [TotalRecive, TotalSend,     [INSERT into Wallet.FinanceReportsBalances]
   TotalBalance, TotalAmount]   FindDiscrepancy=0, BitgoValue=0, BloxValue=0
         |                      LevelId = 100 if |Amount-Balance| > threshold
         |                                 |
         |                     GetFinanceReportDiscrepancies
         |                     [SELECT WHERE LevelId=100]
         |                                 |
         |                     Application calls BitGo + Blox APIs
         |                                 |
         |                     UpdateReportRecord
         |                     [UPDATE FindDiscrepancy, LevelId(1-12),
         |                      BitgoValue, BloxValue, ErrorMsg]
         |                                 |
         |                     Partition Switch (DBA/Infrastructure)
         |                     [Wallet.FinanceReportsBalances -> History.FinanceReportsBalances]
```

### 2.2 Discrepancy Classification Lifecycle

**What**: Each balance record transitions through a classification lifecycle from unclassified to specifically categorized based on which systems agree and which APIs respond.

**Columns/Parameters Involved**: `LevelId`, `FindDiscrepancy`, `ErrorMsg`

**Rules**:
- **Initial state (on INSERT)**: LevelId=NULL means balances are within threshold (no discrepancy). LevelId=100 means initial discrepancy detected, pending detailed classification.
- **After API verification**: LevelId is refined to 1-12 based on the reconciliation outcome. See [Finance Report Level](../../_glossary.md#finance-report-level) for the full classification tree.
- **Error handling**: If BitGo or Blox APIs fail, LevelId is set to an error-specific value (5-11) and ErrorMsg captures the error details.
- FindDiscrepancy is updated from 0 to 1 when a true discrepancy is confirmed after API verification.

**Diagram**:
```
INSERT                                API Verification
  |                                         |
  v                                         v
LevelId=NULL ------(no action)-------> Stays NULL (balanced)
LevelId=100 -------(APIs called)-----> LevelId=1  (eventually consolidated)
                                    -> LevelId=2  (all three differ)
                                    -> LevelId=3  (eToro differs, BitGo/Blox agree)
                                    -> LevelId=4  (multiple addresses)
                                    -> LevelId=5  (BitGo API error)
                                    -> LevelId=6  (Blox API error)
                                    -> LevelId=7  (invalid Blox account)
                                    -> LevelId=8-11 (mixed error + comparison)
                                    -> LevelId=12 (internal/unclassifiable error)
                                    -> LevelId=100 (still unresolved)
```

### 2.3 Wallet Identity and Provider Mapping

**What**: Each row uniquely identifies a crypto wallet by its internal identifiers (WalletId, Gcid, CryptoId) and maps it to external provider accounts (BitgoWalletId for custody, BloxAccountId for portfolio tracking, Address for blockchain).

**Columns/Parameters Involved**: `WalletId`, `Gcid`, `CryptoId`, `Address`, `BitgoWalletId`, `BloxAccountId`

**Rules**:
- WalletId is the internal unique wallet identifier within eToro's crypto wallet system.
- Gcid is the global customer ID that owns the wallet.
- CryptoId identifies the cryptocurrency type (e.g., 1=Bitcoin, 2=Ethereum, 3=Bitcoin Cash, 6=Litecoin, 21=Stellar). This is an external reference - no lookup table exists in this database.
- Address is the blockchain address (format varies by crypto: BTC uses base58/bech32, ETH uses 0x-prefixed hex, XLM uses uppercase alphanumeric).
- A single customer (Gcid) can have multiple wallets across different cryptocurrencies and blockchain addresses.

---

## 3. Data Overview

| Id | ReportId | CryptoId | Address | FindDiscrepancy | LevelId | Meaning |
|----|----------|----------|---------|-----------------|---------|---------|
| 1 | 2 | 1 | 33sspWr1Q29h4XEtyjzqf2wYcNJbtZYwvN | false | NULL | Bitcoin wallet with zero balance on all three systems - reconciled with no discrepancy. Common for inactive wallets included in full report sweeps. |
| 4 | 2 | 2 | 0x53ecdfe8bf8113993d388c7bfad0daaa0c792e99 | false | NULL | Ethereum wallet with 0.1 received/balanced across sources (TotalReceive=BloxBalance=ComputedAmount=0.1). Clean reconciliation with small active balance. |
| 8 | 2 | 21 | GCT5W4Q4MCFIHJM46IB34CANX74YKZTD5L4CXFWXNLEQWJN5GUPT5IYE | false | NULL | Stellar (XLM) wallet with no BloxAccountId mapping - Blox did not have a tracked account for this wallet. Zero balance reconciled cleanly despite missing Blox integration. |
| 6 | 2 | 6 | MCnT43PSBUUrBkZA5Bb3dQwZZ1AY4vHXym | false | NULL | Litecoin wallet with zero balance. Address format (M-prefix) indicates a P2SH-SegWit Litecoin address. Part of report run #2 alongside other crypto types. |
| 2 | 2 | 3 | 3PCQv9tgS9RVRagq84pefMn4xoEW8oswnQ | false | NULL | Bitcoin Cash wallet with zero balance. All sampled rows belong to the earliest report run (ReportId=2, April 2019), representing the initial deployment of the reconciliation system. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key for each balance record within the partition. Part of the composite PK (ReportId, Id, Occurred). Not globally unique across partitions - uniqueness is guaranteed by the composite key. |
| 2 | ReportId | bigint | NO | - | CODE-BACKED | References the parent reconciliation report run (Wallet.FinanceReports.Id). All balance records from the same report share this value. Created by Wallet.CreateNewReports which inserts into Wallet.FinanceReports first, then uses the generated Id as ReportId for all balance rows in the batch. Indexed separately (IX_FinanceReportBalances_ReportId) for report-level queries. |
| 3 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | Internal unique identifier for the crypto wallet within eToro's wallet management system. Sourced from Wallet.vu_GetWalletBalanceReport (external table to WalletDB). Combined with CryptoId, identifies a specific crypto holding for reconciliation. |
| 4 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID - the eToro customer who owns this wallet. Sourced from the external view. A single customer can have multiple wallets across different cryptocurrencies. Used to trace reconciliation discrepancies back to specific customer accounts. |
| 5 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency type identifier. No lookup table exists in WalletBalancesReportDB - this is an external reference to WalletDB's crypto definition. Known values from data: 1=Bitcoin (BTC), 2=Ethereum (ETH), 3=Bitcoin Cash (BCH), 6=Litecoin (LTC), 21=Stellar (XLM). Determines blockchain address format and which custody/tracking integrations apply. |
| 6 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain wallet address where the crypto is held. Format varies by CryptoId: BTC uses base58 (3-prefix for P2SH), ETH uses 0x-prefixed hex, XLM uses uppercase alphanumeric, LTC uses M-prefix for P2SH-SegWit. Nullable for wallets without a direct blockchain address. Sourced from the external view. |
| 7 | BitgoWalletId | nvarchar(100) | NO | - | CODE-BACKED | BitGo custody provider wallet identifier. A hex string (e.g., "5bbf1d30d92c3fe0063a1fa0e26a84d0") that uniquely identifies this wallet in BitGo's custody system. Used by the reconciliation application to call the BitGo API for balance verification during the discrepancy resolution phase. |
| 8 | BloxAccountId | nvarchar(50) | YES | - | NAME-INFERRED | Blox portfolio tracking account identifier. Numeric string (e.g., "164468") that maps this wallet to Blox's tracking system. NULL when no Blox account exists for the wallet (observed for CryptoId=21/Stellar). Not present in the external view or INSERT procedures - likely populated via a separate mapping or update process. |
| 9 | TotalReceive | decimal(20,8) | YES | - | CODE-BACKED | Total amount of cryptocurrency received by this wallet address across all blockchain transactions. Sourced from the external view's TotalRecive field (note: typo in source). Represents cumulative inbound transfers in the cryptocurrency's native unit (e.g., BTC for Bitcoin). Used alongside TotalSend to calculate the expected on-chain balance. |
| 10 | TotalSend | decimal(20,8) | YES | - | CODE-BACKED | Total amount of cryptocurrency sent from this wallet address across all blockchain transactions. Sourced from the external view. Combined with TotalReceive, the difference (TotalReceive - TotalSend) should equal the on-chain balance. |
| 11 | BloxBalance | decimal(20,8) | YES | - | CODE-BACKED | Balance as reported by the Blox portfolio tracking system. Sourced from the external view's TotalBalance field. Represents Blox's view of the wallet's current holding. Compared against ComputedAmount (eToro's view) to detect discrepancies - if `ABS(ComputedAmount - BloxBalance) > @Threshold`, the record is flagged with LevelId=100. |
| 12 | ComputedAmount | decimal(20,8) | YES | - | CODE-BACKED | eToro's computed expected balance for this wallet. Sourced from the external view's TotalAmount field (with ABS() applied in some code paths). Represents the internal ledger's view of what the wallet should hold. This is the "eToro number" in the three-way reconciliation: discrepancies where BitGo and Blox agree but ComputedAmount differs (LevelId=3, EtoroDiffBoth) indicate an internal booking issue. |
| 13 | FindDiscrepancy | bit | NO | - | CODE-BACKED | Whether a confirmed balance discrepancy exists for this wallet in this report run. Set to 0 (false) on initial INSERT by Wallet.CreateNewReports. Updated to 1 (true) by Wallet.UpdateReportRecord after the reconciliation application confirms a discrepancy via API verification. When false with LevelId=NULL, the wallet is fully reconciled. When false with LevelId=100, the wallet is flagged but API verification has not yet run. |
| 14 | BitgoValue | decimal(20,8) | YES | - | CODE-BACKED | Balance as reported by the BitGo custody API. Set to 0 on initial INSERT (before API call). Updated by Wallet.UpdateReportRecord with the actual BitGo balance after the reconciliation application queries the BitGo API. Compared against BloxValue and ComputedAmount to determine the LevelId classification. A value of 0 may indicate either the API has not been called yet or the wallet truly has zero custody balance. |
| 15 | BloxValue | decimal(20,8) | YES | - | CODE-BACKED | Balance as reported by the Blox API during the reconciliation verification phase. Set to 0 on initial INSERT. Updated by Wallet.UpdateReportRecord after querying the Blox API. Distinct from BloxBalance (which comes from the external view at report creation time) - BloxValue is the API-verified balance captured during active reconciliation. |
| 16 | ErrorMsg | nvarchar(256) | YES | - | CODE-BACKED | Error message captured when the reconciliation application encounters an API failure during the BitGo or Blox balance verification call. NULL when no error occurred. Populated by Wallet.UpdateReportRecord alongside an error-specific LevelId (5-11). Contains the raw error description to aid troubleshooting. |
| 17 | LevelId | int | YES | - | CODE-BACKED | Reconciliation outcome classification referencing Dictionary.FinanceReportLevel. NULL = balances within threshold (no discrepancy). 100 = initial discrepancy flagged (|ComputedAmount - BloxBalance| > threshold or negative amount), pending API verification. 1-12 = specific classification after API verification. Set to NULL or 100 on INSERT by Wallet.CreateNewReports based on threshold comparison. Refined to 1-12 by Wallet.UpdateReportRecord. See [Finance Report Level](../../_glossary.md#finance-report-level) for full value definitions. |
| 18 | Occurred | datetime2(7) | NO | - | CODE-BACKED | Timestamp of when the balance record was created. Serves as the partition column for the DatesToFilegroup monthly partition scheme. In the active table (Wallet.FinanceReportsBalances), defaults to GETUTCDATE(). In the History table, preserves the original creation timestamp from the active table after partition switch. Enables time-based partition elimination for queries spanning specific date ranges. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReportId | Wallet.FinanceReports | Implicit FK | Links each balance record to its parent reconciliation report run. Wallet.FinanceReports stores the StartTime and EndTime of each report execution. |
| LevelId | Dictionary.FinanceReportLevel | Implicit FK | Classifies the reconciliation outcome. NULL means no discrepancy, 100 means initial discrepancy, 1-12 are specific outcome categories. See [Finance Report Level](../../_glossary.md#finance-report-level). |
| CryptoId | External (WalletDB) | External Reference | Identifies the cryptocurrency type. No lookup table exists in WalletBalancesReportDB - the definition resides in WalletDB. |
| WalletId | External (WalletDB) | External Reference | References the wallet entity in WalletDB's wallet management system. |
| Gcid | External (Customer system) | External Reference | References the global customer identifier from eToro's customer system. |

### 5.2 Referenced By (other objects point to this)

No objects in this database directly reference History.FinanceReportsBalances. The table is a terminal archive - data flows in via partition switch and is queried directly for reporting and audit purposes.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is a standalone archive table with no explicit FK constraints, computed columns referencing functions, or other structural dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found. The table is queried directly for ad-hoc reporting and audit analysis. No views, procedures, or functions in the SSDT project reference this table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_History_FinanceReportsBalances | CLUSTERED PK | ReportId ASC, Id ASC, Occurred ASC | - | - | Active, DATA_COMPRESSION = PAGE, ON DatesToFilegroup(Occurred) |
| IX_FinanceReportBalances_ReportId | NONCLUSTERED | ReportId ASC | - | - | Active, ON DatesToFilegroup(Occurred) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_History_FinanceReportsBalances | PRIMARY KEY | Composite clustered PK on (ReportId, Id, Occurred). The three-column key is required because Occurred is the partition column and must be part of the clustered index for partition alignment. PAGE compression reduces storage footprint for this 876M+ row table. |

---

## 8. Sample Queries

### 8.1 Get all balance records for a specific report run
```sql
SELECT Id, WalletId, Gcid, CryptoId, Address,
       TotalReceive, TotalSend, BloxBalance, ComputedAmount,
       FindDiscrepancy, BitgoValue, BloxValue, LevelId, ErrorMsg, Occurred
FROM History.FinanceReportsBalances WITH (NOLOCK)
WHERE ReportId = 100
ORDER BY Id;
```

### 8.2 Find all discrepancy records with their classification
```sql
SELECT h.Id, h.ReportId, h.WalletId, h.CryptoId, h.Address,
       h.ComputedAmount, h.BloxBalance, h.BitgoValue, h.BloxValue,
       h.LevelId, l.Name AS LevelName, l.Description AS LevelDescription,
       h.ErrorMsg, h.Occurred
FROM History.FinanceReportsBalances h WITH (NOLOCK)
INNER JOIN Dictionary.FinanceReportLevel l WITH (NOLOCK) ON h.LevelId = l.Id
WHERE h.Occurred >= '2022-01-01' AND h.Occurred < '2022-02-01'
ORDER BY h.LevelId, h.Id;
```

### 8.3 Summarize discrepancy types for a date range (partition-aligned)
```sql
SELECT l.Name AS DiscrepancyType,
       l.Description,
       COUNT(*) AS WalletCount
FROM History.FinanceReportsBalances h WITH (NOLOCK)
INNER JOIN Dictionary.FinanceReportLevel l WITH (NOLOCK) ON h.LevelId = l.Id
WHERE h.Occurred >= '2022-06-01' AND h.Occurred < '2022-07-01'
GROUP BY l.Name, l.Description
ORDER BY WalletCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Confluence searches for "History.FinanceReportsBalances", "FinanceReportsBalances", and "WalletBalancesReport" returned no dedicated documentation pages. Jira MCP was unavailable (410 Gone).

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.6/10 (Elements: 9.4/10, Logic: 10/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed (cross-schema) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FinanceReportsBalances | Type: Table | Source: WalletBalancesReportDB/History/Tables/History.FinanceReportsBalances.sql*
