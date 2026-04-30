# PEP.ParamPoolingRequiredCases

> Table-valued parameter type used to pass polling/retry configuration data (count thresholds and delay intervals) to PEP (Politically Exposed Person) screening procedures.

| Property | Value |
|----------|-------|
| **Schema** | PEP |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | PoolingCount (INT, CLUSTERED PK) |
| **Partition** | N/A |
| **Indexes** | 1 (PK on PoolingCount) |

---

## 1. Business Meaning

This is a table-valued parameter type used in PEP (Politically Exposed Person) screening operations. It defines a lookup structure that maps polling iteration counts to delay intervals in seconds, enabling configurable retry/backoff patterns when the PEP screening service is polled for results.

PEP screening is an asynchronous process - after submitting a customer for screening, the system polls for results. This type allows callers to specify different delay intervals based on how many times they've already polled (e.g., poll quickly at first, then back off with longer delays). The type is passed as a parameter to stored procedures that implement the polling logic.

The type exists in the PEP schema, which handles Politically Exposed Person screening - a key AML/KYC compliance requirement for identifying customers who hold or have held prominent public positions.

---

## 2. Business Logic

### 2.1 Configurable Polling Backoff

**What**: Maps polling iteration count to delay interval for progressive backoff.

**Columns/Parameters Involved**: `PoolingCount`, `Seconds`

**Rules**:
- PoolingCount is the Nth polling attempt (1st, 2nd, 3rd, etc.)
- Seconds is how long to wait before the Nth poll
- Clustered PK on PoolingCount enables efficient lookup by iteration
- Typical pattern: short delays for early polls, longer delays for later polls (exponential or stepped backoff)
- Seconds is nullable, suggesting a NULL value may signal "stop polling"

---

## 3. Data Overview

N/A - this is a type definition, not a table with persistent data. Populated at runtime when passed as a parameter.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PoolingCount | INT | NO | - | CODE-BACKED | Polling iteration number (1st attempt, 2nd attempt, etc.). PK. Determines which delay interval to use. The name "Pooling" appears to be a misspelling of "Polling". |
| 2 | Seconds | INT | YES | - | CODE-BACKED | Delay interval in seconds to wait before this polling attempt. NULL may indicate "stop polling" or "use default". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Used as a table-valued parameter by PEP screening stored procedures (not present in the SSDT project for this database - likely consumed by procedures in an external PEP service database or application code).

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the SSDT project. Used by external PEP screening procedures.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED PK | PoolingCount ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PK | PoolingCount - unique polling iteration |

---

## 8. Sample Queries

### 8.1 Declare and populate the type
```sql
DECLARE @pollingConfig PEP.ParamPoolingRequiredCases
INSERT INTO @pollingConfig (PoolingCount, Seconds)
VALUES (1, 5), (2, 10), (3, 30), (4, 60), (5, NULL)
SELECT * FROM @pollingConfig
```

### 8.2 Pass to a procedure (hypothetical)
```sql
DECLARE @config PEP.ParamPoolingRequiredCases
INSERT INTO @config VALUES (1, 2), (2, 5), (3, 10)
-- EXEC PEP.CheckScreeningResults @pollingConfig = @config
```

### 8.3 Lookup delay for a specific iteration
```sql
DECLARE @config PEP.ParamPoolingRequiredCases
INSERT INTO @config VALUES (1, 3), (2, 10), (3, 30)
SELECT Seconds FROM @config WHERE PoolingCount = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: PEP.ParamPoolingRequiredCases | Type: User Defined Type | Source: RiskClassification/PEP/User Defined Types/PEP.ParamPoolingRequiredCases.sql*
