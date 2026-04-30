# BackOffice.GetRedeemsInfo

> Returns full redeem request details including live position PnL and instrument metadata for a given list of RedeemIDs - used to hydrate Back Office redeem management screens.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemIds (table-valued, required); returns Billing.Redeem rows with live value enrichment |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetRedeemsInfo` retrieves the core data set for managing redeem requests in Back Office. A "redeem" in eToro is a request by a customer to convert a stock or crypto position back to cash (or transfer crypto to an external wallet). This procedure accepts a batch of RedeemIDs and returns each request's full state from `Billing.Redeem`, enriched with the live market value of the underlying position (from `Trade.PositionForExternalUseWithPnL`) and the instrument's display name (from `Trade.InstrumentMetaData`).

The procedure exists to provide BO agents with both the requested amounts and the real-time position value. The `PositionCurrentValue` column - computed as `AmountOnRequest + PnLInDollars` - shows what the position is currently worth in USD at the moment of query, which may differ from what the customer originally requested if the market has moved.

The procedure is a straightforward multi-row lookup with no filtering business logic beyond the ID list. All rows with matching RedeemIDs are returned regardless of status.

---

## 2. Business Logic

### 2.1 Live Position Value Calculation

**What**: Computes the current USD value of the position linked to each redeem request.

**Columns/Parameters Involved**: `PositionCurrentValue`, `AmountOnRequest`, `Trade.PositionForExternalUseWithPnL.PnLInDollars`, `PositionID`

**Rules**:
- `PositionCurrentValue = AmountOnRequest + CAST(PnLInDollars AS DECIMAL(16,2))`
- `AmountOnRequest` is the amount the customer requested at redeem submission time
- `PnLInDollars` is the current unrealized P&L from the live position view - reflects current market price
- NULL if PositionID is NULL or if the position has no entry in PositionForExternalUseWithPnL (e.g., already closed)
- This difference between AmountOnRequest and PositionCurrentValue helps BO decide whether to approve at the current price

### 2.2 Redeem Status Lifecycle

**What**: RedeemStatusID tracks the redeem request through its approval and execution lifecycle.

**Columns/Parameters Involved**: `RedeemStatusID`

**Rules**:
- 1 = PositionPending - submitted, awaiting initial review
- 2 = Rejected - denied by BO
- 3 = Approved - approved by all required groups
- 4 = ReadyToRedeem - approved and queued for execution
- 5 = PositionClosing - position close is in progress
- 6 = PositionClosed - position has been closed
- 7 = TransactionInProcess - crypto/wallet transaction is being processed
- 8 = TransactionDone - full process complete
- 20 = Terminated - permanently stopped (may include NWA/validation failures)
- 21 = FailedToCancel - cancellation attempt failed
- 100 = New - initial state before BO review begins

**Diagram**:
```
New(100) -> PositionPending(1) -> Rejected(2)
                              -> Approved(3) -> ReadyToRedeem(4) -> PositionClosing(5)
                                                                 -> PositionClosed(6)
                                                                 -> TransactionInProcess(7)
                                                                 -> TransactionDone(8)
                              -> Terminated(20)
                              -> FailedToCancel(21)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemIds | [dbo].[IdList] (TABLE TYPE) | NO | - | CODE-BACKED | Table-valued parameter containing RedeemIDs to retrieve. Uses the dbo.IdList UDT with a CID column (naming quirk - used as a generic ID column). All matching Billing.Redeem rows are returned. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RedeemID | INT | NO | - | CODE-BACKED | Primary key of the redeem request (Billing.Redeem.RedeemID). |
