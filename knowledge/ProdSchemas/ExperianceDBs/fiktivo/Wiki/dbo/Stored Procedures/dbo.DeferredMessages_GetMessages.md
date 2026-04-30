# dbo.DeferredMessages_GetMessages

> Retrieves deferred messages from the queue using multi-parameter filters, with server-based routing logic to partition message processing across specific application server instances.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | DeferredMessageID / AffiliateID / Status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the read endpoint for the DeferredMessages queue. Application services call it to fetch messages awaiting processing, filtering by any combination of ID, source, tracking key, status, date ranges, CID, and AffiliateID. A critical server-segmentation clause (added by Ran Ovadia, March 2020) ensures that specific high-volume affiliates (56662 and 56663) are routed to dedicated application server instances (LON-AFFWIZ-SRV with specific APP_NAME values), while LON-AFFWIZ-SRV2 handles all other messages. This prevents processing conflicts in a multi-server deployment.

---

## 2. Business Logic

- All filter parameters are optional (default NULL); a NULL parameter is treated as "no filter" via (param IS NULL OR column = param) pattern.
- RegisteredOn and UpdatedOn are filtered as <= with ISNULL defaulting to current date when not supplied.
- Server segmentation logic uses HOST_NAME() and APP_NAME() to route messages:
  - LON-AFFWIZ-SRV2: handles all affiliates EXCEPT 56662 and 56663.
  - LON-AFFWIZ-SRV + APP_NAME = 'QueueService-p3': handles AffiliateID 56662 only.
  - LON-AFFWIZ-SRV + APP_NAME = 'QuesService': handles AffiliateID 56663 only.
  - Any other host: no segmentation applied (dev/test environments).
- Uses index hint (index(Ran2), nolock) for read performance.
- OPTION (RECOMPILE) prevents parameter sniffing issues given the highly variable filter combinations.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @DeferredMessageID | INT | IN | NULL | High | Filter by specific message ID |
| 2 | @Source | NVARCHAR(MAX) | IN | NULL | High | Filter by message source system name |
| 3 | @SourceKey | NVARCHAR(MAX) | IN | NULL | High | Filter by source-specific key |
| 4 | @TrackingKey | NVARCHAR(MAX) | IN | NULL | High | Filter by tracking/correlation key |
| 5 | @Status | INT | IN | NULL | High | Filter by processing status code |
| 6 | @RegisteredBefore | DATETIME | IN | NULL | High | Upper bound on RegisteredOn (inclusive); defaults to now |
| 7 | @UpdatedBefore | DATETIME | IN | NULL | High | Upper bound on UpdatedOn (inclusive); defaults to now |
| 8 | @CID | INT | IN | NULL | High | Filter by customer CID extracted from message |
| 9 | @AffiliateID | INT | IN | NULL | High | Filter by affiliate ID extracted from message |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.DeferredMessages | Read | Source of all queued messages returned by this SP |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DeferredMessages_GetMessages
  └── dbo.DeferredMessages    (READ)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.DeferredMessages | Table | Queue table from which messages are fetched |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Fetch all pending messages (status = 0) registered before now
EXEC dbo.DeferredMessages_GetMessages @Status = 0;

-- Fetch messages for a specific affiliate registered before a cutoff
EXEC dbo.DeferredMessages_GetMessages
    @AffiliateID     = 12345,
    @RegisteredBefore = '2026-01-01 00:00:00';

-- Fetch a specific message by ID for debugging
EXEC dbo.DeferredMessages_GetMessages @DeferredMessageID = 55001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.
*(Author note: Ran Ovadia, 26/03/2020 - server segmentation addition.)*

---

*Generated: 2026-04-12 | Quality: 8.2/10*
*Object: dbo.DeferredMessages_GetMessages | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.DeferredMessages_GetMessages.sql*
