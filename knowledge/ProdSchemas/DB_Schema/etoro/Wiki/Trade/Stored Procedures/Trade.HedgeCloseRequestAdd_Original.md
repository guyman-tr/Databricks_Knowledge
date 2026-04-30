# Trade.HedgeCloseRequestAdd_Original

> Legacy version of Trade.HedgeCloseRequestAdd using @@ERROR-based error handling; lacks FailReasonID logging. Superseded by Trade.HedgeCloseRequestAdd which adds TRY/CATCH and FailReasonID=17.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeID, @RequestedEndForexRate; Writes: Trade.HedgeRequest (RequestType=2); Logs: History.HedgeFail on displacement |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeCloseRequestAdd_Original is the **original version** of Trade.HedgeCloseRequestAdd, preserved for reference or rollback purposes. It implements the same core logic: queue a hedge close request in Trade.HedgeRequest, displacing any existing pending close request with a failure log. The two differences from the current version are: (1) it uses legacy @@ERROR-based error handling instead of TRY/CATCH, and (2) the History.HedgeFail insert does NOT include FailReasonID (the column was added in the enhanced version).

This procedure is a historical artifact retained after the HedgeCloseRequestAdd was upgraded. It is not the active version called by the hedge server. It exists because the schema preserves the original implementation alongside the enhanced one, which is common for hedging procedures where rollback capability is valued.

See Trade.HedgeCloseRequestAdd for the current active implementation and full business context. All business logic, dependencies, and behavior are identical except for error handling style and FailReasonID logging.

---

## 2. Business Logic

### 2.1 Duplicate Request Displacement (Same as HedgeCloseRequestAdd)

**What**: If a pending close request exists for @HedgeID, archive it and replace with the new request.

**Rules**:
- Step 1: IF EXISTS (SELECT from Trade.HedgeRequest WHERE HedgeID=@HedgeID AND RequestType=2): archive old request to History.HedgeFail (WITHOUT FailReasonID - key difference)
- Step 2: DELETE old request from Trade.HedgeRequest
- Step 3: INSERT new close request (RequestType=2, @RequestedEndForexRate)
- Error handling: @@ERROR check after each DML operation; ROLLBACK + RAISERROR(60000) on any error

### 2.2 Difference from Current Version

**What**: Two technical differences between this original and the current HedgeCloseRequestAdd.

**Rules**:
- FailReasonID: Original does NOT write FailReasonID to History.HedgeFail. Current version writes FailReasonID=17.
- Error handling: Original uses IF @LocalError != 0 checks after each statement. Current version uses TRY/CATCH.
- IF EXISTS guard: Original uses IF EXISTS before the HedgeFail INSERT. Current version uses unconditional SELECT (which is a no-op if no rows exist) - functionally equivalent but slightly different pattern.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INTEGER | NO | - | CODE-BACKED | ID of the hedge for which a close request is being submitted. Identical to Trade.HedgeCloseRequestAdd @HedgeID. |
| 2 | @RequestedEndForexRate | dtPrice | NO | - | CODE-BACKED | The requested closing rate. Identical to Trade.HedgeCloseRequestAdd @RequestedEndForexRate. dtPrice is a user-defined decimal type for price values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeID | Trade.HedgeRequest | INSERT / DELETE | Displaces existing RequestType=2 and inserts new close request |
| @HedgeID | History.HedgeFail | INSERT (conditional) | Archives displaced close requests (without FailReasonID) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeCloseRequestAdd | Supersedes | Historical reference | This is the version that was replaced; current callers use HedgeCloseRequestAdd (without _Original suffix) |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeCloseRequestAdd_Original (procedure)
+-- Trade.HedgeRequest (table) [leaf - SELECT + DELETE + INSERT]
+-- History.HedgeFail (table) [x-schema, leaf - displacement log INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeRequest | Table | IF EXISTS check, INSERT (archive displaced), DELETE (old request), INSERT (new close request) |
| History.HedgeFail | Table | INSERT (archive displaced close requests, without FailReasonID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeCloseRequestAdd | Procedure | Supersedes this object; same caller base uses the non-_Original version |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Uses legacy @@ERROR-based error handling with explicit ROLLBACK and RAISERROR(60000) at each DML step. Returns 0 on success, 60000 on error.

---

## 8. Sample Queries

### 8.1 Compare behavior with current version

```sql
-- Original version (legacy):
EXEC Trade.HedgeCloseRequestAdd_Original
    @HedgeID = 12345,
    @RequestedEndForexRate = 1.08520;

-- Current version (preferred):
EXEC Trade.HedgeCloseRequestAdd
    @HedgeID = 12345,
    @RequestedEndForexRate = 1.08520;
```

### 8.2 Check for missing FailReasonID in legacy failure logs

```sql
-- Rows logged by _Original version will have NULL FailReasonID
SELECT HedgeID, FailTypeID, FailReasonID, FailReason, RequestCloseOccurred
FROM History.HedgeFail WITH (NOLOCK)
WHERE HedgeID = 12345 AND FailTypeID = 2
ORDER BY RequestCloseOccurred DESC;
-- FailReasonID IS NULL -> logged by _Original version
-- FailReasonID = 17   -> logged by current HedgeCloseRequestAdd
```

### 8.3 Verify pending close requests

```sql
SELECT HedgeID, RequestType, RequestedEndForexRate, Occurred
FROM Trade.HedgeRequest WITH (NOLOCK)
WHERE HedgeID = 12345 AND RequestType = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 11 - Phase 10: no results)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeCloseRequestAdd_Original | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeCloseRequestAdd_Original.sql*
