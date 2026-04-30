# BackOffice.CustomerEditComment

> Updates the Comments field on Customer.Customer (the main customer table in the Customer schema) for a specific customer, used by BackOffice for internal account notes.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure allows BackOffice agents to write or update the general Comments field on `Customer.Customer`. Unlike AMLComment (BackOffice.Customer) or RiskComment (BackOffice.Customer), the Comments field in Customer.Customer is a general-purpose note field accessible to customer-facing contexts as well as BackOffice.

The procedure targets `Customer.Customer` (the cross-schema Customer table) rather than `BackOffice.Customer`. This means the comment is written to the core customer record used by account management and support teams, not just the BackOffice-specific profile.

The procedure contains commented-out Service Broker code (to `svcDispatcher`) that previously propagated comment changes to a downstream service - this integration has been removed. The error message text in RAISERROR references 'Customer.DemographyEdit' - indicating this procedure may have been refactored from or shares origin with a Customer schema procedure.

---

## 2. Business Logic

### 2.1 Comment Update with Error Handling

**What**: Updates Customer.Customer.Comments for the specified CID.

**Columns/Parameters Involved**: `@CID`, `@Comments`, `Customer.Customer.Comments`

**Rules**:
- UPDATE Customer.Customer SET Comments=@Comments WHERE CID=@CID
- @@ERROR checked after UPDATE: if non-zero -> RAISERROR(60000, 16, 1, 'Customer.DemographyEdit', @LocalError) and RETURN 60000
- On success: RETURN 0
- Note: targets Customer.Customer (cross-schema), not BackOffice.Customer

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. The customer whose Comments field is being updated. PK of Customer.Customer. |
| 2 | @Comments | VARCHAR(1024) | NO | - | CODE-BACKED | The new comment text to store on the customer record. General-purpose internal note. Max 1024 characters. Replaces existing comment entirely. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN | INT | 0 on success; 60000 if the UPDATE fails (@@ERROR != 0 after UPDATE). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | MODIFIER | Updates Comments WHERE CID=@CID (cross-schema) |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called from BackOffice account management UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerEditComment (procedure)
+-- Customer.Customer (table) [UPDATE target - Comments, cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | UPDATE: sets Comments=@Comments WHERE CID=@CID (cross-schema) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice account management UI | External | Calls this to add or update general account notes on a customer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Cross-schema target | Design | Targets Customer.Customer (not BackOffice.Customer) - comment is stored on the core customer record visible across all schemas |
| Error code 60000 | Application | RAISERROR(60000) on UPDATE failure; error message references 'Customer.DemographyEdit' (historical procedure name) |
| Full overwrite | Application | @Comments fully replaces existing Comments; no append logic |
| Removed Service Broker | Historical | Commented-out block previously notified svcDispatcher of comment changes |

---

## 8. Sample Queries

### 8.1 Add a note to a customer account

```sql
DECLARE @Result INT
EXEC @Result = BackOffice.CustomerEditComment
    @CID = 12345,
    @Comments = 'Customer called 2026-03-17 - interested in higher deposit tier. Follow up in 2 weeks.'
SELECT @Result AS Result  -- 0 = success
```

### 8.2 Clear a customer comment

```sql
EXEC BackOffice.CustomerEditComment @CID = 12345, @Comments = ''
```

### 8.3 View the current comment

```sql
SELECT CID, Comments FROM Customer.Customer WITH (NOLOCK) WHERE CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerEditComment | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerEditComment.sql*
