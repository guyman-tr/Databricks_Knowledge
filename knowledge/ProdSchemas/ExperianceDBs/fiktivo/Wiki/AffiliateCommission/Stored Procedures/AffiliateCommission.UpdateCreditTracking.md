# AffiliateCommission.UpdateCreditTracking

> Marks a credit event as fully processed in the commission pipeline by setting its IsProcessed flag to 1.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Sets IsProcessed = 1 on Credit by CreditID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure marks a credit event (deposit or chargeback) as fully processed by the affiliate commission engine. Once a credit has been evaluated for commission eligibility, the commission has been calculated, and all downstream tracking records have been updated, this procedure is called to set IsProcessed = 1, indicating that the event requires no further processing.

The IsProcessed flag is a key state indicator in the credit commission pipeline. Unprocessed records (IsProcessed = 0) are picked up by the commission engine for evaluation. After successful processing - including eligibility checks, commission calculation, and affiliate attribution - this procedure finalizes the record's state.

This follows the same tracking pattern used across all three commission domains: ClosedPosition (trading), Credit (deposits/chargebacks), and Registration (signups), each with their own UpdateTracking procedure.

---

## 2. Business Logic

### 2.1 Processing State Update

**What**: Sets IsProcessed = 1 on a single credit record to indicate commission processing is complete.

**Columns/Parameters Involved**: @CreditID, Credit.IsProcessed

**Rules**:
- Targets a single record by CreditID
- Unconditionally sets IsProcessed = 1
- No validation of current state - caller is responsible for ensuring processing was successful before calling

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditID | BIGINT | No | - | CODE-BACKED | Unique identifier of the credit record to mark as processed |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CreditID | AffiliateCommission.Credit | UPDATE target | Sets IsProcessed = 1 on the Credit table |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing engine as the final step after a credit event has been fully evaluated and commission records have been written.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateCreditTracking
  --> AffiliateCommission.Credit (UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | UPDATE target - sets IsProcessed = 1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Commission processing service | Application | Calls this SP to finalize credit processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Mark a credit as processed
```sql
EXEC AffiliateCommission.UpdateCreditTracking @CreditID = 123456;
```

### 8.2 Check processing state of a credit
```sql
SELECT CreditID, IsProcessed, Valid, CID
FROM AffiliateCommission.Credit WITH (NOLOCK)
WHERE CreditID = 123456;
```

### 8.3 Count unprocessed credits
```sql
SELECT COUNT(*) AS UnprocessedCount
FROM AffiliateCommission.Credit WITH (NOLOCK)
WHERE IsProcessed = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-1195: New SP output RegistrationID (22/2/2022)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpdateCreditTracking | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateCreditTracking.sql*
