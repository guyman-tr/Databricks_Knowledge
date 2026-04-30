# Trade.GetMirrorCloseSagaByID

> Retrieves the CopyTrader mirror close saga state for a specific mirror-customer pair, tracking the multi-step asynchronous close process.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: MirrorCloseSaga record by MirrorID + CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorCloseSagaByID retrieves the close saga state for a specific CopyTrader mirror relationship. When a copier stops copying a trader, the system must close all copied positions - this is a multi-step asynchronous process (a "saga") tracked in Trade.MirrorCloseSaga. This procedure returns the current saga state for a given MirrorID and CID combination.

This procedure exists because mirror close operations involve multiple sequential steps (close CFD positions, close stock positions, settle funds, etc.), and each step must be tracked. If a step fails, the system can resume from the last successful step. The saga pattern ensures eventual consistency even if individual operations fail.

Called by PROD_BIadmins for monitoring and debugging mirror close operations.

---

## 2. Business Logic

### 2.1 Saga State Retrieval

**What**: Returns the current state of a mirror close saga, showing which step the process is on and how it was initiated.

**Columns/Parameters Involved**: `@MirrorID`, `@CID`, `Trade.MirrorCloseSaga`

**Rules**:
- Filters by both MirrorID AND CID (a saga is unique per mirror-customer pair)
- CurrentStepIndex tracks progress through the saga steps
- MirrorCloseActionType indicates how the close was initiated (manual, system, etc.)
- InitialRequestGuid and ClientRequestId provide correlation for tracing across services

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @MirrorID | int | IN | - | CODE-BACKED | The CopyTrader mirror relationship ID to look up the close saga for. |
| 2 | @CID | int | IN | - | CODE-BACKED | The customer ID (copier) involved in this mirror close. |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | MirrorID | int | NO | CODE-BACKED | The mirror relationship being closed. |
| 2 | CID | int | NO | CODE-BACKED | The copier customer ID. |
| 3 | CurrentStepIndex | int | YES | CODE-BACKED | The index of the current saga step. Tracks how far through the multi-step close process this saga has progressed. |
| 4 | InitialRequestGuid | uniqueidentifier | YES | CODE-BACKED | Correlation GUID from the initial close request. Used for distributed tracing across services. |
| 5 | MirrorCloseActionType | int | YES | CODE-BACKED | How the close was initiated. FK to a close action type dictionary (manual stop-copy, system liquidation, etc.). |
| 6 | ClientRequestId | varchar | YES | CODE-BACKED | Client-side request identifier for end-to-end tracing. |
| 7 | CreateDate | datetime | YES | CODE-BACKED | When the close saga was created (when the close was initiated). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.MirrorCloseSaga | SELECT (READER) | Reads the saga state for this mirror-customer close operation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | GRANT EXECUTE | Application User | Monitoring and debugging |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorCloseSagaByID (procedure)
+-- Trade.MirrorCloseSaga (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.MirrorCloseSaga | Table | SELECT saga state by MirrorID + CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | Application User | Saga monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get close saga for a specific mirror

```sql
EXEC Trade.GetMirrorCloseSagaByID @MirrorID = 12345, @CID = 67890;
```

### 8.2 Find all active close sagas

```sql
SELECT  MirrorID,
        CID,
        CurrentStepIndex,
        MirrorCloseActionType,
        CreateDate
FROM    Trade.MirrorCloseSaga WITH (NOLOCK)
ORDER BY CreateDate DESC;
```

### 8.3 Find stuck sagas (created more than 1 hour ago)

```sql
SELECT  MirrorID,
        CID,
        CurrentStepIndex,
        CreateDate,
        DATEDIFF(MINUTE, CreateDate, GETUTCDATE()) AS MinutesSinceCreation
FROM    Trade.MirrorCloseSaga WITH (NOLOCK)
WHERE   DATEDIFF(MINUTE, CreateDate, GETUTCDATE()) > 60
ORDER BY CreateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorCloseSagaByID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorCloseSagaByID.sql*
