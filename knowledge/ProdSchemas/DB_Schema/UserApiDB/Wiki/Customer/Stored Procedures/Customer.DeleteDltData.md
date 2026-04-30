# Customer.DeleteDltData

> Clears DLT (blockchain) data from a user's identification record, but only if the DLT status is not 'Passed'.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DeleteDltData removes DLT (Distributed Ledger Technology) identification data from a user's CustomerIdentification record. Importantly, it only clears data if the DLT status is NOT 4 (Passed) - once DLT verification has passed, the data is preserved. Sets DltID and DltStatusID to NULL and updates the timestamp.

---

## 2. Business Logic

### 2.1 Conditional DLT Data Removal

**What**: Only clears DLT data if verification hasn't passed.

**Columns/Parameters Involved**: `DltID`, `DltStatusID`

**Rules**:
- If DltStatusID != 4 (Passed): set DltID=NULL, DltStatusID=NULL, UpdateDate=GETUTCDATE()
- If DltStatusID = 4 (Passed): no action (data preserved for compliance)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID whose DLT data to clear. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.CustomerIdentification | UPDATE | Clears DltID and DltStatusID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DeleteDltData (procedure)
  +-- Customer.CustomerIdentification (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | UPDATE (sets DltID/DltStatusID to NULL) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Clear DLT data
```sql
EXEC Customer.DeleteDltData @GCID = 12345
```

### 8.2 Verify conditional behavior
```sql
-- Only clears if DltStatusID != 4 (Passed)
SELECT DltID, DltStatusID FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE GCID = 12345
EXEC Customer.DeleteDltData @GCID = 12345
SELECT DltID, DltStatusID FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE GCID = 12345
```

### 8.3 Check which users have non-passed DLT data
```sql
SELECT GCID, DltStatusID FROM Customer.CustomerIdentification WITH (NOLOCK)
WHERE DltID IS NOT NULL AND DltStatusID != 4
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.DeleteDltData | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.DeleteDltData.sql*
