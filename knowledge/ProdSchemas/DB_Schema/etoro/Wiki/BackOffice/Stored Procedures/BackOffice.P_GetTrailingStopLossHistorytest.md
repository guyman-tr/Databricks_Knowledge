# BackOffice.P_GetTrailingStopLossHistorytest

> Cross-server proxy that delegates to the TSL history procedure on the remote SyncTSL server, returning trailing stop loss history for a position from the legacy archive.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | EXEC [synctsl].[SyncTsl].[BackOffice].[P_GetTrailingStopLossHistory] @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.P_GetTrailingStopLossHistorytest` is a cross-server passthrough procedure. It executes `BackOffice.P_GetTrailingStopLossHistory` on the remote [synctsl] linked server (the original SyncTSL SQL Server instance) and returns whatever that remote procedure returns. The "test" suffix in the name suggests this was originally created as a test/diagnostic wrapper, though it is a production-deployed procedure.

The relationship to `BackOffice.P_GetTrailingStopLossHistory` (local) is complementary: the local version unions data from both local tables AND the remote server. This "test" version calls only the remote server's version, which presumably has its own data scope. This procedure is useful when you need to query TSL history directly from the remote SyncTSL server without the UNION overhead of the local version.

Change history from comments: Originally created by Geri Reshef (ticket 36158, May 2016) for TSL history retrieval; PositionID parameter changed to BIGINT by Shay O (June 2021).

---

## 2. Business Logic

### 2.1 Cross-Server Delegation Pattern

**What**: Single EXEC call to the same-named procedure on the remote [synctsl] linked server.

**Rules**:
- EXEC [synctsl].[SyncTsl].[BackOffice].[P_GetTrailingStopLossHistory] @PositionID: four-part name notation for linked server execution.
- Returns the result set from the remote procedure directly.
- Requires the [synctsl] linked server to be configured and accessible.
- If the linked server is down, the procedure fails with a linked server connectivity error.
- No local data is read or written by this procedure.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | bigint | NO | - | CODE-BACKED | ID of the trading position whose TSL history to retrieve. Passed directly to the remote procedure. Changed to BIGINT (Shay O, June 2021) to match the parameter type on the remote procedure. |

Output: Same columns as BackOffice.P_GetTrailingStopLossHistory (ID, PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy, DateInserted) - sourced from the remote SyncTSL server.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | [synctsl].[SyncTsl].[BackOffice].[P_GetTrailingStopLossHistory] | Callee (cross-server) | Delegates to the same-named procedure on the remote SyncTSL linked server |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found in BackOffice schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.P_GetTrailingStopLossHistorytest (procedure)
+-- [synctsl].[SyncTsl].[BackOffice].[P_GetTrailingStopLossHistory] (remote procedure) [EXEC]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [synctsl].[SyncTsl].[BackOffice].[P_GetTrailingStopLossHistory] | Remote Stored Procedure | EXEC via linked server - returns TSL history from remote SyncTSL server |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Requires [synctsl] linked server connectivity. No fallback if remote server is unavailable.

---

## 8. Sample Queries

### 8.1 Get TSL history from the remote SyncTSL server

```sql
EXEC BackOffice.P_GetTrailingStopLossHistorytest @PositionID = 123456789;
```

### 8.2 Compare local vs remote TSL history for a position

```sql
-- Local (post-migration + migration transition data):
EXEC BackOffice.P_GetTrailingStopLossHistory @PositionID = 123456789;

-- Remote only (legacy SyncTSL server):
EXEC BackOffice.P_GetTrailingStopLossHistorytest @PositionID = 123456789;
```

### 8.3 Verify linked server connectivity before calling

```sql
SELECT name, is_linked FROM sys.servers WITH (NOLOCK) WHERE name = 'synctsl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.P_GetTrailingStopLossHistorytest | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.P_GetTrailingStopLossHistorytest.sql*
