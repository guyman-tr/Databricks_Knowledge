# BackOffice.PaymentTypesAndActivityPeriod

> Table-valued parameter type that pairs a payment method type with a minimum activity date cutoff, used to control which funding types are eligible for cash-out refund calculations.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | PaymentTypeID (NOT NULL - the funding type identifier) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.PaymentTypesAndActivityPeriod` is a Table-Valued Type (TVT) that passes a list of eligible payment method types alongside a per-type activity date threshold into withdrawal (cashout) processing procedures. Each row specifies a `PaymentTypeID` (referencing `Billing.FundingType`) and a `MinActivityDate` cutoff - only transactions of that payment type dated after the cutoff are considered eligible for refund breakdown or cash-out routing.

This type exists to let the caller configure per-payment-type eligibility rules dynamically, without hardcoding them into the procedure. Different business scenarios call for different sets of eligible payment types with different time windows - for example, credit card refunds might only be eligible if the card was used within the last 12 months, while wire transfers might have a different window.

Data flows into this type from the cashout processing application (circa 2019 "cashout tool" redesign). The consuming procedure `BackOffice.GetCashActivities` uses two instances of this type: `@PayablePaymentTypesAndDates` (for determining which funding types can receive the cashout) and `@RefundablePaymentTypesAndDates` (for determining which deposits are eligible for refund-back). The procedure JOINs deposit and withdraw-to-funding records against these lists to build the cashout eligibility picture.

---

## 2. Business Logic

### 2.1 Per-Payment-Type Activity Window Filtering

**What**: Each row defines a distinct payment method and the earliest transaction date that qualifies for cashout consideration - enabling fine-grained per-method eligibility control.

**Columns/Parameters Involved**: `PaymentTypeID`, `MinActivityDate`

**Rules**:
- `PaymentTypeID` maps to `Billing.Funding.FundingTypeID`. Only deposits/withdrawals with a matching FundingTypeID are eligible.
- `MinActivityDate` is the cutoff: transactions with dates BEFORE this value are excluded. A NULL `MinActivityDate` means no date restriction for that payment type.
- The type is used TWICE in `GetCashActivities`: once as `@PayablePaymentTypesAndDates` (governs which funding types can receive the cash out) and once as `@RefundablePaymentTypesAndDates` (governs which deposits are eligible for refund-back to the original funding).
- For refunds: `FundingTypesAndDates.MinActivityDate < Deposits.PaymentDate` - only deposits made after the minimum activity date qualify.
- An empty list means no payment types are eligible (the JOIN returns no rows, so no cash activities are visible).

**Diagram**:
```
@PayablePaymentTypesAndDates:
  [(PaymentTypeID=1, MinActivityDate='2024-01-01'),    <- Credit cards, activity since 2024
   (PaymentTypeID=2, MinActivityDate='2023-01-01'),    <- Bank transfer, since 2023
   (PaymentTypeID=8, MinActivityDate=NULL)]            <- PayPal, no date restriction
         |
         v
BackOffice.GetCashActivities
  - Deposits: FundingTypeID IN (SELECT PaymentTypeID FROM @PayablePaymentTypesAndDates)
  - Refunds:  MinActivityDate < Deposits.PaymentDate per funding type
  - Results:  Only deposits/withdrawals for eligible funding types within the activity window
```

---

## 3. Data Overview

N/A for User Defined Type. This is a transient parameter container, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentTypeID | int | NO | - | CODE-BACKED | Payment method type identifier. Maps to Billing.Funding.FundingTypeID. Specifies which funding type (credit card, bank transfer, PayPal, etc.) this eligibility row applies to. NOT NULL - every row must identify a specific payment type. Example values from GetCashActivities usage: 1=Credit Card, 2=Bank Transfer, 3=?, 6=?, 8=?, 10=?, 22=?, 28=?, 29=?, 21=?, 32=? (see Billing.FundingType for full mapping). |
| 2 | MinActivityDate | datetime | YES | - | CODE-BACKED | Minimum (earliest) transaction date threshold for this payment type. Only deposits or withdraw-to-funding records dated after this value qualify for cashout eligibility. NULL means no date restriction. Used in JOIN: FundingTypesAndDates.MinActivityDate < Deposits.PaymentDate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentTypeID | Billing.Funding.FundingTypeID | Implicit | Identifies which funding type category this eligibility rule applies to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCashActivities | @PayablePaymentTypesAndDates | Schema contract | Governs which funding types are eligible to receive the cash-out amount |
| BackOffice.GetCashActivities | @RefundablePaymentTypesAndDates | Schema contract | Governs which deposit records are eligible for refund-back to the original funding method |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCashActivities | Stored Procedure | Used TWICE as READONLY parameters: @PayablePaymentTypesAndDates (deposit eligibility filter) and @RefundablePaymentTypesAndDates (refund deposit eligibility filter). JOINed against Billing.Deposit.FundingTypeID to scope cash activity results. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PaymentTypeID NOT NULL | Column constraint | Every row must specify a payment type - NULL payment types are not valid eligibility rules. |

---

## 8. Sample Queries

### 8.1 Build standard payable payment types and call GetCashActivities

```sql
DECLARE @payable BackOffice.PaymentTypesAndActivityPeriod;
DECLARE @refundable BackOffice.PaymentTypesAndActivityPeriod;
DECLARE @unsupported BackOffice.IDs;

-- Payable types: credit card (1), bank transfer (2), PayPal (8) etc. with 2-year window
INSERT INTO @payable (PaymentTypeID, MinActivityDate)
VALUES (1, '2024-01-01'),
       (2, '2023-01-01'),
       (8, NULL);

-- Refundable: only credit card deposits from last 18 months
INSERT INTO @refundable (PaymentTypeID, MinActivityDate)
VALUES (1, '2024-09-01');

EXEC BackOffice.GetCashActivities
    @CID = 123456,
    @WithdrawID = 789,
    @IsBlockAllow = 0,
    @PayablePaymentTypesAndDates = @payable,
    @RefundablePaymentTypesAndDates = @refundable,
    @IsThirdPartyBalanced = 0,
    @UnsupportedFundingIds = @unsupported;
```

### 8.2 No date restriction on any payment type

```sql
DECLARE @payable BackOffice.PaymentTypesAndActivityPeriod;

INSERT INTO @payable (PaymentTypeID, MinActivityDate)
VALUES (1, NULL),  -- Credit card, all time
       (2, NULL),  -- Bank transfer, all time
       (22, NULL); -- eWallet, all time

SELECT * FROM @payable WITH (NOLOCK);
```

### 8.3 Inspect activity window per type

```sql
DECLARE @types BackOffice.PaymentTypesAndActivityPeriod;

INSERT INTO @types VALUES (1, '2024-01-01'), (2, '2023-06-01'), (8, NULL);

SELECT t.PaymentTypeID,
       t.MinActivityDate,
       DATEDIFF(DAY, t.MinActivityDate, GETDATE()) AS WindowDays
FROM @types t WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.PaymentTypesAndActivityPeriod | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.PaymentTypesAndActivityPeriod.sql*
