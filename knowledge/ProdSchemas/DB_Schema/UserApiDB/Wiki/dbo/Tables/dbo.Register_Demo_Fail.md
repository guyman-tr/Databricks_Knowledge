# dbo.Register_Demo_Fail

> Logs failed demo account registration attempts with the real CID and whether the demo password was passed.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

dbo.Register_Demo_Fail records instances where demo account registration failed. When a user's real account is created but the linked demo account fails to register, this table captures the failure for operational monitoring and retry processing.

---

## 2. Business Logic

No complex business logic. Failure audit log.

---

## 3. Data Overview

N/A - operational log table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing failure record ID. |
| 2 | CID_Real | int | YES | - | CODE-BACKED | The real account CID whose demo registration failed. |
| 3 | Occurred | datetime | YES | getdate() | CODE-BACKED | When the failure occurred. Default: current datetime. |
| 4 | Pass2Demo | bit | NO | 0 | CODE-BACKED | Whether the password was passed to the demo registration call. Default: 0 (no). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Register_Demo_Fail | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Register_Demo_Fail_Occurred | DEFAULT | getdate() |
| DF_Register_Demo_Fail_Pass2Demo | DEFAULT | (0) |

---

## 8. Sample Queries

### 8.1 Recent failures
```sql
SELECT TOP 50 ID, CID_Real, Occurred, Pass2Demo FROM dbo.Register_Demo_Fail WITH (NOLOCK) ORDER BY Occurred DESC
```

### 8.2 Failure count by date
```sql
SELECT CAST(Occurred AS DATE) AS FailDate, COUNT(*) AS FailCount FROM dbo.Register_Demo_Fail WITH (NOLOCK) GROUP BY CAST(Occurred AS DATE) ORDER BY FailDate DESC
```

### 8.3 Failures for specific CID
```sql
SELECT * FROM dbo.Register_Demo_Fail WITH (NOLOCK) WHERE CID_Real = @CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.Register_Demo_Fail | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.Register_Demo_Fail.sql*
