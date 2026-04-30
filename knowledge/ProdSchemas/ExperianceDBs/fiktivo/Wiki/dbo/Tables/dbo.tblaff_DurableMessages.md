# dbo.tblaff_DurableMessages

> Durable message queue (outbox pattern) for reliable delivery of affiliate tracking pixel events, primarily triggered by approved customer deposits.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ReferenceID (bigint IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK + TransactionID) |

---

## 1. Business Meaning

dbo.tblaff_DurableMessages implements the transactional outbox pattern for reliable delivery of affiliate tracking pixel callbacks. When a customer makes an approved deposit, the system creates a durable message containing the pixel firing instructions. A consumer service reads undelivered messages, fires the tracking pixels to affiliate partners, and marks them as delivered.

Without this table, pixel firing for approved deposits would be unreliable - network failures, service restarts, or processing errors could cause lost tracking events, resulting in affiliates not being properly credited for their referred customers' deposits.

The `InsertApprovedDepositPixel` procedure creates messages on approved deposit events (WRITER). The `GetApprovedDepositPixels` procedure atomically retrieves message data and marks it as delivered (MODIFIER), using CorrelationID + ReferenceID as the idempotency key. Only undelivered messages (IsDelivered=0) can be processed, preventing double-firing. The table contains ~1.09M records, with 96% still undelivered - suggesting either a high-volume environment or a processing backlog.

---

## 2. Business Logic

### 2.1 Durable Outbox Pattern

**What**: Ensures at-least-once delivery of pixel firing events through a persistent message queue.

**Columns/Parameters Involved**: `ReferenceID`, `CorrelationID`, `IsDelivered`, `CreateTime`, `UpdateTime`

**Rules**:
- `IsDelivered = 0`: Message queued but not yet processed - pixel has not fired
- `IsDelivered = 1`: Message processed and pixel delivered to affiliate partner
- `GetApprovedDepositPixels` uses optimistic concurrency: `WHERE IsDelivered=0` ensures a message is processed exactly once even under concurrent consumers
- `CorrelationID` (GUID) provides unique correlation across the distributed system
- `UpdateTime` is set when delivery is confirmed; NULL means never processed

**Diagram**:
```
[Approved Deposit Event]
        |
        v
InsertApprovedDepositPixel (WRITER)
        |
        v
tblaff_DurableMessages [IsDelivered=0]
        |
        v
Consumer Service (polls for undelivered)
        |
        v
GetApprovedDepositPixels (MODIFIER)
  - Atomically: SET IsDelivered=1, UpdateTime=@now
  - Returns: MessageData
  - Only if: IsDelivered=0 AND CorrelationID matches
        |
        v
[Fire tracking pixels to affiliate]
```

### 2.2 Pixel Payload Structure

**What**: Each message carries the pixel firing instructions as JSON payloads.

**Columns/Parameters Involved**: `PixelIDs`, `MessageData`, `AppsFlyerID`

**Rules**:
- `PixelIDs`: JSON array of pixel IDs to fire (references tblaff_AffiliatePixels). Empty array "[]" when no specific pixels are configured.
- `MessageData`: JSON payload with event details for the pixel callback. Returned by GetApprovedDepositPixels for processing.
- `AppsFlyerID`: AppsFlyer mobile attribution ID for mobile app installs. NULL when not applicable.

---

## 3. Data Overview

