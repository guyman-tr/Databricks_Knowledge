# Customer.ExtendedUserField_History

> Audit history table tracking all changes to extended user field values, including the action type (INSERT/UPDATE/DELETE).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.ExtendedUserField_History maintains a complete audit trail of all changes to extended user field values. Unlike the system-versioned history tables used by other Customer tables, this uses an application-level history pattern with explicit Action tracking (INSERT/UPDATE/DELETE). This enables compliance teams to see exactly when and how KYC field values changed.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Append-only audit log.

---

## 3. Data Overview

N/A - audit history table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing audit record identifier. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID whose field was changed. |
| 3 | FieldId | int | NO | - | CODE-BACKED | Which extended field was changed. Maps to Dictionary.ExtendedUserField. |
| 4 | Value | nvarchar(128) | YES | - | CODE-BACKED | The field value at the time of the change (new value for INSERT/UPDATE, old value for DELETE). |
| 5 | LastModified | datetime | NO | - | CODE-BACKED | Original LastModified timestamp from the source record. |
| 6 | Occurred | datetime | NO | - | CODE-BACKED | When this history record was created (the actual change timestamp). |
| 7 | Action | nvarchar(10) | YES | - | CODE-BACKED | Type of change: 'INSERT', 'UPDATE', or 'DELETE'. |
| 8 | TypeId | int | YES | - | CODE-BACKED | Value subtype at the time of the change. Maps to Dictionary.ExtendedUserValueType. |
| 9 | CountryId | int | YES | - | CODE-BACKED | Country context at the time of the change. |
| 10 | AdditionalDetails | varchar(max) | YES | - | CODE-BACKED | Additional data at the time of the change. |

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
| PK_CustomerExtendedUserField_History | CLUSTERED PK | ID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get change history for a user's field
```sql
SELECT FieldId, Value, Action, Occurred FROM Customer.ExtendedUserField_History WITH (NOLOCK)
WHERE GCID = @GCID AND FieldId = @FieldId ORDER BY Occurred DESC
```

### 8.2 Recent changes across all users
```sql
SELECT TOP 100 GCID, FieldId, Action, Occurred FROM Customer.ExtendedUserField_History WITH (NOLOCK) ORDER BY Occurred DESC
```

### 8.3 Count changes by action type
```sql
SELECT Action, COUNT(*) AS ChangeCount FROM Customer.ExtendedUserField_History WITH (NOLOCK) GROUP BY Action
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.ExtendedUserField_History | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.ExtendedUserField_History.sql*
