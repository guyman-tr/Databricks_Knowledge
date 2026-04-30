# Monitoring.ExcludedErrors

> Exclusion list of error message patterns that should be filtered out from operational monitoring reports, preventing known benign errors from triggering alerts.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Table |
| **Key Identifier** | ErrorMessage (unique constraint, no PK) |
| **Partition** | No |
| **Indexes** | 1 active (unique nonclustered on ErrorMessage) |

---

## 1. Business Meaning

Monitoring.ExcludedErrors is a configuration table that stores SQL LIKE patterns for error messages that should be excluded from operational failure reports. When the monitoring system calculates success/failure rates for wallet operations, certain errors are considered "expected" or "benign" - for example, user-caused errors like insufficient funds, invalid addresses, or permission restrictions. These errors are not infrastructure failures and should not inflate failure metrics.

Without this table, every operational monitoring report would include user-generated errors alongside genuine system failures, making it impossible to distinguish real incidents from normal user behavior. The monitoring team would receive noisy alerts and the failure percentage metrics would be unreliable for incident detection.

Rows in this table are managed manually by the operations/monitoring team. The table is consumed by four reporting stored procedures (OperationsReport, OperationFailuresReport, OperationFailuresCountReport, OperationFailuresDetailsReport) that LEFT JOIN to this table using a LIKE pattern match against `RequestStatuses.DetailsJson`. When a match is found, the error row is excluded from the report output.

---

## 2. Business Logic

### 2.1 LIKE Pattern Exclusion Mechanism

**What**: Error messages are stored as SQL LIKE patterns (with `%` wildcards) and matched against the JSON error details of request statuses.

**Columns/Parameters Involved**: `ErrorMessage`

**Rules**:
- Each row contains a LIKE pattern (e.g., `%insufficient funds%`) that matches against `Wallet.RequestStatuses.DetailsJson`
- The consuming SPs use `LEFT JOIN Monitoring.ExcludedErrors ee ON rs.DetailsJson LIKE ee.ErrorMessage` followed by `WHERE ee.ErrorMessage IS NULL` - this keeps only rows that do NOT match any exclusion pattern
- Patterns use leading and trailing `%` wildcards to match anywhere within the JSON error payload
- Some patterns match structured JSON error codes (e.g., `{"Code":"WL.0221","ResponseMessage":"insufficient balance"%`), providing precise targeting of specific error codes

**Diagram**:
```
RequestStatuses.DetailsJson
        |
        v
  LEFT JOIN ON LIKE
        |
  ExcludedErrors.ErrorMessage (28 patterns)
        |
        v
  WHERE ee.ErrorMessage IS NULL
        |
        v
  Only unmatched (real failures) pass through
```

### 2.2 Error Category Classification

**What**: The 28 exclusion patterns cover distinct categories of benign errors.

**Columns/Parameters Involved**: `ErrorMessage`

**Rules**:
- **User limit violations**: Daily transfer limits (WL.0202), single transaction limits (WL.0201), conversion limits
- **User permission restrictions**: Cannot create wallet (WL.0102), cannot send (WL.0233), cannot buy crypto (WL.0501)
- **Blockchain validation errors**: Dust threshold, invalid address, invalid memo, double spend (WL.0221)
- **AML/compliance rejections**: Transaction rejected due to AML (WL.0222)
- **Duplicate/conflict errors**: Duplicate key in Wallet.Requests, wallet already exists
- **Business rule violations**: Internal transactions not supported, staking not allowed, invalid fiat amount (WL.0502)

---

## 3. Data Overview

| ErrorMessage | Meaning |
|---|---|
| `%insufficient funds%` | Generic catch-all for any insufficient balance error across providers - user tried to send more crypto than available in their wallet |
| `{"Code":"WL.0202","ResponseMessage":"Amount exceeds your daily Transfer limit%` | User hit their daily transfer ceiling configured by compliance/risk - expected behavior during high-activity periods |
| `{"Code":"WL.0221","ResponseMessage":"invalid address%` | Blockchain address validation failed - user entered a malformed or incompatible address for the target crypto network |
| `{"Code":"WL.0222","ResponseMessage":"Transaction rejected due to AML%` | Anti-money-laundering check blocked the transaction - compliance control working as designed |
| `{"Code":"WL.0233","ResponseMessage":"User has no permission to send a transaction%` | User account is restricted from sending (e.g., regulatory hold, KYC incomplete) - not a system error |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ErrorMessage | varchar(500) | NO | - | VERIFIED | SQL LIKE pattern for matching against `Wallet.RequestStatuses.DetailsJson`. Each pattern uses `%` wildcards to match error messages anywhere within the JSON payload. Patterns range from generic substrings (`%insufficient funds%`) to precise JSON code prefixes (`{"Code":"WL.0221","ResponseMessage":"insufficient balance"%`). Used by 4 monitoring SPs via LEFT JOIN with IS NULL filter to exclude matched errors from failure reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Monitoring.OperationsReport | ee.ErrorMessage | LEFT JOIN (LIKE) | Excludes known benign errors from the overall operations success/failure summary report |
| Monitoring.OperationFailuresReport | ee.ErrorMessage | LEFT JOIN (LIKE) | Excludes known benign errors from the detailed operation failures listing |
| Monitoring.OperationFailuresCountReport | ee.ErrorMessage | LEFT JOIN (LIKE) | Excludes known benign errors from the failure count aggregation by error code |
| Monitoring.OperationFailuresDetailsReport | ee.ErrorMessage | LEFT JOIN (LIKE) | Excludes known benign errors from the per-wallet failure detail report |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Monitoring.OperationsReport | Stored Procedure | LEFT JOIN to exclude benign errors from success/failure summary |
| Monitoring.OperationFailuresReport | Stored Procedure | LEFT JOIN to exclude benign errors from failure detail listing |
| Monitoring.OperationFailuresCountReport | Stored Procedure | LEFT JOIN to exclude benign errors from failure count by error code |
| Monitoring.OperationFailuresDetailsReport | Stored Procedure | LEFT JOIN to exclude benign errors from per-wallet failure details |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| UQ__Exclude__444E3C53... | NONCLUSTERED UNIQUE | ErrorMessage | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UQ__Exclude__444E3C53... | UNIQUE | Prevents duplicate error patterns - each exclusion pattern must be distinct to avoid redundant LIKE matching overhead |

---

## 8. Sample Queries

### 8.1 View all current exclusion patterns
```sql
SELECT ErrorMessage
FROM Monitoring.ExcludedErrors WITH (NOLOCK)
ORDER BY ErrorMessage;
```

### 8.2 Check if a specific error is currently excluded
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1
    FROM Monitoring.ExcludedErrors ee WITH (NOLOCK)
    WHERE '{"Code":"WL.0221","ResponseMessage":"insufficient balance"}' LIKE ee.ErrorMessage
) THEN 'Excluded' ELSE 'Not Excluded' END AS ExclusionStatus;
```

### 8.3 Count recent failures that pass the exclusion filter
```sql
SELECT COUNT(*) AS UnexcludedFailures
FROM Wallet.RequestStatuses rs WITH (NOLOCK)
LEFT JOIN Monitoring.ExcludedErrors ee WITH (NOLOCK) ON rs.DetailsJson LIKE ee.ErrorMessage
WHERE rs.RequestStatusId = 2
  AND rs.Timestamp >= DATEADD(HOUR, -24, GETUTCDATE())
  AND ee.ErrorMessage IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.ExcludedErrors | Type: Table | Source: WalletDB/Monitoring/Tables/Monitoring.ExcludedErrors.sql*
