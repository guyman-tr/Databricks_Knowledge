# AffiliateCommission.AffiliateTraderRegistrationQueue

> Message queue table that stores XML-encoded affiliate trader registration events awaiting processing by the commission calculation pipeline.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | ID (bigint, IDENTITY, clustered index) |
| **Partition** | No |
| **Indexes** | 1 active (CDX_AffiliateTraderRegistrationQueue on ID) |

---

## 1. Business Meaning

AffiliateTraderRegistrationQueue is a message queue table that temporarily holds registration events for affiliate-referred customers. Each row represents one customer registration that needs to be processed by the affiliate commission system to determine if a registration commission should be paid to the referring affiliate.

This table exists as an intermediary in the asynchronous registration processing pipeline. When a customer registers on the platform and is linked to an affiliate, a registration message is placed in this queue. A background process then reads unhandled messages, processes the registration (creating records in Registration, RegistrationEvent, and RegistrationMetaData), and removes the message from the queue upon successful processing.

The queue was originally populated via Service Broker (`[Broker].[actAffiliateTraderRegistration]`), but this mechanism was disabled in March 2023 (PART-1253). The Load procedure now has an early `RETURN` statement, effectively stopping new messages from entering via the old path. The remaining 11,268 rows date from February 2023 and represent stale unprocessed messages from the transition period. The registration pipeline likely migrated to a different event ingestion mechanism.

---

## 2. Business Logic

### 2.1 Retry/Pickup Mechanism

**What**: Unprocessed messages are automatically retried after a 10-minute timeout.

**Columns/Parameters Involved**: `DateModified`, `DateCreated`, `RegistrationMessage`

**Rules**:
- ReadRegistrationUnhandledMessages picks up messages where DateModified is more than 10 minutes old
- Each pickup updates DateModified to the current UTC time, resetting the 10-minute retry window
- Successfully processed messages are deleted by RemoveRegistrationUnhandledMessage
- Messages that repeatedly fail remain in the queue indefinitely (no max retry limit)

**Diagram**:
```
[Service Broker / External Source] -- DISABLED (PART-1253)
       |
       v
  AffiliateTraderRegistrationQueue (INSERT)
       |
       v
  ReadRegistrationUnhandledMessages (picks up after 10 min)
       |
       +-- Success --> RemoveRegistrationUnhandledMessage (DELETE)
       |
       +-- Failure --> stays in queue, retried after 10 more min
```

### 2.2 XML Message Structure

**What**: Each registration message contains the full context needed to create a registration commission.

**Columns/Parameters Involved**: `RegistrationMessage`

**Rules**:
- XML root element: `<AffiliateTraderRegistration>`
- Contains customer identity (CID, GCID, OriginalCID), affiliate attribution (AffiliateID, AffiliateCampaign, BannerID, DownloadID), geographic context (CountryID), provider chain (ProviderID, OriginalProviderID), and classification data (FunnelID, LabelID, PlayerLevelID)
- The Occurred timestamp within the XML represents the actual registration time, while DateCreated represents when the message entered the queue

---

## 3. Data Overview

