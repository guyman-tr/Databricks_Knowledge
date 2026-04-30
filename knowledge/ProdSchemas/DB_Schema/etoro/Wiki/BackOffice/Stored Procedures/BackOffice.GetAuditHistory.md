# BackOffice.GetAuditHistory

> Returns the full audit trail of back-office manager actions for a given customer or manager, with action classification, timing, and a flag indicating whether detailed field-level change data is available in DB_Logs.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer) OR @ManagerID (manager) - at least one required; returns one row per audit action ordered descending by time |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAuditHistory` is the primary audit trail query for the BackOffice management interface. It answers: "What has been done to this customer, and by whom?" or "What actions has this manager performed?" It reads from `BackOffice.AuditAction` - the central log of all back-office operations - and enriches each record with the action type name, the manager's full name and login, and optionally the customer CID (resolved from GCID when a direct CID match is absent).

The `HasDetails` column is a key feature: it performs a correlated EXISTS check against `DB_Logs.BackOffice.AuditActionDetail` (a separate audit database) to flag which actions have field-level change records (old value / new value pairs). When HasDetails=1, the caller can fetch granular details via `BackOffice.GetAuditHistoryDetails`.

The procedure requires at least one of @CID or @ManagerID. If both are NULL, it immediately returns without executing (RETURN guard). This is a safety mechanism preventing full table scans of the audit log.

**Common use cases**:
- Compliance review: "Show all actions taken on customer X" (pass @CID)
- Manager review: "Show all actions by manager Y" (pass @ManagerID)
- Dual filter: "Show all actions by manager Y on customer X" (pass both)

The audit system has grown significantly: Dictionary.AuditActionType contains 358 distinct action types covering every major back-office operation (customer updates, document classifications, withdraw approvals, risk flags, bonus grants, etc.).

---

## 2. Business Logic

### 2.1 Dual-Mode Filter: By Customer OR By Manager

**What**: The procedure supports three filter modes with one guard.

**Columns/Parameters Involved**: `@CID`, `@ManagerID`, `BAAC.CID`, `BAAC.GCID`, `BAAC.ManagerID`

**Rules**:
- Both NULL -> RETURN immediately (no rows, no error).
- @CID only -> returns all actions where `BAAC.CID = @CID OR BAAC.GCID = (SELECT GCID FROM Customer.Customer WHERE CID = @CID)`. The dual condition handles cases where the AuditAction was logged by GCID rather than CID.
- @ManagerID only -> returns all actions by that manager regardless of customer.
- Both provided -> intersection: actions by that manager on that customer.

### 2.2 GCID Resolution for CID-Filtered Queries

**What**: Some AuditAction records store GCID instead of CID; the WHERE clause handles both cases.

**Columns/Parameters Involved**: `BAAC.CID`, `BAAC.GCID`, `Customer.Customer.GCID`, `Customer.Customer.CID`

**Rules**:
- Primary match: `BAAC.CID = @CID` (direct CID match - majority of rows).
- Secondary match: `BAAC.GCID = (SELECT GCID FROM Customer.Customer WHERE CID = @CID)` - subquery resolves @CID to GCID for records that were logged by GCID (e.g., cross-entity operations).
- The subquery runs once per query execution (not per row) given optimizer behavior with scalar subqueries.

### 2.3 Resolved CID in Output (COALESCE)

**What**: The output CID is derived from whichever source is non-NULL.

**Columns/Parameters Involved**: `BAAC.CID`, `CUST.CID` (from LEFT JOIN Customer.Customer on GCID)

**Rules**:
- `COALESCE(BAAC.CID, CUST.CID)` - if the AuditAction stored a CID directly, use it; otherwise resolve from the LEFT JOIN on GCID.
- If both are NULL (manager-only action not tied to a customer), [CID] is NULL.

### 2.4 HasDetails: Cross-Database Existence Check

**What**: Each row is flagged to indicate whether granular field-level changes exist in the DB_Logs database.

**Columns/Parameters Involved**: `HasDetails`, `DB_Logs.BackOffice.AuditActionDetail.AuditActionId`

**Rules**:
- `IIF(EXISTS (SELECT 1 FROM DB_Logs.BackOffice.AuditActionDetail AAD WHERE AAD.AuditActionId = BAAC.ActionID), 1, 0) AS HasDetails`
- HasDetails=1: Field-level old/new values available via `BackOffice.GetAuditHistoryDetails @ActionID`.
- HasDetails=0: Only the top-level action record exists; no field-level breakdown.
- DB_Logs is a separate database on the same server - no linked server required.
- NOT all action types write detail records. Only operations that modify specific fields (e.g., CustomerUpdate, StatusChange, DocumentClassification) populate AuditActionDetail.

### 2.5 Action Type Classification (358 Types)

**What**: Each AuditAction has an AuditActionTypeID that classifies the operation performed.

**Columns/Parameters Involved**: `DAAT.AuditActionTypeName`, `BAAC.AuditActionTypeID`

**Rules**:
- Dictionary.AuditActionType contains 358 values (as of 2026-03-17).
- Selected values spanning the range:
  - 1=GetCustomerDetails, 2=UpdateCustomerStatus, 3=UpdateAccountStatus, 4=GetActivityList
  - 10=UpdateAMLComment, 11=UpdateRiskComment, 12=AddDocumentClassification
  - 20=CashoutApprove, 21=CashoutReject, 22=CashoutCancel
  - 30=BonusAdd, 31=CompensationAdd
  - 50=MirrorClose, 51=MirrorReopen
  - 100=LoginAttempt, 101=LoginSuccess, 102=LoginFailed
  - 200=PositionManualClose, 201=PositionManualSLChange
  - 225=GetAmlAndRiskComments (read-only action - BackOffice.GetAmlAndRiskComments)
  - 300+=Compliance/KYC actions
  - 358=most recent action type (most recent addition)
- AuditActionParameters (JSON or pipe-delimited string) provides context for each action.

### 2.6 Result Ordering

**What**: Results are always newest-first for chronological audit review.

**Columns/Parameters Involved**: `BAAC.ActionTime`

**Rules**:
- ORDER BY BAAC.ActionTime DESC - most recent action at top.
- ActionTime is a DATETIME stored in UTC.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | NULL | CODE-BACKED | Customer Identifier. When provided, filters audit actions to those targeting this customer (by CID or resolved GCID). NULL=no customer filter. |
| 2 | @ManagerID | INT | YES | NULL | CODE-BACKED | Manager Identifier. When provided, filters audit actions to those performed by this manager. NULL=no manager filter. At least one of @CID/@ManagerID must be non-NULL or the procedure returns immediately. |
| 3 | Action ID | INT | NO | - | CODE-BACKED | Primary key of the BackOffice.AuditAction record (BAAC.ActionID). Unique identifier for each audit event. Used to fetch field-level details via GetAuditHistoryDetails. |
| 4 | Manager Name | NVARCHAR | YES | - | CODE-BACKED | Full name of the back-office manager who performed the action (FirstName + ' ' + LastName from BackOffice.Manager). NULL if manager record not found (unlikely given INNER JOIN). |
| 5 | Manager Login | VARCHAR | YES | - | CODE-BACKED | Username/login of the manager who performed the action (BackOffice.Manager.Login). Used for display and audit export. |
| 6 | Action | NVARCHAR | NO | - | CODE-BACKED | Human-readable action type name from Dictionary.AuditActionType.AuditActionTypeName. 358 possible values mapping to specific back-office operations (e.g., "UpdateAMLComment", "CashoutApprove", "AddDocumentClassification"). |
| 7 | Action Time | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the action was performed. Results ordered by this column DESC (newest first). |
| 8 | CID | INT | YES | - | CODE-BACKED | Customer ID associated with the action. COALESCE(BAAC.CID, CUST.CID) - prefers directly stored CID, falls back to GCID-resolved CID via LEFT JOIN Customer.Customer. NULL for manager-only actions not tied to a customer. |
| 9 | AuditActionParameters | NVARCHAR | YES | - | CODE-BACKED | Context parameters for the action (JSON blob or pipe-delimited string depending on action type). Content varies by AuditActionTypeID - may contain amounts, status codes, document IDs, etc. |
| 10 | HasDetails | BIT | NO | - | CODE-BACKED | Whether field-level change details exist in DB_Logs.BackOffice.AuditActionDetail for this action. 1=details available (call GetAuditHistoryDetails @ActionID); 0=top-level record only. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Action ID / @CID | BackOffice.AuditAction | Primary source | All audit action records filtered by CID/ManagerID. |
| AuditActionTypeID | Dictionary.AuditActionType | Lookup (INNER JOIN) | Resolves action type ID to human-readable name. |
| ManagerID | BackOffice.Manager | Lookup (INNER JOIN) | Resolves manager ID to full name and login. |
| GCID | Customer.Customer | Lookup (LEFT JOIN) | Resolves GCID to CID for output and GCID-based WHERE filter. |
| ActionID | DB_Logs.BackOffice.AuditActionDetail | Existence check (correlated EXISTS) | Cross-database check for field-level change detail availability. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by BOUser, BOSegSpecial, BOFacade service accounts. `BackOffice.GetAuditHistoryDetails` is the companion procedure for HasDetails=1 rows.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAuditHistory (procedure)
├── BackOffice.AuditAction (table) [via BackOffice.AuditAction synonym]
├── Dictionary.AuditActionType (table) [cross-schema]
├── BackOffice.Manager (table)
├── Customer.Customer (table) [cross-schema, LEFT JOIN + scalar subquery]
└── DB_Logs.BackOffice.AuditActionDetail (table) [cross-database EXISTS check]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AuditAction | Table (via synonym) | Main data source - all audit action records filtered by CID/ManagerID/GCID. |
| Dictionary.AuditActionType | Table (cross-schema) | INNER JOIN on AuditActionTypeID for action name. |
| BackOffice.Manager | Table | INNER JOIN on ManagerID for manager name and login. |
| Customer.Customer | Table (cross-schema) | LEFT JOIN on GCID for CID resolution; scalar subquery for GCID lookup in WHERE clause. |
| DB_Logs.BackOffice.AuditActionDetail | Table (cross-database) | Correlated EXISTS for HasDetails flag. Same server, separate database. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by BOUser, BOSegSpecial, BOFacade. Companion: GetAuditHistoryDetails for HasDetails=1 rows. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. BackOffice.AuditAction should have indexes on (CID), (GCID), (ManagerID), and (ActionTime) for performance - large table (all historical back-office actions).

### 7.2 Constraints

No SET NOCOUNT ON. NOLOCK on all tables. NULL guard: both parameters NULL -> RETURN (no output). INNER JOIN to BackOffice.Manager and Dictionary.AuditActionType means actions logged with an invalid ManagerID or AuditActionTypeID would be silently excluded. Cross-database EXISTS to DB_Logs adds per-row overhead - acceptable for the paginated display volumes expected.

---

## 8. Sample Queries

### 8.1 Get full audit history for a customer
```sql
EXEC BackOffice.GetAuditHistory @CID = 10848122;
```

### 8.2 Get all actions by a specific manager
```sql
EXEC BackOffice.GetAuditHistory @ManagerID = 4512;
```

### 8.3 Get actions by manager on a specific customer
```sql
EXEC BackOffice.GetAuditHistory @CID = 10848122, @ManagerID = 4512;
```

### 8.4 Fetch field-level details for an action with HasDetails=1
```sql
-- First get the audit history
EXEC BackOffice.GetAuditHistory @CID = 10848122;

