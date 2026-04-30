# Customer.GetUserChangesHistory

> Returns the full versioned history of a customer's key contact fields (Email, Phone, LanguageID) from the History.Customer audit table, identified by GCID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID -> History.Customer versions for the resolved CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUserChangesHistory returns every historical version of a customer's contact information from History.Customer, covering LanguageID, Email, and Phone. These are the fields most commonly changed by customers in account settings and most relevant to contact data synchronization. The procedure accepts a GCID (Group Customer ID) - the cross-product identifier used by modern services - and resolves it to a CID via Customer.CustomerStatic before querying History.Customer.

This procedure was created for Jira ticket COINF-1613 by Serhii Poltava. It is called by SQL_UserSyncAPI - the service responsible for synchronizing customer contact data across systems. The change history is needed by sync processes that need to detect what changed and when (e.g., to replay email or phone updates to downstream systems that missed them). Without this procedure, the sync service would need to join Customer.CustomerStatic to History.Customer and resolve GCID internally.

Data flows: Every UPDATE to Customer.CustomerStatic triggers the CustomerVersionUpdate trigger, which inserts a new History.Customer row with ValidFrom=GetUTCDate() and closes the previous row by setting ValidTo=GetUTCDate(). The current active version has ValidTo='3000-01-01'. This procedure returns ALL versions ordered by the History.Customer physical storage (no explicit ORDER BY - sorted by CID, implicit insert order).

---

## 2. Business Logic

### 2.1 GCID-to-CID Resolution Step

**What**: The procedure resolves the caller-supplied GCID to the internal CID before querying History.Customer, which is keyed on CID.

**Columns/Parameters Involved**: `@GCID`, `Customer.CustomerStatic.GCID`, `Customer.CustomerStatic.CID`

**Rules**:
- First step: SELECT @CID = CID FROM Customer.CustomerStatic WHERE GCID = @GCID
- If GCID does not exist in CustomerStatic (e.g., deleted or invalid), @CID remains NULL and the subsequent History.Customer query returns 0 rows (safe no-op)
- GCID is the cross-product identity used by external systems; CID is the internal eToro identity used by History.Customer
- This two-step pattern is common in newer procedures that accept GCID to support cross-product integrations

### 2.2 History Snapshot Columns

**What**: Only a subset of History.Customer columns is returned - those relevant to contact data synchronization.

**Columns/Parameters Involved**: `CID`, `GCID`, `LanguageID`, `Email`, `Phone`, `ValidFrom`, `ValidTo`

**Rules**:
- ValidFrom / ValidTo define the time window during which each version was active
- ValidTo = '3000-01-01' marks the current active version
- Multiple rows with the same GCID will appear when the customer changed Email, Phone, or LanguageID - each change creates a new version row in History.Customer
- Only LanguageID, Email, and Phone change-tracking is surfaced (not all 84 CustomerStatic columns)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | VERIFIED | Group Customer ID - the cross-product customer identifier used by modern services and the SQL_UserSyncAPI. Resolved to an internal CID via Customer.CustomerStatic before querying History.Customer. |

**Output columns** (SELECT result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Internal eToro Customer ID. From History.Customer. Resolved from @GCID by the procedure. All returned rows share this CID. |
| 2 | GCID | int | YES | - | VERIFIED | Group Customer ID echoed from History.Customer. May be NULL for very old history rows predating GCID introduction. Confirms which cross-product identity these changes belong to. |
| 3 | LanguageID | int | YES | - | CODE-BACKED | Customer's preferred platform language at the time this version was active. Changes when the customer updates language preferences. Part of the contact profile sync scope. |
| 4 | Email | varchar | YES | - | VERIFIED | Customer's email address during this version's validity window (ValidFrom to ValidTo). PII field. Changes are tracked in History.Customer by the CustomerVersionUpdate trigger on Customer.CustomerStatic. Masked by Dynamic Data Masking for unauthorized DB users. |
| 5 | Phone | varchar | YES | - | VERIFIED | Customer's phone number during this version's validity window. PII field. Changes are tracked by the CustomerVersionUpdate trigger. Masked by Dynamic Data Masking for unauthorized DB users. |
| 6 | ValidFrom | datetime | NO | - | VERIFIED | UTC timestamp when this version became active (i.e., when Customer.CustomerStatic was updated and this version was inserted into History.Customer by the CustomerVersionUpdate trigger). |
| 7 | ValidTo | datetime | NO | - | VERIFIED | UTC timestamp when this version was superseded. ValidTo = '3000-01-01' marks the current active version. Otherwise, this is the timestamp when the next UPDATE to CustomerStatic was committed. The window [ValidFrom, ValidTo) represents the period the customer held these contact values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID -> @CID | Customer.CustomerStatic | Reader (SELECT scalar) | Resolves GCID to internal CID before the main query |
| @CID | History.Customer | Reader (SELECT) | Returns all versioned contact history rows for the resolved CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_UserSyncAPI | EXECUTE permission | Caller | Contact data synchronization service reads change history to detect and replay updates to downstream systems |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUserChangesHistory (procedure)
├── Customer.CustomerStatic (table)
└── History.Customer (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | GCID -> CID resolution step (SELECT @CID = CID WHERE GCID = @GCID) |
| History.Customer | Table | Main SELECT source - returns all versioned rows WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_UserSyncAPI | Service account | Calls this procedure to retrieve contact change history for data synchronization (COINF-1613) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get full contact change history for a customer by GCID
```sql
EXEC Customer.GetUserChangesHistory @GCID = 12345678;
```

### 8.2 Direct equivalent query for debugging
```sql
DECLARE @CID INT;
SELECT @CID = CID FROM Customer.CustomerStatic WITH (NOLOCK) WHERE GCID = 12345678;

SELECT CID, GCID, LanguageID, Email, Phone, ValidFrom, ValidTo
FROM History.Customer WITH (NOLOCK)
WHERE CID = @CID;
```

### 8.3 Find most recent version and previous version for a customer
```sql
DECLARE @CID INT;
SELECT @CID = CID FROM Customer.CustomerStatic WITH (NOLOCK) WHERE GCID = 12345678;

SELECT TOP 2 CID, GCID, LanguageID, Email, Phone, ValidFrom, ValidTo
FROM History.Customer WITH (NOLOCK)
WHERE CID = @CID
ORDER BY ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| COINF-1613 | Jira | Ticket referenced in SP comment - created by Serhii Poltava; this procedure was built for the UserSyncAPI contact data synchronization use case |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 1 Jira (from SP comment) | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetUserChangesHistory | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetUserChangesHistory.sql*
