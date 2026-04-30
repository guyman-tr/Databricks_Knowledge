# Billing.Login

> Legacy session log table recording Billing cashier/backoffice login and logout events, with last activity in 2017 - effectively deprecated.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | LoginID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | HISTORY filegroup |
| **Indexes** | 2 active (PK clustered + NC on CID + LoggedIn DESC) |

---

## 1. Business Meaning

Billing.Login is a legacy session tracking table that recorded login and logout events for the Billing cashier/backoffice system. Each row represents a session: when a user (identified by CID) logged in, and optionally when they logged out. The table stores the originating IP address and a ManagerID (always 0 in practice, suggesting it was never used for manager-supervised sessions).

This table is effectively deprecated. The 384 rows span 2014-2017 and all belong to a single CID (20653), indicating the table was only ever used by a specific internal test or backoffice account before the session tracking was moved elsewhere. The table resides on the HISTORY filegroup, further confirming it was treated as read-mostly historical data.

The supporting procedures Billing.LogIn (INSERT) and Billing.LogOut (UPDATE LoggedOut) and the view Billing.CashierLogin still exist in the codebase but the table itself stopped receiving new rows after May 2017.

---

## 2. Business Logic

### 2.1 Session Lifecycle

**What**: A session begins when LogIn is called and ends when LogOut is called.

**Columns/Parameters Involved**: `LoginID`, `LoggedIn`, `LoggedOut`

**Rules**:
- On Billing.LogIn: inserts a new row with LoggedIn=GETDATE(), LoggedOut=NULL.
- On Billing.LogOut: updates the matching row's LoggedOut to the current timestamp.
- Rows with LoggedOut=NULL represent sessions that were never explicitly closed (browser closed, timeout, or abandoned).
- From live data: many rows have LoggedOut=NULL or LoggedOut < LoggedIn (data anomaly) suggesting the LogOut SP was not reliably called.

---

## 3. Data Overview

| LoginID | CID | LoggedIn | LoggedOut | ManagerID | IP |
|---|---|---|---|---|---|
| 3370 | 20653 | 2017-05-24 13:46 | NULL | 0 | 127.0.0.1 | Local loopback session, never closed. Last record in the table - end of active use. |
| 3369 | 20653 | 2017-05-17 15:30 | 2017-05-24 13:28 | 0 | 194.105.145.92 | Regular session from external IP, properly closed before the next session started. |
| 3368 | 20653 | 2017-05-17 15:30 | NULL | 0 | 194.105.145.92 | Duplicate session started same minute - two rows for same time suggests concurrent sessions or retry. Never closed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LoginID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Auto-incrementing session identifier. NOT FOR REPLICATION flag indicates this table was part of a replicated setup where the identity should not be re-seeded on the subscriber. Clustered PK. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer/user ID who initiated the session. Explicit FK to Customer.CustomerStatic(CID). In practice, all 384 rows belong to CID=20653 (a Billing backoffice account). |
| 3 | LoggedIn | datetime | NO | - | CODE-BACKED | UTC timestamp when the session was created (via Billing.LogIn SP using GETDATE()). Note: SP uses GETDATE() not GETUTCDATE() - timestamps reflect server local time. |
| 4 | LoggedOut | datetime | YES | - | CODE-BACKED | UTC timestamp when the session was explicitly closed (via Billing.LogOut SP). NULL means the session was never formally closed (timeout, browser close, or abandoned). |
| 5 | ManagerID | int | NO | (0) | CODE-BACKED | Identifier for a supervising manager. Default is 0 and all 384 rows have ManagerID=0 - this field was defined for supervised-session functionality that was never implemented or used. |
| 6 | IP | char(15) | YES | - | CODE-BACKED | IPv4 address of the client machine, stored as a fixed 15-character string (max IPv4 length). Trailing spaces pad shorter addresses. Values observed: 127.0.0.1 (local) and 194.105.145.92 (eToro office IP). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (explicit FK_CCST_ILOG) | References the customer who initiated the billing session. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.LogIn | LoginID | INSERT writer | Creates new session rows. |
| Billing.LogOut | LoggedOut | UPDATE writer | Closes sessions by setting LoggedOut timestamp. |
| Billing.CashierLogin | - | View | View built on this table for cashier session reporting. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Login (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Explicit FK target for CID column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.LogIn | Stored Procedure | INSERT writer |
| Billing.LogOut | Stored Procedure | UPDATE writer |
| Billing.CashierLogin | View | Reader - session reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ILOG | CLUSTERED PK | LoginID ASC | - | - | Active (FILLFACTOR=80, HISTORY filegroup) |
| ILOG_CLOGGED | NC | CID ASC, LoggedIn DESC | LoginID, IP, LoggedOut | - | Active (FILLFACTOR=90, HISTORY filegroup) - supports lookups of most recent sessions per customer |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ILOG | PRIMARY KEY | LoginID clustered |
| DF_BillingLogin_ManagerID | DEFAULT | ManagerID = 0 |
| FK_CCST_ILOG | FK | CID -> Customer.CustomerStatic(CID) |

---

## 8. Sample Queries

### 8.1 Get most recent sessions (historical data only)

```sql
SELECT TOP 10
    l.LoginID,
    l.CID,
    l.LoggedIn,
    l.LoggedOut,
    l.IP,
    DATEDIFF(MINUTE, l.LoggedIn, ISNULL(l.LoggedOut, l.LoggedIn)) AS SessionMinutes
FROM Billing.Login l WITH (NOLOCK)
ORDER BY l.LoginID DESC
```

### 8.2 Find sessions that were never closed

```sql
SELECT LoginID, CID, LoggedIn, IP
FROM Billing.Login WITH (NOLOCK)
WHERE LoggedOut IS NULL
ORDER BY LoggedIn DESC
```

### 8.3 Session history for a specific user

```sql
SELECT
    l.LoginID,
    l.LoggedIn,
    l.LoggedOut,
    l.IP,
    l.ManagerID
FROM Billing.Login l WITH (NOLOCK)
WHERE l.CID = 20653
ORDER BY l.LoggedIn DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.Login | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Login.sql*
