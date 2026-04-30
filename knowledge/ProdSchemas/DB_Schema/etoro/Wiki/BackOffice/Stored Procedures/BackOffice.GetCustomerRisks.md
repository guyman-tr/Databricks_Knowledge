# BackOffice.GetCustomerRisks

> Retrieves all risk flags recorded against a customer group (GCID), optionally filtering to only active risk event statuses.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns rows from BackOffice.CustomerRisk filtered by GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetCustomerRisks is the primary read procedure for the Risk team to inspect a customer's complete risk profile. Given a GCID (group-level customer identity), it returns every risk alert recorded for that customer, along with its current lifecycle status and audit metadata. This is the foundational query behind the BackOffice risk panel - when a Risk agent opens a customer file, this procedure populates the risk flags section.

The procedure exists to provide a filtered, audit-ready view of risk flags. Rather than exposing the raw CustomerRisk table directly, it enforces a soft filter: by default, only risk event statuses that are still "active" (IsActive=1 in Dictionary.RiskEventStatus, covering On and InProcess states) are returned. This default keeps the BackOffice UI clean by hiding already-resolved (Off) risk flags, while the @IsActive=0 override allows supervisors or auditors to review the full historical risk record including closed flags.

Called directly from the BackOffice application when loading a customer's risk profile. No other stored procedures call this procedure - it is a terminal read operation. The Risk team uses its output to decide whether to investigate further, update the risk status, add remarks, or escalate to compliance.

---

## 2. Business Logic

### 2.1 Active-Only vs Full History Filtering

**What**: The procedure defaults to returning only risk events with an active event status, with a parameter to override and return all statuses including resolved ones.

**Columns/Parameters Involved**: `@IsActive`, `Dictionary.RiskEventStatus.IsActive`

**Rules**:
- Default (`@IsActive = 1`): Returns only risk event statuses where `Dictionary.RiskEventStatus.IsActive = 1`. This covers RiskEventStatusID=1 (On) and RiskEventStatusID=2 (InProcess) - flags actively requiring Risk team attention.
- Override (`@IsActive = 0`): The WHERE clause becomes `(dres.IsActive = 1 OR dres.IsActive = 0)`, which is always true - returns ALL risk flags regardless of event status, including RiskEventStatusID=3 (Off/resolved).
- This pattern (`IsActive = 1 OR IsActive = @IsActive`) was added by Adi on 09/06/2020 to make the historical view opt-in without changing the default behavior for existing callers.

**Diagram**:
```
@IsActive = 1 (default)           @IsActive = 0 (audit/history mode)
        |                                  |
        v                                  v
Returns: On (1) + InProcess (2)    Returns: On + InProcess + Off
  = Active risk queue view          = Full risk history view
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INTEGER | NO | - | CODE-BACKED | Group Customer ID identifying the customer group whose risk flags are requested. Passed directly into the WHERE clause: `WHERE GCID = @GCID`. One call per customer. See BackOffice.CustomerRisk for GCID semantics. |
| 2 | @IsActive | TINYINT | NO | 1 | CODE-BACKED | Controls whether to return only active risk event statuses (default 1) or all statuses including resolved (0). When 1: only On (RiskEventStatusID=1) and InProcess (RiskEventStatusID=2) flags returned. When 0: Off flags (RiskEventStatusID=3) also included - full history mode. Added 09/06/2020 by Adi. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | GCID | int | NO | - | VERIFIED | Group Customer ID - person-level identifier. Returned to confirm the customer context. See BackOffice.CustomerRisk.GCID. |
| R2 | RiskStatusID | int | NO | - | VERIFIED | The specific risk alert type. FK to Dictionary.RiskStatus. 90 defined types covering velocity checks, country/geo conflicts, fraud indicators, document quality, affiliate abuse, and AML/behavioral patterns. Identifies WHICH type of risk was detected. See BackOffice.CustomerRisk.RiskStatusID for the full category breakdown. |
| R3 | Occurred | datetime | YES | - | VERIFIED | Timestamp when the risk event originally occurred. Historical rows may show '1900-01-01' for legacy imports with unknown original timestamps. See BackOffice.CustomerRisk.Occurred. |
| R4 | ModifiedDate | datetime | NO | - | VERIFIED | Timestamp of the last status change or update to this risk flag. Used by the Risk team to order the queue and track SLA compliance. See BackOffice.CustomerRisk.ModifiedDate. |
| R5 | Remark | varchar(255) | YES | - | CODE-BACKED | Free-text note by the Risk agent describing the risk situation, investigation findings, or resolution rationale. NULL for system-generated flags not yet reviewed. See BackOffice.CustomerRisk.Remark. |
| R6 | RiskEventStatusID | int | NO | - | VERIFIED | Current lifecycle status of this risk flag: 1=On (active, requires attention), 2=InProcess (under investigation), 3=Off (resolved). The JOIN to Dictionary.RiskEventStatus on this column enables the @IsActive filter. See BackOffice.CustomerRisk.RiskEventStatusID. |
| R7 | ManagerID | int | YES | - | CODE-BACKED | BackOffice Risk agent who last modified this flag. NULL for system-generated flags not yet reviewed. FK to BackOffice.Manager. See BackOffice.CustomerRisk.ManagerID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BackOffice.CustomerRisk | BackOffice.CustomerRisk | SELECT | Primary source - all risk flags for the given GCID |
| RiskEventStatusID | Dictionary.RiskEventStatus | INNER JOIN | Joined to filter by IsActive - enforces the active-only default |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. This procedure is called from the BackOffice application layer (no stored procedure callers found in the BackOffice schema).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerRisks (procedure)
├── BackOffice.CustomerRisk (table)
└── Dictionary.RiskEventStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerRisk | Table | SELECT - primary data source; filtered by @GCID |
| Dictionary.RiskEventStatus | Table | INNER JOIN on RiskEventStatusID; IsActive column used in WHERE to implement active-only filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application | External | READER - called to load risk panel for a customer in the BackOffice UI |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all active risk flags for a customer (default behavior)
```sql
EXEC BackOffice.GetCustomerRisks
    @GCID = 12345  -- replace with target GCID
```

### 8.2 Get full risk history including resolved flags
```sql
EXEC BackOffice.GetCustomerRisks
    @GCID = 12345,
    @IsActive = 0  -- include Off/resolved statuses
```

### 8.3 Get active risk flags joined to risk type names for readability
```sql
SELECT
    cr.GCID,
    rs.Name AS RiskType,
    res.Name AS EventStatus,
    cr.Occurred,
    cr.ModifiedDate,
    cr.Remark
FROM BackOffice.CustomerRisk cr WITH (NOLOCK)
JOIN Dictionary.RiskStatus rs WITH (NOLOCK) ON rs.RiskStatusID = cr.RiskStatusID
JOIN Dictionary.RiskEventStatus res WITH (NOLOCK) ON res.RiskEventStatusID = cr.RiskEventStatusID
WHERE cr.GCID = 12345
  AND res.IsActive = 1  -- active flags only (equivalent to default proc behavior)
ORDER BY cr.ModifiedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED (no BackOffice repos) | Corrections: 0 applied*
*Object: BackOffice.GetCustomerRisks | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerRisks.sql*
