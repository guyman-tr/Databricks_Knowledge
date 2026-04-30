# Trade.HedgeCloseErrors

> Historical error log for failures in Trade.HedgeClose. Captures error number, message, and line when closing hedge positions. Insert logic is currently commented out but table retains legacy data.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK) |

---

## 1. Business Meaning

Trade.HedgeCloseErrors stores errors encountered when closing hedge positions via Trade.HedgeClose. Each row captures ErrorNum (SQL error number), ErrorMessage, ErrorLIne (typo in DDL), and ErrorTime (UTC). The table was intended for debugging production hedge close failures (comment: "Added by Adi for debuging problems in production").

This table exists because hedge closes can fail (e.g., "Divide by zero", "Cannot close hedge position -1. Position does not exist"); logging these errors helps diagnose integration issues between eToro and the hedging provider. The insert statements in Trade.HedgeClose CATCH blocks are **commented out** (lines 206, 221), so new errors are not currently logged. The table holds 301 rows of legacy data from 2012.

Data flows: Historically populated by Trade.HedgeClose (when insert was enabled). Currently no active writer; Trade.HedgeClose still RAISERRORs but does not insert. ErrorTime defaults to getutcdate().

---

## 2. Business Logic

### 2.1 Error Capture (When Enabled)

**What**: On hedge close failure, CATCH block would insert ErrorNum, ErrorMessage, ErrorLIne.

**Columns/Parameters Involved**: `ErrorNum`, `ErrorMessage`, `ErrorLIne`, `ErrorTime`

**Rules**:
- ErrorNum: ERROR_NUMBER() from SQL (e.g., 8134 divide-by-zero, 60004 custom).
- ErrorMessage: ERROR_MESSAGE().
- ErrorLIne: ERROR_LINE() (typo in column name).
- ErrorTime: DEFAULT getutcdate(). Sample data from 2012.

**Diagram**:
```
Trade.HedgeClose CATCH
  -- insert into Trade.HedgeCloseErrors (ErrorNum, ErrorMessage, ErrorLIne) values (ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_LINE())
  RAISERROR(...)
```

### 2.2 Common Error Patterns (from Sample Data)

**What**: Observed error types from legacy rows.

**Rules**:
- 8134: "Divide by zero error encountered."
- 60004: "Cannot close hedge position -1. Position does not exist." (e.g., invalid/closed position ID)

---

## 3. Data Overview

| ID | ErrorTime | ErrorNum | ErrorMessage | ErrorLIne | Meaning |
|----|-----------|----------|--------------|-----------|---------|
| 3 | 2012-01-26 19:44:25 | 8134 | Divide by zero error encountered. | 11 | Arithmetic error in hedge close. |
| 4 | 2012-01-26 19:48:27 | 8134 | Divide by zero error encountered. | 11 | Same pattern. |
| 5 | 2012-01-26 19:53:12 | 60004 | Cannot close hedge position -1. Position does not exist. | 182 | Invalid position close attempt. |
| 6 | 2012-01-26 20:14:26 | 60004 | Cannot close hedge position -1. Position does not exist. | 182 | Same. |
| 7 | 2012-01-26 20:22:23 | 60004 | Cannot close hedge position -1. Position does not exist. | 182 | Same. |

**Selection criteria**: First 5 by ID. 301 rows total. All from 2012; no current inserts (logic commented out).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | VERIFIED | Surrogate PK. |
| 2 | ErrorTime | datetime | NO | getutcdate() | VERIFIED | When error occurred (UTC). |
| 3 | ErrorNum | int | NO | - | VERIFIED | SQL error number (e.g., 8134, 60004). |
| 4 | ErrorMessage | varchar(600) | YES | - | VERIFIED | Full error message text. |
| 5 | ErrorLIne | int | YES | - | VERIFIED | Line number in procedure (typo: LIne). |

---

## 5. Relationships

### 5.1 References To

- None (standalone log table)

### 5.2 Referenced By

- **Trade.HedgeClose** — insert logic commented out; no active dependency

---

## 6. Dependencies

### 6.0 Chain

```
(Leaf table; no declared dependencies)
```

### 6.1 Depends On

- None

### 6.2 Depended On By

- Trade.HedgeClose (historically; insert now disabled)

---

## 7. Technical Details

### 7.1 Indexes

| Name | Type | Columns |
|------|------|---------|
| PK_TradeHedgeCloseErrors | CLUSTERED | ID |

### 7.2 Constraints

- PK_TradeHedgeCloseErrors: PRIMARY KEY (ID)
- DF_HedgeCloseErrorsErrorTime: DEFAULT getutcdate() FOR ErrorTime

---

## 8. Sample Queries

```sql
-- Row count
SELECT COUNT(*) AS Cnt FROM Trade.HedgeCloseErrors WITH (NOLOCK);

-- Sample rows
SELECT TOP 5 * FROM Trade.HedgeCloseErrors WITH (NOLOCK);

-- Errors by type
SELECT ErrorNum, ErrorMessage, COUNT(*) AS Cnt
FROM Trade.HedgeCloseErrors WITH (NOLOCK)
GROUP BY ErrorNum, ErrorMessage
ORDER BY Cnt DESC;
```

---

## 9. Atlassian Knowledge Sources

*None discovered.*

---

*Generated: 2026-03-14 | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
