# Dictionary.StockError

## 1. Business Meaning

**What it is**: A lookup table defining error codes for stock/REAL asset order failures. Each entry describes a specific failure condition that prevented a stock order from executing successfully.

**Why it exists**: When a REAL (physical stock) order fails — due to insufficient funds, mirror relationship issues, or order cancellation — the system records a specific error code in `Stocks.OrderFail`. This table provides the human-readable error names for those failure codes, enabling support and operations teams to diagnose order failures.

**How it works**: The `Stocks.OrderFail` table stores failed stock orders with a `StockErrorID` from this table. Support tools and reports join this table to display the failure reason. Error codes 0-3 relate to CopyTrading/mirror operations (where the copied trade failed due to the copier's account conditions), while codes 6-7 relate to order cancellation scenarios.

---

## 2. Business Logic

### Stock Error Codes
| ID | Name | Meaning |
|----|------|---------|
| 0 | Unknown | Unclassified stock order failure |
| 1 | Mirror Not Found | CopyTrading mirror relationship not found — copied trade cannot execute |
| 2 | Insufficient Funds in Mirror | Copier's allocated CopyTrading funds insufficient for this trade |
| 3 | Insufficient Funds from Ancestor | Parent/guru account has insufficient funds (upstream issue) |
| 6 | Order Cancellation | Stock order was explicitly cancelled before execution |
| 7 | Parent Order Cancellation | Parent (guru) order was cancelled, causing copied order to fail |

### Gap Analysis
IDs 4-5 are unused — likely reserved or deprecated error types.

### CopyTrading Error Pattern
Errors 1-3 and 7 all relate to the CopyTrading flow where a guru's trade is being replicated to a copier. Failures can occur at the mirror lookup, copier funds, guru funds, or guru cancellation stages.

---

## 3. Data Overview

| StockErrorID | Name | Business Meaning |
|-------------|------|------------------|
| 0 | Unknown | Unclassified failure |
| 1 | Mirror Not Found | CopyTrading mirror not found |
| 2 | Insufficient Funds in Mirror | Copier funds insufficient |
| 3 | Insufficient Funds from Ancestor | Guru funds insufficient |
| 6 | Order Cancellation | Order explicitly cancelled |
| 7 | Parent Order Cancellation | Guru order cancelled |

*6 rows — stock order failure classifications*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **StockErrorID** | int | NOT NULL | — | Primary key. Error code: 0=Unknown, 1=Mirror Not Found, 2=Insufficient Mirror Funds, 3=Insufficient Ancestor Funds, 6=Cancelled, 7=Parent Cancelled. | `MCP` |
| **Name** | char(50) | NOT NULL | — | Fixed-width error name. Padded with spaces due to char(50) type. Describes the specific failure condition. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| Stocks.OrderFail | StockErrorID | Implicit FK | Failed stock orders reference specific error codes |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `Stocks.OrderFail` — stock order failure records

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `StockErrorID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Row Count | 6 |

---

## 8. Sample Queries

```sql
-- Get all stock error codes
SELECT  StockErrorID, RTRIM(Name) AS Name
FROM    Dictionary.StockError WITH (NOLOCK)
ORDER BY StockErrorID;

-- Stock order failures by error type
SELECT  RTRIM(SE.Name) AS ErrorType, COUNT(*) AS FailCount
FROM    Stocks.OrderFail OF2 WITH (NOLOCK)
JOIN    Dictionary.StockError SE WITH (NOLOCK) ON SE.StockErrorID = OF2.StockErrorID
GROUP BY RTRIM(SE.Name)
ORDER BY FailCount DESC;

-- Recent CopyTrading-related stock failures
SELECT  TOP 10 OF2.*, RTRIM(SE.Name) AS ErrorName
FROM    Stocks.OrderFail OF2 WITH (NOLOCK)
JOIN    Dictionary.StockError SE WITH (NOLOCK) ON SE.StockErrorID = OF2.StockErrorID
WHERE   OF2.StockErrorID IN (1, 2, 3, 7)
ORDER BY OF2.StockErrorID;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Stock error codes are an internal trading infrastructure feature for REAL asset order failure tracking.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.0 — MCP verified (6 rows), codebase traced (1 consumer: Stocks.OrderFail), CopyTrading error pattern documented*
