# Dictionary.ExecutionErrorCategories

## 1. Business Meaning

### What It Is
A lookup table classifying trade execution errors into broad categories, used by the hedge execution error mapping system to categorize failures during order execution against liquidity providers.

### Why It Exists
When hedge orders fail during execution, the error needs to be classified for operational analysis, alerting, and automated retry logic. This table provides the high-level error categories that group specific error codes into actionable buckets: technical failures vs. validation rejects vs. provider issues.

### How It's Used
Referenced by `Hedge.ExecutionErrorMapping.ErrorCategoryID` which maps specific provider error codes to these categories. The mapping allows the system to determine appropriate retry behavior and escalation paths based on error category rather than individual error codes.

---

## 2. Business Logic

### Error Category Hierarchy

**System/Technical Failures:**
| ID | Category | Meaning |
|----|----------|---------|
| 0 | Technical Failure | Infrastructure/system-level error (network, timeout, internal bug) |

**Validation/Business Rejections:**
| ID | Category | Meaning |
|----|----------|---------|
| 1 | Order Validation | Order rejected by internal validation rules (invalid size, price, params) |
| 6 | Provider Business Validation | Provider rejected order based on their business rules |

**Market/Provider Issues:**
| ID | Category | Meaning |
|----|----------|---------|
| 2 | Market Reject | Exchange/market rejected the order (market closed, halted, etc.) |
| 3 | Provider Reject | Liquidity provider explicitly rejected the order |
| 4 | Provider Not Connected | Cannot reach the liquidity provider |
| 5 | Provider Unknown | Provider returned an unrecognized/unmapped error |

### Retry Logic Implications
- **Technical Failure (0)** / **Provider Not Connected (4)** → typically retryable (transient issues)
- **Order Validation (1)** / **Market Reject (2)** → not retryable (permanent rejection)
- **Provider Reject (3)** / **Business Validation (6)** → may need manual review
- **Provider Unknown (5)** → requires investigation and error mapping update

> **Note**: "Provider Unkown" (ID 5) contains a typo in the data (should be "Unknown").

---

## 3. Data Overview

| ErrorCategoryID | ErrorCategoryName |
|----------------|-------------------|
| 0 | Technical Failure |
| 1 | Order Validation |
| 2 | Market Reject |
| 3 | Provider Reject |
| 4 | Provider Not Connected |
| 5 | Provider Unkown |
| 6 | Provider Business Validation |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **ErrorCategoryID** | `smallint` | NO | Primary key. Error category identifier (0-6). | `MCP` |
| **ErrorCategoryName** | `varchar(50)` | YES | Category label. Nullable but all current rows populated. | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | Relationship |
|-------|--------|-------------|
| Hedge.ExecutionErrorMapping | ErrorCategoryID | Implicit FK — maps specific error codes to categories |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `Hedge.ExecutionErrorMapping` — maps provider-specific error codes to these categories

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `ErrorCategoryID` (clustered, PK_executionErrorCategories, FILLFACTOR=100) |
| **Filegroup** | DICTIONARY |
| **Row Count** | 7 |
| **Identity** | No |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all execution error categories
SELECT  ErrorCategoryID,
        ErrorCategoryName
FROM    Dictionary.ExecutionErrorCategories WITH (NOLOCK)
ORDER BY ErrorCategoryID;

-- Count mapped errors per category
SELECT  ec.ErrorCategoryName  AS Category,
        COUNT(*)              AS MappedErrors
FROM    Hedge.ExecutionErrorMapping eem WITH (NOLOCK)
JOIN    Dictionary.ExecutionErrorCategories ec WITH (NOLOCK)
        ON eem.ErrorCategoryID = ec.ErrorCategoryID
GROUP BY ec.ErrorCategoryName
ORDER BY MappedErrors DESC;

-- Find retryable error categories (technical/connectivity)
SELECT  ErrorCategoryID,
        ErrorCategoryName
FROM    Dictionary.ExecutionErrorCategories WITH (NOLOCK)
WHERE   ErrorCategoryID IN (0, 4);
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
