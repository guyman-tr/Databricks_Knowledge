# Billing.Redeem

> Core crypto redemption request table tracking each customer's request to convert a crypto position back to fiat currency, from initial submission through position closure, blockchain transfer, and final settlement.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | RedeemID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | Yes - [MAIN] filegroup on RedeemID and all indexes |
| **Indexes** | 5 (1 CLUSTERED PK + 4 NCI, including 1 covering index) |

---

## 1. Business Meaning

Billing.Redeem represents a customer's request to "redeem" (liquidate) a crypto asset position - selling their crypto and transferring the resulting fiat value back to their payment method. Each row corresponds to one redemption request for one position. The record tracks the entire lifecycle from the customer's initial request through backend approval, position closing, blockchain transfer, and final payout.

The table is the authoritative source for the crypto redemption pipeline. Without it, the system would have no way to coordinate the multi-step process: validating the request, closing the trading position, sending crypto via the blockchain, and crediting the customer's funding method. It is a temporal table, meaning all historical states are preserved in History.Redeem for audit and compliance purposes.

Rows are created by `Billing.Redeem_Add` (status=100/New) when a customer submits a redemption request. Status transitions are controlled by `Billing.RedeemStatusUpdate`, which validates every transition against a state machine in `Dictionary.RedeemStatusStateMachine`. The record is never deleted - terminated redemptions are marked with RedeemStatusID=20 and remain as permanent history. The temporal system automatically snapshots every row change to History.Redeem.

---

## 2. Business Logic

### 2.1 Redemption Status State Machine

**What**: Status transitions are strictly governed by a state machine - only valid transitions are allowed, enforced by `RedeemStatusUpdate` via `Dictionary.RedeemStatusStateMachine`.

**Columns/Parameters Involved**: `RedeemStatusID`, `RedeemReasonID`, `LastModificationDate`

**Rules**:
- Every status change is validated: `IF NOT EXISTS (SELECT * FROM Dictionary.RedeemStatusStateMachine WHERE FromStatusID = @Old AND ToStatusID = @New)` -> RAISERROR
- RedeemReasonID is only set when a redemption fails/terminates - it explains WHY (e.g., RejectedByOps, CanceledByUser, FailedByTrading)
- The dominant terminal state is Terminated (20) - ~60% of all records. PositionPending (1) is the main active state for ~32%.
- Cancellable states: 1=PositionPending, 2=Rejected, 3=Approved, 4=ReadyToRedeem, 5=PositionClosing, 21=FailedToCancel, 25=TransferNegativeBalance, 100=New

**Diagram**:
```
New (100)
  |
  v
PositionPending (1) <-- main queue state
  |         |
  v         v
Approved   Rejected (2)
  (3)        |
  |          v
  v       Terminated (20)
ReadyToRedeem (4)
  |
  v
PositionClosing (5)  <- Trade system closes the position
  |
  v
PositionClosed (6)   <- AmountOnClose set here
  |
  v
TransactionInProcess (7) <- Blockchain transfer initiated
  |
  v
TransactionDone (8)      <- Crypto sent, fiat credited

Also: Terminated (20), FailedToCancel (21), TransferNegativeBalance (25)
```

### 2.2 Amount and Fee Tracking

**What**: Three fee types and two amount snapshots capture the full economics of the redemption.

**Columns/Parameters Involved**: `AmountOnRequest`, `AmountOnClose`, `RedeemFee`, `WalletFee`, `BlockchainFee`, `NetProfit`, `Units`

