# Billing.UpdateMonthlyProcessingQuota

> Accumulates the deposit amount into the credit card protocol's monthly running total (Billing.MonthlyQuota), which the routing algorithm uses to balance load across payment processors. Only processes credit card deposits (FundingTypeID=1); no-ops for other payment types.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - resolves ProtocolID via Billing.Deposit + Billing.Depot; targets Billing.MonthlyQuota |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateMonthlyProcessingQuota` accumulates deposit transaction amounts into `Billing.MonthlyQuota` - the monthly processing volume tracker used by the credit card routing algorithm. After each successful credit card deposit is credited to the customer's account, `Customer.SetBalanceDeposit` calls this procedure to add the deposit amount to the current month's running total for the payment protocol (WorldPay, Checkout, IxopayNuvei, etc.) that processed the transaction.

The monthly quota data is then consumed by the routing SPs (`Billing.GetCCProcessingBundle`, `GetCCProcessingBundleByBin`, `GetCCProcessingBundleByBinUS`) to select which payment processor to route the next deposit to - balancing load across processors and ensuring no single processor approaches its monthly processing capacity limit.

The SP silently no-ops for non-credit-card deposits by checking if the deposit's depot has `FundingTypeID=1`. Wire transfers, PayPal, and other payment methods do not have monthly quota tracking.

Created June 2018 by Ran Ovadia (ticket 51351, parent of 51486).

Active monthly volumes as of March 2026: WorldPay ($13.8M), Checkout ($16.9M), IxopayNuvei ($2.5M).

---

## 2. Business Logic

### 2.1 Credit Card Protocol Resolution

**What**: Resolves which payment protocol (acquiring bank's processing system) handled this deposit, by traversing Deposit -> Depot -> Protocol.

**Columns/Parameters Involved**: `@DepositID`, `Billing.Deposit.DepotID`, `Billing.Depot.ProtocolID`, `Billing.Depot.FundingTypeID`

**Rules**:
- SELECT `ProtocolID` FROM `Billing.Depot` WHERE `FundingTypeID=1` AND `DepotID IN (SELECT DepotID FROM Billing.Deposit WHERE DepositID=@DepositID)`
- `FundingTypeID=1` filter: only credit card depots participate in monthly quota tracking
- If no credit card depot found (wire transfer, PayPal, etc.) -> `@ProtocolID IS NULL` -> `RETURN` immediately (no-op)
- Protocol is the payment processing network (WorldPay, Checkout, etc.); multiple depots can share the same ProtocolID

### 2.2 Monthly UPSERT - Accumulate Amount

**What**: Either adds @Amount to the existing monthly total for this protocol, or inserts the first row for this protocol/month if it doesn't exist yet.

**Columns/Parameters Involved**: `@ProtocolID`, `@Year`, `@Month`, `@Amount`, `Billing.MonthlyQuota.Amount`, `Billing.MonthlyQuota.TimeStamp`

**Rules**:
- `@Year = YEAR(GETUTCDATE())`, `@Month = MONTH(GETUTCDATE())`: current UTC calendar period
- IF row EXISTS for `(ProtocolID, Year, Month)`:
  - UPDATE: `Amount = Amount + @Amount`, `TimeStamp = GETUTCDATE()`
- ELSE (first deposit this month for this protocol):
  - INSERT: `(ProtocolID, Year, Month, @Amount, GETUTCDATE())`
- UNIQUE constraint on `(ProtocolID, Year, Month)` in `Billing.MonthlyQuota` ensures exactly one running total per protocol per month
- `@Amount` is DECIMAL(18,2) - supports fractional USD amounts

**Diagram**:
```
Customer makes a $250 USD credit card deposit:
  Customer.SetBalanceDeposit is called (account crediting)
    |
    EXEC Billing.UpdateMonthlyProcessingQuota @DepositID=X, @Amount=250

      Step 1: Resolve protocol
        SELECT ProtocolID FROM Billing.Depot
        WHERE FundingTypeID=1 AND DepotID IN (SELECT DepotID FROM Billing.Deposit WHERE DepositID=X)
        -> ProtocolID = 5 (e.g., Checkout)
        [If NULL -> RETURN (not a CC deposit)]

      Step 2: Upsert monthly total
        IF EXISTS (ProtocolID=5, Year=2026, Month=3):
          UPDATE: Amount = Amount + 250  (e.g., 16,900,250.00)
          TimeStamp = GETUTCDATE()
        ELSE:
          INSERT: (ProtocolID=5, Year=2026, Month=3, Amount=250, TimeStamp=now)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | The deposit whose protocol and amount to accumulate. Used to resolve the payment protocol via Billing.Deposit -> Billing.Depot (FundingTypeID=1 only). If the deposit is not a credit card deposit, the SP returns immediately with no changes. |
| 2 | @Amount | DECIMAL(18,2) | NO | - | CODE-BACKED | Deposit amount to add to the monthly quota. Accumulated in `Billing.MonthlyQuota.Amount` for the resolved protocol's current year/month. Represents the USD value (or deposit currency value) of the processed deposit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE DepositID (subquery) | Billing.Deposit | SELECT (subquery) | Resolves the DepotID for the specified deposit |
| WHERE FundingTypeID=1 | Billing.Depot | SELECT (WITH NOLOCK) | Resolves the ProtocolID from the deposit's credit card depot |
| UPSERT (ProtocolID, Year, Month) | Billing.MonthlyQuota | UPDATE or INSERT | Accumulates deposit amount into the current month's running total |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalanceDeposit | @DepositID, @Amount | EXEC (SQL caller) | Called after a deposit is credited to the customer account to update the monthly processing quota |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateMonthlyProcessingQuota (procedure)
|- Billing.Deposit (table) - SELECT subquery (DepotID resolution)
|- Billing.Depot (table) - SELECT WITH NOLOCK (ProtocolID resolution, FundingTypeID=1 filter)
`- Billing.MonthlyQuota (table) - UPDATE or INSERT (quota accumulation)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SELECT (WITH NOLOCK) subquery - resolves DepotID for the given deposit |
| Billing.Depot | Table | SELECT (WITH NOLOCK) - resolves ProtocolID; FundingTypeID=1 filter gates CC-only processing |
| Billing.MonthlyQuota | Table | UPDATE (accumulate Amount) or INSERT (first deposit this month for protocol) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalanceDeposit | Procedure | EXEC caller - called after account crediting to track CC processing volumes |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Key indexes used:
- `Billing.MonthlyQuota`: UNIQUE NC on `(ProtocolID, Year, Month)` - supports both the existence check and the UPDATE/INSERT
- `Billing.Depot`: UNIQUE index on `(FundingTypeID, PaymentTypeID, ProtocolID)` (`BDPT_DEPOT`) - used in the ProtocolID resolution subquery

### 7.2 Constraints

N/A for stored procedure. Note: The upsert is implemented as a two-step IF EXISTS / UPDATE-ELSE INSERT pattern rather than MERGE. Under very high concurrency, two simultaneous calls for the same (ProtocolID, Year, Month) could both fail the EXISTS check and attempt simultaneous INSERTs - the UNIQUE constraint on MonthlyQuota would cause one to fail with a duplicate key error. In practice, this race is unlikely due to call serialization in the deposit processing pipeline.

---

## 8. Sample Queries

### 8.1 View current month's quota for all protocols
```sql
SELECT mq.ProtocolID, mq.Amount, mq.TimeStamp
FROM Billing.MonthlyQuota mq WITH (NOLOCK)
WHERE mq.Year = YEAR(GETUTCDATE())
  AND mq.Month = MONTH(GETUTCDATE())
ORDER BY mq.Amount DESC;
```

### 8.2 Check the protocol for a specific deposit (simulate SP logic)
```sql
SELECT DISTINCT d.DepotID, dep.ProtocolID, dep.FundingTypeID
FROM Billing.Deposit d WITH (NOLOCK)
INNER JOIN Billing.Depot dep WITH (NOLOCK)
    ON dep.DepotID = d.DepotID AND dep.FundingTypeID = 1
WHERE d.DepositID = 10780413;
-- NULL result = not a credit card deposit (SP would no-op)
```

### 8.3 Month-over-month quota trend for a protocol
```sql
SELECT Year, Month, Amount, TimeStamp
FROM Billing.MonthlyQuota WITH (NOLOCK)
WHERE ProtocolID = 5 -- e.g., Checkout
ORDER BY Year DESC, Month DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Internal code comment references ticket 51351 (June 2018, Ran Ovadia) as the parent feature for monthly quota tracking.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed (Customer.SetBalanceDeposit) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateMonthlyProcessingQuota | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateMonthlyProcessingQuota.sql*
