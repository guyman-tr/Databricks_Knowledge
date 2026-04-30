# History.Redeem

> Temporal (system-versioned) history table for Billing.Redeem. Automatically maintained by SQL Server to record every previous row state whenever a redeem record is inserted, updated, or deleted. Each row represents a point-in-time snapshot of a crypto redemption request, capturing the RedeemStatusID that was active during the period [SysStartTime, SysEndTime).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (System-Versioned History) |
| **Key Identifier** | RedeemID (int, no PK - temporal history tables have no PK) |
| **Partition** | No - CLUSTERED on [MAIN] (SysEndTime, SysStartTime) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |
| **Current Table** | Billing.Redeem (SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.Redeem)) |

---

## 1. Business Meaning

This table is the system-versioned temporal history for `Billing.Redeem`, which tracks crypto redemption requests. A "redeem" is eToro's feature allowing customers to withdraw cryptocurrency positions from the eToro platform and transfer the underlying coins to their eToro Wallet (external crypto wallet). Redeems are processed daily by the OPS CO Payments team after required approvals from Risk, AML, and OPS departments.

Every time a `Billing.Redeem` row changes (status transitions, manager review, amount updates), SQL Server automatically writes the old row state to this history table with the `SysStartTime` and `SysEndTime` bounds of that state. This enables full audit trail and point-in-time reconstruction of any redeem request.

The table has 173,629 rows tracking 38,433 distinct redeemIDs across 36,288 customers (Jan 2023 to Mar 2026). The dominant historical state is `Terminated` (48% of row-states), indicating many requests are cancelled before execution.

**Atlassian source**: "Redeem Handling" (Confluence, ID 971374912) documents the full operational procedure.

---

## 2. Business Logic

### 2.1 Temporal System-Versioning (SQL Server)

**What**: This table is managed exclusively by SQL Server's temporal mechanism. No procedure writes to it directly.

**Rules**:
```sql
-- Billing.Redeem DDL declares temporal versioning:
PERIOD FOR SYSTEM_TIME ([SysStartTime], [SysEndTime])
SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[Redeem])

-- SysStartTime/SysEndTime in Billing.Redeem are GENERATED ALWAYS AS ROW START/END HIDDEN
-- In History.Redeem they are explicit columns (not hidden)
```
- When a `Billing.Redeem` row is updated, the prior state is written here with `SysEndTime = transaction start time`
- When a `Billing.Redeem` row is deleted, the final state is written here
- `SysStartTime <= SysEndTime` for each row (equality possible for rows updated within the same second)
- The CLUSTERED index on (SysEndTime ASC, SysStartTime ASC) optimizes FOR SYSTEM_TIME AS OF queries

### 2.2 Redeem Status Lifecycle (RedeemStatusID)

**What**: The status transitions define the redeem processing pipeline. History.Redeem captures every state transition.

**Status values** (from Dictionary.RedeemStatus):

| RedeemStatusID | Name | IsCancelable | Description |
|----------------|------|--------------|-------------|
| 100 | New | Yes | Initial state - customer has submitted a redeem request |
| 1 | PositionPending | Yes | Position closure initiated but not yet started |
| 3 | Approved | Yes | Approved by OPS/Risk/AML teams for processing |
| 4 | ReadyToRedeem | Yes | Position closed, ready for blockchain transfer |
| 5 | PositionClosing | Yes | Position close in progress |
| 6 | PositionClosed | No | Position successfully closed, awaiting blockchain transfer |
| 7 | TransactionInProcess | No | Blockchain transaction submitted via BitGo |
| 8 | TransactionDone | No | Blockchain transfer complete - redeem fulfilled |
| 20 | Terminated | No | Cancelled/terminated at any stage (most common terminal state at 48% of historical row-states) |
| 2 | Rejected | Yes | Rejected by review process (rare: 2 rows in history) |
| 25 | TransferNegativeBalance | Yes | Special state for negative balance transfers (rare: 2 rows) |

**Typical lifecycle**:
```
100 (New) -> 1 (PositionPending) -> 3 (Approved) -> 4 (ReadyToRedeem)
           -> 5 (PositionClosing) -> 6 (PositionClosed) -> 7 (TransactionInProcess)
           -> 8 (TransactionDone)   [successful end state]
  or at any point -> 20 (Terminated)    [cancelled/rejected end state - 48% of history]
```

### 2.3 Redeem Operational Process (from Atlassian)

**What**: Manual approval workflow required before execution. History.Redeem captures all status changes during this process.

**Rules** (from Confluence "Redeem Handling"):
- Redeems require approval from **3 departments**: Risk, AML, and OPS CO Payments before execution
- Reviewed daily around 11 AM
- Triggers that block auto-approval: dividend checks, unclear deposits, accounts with warning status, amounts >= $100,000, customer age triggers
- **High-value rule**: >= $100K total redeem requires a customer call within the last year
- **Age rule**: Customer age 69+ with $50K+ total requires a call within the last 6 months
- Redeems can be held for max 3 working days; no response = must be cancelled (-> Terminated)
- Blockchain transfers executed via BitGo platform

### 2.4 Point-in-Time Query Pattern

**What**: Query Billing.Redeem FOR SYSTEM_TIME AS OF @PointInTime to reconstruct historical state.

**Rules**:
```sql
-- Reconstruct state of a specific redeem at a specific time:
SELECT * FROM Billing.Redeem FOR SYSTEM_TIME AS OF @PointInTime WHERE RedeemID = @RedeemID

-- View all state transitions for a specific redeem:
SELECT RedeemID, RedeemStatusID, SysStartTime, SysEndTime,
    DATEDIFF(SECOND, SysStartTime, SysEndTime) AS DurationSeconds
FROM History.Redeem
WHERE RedeemID = @RedeemID
ORDER BY SysStartTime
```
- SQL Server automatically routes FOR SYSTEM_TIME queries to combine Billing.Redeem (current) + History.Redeem (past)
- Direct queries to History.Redeem access historical rows only (not the current active row in Billing.Redeem)

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 173,629 |
| Distinct RedeemIDs | 38,433 |
| Distinct CIDs | 36,288 |
| Date range | 2023-01-04 to 2026-03-18 |

**RedeemStatusID distribution** (all historical row-states):

| RedeemStatusID | Name | Count | Pct |
|----------------|------|-------|-----|
| 20 | Terminated | 83,938 | 48% |
| 100 | New | 38,432 | 22% |
| 6 | PositionClosed | 20,591 | 12% |
| 1 | PositionPending | 15,875 | 9% |
| 3 | Approved | 7,126 | 4% |
| 4 | ReadyToRedeem | 5,138 | 3% |
| 5 | PositionClosing | 2,078 | 1.2% |
| 7 | TransactionInProcess | 301 | 0.2% |
| 8 | TransactionDone | 146 | 0.08% |
| 2 | Rejected | 2 | <0.01% |
| 25 | TransferNegativeBalance | 2 | <0.01% |

The dominance of Terminated (48%) reflects requests that were cancelled mid-workflow (on-hold timeouts, customer withdrawal, risk flags). TransactionDone (146 rows) represents the count of rows that reached the successful transfer terminal state. New (100) appearing at 22% means most New requests have been processed - the current snapshot in Billing.Redeem would show only the most recent state.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RedeemID | int | NO | - | CODE-BACKED | The redeem request identifier. NOT an IDENTITY here (IDENTITY is in Billing.Redeem). Matches Billing.Redeem.RedeemID. Multiple rows per RedeemID (one per state transition). |
| 2 | CID | int | NO | - | CODE-BACKED | The customer who submitted the redeem request. |
| 3 | PositionID | bigint | NO | - | CODE-BACKED | The crypto position being redeemed. bigint (changed from int in Nov 2021). Links to History.Position_Active after the position is closed. |
| 4 | RedeemStatusID | int | NO | - | CODE-BACKED | Status during this time period. FK to Dictionary.RedeemStatus. The key tracking field - every status transition generates a new row here. Values: 100=New, 1=PositionPending, 3=Approved, 4=ReadyToRedeem, 5=PositionClosing, 6=PositionClosed, 7=TransactionInProcess, 8=TransactionDone, 20=Terminated. |
| 5 | RedeemReasonID | int | YES | - | CODE-BACKED | Reason for the redeem (from Dictionary.RedeemReason per Billing.Redeem FK). NULL in current data - likely populated only for specific redeem types or termination reasons. |
| 6 | Units | decimal(16,8) | NO | - | CODE-BACKED | Number of crypto units to be transferred (8 decimal places for fractional crypto quantities). |
| 7 | RedeemFee | decimal(16,8) | YES | - | CODE-BACKED | Platform fee charged for the redeem operation, in the instrument's units. NULL when not yet calculated. |
| 8 | WalletFee | decimal(16,8) | YES | - | CODE-BACKED | eToro Wallet processing fee, in units. NULL when not applicable. |
| 9 | BlockchainFee | decimal(16,8) | YES | - | CODE-BACKED | Blockchain network transaction fee (gas fee), in units. NULL until TransactionInProcess/TransactionDone. |
| 10 | AmountOnRequest | money | YES | - | CODE-BACKED | USD value of the position at the time the redeem was requested. Used by OPS for approval review and total-value thresholds (>= $100K triggers call requirement). |
| 11 | AmountOnClose | money | YES | - | CODE-BACKED | Actual USD value at position close time. NULL until PositionClosed status. May differ from AmountOnRequest due to price movement during processing. |
| 12 | FundingID | int | YES | - | CODE-BACKED | The funding record associated with this redeem (FK to Billing.Funding in Billing.Redeem). NULL if not linked to a specific funding. |
| 13 | InstrumentID | int | NO | - | CODE-BACKED | The cryptocurrency instrument (FK to Trade.InstrumentMetaData in Billing.Redeem). InstrumentID=100001 is visible in recent data. Determines which blockchain/crypto network to use. |
| 14 | RequestDate | datetime | YES | - | CODE-BACKED | When the customer submitted the redeem request. |
| 15 | LastModificationDate | datetime | YES | - | CODE-BACKED | When the row was last modified in Billing.Redeem (before this historical snapshot was taken). |
| 16 | WithdrawToFundingID | int | YES | - | CODE-BACKED | The destination wallet/funding record (FK to Billing.WithdrawToFunding in Billing.Redeem). Identifies the eToro Wallet destination. |
| 17 | ManagerOpsID | int | YES | - | CODE-BACKED | The OPS manager who reviewed/approved this request. NULL until reviewed. |
| 18 | ManagerID | int | YES | - | CODE-BACKED | The account manager associated with the customer. Used for directing escalation emails ("High Redeem - Call needed"). |
| 19 | Remark | varchar(500) | YES | - | CODE-BACKED | Free-text operational remarks. Includes hold comments like "OPS - Call needed - check DD.MM.YY" per Atlassian procedure. |
| 20 | CryptoID | int | NO | - | CODE-BACKED | The CryptoID of the target wallet for the transfer. Identifies the specific crypto address/wallet record. |
| 21 | IPAddress | varchar(16) | YES | - | CODE-BACKED | Customer IP address at request time. Used for AML/fraud monitoring. |
| 22 | NetProfit | money | YES | - | CODE-BACKED | Net profit on the position being redeemed. DEFAULT=0 in Billing.Redeem. |
| 23 | SysStartTime | datetime2(0) | NO | - | CODE-BACKED | The UTC timestamp when this row state became active in Billing.Redeem. Start of this temporal period. Precision: 1 second. |
| 24 | SysEndTime | datetime2(0) | NO | - | CODE-BACKED | The UTC timestamp when this row state ended (next update or delete). End of this temporal period. CLUSTERED index leading column. |
| 25 | RedeemTypeID | int | YES | - | CODE-BACKED | Classifies the type of redeem operation. DEFAULT=0 in Billing.Redeem. All recent rows have RedeemTypeID=0. |
| 26 | OperationID | uniqueidentifier | YES | - | CODE-BACKED | A unique operation identifier (GUID) for the redeem transaction. Used for idempotency and blockchain transaction correlation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Billing.Redeem | RedeemID | Temporal parent | This is the history table for Billing.Redeem. All queries should use FOR SYSTEM_TIME on Billing.Redeem or join to this table for history. |
| Customer.Customer | CID | Implicit FK | The customer who submitted the redeem. |
| History.Position_Active | PositionID | Implicit FK | The crypto position being redeemed (after position close). |
| Trade.InstrumentMetaData | InstrumentID | Implicit FK (enforced on Billing.Redeem) | The cryptocurrency instrument. |
| Dictionary.RedeemStatus | RedeemStatusID | Implicit FK (enforced on Billing.Redeem) | Status lookup. |
| Dictionary.RedeemReason | RedeemReasonID | Implicit FK (enforced on Billing.Redeem) | Reason lookup. |
| Billing.Funding | FundingID | Implicit FK (enforced on Billing.Redeem) | Source funding record. |
| Billing.WithdrawToFunding | WithdrawToFundingID | Implicit FK (enforced on Billing.Redeem) | Destination wallet/funding. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Redeem | (temporal) | System-Versioning owner | SQL Server writes to this table whenever Billing.Redeem rows change. Not written by any SP directly. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Redeem (temporal history table)
- Written by: SQL Server SYSTEM_VERSIONING mechanism
  - Triggered by: any INSERT/UPDATE/DELETE on Billing.Redeem
  - No application code writes directly to History.Redeem
