# Apex.SaveAleTopic

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveAleTopic.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-11-15  
**Last Modified:** 2023-06-19 (Ran Ovadia — changed `LastEventID` to `bigint`)  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveAleTopic` creates or advances the event-stream bookmark for a named Apex Listener Event (ALE) topic. After a service successfully processes a batch of events from a topic, it calls this procedure to record the highest event ID processed and the timestamp of that operation. This persistent bookmark allows the service to resume from the correct position after a restart, preventing both re-processing and skipping events.

This is one of the most frequently called procedures in the event-ingestion path — called once per successful event-batch flush for every active topic.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@TopicName` | `varchar(128)` | No | The unique name of the ALE topic whose bookmark is being updated. |
| `@LastEventID` | `bigint` | No | The ID of the highest event successfully processed from this topic. |
| `@LastUpdateDate` | `datetime` | No | The UTC timestamp when the bookmark is being written. |

---

## 3. Result Sets

None. This is a write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `AleTopics` | `Apex` | SELECT (EXISTS check) + UPDATE or INSERT | Classic IF EXISTS / UPDATE ELSE INSERT upsert pattern. |

---

## 5. Logic Flow

1. `IF EXISTS (SELECT 1 FROM Apex.AleTopics WHERE TopicName = @TopicName)`:
   - **True:** `UPDATE AleTopics SET LastEventID = @LastEventID, LastUpdateDate = @LastUpdateDate WHERE TopicName = @TopicName`.
   - **False:** `INSERT INTO AleTopics (TopicName, LastEventID, LastUpdateDate) VALUES (...)`.

The IF EXISTS / UPDATE ELSE INSERT pattern creates the topic bookmark on first use and advances it on subsequent calls. Note: this pattern has a theoretical TOCTOU race under extreme concurrent inserts for the same new topic; in practice topics are inserted once and only ever updated thereafter.

---

## 6. Error Handling

No explicit error handling. If the INSERT or UPDATE fails (e.g., constraint violation), the exception propagates to the caller.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.AleTopics` | Table | Read-checked and written |
| `Apex.GetAleTopic` | Stored Procedure | Companion reader; retrieves the bookmark written here |

---

## 8. Usage Notes

- `LastEventID` was changed from a narrower integer type to `bigint` on 2023-06-19; ensure all callers use a 64-bit integer type to avoid silent truncation.
- The procedure should only be called after the event batch has been fully processed and committed in the application. Calling it before processing completes risks losing events if the application crashes before finishing.
- Under high-throughput scenarios where many topic names could be inserted simultaneously, consider adding a `HOLDLOCK` hint to the EXISTS check or replacing with a MERGE to eliminate the TOCTOU window.
- `@LastUpdateDate` should be the UTC timestamp of the batch processing completion, not the timestamp of the last event in the batch.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveAleTopic.sql` | Quality Score: 8.5/10*