-- For rows where HasDetails=1, fetch detail:
EXEC BackOffice.GetAuditHistoryDetails @ActionID = 99887766;
```

### 8.5 Inline equivalent with action type filter
```sql
SELECT BAAC.ActionID, BMAN.Login, DAAT.AuditActionTypeName, BAAC.ActionTime,
       COALESCE(BAAC.CID, CUST.CID) AS CID, BAAC.AuditActionParameters
FROM BackOffice.AuditAction BAAC WITH (NOLOCK)
JOIN Dictionary.AuditActionType DAAT WITH (NOLOCK) ON DAAT.AuditActionTypeID = BAAC.AuditActionTypeID
JOIN BackOffice.Manager BMAN WITH (NOLOCK) ON BMAN.ManagerID = BAAC.ManagerID
LEFT JOIN Customer.Customer CUST WITH (NOLOCK) ON CUST.GCID = BAAC.GCID
WHERE BAAC.CID = 10848122
ORDER BY BAAC.ActionTime DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Audit tables](https://etoro-confluence.atlassian.net/wiki/spaces/DROD/pages/audit-tables) | Confluence (DROD space) | Documents the BackOffice audit table structure, AuditAction + AuditActionDetail split, and DB_Logs cross-database design. Describes HasDetails pattern. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAuditHistory | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetAuditHistory.sql*
