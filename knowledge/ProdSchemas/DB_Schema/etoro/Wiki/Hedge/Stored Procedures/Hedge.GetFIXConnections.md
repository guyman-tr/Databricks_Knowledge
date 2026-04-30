# Hedge.GetFIXConnections

> Returns all FIX connection records for a specific liquidity account, providing the connection IDs and schedule references the hedge server needs to manage provider sessions.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityAccountID - the liquidity account whose FIX connections to retrieve |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetFIXConnections retrieves all FIX connection records associated with a specific liquidity account. A liquidity account (e.g., ZBFX, OMS UAT IM3) may have one or more FIX connections - each representing a distinct named session endpoint. The procedure returns the connection metadata needed by the hedge server to enumerate which FIX sessions to establish, what to name them, and what schedule governs their uptime.

The procedure is a simple lookup used during hedge server initialization when the server needs to know which FIX connections belong to its configured liquidity accounts. It returns connection-level metadata only (name, ID, schedule); the detailed FIX session parameters (host, port, credentials) are loaded separately via Hedge.GetFIXConnectionDetails using the returned ConnectionIDs.

Not called by any other SQL procedures in the schema - called directly from the hedge server application.

---

## 2. Business Logic

### 2.1 One Liquidity Account, Multiple Connections

**What**: A single liquidity account may have multiple FIX connections (e.g., primary and backup, or different execution venues under the same provider account).

**Columns/Parameters Involved**: `LiquidityAccountID`, `ConnectionID`, `Name`, `ScheduleID`

**Rules**:
- All connections returned share the same @LiquidityAccountID.
- The hedge server uses ConnectionID from this result to call Hedge.GetFIXConnectionDetails for each connection to load its full parameters.
- ScheduleID controls when each connection is active: "AllWeekExample" (24/7), "OMS" (OMS-gated), "Default" (standard trading hours).
- In practice, most liquidity accounts have 1 connection; the query supports multiple but the typical case is a single row returned.

**Diagram**:
```
@LiquidityAccountID = 8 (ZBFX):
  -> ConnectionID=1, Name="ZBFX Price1 Execution", ScheduleID="AllWeekExample"
  -> ConnectionID=10, Name="ZBFX Price2 Execution", ScheduleID="AllWeekExample"
  (Then caller does: GetFIXConnectionDetails(@ConnectionID=1) and (=10))
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityAccountID | int | NO | - | CODE-BACKED | The liquidity account to retrieve FIX connections for. References Hedge.Accounts.ID (implicit FK via Hedge.FIXConnections.LiquidityAccountID). E.g., 8=ZBFX, 2147=OMS UAT IM3. |

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | ConnectionID | int | NO | - | CODE-BACKED | The FIX connection identifier. PK of Hedge.FIXConnections. Used by the caller to subsequently load session parameters via Hedge.GetFIXConnectionDetails(@ConnectionID). |
| 3 | Name | varchar(256) | YES | - | CODE-BACKED | Human-readable display name for the FIX connection. Identifies the provider and purpose: "ZBFX Price1 Execution", "OMS UAT IM3", etc. May be NULL for unconfigured connections. Inherited from Hedge.FIXConnections.Name. |
| 4 | LiquidityAccountID | int | YES | - | CODE-BACKED | Echoed from the filter. All rows will have this same value (= @LiquidityAccountID). Implicit FK to Hedge.Accounts.ID. Inherited from Hedge.FIXConnections.LiquidityAccountID. |
| 5 | ScheduleID | varchar(256) | NO | - | CODE-BACKED | Trading schedule governing when this connection should be active. Observed values: "AllWeekExample" (24/7), "OMS" (OMS-gated hours), "Default" (standard hours). References Hedge.FIXSchedules (implicit, no DDL FK). Inherited from Hedge.FIXConnections.ScheduleID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LiquidityAccountID filter | Hedge.FIXConnections | Lookup / Read | Retrieves connection records by LiquidityAccountID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | LiquidityAccountID | Caller | Hedge server enumerates FIX connections for its liquidity accounts at startup; not called by any other SQL procedures. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetFIXConnections (procedure)
└── Hedge.FIXConnections (table)
      └── Hedge.Accounts (table) [implicit FK - LiquidityAccountID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.FIXConnections | Table | SELECT ConnectionID, Name, LiquidityAccountID, ScheduleID WHERE LiquidityAccountID = @LiquidityAccountID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server (external) | Application | Calls at startup to discover which FIX connections belong to a liquidity account; uses returned ConnectionIDs to call GetFIXConnectionDetails. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Retrieve all FIX connections for the primary ZBFX account

```sql
EXEC Hedge.GetFIXConnections @LiquidityAccountID = 8;
```

### 8.2 Verify manually against the table

```sql
SELECT ConnectionID, [Name], LiquidityAccountID, ScheduleID
FROM   Hedge.FIXConnections WITH (NOLOCK)
WHERE  LiquidityAccountID = 8
ORDER BY ConnectionID;
```

### 8.3 All liquidity accounts and their FIX connection count

```sql
SELECT LiquidityAccountID,
       COUNT(1)          AS ConnectionCount,
       MAX([Name])       AS SampleName,
       MAX(ScheduleID)   AS SampleSchedule
FROM   Hedge.FIXConnections WITH (NOLOCK)
GROUP  BY LiquidityAccountID
ORDER  BY LiquidityAccountID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetFIXConnections | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetFIXConnections.sql*