| 2 | PositionID | INT | YES | - | CODE-BACKED | ID of the trading position being redeemed (Billing.Redeem.PositionID). Links to Trade.PositionTbl. May be NULL for non-position redeem types. |
| 3 | OperationID | INT | YES | - | CODE-BACKED | ID of the operation record associated with this redeem (Billing.Redeem.OperationID). Links to the operation tracking system. |
| 4 | RedeemTypeID | INT | NO | - | CODE-BACKED | Type of redeem request. 0 = standard redeem (position close to cash). 1 = transfer type. (Dictionary.RedeemType table exists but is currently empty; values inferred from data distribution.) |
| 5 | RedeemStatusID | INT | NO | - | VERIFIED | Current processing status of the redeem. 1=PositionPending, 2=Rejected, 3=Approved, 4=ReadyToRedeem, 5=PositionClosing, 6=PositionClosed, 7=TransactionInProcess, 8=TransactionDone, 20=Terminated, 21=FailedToCancel, 100=New. (Dictionary.RedeemStatus) |
| 6 | RequestDate | DATETIME | NO | - | CODE-BACKED | Timestamp when the customer submitted the redeem request (Billing.Redeem.RequestDate). |
| 7 | RedeemReasonID | INT | YES | - | CODE-BACKED | Reason code for this redeem outcome (Billing.Redeem.RedeemReasonID). Populated when the redeem is terminated or fails. See Dictionary.RedeemReason for values. |
| 8 | RedeemReasonName | NVARCHAR | YES | - | VERIFIED | Human-readable name of the redeem reason (Dictionary.RedeemReason.DisplayName). Examples: RreTradeBlocked, RreFundingBlocked, RreDisputeProcess, RreVerificationLevel, CanceledByOps, FailedByTrading, FailedByWallet, CanceledByUser. NULL if no reason assigned. |
| 9 | Units | DECIMAL | YES | - | CODE-BACKED | Number of instrument units to be redeemed (Billing.Redeem.Units). For stocks: share count. For crypto: token amount. |
| 10 | AmountOnRequest | MONEY | YES | - | CODE-BACKED | USD value of the redeem request at the time of submission (Billing.Redeem.AmountOnRequest). Used as the base for PositionCurrentValue calculation. |
| 11 | AmountOnClose | MONEY | YES | - | CODE-BACKED | USD amount at the time the position was actually closed (Billing.Redeem.AmountOnClose). May differ from AmountOnRequest due to market movement. Populated after PositionClosed status. |
| 12 | ManagerID | INT | YES | - | CODE-BACKED | ID of the BackOffice manager who processed or last updated this redeem (Billing.Redeem.ManagerID). |
| 13 | ManagerOpsID | INT | YES | - | CODE-BACKED | ID of the operations manager associated with this redeem (Billing.Redeem.ManagerOpsID). May differ from ManagerID for dual-approval workflows. |
| 14 | WalletFee | MONEY | YES | - | CODE-BACKED | Fee charged for the wallet/transfer component of the redeem (Billing.Redeem.WalletFee). Applicable for crypto transfers to external wallets. |
| 15 | RedeemFee | MONEY | YES | - | CODE-BACKED | Platform fee charged for processing the redeem (Billing.Redeem.RedeemFee). |
| 16 | BlockchainFee | MONEY | YES | - | CODE-BACKED | Blockchain network fee (gas) for crypto transfers (Billing.Redeem.BlockchainFee). NULL for non-crypto redeems. |
| 17 | InstrumentID | INT | YES | - | CODE-BACKED | ID of the financial instrument being redeemed (Billing.Redeem.InstrumentID). Links to Trade.InstrumentMetaData for the display name. |
| 18 | FundingID | INT | YES | - | CODE-BACKED | ID of the funding record associated with the cash proceeds of this redeem (Billing.Redeem.FundingID). Links to Billing.Funding. |
| 19 | InstrumentName | NVARCHAR | YES | - | CODE-BACKED | Display name of the instrument (Trade.InstrumentMetaData.InstrumentDisplayName via InstrumentID JOIN). NULL if instrument not found in metadata. |
| 20 | CryptoID | INT | YES | - | CODE-BACKED | ID of the crypto asset associated with this redeem (Billing.Redeem.CryptoID). NULL for stock redeems. |
| 21 | PositionCurrentValue | DECIMAL(16,2) | YES | - | VERIFIED | Current USD value of the linked position: AmountOnRequest + CAST(Trade.PositionForExternalUseWithPnL.PnLInDollars AS DECIMAL(16,2)). Reflects live market price. NULL if PositionID is NULL or position not found in PnL view. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RedeemIds -> RedeemID | Billing.Redeem | Read (IN filter) | Core driving table |
| BR.PositionID | Trade.PositionForExternalUseWithPnL | LEFT JOIN | Live PnL for current position value |
| BR.InstrumentID | Trade.InstrumentMetaData | LEFT JOIN | Instrument display name |
| BR.RedeemReasonID | Dictionary.RedeemReason | LEFT JOIN | Reason name for terminated/failed redeems |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO application layer) | (direct call) | Application | Called by BO redeem management screens to display redeem details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetRedeemsInfo (procedure)
├── Billing.Redeem (table)
├── Trade.PositionForExternalUseWithPnL (view)
├── Trade.InstrumentMetaData (table)
├── Dictionary.RedeemReason (table)
└── dbo.IdList (user defined type - parameter type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | Primary data source (FROM) |
| Trade.PositionForExternalUseWithPnL | View | LEFT JOIN - live PnL for PositionCurrentValue |
| Trade.InstrumentMetaData | Table | LEFT JOIN - instrument display name |
| Dictionary.RedeemReason | Table | LEFT JOIN - reason name |
| dbo.IdList | User Defined Type | Table-valued parameter type for @RedeemIds |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| dbo.IdList UDT | Implementation | @RedeemIds uses dbo.IdList - the internal column is named "CID" (SELECT CID FROM @RedeemIds) despite containing RedeemIDs. This is a generic ID list type reused across multiple procedures. |
| No status filter | Logic | All matching RedeemIDs are returned regardless of RedeemStatusID - caller must filter if needed |

---

## 8. Sample Queries

### 8.1 Get redeem info for a specific set of redeem IDs
```sql
DECLARE @Ids dbo.IdList
INSERT INTO @Ids VALUES (1001), (1002), (1003)
EXEC [BackOffice].[GetRedeemsInfo] @RedeemIds = @Ids
```

### 8.2 Check current values of pending redeems
```sql
SELECT BR.RedeemID, BR.AmountOnRequest,
       BR.AmountOnRequest + CAST(ISNULL(Gp.PnLInDollars, 0) AS DECIMAL(16,2)) AS CurrentValue,
       BR.RedeemStatusID
FROM Billing.Redeem BR WITH (NOLOCK)
LEFT JOIN Trade.PositionForExternalUseWithPnL Gp WITH (NOLOCK) ON Gp.PositionID = BR.PositionID
WHERE BR.RedeemStatusID IN (1, 100, 3, 4)
```

### 8.3 Redeem requests with reason names and instrument details
```sql
SELECT BR.RedeemID, BR.RedeemStatusID, RR.DisplayName AS ReasonName,
       ITD.InstrumentDisplayName AS Instrument, BR.RequestDate
FROM Billing.Redeem BR WITH (NOLOCK)
LEFT JOIN Dictionary.RedeemReason RR WITH (NOLOCK) ON BR.RedeemReasonID = RR.RedeemReasonID
LEFT JOIN Trade.InstrumentMetaData ITD WITH (NOLOCK) ON BR.InstrumentID = ITD.InstrumentID
WHERE BR.RedeemStatusID NOT IN (8, 20)
ORDER BY BR.RequestDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetRedeemsInfo | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetRedeemsInfo.sql*
