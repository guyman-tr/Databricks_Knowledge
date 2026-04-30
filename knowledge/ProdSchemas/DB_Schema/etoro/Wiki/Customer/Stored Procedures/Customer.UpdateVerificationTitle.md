# Customer.UpdateVerificationTitle

> Updates the KYC verification title on Customer.CustomerStatic using optimistic concurrency: only succeeds if the caller's version GUID matches the current value, preventing concurrent overwrites in multi-user admin tools.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Customer.CustomerStatic by VerificationTitleVersion (optimistic concurrency key); returns Success (BIT) and updated VerificationTitleVersion via OUTPUT parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateVerificationTitle allows BackOffice operators or automated KYC processes to update the VerificationTitle field on a customer's CustomerStatic record. VerificationTitle is a short (up to 50 char) text label that represents the customer's KYC verification status or tier - it is distinct from the numeric VerificationLevelID; it is a human-readable classification like "Standard", "Enhanced", or a custom label used in compliance tools.

The procedure implements the classic optimistic concurrency pattern to prevent lost updates in environments where multiple operators may update the same customer's record simultaneously. The caller must supply the GUID version they last read. If the database's version still matches, the update succeeds and a new version GUID is issued. If it has been changed by another process since the caller read it, the WHERE clause returns 0 rows and @Success = 0, signaling the caller to re-read and retry.

Data flows: Customer.GetVerificationTitle reads the current VerificationTitle and VerificationTitleVersion from CustomerStatic (via the Customer view). The caller modifies the title and calls this procedure with the version they read. Every successful update is captured in History.Customer via the CustomerVersionUpdate trigger on CustomerStatic.

---

## 2. Business Logic

### 2.1 Optimistic Concurrency via Version GUID

**What**: The VerificationTitleVersion GUID acts as a row version token. The caller must present the version they last observed; if it no longer matches (another update occurred), the procedure fails safely.

**Columns/Parameters Involved**: `@VerificationTitleVersion` (IN/OUT), `@VerificationTitle`, `@Success`, CustomerStatic.VerificationTitleVersion

**Rules**:
- @VerificationTitleVersion INPUT: the version GUID the caller last read from CustomerStatic. Used in WHERE clause.
- UPDATE WHERE VerificationTitleVersion = @VerificationTitleVersion: only succeeds if no other update occurred since the caller read the record
- On success (@@ROWCOUNT = 1):
  - CustomerStatic.VerificationTitleVersion = new NEWID() (fresh GUID issued)
  - @VerificationTitleVersion OUTPUT = that new GUID (caller receives the new token for any future update)
  - @Success = 1
- On failure (@@ROWCOUNT = 0, concurrent update detected):
  - @VerificationTitleVersion is NOT updated (still holds the old value the caller passed in)
  - @Success = 0
  - Caller should re-read, get the new version, and retry if appropriate
- History.Customer is updated via the CustomerVersionUpdate trigger on CustomerStatic (every successful UPDATE triggers a new version row)

**Diagram**:
```
Caller reads CustomerStatic:
  VerificationTitle = "Standard"
  VerificationTitleVersion = GUID_A
         |
         v
EXEC Customer.UpdateVerificationTitle
  @VerificationTitleVersion = GUID_A (IN/OUT)
  @VerificationTitle = "Enhanced"
  @Success OUTPUT
         |
         v
UPDATE CustomerStatic
  SET VerificationTitle = "Enhanced"
      VerificationTitleVersion = NEW_GUID_B
  WHERE VerificationTitleVersion = GUID_A
         |
   +-----------+
   |           |
@@ROWCOUNT=1  @@ROWCOUNT=0
(matched)     (concurrent update)
   |           |
@Success=1    @Success=0
@VTV = NEW_GUID_B  @VTV unchanged (still GUID_A)
History.Customer row added
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @VerificationTitleVersion | UNIQUEIDENTIFIER | NO | - | VERIFIED | Dual-role parameter: INPUT = the version GUID the caller last read from CustomerStatic.VerificationTitleVersion (optimistic concurrency token, used in WHERE clause). OUTPUT = the new GUID assigned if the update succeeds (caller should save this for any future updates). If @Success=0, the OUTPUT value is unchanged from INPUT (the old GUID). |
| 2 | @VerificationTitle | NVARCHAR(50) | NO | - | VERIFIED | The new KYC verification title text to write to CustomerStatic.VerificationTitle. Max 50 chars (matches column definition). Typically a compliance classification label such as "Standard", "Enhanced", or a custom tier name. Change is versioned in History.Customer via CustomerVersionUpdate trigger. |
| 3 | @Success | BIT | NO | - | VERIFIED | OUTPUT parameter indicating whether the update succeeded. 1 = update applied (VerificationTitleVersion matched, record updated, new GUID issued). 0 = update failed (VerificationTitleVersion did not match - concurrent modification detected; caller should re-read and retry). Initialized to 0 at the start of the procedure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @VerificationTitleVersion | Customer.CustomerStatic | MODIFIER | Updates VerificationTitle and issues new VerificationTitleVersion on successful concurrency check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.GetVerificationTitle | VerificationTitle, VerificationTitleVersion | Companion reader | Reads the current VerificationTitle and VerificationTitleVersion that callers need before invoking this procedure |
| (BackOffice / KYC application layer) | - | Caller | Called by compliance tools and automated KYC workflows to update the title after reading the current version via GetVerificationTitle |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateVerificationTitle (procedure)
└── Customer.CustomerStatic (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | UPDATE target - sets VerificationTitle and VerificationTitleVersion WHERE VerificationTitleVersion matches |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.GetVerificationTitle | Stored Procedure | Companion reader - callers use GetVerificationTitle first, then pass the version to this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Update verification title with concurrency check

```sql
DECLARE @version UNIQUEIDENTIFIER;
DECLARE @success BIT;

-- Step 1: Read current version
SELECT @version = VerificationTitleVersion
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE GCID = 12345678;

-- Step 2: Attempt update
EXEC Customer.UpdateVerificationTitle
    @VerificationTitleVersion = @version OUTPUT,
    @VerificationTitle = N'Enhanced',
    @Success = @success OUTPUT;

SELECT @success AS UpdateSucceeded, @version AS NewVersionIfSucceeded;
```

### 8.2 Check current verification title for a customer

```sql
SELECT
    cs.CID,
    cs.GCID,
    cs.VerificationTitle,
    cs.VerificationTitleVersion
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.GCID = 12345678;
```

### 8.3 View verification title change history for a customer

```sql
SELECT
    h.ValidFrom,
    h.ValidTo,
    h.VerificationTitle,
    h.VerificationTitleVersion
FROM History.Customer h WITH (NOLOCK)
WHERE h.CID = (
    SELECT CID FROM Customer.CustomerStatic WITH (NOLOCK) WHERE GCID = 12345678
)
ORDER BY h.ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.UpdateVerificationTitle | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateVerificationTitle.sql*
