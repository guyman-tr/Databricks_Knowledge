# Dictionary.RedeemReason

> Lookup table defining the 18 reasons for redeem (copy-fund exit) failures and rejections — from trade/funding blocks and verification issues to server errors, cancellations, and data integrity failures.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RedeemReasonID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup (PAGE compressed) |
| **Row Count** | 18 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.RedeemReason classifies why a redeem (copy-fund exit / CopyTrading liquidation) was rejected, failed, or cancelled. When a copier exits a copy relationship, the system must close positions, calculate final value, and transfer funds — this multi-step process can fail at various points. The RedeemReasonID explains what went wrong or why the operation was blocked.

The reasons fall into several categories: pre-validation blocks (trade blocked, funding blocked, dispute, internal user, verification level), processing failures (failed by trading, failed by wallet, server errors), operational decisions (rejected by ops, canceled by ops, canceled by user), and technical errors (data integrity, DB error, NWA validation). The table also includes a special `TransferNegativeBalanceTerminated` reason (ID 20) for copy exits that are terminated due to negative balance conditions.

RedeemReasonID is stored on Billing.Redeem (explicit FK), Trade.OrdersExitTbl, and their history tables. It flows through multiple Billing redeem procedures (RedeemStatusUpdate, SetRedeemStatus, RedeemPayoutProcess) and Trade procedures (UpdatePositionRedeemStatus, PositionClose, OrderExitOpen). BackOffice.GetRedeemsInfo and BackOffice.GetCryptoTransactions JOIN to this table for display.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: The major categories of redeem failure/rejection reasons.

**Columns/Parameters Involved**: `RedeemReasonID`, `Name`, `DisplayName`

**Rules**:
- **Pre-Validation Blocks (1-5, 16)**: Customer doesn't meet requirements for redemption
  - RreTradeBlocked (1): Customer's trading is blocked — cannot close positions
  - RreFundingBlocked (2): Customer's funding is blocked — cannot transfer funds
  - RreDisputeProcess (3): Customer is in an active dispute — redemption suspended
  - RreInternalUser (4): Internal/employee account — different redemption rules
  - RreVerificationLevel (5): Customer hasn't met verification requirements
  - NwaValidation (16): NWA (Negative Wallet Amount) validation failure
- **Processing Failures (8-9, 11-14)**: Technical or system failures during processing
  - FailedByTrading (8): Trading engine rejected the position close
  - FailedByWallet (9): Wallet/fund transfer system failed
  - ServerErrorTrading (11): Trading service unavailable
  - ServerErrorWallet (12): Wallet service unavailable
  - ServerErrorSettings (13): Settings service unavailable
  - DbError (14): Database-level error during processing
- **Operational Decisions (7, 10, 15, 18)**: Human or automated cancellations
  - RejectedByOps (7): Operations team manually rejected the redemption
  - CanceledByOps (10): Operations team manually cancelled
  - CanceledByUser (15): Customer cancelled their own redemption request
  - CancelledByTrading (18): Trading system cancelled the redemption
- **Data Issues (6)**: ValidationDataIntegrity — data consistency check failed
- **Special (20)**: TransferNegativeBalanceTerminated — negative balance transfer was terminated

### 2.2 Redeem Reason in Processing Flow

**What**: How reasons are set during redeem processing.

**Columns/Parameters Involved**: `RedeemReasonID`

**Rules**:
- Billing.RedeemStatusUpdate: Accepts @RedeemReasonID and updates Billing.Redeem
- Billing.SetRedeemStatus: Sets both status and reason
- Trade.PositionClose: Passes @RedeemReasonID through XML output for post-close processing
- Trade.OrderExitOpen: Inserts @RedeemReasonID into exit order records
- BackOffice.GetCryptoTransactions: CASE WHEN RedeemReasonID = 10 (CanceledByOps) for special crypto handling

---

## 3. Data Overview

| RedeemReasonID | Name | DisplayName | Meaning |
|---|---|---|---|
| 1 | RreTradeBlocked | RreTradeBlocked | Customer's trading permissions are blocked. Positions cannot be closed for redemption. |
| 2 | RreFundingBlocked | RreFundingBlocked | Customer's funding is blocked. Fund transfers for redemption are not allowed. |
| 3 | RreDisputeProcess | RreDisputeProcess | Active dispute in progress. Redemption suspended until dispute resolution. |
| 4 | RreInternalUser | RreInternalUser | Internal/employee account. Different redemption rules may apply. |
| 5 | RreVerificationLevel | RreVerificationLevel | Customer hasn't met required verification level for redemption. |
| 6 | ValidationDataIntegrity | ValidationDataIntegrity | Data integrity check failed. Inconsistency detected in redeem data. |
| 7 | RejectedByOps | RejectedByOps | Operations team manually rejected the redemption request. |
| 8 | FailedByTrading | FailedByTrading | Trading engine failed to close positions. May be due to market conditions or system issues. |
| 9 | FailedByWallet | FailedByWallet | Wallet/fund transfer service failed. Funds could not be transferred. |
| 10 | CanceledByOps | CanceledByOps | Operations team manually cancelled the redemption. BackOffice.GetCryptoTransactions checks this specifically. |
| 11 | ServerErrorTrading | ServerErrorTrading | Trading microservice unavailable or returned an error. |
| 12 | ServerErrorWallet | ServerErrorWallet | Wallet microservice unavailable or returned an error. |
| 13 | ServerErrorSettings | ServerErrorSettings | Settings microservice unavailable or returned an error. |
| 14 | DbError | DbError | Database-level error during redemption processing. |
| 15 | CanceledByUser | CanceledByUser | Customer cancelled their own redemption request before completion. |
| 16 | NwaValidation | NwaValidation | Negative Wallet Amount validation failed. Account balance check prevented redemption. |
| 18 | CancelledByTrading | CancelledByTrading | Trading system automatically cancelled the redemption. Note: ID 17 is skipped. |
| 20 | TransferNegativeBalanceTerminated | TransferNegativeBalanceTerminated | Redemption terminated due to negative balance transfer condition. Note: IDs 17, 19 are skipped. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RedeemReasonID | int | NO | - | VERIFIED | Primary key identifying the failure/rejection reason. Range 1-20 (gaps at 17, 19). Referenced by Billing.Redeem (explicit FK), Trade.OrdersExitTbl. Used as parameter in Billing.RedeemStatusUpdate, Trade.PositionClose, Trade.OrderExitOpen. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Internal reason code name. Not nullable. Prefix convention: "Rre" = Redeem Rejection, "ServerError" = service failure, "Failed" = processing failure. Used in procedure logic and debugging. |
| 3 | Description | varchar(500) | YES | - | VERIFIED | Extended description of the reason. Currently NULL for all rows — available for future enrichment. PAGE compressed. |
| 4 | DisplayName | varchar(50) | NO | - | VERIFIED | Customer/UI-facing display name. Currently matches Name for all rows. Used by dbo.SSRS_REDEEM_REPORT for report output. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Redeem | RedeemReasonID | Explicit FK (FK_BillingRedeem_DictionaryRedeemReason) | Main redeem table stores failure reason |
| History.Redeem | RedeemReasonID | Column | Historical redeem records |
| Trade.OrdersExitTbl | RedeemReasonID | Column | Exit orders store redeem reason |
| History.OrdersExitTbl | RedeemReasonID | Column | Historical exit orders |
| Trade.GetOrderExitData | RedeemReasonID | View SELECT | Exit order data view |
| Trade.OrdersExit | RedeemReasonID | View SELECT | Exit orders view |
| History.OrdersExit | RedeemReasonID | View SELECT | Historical exit orders view |
| Billing.RedeemStatusUpdate | @RedeemReasonID | Parameter UPDATE | Updates redeem reason |
| Billing.SetRedeemStatus | @RedeemReasonID | Parameter UPDATE | Sets status and reason |
| Billing.RedeemPayoutProcess_Update | @RedeemReasonID | Parameter | Payout processing update |
| Trade.UpdatePositionRedeemStatus | @RedeemReasonID | Parameter | Updates position redeem status |
| Trade.PositionClose | @RedeemReasonID | Parameter, XML output | Close position with reason |
| Trade.OrderExitOpen | @RedeemReasonID | Parameter INSERT | Exit order creation |
| BackOffice.GetRedeemsInfo | RedeemReasonID | JOIN | Redeem info display |
| BackOffice.GetCryptoTransactions | RedeemReasonID | JOIN, CASE WHEN = 10 | Crypto transaction display |
| dbo.SSRS_REDEEM_REPORT | - | Subquery for DisplayName | Reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.RedeemReason (table)
  └── referenced by Billing.Redeem (FK_BillingRedeem_DictionaryRedeemReason)
  └── stored in Trade.OrdersExitTbl, History tables
  └── consumed by 15+ Billing/Trade/BackOffice procedures
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | FK on RedeemReasonID |
| Trade.OrdersExitTbl | Table | Stores redeem reason on exit orders |
| Billing.RedeemStatusUpdate | Stored Procedure | Updates reason |
| Trade.PositionClose | Stored Procedure | Passes reason through close flow |
| Trade.OrderExitOpen | Stored Procedure | Writes reason to exit orders |
| BackOffice.GetRedeemsInfo | Stored Procedure | JOINs for display |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_RedeemReason | CLUSTERED PK | RedeemReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_RedeemReason | PRIMARY KEY | Unique reason identifier, FILLFACTOR 95, PAGE compression, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all redeem reasons
```sql
SELECT  RedeemReasonID,
        Name,
        DisplayName,
        Description
FROM    Dictionary.RedeemReason WITH (NOLOCK)
ORDER BY RedeemReasonID;
```

### 8.2 Count redeems by failure reason
```sql
SELECT  drr.DisplayName     AS Reason,
        COUNT(*)            AS RedeemCount
FROM    Billing.Redeem br WITH (NOLOCK)
JOIN    Dictionary.RedeemReason drr WITH (NOLOCK)
        ON br.RedeemReasonID = drr.RedeemReasonID
WHERE   br.RedeemReasonID IS NOT NULL
GROUP BY drr.DisplayName
ORDER BY RedeemCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data (18 reasons) and codebase analysis across 15+ procedures in Billing, Trade, and BackOffice schemas.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RedeemReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RedeemReason.sql*
