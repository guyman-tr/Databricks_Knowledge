# Apex.GetAleTopic

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetAleTopic.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-11-15  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetAleTopic` retrieves the current position information for a named Apex Listener Event (ALE) topic. The procedure answers the question "what is the last event we have processed on this topic?" and is used by the event-consumption layer to resume reading from the correct offset after a restart or re-sync.

ALE topics act as event-stream channels; each named topic tracks its own high-water mark (`LastEventID`) and the timestamp when it was last updated. By reading this row before consuming events, the calling service knows exactly where to start fetching new messages, preventing both duplicate processing and data gaps.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@TopicName` | `varchar(128)` | No | The unique name of the ALE topic to retrieve (e.g., `"user-data-updates"`). |

---

## 3. Result Sets

**Result Set 1 – Topic Bookmark**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `TopicName` | `Apex.AleTopics` | The unique name identifying this event-stream topic. |
| `LastEventID` | `Apex.AleTopics` | The ID of the most recently processed event on this topic (bigint). |
| `LastUpdateDate` | `Apex.AleTopics` | UTC timestamp when the bookmark was last written. |

Returns 0 rows if no entry exists for the given topic name.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `AleTopics` | `Apex` | SELECT | Read with `NOLOCK`; no dirty-read risk for a simple bookmark. |

---

## 5. Logic Flow

1. Opens a `NOLOCK` read on `Apex.AleTopics`.
2. Filters by `TopicName = @TopicName` (exact equality; single-row lookup).
3. Returns the three bookmark columns directly.

No joins, aggregates, or conditional branching. This is a single-predicate point query.

---

## 6. Error Handling

No explicit error handling. The procedure relies on standard SQL Server exception propagation. If the topic does not exist, an empty result set is returned (not an error).

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.AleTopics` | Table | Primary data source |
| `Apex.SaveAleTopic` | Stored Procedure | Companion writer that creates/updates the row read here |

---

## 8. Usage Notes

- Use `Apex.SaveAleTopic` to create or advance the bookmark after processing events.
- The `NOLOCK` hint means concurrent uncommitted writes to `AleTopics` may be transiently visible, but since this is a single-row bookmark read this is acceptable.
- `LastEventID` was changed to `bigint` (from a narrower type) on 2023-06-19 per change by Ran Ovadia; ensure calling code uses a 64-bit integer type.
- Callers should handle an empty result set (zero rows) as a signal that the topic is new and processing should start from the beginning.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetAleTopic.sql` | Quality Score: 8.5/10*
