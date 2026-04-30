# AffiliateAttribution.UpdateEvents

> Post-re-attribution procedure that timestamps the ReAttributeUpdated column on credit and closed position event records for a customer, signaling the commission pipeline to re-process these events under the new affiliate attribution.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAttribution |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE ReAttributeUpdated on CreditEvent + ClosedPositionEvent for a CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAttribution.UpdateEvents is the final step in the affiliate re-attribution workflow. After UpdateAffiliationInfo has changed the AffiliateID on commission records, this procedure marks the corresponding event records (CreditEvent and ClosedPositionEvent) with a ReAttributeUpdated timestamp. This signal tells the commission processing pipeline that these events need to be re-evaluated under the new affiliate attribution - potentially recalculating sub-affiliate commissions, eligibility rules, and event state transitions.

This procedure exists because changing the AffiliateID on commission records (UpdateAffiliationInfo) is not sufficient on its own. The event-driven commission pipeline maintains its own state in CreditEvent and ClosedPositionEvent tables. Without marking these events as re-attributed, the pipeline would not know to re-process them, and the downstream effects (sub-affiliate commissions, eligibility re-evaluation) would not occur.

Called by the Databricks re-attribution notebook as the third and final step, after GetAffiliateInfo (eligibility check) and UpdateAffiliationInfo (commission update). The procedure runs both UPDATEs in a single transaction with XACT_ABORT ON. Note: the RegistrationMetaData update was removed in PART-2757 and moved to a separate procedure.

---

## 2. Business Logic

### 2.1 Event Re-Processing Signal

**What**: Sets ReAttributeUpdated = GETUTCDATE() on event records to trigger pipeline re-processing.

**Columns/Parameters Involved**: `@CID`, `ReAttributeUpdated`

**Rules**:
- UPDATE 1: AffiliateCommission.CreditEvent SET ReAttributeUpdated = GETUTCDATE() WHERE CID = @CID
- UPDATE 2: AffiliateCommission.ClosedPositionEvent SET ReAttributeUpdated = GETUTCDATE() WHERE CID = @CID
- Both UPDATEs affect ALL events for the CID (not filtered by Tier or date)
- ReAttributeUpdated timestamp signals "this event was re-attributed at this time"
- The commission pipeline checks ReAttributeUpdated to identify events needing re-processing
- Both UPDATEs run within BEGIN TRAN / COMMIT with XACT_ABORT ON

**Diagram**:
```
Re-Attribution Workflow:
    |
    | Step 1: GetAffiliateInfo (eligibility check)
    | Step 2: UpdateAffiliationInfo (update commission records)
    | Step 3: UpdateEvents (signal pipeline re-processing)
    v
BEGIN TRAN (XACT_ABORT ON)
    |
    +-- UPDATE CreditEvent SET ReAttributeUpdated = GETUTCDATE()
    |     WHERE CID = @CID
    |
    +-- UPDATE ClosedPositionEvent SET ReAttributeUpdated = GETUTCDATE()
    |     WHERE CID = @CID
    |
    v
COMMIT
    |
    v
Commission pipeline detects ReAttributeUpdated != NULL
    -> Re-processes events under new affiliate
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int | NO | - | CODE-BACKED | The new affiliate ID (passed for context but not used in the procedure body - the affiliate change was already applied by UpdateAffiliationInfo). Present in the signature for workflow consistency. |
| 2 | @CID | bigint | NO | - | CODE-BACKED | The customer ID whose events should be marked for re-processing. All CreditEvent and ClosedPositionEvent records with this CID will have ReAttributeUpdated set to the current UTC timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.CreditEvent | MODIFY (UPDATE) | Sets ReAttributeUpdated timestamp on all credit events for the CID |
| - | AffiliateCommission.ClosedPositionEvent | MODIFY (UPDATE) | Sets ReAttributeUpdated timestamp on all closed position events for the CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Databricks Notebook (external) | - | Caller | Re-attribution workflow step 3: signal event re-processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAttribution.UpdateEvents (procedure)
+-- AffiliateCommission.CreditEvent (table, cross-schema)
+-- AffiliateCommission.ClosedPositionEvent (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEvent | Table | UPDATE target - sets ReAttributeUpdated for re-processing |
| AffiliateCommission.ClosedPositionEvent | Table | UPDATE target - sets ReAttributeUpdated for re-processing |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Databricks Notebook (external) | External | Calls as final step of re-attribution workflow |
| Commission Pipeline (external) | External | Detects ReAttributeUpdated to trigger event re-processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XACT_ABORT ON | Transaction Safety | Automatically rolls back on any error |
| BEGIN TRAN / COMMIT | Atomicity | Both event table UPDATEs are atomic |

---

## 8. Sample Queries

### 8.1 Mark events for re-processing after re-attribution
```sql
EXEC AffiliateAttribution.UpdateEvents @AffiliateID = 67890, @CID = 12345
```

### 8.2 Check if events were marked for re-processing
```sql
SELECT TOP 5 CID, ReAttributeUpdated
FROM AffiliateCommission.CreditEvent WITH (NOLOCK)
WHERE CID = 12345 AND ReAttributeUpdated IS NOT NULL
ORDER BY ReAttributeUpdated DESC
```

### 8.3 Find all recently re-attributed customers
```sql
SELECT DISTINCT CID, MAX(ReAttributeUpdated) AS LastReAttribution
FROM AffiliateCommission.CreditEvent WITH (NOLOCK)
WHERE ReAttributeUpdated IS NOT NULL
  AND ReAttributeUpdated >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY CID
ORDER BY LastReAttribution DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-1999 (referenced in SQL comments) | Jira | New SP for Databricks notebook - affiliate re-attribution (Oct 2023, Gil Haba) |
| PART-2440 (referenced in SQL comments) | Jira | Fixed support for new CPA revenue (Jan 2024, Gil Haba) |
| PART-2757 (referenced in SQL comments) | Jira | Removed RegistrationMetaData update - moved to separate SP (Feb 2024, Gil Haba) |

No Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.1/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 3 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAttribution.UpdateEvents | Type: Stored Procedure | Source: fiktivo/AffiliateAttribution/Stored Procedures/AffiliateAttribution.UpdateEvents.sql*