- Current/live table: Billing.Redeem
  - SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[Redeem])
  - Writers: Billing schema SPs, BO (Back Office) application
```

### 6.1 Objects This Depends On

Temporal history table - no FK constraints. Structurally paired with `Billing.Redeem`.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none identified in SSDT) | - | Temporal history - consumed via FOR SYSTEM_TIME on Billing.Redeem or direct query for audit purposes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Redeem | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (PAGE compression, MAIN filegroup) |

The CLUSTERED index on (SysEndTime, SysStartTime) is the SQL Server recommended pattern for temporal history tables. SysEndTime leading enables the engine to efficiently satisfy FOR SYSTEM_TIME AS OF @t queries (find rows where SysStartTime <= @t AND SysEndTime > @t) using the range on SysEndTime.

### 7.2 Constraints

No constraints. Temporal history tables have no PK or FK constraints - SQL Server manages consistency between the current and history tables via SYSTEM_VERSIONING.

---

## 8. Sample Queries

### 8.1 All status transitions for a specific redeem

```sql
-- History rows only:
SELECT
    h.RedeemID,
    h.RedeemStatusID,
    ds.Name AS StatusName,
    h.AmountOnRequest,
    h.Units,
    h.SysStartTime,
    h.SysEndTime,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS DurationSeconds
FROM History.Redeem h WITH (NOLOCK)
    LEFT JOIN Dictionary.RedeemStatus ds ON h.RedeemStatusID = ds.RedeemStatusID
WHERE h.RedeemID = @RedeemID
ORDER BY h.SysStartTime;
```

### 8.2 Full audit trail using FOR SYSTEM_TIME (recommended)

```sql
-- Combines current + history seamlessly:
SELECT
    r.RedeemID,
    r.CID,
    r.RedeemStatusID,
    ds.Name AS StatusName,
    r.AmountOnRequest,
    r.Units,
    r.SysStartTime,
    r.SysEndTime
FROM Billing.Redeem FOR SYSTEM_TIME ALL r
    LEFT JOIN Dictionary.RedeemStatus ds ON r.RedeemStatusID = ds.RedeemStatusID
WHERE r.CID = @CID
ORDER BY r.RedeemID, r.SysStartTime;
```

### 8.3 State of all redeems at a specific point in time

```sql
SELECT
    r.RedeemID, r.CID, r.PositionID, r.RedeemStatusID, r.AmountOnRequest
FROM Billing.Redeem FOR SYSTEM_TIME AS OF @AsOfDateTime r
WHERE r.CID = @CID;
```

---

## 9. Atlassian Knowledge Sources

| Source | ID | Title | Relevance |
|--------|----|-------|-----------|
| Confluence | 971374912 | Redeem Handling | Full operational procedure: daily review, approval workflow, hold rules, high-value thresholds, BitGo execution |
| Confluence | 900530553 | Redeem Process | Additional redeem process documentation |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.3/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 9.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed (system-versioned - no SP writes directly) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Redeem | Type: Table (System-Versioned History) | Source: etoro/etoro/History/Tables/History.Redeem.sql*
