# BackOffice.CustomerSetManager

> Assigns or reassigns a sales manager to a customer account, preserving the previous manager in PreviousManagerID for audit and rollback purposes.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - internal customer identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerSetManager is the canonical procedure for assigning a sales manager to a customer. In eToro's BackOffice model, each customer account can be assigned to a specific sales agent (ManagerID in BackOffice.Customer) who is responsible for that customer's relationship and conversion. This procedure performs the assignment atomically while preserving the prior manager in `PreviousManagerID`, creating a one-step rollback trail.

The procedure exists to ensure manager changes are applied safely: it only executes the UPDATE when the new ManagerID genuinely differs from the current one (including NULL-aware comparisons), avoiding spurious history records. The now-unused `@CalledFromDynamics` parameter is a backward-compatibility remnant from a 2012 change when Service Broker integration was removed.

Data flows from CRM systems and BackOffice tooling through this procedure into `BackOffice.Customer`. It is also invoked by `BackOffice.CustomerSetManagerFromDynamics`, which wraps this procedure to handle Dynamics CRM-originated manager assignments using GCID-based resolution.

---

## 2. Business Logic

### 2.1 Change-Guard Update with NULL-Safe Comparison

**What**: The UPDATE only executes if the new ManagerID is genuinely different from the current one, with correct handling of NULL-to-value, value-to-NULL, and value-to-value transitions.

**Columns/Parameters Involved**: `@ManagerID`, `BackOffice.Customer.ManagerID`, `BackOffice.Customer.PreviousManagerID`

**Rules**:
- UPDATE fires when any of these three conditions is true:
  - `@ManagerID IS NULL AND ManagerID IS NOT NULL` - clearing a manager (unassignment)
  - `ManagerID IS NULL AND @ManagerID IS NOT NULL` - assigning where none existed
  - `@ManagerID <> ManagerID` - changing from one manager to another
- UPDATE does NOT fire if `@ManagerID = ManagerID` (including both NULL) - idempotent, no phantom history records.
- When the UPDATE fires: `PreviousManagerID = ManagerID` (preserve prior), then `ManagerID = @ManagerID` (apply new).

**Diagram**:
```
Before: ManagerID = 101, PreviousManagerID = 55
EXEC CustomerSetManager @CID=X, @ManagerID=202
After:  ManagerID = 202, PreviousManagerID = 101

Before: ManagerID = 101, PreviousManagerID = 55
EXEC CustomerSetManager @CID=X, @ManagerID=101  <- same value
After:  ManagerID = 101, PreviousManagerID = 55  <- no change, guard blocked it
```

### 2.2 Legacy CalledFromDynamics Parameter

**What**: A backward-compatibility parameter accepted but not used by the procedure body.

**Columns/Parameters Involved**: `@CalledFromDynamics`

**Rules**:
- Accepted with default `0` to avoid breaking existing callers that pass it.
- As of 2012 (per inline comment), the Service Broker Customer Dynamics XML notification was removed from this procedure. The parameter was retained for compatibility.
- No conditional logic depends on `@CalledFromDynamics` - it is ignored entirely.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Internal Customer ID. Used directly in the WHERE clause to target the customer's row in BackOffice.Customer. |
| 2 | @ManagerID | INTEGER | YES | - | CODE-BACKED | The sales manager (ManagerID) to assign to this customer. Can be NULL to unassign. Mapped to BackOffice.Customer.ManagerID. FK to BackOffice.Manager. |
| 3 | @CalledFromDynamics | BIT | YES | 0 | CODE-BACKED | Legacy parameter, retained for backward compatibility. Was used to control Service Broker XML notification to Dynamics CRM before that integration was removed in December 2012. Currently ignored by the procedure body. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Modifier | UPDATE target - changes ManagerID and PreviousManagerID for this customer's row. |
| @ManagerID | BackOffice.Manager | Implicit FK | ManagerID value must be a valid ManagerID in BackOffice.Manager (enforced at application layer, not by DB FK constraint). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerSetManagerFromDynamics | EXEC call | Caller | Wraps this procedure - resolves GCID to CID then calls CustomerSetManager for Dynamics CRM-originated manager assignments. |
| Application (CRM/BackOffice service) | EXEC | Caller | Called directly from CRM tooling (CRM_TS permissions grant) for manual manager assignments. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetManager (procedure)
└── BackOffice.Customer (table) - UPDATE target for ManagerID/PreviousManagerID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE - sets ManagerID = @ManagerID, PreviousManagerID = prior ManagerID, WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerSetManagerFromDynamics | Procedure | EXEC call - delegates the actual update after resolving GCID to CID |
| Application (CRM/BackOffice) | External | Direct EXEC for manual sales agent assignment |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Change-guard WHERE condition | Logic | Update only fires when ManagerID is genuinely changing (NULL-safe 3-way comparison). Prevents phantom audit records on no-op calls. |
| @@ERROR return | Convention | Returns SQL error code of the UPDATE. 0 = success. Backward-compatible per inline comment. |

---

## 8. Sample Queries

### 8.1 Assign a sales manager to a customer
```sql
EXEC BackOffice.CustomerSetManager @CID = 12345678, @ManagerID = 42
```

### 8.2 Unassign a manager (clear assignment)
```sql
EXEC BackOffice.CustomerSetManager @CID = 12345678, @ManagerID = NULL
```

### 8.3 Check current and previous manager assignment for a customer
```sql
SELECT
    bc.CID,
    cs.GCID,
    cs.UserName,
    bc.ManagerID,
    bc.PreviousManagerID,
    m.FirstName + ' ' + m.LastName AS CurrentManager
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = bc.CID
LEFT JOIN BackOffice.Manager m WITH (NOLOCK) ON m.ManagerID = bc.ManagerID
WHERE bc.CID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (CustomerSetManagerFromDynamics) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerSetManager | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetManager.sql*
