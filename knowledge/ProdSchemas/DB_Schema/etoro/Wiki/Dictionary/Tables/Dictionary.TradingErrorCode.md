# Dictionary.TradingErrorCode

> Comprehensive registry of 200+ trading engine error codes covering every failure scenario from login to position execution.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ErrorMessagesCodeID (int, PK) |
| **Row Count** | ~200 |
| **Indexes** | 1 (clustered PK, FILLFACTOR 90) |
| **Filegroup** | DICTIONARY |

---

## 1. Business Meaning

### What It Is
Dictionary.TradingErrorCode is a comprehensive lookup table containing every error code that the trading engine can return. Each code maps to a SCREAMING_SNAKE_CASE error message string that identifies the specific failure scenario.

### Why It Exists
The trading engine communicates failures through numeric error codes. This table provides the human-readable mapping for each code, enabling SSRS reports, monitoring dashboards, and debugging tools to display meaningful error descriptions instead of raw numeric codes.

### How It Works
The `ErrorMessagesCodeID` is returned by the trading engine when operations fail. Reporting procedures like `dbo.SSRS_ASYNC_EXECUTION_FAILURES` and `Trade.SSRS_Market_Open_Data` join against this table to translate numeric codes into readable error names for operational dashboards and reports.

---

## 2. Business Logic

### Error Code Ranges

| Range | Category | Examples |
|-------|----------|----------|
| 300-302 | Login Errors | LOGIN_FAILED, USER_ALREADY_LOGIN, USERNAME_PASSWORD_NOT_FOUND |
| 405 | Credit | LOW_CREDIT |
| 600-632 | Trading Validation | WRONG_PARAMS, INSUFFICIENT_FUNDS, LEVERAGE_TOO_HIGH, FAILED_TO_CLOSE |
| 640-670 | Trading Rules | TRADE_RANGE_VIOLATION, USA_LEVERAGE_TOO_HIGH, FAILED_TO_EDIT_MIRRORED |
| 680-699 | Trade Engine | TRADE_GAME_NOT_EXIST, OPEN/CLOSE/EDIT errors |
| 700-799 | Order/Position | EXIT_ORDER, ENTRY_ORDER, INSTRUMENT_BLOCKED, MIRROR failures |
| 800-819 | CopyTrading | MIRROR_MAXIMUM_AMOUNT, REGULATION_BLOCKED, SELF_COPY_BLOCKED |
| 900-970 | Execution Engine | POSITION_OPEN/CLOSE_ERROR, ORDER_FOR_EXECUTION failures |
| 1000-1072 | Advanced Execution | PDT, DEALING_REJECT, ADMIN_POSITION, ALLOCATION failures |
| 2008-2022 | Settlement/Real | CLOSE_REAL_POSITION restrictions, SETTLEMENT_TYPE failures |
| 50000 | Logical Boundary | MIN_LOGICAL_ERROR_CODE (sentinel value) |
| 60001-60097 | Database-Level | DB_OPEN_POS, DB_MIRROR, DB_POSITION errors (RAISERROR from SPs) |

### Key Error Patterns
- **60xxx range**: Database-level errors raised by stored procedures via RAISERROR — these indicate failures within the SQL layer
- **900-970 range**: Execution engine errors — failures during the order-for-execution pipeline
- **1064-1069 range**: Dealing desk reject codes — provider/market rejections

---

## 3. Data Overview

| ErrorMessagesCodeID | ErrorMessagesCode | Scenario |
|---------------------|-------------------|----------|
| 604 | INSUFFICIENT_FUNDS_ERROR | User tries to open position with more than available balance |
| 617 | FAILED_TO_EXECUTE_ORDER_INSTRUMENT_SUSPENSION | Trade blocked because instrument is suspended |
| 715 | AMOUNT_TOO_LOW | Order amount below minimum threshold |
| 810 | SELF_COPY_BLOCKED | User attempts to copy themselves |
| 956 | MARKET_HOURS_ERROR_MARKET_CLOSED | Trade submitted outside market hours |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ErrorMessagesCodeID | int | NO | — | HIGH | Primary key — the numeric error code returned by the trading engine. Ranges from 300 to 60116. Referenced by execution failure logging and SSRS reports. |
| 2 | ErrorMessagesCode | varchar(100) | NO | — | HIGH | SCREAMING_SNAKE_CASE error identifier string. Some values have trailing spaces. Used in reports and monitoring dashboards. |

---

## 5. Relationships

### Referenced By (Implicit)

| Consumer | Context | Evidence |
|----------|---------|----------|
| Trading engine error logs | Error code classification | Numeric codes stored in execution logs |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| dbo.SSRS_ASYNC_EXECUTION_FAILURES | SELECT (JOIN) | SSRS report translating failure codes to names |
| Trade.SSRS_Market_Open_Data | SELECT (JOIN) | Market open monitoring report |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table.

### Depended On By
- SSRS reporting procedures for execution failure analysis
- Application-layer error handling and logging

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_ErrorMessagesCodeID | CLUSTERED PK | ErrorMessagesCodeID ASC | FILLFACTOR 90 |

| Property | Value |
|----------|-------|
| Filegroup | DICTIONARY |

---

## 8. Sample Queries

```sql
-- Get all error codes
SELECT  ErrorMessagesCodeID,
        RTRIM(ErrorMessagesCode) AS ErrorCode
FROM    Dictionary.TradingErrorCode WITH (NOLOCK)
ORDER BY ErrorMessagesCodeID;

-- Find all mirror/copy-related errors
SELECT  ErrorMessagesCodeID,
        RTRIM(ErrorMessagesCode) AS ErrorCode
FROM    Dictionary.TradingErrorCode WITH (NOLOCK)
WHERE   ErrorMessagesCode LIKE '%MIRROR%'
   OR   ErrorMessagesCode LIKE '%COPY%'
ORDER BY ErrorMessagesCodeID;

-- Find all database-level errors (60xxx range)
SELECT  ErrorMessagesCodeID,
        RTRIM(ErrorMessagesCode) AS ErrorCode
FROM    Dictionary.TradingErrorCode WITH (NOLOCK)
WHERE   ErrorMessagesCodeID >= 60000
ORDER BY ErrorMessagesCodeID;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `TradingErrorCode`.

---

*Generated: 2026-03-14 | Quality: 9.2/10*
*Object: Dictionary.TradingErrorCode | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TradingErrorCode.sql*
