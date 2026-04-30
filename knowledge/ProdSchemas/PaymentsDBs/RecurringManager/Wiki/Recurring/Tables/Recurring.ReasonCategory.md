# Recurring.ReasonCategory

> Lookup table that categorizes payment decline reasons into high-level business categories used by the execution status result configuration engine.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Table |
| **Key Identifier** | ReasonCategoryId (INT, IDENTITY) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 1 unique nonclustered on Name |

---

## 1. Business Meaning

Recurring.ReasonCategory is a lookup table that classifies payment processing decline reasons into standardized business categories. Each category represents a broad class of payment failure (e.g., insufficient funds, expired card, transaction not permitted) that the system uses to determine how to handle failed recurring payment executions.

This table exists to provide a controlled vocabulary for decline reasons. Without it, the system would have no standardized way to categorize why a recurring payment attempt failed, making it impossible to configure automated responses (retry vs. block vs. escalate) based on failure type.

Rows in this table are reference data, seeded at deployment time. The ExecutionStatusResultConfig table references ReasonCategoryId to map specific payment status + status code combinations to a decline category, enabling the system to apply different handling rules depending on why a payment failed.

---

## 2. Business Logic

### 2.1 Payment Decline Categorization

**What**: Standardized categories for recurring payment processing failures, used to drive automated handling decisions.

**Columns/Parameters Involved**: `ReasonCategoryId`, `Name`

**Rules**:
- Each category represents a distinct class of payment decline from the payment processor
- Category 0 (UNKNOWN) is the fallback for unrecognized decline codes
- Categories are referenced by ExecutionStatusResultConfig to determine whether a failed execution should be retried, blocked, or escalated
- Card-related declines (EXPIRED_CARD, TRANSACTION_NOT_PERMITTED_TO_CARDHOLDER) typically indicate the payment method needs updating, not a transient failure

**Value Map**:

| ReasonCategoryId | Name | Business Meaning |
|---|---|---|
| 0 | UNKNOWN | Fallback category for decline codes not yet mapped to a specific reason |
| 1 | INSUFFICIENT_FUNDS | Customer's payment method lacks sufficient balance to cover the recurring amount |
| 2 | TRANSACTION_NOT_PERMITTED_TO_CARDHOLDER | The card issuer has restricted this type of transaction for the cardholder |
| 3 | INVALID_TRANSACTION | The transaction was rejected by the processor as structurally invalid |
| 4 | DECLINED_DO_NOT_HONOUR | Generic decline from the issuing bank with no specific reason provided |
| 5 | EXCEEDS_WITHDRAWAL | The transaction amount exceeds the card's withdrawal or spending limit |
| 6 | EXPIRED_CARD | The payment card has passed its expiration date |

---

## 3. Data Overview

| ReasonCategoryId | Name | Meaning |
|---|---|---|
| 0 | UNKNOWN | Catch-all for unmapped processor decline codes. Used when the system receives a decline status code that has no explicit mapping in ExecutionStatusResultConfig. |
| 1 | INSUFFICIENT_FUNDS | Most common transient failure - the customer's account balance is too low. These are typically retry-eligible since the customer may deposit funds before the next attempt. |
| 4 | DECLINED_DO_NOT_HONOUR | The issuing bank refused the charge without explanation. This is the most common generic decline and may warrant different retry logic than specific declines. |
| 5 | EXCEEDS_WITHDRAWAL | The recurring payment amount exceeds the card's per-transaction or daily limit. May require the customer to adjust their card limits or payment amount. |
| 6 | EXPIRED_CARD | Terminal failure - the card is expired and cannot process payments. The customer must update their payment method before recurring payments can resume. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReasonCategoryId | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key identifying each decline reason category. Referenced by Recurring.ExecutionStatusResultConfig.ReasonCategoryId to map payment status/code combinations to a decline category. Note: actual values start at 0 (explicitly seeded), not 1. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Unique machine-readable label for the decline category using SCREAMING_SNAKE_CASE convention (e.g., INSUFFICIENT_FUNDS, EXPIRED_CARD). Used as the business identifier for the category. Enforced unique via nonclustered index. |
| 3 | CreatedAt | datetime2(7) | YES | sysutcdatetime() | CODE-BACKED | UTC timestamp when the category row was created. Auto-populated by default constraint. All existing rows share the same timestamp (2025-07-27), indicating they were seeded in a single deployment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a leaf lookup table.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recurring.ExecutionStatusResultConfig | ReasonCategoryId | Implicit FK (Lookup) | Maps specific payment execution outcomes (status + status code combinations) to a decline reason category, enabling category-based handling rules |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.ExecutionStatusResultConfig | Table | ReasonCategoryId column references this table for decline categorization |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (ReasonCategoryId) | CLUSTERED | ReasonCategoryId ASC | - | - | Active |
| UQ (Name) | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ReasonCategory | PRIMARY KEY | Clustered on ReasonCategoryId - ensures each category has a unique identifier |
| UNIQUE (Name) | UNIQUE | Ensures no two categories share the same name label |
| DEFAULT (CreatedAt) | DEFAULT | sysutcdatetime() - auto-stamps creation time in UTC |

---

## 8. Sample Queries

### 8.1 List all decline reason categories
```sql
SELECT ReasonCategoryId, Name
FROM Recurring.ReasonCategory WITH (NOLOCK)
ORDER BY ReasonCategoryId
```

### 8.2 Find execution status configs for a specific decline category
```sql
SELECT esrc.ExecutionStatusResultConfigId,
       esrc.PaymentStatusId,
       esrc.StatusCode,
       esrc.ExecutionStatusId,
       esrc.IsBlocked,
       esrc.ExecutionResultStatusId,
       rc.Name AS ReasonCategoryName
FROM Recurring.ExecutionStatusResultConfig esrc WITH (NOLOCK)
INNER JOIN Recurring.ReasonCategory rc WITH (NOLOCK)
    ON esrc.ReasonCategoryId = rc.ReasonCategoryId
WHERE rc.Name = 'INSUFFICIENT_FUNDS'
```

### 8.3 Summarize execution status configs by decline category
```sql
SELECT rc.ReasonCategoryId,
       rc.Name AS ReasonCategory,
       COUNT(*) AS ConfigCount,
       SUM(CASE WHEN esrc.IsBlocked = 1 THEN 1 ELSE 0 END) AS BlockedConfigs
FROM Recurring.ReasonCategory rc WITH (NOLOCK)
LEFT JOIN Recurring.ExecutionStatusResultConfig esrc WITH (NOLOCK)
    ON rc.ReasonCategoryId = esrc.ReasonCategoryId
GROUP BY rc.ReasonCategoryId, rc.Name
ORDER BY rc.ReasonCategoryId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.ReasonCategory | Type: Table | Source: RecurringManager/Recurring/Tables/Recurring.ReasonCategory.sql*
