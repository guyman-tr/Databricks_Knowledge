# Apex.AleTopics

> Event consumer checkpoint tracker that records the last-processed event ID for each ALE (event streaming) topic, enabling reliable resume-from-last-position consumption.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | TopicName (VARCHAR(128), CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.AleTopics is an event consumer checkpoint table that tracks progress through ALE (event streaming) topics. Each row represents a subscription to a specific event topic and records the last event ID that was successfully processed. This enables the consumer to resume from exactly where it left off after a restart or failure, preventing duplicate processing or missed events.

This table is essential for reliable event-driven integration between the Apex account management system and external event sources. Without it, the system would either re-process all events from the beginning after each restart (causing duplicate operations) or skip ahead and miss events (causing data loss). The checkpoint pattern guarantees exactly-once or at-least-once processing semantics.

Data flows through a simple read-update cycle: the consumer calls Apex.GetAleTopic to retrieve the last checkpoint, processes events starting from that point, then calls Apex.SaveAleTopic to advance the checkpoint. SaveAleTopic uses an upsert pattern (UPDATE if exists, INSERT if new) to handle both initial subscription and ongoing progress tracking.

---

## 2. Business Logic

### 2.1 Event Consumer Checkpoint Pattern

**What**: Classic event consumer checkpoint/offset tracking for reliable stream processing.

**Columns/Parameters Involved**: `TopicName`, `LastEventID`, `LastUpdateDate`

**Rules**:
- Each topic has exactly one checkpoint record (TopicName is the PK)
- LastEventID advances monotonically as events are processed - it should never decrease
- LastUpdateDate records when the checkpoint was last advanced, useful for monitoring consumer lag
- The consumer reads the checkpoint, processes events with IDs > LastEventID, then saves the new checkpoint

**Diagram**:
```
Event Stream (topic: atlas-account_request-status)
    |
    | Events: ...3299088140, 3299088141, 3299088142...
    |                              ^
    |                              |
    +--- AleTopics.LastEventID = 3299088141
         (consumer has processed up to here)
         (next poll starts from 3299088142)
```

---

## 3. Data Overview

| TopicName | LastEventID | LastUpdateDate | Meaning |
|-----------|-------------|----------------|---------|
| atlas-account_request-status | 3299088141 | 2026-04-14 11:40:32 | The Apex system subscribes to Apex/Atlas account request status events. It has processed over 3.2 billion events through this topic, with the last checkpoint updated today - indicating an active, continuously-running consumer. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TopicName | varchar(128) | NO | - | CODE-BACKED | The name of the ALE event streaming topic being consumed. Acts as the unique identifier for each subscription. Current known value: "atlas-account_request-status" which delivers account creation/update status events from the Atlas/Apex clearing integration. Format follows a hierarchical naming convention: {system}-{domain}-{event_type}. |
| 2 | LastEventID | bigint | YES | 0 | CODE-BACKED | The ID of the last event successfully processed from this topic. Used as a cursor/offset to resume consumption - the next poll requests events with ID > this value. Originally stored as INT, changed to BIGINT in June 2023 (by Ran Ovadia) to accommodate the growing event volume exceeding INT range. Default of 0 means "start from beginning" for new subscriptions. Current value exceeds 3.2 billion, confirming the BIGINT migration was necessary. |
| 3 | LastUpdateDate | datetime | YES | - | CODE-BACKED | Timestamp of when this checkpoint was last updated (when the last batch of events was processed). Used for operational monitoring - a stale LastUpdateDate indicates the consumer may be stuck or offline. Set by the application via Apex.SaveAleTopic alongside the new LastEventID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.GetAleTopic | @TopicName | Read | Retrieves the checkpoint for a specific topic by name |
| Apex.SaveAleTopic | @TopicName | Write | Upserts the checkpoint - advances LastEventID and LastUpdateDate |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.GetAleTopic | Stored Procedure | Reader - retrieves checkpoint by TopicName |
| Apex.SaveAleTopic | Stored Procedure | Writer/Modifier - upserts checkpoint (INSERT or UPDATE) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Apex_AleTopics | CLUSTERED PK | TopicName ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Apex_AleTopics | PRIMARY KEY | TopicName - each event topic has exactly one checkpoint record |
| DF_Apex_AleTopics_LastEventID | DEFAULT | LastEventID defaults to 0 - new subscriptions start from the beginning of the topic |

---

## 8. Sample Queries

### 8.1 Check current checkpoint for all topics

```sql
SELECT TopicName, LastEventID, LastUpdateDate,
       DATEDIFF(MINUTE, LastUpdateDate, GETUTCDATE()) AS MinutesSinceLastUpdate
FROM Apex.AleTopics WITH (NOLOCK)
ORDER BY LastUpdateDate DESC;
```

### 8.2 Detect stale consumers (no update in last 30 minutes)

```sql
SELECT TopicName, LastEventID, LastUpdateDate
FROM Apex.AleTopics WITH (NOLOCK)
WHERE DATEDIFF(MINUTE, LastUpdateDate, GETUTCDATE()) > 30
ORDER BY LastUpdateDate ASC;
```

### 8.3 Get checkpoint for a specific topic

```sql
SELECT TopicName, LastEventID, LastUpdateDate
FROM Apex.AleTopics WITH (NOLOCK)
WHERE TopicName = 'atlas-account_request-status';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.AleTopics | Type: Table | Source: USABroker/Apex/Tables/Apex.AleTopics.sql*
