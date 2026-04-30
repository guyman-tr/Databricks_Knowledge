# apex.EXT901_BalanceCashAndBalanceMarginDumpReport

> Cash and margin balance report from Apex Clearing EXT901 extract: trade/settle balances, SMA, and activity indicators per account.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores the daily cash and margin balance dump from Apex Clearing's EXT901 extract. Each row represents the balance state of a single account, including trade-date and settle-date cash balances, prior-day beginning balances, and activity indicators. The data spans multiple balance categories: cash, margin, short, and money market.

The EXT901 data is vital for cash balance reconciliation and for monitoring account health. It enables eToro to verify that cash balances at Apex match internal records, to track the progression of balances over time, and to identify accounts with unusual activity patterns.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT901 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Multi-Level Balance Aggregation

**What**: Trade balances are tracked at multiple organizational levels.

**Columns Involved**: `TradeBalance`, `TradeBalanceOffice`, `TradeBalanceCorrespondent`, `TradeBalanceFirm`

**Rules**:
- TradeBalance is the account-level trade-date cash balance
- TradeBalanceOffice is the office-level aggregate
- TradeBalanceCorrespondent is the correspondent-level aggregate
- TradeBalanceFirm is the firm-level aggregate
- These enable reconciliation at different organizational tiers

### 2.2 Balance Comparison

**What**: Begin and prior-begin balances enable day-over-day comparison.

**Columns Involved**: `BeginBalance`, `PriorBeginBalance`, `TradeBalance`, `SettleBalance`, `MarketBalance`

**Rules**:
- BeginBalance is the start-of-day balance
- PriorBeginBalance is the prior day's start-of-day balance
- The difference between TradeBalance and SettleBalance reflects unsettled activity

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT901 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | CorrespondentOfficeID | int | YES | - | CODE-BACKED | Correspondent firm office identifier. |
| 5 | OfficeCode | varchar(3) | YES | - | CODE-BACKED | Apex office/branch code associated with the account. |
| 6 | AccountType | varchar(1) | YES | - | CODE-BACKED | Account type code (cash, margin, short). |
| 7 | CurrencyCode | varchar(3) | YES | - | CODE-BACKED | ISO currency code for the balance. |
| 8 | CurrencyCodeOffice | varchar(3) | YES | - | NAME-INFERRED | Currency code at the office level (may differ for multi-currency offices). |
| 9 | MoneyMarketCode | varchar(3) | YES | - | NAME-INFERRED | Money market fund code for sweep balances. |
| 10 | ProcessDate | date | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 11 | Firm | varchar(2) | YES | - | CODE-BACKED | Clearing firm identifier. |
| 12 | BeginBalance | decimal(28,10) | YES | - | CODE-BACKED | Start-of-day balance for the current business date. |
| 13 | PriorBeginBalance | decimal(28,10) | YES | - | CODE-BACKED | Start-of-day balance from the prior business date. |
| 14 | TradeBalance | decimal(28,10) | YES | - | CODE-BACKED | Account-level trade-date cash balance. |
| 15 | TradeBalanceOffice | decimal(28,10) | YES | - | NAME-INFERRED | Trade-date balance aggregated at the office level. |
| 16 | TradeBalanceCorrespondent | decimal(28,10) | YES | - | NAME-INFERRED | Trade-date balance aggregated at the correspondent level. |
| 17 | TradeBalanceFirm | decimal(28,10) | YES | - | NAME-INFERRED | Trade-date balance aggregated at the firm level. |
| 18 | SettleBalance | decimal(28,10) | YES | - | CODE-BACKED | Settle-date cash balance (reflects only settled transactions). |
| 19 | MarketBalance | decimal(28,10) | YES | - | NAME-INFERRED | Market value balance of the account. |
| 20 | ActivityIndicator | varchar(1) | YES | - | NAME-INFERRED | Flag indicating if the account had activity on the process date. |
| 21 | LastActiveDate | smalldatetime | YES | - | CODE-BACKED | Date of the most recent activity on the account. |
| 22 | TradeCashBalance | decimal(28,10) | YES | - | NAME-INFERRED | Trade-date cash-type balance (distinct from margin balance). |
| 23 | ShortTradeBalance | decimal(28,10) | YES | - | NAME-INFERRED | Trade-date balance for short positions. |

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
apex.EXT901_BalanceCashAndBalanceMarginDumpReport (table)
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
| PK_EXT901_BalanceCashAndBalanceMarginDumpReport | CLUSTERED PK | Id | - | - | Active |
| IX_EXT901_BalanceCashAndBalanceMarginDumpReport_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT901_BalanceCashAndBalanceMarginDumpReport | PRIMARY KEY | Unique Id per row |
| FK_EXT901_BalanceCashAndBalanceMarginDumpReport_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get balances from the latest import

```sql
SELECT AccountNumber, AccountType, CurrencyCode, TradeBalance, SettleBalance, BeginBalance, ProcessDate
FROM apex.EXT901_BalanceCashAndBalanceMarginDumpReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 901 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber;
```

### 8.2 Find accounts with large balance changes

```sql
SELECT AccountNumber, BeginBalance, PriorBeginBalance,
       (BeginBalance - PriorBeginBalance) AS BalanceChange, ProcessDate
FROM apex.EXT901_BalanceCashAndBalanceMarginDumpReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 901 AND Status = 2 ORDER BY ProcessDate DESC)
  AND ABS(BeginBalance - PriorBeginBalance) > 100000
ORDER BY ABS(BeginBalance - PriorBeginBalance) DESC;
```

### 8.3 Compare trade vs settle balances

```sql
SELECT AccountNumber, TradeBalance, SettleBalance,
       (TradeBalance - SettleBalance) AS UnsettledAmount, ProcessDate
FROM apex.EXT901_BalanceCashAndBalanceMarginDumpReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 901 AND Status = 2 ORDER BY ProcessDate DESC)
  AND TradeBalance <> SettleBalance
ORDER BY ABS(TradeBalance - SettleBalance) DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 12 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT901_BalanceCashAndBalanceMarginDumpReport | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT901_BalanceCashAndBalanceMarginDumpReport.sql*
