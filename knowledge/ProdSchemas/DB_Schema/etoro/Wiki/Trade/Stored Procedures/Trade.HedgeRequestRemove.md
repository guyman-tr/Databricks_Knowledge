# Trade.HedgeRequestRemove

> Deletes all pending hedge requests for a given HedgeID from Trade.HedgeRequest. Simple single-statement cleanup used to cancel a pending hedge open or close request without logging to HedgeFail.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeID; Deletes: Trade.HedgeRequest |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeRequestRemove cancels a pending hedge request by deleting all Trade.HedgeRequest rows for the given HedgeID, regardless of RequestType (both open RequestType=1 and close RequestType=2 are deleted). Unlike Trade.HedgeRemove which also logs to History.HedgeFail, this procedure silently removes the request with no audit trail.

This is the lightweight "cancel request" operation. Use when the request was submitted in error or a simpler cleanup is needed without failure logging.

---

## 2. Business Logic

### 2.1 Request Deletion

**What**: Unconditional DELETE of all HedgeRequest rows for @HedgeID.

**Rules**:
- `DELETE FROM Trade.HedgeRequest WHERE HedgeID = @HedgeID`
- Deletes ALL RequestTypes for this HedgeID (both open and close requests).
- No logging to History.HedgeFail.
- No transaction, no TRY/CATCH.
- RETURN @@ERROR (0 on success, SQL error number on failure).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INTEGER | NO | - | CODE-BACKED | HedgeID whose requests should be deleted. All RequestType rows (1=open, 2=close) are removed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeID | Trade.HedgeRequest | DELETE | Removes all pending requests for this hedge |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server (external) | - | Called by external system | Cancel a pending request without failure logging |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeRequestRemove (procedure)
+-- Trade.HedgeRequest (table) [DELETE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeRequest | Table | DELETE all rows WHERE HedgeID=@HedgeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Server (external) | External caller | Cancel pending request without audit trail |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. No transaction, no TRY/CATCH, no logging. Distinction from Trade.HedgeRemove: HedgeRequestRemove only touches HedgeRequest (no HedgeFail log, no Hedge delete, no Position update). For a full cleanup with audit trail, use Trade.HedgeRemove.

---

## 8. Sample Queries

### 8.1 Cancel a pending hedge request

```sql
EXEC Trade.HedgeRequestRemove @HedgeID = 12345;
```

### 8.2 Verify cleanup

```sql
SELECT * FROM Trade.HedgeRequest WITH (NOLOCK) WHERE HedgeID = 12345;
-- Should return no rows
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 7/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeRequestRemove | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeRequestRemove.sql*
