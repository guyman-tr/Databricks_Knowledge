# History.LogOutByLobbyID

> Bulk logout procedure that terminates all active sessions in a given lobby by iterating over Customer.Login with a cursor and calling History.LogOutByLoginID for each active session.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LobbyID - the lobby whose active sessions are all force-closed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogOutByLobbyID` performs a bulk, lobby-scoped logout. It closes every active session in `Customer.Login` that is associated with the given LobbyID. This is used for lobby-level maintenance operations - for example, when a lobby server is being shut down, restarted, or taken offline, all players currently connected to that lobby need to be logged out so that their sessions are properly archived and their game state is cleaned up.

The procedure exists because the normal logout path (`History.LogOutByLoginID`) operates on a single session at a time. `History.LogOutByLobbyID` wraps that in a cursor loop to handle bulk closure without requiring the caller to enumerate each session individually.

Data flow: The caller provides a LobbyID. The procedure opens a STATIC LOCAL cursor over `Customer.Login WHERE LobbyID = @LobbyID`, fetching CID, LoginID, and NumberOfConnections for each active session. For each row, it calls `History.LogOutByLoginID` to perform the individual session close (delete from Customer.Login, archive to History.Login, fire events, recalculate player level). The cursor continues until all sessions in the lobby are closed.

---

## 2. Business Logic

### 2.1 Cursor-Based Bulk Logout

**What**: All active sessions for a given lobby are closed one by one using a CURSOR, reusing the single-session logout logic in History.LogOutByLoginID.

**Columns/Parameters Involved**: `@LobbyID`, `Customer.Login.LobbyID`, `Customer.Login.CID`, `Customer.Login.LoginID`, `Customer.Login.NumberOfConnections`

**Rules**:
- Uses a STATIC cursor: the session list is snapshotted at the time the cursor is opened. New sessions that join the lobby during execution will not be affected.
- Cursor scope is LOCAL: not visible outside this procedure's execution context.
- Each row yields @CID, @LoginID, @NumberOfConnections which are passed directly to History.LogOutByLoginID.
- Return value from History.LogOutByLoginID is not checked; errors in individual session closure do not stop the loop.
- Returns 0 on completion regardless of how many sessions were closed.

**Diagram**:
```
SELECT CID, LoginID, NumberOfConnections
FROM Customer.Login WHERE LobbyID = @LobbyID (STATIC snapshot)
     |
     v
WHILE rows remain:
  EXEC History.LogOutByLoginID @CID, @LoginID, @NumberOfConnections
     |  (archives session, fires events, recalculates player level)
     v
RETURN 0
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LobbyID | INT | NO | - | CODE-BACKED | The lobby identifier whose active sessions are all to be closed. Matched against Customer.Login.LobbyID. All sessions with this LobbyID in Customer.Login (active sessions table) at cursor-open time will be logged out via History.LogOutByLoginID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LobbyID | Customer.Login | Lookup + Cursor | SELECT CID, LoginID, NumberOfConnections WHERE LobbyID = @LobbyID to enumerate all active sessions in the lobby |
| (body) | History.LogOutByLoginID | Procedure call | Called for each active session found; handles the full individual logout lifecycle (archive, events, player level) |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. This procedure is expected to be called externally (lobby server shutdown routines or administrative scripts).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogOutByLobbyID (procedure)
+-- Customer.Login (table)
+-- History.LogOutByLoginID (procedure)
      +-- Customer.Login (table)
      +-- History.Login (table)
      +-- Customer.Customer (table)
      +-- Customer.SendEvent (procedure)
      +-- History.InsertLogErrorGeneral (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Login | Table | CURSOR SELECT to enumerate all active sessions for @LobbyID |
| History.LogOutByLoginID | Procedure | Called per session to execute the full individual logout flow |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| STATIC cursor | Implementation | Session list is snapshotted at cursor open time; late arrivals to the lobby are not affected |
| No error propagation | Implementation | Return value of History.LogOutByLoginID per iteration is not checked; individual logout failures do not abort the loop |

---

## 8. Sample Queries

### 8.1 Check which sessions are active in a lobby before calling this procedure

```sql
SELECT CID, LoginID, NumberOfConnections, LoggedIn, IP, ClientVersion
FROM Customer.Login WITH (NOLOCK)
WHERE LobbyID = 999
ORDER BY LoggedIn DESC
```

### 8.2 Count active sessions per lobby

```sql
SELECT LobbyID, COUNT(*) AS ActiveSessions
FROM Customer.Login WITH (NOLOCK)
GROUP BY LobbyID
ORDER BY ActiveSessions DESC
```

### 8.3 Verify all sessions for a lobby are closed after execution

```sql
SELECT COUNT(*) AS RemainingActiveSessions
FROM Customer.Login WITH (NOLOCK)
WHERE LobbyID = 999
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (LogOutByLoginID dependency) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.LogOutByLobbyID | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogOutByLobbyID.sql*
