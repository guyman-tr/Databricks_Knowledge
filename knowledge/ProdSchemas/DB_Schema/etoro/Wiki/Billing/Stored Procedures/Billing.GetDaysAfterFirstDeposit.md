# Billing.GetDaysAfterFirstDeposit

> Returns the number of days elapsed since a customer's first approved deposit (FTD), used by the business rules engine to evaluate time-based eligibility conditions.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns DaysFromFTD (INT) - days since first approved deposit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDaysAfterFirstDeposit` calculates the age (in days) of a customer's first-time deposit (FTD) by measuring the interval from the FTD's `PaymentDate` to the current UTC timestamp. An FTD is the customer's first ever approved deposit on eToro, identified by `IsFTD=1` in `Billing.Deposit`.

Without this procedure, business rule evaluations requiring deposit tenure (e.g., "has the customer deposited at least 30 days ago?") would require consumers to join and calculate inline. This procedure encapsulates that logic into a single, reusable call.

It is called by the business rules engine (`BusinessRuleUserForEtoro`) to support rule conditions such as deposit age thresholds for promotions, eligibility gates, withdrawal rules, and compliance checks. The procedure is read-only and returns a single integer row.

---

## 2. Business Logic

### 2.1 FTD Age Calculation

**What**: The number of calendar days between the customer's first approved deposit and the current UTC time.

**Columns/Parameters Involved**: `@CID`, `Billing.Deposit.PaymentDate`, `Billing.Deposit.PaymentStatusID`, `Billing.Deposit.IsFTD`

**Rules**:
- Only rows where `PaymentStatusID = 2` (Approved) are considered - declined, pending, or refunded deposits are excluded
- Only rows where `IsFTD = 1` are selected - this is the deposit that was the customer's first-ever approved deposit
- There is at most one row per customer with `IsFTD = 1` per Billing.Deposit lifecycle rules
- The calculation uses `DATEDIFF(day, PaymentDate, GETUTCDATE())` - full calendar days, not hours
- If the customer has no FTD (never deposited or deposit not yet approved), the procedure returns no rows

**Diagram**:
```
Input: @CID
  |
  v
Billing.Deposit WHERE CID=@CID AND PaymentStatusID=2 AND IsFTD=1
  |
  +-- PaymentDate (when FTD was approved)
  |
  v
DATEDIFF(day, PaymentDate, GETUTCDATE())
  |
  v
Output: DaysFromFTD (integer, 0+ days since FTD approval)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID - the identifier of the customer whose FTD age is being queried. Filters `Billing.Deposit.CID`. |
| 2 | DaysFromFTD | INT (return column) | YES | - | CODE-BACKED | Number of calendar days elapsed since the customer's first approved deposit (`IsFTD=1`, `PaymentStatusID=2`). Computed as `DATEDIFF(day, PaymentDate, GETUTCDATE())`. Returns no row if the customer has no approved FTD. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit.CID | Lookup | Filters deposits to the specified customer |
| (implicit) | Billing.Deposit.PaymentStatusID | Lookup | Hardcoded filter: 2=Approved - only approved deposits are eligible FTDs |
| (implicit) | Billing.Deposit.IsFTD | Lookup | Hardcoded filter: 1 - selects only the first-time deposit row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BusinessRuleUserForEtoro | GRANT EXECUTE | Permission | Called by the business rules engine for time-based eligibility evaluation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDaysAfterFirstDeposit (procedure)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SELECT with NOLOCK; filters by CID, PaymentStatusID=2, IsFTD=1; reads PaymentDate for DATEDIFF |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BusinessRuleUserForEtoro | DB User / Application | Calls this procedure as part of business rule evaluation (deposit age conditions) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check days since a customer's first deposit

```sql
EXEC Billing.GetDaysAfterFirstDeposit @CID = 12345;
```

### 8.2 Evaluate FTD age for a list of customers inline

```sql
-- For bulk checks, use the underlying table directly
SELECT
    CID,
    DATEDIFF(day, PaymentDate, GETUTCDATE()) AS DaysFromFTD
FROM Billing.Deposit WITH (NOLOCK)
WHERE PaymentStatusID = 2
  AND IsFTD = 1
  AND CID IN (12345, 67890, 11111);
```

### 8.3 Find customers whose FTD was more than 30 days ago

```sql
-- Inline equivalent for batch processing
SELECT
    d.CID,
    DATEDIFF(day, d.PaymentDate, GETUTCDATE()) AS DaysFromFTD
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.PaymentStatusID = 2
  AND d.IsFTD = 1
  AND DATEDIFF(day, d.PaymentDate, GETUTCDATE()) > 30;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Billing.GetDaysAfterFirstDeposit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDaysAfterFirstDeposit.sql*
