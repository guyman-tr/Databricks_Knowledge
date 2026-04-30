# Dictionary.EventState

> Lookup table tracking the processing state of affiliate commission events as they flow through the multi-stage event-driven pipeline (tracking, eligibility, commission, deferred).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | EventStateID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.EventState defines all 51 possible states an affiliate commission event can occupy as it moves through the four-stage processing pipeline: Tracking (intake), Eligibility (rule evaluation), Commission (calculation/saving), and Deferred (retry processing). Each state represents a specific step, decision point, or error condition in the commission processing workflow.

This table is the backbone of commission event observability. Without it, there would be no way to diagnose where events are stuck, why commissions were not paid, or what processing step failed. Every commission dispute investigation starts by checking the event state trail.

Events enter through the Service Bus (state 1), flow through eligibility rules including organic and CPA checks, and either earn a commission (state 12) or are rejected at various gates. The GroupID column clusters states by processing stage, enabling stage-level monitoring dashboards.

---

## 2. Business Logic

### 2.1 Four-Stage Processing Pipeline

**What**: Commission events flow through four sequential stages, each with multiple possible states representing success paths, rejection reasons, and error conditions.

**Columns/Parameters Involved**: `EventStateID`, `Description`, `GroupID`

**Rules**:
- GroupID 0: General/reprocessing (state 11 - event retrieved from store for reprocessing)
- GroupID 1: Tracking stage (states 1-4, 15-16, 19-20, 33, 36, 42, 51) - Service Bus intake, tracking creation, queue management
- GroupID 2: Eligibility stage (states 5-10, 13-14, 17-18, 21-32, 38-39, 46-48, 50) - rule evaluation, CPA checks, organic attribution
- GroupID 3: Commission stage (states 12, 37, 40, 43-45, 49) - calculation, saving, FTDE pixel firing
- GroupID 4: Deferred processing (states 34-35, 41) - deferred message service lifecycle

### 2.2 CPA Eligibility Decision Tree

**What**: Cost Per Acquisition (CPA) checks form the most complex eligibility path with 12 dedicated states.

**Columns/Parameters Involved**: `EventStateID` (states 14, 22-32, 46)

**Rules**:
- State 24: CPA eligible, no minimum commission threshold - simplest pass
- State 25: CPA eligible, minimum commission reached - threshold check passed
- State 26: CPA not eligible, below minimum commission - common rejection
- State 32: CPA not eligible, not first deposit - only first deposits qualify for CPA
- States 27-29: Chargeback handling under CPA - determines if prior deposit commission survives a chargeback

**Diagram**:
```
[Event Read (1)] --> [Tracking Created (3)] --> [To Eligibility Queue (4)]
    |                                               |
    v                                               v
[No Affiliate (2)]                    [All Rules Pass (5)] --> [To Commission (6)]
                                           |                        |
                                      [Organic Fail (7)]    [Commission Saved (12)]
                                      [CPA Fail (14)]        [FTDE Pixel (49)]
                                           |
                                    [CPA Decision Tree]
                                    (states 22-32)
```

---

## 3. Data Overview

| EventStateID | Description | GroupID | Meaning |
|---|---|---|---|
| 1 | event is read from SB | 1 | Entry point - event received from Service Bus for tracking stage processing. This is where every commission event journey begins |
| 5 | all rules are eligible for commission | 2 | All eligibility rules passed - the event qualifies for commission payment. This is the success gate between eligibility and commission stages |
| 12 | save event commission | 3 | Commission calculated and saved to database. This is the terminal success state - the affiliate will be paid |
| 7 | rule organic is not eligible | 2 | Organic rule failed - the customer is classified as "organic" (found the platform without affiliate help), so no commission is owed |
| 49 | send FTDE Pixel | 3 | First-Time Deposit Eligible pixel fired for conversion tracking. Signals to external tracking systems that a qualified first deposit occurred |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EventStateID | int | NO | - | VERIFIED | Primary key identifying the event processing state. 51 values spanning four pipeline stages (GroupID 0-4). See [Event State](../../_glossary.md#event-state) for full value map with all 51 states and their business meanings. Key states: 1=Event read from SB, 3=Tracking added, 5=All rules eligible, 12=Commission saved, 7=Organic rejection. |
| 2 | Description | nvarchar(1000) | NO | - | VERIFIED | Detailed human-readable description of what this state means in the processing pipeline. Used in event state logs and diagnostic dashboards. Descriptions are written from the system's perspective (e.g., "event is read from SB"). |
| 3 | GroupID | int | NO | - | VERIFIED | Clusters states by processing stage. Values: 0=General/reprocessing, 1=Tracking stage (Service Bus intake, queue management), 2=Eligibility stage (rule evaluation, CPA/organic checks), 3=Commission stage (calculation, saving, pixel firing), 4=Deferred message processing. Enables stage-level monitoring and filtering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.CreditEventStateLog | EventStateID | Implicit FK | Logs every state transition for each credit event, creating a full audit trail |
| AffiliateCommission.InsertCreditEventStateLog | Parameter | Lookup | Inserts new state log entries as events transition between states |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEventStateLog | Table | Stores EventStateID for each state transition |
| AffiliateCommission.InsertCreditEventStateLog | Stored Procedure | WRITER - inserts state log entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryEventState | CLUSTERED PK | EventStateID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all event states grouped by processing stage
```sql
SELECT GroupID, EventStateID, Description
FROM Dictionary.EventState WITH (NOLOCK)
ORDER BY GroupID, EventStateID
```

### 8.2 View event state log with readable descriptions
```sql
SELECT TOP 20
    log.CreditEventID,
    log.EventStateID,
    es.Description AS StateName,
    es.GroupID,
    CASE es.GroupID
        WHEN 0 THEN 'General'
        WHEN 1 THEN 'Tracking'
        WHEN 2 THEN 'Eligibility'
        WHEN 3 THEN 'Commission'
        WHEN 4 THEN 'Deferred'
    END AS StageName
FROM AffiliateCommission.CreditEventStateLog log WITH (NOLOCK)
JOIN Dictionary.EventState es WITH (NOLOCK) ON log.EventStateID = es.EventStateID
ORDER BY log.CreditEventID DESC
```

### 8.3 Count events by processing stage
```sql
SELECT
    es.GroupID,
    CASE es.GroupID
        WHEN 0 THEN 'General'
        WHEN 1 THEN 'Tracking'
        WHEN 2 THEN 'Eligibility'
        WHEN 3 THEN 'Commission'
        WHEN 4 THEN 'Deferred'
    END AS StageName,
    COUNT(*) AS EventCount
FROM AffiliateCommission.CreditEventStateLog log WITH (NOLOCK)
JOIN Dictionary.EventState es WITH (NOLOCK) ON log.EventStateID = es.EventStateID
GROUP BY es.GroupID
ORDER BY es.GroupID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.EventState | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.EventState.sql*
