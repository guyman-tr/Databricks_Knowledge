# BackOffice.CustomerIMDetailUpdate_Del

> Updates an Instant Messaging account identifier for a customer in BackOffice.CustomerToIMType (changes an existing IMIdentifier). Legacy/deprecated (_Del suffix). Returns @@ERROR (0=success).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @IMTypeID + @OldIMIdentifier (row to change) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure updates the `IMIdentifier` value for a specific customer IM account record in `BackOffice.CustomerToIMType`. It replaces an existing IM handle with a new one while keeping the same customer and IM type.

Used when a customer changed their IM username on a platform (e.g., updated their Skype handle). The `_Del` suffix indicates this procedure is marked for deletion as part of the IM feature decommissioning.

No existence check - if the specified (CID, IMTypeID, OldIMIdentifier) does not exist, the UPDATE silently affects 0 rows.

---

## 2. Business Logic

### 2.1 Identifier Rename

**What**: Changes IMIdentifier from @OldIMIdentifier to @IMIdentifier for the matching row.

**Rules**:
- UPDATE BackOffice.CustomerToIMType SET IMIdentifier=@IMIdentifier WHERE CID=@CID AND IMTypeID=@IMTypeID AND IMIdentifier=@OldIMIdentifier
- All three WHERE conditions must match
- Silent no-op if no matching row found
- Does NOT update Verified flag - if old identifier was Verified=1, the new identifier inherits that flag (potential data integrity concern: new handle not re-verified)
- RETURN @@ERROR: 0=success, non-zero=SQL error code

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 2 | @IMTypeID | INT | NO | - | CODE-BACKED | IM platform type. 1=Windows Live Messenger, 2=Yahoo! Messenger, 3=Google Talk, 4=Skype, 5=ICQ. |
| 3 | @OldIMIdentifier | VARCHAR(255) | NO | - | CODE-BACKED | Current IMIdentifier value to match and replace. Used in the WHERE clause to identify the target row. |
| 4 | @IMIdentifier | VARCHAR(255) | NO | - | CODE-BACKED | New IMIdentifier value to set. Replaces @OldIMIdentifier in the matching row. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 5 | RETURN | INT | 0=success. Non-zero SQL error code on failure. Legacy pattern. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @IMTypeID + @OldIMIdentifier | BackOffice.CustomerToIMType | UPDATE | Changes IMIdentifier on the matching row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice IM feature | External | Deprecated - no active callers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerIMDetailUpdate_Del (procedure)
|- BackOffice.CustomerToIMType (table) [UPDATE: IMIdentifier]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToIMType | Table | UPDATE: changes IMIdentifier value |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Legacy BackOffice IM feature | External | Deprecated - no active callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN @@ERROR | Design | Legacy error-return pattern |
| Verified flag inheritance | Behavior | New identifier inherits Verified status of old row without re-verification |
| _Del designation | Lifecycle | Marked for deletion; feature decommissioned |

---

## 8. Sample Queries

### 8.1 Update a Skype username

```sql
DECLARE @Ret INT;
EXEC @Ret = BackOffice.CustomerIMDetailUpdate_Del
    @CID = 12345,
    @IMTypeID = 4,
    @OldIMIdentifier = 'john.smith.old',
    @IMIdentifier = 'john.smith.new';
SELECT @Ret AS ReturnCode;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerIMDetailUpdate_Del | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerIMDetailUpdate_Del.sql*
