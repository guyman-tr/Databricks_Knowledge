# BackOffice.GetManagers

> Returns all BackOffice managers or a specific manager by ID, including contact details, Calendly scheduling link, title, and the manager's own customer account (CID).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ManagerID (optional) - if NULL, returns all managers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the list of BackOffice managers registered in the system. It answers: "Who are the BackOffice managers, what are their contact details, and what is their CID?" - serving as the manager directory lookup for services that need to assign, display, or route work to BackOffice staff.

BackOffice managers are the agents responsible for customer account management, withdrawal processing, document verification, and compliance tasks within eToro's BackOffice system. This procedure is called by multiple services (CashoutTool, ClubService, WithdrawalServiceUser) to populate manager selection lists and to associate withdrawal/account operations with the responsible manager.

The optional `@ManagerID` parameter allows fetching a single manager (for detail views) or all managers (for dropdown lists/bulk operations). The `eToroCID` alias as `CID` links each BackOffice manager to their own eToro customer account - relevant for scenarios where a manager has a trading account of their own (e.g., for Popular Investor managers).

---

## 2. Business Logic

### 2.1 Optional Single-Manager vs All-Managers Fetch

**What**: The procedure uses a standard optional filter pattern - pass NULL to get all, pass an ID to get one.

**Columns/Parameters Involved**: `@ManagerID`

**Rules**:
- `WHERE bm.ManagerID = @ManagerID OR @ManagerID IS NULL` - when @ManagerID is NULL (default), all managers are returned.
- When @ManagerID is provided, exactly one manager is returned (assuming ManagerID is a unique key in BackOffice.Manager).
- No ORDER BY clause - callers are responsible for sorting if needed.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ManagerID | INT | YES | NULL | CODE-BACKED | Optional input parameter. When NULL (default), returns all BackOffice managers. When provided, returns only the single manager with that ManagerID. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManagerID | INT | NO | - | CODE-BACKED | Primary key of the BackOffice manager. Unique identifier used across the BackOffice schema to reference this manager (in CustomerDocument, Withdraw, MailTemplates, etc.). |
| 2 | FirstName | NVARCHAR | YES | - | CODE-BACKED | Manager's first name. Displayed in UI dropdowns and assignment lists. |
| 3 | LastName | NVARCHAR | YES | - | CODE-BACKED | Manager's last name. Combined with FirstName for display purposes. |
| 4 | Email | NVARCHAR | YES | - | CODE-BACKED | Manager's email address. Used for internal notifications and communication routing. |
| 5 | CalendlyID | NVARCHAR | YES | - | CODE-BACKED | Manager's Calendly scheduling identifier. Used by Club/account management services to display a scheduling link to customers who wish to book a call with their assigned manager. Added August 2019. |
| 6 | ManagerTitleID | INT | YES | - | CODE-BACKED | Title/role classification of the manager (e.g., Account Manager, Senior Account Manager). References a title lookup table. Added August 2019. |
| 7 | CID | INT | YES | - | CODE-BACKED | The manager's own eToro customer account identifier. Sourced from `BackOffice.Manager.eToroCID`. Relevant for managers who are also Popular Investors or have their own trading accounts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (internal) | BackOffice.Manager | Lookup (READ) | Sole data source for all output columns |
| CID | Customer.CustomerStatic or similar | Implicit | eToroCID is a CID linking the manager to the customer system |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CashoutTool (service) | EXECUTE | Permission | The CashoutTool service uses this to load the manager list for withdrawal processing assignment |
| ClubService (service) | EXECUTE | Permission | The Club/account management service uses this to display assigned manager profiles (including Calendly) to customers |
| WithdrawalServiceUser (service) | EXECUTE | Permission | The Withdrawal Service uses this to look up manager details when processing withdrawal requests |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetManagers (procedure)
└── BackOffice.Manager (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | FROM clause; source of all output columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CashoutTool | External service | Fetches manager list for cashout/withdrawal processing |
| ClubService | External service | Fetches manager profiles (including CalendlyID) for customer-facing account management |
| WithdrawalServiceUser | External service | Fetches manager details for withdrawal processing workflows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) on BackOffice.Manager | Query hint | Avoids blocking reads on the manager table |
| Optional filter pattern | Query logic | `WHERE ManagerID = @ManagerID OR @ManagerID IS NULL` enables both single-record and full-list retrieval |

---

## 8. Sample Queries

### 8.1 Get all managers

```sql
EXEC BackOffice.GetManagers
```

### 8.2 Get a specific manager by ID

```sql
EXEC BackOffice.GetManagers @ManagerID = 42
```

### 8.3 Get all managers with their title names

```sql
SELECT bm.ManagerID,
       bm.FirstName,
       bm.LastName,
       bm.Email,
       bm.CalendlyID,
       bm.eToroCID AS CID
FROM BackOffice.Manager bm WITH (NOLOCK)
ORDER BY bm.LastName, bm.FirstName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 8.0/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers, 3 app service consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetManagers | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetManagers.sql*
