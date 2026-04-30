# BackOffice.CustomerSetAffiliateManager

> Assigns a UserGroup as the affiliate manager for a customer by updating AffiliateManagerID on BackOffice.Customer. Validates the UserGroupID against Dictionary.UserGroup before updating.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure assigns an affiliate manager (represented as a UserGroup) to a customer by setting `BackOffice.Customer.AffiliateManagerID`. The affiliate manager association determines which affiliate partner is credited for this customer's trading activity - used for affiliate commission calculations and relationship management.

`AffiliateManagerID` stores a `UserGroupID` value from `Dictionary.UserGroup`. Affiliate managers are organized into user groups, and a customer can be attributed to one affiliate manager group. This is used in the affiliate/IB (Introducing Broker) business model where external partners earn commissions for bringing in customers.

The procedure validates that the supplied @UserGroupID exists in `Dictionary.UserGroup` before applying the update. No CID existence check is performed (silent no-op if CID not found).

Note: Despite the parameter name `@UserGroupID`, it maps to the column `AffiliateManagerID`. This naming reflects the design where affiliate managers are user groups, not individual users.

---

## 2. Business Logic

### 2.1 UserGroup Validation then Update

**What**: Validates the UserGroupID exists, then sets AffiliateManagerID.

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM Dictionary.UserGroup WITH(NOLOCK) WHERE UserGroupID=@UserGroupID): RAISERROR(60000, 'not found user group'), RETURN 60000
- ELSE: UPDATE BackOffice.Customer SET AffiliateManagerID=@UserGroupID WHERE CID=@CID
- No @@ROWCOUNT check: silent no-op if CID not found
- RETURN 0 on success

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. No existence check - silent no-op if not found in BackOffice.Customer. |
| 2 | @UserGroupID | INT | NO | - | CODE-BACKED | User group ID representing the affiliate manager to assign. Must exist in Dictionary.UserGroup (validation check). Written to BackOffice.Customer.AffiliateManagerID. |

**Return Values:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN 0 | INT | Success: UserGroupID validated and update applied (or CID silently not found). |
| 4 | RETURN 60000 | INT | Failure: @UserGroupID not found in Dictionary.UserGroup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserGroupID | Dictionary.UserGroup | SELECT (NOLOCK, validation) | Validates user group exists before assigning |
| @CID | BackOffice.Customer | UPDATE | Sets AffiliateManagerID=@UserGroupID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice affiliate management | External | Direct call | Assigns an affiliate manager to a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetAffiliateManager (procedure)
|- Dictionary.UserGroup (table) [SELECT NOLOCK: validation]
|- BackOffice.Customer (table) [UPDATE: AffiliateManagerID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.UserGroup | Table | Validation: @UserGroupID must exist |
| BackOffice.Customer | Table | UPDATE: AffiliateManagerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate management workflows | External | Assign customers to affiliate manager groups |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UserGroup validation | Application | @UserGroupID must exist in Dictionary.UserGroup |
| No CID validation | Design | Silent no-op if CID not found |
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| Parameter/column naming | Code quality | @UserGroupID maps to AffiliateManagerID column - affiliate managers are stored as UserGroup IDs |

---

## 8. Sample Queries

### 8.1 Assign an affiliate manager to a customer

```sql
EXEC BackOffice.CustomerSetAffiliateManager
    @CID = 12345,
    @UserGroupID = 50;
-- RETURN 0 = success
-- RETURN 60000 = UserGroupID not found in Dictionary.UserGroup
```

### 8.2 Check current affiliate manager assignment

```sql
SELECT bc.CID, bc.AffiliateManagerID, ug.Name AS AffiliateManagerGroupName
FROM BackOffice.Customer bc WITH (NOLOCK)
LEFT JOIN Dictionary.UserGroup ug WITH (NOLOCK) ON ug.UserGroupID = bc.AffiliateManagerID
WHERE bc.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerSetAffiliateManager | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetAffiliateManager.sql*
