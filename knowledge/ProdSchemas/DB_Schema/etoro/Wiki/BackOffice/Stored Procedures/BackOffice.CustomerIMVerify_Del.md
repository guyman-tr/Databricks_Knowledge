# BackOffice.CustomerIMVerify_Del

> Sets the Verified flag on a customer's Instant Messaging account record in BackOffice.CustomerToIMType. Legacy/deprecated (_Del suffix). Returns @@ERROR (0=success).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @IMTypeID + @IMIdentifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure marks a customer's IM account identifier as verified (or unverified) by setting the `Verified` flag on the corresponding `BackOffice.CustomerToIMType` record.

Verification confirmed that the IM handle actually belonged to the customer (e.g., via a challenge-response test: a code was sent to the IM handle and the customer confirmed receipt). Verified IM handles would have been trusted for customer contact by BackOffice agents.

The `_Del` suffix indicates this procedure is marked for deletion as part of the IM feature decommissioning.

---

## 2. Business Logic

### 2.1 Verification Flag Update

**What**: Sets Verified flag for a specific IM account row.

**Rules**:
- UPDATE BackOffice.CustomerToIMType SET Verified=@Verified WHERE CID=@CID AND IMTypeID=@IMTypeID AND IMIdentifier=@IMIdentifier
- @Verified=1: mark as verified (IM handle belongs to customer)
- @Verified=0: mark as unverified
- Silent no-op if no matching row found
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
| 3 | @IMIdentifier | VARCHAR(255) | NO | - | CODE-BACKED | IM account identifier of the row to update. Must exactly match the stored value. |
| 4 | @Verified | BIT | NO | - | CODE-BACKED | New verification state. 1=verified (IM handle confirmed to belong to customer), 0=unverified. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 5 | RETURN | INT | 0=success. Non-zero SQL error code on failure. Legacy pattern. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @IMTypeID + @IMIdentifier | BackOffice.CustomerToIMType | UPDATE | Sets Verified flag on the matching IM account row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice IM verification flow | External | Deprecated - no active callers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerIMVerify_Del (procedure)
|- BackOffice.CustomerToIMType (table) [UPDATE: Verified flag]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToIMType | Table | UPDATE: sets Verified on the specified IM account |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Legacy BackOffice IM verification flow | External | Deprecated - no active callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN @@ERROR | Design | Legacy error-return pattern |
| No existence check | Design | Silent no-op if matching row not found |
| _Del designation | Lifecycle | Marked for deletion; feature decommissioned |

---

## 8. Sample Queries

### 8.1 Mark a customer's Skype handle as verified

```sql
DECLARE @Ret INT;
EXEC @Ret = BackOffice.CustomerIMVerify_Del
    @CID = 12345,
    @IMTypeID = 4,
    @IMIdentifier = 'john.smith.trading',
    @Verified = 1;
SELECT @Ret AS ReturnCode;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerIMVerify_Del | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerIMVerify_Del.sql*
