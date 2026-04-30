# BackOffice.CustomerEditRiskComment

> Updates the RiskComment field on BackOffice.Customer for a specific customer, used by BackOffice risk analysts to record trading risk observations and assessments.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure allows BackOffice risk analysts to write or update the RiskComment field on a customer's BackOffice.Customer record. RiskComment is a dedicated free-text field for trading risk observations - distinct from AMLComment (compliance/AML notes) and the general Comments field in Customer.Customer.

Risk comments typically capture findings from risk reviews: unusual trading patterns, high-frequency trading behavior, leverage usage concerns, potential manipulation flags, or notes from the risk management team. The separation from AMLComment reflects the organizational division between AML compliance teams and trading risk management teams.

Created by Geri Reshef on 2018-04-09 (ticket 51005, OPS0435 "DB changes for OPS0435 - Comments for economic profile report") - the same ticket that created CustomerEditAmlComment, indicating both fields were added together as part of an economic profile reporting initiative.

---

## 2. Business Logic

### 2.1 Risk Comment Update

**What**: Overwrites the RiskComment for the specified customer.

**Columns/Parameters Involved**: `@CID`, `@Comments`, `BackOffice.Customer.RiskComment`

**Rules**:
- UPDATE BackOffice.Customer SET RiskComment=@Comments WHERE CID=@CID
- @Comments replaces the existing RiskComment entirely
- Pass NULL or empty string to clear an existing risk comment
- Returns 0 always (hardcoded RETURN 0, no error handling)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. The customer whose RiskComment is being updated. PK of BackOffice.Customer. |
| 2 | @Comments | VARCHAR(1024) | NO | - | CODE-BACKED | The trading risk observation text. Used to record unusual trading patterns, risk flags, leverage concerns, or risk team assessments. Max 1024 characters. Replaces existing RiskComment entirely. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN | INT | Always 0 (hardcoded RETURN 0). No error handling; SQL errors propagate as unhandled exceptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | MODIFIER | Updates RiskComment WHERE CID=@CID |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called from BackOffice risk management UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerEditRiskComment (procedure)
+-- BackOffice.Customer (table) [UPDATE target - RiskComment]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: sets RiskComment=@Comments WHERE CID=@CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice risk management UI | External | Calls this to record or update trading risk observations on a customer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Always returns 0 | Design | RETURN 0 hardcoded - no error check; SQL errors propagate as exceptions |
| Full overwrite | Application | @Comments fully replaces RiskComment; callers must read existing comment if append behavior is needed |
| Separate from AMLComment | Design | RiskComment is distinct from AMLComment (same procedure signature; different column; different organizational use) |

---

## 8. Sample Queries

### 8.1 Add a risk observation to a customer

```sql
EXEC BackOffice.CustomerEditRiskComment
    @CID = 12345,
    @Comments = 'Flagged for high-frequency CFD trading with max leverage. Pattern review scheduled 2026-04-01.'
```

### 8.2 Clear a risk comment after review is resolved

```sql
EXEC BackOffice.CustomerEditRiskComment @CID = 12345, @Comments = NULL
```

### 8.3 View all three comment fields for a customer

```sql
SELECT
    BC.CID,
    BC.AMLComment,
    BC.RiskComment,
    CC.Comments AS GeneralComments
FROM BackOffice.Customer BC WITH (NOLOCK)
JOIN Customer.Customer CC WITH (NOLOCK) ON BC.CID = CC.CID
WHERE BC.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerEditRiskComment | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerEditRiskComment.sql*
