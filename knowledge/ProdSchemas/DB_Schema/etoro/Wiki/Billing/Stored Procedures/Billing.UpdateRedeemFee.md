# Billing.UpdateRedeemFee

> Sets the platform fee amount on a crypto redemption record (Billing.Redeem.RedeemFee) after the fee is calculated - used by the Redeem service and SecurePay pipeline during the crypto liquidation workflow.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemID - targets Billing.Redeem.RedeemFee |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateRedeemFee` sets the platform fee charged on a crypto redemption (liquidation) transaction. In eToro's crypto redemption pipeline, when a customer redeems (sells) a crypto position and withdraws the proceeds, a fee is charged. This procedure records the calculated fee amount against the redemption record in `Billing.Redeem`.

The `RedeemFee` column stores the platform's fee for the redemption (approximately 2-7% of the redemption value, e.g., $39.88 fee on a $589.99 redemption). This fee is typically calculated at or after position close, once the actual redemption amount is known, and is then applied via this procedure.

Created April 2021 (Shay O., initial version); the `@RedeemFee` parameter precision was updated in July 2021 from the original precision to DECIMAL(16,8) to support higher-precision fee calculations for crypto assets with many decimal places.

`Billing.Redeem` is a temporal table (SYSTEM_VERSIONING = ON) - every UPDATE is automatically archived in History.Redeem, providing a complete audit trail of fee changes.

Called by `RedeemServiceUser` (the crypto redemption service) and `SQL_SecurePay` (the secure payment processing pipeline).

---

## 2. Business Logic

### 2.1 Fee Assignment on Redemption Record

**What**: Sets the platform fee on a specific redemption record, recording what the customer is charged for liquidating their crypto position.

**Columns/Parameters Involved**: `@RedeemID`, `@RedeemFee`, `Billing.Redeem.RedeemFee`

**Rules**:
- `UPDATE Billing.Redeem SET RedeemFee = @RedeemFee WHERE RedeemID = @RedeemID`
- No prior-state validation - unconditional fee assignment
- `@RedeemFee DECIMAL(16,8)`: high precision supports fractional fees on crypto assets (up to 8 decimal places)
- If `@RedeemID` does not exist, the UPDATE silently affects 0 rows
- `Billing.Redeem` is a temporal table: the fee update is automatically archived in `History.Redeem`
- This SP does NOT update `LastModificationDate` - that is managed by `Billing.RedeemStatusUpdate`

**Fee context from Billing.Redeem**:
- `RedeemFee`: platform fee on the redemption (this SP's target)
- `WalletFee`: crypto wallet service fee (separate; currently always NULL)
- `BlockchainFee`: on-chain blockchain transfer fee (separate)
- `NetProfit`: final net amount after all fees

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemFee | DECIMAL(16,8) | NO | - | CODE-BACKED | The platform fee amount to record for this redemption. Written to `Billing.Redeem.RedeemFee`. DECIMAL(16,8) precision supports fractional fee amounts for high-precision crypto assets. Example: 39.88 (fee on a ~$589.99 redemption). |
| 2 | @RedeemID | INT | NO | - | CODE-BACKED | Primary key of the redemption record to update. Maps to `Billing.Redeem.RedeemID` (INT IDENTITY). If RedeemID does not exist, the UPDATE silently affects 0 rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE RedeemID | Billing.Redeem | UPDATE (temporal table) | Sets RedeemFee on the target redemption record; change auto-archived in History.Redeem |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Redeem service | @RedeemID, @RedeemFee | EXEC (RedeemServiceUser role) | Called during the crypto redemption pipeline after fee calculation |
| SecurePay pipeline | @RedeemID, @RedeemFee | EXEC (SQL_SecurePay role) | Called as part of secure payment processing for crypto liquidations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateRedeemFee (procedure)
`- Billing.Redeem (table) - UPDATE target (temporal)
   `- History.Redeem (table) - auto-archived by temporal system
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | UPDATE - sets RedeemFee WHERE RedeemID=@RedeemID; temporal table auto-archives change to History.Redeem |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Redeem service (RedeemServiceUser) and SecurePay pipeline (SQL_SecurePay). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. `Billing.Redeem` has PK CLUSTERED on `RedeemID` - the WHERE clause uses this index for efficient single-row update. The temporal SYSTEM_VERSIONING ensures automatic history archival on every update.

### 7.2 Constraints

N/A for stored procedure. Note: `@RedeemFee` precision was updated from original (April 2021) to DECIMAL(16,8) in July 2021 to support higher-precision crypto fee calculations. The target column `Billing.Redeem.RedeemFee` must also support DECIMAL(16,8) or higher precision.

---

## 8. Sample Queries

### 8.1 Set the redemption fee after position close
```sql
EXEC Billing.UpdateRedeemFee @RedeemFee = 39.88000000, @RedeemID = 12345;
```

### 8.2 Check the fee and full financial picture for a redemption
```sql
SELECT RedeemID, AmountOnRequest, AmountOnClose, RedeemFee,
       WalletFee, BlockchainFee, NetProfit, RedeemStatusID
FROM Billing.Redeem WITH (NOLOCK)
WHERE RedeemID = 12345;
```

### 8.3 View fee history for a redemption (temporal audit trail)
```sql
SELECT RedeemID, RedeemFee, RedeemStatusID, ValidFrom, ValidTo
FROM History.Redeem WITH (NOLOCK)
WHERE RedeemID = 12345
ORDER BY ValidFrom;
```

### 8.4 Average redemption fee rate
```sql
SELECT
    AVG(CAST(RedeemFee AS FLOAT) / NULLIF(AmountOnClose, 0) * 100) AS AvgFeeRatePct
FROM Billing.Redeem WITH (NOLOCK)
WHERE AmountOnClose IS NOT NULL AND AmountOnClose > 0
  AND RedeemFee IS NOT NULL AND RedeemFee > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateRedeemFee | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateRedeemFee.sql*