**Rules**:
- AmountOnRequest: fiat value when the customer submitted (price at request time)
- AmountOnClose: fiat value when the position was actually closed (set when status transitions to 6=PositionClosed by RedeemStatusUpdate). NULL until position closes.
- RedeemFee: platform fee on the redemption (~2% based on data: e.g., Fee=39.88 on Amount=589.99 = 6.8%)
- WalletFee: fee for the crypto wallet service (currently always NULL - may be unused or charged separately)
- BlockchainFee: on-chain gas/network fee for the blockchain transfer (NULL for instruments where it doesn't apply)
- NetProfit: defaults to 0; represents profit on the redemption after fees
- Units: crypto amount to redeem (decimal(16,8) for crypto precision)

### 2.3 Idempotency Guard

**What**: Only one active (non-Terminated) redemption is allowed per PositionID at any time.

**Columns/Parameters Involved**: `PositionID`, `RedeemStatusID`

**Rules**:
- `Billing.Redeem_Add` checks: `IF EXISTS (SELECT 1 FROM Billing.Redeem WHERE PositionID = @PositionID AND RedeemStatusID <> 20)` -> RAISERROR 60025
- A position can be re-redeemed after its prior redemption is Terminated (20)
- This prevents double-spending of a single crypto position

### 2.4 RedeemType for Special Redemptions

**What**: RedeemTypeID distinguishes standard crypto redemptions from special types (added PTL-76, June 2022).

**Columns/Parameters Involved**: `RedeemTypeID`, `OperationID`

**Rules**:
- RedeemTypeID=0 (DEFAULT): standard crypto-to-fiat redemption (99.9% of records)
- RedeemTypeID=1: special redemption type (21 rows, all Bitcoin - likely NFT or internal transfer based on procedures GetNFTRedeemDetailsByOperationID, GetNFTRedeemStatus)
- OperationID (GUID): external operation reference, used alongside RedeemTypeID for tracking special redemptions

---

## 3. Data Overview

| RedeemID | CID | RedeemStatusID | InstrumentID | Units | AmountOnRequest | AmountOnClose | RedeemFee | Meaning |
|----------|-----|----------------|-------------|-------|-----------------|---------------|-----------|---------|
| 40039 | 25463678 | 8 (TransactionDone) | 100017 | 1994.19 | 589.99 | 573.06 | Completed redemption: customer sold ~1994 units of crypto (InstrumentID 100017, CryptoID 18) for $589.99 requested, received $573.06 at close. Price moved against customer during processing. |
| 40037 | 3635308 | 5 (PositionClosing) | 100001 | 0.33 | 770.00 | NULL | Bitcoin redemption currently in progress - position is closing, AmountOnClose not yet set. Customer requested $770 at time of submission. |
| 40036 | 3635308 | 8 (TransactionDone) | 100001 | 0.32 | 750.00 | 750.00 | Completed BTC redemption where AmountOnClose matched AmountOnRequest exactly ($750). BlockchainFee=$0.000256 BTC for on-chain transfer. |
| (typical) | - | 20 (Terminated) | - | - | - | NULL | 60% of all records are Terminated - these are cancelled, rejected, or failed redemptions. AmountOnClose is NULL as position was never fully closed. |
| (typical) | - | 1 (PositionPending) | - | - | - | NULL | 32% are in PositionPending - the main approval queue awaiting review or automated processing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RedeemID | INT | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK, auto-increment. Output parameter in Billing.Redeem_Add (SET @RedeemID = SCOPE_IDENTITY()). |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID. No FK constraint but standard eToro CID referencing the customer who submitted the redemption request. |
| 3 | PositionID | BIGINT | NO | - | CODE-BACKED | The trading position being redeemed. No FK constraint (BIGINT, references Trade.PositionTbl). Indexed with RedeemID (IX_PositionID_RedeemID). Used in idempotency guard: only one active redeem allowed per PositionID. |
| 4 | RedeemStatusID | INT | NO | - | VERIFIED | Current state in the redemption state machine. FK to Dictionary.RedeemStatus. Transitions validated by Dictionary.RedeemStatusStateMachine in RedeemStatusUpdate. Values: 1=PositionPending, 2=Rejected, 3=Approved, 4=ReadyToRedeem, 5=PositionClosing, 6=PositionClosed, 7=TransactionInProcess, 8=TransactionDone, 20=Terminated, 21=FailedToCancel, 25=TransferNegativeBalance, 100=New. Distribution: 20=Terminated (60%), 1=PositionPending (32%). |
| 5 | RedeemReasonID | INT | YES | - | CODE-BACKED | Reason code for non-success outcomes. FK to Dictionary.RedeemReason. Set by RedeemStatusUpdate when redemption fails or is cancelled. Values: 1=RreTradeBlocked, 2=RreFundingBlocked, 7=RejectedByOps, 8=FailedByTrading, 9=FailedByWallet, 10=CanceledByOps, 11-14=ServerErrors, 15=CanceledByUser, etc. NULL for successfully completed redemptions (status=8). |
| 6 | Units | DECIMAL(16,8) | NO | - | CODE-BACKED | Crypto quantity to redeem (decimal precision for crypto amounts). Set on INSERT via @Units. May be updated to actual closed amount when status=6: `Units = IIF(@RedeemStatusID = 6, ISNULL(@Units, Units), Units)` in RedeemStatusUpdate. |
| 7 | RedeemFee | DECIMAL(16,8) | YES | - | CODE-BACKED | eToro platform fee on the redemption. Set on INSERT via @Fee (maps to column RedeemFee). Approximately 2% of the redemption amount based on observed data. |
| 8 | WalletFee | DECIMAL(16,8) | YES | - | NAME-INFERRED | Fee for the crypto wallet service. Currently always NULL in production data - either not charged separately, deducted from AmountOnClose, or reserved for future use. |
| 9 | BlockchainFee | DECIMAL(16,8) | YES | - | NAME-INFERRED | On-chain network fee (gas fee) for the blockchain transfer. Populated for Bitcoin (e.g., 0.000256 BTC) and certain other instruments. NULL for instruments where blockchain fees are absorbed or not applicable. |
| 10 | AmountOnRequest | MONEY | YES | - | CODE-BACKED | Fiat value of the redemption as calculated when the customer submitted the request. Set on INSERT via @Amount. Reflects the crypto price at request time. May differ from AmountOnClose if price moves before the position closes. |
| 11 | AmountOnClose | MONEY | YES | - | CODE-BACKED | Fiat value realized when the position was actually closed. Set by RedeemStatusUpdate when status transitions to 6 (PositionClosed): `AmountOnClose = IIF(@RedeemStatusID = 6, @Amount, AmountOnClose)`. NULL until PositionClosed state is reached. |
| 12 | FundingID | INT | YES | - | CODE-BACKED | The payment method funding record. FK to Billing.Funding(FundingID). Indexed (IX_BillingRedeem_FundingID). Identifies which funding method will receive the fiat payout. Set on INSERT. |
| 13 | InstrumentID | INT | NO | - | VERIFIED | The trading instrument being redeemed. FK to Trade.InstrumentMetaData(InstrumentID). Examples: 100001=Bitcoin, 100017=another crypto. Used by multiple procedures for instrument-specific business logic. |
| 14 | RequestDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp when the customer submitted the redemption request. Set to GETUTCDATE() on INSERT by Billing.Redeem_Add. |
| 15 | LastModificationDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp of the most recent status change or update. Set to GETUTCDATE() on INSERT and updated on every status change by RedeemStatusUpdate. Part of covering index (ix_BillingRedeem_Covering). |
| 16 | WithdrawToFundingID | INT | YES | - | CODE-BACKED | Link to the withdrawal record. FK to Billing.WithdrawToFunding(ID). Set when the redemption payout is linked to a specific withdrawal-to-funding process. |
| 17 | ManagerOpsID | INT | YES | - | CODE-BACKED | Operations team staff member ID who handled this redemption. Set by RedeemStatusUpdate via @ManagerOpsId. NULL for automated redemptions. |
| 18 | ManagerID | INT | YES | - | CODE-BACKED | Manager staff member ID. Set by RedeemStatusUpdate via @ManagerID. NULL for automated redemptions. |
| 19 | Remark | VARCHAR(500) | YES | - | CODE-BACKED | Free-text note added by operations staff. Set by RedeemStatusUpdate via @Remark. Preserved across updates (ISNULL(@Remark, Remark) pattern). |
| 20 | CryptoID | INT | NO | - | CODE-BACKED | Crypto-wallet-system identifier for the crypto asset. Set on INSERT. Distinct from InstrumentID: CryptoID is the wallet/exchange identifier (e.g., 2=Bitcoin, 18=another asset) while InstrumentID is the trading system identifier. |
| 21 | IPAddress | VARCHAR(16) | YES | - | CODE-BACKED | Client IP address at the time the redemption was submitted. Set on INSERT via @IPAddress. Used for fraud/compliance audit. |
| 22 | NetProfit | MONEY | NO | 0 | CODE-BACKED | Net profit on the redemption after fees. Default=0. Populated by the settlement process. |
| 23 | RedeemTypeID | INT | YES | 0 | CODE-BACKED | Redemption type: 0=Standard crypto-to-fiat (DEFAULT, 99.9% of records), 1=Special type (21 rows, appears to be NFT or internal transfer per procedures GetNFTRedeemDetailsByOperationID). Added in PTL-76 (June 2022). |
| 24 | OperationID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | External operation reference GUID. Added in PTL-76 alongside RedeemTypeID. Used for NFT redemptions and cross-system operation tracking. |
| - | SysStartTime | DATETIME2(0) | NO | sysutcdatetime() | CODE-BACKED | Temporal system column (HIDDEN). Row version start time, automatically managed by SQL Server temporal tables. Stored in History.Redeem for historical tracking. |
| - | SysEndTime | DATETIME2(0) | NO | 9999-12-31 | CODE-BACKED | Temporal system column (HIDDEN). Row version end time. Set to 9999-12-31 for current rows; updated to the change time when a row is historized. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawToFundingID | Billing.WithdrawToFunding | FK (FK_BillingRedeem) | Links to the withdrawal processing record for the payout |
| FundingID | Billing.Funding | FK (FK_BillingRedeem_BillingFunding) | The customer's payment method for receiving the fiat payout |
| RedeemReasonID | Dictionary.RedeemReason | FK (FK_BillingRedeem_DictionaryRedeemReason) | Reason for non-success outcomes (rejection, cancellation, failure) |
| RedeemStatusID | Dictionary.RedeemStatus | FK (FK_BillingRedeem_DictionaryRedeemStatus) | Current state in the redemption workflow |
| InstrumentID | Trade.InstrumentMetaData | FK (FK_BillingRedeem_TradeInstrumentMetaData) | The trading instrument (crypto asset) being redeemed |
| PositionID | Trade.PositionTbl | Implicit FK | The trading position being liquidated (no DDL constraint) |
| CID | BackOffice.Customer | Implicit FK | The customer submitting the redemption (no DDL constraint) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Redeem_Add | PositionID, CID | WRITER | Creates initial redeem record (status=100) |
| Billing.RedeemStatusUpdate | RedeemID, PositionID | MODIFIER | State transitions, sets AmountOnClose, Remark, Manager fields |
| Billing.SetRedeemStatus | RedeemID | MODIFIER | Alternative status setter |
| Billing.RedeemStatusUpdateByPosition | PositionID | MODIFIER | Bulk status update by position |
| Billing.UpdateRedeemFee | RedeemID | MODIFIER | Updates the RedeemFee column |
| Trade.UpdatePositionRedeemStatus | PositionID | MODIFIER | Trade schema updates redeem status on position events |
| Billing.RedeemPayoutProcess | RedeemID | READER+MODIFIER | Payout processing reads and updates redeem records |
| BackOffice.RedeemApprovalAdd | RedeemID | READER | Ops approval workflow reads this table |
| Billing.GetRedeemRecords | - | READER | Returns redeem records for UI/API |
| Billing.WithdrawAndWithdrawToFundingAdd | WithdrawToFundingID | READER+MODIFIER | Converts Redeem to WTF leg; reads idempotency guard (WithdrawToFundingID IS NOT NULL), updates WithdrawToFundingID on completion |
| Billing.WithdrawService_GetWithdrawsWithoutRedeems | RedeemID | READER (LEFT JOIN) | Identifies withdrawals with no linked Redeem; used for reconciliation reporting |
| Billing.RedeemPayoutProcess | RedeemID | READER | Cross-references for payout calculation |
| Billing.RedeemPayoutProcess_GetNewRecords | RedeemStatusID | READER | Gets new records for payout processing |
| dbo.SSRS_REDEEM_REPORT | - | READER | SSRS reporting |
| History.Redeem | - | TEMPORAL HISTORY | SQL Server temporal table stores all historical versions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Redeem (table)
├── Billing.WithdrawToFunding (table) [FK: WithdrawToFundingID]
├── Billing.Funding (table) [FK: FundingID]
├── Dictionary.RedeemReason (table) [FK: RedeemReasonID]
├── Dictionary.RedeemStatus (table) [FK: RedeemStatusID]
└── Trade.InstrumentMetaData (table) [FK: InstrumentID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | FK WithdrawToFundingID - the payout withdrawal record |
| Billing.Funding | Table | FK FundingID - the payment method for fiat payout |
| Dictionary.RedeemReason | Table | FK RedeemReasonID - reason codes for failures/cancellations |
| Dictionary.RedeemStatus | Table | FK RedeemStatusID - status values and IsCancelable flag |
| Trade.InstrumentMetaData | Table | FK InstrumentID - the crypto instrument definition |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem_Add | Stored Procedure | WRITER - creates new redemption records |
| Billing.RedeemStatusUpdate | Stored Procedure | MODIFIER - state machine transitions |
| Billing.SetRedeemStatus | Stored Procedure | MODIFIER - direct status updates |
| Billing.UpdateRedeemFee | Stored Procedure | MODIFIER - fee updates |
| Billing.RedeemPayoutProcess | Table | References RedeemID for payout coordination |
| BackOffice.RedeemApproval | Table | References RedeemID for approval records |
| History.Redeem | Table | Temporal history - all historical row versions |
| 40+ procedures | Various | Full list: GetRedeemRecords*, GetCryptoTransactions*, RedeemPayoutProcess_*, etc. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing_Redeem | CLUSTERED PK | RedeemID ASC | - | - | Active |
| IX_BillingRedeem_CID | NONCLUSTERED | CID ASC | - | - | Active |
| IX_BillingRedeem_FundingID | NONCLUSTERED | FundingID ASC | - | - | Active |
| IX_PositionID_RedeemID | NONCLUSTERED | PositionID ASC, RedeemID ASC | - | - | Active |
| ix_BillingRedeem_Covering | NONCLUSTERED | RedeemStatusID ASC, LastModificationDate ASC | RedeemID, CID, PositionID, RedeemReasonID, Units, RedeemFee, WalletFee, BlockchainFee, AmountOnRequest, AmountOnClose, FundingID, InstrumentID, RequestDate, WithdrawToFundingID, ManagerOpsID, ManagerID, Remark, CryptoID | - | Active |
| ix_BillingRedeem_StatusID_Modification | NONCLUSTERED | RedeemStatusID ASC, LastModificationDate ASC | FundingID, RedeemTypeID | - | Active (DATA_COMPRESSION=PAGE) |

All indexes on [MAIN] filegroup, FILLFACTOR=95.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing_Redeem | PRIMARY KEY CLUSTERED | RedeemID unique |
| FK_BillingRedeem | FOREIGN KEY | WithdrawToFundingID -> Billing.WithdrawToFunding(ID) |
| FK_BillingRedeem_BillingFunding | FOREIGN KEY | FundingID -> Billing.Funding(FundingID) |
| FK_BillingRedeem_DictionaryRedeemReason | FOREIGN KEY | RedeemReasonID -> Dictionary.RedeemReason(RedeemReasonID) |
| FK_BillingRedeem_DictionaryRedeemStatus | FOREIGN KEY | RedeemStatusID -> Dictionary.RedeemStatus(RedeemStatusID) |
| FK_BillingRedeem_TradeInstrumentMetaData | FOREIGN KEY | InstrumentID -> Trade.InstrumentMetaData(InstrumentID) |
| DF_BillingRedeemNetProfit | DEFAULT | NetProfit = 0 |
| D_BD_RedeemType | DEFAULT | RedeemTypeID = 0 (standard redemption) |
| DF_SysStart | DEFAULT | SysStartTime = sysutcdatetime() |
| DF_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59' |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.Redeem - all row versions preserved |

---

## 8. Sample Queries

### 8.1 Get active (non-terminated) redeems with status details

```sql
SELECT
    r.RedeemID,
    r.CID,
    r.PositionID,
    rs.Name AS Status,
    rs.IsCancelable,
    rr.Name AS Reason,
    r.Units,
    r.AmountOnRequest,
    r.AmountOnClose,
    r.RedeemFee,
    r.BlockchainFee,
    r.RequestDate,
    r.LastModificationDate
FROM [Billing].[Redeem] r WITH (NOLOCK)
INNER JOIN [Dictionary].[RedeemStatus] rs WITH (NOLOCK) ON rs.RedeemStatusID = r.RedeemStatusID
LEFT JOIN [Dictionary].[RedeemReason] rr WITH (NOLOCK) ON rr.RedeemReasonID = r.RedeemReasonID
WHERE r.RedeemStatusID <> 20  -- exclude Terminated
ORDER BY r.LastModificationDate DESC
```

### 8.2 Get redeems in PositionPending state for a specific date range

```sql
SELECT
    r.RedeemID,
    r.CID,
    r.PositionID,
    r.InstrumentID,
    r.Units,
    r.AmountOnRequest,
    r.RedeemFee,
    r.RequestDate
FROM [Billing].[Redeem] r WITH (NOLOCK)
WHERE r.RedeemStatusID = 1  -- PositionPending
  AND r.RequestDate >= DATEADD(day, -7, GETUTCDATE())
ORDER BY r.RequestDate ASC
```

### 8.3 Completed redemptions with full fee breakdown and instrument names

```sql
SELECT
    r.RedeemID,
    r.CID,
    r.PositionID,
    im.InstrumentDisplayName,
    r.Units,
    r.AmountOnRequest,
    r.AmountOnClose,
    r.AmountOnRequest - r.AmountOnClose AS PriceSlippage,
    r.RedeemFee,
    r.BlockchainFee,
    r.RequestDate,
    r.LastModificationDate
FROM [Billing].[Redeem] r WITH (NOLOCK)
INNER JOIN [Trade].[InstrumentMetaData] im WITH (NOLOCK) ON im.InstrumentID = r.InstrumentID
WHERE r.RedeemStatusID = 8  -- TransactionDone
ORDER BY r.LastModificationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.2/10 (Elements: 9.2/10, Logic: 9.0/10, Relationships: 10.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED (WalletFee, BlockchainFee) | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed (47 total references) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.Redeem | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Redeem.sql*
