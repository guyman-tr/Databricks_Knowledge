# BackOffice.CustomerBlackListAdd

> Adds a new entry to the BackOffice.CustomerBlackList data-value block registry, normalizing the value to lowercase before insertion to ensure case-insensitive blocking.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (@BlockedDataTypeID, @Data) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the entry point for adding new entries to the customer blacklist. The blacklist is a data-value registry that blocks re-registration and re-funding by banned users: when someone is banned, their username, email, credit card number, PayPal address, or original CID can be added here to prevent them from circumventing the ban via a new account.

The critical design detail is the `LOWER(@Data)` normalization: all blacklist entries are stored lowercase, ensuring that blocking applies regardless of the case used in future registration or deposit attempts. Callers provide the value in any case; the procedure guarantees lowercase storage. The unique index on (BlockedDataTypeID, Data) prevents duplicate entries for the same type/value combination.

BlockedDataTypeID values: 1=Username, 2=Email, 3=OriginalCID, 4=Credit Card, 5=PayPal Email.

---

## 2. Business Logic

### 2.1 Lowercase Normalization and Insert

**What**: Normalizes @Data to lowercase before inserting to ensure case-insensitive block matching.

**Columns/Parameters Involved**: `@BlockedDataTypeID`, `@Data`, `BackOffice.CustomerBlackList.Data`

**Rules**:
- INSERT INTO BackOffice.CustomerBlackList (BlockedDataTypeID, Data) VALUES (@BlockedDataTypeID, LOWER(@Data))
- @Data is always lowercased before insert - emails, usernames, card numbers all normalized to lowercase
- Duplicate (BlockedDataTypeID, Data) combination raises SQL error 2627 (unique index violation)
- Returns @@ERROR: 0 on success; 2627 on duplicate; other non-zero on failure

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BlockedDataTypeID | INTEGER | NO | - | CODE-BACKED | The type of data value being blocked. Values: 1=Username (529 entries), 2=Email (475 entries), 3=OriginalCID (430 entries), 4=Credit Card (261 entries), 5=PayPal Email (74 entries). |
| 2 | @Data | VARCHAR(250) | NO | - | CODE-BACKED | The data value to block. Stored as LOWER(@Data) - normalized to lowercase regardless of input case. Max 250 characters. Example: 'john.doe@gmail.com' (email) or '4111111111111111' (card number). |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN | INT | @@ERROR: 0 on success; 2627 if the (BlockedDataTypeID, Data) combination already exists; other non-zero SQL errors on failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BlockedDataTypeID / @Data | BackOffice.CustomerBlackList | WRITER (INSERT) | Adds new blocking entry with LOWER-normalized data value |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called from BackOffice ban/blacklist management UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerBlackListAdd (procedure)
+-- BackOffice.CustomerBlackList (table) [INSERT target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerBlackList | Table | INSERT: adds (BlockedDataTypeID, LOWER(@Data)) as new blacklist entry |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice ban management UI | External | Calls this when banning a customer to block their identifying data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| LOWER normalization | Application | LOWER(@Data) before insert - all entries stored lowercase for case-insensitive blocking at lookup time |
| Unique index guard | DB Enforced | NC unique index on (BlockedDataTypeID, Data) prevents duplicate blacklist entries; raises error 2627 on conflict |

---

## 8. Sample Queries

### 8.1 Add an email to the blacklist

```sql
DECLARE @Result INT
EXEC @Result = BackOffice.CustomerBlackListAdd
    @BlockedDataTypeID = 2,              -- 2 = Email
    @Data = 'Banned.User@example.com'    -- stored as 'banned.user@example.com'
SELECT @Result AS Result -- 0 = success
```

### 8.2 Add a credit card to the blacklist

```sql
EXEC BackOffice.CustomerBlackListAdd
    @BlockedDataTypeID = 4,          -- 4 = Credit Card
    @Data = '4111111111111111'
```

### 8.3 Verify the entry was added

```sql
SELECT BlackListID, BlockedDataTypeID, Data
FROM BackOffice.CustomerBlackList WITH (NOLOCK)
WHERE BlockedDataTypeID = 2 AND Data = 'banned.user@example.com'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerBlackListAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerBlackListAdd.sql*
