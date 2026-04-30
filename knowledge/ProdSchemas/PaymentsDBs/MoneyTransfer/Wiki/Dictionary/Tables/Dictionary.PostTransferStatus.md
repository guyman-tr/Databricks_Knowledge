# Dictionary.PostTransferStatus

> Lookup table intended to define lifecycle states for post-transfer actions - follow-up operations that occur after a primary money transfer. Currently empty; status values are managed by the application layer.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.PostTransferStatus is a lookup table designed to define the lifecycle states of post-transfer actions in the MoneyTransfer system. Post-transfer actions are follow-up operations (such as notifications, reconciliations, or secondary fund movements) that occur after the primary transfer has been initiated.

The table exists as part of the standard Dictionary pattern used across the MoneyTransfer database, providing a centralized reference for status definitions. However, unlike Dictionary.TransferStatus (which has 8 defined statuses), this table currently contains zero rows - the post-transfer status values (observed values: 1 and 2 in Billing.PostTransferActions data) are managed entirely through application-layer constants rather than database reference data.

PostTransferStatusID values are written to `Billing.PostTransferActions` by `Billing.CreatePostTransfer` and updated by `Billing.UpdatePostTransferStatus`. The MIMO service account has SELECT access for external monitoring/reporting.

---

## 2. Business Logic

### 2.1 Application-Managed Status Values

**What**: Post-transfer action statuses are defined in application code rather than in this Dictionary table.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- The table schema mirrors Dictionary.TransferStatus (ID + Name + Description) but contains no rows
- Live data in Billing.PostTransferActions shows PostTransferStatusID values of at least 1 and 2 in active use
- The application passes status values directly to `Billing.CreatePostTransfer` and `Billing.UpdatePostTransferStatus` without database-level validation against this lookup table
- No FK constraint exists between Billing.PostTransferActions.PostTransferStatusID and this table

---

## 3. Data Overview

| ID | Name | Description | Meaning |
|----|------|-------------|---------|
| *(table is empty - 0 rows)* | - | - | Status values are managed by the application layer. Known values in use: 1 and 2 (observed in Billing.PostTransferActions data). Business meaning of these values must be determined from application code. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Unique identifier for each post-transfer status. Auto-incremented PK. Intended as the FK target for `Billing.PostTransferActions.PostTransferStatusID`, though no explicit FK constraint exists and no rows are populated. See [Post Transfer Status](../../_glossary.md#post-transfer-status). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the post-transfer status. NOT NULL constraint means any future rows must have a name. Currently unused as table has no rows. |
| 3 | Description | varchar(100) | YES | - | CODE-BACKED | Optional extended description of the post-transfer status. Follows the same pattern as Dictionary.TransferStatus.Description. Currently unused. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PostTransferActions | PostTransferStatusID | Implicit FK (Lookup) | Current lifecycle status of each post-transfer action. Values set by application code without database-level validation against this table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PostTransferActions | Table | PostTransferStatusID column logically references this lookup (implicit FK, no constraint) |
| Billing.CreatePostTransfer | Stored Procedure | Accepts @PostTransferStatusID parameter and writes to PostTransferActions |
| Billing.UpdatePostTransferStatus | Stored Procedure | Updates PostTransferStatusID in PostTransferActions |
| Billing.GetPostTransfer | Stored Procedure | Returns PostTransferStatusID in result set |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all post-transfer statuses (currently returns empty)
```sql
SELECT ID, Name, Description
FROM Dictionary.PostTransferStatus WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find distinct status values actually in use
```sql
SELECT TOP 10 PostTransferStatusID, COUNT(*) AS ActionCount
FROM Billing.PostTransferActions WITH (NOLOCK)
GROUP BY PostTransferStatusID
ORDER BY ActionCount DESC
```

### 8.3 Compare defined statuses vs actual usage
```sql
SELECT COALESCE(d.Name, CONCAT('Undefined (', pa.PostTransferStatusID, ')')) AS StatusLabel,
       pa.PostTransferStatusID, COUNT(*) AS ActionCount
FROM Billing.PostTransferActions pa WITH (NOLOCK)
LEFT JOIN Dictionary.PostTransferStatus d WITH (NOLOCK) ON pa.PostTransferStatusID = d.ID
GROUP BY d.Name, pa.PostTransferStatusID
ORDER BY ActionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PostTransferStatus | Type: Table | Source: MoneyTransfer/Dictionary/Tables/Dictionary.PostTransferStatus.sql*
