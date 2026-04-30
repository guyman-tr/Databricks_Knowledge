# Billing.CashierLogin

> Narrow projection view of Billing.Login exposing only the session identifier, customer ID, and login timestamp - a legacy view for the deprecated Billing cashier session system, with last activity in 2017.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | LoginID - from Billing.Login |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.CashierLogin` is a read-only projection of `Billing.Login` that surfaces only the three core session-identification columns: LoginID, CID, and LoggedIn. It deliberately omits the LoggedOut timestamp, ManagerID, and IP address columns.

The view exists as a simplified read interface for the Billing cashier/backoffice session system - providing session lookup by login ID or customer ID without exposing the full session lifecycle details (logout time, IP). The pattern suggests a consumer (application or reporting query) only needed to know "who is logged in and when did they log in" without the fuller administrative context.

This is a legacy view associated with a deprecated system. `Billing.Login` (the base table) contains only 384 rows, all belonging to CID=20653 (a Billing backoffice account), with the last row created in May 2017. No new sessions have been recorded since. The view remains in place but serves no active operational purpose. See [Billing.Login](../Tables/Billing.Login.md) for full historical context.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This view is a pure column-projection SELECT with no WHERE filter, aggregation, or computation. All rows from Billing.Login are exposed; the consumer must apply any filtering (e.g., active sessions, specific CID).

---

## 3. Data Overview

| LoginID | CID | LoggedIn | Meaning |
|---|---|---|---|
| 3370 | 20653 | 2017-05-24 13:46 | Last session ever recorded in the system - a local loopback (127.0.0.1) session for CID=20653 (the Billing backoffice account), never formally closed. Marks the effective end of this system's active use. |
| 3369 | 20653 | 2017-05-17 15:30 | Session from an external eToro office IP, properly closed before session 3370 began. |
| 3368 | 20653 | 2017-05-17 15:30 | Duplicate session opened at the exact same millisecond as 3369, same IP - suggests a retry or concurrent request. Never formally closed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LoginID | int | NO | - | CODE-BACKED | Auto-incrementing session identifier. From Billing.Login.LoginID (IDENTITY PK). Identifies a unique cashier session record. All 384 records in the base table are exposed; last value is 3370 (May 2017). |
| 2 | CID | int | NO | - | CODE-BACKED | Customer/user ID of the session owner. From Billing.Login.CID. FK to Customer.CustomerStatic. In practice, all records belong to CID=20653 (the Billing backoffice account). |
| 3 | LoggedIn | datetime | NO | - | CODE-BACKED | Timestamp when the session was created (via Billing.LogIn SP using GETDATE() - server local time, not UTC). From Billing.Login.LoggedIn. Indicates when the cashier logged in to the Billing system. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LoginID, CID, LoggedIn | Billing.Login | Source (FROM) | All columns are direct projections from the Login table; no transformation applied |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No stored procedures in Billing schema reference this view | - | - | Legacy view, no active code consumers discovered |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CashierLogin (view)
└── Billing.Login (table)
      └── Customer.CustomerStatic (table, FK target for CID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Login | Table | FROM source: all rows, 3 columns projected (LoginID, CID, LoggedIn) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered | - | Legacy view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No WHERE filter, no computed columns, no aggregation. Simple SELECT of 3 columns from Billing.Login.

---

## 8. Sample Queries

### 8.1 View all cashier sessions (legacy data only)

```sql
SELECT LoginID, CID, LoggedIn
FROM Billing.CashierLogin WITH (NOLOCK)
ORDER BY LoginID DESC
```

### 8.2 Check session history for a specific customer

```sql
SELECT LoginID, CID, LoggedIn
FROM Billing.CashierLogin WITH (NOLOCK)
WHERE CID = @CustomerID
ORDER BY LoggedIn DESC
```

### 8.3 Join with Login table for full session details

```sql
-- CashierLogin only shows 3 columns; join to Login for full context
SELECT cl.LoginID, cl.CID, cl.LoggedIn,
       l.LoggedOut, l.IP, l.ManagerID
FROM Billing.CashierLogin cl WITH (NOLOCK)
INNER JOIN Billing.Login l WITH (NOLOCK) ON cl.LoginID = l.LoginID
ORDER BY cl.LoginID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CashierLogin | Type: View | Source: etoro/etoro/Billing/Views/Billing.CashierLogin.sql*
