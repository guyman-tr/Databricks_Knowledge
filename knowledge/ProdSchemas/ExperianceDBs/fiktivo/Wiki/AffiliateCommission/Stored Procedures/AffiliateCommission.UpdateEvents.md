# AffiliateCommission.UpdateEvents

> Sets the NonOrganicUpdated timestamp on all three event tables for a customer, triggering commission reprocessing after organic-to-non-organic reclassification.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Sets NonOrganicUpdated = GETUTCDATE() on CreditEvent, ClosedPositionEvent, and RegistrationEvent by CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a cross-domain trigger that marks all event records for a given customer as needing commission reprocessing due to a change in their organic/non-organic classification. When a customer who was previously classified as "organic" (not attributed to any affiliate) is reclassified as "non-organic" (attributed to an affiliate), all their existing events across all three commission domains need to be re-evaluated.

The NonOrganicUpdated timestamp acts as a signal to the commission engine that these events should be picked up for reprocessing. The procedure only sets this timestamp on records where it is currently NULL, meaning each event is only flagged once - subsequent calls for the same customer will not re-flag already-marked events.

By updating all three event tables (CreditEvent, ClosedPositionEvent, RegistrationEvent) in a single call, the procedure ensures that all commission-eligible activity for the customer is consistently flagged for reprocessing regardless of domain.

---

## 2. Business Logic

### 2.1 Cross-Domain NonOrganic Flag

**What**: Sets NonOrganicUpdated = GETUTCDATE() on all three event tables for events belonging to a specific customer that have not yet been flagged.

**Columns/Parameters Involved**: @CID, CreditEvent.NonOrganicUpdated, ClosedPositionEvent.NonOrganicUpdated, RegistrationEvent.NonOrganicUpdated

**Rules**:
- Updates CreditEvent, ClosedPositionEvent, and RegistrationEvent in sequence
- Only updates rows WHERE CID = @CID AND NonOrganicUpdated IS NULL
- Uses GETUTCDATE() as the timestamp (UTC time of execution)
- Idempotent for previously flagged events - NULL check prevents re-flagging

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | BIGINT | No | - | CODE-BACKED | Customer ID whose events need to be flagged for reprocessing |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateCommission.CreditEvent | UPDATE target | Sets NonOrganicUpdated timestamp |
| @CID | AffiliateCommission.ClosedPositionEvent | UPDATE target | Sets NonOrganicUpdated timestamp |
| @CID | AffiliateCommission.RegistrationEvent | UPDATE target | Sets NonOrganicUpdated timestamp |

### 5.2 Referenced By (other objects point to this)

Called by the attribution service when a customer is reclassified from organic to non-organic (affiliate-attributed).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateEvents
  --> AffiliateCommission.CreditEvent (UPDATE)
  --> AffiliateCommission.ClosedPositionEvent (UPDATE)
  --> AffiliateCommission.RegistrationEvent (UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEvent | Table | UPDATE target - sets NonOrganicUpdated |
| AffiliateCommission.ClosedPositionEvent | Table | UPDATE target - sets NonOrganicUpdated |
| AffiliateCommission.RegistrationEvent | Table | UPDATE target - sets NonOrganicUpdated |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Attribution/reclassification service | Application | Calls this SP when customer organic status changes |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Flag all events for a customer for reprocessing
```sql
EXEC AffiliateCommission.UpdateEvents @CID = 500001;
```

### 8.2 Check NonOrganicUpdated status for a customer across all domains
```sql
SELECT 'CreditEvent' AS Domain, CreditID AS EventID, NonOrganicUpdated
FROM AffiliateCommission.CreditEvent WITH (NOLOCK)
WHERE CID = 500001
UNION ALL
SELECT 'ClosedPositionEvent', ClosedPositionID, NonOrganicUpdated
FROM AffiliateCommission.ClosedPositionEvent WITH (NOLOCK)
WHERE CID = 500001
UNION ALL
SELECT 'RegistrationEvent', RegistrationID, NonOrganicUpdated
FROM AffiliateCommission.RegistrationEvent WITH (NOLOCK)
WHERE CID = 500001;
```

### 8.3 Count unflagged events across all domains
```sql
SELECT 'CreditEvent' AS Domain, COUNT(*) AS UnflaggedCount
FROM AffiliateCommission.CreditEvent WITH (NOLOCK)
WHERE NonOrganicUpdated IS NULL
UNION ALL
SELECT 'ClosedPositionEvent', COUNT(*)
FROM AffiliateCommission.ClosedPositionEvent WITH (NOLOCK)
WHERE NonOrganicUpdated IS NULL
UNION ALL
SELECT 'RegistrationEvent', COUNT(*)
FROM AffiliateCommission.RegistrationEvent WITH (NOLOCK)
WHERE NonOrganicUpdated IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-1195: New SP, support Registration Commission (22/2/2022)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpdateEvents | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateEvents.sql*
