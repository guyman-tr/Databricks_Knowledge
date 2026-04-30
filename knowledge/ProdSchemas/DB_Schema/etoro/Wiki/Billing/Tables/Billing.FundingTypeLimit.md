# Billing.FundingTypeLimit

> Configuration table defining transaction frequency and amount limits per payment method - stores daily, weekly, and monthly caps (count and amount) checked before allowing a deposit. Currently empty (no active limits configured).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | FundingTypeLimitID (IDENTITY PK, NONCLUSTERED) |
| **Partition** | No (MAIN filegroup, FILLFACTOR 90) |
| **Indexes** | 2 (NC PK on FundingTypeLimitID + NC on FundingTypeID) |

---

## 1. Business Meaning

`Billing.FundingTypeLimit` is a per-payment-method transaction limit configuration table. Each row defines the maximum number of transactions and maximum total amount allowed for a specific payment method (`FundingTypeID`) over three time windows: daily, weekly, and monthly. Before processing a deposit, the `CheckFundingTypeLimit` and `CheckFundingTypeLimitByCCNumber` procedures query this table to determine whether the customer has reached their limit for that payment method.

The table is currently empty - no limits are actively configured for any payment method. This means limit checks will return a null result set (no limits to enforce), and deposits proceed unconstrained. The infrastructure is in place for when limits need to be activated.

The `NOT FOR REPLICATION` flag on the IDENTITY column indicates this table participates in SQL Server replication. The PK is NONCLUSTERED (unusual), with the lookup index on `FundingTypeID` being the effectively used access path during limit checks.

The limit check procedure computes 6 distinct violations (returned as `@CheckResult` OUTPUT parameter):
- 1 = Monthly transaction count exceeded
- 2 = Monthly amount exceeded
- 3 = Weekly transaction count exceeded
- 4 = Weekly amount exceeded
- 5 = Daily transaction count exceeded
- 6 = Daily amount exceeded
- 0 = No limit exceeded

---

## 2. Business Logic

### 2.1 Limit Check Pattern

**What**: Before a deposit, the system checks if the customer has exceeded their payment-method-specific limits.

**Columns/Parameters Involved**: `FundingTypeID`, `DailyTransaction`, `DailyAmount`, `WeeklyTransaction`, `WeeklyAmount`, `MonthlyTransaction`, `MonthlyAmount`

**Rules**:
- `CheckFundingTypeLimit(@CID, @FundingTypeID, @CheckResult OUTPUT)`:
  1. Loads the customer's transactions for the current month (from Billing.Payment + Billing.Deposit).
  2. Reads this table for the payment method's limits.
  3. Checks monthly count, monthly amount, weekly count, weekly amount, daily count, daily amount - in that order.
  4. Returns `@CheckResult` = 0 (OK) or 1-6 (specific violation).
- `CheckFundingTypeLimitByCCNumber` performs the same check but also filters by specific credit card number (for card-level limits).
- Amount columns are in minor currency units (cents): deposits contribute `Amount * 100` to the running total.
- Week starts Monday (SET DATEFIRST 1).
- If no row exists for a FundingTypeID in this table, `@CheckResult = 0` (no limits = no violations).

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 0 |
| Active limits | None currently configured |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeLimitID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Surrogate primary key. NONCLUSTERED (unusual - typically clustered). NOT FOR REPLICATION on IDENTITY. The FundingTypeID index is the primary access path. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method these limits apply to. Implicit FK to Dictionary.FundingType. Indexed via BFTL_FUNDINGTYPE for fast lookup in limit checks: `WHERE FundingTypeID = @FundingTypeID`. |
| 3 | DailyTransaction | int | NO | - | CODE-BACKED | Maximum number of transactions allowed per day for this payment method. Compared against: `COUNT(*) WHERE PaymentDate >= today`. CheckResult=5 if exceeded. |
| 4 | DailyAmount | int | NO | - | CODE-BACKED | Maximum total amount allowed per day for this payment method, in minor currency units (cents). Compared against: `SUM(Amount) WHERE PaymentDate >= today`. CheckResult=6 if exceeded. |
| 5 | WeeklyTransaction | int | NO | - | CODE-BACKED | Maximum number of transactions allowed per week (Monday-start). Compared against: `COUNT(*) WHERE PaymentDate >= @WeekStart`. CheckResult=3 if exceeded. |
| 6 | WeeklyAmount | int | NO | - | CODE-BACKED | Maximum total amount allowed per week, in minor currency units (cents). Compared against: `SUM(Amount) WHERE PaymentDate >= @WeekStart`. CheckResult=4 if exceeded. |
| 7 | MonthlyTransaction | int | NO | - | CODE-BACKED | Maximum number of transactions allowed per calendar month. Compared against: `COUNT(*) WHERE PaymentDate >= first of current month`. CheckResult=1 if exceeded. |
| 8 | MonthlyAmount | int | NO | - | CODE-BACKED | Maximum total amount allowed per calendar month, in minor currency units (cents). Compared against: `SUM(Amount) WHERE PaymentDate >= first of current month`. CheckResult=2 if exceeded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit FK | Payment method for which limits are configured. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CheckFundingTypeLimit | FundingTypeID, all limit columns | READER | Reads limit thresholds for a payment method during deposit validation. |
| Billing.CheckFundingTypeLimitByCCNumber | FundingTypeID, all limit columns | READER | Same as above but filters by credit card number. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (leaf table).

---

### 6.1 Objects This Depends On

No dependencies (no FK constraints).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CheckFundingTypeLimit | Stored Procedure | READER - enforces transaction/amount limits per payment method |
| Billing.CheckFundingTypeLimitByCCNumber | Stored Procedure | READER - same enforcement, scoped to credit card number |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BFTL | NONCLUSTERED PK | FundingTypeLimitID ASC | - | - | Active |
| BFTL_FUNDINGTYPE | NONCLUSTERED | FundingTypeID ASC | - | - | Active |

Both FILLFACTOR=90. Both on MAIN filegroup. No clustered index - the table is heap-organized.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BFTL | PRIMARY KEY (NONCLUSTERED) | FundingTypeLimitID - unique limit row identifier |

---

## 8. Sample Queries

### 8.1 View all configured limits with payment method names

```sql
SELECT ft.Name AS FundingType,
    fl.DailyTransaction, fl.DailyAmount / 100.0 AS DailyAmountUSD,
    fl.WeeklyTransaction, fl.WeeklyAmount / 100.0 AS WeeklyAmountUSD,
    fl.MonthlyTransaction, fl.MonthlyAmount / 100.0 AS MonthlyAmountUSD
FROM [Billing].[FundingTypeLimit] fl WITH (NOLOCK)
JOIN [Dictionary].[FundingType] ft WITH (NOLOCK) ON fl.FundingTypeID = ft.FundingTypeID
ORDER BY ft.Name;
```

### 8.2 Check limits for a specific payment method

```sql
SELECT FundingTypeLimitID, FundingTypeID,
    DailyTransaction, DailyAmount,
    WeeklyTransaction, WeeklyAmount,
    MonthlyTransaction, MonthlyAmount
FROM [Billing].[FundingTypeLimit] WITH (NOLOCK)
WHERE FundingTypeID = 1;  -- CreditCard
```

### 8.3 Invoke limit check for a customer

```sql
DECLARE @Result INT;
EXEC [Billing].[CheckFundingTypeLimit] @CID = @CID, @FundingTypeID = 1, @CheckResult = @Result OUTPUT;
SELECT @Result AS CheckResult,
    CASE @Result
        WHEN 0 THEN 'OK - no limit exceeded'
        WHEN 1 THEN 'Monthly transaction count exceeded'
        WHEN 2 THEN 'Monthly amount exceeded'
        WHEN 3 THEN 'Weekly transaction count exceeded'
        WHEN 4 THEN 'Weekly amount exceeded'
        WHEN 5 THEN 'Daily transaction count exceeded'
        WHEN 6 THEN 'Daily amount exceeded'
    END AS ResultDescription;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeLimit | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.FundingTypeLimit.sql*
