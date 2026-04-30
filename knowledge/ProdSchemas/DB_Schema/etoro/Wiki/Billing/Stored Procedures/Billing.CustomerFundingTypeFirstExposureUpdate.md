# Billing.CustomerFundingTypeFirstExposureUpdate

> Records the first time a customer encounters a payment method (funding type) by inserting a single row into `Billing.CustomerFundingTypeFirstExposure`; silently no-ops if the CID+FundingTypeID pair already exists.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingTypeID (deduplication key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerFundingTypeFirstExposureUpdate` is the sole write path for `Billing.CustomerFundingTypeFirstExposure`. It records the moment a customer first encounters a given payment method at eToro. The table stores one row per (CID, FundingTypeID) pair - this procedure enforces that deduplication by using an INSERT-if-not-exists pattern.

The procedure was created July 2022 by Elrom B. (PAYIL-4744). Its primary business driver is tracking **eToroMoney onboarding**: when a customer is first presented with FundingTypeID=33 (eToroMoney), this procedure is called to stamp the `ExposureDate`. The deposit info API (`Billing.GetCustomerDepositInfo`) later reads that date to send `eToroMoneyExposureDate` to the client app, enabling the front-end to tailor the payment flow for customers who have or haven't yet been introduced to eToroMoney.

As of March 2026, the table contains ~4,952 rows: eToroMoney (FundingTypeID=33) at 41% (2,037 rows) and CreditCard (FundingTypeID=1) at 30% (1,503 rows) are the dominant payment types tracked.

---

## 2. Business Logic

### 2.1 INSERT-If-Not-Exists (First-Exposure Deduplication)

**What**: Inserts a row only if no existing row matches the CID+FundingTypeID combination. A second call for the same pair produces zero rows inserted.

**Parameters Involved**: `@CID`, `@FundingTypeID`

**Rules**:
- Pattern: `INSERT INTO ... SELECT ... FROM (VALUES) AS List LEFT JOIN target ON CID+FundingTypeID WHERE tst.Id IS NULL`
- The LEFT JOIN on the covering index `IX_BCFTF_Cover (CID, FundingTypeID)` efficiently detects existence without a separate SELECT
- `ExposureDate = GETUTCDATE()` is always the current UTC time - the caller cannot supply a date
- If the pair already exists: `WHERE tst.Id IS NULL` is false for the existing row -> 0 rows inserted (silent no-op)
- If the pair is new: 1 row inserted with `ExposureDate = GETUTCDATE()`
- `SET NOCOUNT ON`: no rows-affected message returned to the caller

**Visual logic**:
```
CALL CustomerFundingTypeFirstExposureUpdate(@CID=100, @FundingTypeID=33)

First call:  Row (100,33) does NOT exist -> INSERT (ExposureDate=now) -> 1 row written
Second call: Row (100,33) EXISTS          -> WHERE IS NULL = false    -> 0 rows written
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | VERIFIED | Customer whose first exposure is being recorded. Written to `Billing.CustomerFundingTypeFirstExposure.CID`. Implicit FK to Customer.CustomerStatic. |
| 2 | @FundingTypeID | INTEGER | NO | - | VERIFIED | The payment method the customer encountered for the first time. Written to `Billing.CustomerFundingTypeFirstExposure.FundingTypeID`. Implicit FK to Billing.FundingType. Key value: 33=eToroMoney (the primary use case). Other active values: 1=CreditCard, 3=PayPal, and 40+ other funding types. |

**Return value**: None (no result set, no OUTPUT parameter, no RETURN value).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingTypeID | Billing.CustomerFundingTypeFirstExposure | Write (INSERT-if-not-exists) | Records first-exposure timestamp for the CID+FundingTypeID pair |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit service | @CID, @FundingTypeID | Caller | Called when a customer is first presented with a payment method (PAYIL-4744) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CustomerFundingTypeFirstExposureUpdate (procedure)
+-- Billing.CustomerFundingTypeFirstExposure (table) [INSERT target]
      +-- IX_BCFTF_Cover (index on CID, FundingTypeID) [used for deduplication check]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerFundingTypeFirstExposure | Table | INSERT target; LEFT JOIN used for deduplication check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCustomerDepositInfo | Stored Procedure | Reads ExposureDate for FundingTypeID=33 (eToroMoney) per customer |
| Deposit service | External | Sole caller for writing first-exposure records (PAYIL-4744) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**No explicit transaction**: Single-statement INSERT - inherently atomic. No MERGE (unlike `CreditCardSchemeIDInsert`); uses the INSERT-SELECT-LEFT JOIN-WHERE NULL idiom instead.

**Potential race condition**: Two simultaneous first calls for the same (CID, FundingTypeID) could both pass the NULL check and attempt concurrent INSERTs. The table has no UNIQUE constraint on (CID, FundingTypeID) - only an NC index - so both could succeed. However, the call pattern (per-customer serialization in the deposit flow) makes this practically impossible.

---

## 8. Sample Queries

### 8.1 Record first eToroMoney exposure for a customer

```sql
EXEC Billing.CustomerFundingTypeFirstExposureUpdate
    @CID = 24186018,
    @FundingTypeID = 33  -- eToroMoney
-- First call: inserts row with ExposureDate=now
-- Subsequent calls: no-op
```

### 8.2 Check a customer's first exposure dates per payment method

```sql
SELECT
    cfte.FundingTypeID,
    cfte.ExposureDate
FROM Billing.CustomerFundingTypeFirstExposure cfte WITH(NOLOCK)
WHERE cfte.CID = 24186018
ORDER BY cfte.ExposureDate
```

### 8.3 Count customers with eToroMoney first exposure

```sql
SELECT COUNT(*) AS CustomersExposedToEToroMoney
FROM Billing.CustomerFundingTypeFirstExposure WITH(NOLOCK)
WHERE FundingTypeID = 33
-- As of 2026-03-17: ~2,037 customers
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYIL-4744 | Jira | Initial implementation ticket (Elrom B., July 2022) - tracking first payment method exposure per customer |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerFundingTypeFirstExposureUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerFundingTypeFirstExposureUpdate.sql*
