# Billing.GetRedeemProcessingDetails

> Given a WithdrawToFundingID, returns the combined payout and redemption context - the payment leg status from Billing.WithdrawToFunding and the redemption request details from Billing.Redeem - used by the payout pipeline to coordinate processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingID (payment leg lookup); returns at most one row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRedeemProcessingDetails` is the payout coordination lookup for the crypto redemption pipeline. When the payout processor needs to act on a specific payment leg (identified by its `WithdrawToFundingID`), it calls this procedure to retrieve both the withdrawal execution details (payment status, funding method, withdrawal request reference) and the originating redemption details (status, type, amounts, fee) in a single query.

The procedure links the two primary tables in the redemption payout flow: `Billing.Redeem` (the customer's redemption request) and `Billing.WithdrawToFunding` (the payment leg that carries the proceeds to the customer's account). The `WithdrawToFundingID` is the bridge between them - it is stored on the `Billing.Redeem` row once the payout is initiated and uniquely identifies the payment execution leg.

Data flow: the payout pipeline typically knows the `WithdrawToFundingID` from the payment processor callback or operator action, and calls this procedure to load all context needed to update statuses, log events, or make routing decisions.

---

## 2. Business Logic

### 2.1 Payout + Redemption Context Join

**What**: The procedure joins the payment execution leg to its originating redemption record, giving the caller a unified view of both sides of the payout.

**Columns/Parameters Involved**: `@WithdrawToFundingID`, `Billing.WithdrawToFunding.ID`, `Billing.Redeem.WithdrawToFundingID`

**Rules**:
- `Billing.Redeem.WithdrawToFundingID` links the redemption to its payment leg - set once the payout process is initiated
- `Billing.WithdrawToFunding.ID` is the PK of the payment leg - the INNER JOIN on `WTF.ID = BR.WithdrawToFundingID` should always return exactly one row when called with a valid WithdrawToFundingID (1:1 relationship per redemption)
- The WHERE clause uses `WithdrawToFundingID = @WithdrawToFundingID` - this may match via either the JOIN or the Redeem column (both refer to the same value)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | INT | NO | - | CODE-BACKED | Primary key of the `Billing.WithdrawToFunding` record representing the payment execution leg for this redemption payout. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | INT | NO | - | CODE-BACKED | Customer identifier from `Billing.Redeem`. |
| 3 | WPID | INT | NO | - | CODE-BACKED | `Billing.WithdrawToFunding.ID` (the payment leg primary key) aliased as WPID. Same as @WithdrawToFundingID. |
| 4 | CashoutStatusID | INT | YES | - | CODE-BACKED | Execution status of the payment leg from `Billing.WithdrawToFunding`. Tracks the payment provider's processing state (e.g., pending, sent, rejected). FK to `Dictionary.CashoutStatus`. |
| 5 | FundingID | INT | YES | - | CODE-BACKED | Payment instrument the redemption proceeds are being sent to. From `Billing.WithdrawToFunding.FundingID`. FK to `Billing.Funding`. |
| 6 | WithdrawID | INT | YES | - | CODE-BACKED | The parent withdrawal request (`Billing.Withdraw.WithdrawID`) that this payment leg belongs to. From `Billing.WithdrawToFunding`. |
| 7 | ManagerID | INT | YES | - | CODE-BACKED | Operations manager who created or last handled the payment leg. From `Billing.WithdrawToFunding.ManagerID`. 0 or NULL = system-automated. |
| 8 | RedeemID | INT | NO | - | CODE-BACKED | Primary key of the redemption request in `Billing.Redeem`. |
| 9 | Units | DECIMAL | YES | - | CODE-BACKED | Number of crypto units being redeemed. From `Billing.Redeem.Units`. |
| 10 | RedeemStatusID | INT | YES | - | CODE-BACKED | Current status of the redemption request. From `Billing.Redeem.RedeemStatusID`. See `Billing.Redeem` Section 2.1 for state machine values (1=PositionPending through 8=TransactionDone). |
| 11 | RedeemTypeID | INT | YES | - | CODE-BACKED | Type of redemption (0=standard, 1=NFT/special). From `Billing.Redeem.RedeemTypeID`. |
| 12 | RedeemFee | DECIMAL | YES | - | CODE-BACKED | Fee charged for this redemption in units. From `Billing.Redeem.RedeemFee`. |
| 13 | AmountOnRequest | DECIMAL | YES | - | CODE-BACKED | USD value of the position at the time the customer submitted the redemption request. From `Billing.Redeem.AmountOnRequest`. |
| 14 | AmountOnClose | DECIMAL | YES | - | CODE-BACKED | USD value of the position at the time the trading position was closed. From `Billing.Redeem.AmountOnClose`. Populated once the position closes (RedeemStatusID >= 6). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID | Billing.WithdrawToFunding | INNER JOIN (PK) | Payment leg execution details |
| WithdrawToFundingID | Billing.Redeem | INNER JOIN | Originating redemption request details |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application payout pipeline | @WithdrawToFundingID | EXEC | Called during payment processing to load full payout context |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRedeemProcessingDetails (procedure)
├── Billing.Redeem (table)
└── Billing.WithdrawToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | INNER JOIN via WithdrawToFundingID; source of redemption request fields |
| Billing.WithdrawToFunding | Table | INNER JOIN on ID; source of payment leg execution fields |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application payout pipeline | External | Calls to retrieve payout context when processing a specific payment leg |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 1:1 relationship | Design | Each Redeem row has at most one WithdrawToFundingID; this procedure returns at most one row |
| NOLOCK | Concurrency | Both table reads use NOLOCK for throughput |

---

## 8. Sample Queries

### 8.1 Get payout processing details for a specific payment leg
```sql
EXEC Billing.GetRedeemProcessingDetails @WithdrawToFundingID = 500001;
```

### 8.2 View payment leg and redemption status side-by-side
```sql
SELECT
    wtf.ID AS WithdrawToFundingID,
    wtf.CashoutStatusID,
    r.RedeemID,
    r.RedeemStatusID,
    r.AmountOnRequest,
    r.AmountOnClose,
    r.Units,
    r.RedeemFee
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
INNER JOIN Billing.Redeem r WITH (NOLOCK) ON r.WithdrawToFundingID = wtf.ID
WHERE wtf.ID = 500001;
```

### 8.3 Find all payment legs for a customer's redemptions
```sql
SELECT
    wtf.ID AS WPID,
    wtf.CashoutStatusID,
    r.RedeemID,
    r.RedeemStatusID,
    r.AmountOnClose
FROM Billing.Redeem r WITH (NOLOCK)
INNER JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wtf.ID = r.WithdrawToFundingID
WHERE r.CID = 12345678
  AND r.WithdrawToFundingID IS NOT NULL
ORDER BY r.RedeemID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRedeemProcessingDetails | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRedeemProcessingDetails.sql*
