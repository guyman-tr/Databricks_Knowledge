# BackOffice.CustomerGetVerificationLevelID

> Returns a customer's current VerificationLevelID from BackOffice.Customer via an OUTPUT parameter. Used to check the KYC verification tier for a customer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the `VerificationLevelID` for a customer from `BackOffice.Customer` and returns it via an OUTPUT parameter. It is used to check what KYC verification tier a customer has reached - determining which trading features and withdrawal limits are available to them.

`VerificationLevelID` is a core KYC/compliance field that controls the customer's access to trading products and cashout capabilities. Customers progress through verification levels as they submit and have documents approved. Higher levels unlock larger withdrawal amounts, access to more instruments, and reduced trading restrictions.

Uses `WITH(NOLOCK)` for non-blocking reads - appropriate for a read-only status check where a slightly stale result is acceptable.

Created by Amir Moualem, October 2012. Not marked JUNK - still active.

---

## 2. Business Logic

### 2.1 Simple Scalar Lookup via OUTPUT Parameter

**What**: Retrieves VerificationLevelID for a CID with NOLOCK. If CID not found, @VerificationLevelID remains NULL.

**Rules**:
- SELECT @VerificationLevelID = VerificationLevelID FROM BackOffice.Customer WITH(NOLOCK) WHERE CID=@CID
- WITH(NOLOCK): dirty reads permitted - non-blocking read for status check
- SET NOCOUNT ON: no row count messages
- No error handling: if CID not found, @VerificationLevelID = NULL (no exception raised)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Must exist in BackOffice.Customer. If not found, @VerificationLevelID OUTPUT remains NULL. |

**Output Parameters:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 2 | @VerificationLevelID | INT OUT | YES | CODE-BACKED | Current VerificationLevelID for the customer. NULL if CID not found or VerificationLevelID IS NULL. Controls KYC tier: higher values = more verified, more trading access. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | SELECT (NOLOCK) | Reads VerificationLevelID for the given CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice KYC workflow services | External | Direct call | Check verification level before gating features or computing allowed actions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerGetVerificationLevelID (procedure)
|- BackOffice.Customer (table) [SELECT NOLOCK: VerificationLevelID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | SELECT: reads VerificationLevelID for given CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC workflow services | External | Retrieve verification tier for feature gating |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH(NOLOCK) | Concurrency | Dirty reads permitted - prevents blocking on Customer table |
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| No error handling | Design | If CID not found, OUTPUT = NULL (no exception) |

---

## 8. Sample Queries

### 8.1 Get verification level for a customer

```sql
DECLARE @VLevel INT;
EXEC BackOffice.CustomerGetVerificationLevelID
    @CID = 12345,
    @VerificationLevelID = @VLevel OUTPUT;
SELECT @VLevel AS VerificationLevelID;
-- NULL = CID not found OR level not set
```

### 8.2 Direct query equivalent

```sql
SELECT CID, VerificationLevelID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerGetVerificationLevelID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerGetVerificationLevelID.sql*
