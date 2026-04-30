# BackOffice.CustomerIMDetailAdd_Del

> Adds an Instant Messaging (IM) account identifier for a customer to BackOffice.CustomerToIMType. Legacy/deprecated (_Del suffix). Returns @@ERROR (0=success).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @IMTypeID + @IMIdentifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure adds a customer's Instant Messaging handle (e.g., Skype username, Google Talk address) to `BackOffice.CustomerToIMType`. It was used when BackOffice agents or customers registered their IM accounts for contact purposes.

The `_Del` suffix on both this procedure and its sibling SPs indicates they are marked for deletion as part of the decommissioning of the IM contact feature. The IM platform landscape has changed dramatically since this feature was built: Google Talk (IMTypeID=3) was shut down in 2013, Windows Live Messenger in 2013, and Yahoo! Messenger in 2018. Only Skype (IMTypeID=4) remains active.

The procedure contains no duplicate check - if the same (CID, IMTypeID, IMIdentifier) already exists, it will raise a primary key violation (the table has a composite PK on those three columns).

Uses legacy `RETURN @@ERROR` error pattern - no TRY/CATCH.

---

## 2. Business Logic

### 2.1 Simple Insert with Legacy Error Return

**What**: Inserts one IM account row. Returns 0 on success, SQL error number on failure.

**Rules**:
- INSERT INTO BackOffice.CustomerToIMType (CID, IMTypeID, IMIdentifier) VALUES (@CID, @IMTypeID, @IMIdentifier)
- RETURN @@ERROR: 0 = success, non-zero = SQL error code
- No duplicate check: PK violation if same (CID, IMTypeID, IMIdentifier) already exists
- New rows are inserted with Verified=NULL/default (not verified)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. FK to BackOffice.Customer. |
| 2 | @IMTypeID | INT | NO | - | CODE-BACKED | IM platform type. FK to Dictionary.IMType_Del. Known values: 1=Windows Live Messenger, 2=Yahoo! Messenger, 3=Google Talk, 4=Skype, 5=ICQ. |
| 3 | @IMIdentifier | VARCHAR(255) | NO | - | CODE-BACKED | Customer's IM account identifier (username, email, or handle) on the specified IM platform. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 4 | RETURN | INT | 0 = success (@@ERROR = 0). Non-zero SQL error code on failure. Legacy pattern - no RAISERROR. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @IMTypeID + @IMIdentifier | BackOffice.CustomerToIMType | INSERT | Adds a new IM account registration row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice IM registration UI | External | Direct call - deprecated | Called when a customer registered an IM account (feature decommissioned) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerIMDetailAdd_Del (procedure)
|- BackOffice.CustomerToIMType (table) [INSERT]
   Note: table documented as BackOffice.CustomerToIMType_Del in SSDT/wiki (filename carries _Del suffix)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToIMType | Table | INSERT: adds IM account record (table SSDT filename: BackOffice.CustomerToIMType_Del) |

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
| RETURN @@ERROR | Design | Legacy error-return pattern; 0=success, non-zero=SQL error code |
| No duplicate check | Design | PK violation if same (CID, IMTypeID, IMIdentifier) combo already exists |
| _Del designation | Lifecycle | Marked for deletion; feature decommissioned |

---

## 8. Sample Queries

### 8.1 Add a Skype IM handle for a customer (legacy)

```sql
DECLARE @Ret INT;
EXEC @Ret = BackOffice.CustomerIMDetailAdd_Del
    @CID = 12345,
    @IMTypeID = 4,             -- Skype
    @IMIdentifier = 'john.smith.trading';
SELECT @Ret AS ReturnCode; -- 0 = success
```

### 8.2 Check existing IM registrations

```sql
SELECT CID, IMTypeID, IMIdentifier, Verified
FROM BackOffice.CustomerToIMType WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerIMDetailAdd_Del | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerIMDetailAdd_Del.sql*
