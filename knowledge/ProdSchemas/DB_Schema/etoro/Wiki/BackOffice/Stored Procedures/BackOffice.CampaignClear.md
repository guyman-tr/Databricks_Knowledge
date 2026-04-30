# BackOffice.CampaignClear

> Removes campaign assignment from all customers currently linked to a campaign by setting Customer.Customer.CampaignID = NULL, returning the SQL error code (0 = success).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure dissociates all customers from a specific campaign by nullifying their CampaignID reference in Customer.Customer. It is used when a campaign needs to be deactivated and its customer assignments cleared - for example, before CampaignDelete can succeed (CampaignDelete blocks deletion if any customers still reference the campaign via CampaignID).

CampaignClear is a prerequisite for campaign deletion when customers have been assigned to the campaign. It only clears the forward-reference from Customer.Customer to the campaign - it does NOT delete the campaign itself, does NOT reverse any bonuses already issued to customers, and does NOT affect History.Credit records (which is a separate guard for CampaignDelete).

---

## 2. Business Logic

### 2.1 Customer Campaign Assignment Removal

**What**: Bulk-nullifies CampaignID for all customers assigned to the specified campaign.

**Columns/Parameters Involved**: `@CampaignID`, `Customer.Customer.CampaignID`

**Rules**:
- UPDATE Customer.Customer SET CampaignID = NULL WHERE CampaignID = @CampaignID
- No existence check on @CampaignID - if no customers are assigned, UPDATE affects 0 rows (silent no-op)
- Affects all customers with CampaignID = @CampaignID in one set-based operation
- Returns @@ERROR (0=success, non-zero=SQL error)
- Does NOT cascade: bonuses already issued (History.Credit), audit records, or any other campaign-referenced data is not affected

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignID | INTEGER | NO | - | VERIFIED | The campaign whose customer assignments should be cleared. All Customer.Customer rows with CampaignID = @CampaignID will have CampaignID set to NULL. |

**Return Value:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | RETURN | INT | NO | - | CODE-BACKED | @@ERROR after UPDATE - 0=success, non-zero=SQL error. Returns 0 even if no customers were assigned (silent no-op). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CampaignID | Customer.Customer | MODIFIER | Bulk-nullifies CampaignID WHERE CampaignID = @CampaignID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application layer | - | Caller | Called before CampaignDelete if customers are still assigned to the campaign |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CampaignClear (procedure)
+-- Customer.Customer (table) [UPDATE target - nullifies CampaignID for matching customers]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table (cross-schema) | UPDATE target - CampaignID set to NULL for all customers with matching CampaignID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Called as prerequisite to CampaignDelete when customers are assigned to the campaign |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| Silent no-op | Design | No customers assigned = 0 rows updated, no error |
| No cascade | Design | Only Customer.Customer.CampaignID is cleared; bonuses, credits, and history records are NOT affected |
| CampaignDelete dependency | Design | CampaignDelete guard checks Customer.Customer; call CampaignClear first if customers are assigned |
| RETURN @@ERROR | Design | Returns SQL error code; 0=success |

---

## 8. Sample Queries

### 8.1 Clear all customer assignments before deleting a campaign

```sql
-- Step 1: Check how many customers are assigned
SELECT COUNT(*) AS AssignedCustomers
FROM Customer.Customer WITH (NOLOCK)
WHERE CampaignID = 5001

-- Step 2: Clear assignments
DECLARE @rc INT
EXEC @rc = BackOffice.CampaignClear @CampaignID = 5001

-- Step 3: Now CampaignDelete can proceed (if other guards also clear)
-- EXEC BackOffice.CampaignDelete @CampaignID = 5001
```

### 8.2 Verify all customers were cleared

```sql
SELECT COUNT(*) AS RemainingAssigned
FROM Customer.Customer WITH (NOLOCK)
WHERE CampaignID = 5001
-- Should return 0 after CampaignClear
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CampaignClear | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CampaignClear.sql*
