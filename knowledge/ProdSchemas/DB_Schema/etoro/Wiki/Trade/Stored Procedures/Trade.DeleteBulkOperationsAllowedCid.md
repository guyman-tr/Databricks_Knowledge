# Trade.DeleteBulkOperationsAllowedCid

> Removes a customer from the bulk operations whitelist after verifying the CID exists, preventing invalid deletes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to remove from whitelist) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteBulkOperationsAllowedCid removes a single customer identifier from the Trade.BulkOperationsAllowedCids table, which controls which customers are permitted to receive bulk trading operations (e.g., mass position closes, bulk fee adjustments). This is an admin-facing procedure used when a customer should no longer be eligible for bulk operations.

This procedure exists to provide a safe delete mechanism with existence validation. It first checks whether the CID exists in the whitelist and raises an error if not found, preventing silent no-op deletes that could mask data issues.

Data flow: The caller provides a CID. The procedure first selects to verify existence. If found, it deletes the row. If not found, it raises a descriptive error. The table (BulkOperationsAllowedCids) is maintained by admin tools and controls eligibility for batch trading operations.

---

## 2. Business Logic

### 2.1 Existence Validation Before Delete

**What**: Ensures the CID actually exists before attempting deletion.

**Columns/Parameters Involved**: `@CID`

**Rules**:
- SELECT @Result = CID WHERE CID = @CID runs first
- If @Result IS NULL, RAISERROR with message about incorrect ID
- Only if the record exists does the DELETE execute
- Wrapped in TRY/CATCH with THROW for error propagation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier to remove from the bulk operations whitelist. Must exist in Trade.BulkOperationsAllowedCids or an error is raised. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.BulkOperationsAllowedCids | DELETER | Removes the row matching this CID from the whitelist |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteBulkOperationsAllowedCid (procedure)
+-- Trade.BulkOperationsAllowedCids (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.BulkOperationsAllowedCids | Table | SELECT for existence check, then DELETE |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove a customer from bulk operations whitelist

```sql
EXEC Trade.DeleteBulkOperationsAllowedCid @CID = 12345
```

### 8.2 Check current whitelist before deletion

```sql
SELECT CID FROM Trade.BulkOperationsAllowedCids WITH (NOLOCK) ORDER BY CID
```

### 8.3 Verify deletion was successful

```sql
EXEC Trade.DeleteBulkOperationsAllowedCid @CID = 12345
SELECT COUNT(*) AS StillExists FROM Trade.BulkOperationsAllowedCids WITH (NOLOCK) WHERE CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteBulkOperationsAllowedCid | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteBulkOperationsAllowedCid.sql*
