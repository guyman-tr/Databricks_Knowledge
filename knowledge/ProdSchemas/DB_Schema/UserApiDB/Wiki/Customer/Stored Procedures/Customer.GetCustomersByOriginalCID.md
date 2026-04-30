# Customer.GetCustomersByOriginalCID

> Stub procedure - contains no logic, immediately returns. Retained for backward compatibility; actual functionality is in Customer.CustomersByOriginalCID which delegates to the etoro database.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomersByOriginalCID is a stub procedure that does nothing - it contains only `As Return;`. It exists as a placeholder, likely retained for dependency resolution or backward compatibility.

The actual username-based customer lookup functionality lives in Customer.CustomersByOriginalCID, which delegates to [etoro].[Customer].[GetCustomersByOriginalCID] via the dbo.GetCustomersByOriginalCID synonym.

---

## 2. Business Logic

No business logic. Stub procedure - immediately returns.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters and returns nothing.

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none known) | - | - | Stub retained for compatibility |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none known) | - | Stub - likely no active dependents |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Call the stub (returns immediately)
```sql
EXEC Customer.GetCustomersByOriginalCID
-- Returns nothing - this is a stub
```

### 8.2 Use the actual functional procedure instead
```sql
EXEC Customer.CustomersByOriginalCID @UserName = 'traderx'
-- This is the procedure that actually performs the lookup
```

### 8.3 Check the synonym target
```sql
SELECT * FROM sys.synonyms WITH (NOLOCK) WHERE name = 'GetCustomersByOriginalCID'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomersByOriginalCID | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetCustomersByOriginalCID.sql*
