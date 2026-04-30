# BackOffice.CustomerIMDetailRemove_Del

> Removes a specific Instant Messaging (IM) account identifier for a customer from BackOffice.CustomerToIMType. Legacy/deprecated (_Del suffix). Returns @@ERROR (0=success).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @IMTypeID + @IMIdentifier (composite PK match) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure removes a customer's Instant Messaging account registration from `BackOffice.CustomerToIMType`. It is the delete counterpart to `BackOffice.CustomerIMDetailAdd_Del`.

Used when a BackOffice agent or the customer removed a registered IM handle from their profile. The `_Del` suffix indicates this procedure is marked for deletion as part of the IM feature decommissioning.

No existence check - if the specified (CID, IMTypeID, IMIdentifier) combination does not exist, the DELETE silently affects 0 rows with no error.

Uses legacy `RETURN @@ERROR` error pattern.

---

## 2. Business Logic

### 2.1 Exact-Match Delete

**What**: Deletes the row matching all three key fields exactly.

**Rules**:
- DELETE FROM BackOffice.CustomerToIMType WHERE CID=@CID AND IMTypeID=@IMTypeID AND IMIdentifier=@IMIdentifier
- All three conditions must match for deletion (composite PK match)
- Silent no-op if no matching row exists
- RETURN @@ERROR: 0=success, non-zero=SQL error code

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Must match the target row's CID. |
| 2 | @IMTypeID | INT | NO | - | CODE-BACKED | IM platform type ID. 1=Windows Live Messenger, 2=Yahoo! Messenger, 3=Google Talk, 4=Skype, 5=ICQ. |
| 3 | @IMIdentifier | VARCHAR(255) | NO | - | CODE-BACKED | IM account identifier to remove. Must exactly match the stored value (case-sensitive per collation). |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 4 | RETURN | INT | 0=success. Non-zero SQL error code on failure. Legacy pattern. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @IMTypeID + @IMIdentifier | BackOffice.CustomerToIMType | DELETE | Removes the matching IM registration row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice IM feature | External | Deprecated - no active callers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerIMDetailRemove_Del (procedure)
|- BackOffice.CustomerToIMType (table) [DELETE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToIMType | Table | DELETE: removes the specified IM account row |

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
| No existence check | Design | Silent no-op if row does not exist |
| _Del designation | Lifecycle | Marked for deletion; feature decommissioned |

---

## 8. Sample Queries

### 8.1 Remove a Skype IM registration

```sql
DECLARE @Ret INT;
EXEC @Ret = BackOffice.CustomerIMDetailRemove_Del
    @CID = 12345,
    @IMTypeID = 4,
    @IMIdentifier = 'john.smith.trading';
SELECT @Ret AS ReturnCode;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerIMDetailRemove_Del | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerIMDetailRemove_Del.sql*