| ID | DateCreated | DateModified | Meaning |
|---|---|---|---|
| 588116 | 2023-02-22 14:30:39 | 2023-02-23 13:42:06 | Registration for CID 9853579 referred by AffiliateID 3 from CountryID 143. Message was retried ~23 hours after creation - indicates processing stalled. |
| 588117 | 2023-02-22 14:31:06 | 2023-02-23 13:42:20 | Sequential registration from same affiliate batch. Same retry pattern as above. |
| 588118 | 2023-02-22 14:31:10 | 2023-02-23 13:42:27 | Part of rapid-fire registration batch (4 seconds after previous). All from AffiliateID 3, CountryID 143 - likely a bulk import or test scenario. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. Used by RemoveRegistrationUnhandledMessage to delete specific processed messages. Clustered index ensures insertion order. |
| 2 | RegistrationMessage | xml | YES | - | CODE-BACKED | Full XML payload containing the registration event data. Includes CID, GCID, OriginalCID, ProviderID, OriginalProviderID, CountryID, AffiliateID, AffiliateCampaign, DownloadID, FunnelFromID, BannerID, LabelID, FunnelID, PlayerLevelID, DownloadCounter, and Occurred timestamp. Nullable because the insert happens conditionally (only when Broker output is not NULL). |
| 3 | DateCreated | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the message was inserted into the queue. Set automatically via default constraint. Represents when the system received the registration event, not when the customer actually registered (that is the Occurred field inside the XML). |
| 4 | DateModified | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of the last processing attempt. Updated by ReadRegistrationUnhandledMessages to current UTC time each time the message is picked up for retry. The 10-minute gap between DateModified and current time determines retry eligibility. Initially set to creation time via default constraint. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. The XML payload contains IDs (CID, AffiliateID, CountryID, etc.) but these are embedded in the message, not as relational columns.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.LoadAffiliateTraderRegistrationQueue | INSERT | Writer | Originally inserted messages from Service Broker (now disabled) |
| AffiliateCommission.ReadRegistrationUnhandledMessages | UPDATE/OUTPUT | Reader/Modifier | Picks up unhandled messages older than 10 minutes |
| AffiliateCommission.RemoveRegistrationUnhandledMessage | DELETE | Deleter | Removes successfully processed messages by ID |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.LoadAffiliateTraderRegistrationQueue | Stored Procedure | Writer (disabled - inserts from Service Broker) |
| AffiliateCommission.ReadRegistrationUnhandledMessages | Stored Procedure | Reader/Modifier (retry pickup) |
| AffiliateCommission.RemoveRegistrationUnhandledMessage | Stored Procedure | Deleter (cleanup after processing) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CDX_AffiliateTraderRegistrationQueue | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_AffiliateCommissionAffiliateTraderRegistrationQueue_DateCreated | DEFAULT | getutcdate() - auto-stamps creation time |
| DF_AffiliateTraderRegistrationQueue_DateModified | DEFAULT | getutcdate() - auto-stamps modification time |

---

## 8. Sample Queries

### 8.1 Count unhandled messages older than 10 minutes
```sql
SELECT COUNT(*) AS UnhandledCount
FROM AffiliateCommission.AffiliateTraderRegistrationQueue WITH (NOLOCK)
WHERE DATEADD(minute, 10, DateModified) < GETUTCDATE();
```

### 8.2 Extract key fields from XML messages
```sql
SELECT TOP 10
    ID,
    RegistrationMessage.value('(/AffiliateTraderRegistration/CID)[1]', 'bigint') AS CID,
    RegistrationMessage.value('(/AffiliateTraderRegistration/AffiliateID)[1]', 'int') AS AffiliateID,
    RegistrationMessage.value('(/AffiliateTraderRegistration/CountryID)[1]', 'bigint') AS CountryID,
    RegistrationMessage.value('(/AffiliateTraderRegistration/Occurred)[1]', 'datetime') AS Occurred,
    DateCreated
FROM AffiliateCommission.AffiliateTraderRegistrationQueue WITH (NOLOCK)
ORDER BY ID DESC;
```

### 8.3 Find messages stuck in queue for more than 24 hours
```sql
SELECT ID, DateCreated, DateModified,
       DATEDIFF(hour, DateCreated, GETUTCDATE()) AS HoursInQueue
FROM AffiliateCommission.AffiliateTraderRegistrationQueue WITH (NOLOCK)
WHERE DATEDIFF(hour, DateCreated, GETUTCDATE()) > 24
ORDER BY DateCreated;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-1253](https://etoro-jira.atlassian.net/browse/PART-1253) | Jira | Service Broker call to registration queue was disabled (Mar 2023). LoadAffiliateTraderRegistrationQueue now returns immediately without activity. |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.AffiliateTraderRegistrationQueue | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.AffiliateTraderRegistrationQueue.sql*
