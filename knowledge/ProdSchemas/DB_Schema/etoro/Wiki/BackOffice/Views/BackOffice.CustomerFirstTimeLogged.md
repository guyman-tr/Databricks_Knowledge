# BackOffice.CustomerFirstTimeLogged

> Filters History.LoginArch to return only customers who have exactly one login record total - identifying first-time-only logins where the customer has never logged in again.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | CID (from base view) |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.CustomerFirstTimeLogged` identifies customers who have appeared in the login archive exactly once - customers whose entire login history consists of a single record. This acts as a "first-time login" marker: if a customer has only one login on record, that login is definitionally their first (and so far only) session.

This view is used to detect customers at the "freshly registered, first login" stage of the onboarding funnel. Back-office logic monitoring first logins (e.g., for welcome workflows, onboarding triggers, or registration metrics) can query this view to identify customers whose very first login session just appeared in the system.

The base source is `History.LoginArch` - itself a UNION ALL view combining:
- `Customer.Login`: currently active/recent sessions (LoggedOut = NULL, IsLogged = 1)
- `History.Login`: archived completed sessions

The filter `HAVING COUNT(*) = 1` ensures only customers with a single login record (across both active and archived sessions combined) appear.

---

## 2. Business Logic

### 2.1 First-Login Detection via COUNT Filter

**What**: Returns CID and IsLogged for customers with exactly one total login record in the system.

**Columns Involved**: CID, IsLogged (from History.LoginArch)

**Rules**:
- The correlated EXISTS subquery groups `History.LoginArch` by CID and filters to groups with COUNT(*) = 1.
- Only customers with exactly ONE row across `Customer.Login UNION ALL History.Login` are returned.
- A customer with more than one session (even if all are in History.Login) will NOT appear.
- Since these customers have exactly one login, the outer SELECT returns exactly one row per qualifying CID.
- `IsLogged` = 1 for the current active session record (from Customer.Login); `IsLogged` from History.Login records the session's logged-in flag.
- This view produces one row per first-time-only customer (their single login record).

**Diagram**:
```
History.LoginArch (UNION ALL of Customer.Login + History.Login)
  |
  +-- Correlated EXISTS: "Does this CID have COUNT(*) = 1 total logins?"
        |
        YES -> Include this row (CID's only-ever login)
        NO  -> Exclude (customer has multiple logins)
        |
        v
BackOffice.CustomerFirstTimeLogged
  (one row per customer who has logged in exactly once total)
  CID | IsLogged
  ... |    1    (active single-login customer)
  ... |    1    (active single-login customer)
```

---

## 3. Data Overview

N/A - this is a filtered view over `History.LoginArch`. Row count depends on how many customers have exactly 1 login record at query time. Given `CustomerAllTimeAggregatedData_1` shows TotalLoginCount distribution, the fraction with exactly 1 login is likely a small subset of total customers (recently registered accounts or churned first-time visitors).

---

## 4. Elements

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| 1 | CID | int | History.LoginArch.CID | CODE-BACKED | Customer ID. Identifies the customer who has exactly one login record on file. |
| 2 | IsLogged | bit | History.LoginArch.IsLogged | CODE-BACKED | Login state flag. 1 = session is/was active (from Customer.Login, always 1); for History.Login rows, records whether the session was logged-in at archive time. Since customers appear here only once, this is the IsLogged flag from their single login record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HLOG, HLGF | History.LoginArch | Base View | All login data sourced from this UNION view (Customer.Login + History.Login) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No BackOffice SP consumers identified in SSDT) | - | - | No stored procedures in BackOffice schema reference this view. Likely consumed by application code or reporting queries outside the SSDT repo. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerFirstTimeLogged (view)
+-- History.LoginArch (view, cross-schema)
      +-- Customer.Login (active sessions)
      +-- History.Login (archived sessions)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.LoginArch | View (cross-schema) | Base data source - both as outer query and inner correlated subquery for the COUNT(*) = 1 filter |

### 6.2 Objects That Depend On This

No stored procedure consumers identified in the SSDT repo. The view may be used directly by application services or external reporting.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Query performance depends on indexes on `Customer.Login` and `History.Login` (CID columns).

### 7.2 Constraints

N/A for View.

### 7.3 Performance Note

The correlated subquery (`WHERE EXISTS (SELECT ... GROUP BY CID HAVING COUNT(*) = 1)`) is evaluated per row in the outer scan of `History.LoginArch`. This pattern can be expensive on large login tables. The semantically equivalent form `CID IN (SELECT CID FROM History.LoginArch GROUP BY CID HAVING COUNT(*) = 1)` may perform better with a covering index on CID.

---

## 8. Sample Queries

### 8.1 Get all customers who have logged in exactly once

```sql
SELECT CID, IsLogged
FROM BackOffice.CustomerFirstTimeLogged WITH (NOLOCK);
```

### 8.2 Join to customer info for first-time-only logins

```sql
SELECT cftl.CID,
       cftl.IsLogged,
       bc.RegisterDate,
       bc.PlayerStatusID
FROM BackOffice.CustomerFirstTimeLogged cftl WITH (NOLOCK)
JOIN BackOffice.Customer bc WITH (NOLOCK)
    ON bc.CID = cftl.CID
ORDER BY bc.RegisterDate DESC;
```

### 8.3 Count first-time-only logins today

```sql
SELECT COUNT(DISTINCT cftl.CID) AS FirstTimeOnlyLogins
FROM BackOffice.CustomerFirstTimeLogged cftl WITH (NOLOCK)
JOIN History.LoginArch hlog WITH (NOLOCK)
    ON hlog.CID = cftl.CID
WHERE CAST(hlog.LoggedIn AS DATE) = CAST(GETDATE() AS DATE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this view.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11 (DDL, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerFirstTimeLogged | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.CustomerFirstTimeLogged.sql*