| ReferenceID | AffiliateID | CID | IsDelivered | TransactionID | CorrelationID | CreateTime | Meaning |
|---|---|---|---|---|---|---|---|
| 1137286 | 3 | 12110912 | false | 4897359 | 7f0cbf4e-... | 2023-09-13 10:01 | Undelivered pixel event for house affiliate (#3). Transaction 4897359 queued for pixel firing. Empty pixel/message payloads suggest pixels may be resolved at fire time. |
| 1137283 | 3 | 12110905 | false | 4897354 | 4975a22c-... | 2023-09-13 10:00 | Another undelivered message from same batch (same second). Same affiliate, different customer and transaction. Pattern shows bulk deposit processing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReferenceID | bigint IDENTITY | NO | - | VERIFIED | Auto-incrementing primary key and message reference. Returned as OUTPUT by InsertApprovedDepositPixel. Used with CorrelationID as the idempotency key in GetApprovedDepositPixels. NOT FOR REPLICATION. |
| 2 | AffiliateID | int | NO | - | VERIFIED | The affiliate to whom this pixel event belongs. FK to dbo.tblaff_Affiliates.AffiliateID (explicit constraint FK_MyTbl_Col2). Determines which affiliate's pixels should be fired. |
| 3 | CID | int | NO | - | VERIFIED | Customer ID whose approved deposit triggered this pixel event. Combined with AffiliateID, identifies the specific customer-affiliate relationship for pixel attribution. |
| 4 | PixelIDs | nvarchar(max) | YES | - | VERIFIED | JSON array of pixel IDs to fire for this event. References tblaff_AffiliatePixels. Empty "[]" when no specific pixels are pre-configured - pixels may be resolved dynamically at fire time based on affiliate configuration. |
| 5 | AppsFlyerID | varchar(255) | YES | - | CODE-BACKED | AppsFlyer mobile attribution identifier. Used for mobile app install tracking integrations. NULL when the event is not mobile-related or AppsFlyer is not configured for this affiliate. |
| 6 | CorrelationID | varchar(255) | NO | - | VERIFIED | GUID-format correlation identifier providing distributed tracing across the pixel delivery pipeline. Used with ReferenceID as the compound idempotency key in GetApprovedDepositPixels to prevent double-delivery. |
| 7 | MessageData | nvarchar(max) | YES | - | VERIFIED | JSON payload containing the full event data for pixel firing. Returned by GetApprovedDepositPixels when the message is processed. Contains details needed by the pixel firing service (deposit amount, customer attributes, etc.). Empty "[]" in sample data. |
| 8 | IsDelivered | bit | NO | 0 | VERIFIED | Delivery status: 0 = queued/pending (96% of rows), 1 = successfully delivered (4%). GetApprovedDepositPixels sets this to 1 atomically, using WHERE IsDelivered=0 to ensure exactly-once processing semantics. |
| 9 | CreateTime | datetime | YES | - | VERIFIED | Timestamp when the message was created by InsertApprovedDepositPixel. NULL only for legacy records inserted before this column was added. Passed as parameter, not defaulted. |
| 10 | UpdateTime | datetime | YES | - | VERIFIED | Timestamp when the message was processed/delivered by GetApprovedDepositPixels. NULL = never processed. Set simultaneously with IsDelivered=1. The difference between UpdateTime and CreateTime measures message processing latency. |
| 11 | TransactionID | varchar(255) | YES | - | CODE-BACKED | The deposit transaction ID that triggered this pixel event. References the approved deposit in the billing/payment system. Indexed for lookups. Values are numeric strings (e.g., "4897359"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | dbo.tblaff_Affiliates | FK (explicit) | The affiliate whose pixels should be fired for this event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.InsertApprovedDepositPixel | INSERT | Procedure (WRITER) | Creates durable messages when approved deposits occur |
| dbo.GetApprovedDepositPixels | UPDATE | Procedure (MODIFIER) | Atomically retrieves and marks messages as delivered |
| dbo.SSRS_AffWiz_ClosedPositions | JOIN | Procedure (READER) | Cross-references with ClosedPositions to avoid reprocessing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (FK to tblaff_Affiliates is a relationship, not a code-level dependency).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.InsertApprovedDepositPixel | Stored Procedure | WRITER - inserts durable messages for approved deposit pixel events |
| dbo.GetApprovedDepositPixels | Stored Procedure | MODIFIER - retrieves and marks messages as delivered |
| dbo.SSRS_AffWiz_ClosedPositions | Stored Procedure | READER - cross-references to avoid duplicate processing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_DurableMessages | CLUSTERED PK | ReferenceID ASC | - | - | Active (fill 90%, PAGE compression) |
| IDX_tblaff_DurableMessages_TransactionID | NC | TransactionID ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_tblaff_DurableMessages_IsDelivered | DEFAULT | 0 - Messages start as undelivered |
| FK_MyTbl_Col2 | FOREIGN KEY | AffiliateID -> dbo.tblaff_Affiliates(AffiliateID) |

---

## 8. Sample Queries

### 8.1 Count undelivered messages (processing backlog)
```sql
SELECT COUNT(*) AS UndeliveredCount,
       MIN(CreateTime) AS OldestUndelivered,
       MAX(CreateTime) AS NewestUndelivered
FROM dbo.tblaff_DurableMessages WITH (NOLOCK)
WHERE IsDelivered = 0
```

### 8.2 Delivery rate by affiliate
```sql
SELECT AffiliateID,
       COUNT(*) AS TotalMessages,
       SUM(CASE WHEN IsDelivered = 1 THEN 1 ELSE 0 END) AS Delivered,
       SUM(CASE WHEN IsDelivered = 0 THEN 1 ELSE 0 END) AS Pending
FROM dbo.tblaff_DurableMessages WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY TotalMessages DESC
```

### 8.3 Average delivery latency for processed messages
```sql
SELECT AVG(DATEDIFF(SECOND, CreateTime, UpdateTime)) AS AvgLatencySeconds,
       MIN(DATEDIFF(SECOND, CreateTime, UpdateTime)) AS MinLatencySeconds,
       MAX(DATEDIFF(SECOND, CreateTime, UpdateTime)) AS MaxLatencySeconds
FROM dbo.tblaff_DurableMessages WITH (NOLOCK)
WHERE IsDelivered = 1 AND CreateTime IS NOT NULL AND UpdateTime IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 9.1/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_DurableMessages | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_DurableMessages.sql*
