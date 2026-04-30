# Customer.LoggedCustomer

> Active session view: joins Customer.Login to Customer.Customer to return customers with current login sessions, showing their most recent LoggedIn timestamp per session alongside their identity, affiliate, and campaign attributes.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | CID + CustomerSessionID (composite - one row per active session) |
| **Partition** | N/A |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Customer.LoggedCustomer is the primary view for querying currently logged-in customers. It joins Customer.Login (active session records) to Customer.Customer (full profile) and groups by session ID, exposing the most recent LoggedIn timestamp per session. The result set contains one row per customer session - a customer with multiple active sessions (e.g., simultaneous web and mobile login) will appear multiple times.

The view includes the BackOffice.Campaign record for each customer's acquisition campaign, enabling tracking of which campaigns are driving login activity. The CampaignID and Campaign.Code columns allow attribution analysis: which marketing campaigns are producing actively logged-in users.

The view includes both real (IsReal=1) and demo (IsReal=0) customers - there is no IsReal filter. The IsReal column is exposed so consumers can filter as needed.

---

## 2. Business Logic

### 2.1 Session-Level Grouping

**What**: The view groups by CustomerSessionID (not just CID), meaning one customer with multiple sessions appears once per session.

**Columns/Parameters Involved**: `CustomerSessionID`, `LoggedIn`

**Rules**:
- GROUP BY includes CustomerSessionID - each active session is a separate row
- MAX(LoggedIn) returns the most recent activity timestamp within that session
- Customers with multiple concurrent sessions (web + mobile) have multiple rows
- CustomerSessionID is a GUID from Customer.Login identifying the session token
- Consumers must be aware of the 1:many CID-to-row relationship

### 2.2 Campaign Attribution

**What**: The Campaign.Code column enables tracking which marketing campaign drove each customer's registration.

**Columns/Parameters Involved**: `CampaignID`, `Code`

**Rules**:
- LEFT OUTER JOIN to BackOffice.Campaign on CampaignID
- Code is NULL for organic/unattributed customers (CampaignID IS NULL)
- Code is the BackOffice campaign tracking code (e.g., "GOOGLE_EN_2021")
- Enables campaign-level login attribution analysis

---

## 3. Data Overview

| CID | UserName | IsReal | PlayerLevelID | CustomerSessionID | LoggedIn | Meaning |
|-----|----------|--------|--------------|-------------------|----------|---------|
| 758355 | marcosdelrio99 | true | 1 | D095438E-... | 2014-03-22 21:31:51 | Real account, standard level, logged in via web session. Old 2014 timestamp indicates test/dev data. SerialID=7497 (acquired via affiliate). |
| 3293664 | DanielJCM | true | 1 | CFD266E6-... | 2014-03-22 21:15:03 | Real account with affiliate acquisition (SerialID=22764). OriginalCID=4261349 indicates migrated account. |
| 3631878 | jonathanhygea | true | 1 | E61D5904-... | 2014-03-22 19:21:20 | Standard real account. Last session from March 2014. No campaign (CampaignID=null). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID - platform-internal primary key. From Customer.Customer (CustomerStatic). |
| 2 | OriginalProviderID | int | NO | - | CODE-BACKED | Provider ID from original migration source. From Customer.Customer (CustomerStatic). 0 for non-migrated accounts. |
| 3 | OriginalCID | int | NO | - | CODE-BACKED | Original CID before migration. From Customer.Customer (CustomerStatic). Default=0 for native accounts; non-zero indicates the source CID before porting. |
| 4 | SerialID | int | YES | - | VERIFIED | Affiliate ID under which the customer was acquired. From Customer.Customer.SerialID. FK to BackOffice.Affiliate. NULL for organic registrations. |
| 5 | UserName | varchar(20) | NO | - | VERIFIED | Customer login username. From Customer.Customer (CustomerStatic). Unique identifier for display and lookup. |
| 6 | Email | varchar(50) | YES | - | VERIFIED | Customer email address. From Customer.Customer (CustomerStatic). Dynamic Data Masking on base table. |
| 7 | PlayerLevelID | int | NO | - | VERIFIED | Customer tier/experience level. From Customer.Customer (CustomerStatic). FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor; 7=VIP. |
| 8 | CustomerSessionID | uniqueidentifier | YES | - | CODE-BACKED | Active session GUID from Customer.Login. Identifies the specific login session. A single CID can have multiple active sessions (multiple rows per customer in this view). |
| 9 | CampaignID | int | YES | - | VERIFIED | Marketing campaign ID from customer's acquisition. From Customer.Customer (CustomerStatic). FK to BackOffice.Campaign. NULL for organic/direct registrations. |
| 10 | Code | nvarchar | YES | - | CODE-BACKED | Campaign tracking code from BackOffice.Campaign. NULL when CampaignID is NULL (organic) or when no matching Campaign record exists. Used for marketing attribution. |
| 11 | IsReal | bit | NO | - | VERIFIED | 1=real-money account, 0=demo account. From Customer.Customer (CustomerStatic). Both real and demo customers appear in this view. |
| 12 | LoggedIn | datetime | YES | - | VERIFIED | Most recent activity timestamp for this session. MAX(Customer.Login.LoggedIn) grouped by all other columns. When this timestamp was last updated depends on the client application's session heartbeat frequency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OriginalProviderID, OriginalCID, SerialID, UserName, Email, PlayerLevelID, CampaignID, IsReal | Customer.Customer | FROM (base view, CCST alias) | Full customer profile |
| CustomerSessionID, LoggedIn | Customer.Login | FROM (CLOG alias) via WHERE CLOG.CID = CCST.CID | Active login session data |
| Code | BackOffice.Campaign | LEFT OUTER JOIN on CampaignID | Campaign tracking code |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view in the SSDT repository. Used directly by applications or marketing systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.LoggedCustomer (view)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
├── Customer.Login (table)
└── BackOffice.Campaign (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (base view, CCST alias) - customer profile |
| Customer.Login | Table | FROM (CLOG alias) with WHERE join on CID - session data |
| BackOffice.Campaign | Table (cross-schema) | LEFT OUTER JOIN on CampaignID - campaign code |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE CLOG.CID = CCST.CID | Implicit INNER JOIN | Only customers with at least one login record appear (no sessions = excluded) |
| GROUP BY CustomerSessionID | Multi-row per customer | One row per session - CID may appear multiple times |

---

## 8. Sample Queries

### 8.1 Most recently active real customers
```sql
SELECT
    CID,
    UserName,
    Email,
    IsReal,
    PlayerLevelID,
    LoggedIn
FROM Customer.LoggedCustomer WITH (NOLOCK)
WHERE IsReal = 1
ORDER BY LoggedIn DESC;
```

### 8.2 Campaign attribution for active sessions
```sql
SELECT
    Code AS CampaignCode,
    COUNT(DISTINCT CID) AS UniqueCIDs,
    MAX(LoggedIn) AS LastSeen
FROM Customer.LoggedCustomer WITH (NOLOCK)
WHERE Code IS NOT NULL
GROUP BY Code
ORDER BY UniqueCIDs DESC;
```

### 8.3 Customers with multiple concurrent sessions
```sql
SELECT
    CID,
    UserName,
    COUNT(*) AS SessionCount,
    MAX(LoggedIn) AS LastActivity
FROM Customer.LoggedCustomer WITH (NOLOCK)
GROUP BY CID, UserName
HAVING COUNT(*) > 1
ORDER BY SessionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 9.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.LoggedCustomer | Type: View | Source: etoro/etoro/Customer/Views/Customer.LoggedCustomer.sql*
