# AffiliateCommission.UpdateCreditEventLastCheckDate

> Updates the last check date and affiliate attribution on a credit event, ensuring only forward-moving timestamps are recorded.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates LastCheckDate and AffiliateID on CreditEvent by CreditID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records when a credit event (deposit or chargeback) was last evaluated by the commission processing engine and updates the affiliate attribution simultaneously. The LastCheckDate serves as a watermark indicating the most recent point in time that the credit event was assessed for commission eligibility.

The procedure enforces a forward-only timestamp rule: it only updates the LastCheckDate if the new date is more recent than the existing one, or if no previous check date exists. This prevents stale or out-of-order processing runs from overwriting more recent evaluation results, which is critical in distributed processing scenarios.

The AffiliateID is updated alongside the check date because affiliate attribution may change over time due to reattribution events. This ensures the credit event always reflects the most recently evaluated affiliate assignment, and follows the same pattern used by UpdateClosedPositionEventLastCheckDate and UpdateRegistrationEventLastCheckDate.

---

## 2. Business Logic

### 2.1 Forward-Only Check Date Update

**What**: Updates LastCheckDate and AffiliateID on a credit event, but only if the new date is more recent or no previous date exists.

**Columns/Parameters Involved**: @CreditID, @Date, @AffiliateID, CreditEvent.LastCheckDate, CreditEvent.AffiliateID

**Rules**:
- Updates only WHERE LastCheckDate IS NULL OR LastCheckDate < @Date
- This prevents backward timestamp updates from stale processing runs
- AffiliateID is always set alongside the date update
- Targets a single event record by CreditID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditID | BIGINT | No | - | CODE-BACKED | Unique identifier of the credit event to update |
| 2 | @Date | DATETIME | No | - | CODE-BACKED | The new last-check timestamp to record |
| 3 | @AffiliateID | INT | No | - | CODE-BACKED | The affiliate ID to attribute to this event |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CreditID | AffiliateCommission.CreditEvent | UPDATE target | Updates LastCheckDate and AffiliateID on the event record |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing engine during credit event evaluation cycles.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateCreditEventLastCheckDate
  --> AffiliateCommission.CreditEvent (UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEvent | Table | UPDATE target - sets LastCheckDate and AffiliateID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Commission processing service | Application | Calls this SP after evaluating a credit event |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update last check date for a credit event
```sql
EXEC AffiliateCommission.UpdateCreditEventLastCheckDate
    @CreditID = 123456,
    @Date = '2026-04-12 14:00:00',
    @AffiliateID = 1001;
```

### 8.2 Check current last check date for a credit event
```sql
SELECT CreditID, LastCheckDate, AffiliateID
FROM AffiliateCommission.CreditEvent WITH (NOLOCK)
WHERE CreditID = 123456;
```

### 8.3 Find credit events that have never been checked
```sql
SELECT CreditID, CID
FROM AffiliateCommission.CreditEvent WITH (NOLOCK)
WHERE LastCheckDate IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-2889: Fix RegistrationCommission AffiliateID (28/3/2023)
- PART-2448: CPA New Compensation Design (17/12/23)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpdateCreditEventLastCheckDate | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateCreditEventLastCheckDate.sql*
