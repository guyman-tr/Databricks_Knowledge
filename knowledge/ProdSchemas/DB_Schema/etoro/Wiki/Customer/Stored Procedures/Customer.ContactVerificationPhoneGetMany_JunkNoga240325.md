# Customer.ContactVerificationPhoneGetMany_JunkNoga240325

> Batch lookup procedure that retrieves phone verification details for a list of GCIDs, returning the most current phone number, verification status, verification date, and risk score for each customer, by combining CustomerStatic, BackOffice.Customer, and the phone verification details table.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCIDs (table-valued parameter - list of GCIDs to look up) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.ContactVerificationPhoneGetMany_JunkNoga240325 is the phone verification data retrieval procedure for the Contact Verification service. It accepts a list of GCIDs and returns the current phone verification state for each - the phone number (from verification records, falling back to the CustomerStatic raw phone), verification outcome ID, verification date, country code, and risk score from the third-party provider.

This procedure exists as a batch-efficient alternative to querying the three source tables individually. The Contact Verification service (SQL_ContactVerificationService permission user) needs to check whether a set of customers already have a verified phone number and what their risk profile is, before initiating or approving a new phone verification step. The two ISNULL fallback patterns are critical: PhoneNumber prefers the dedicated verification record over the raw CustomerStatic.Phone field; PhoneVerifiedID prefers the verification table's value over the BackOffice.Customer fallback.

Note: The SP references `Customer.PhoneVerificationDetails` without the "_JunkNoga0725" suffix. In production, this is the active phone verification table - the SSDT version is `Customer.PhoneVerificationDetails_JunkNoga0725`, which appears to be the physical table renamed in July 2025. The SP was created in October 2023 as a "temp solution to fix bug" (per comment) but has since become the primary phone data retrieval endpoint for the Contact Verification service, enriched with ONBRD-7931 (RiskInfoScore added by Boris K & Noga).

---

## 2. Business Logic

### 2.1 Phone Number Fallback Chain

**What**: The returned PhoneNumber uses a priority cascade to return the best available number.

**Columns/Parameters Involved**: `pvd.PhoneNumber`, `cc.Phone`, `PhoneNumber` (output)

**Rules**:
- If a verification record exists (LEFT JOIN found a match on CID with PhoneVerifiedID in (1,2)): use pvd.PhoneNumber (the verified phone)
- If no verification record: fall back to cc.Phone (raw phone from CustomerStatic)
- Result: always returns SOMETHING as PhoneNumber (unless both are NULL)

**Diagram**:
```
pvd.PhoneNumber != NULL?
  YES -> return pvd.PhoneNumber  (verified phone record)
  NO  -> return cc.Phone         (raw CustomerStatic phone fallback)
```

### 2.2 PhoneVerifiedID Fallback Chain

**What**: The verification status comes from the dedicated table first, then falls back to BackOffice.

**Columns/Parameters Involved**: `pvd.PhoneVerifiedID`, `boc.PhoneVerifiedID`, `PhoneVerifiedID` (output)

**Rules**:
- If pvd.PhoneVerifiedID is not NULL (verification record joined): use verification table's value
- If NULL (no record): fall back to BackOffice.Customer.PhoneVerifiedID
- This allows BackOffice to hold a verification status for customers who were verified through a legacy flow not captured in the dedicated table

### 2.3 PhoneVerifiedID Filter (1, 2)

**What**: The LEFT JOIN to PhoneVerificationDetails filters to specific verification status values.

**Rules**:
- Only PhoneVerifiedID values 1 or 2 are joined - these represent specific verification states
- PhoneVerified values: 0=unverified (default, excluded), 1 and 2 represent specific intermediate/positive states, 3=verified (excluded from this SP's LEFT JOIN)
- The filter means this SP is retrieving customers with specific non-default, non-final verification records
- Customers with PhoneVerifiedID=3 (fully verified) would appear with NULL for pvd columns and fall back to BackOffice.Customer for the PhoneVerifiedID output

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCIDs | dbo.IdIntList READONLY | NO | - | CODE-BACKED | Table-valued parameter: list of GCID integers to look up. dbo.IdIntList is a system-wide UDT for integer ID lists. The SP JOINs on GCID = ID to filter CustomerStatic. |

**Output columns (result set):**

| # | Element | Source | Nullable | Confidence | Description |
|---|---------|--------|----------|------------|-------------|
| 1 | GCID | Customer.CustomerStatic.GCID | NO | CODE-BACKED | Group Customer ID - the cross-product identity key. Matches the input @GCIDs list. From CustomerStatic, guaranteed non-null per the JOIN. |
| 2 | PhoneNumber | ISNULL(pvd.PhoneNumber, cc.Phone) | YES | VERIFIED | The customer's most current phone number. Prefers the dedicated phone verification record over CustomerStatic.Phone. NULL only if both sources are NULL. Dynamic Data Masking applies to PhoneNumber in the source table. |
| 3 | CountryID | pvd.CountryID | YES | CODE-BACKED | Country code associated with the phone verification record. NULL if no verification record (LEFT JOIN missed). From Customer.PhoneVerificationDetails. |
| 4 | PhoneVerifiedID | ISNULL(pvd.PhoneVerifiedID, boc.PhoneVerifiedID) | YES | VERIFIED | Verification status ID. Prefers PhoneVerificationDetails value; falls back to BackOffice.Customer.PhoneVerifiedID. See Dictionary.PhoneVerified for value meanings (0=unverified, 3=verified). |
| 5 | VerifacationDate | pvd.VerifacationDate | YES | CODE-BACKED | Date/time the phone was verified. NULL if no verification record. Note: column name typo ("VerifacationDate" instead of "VerificationDate") inherited from Customer.PhoneVerificationDetails_JunkNoga0725. |
| 6 | RiskInfoScore | pvd.RiskInfoScore | YES | VERIFIED | Numeric risk score from the third-party phone verification provider. NULL if no verification record or risk scoring not performed. Added per ONBRD-7931 (Boris K & Noga). From Customer.PhoneVerificationDetails_JunkNoga0725 - see Section 4 of that doc for full risk score context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCIDs.ID = cc.GCID | Customer.CustomerStatic | JOIN (read) | Resolves GCIDs to CIDs and retrieves Phone fallback |
| cc.CID = boc.CID | BackOffice.Customer | JOIN (read) | Retrieves PhoneVerifiedID fallback from BackOffice |
| pvd.CID = cc.CID, PhoneVerifiedID in (1,2) | Customer.PhoneVerificationDetails (prod) / Customer.PhoneVerificationDetails_JunkNoga0725 (SSDT) | LEFT JOIN (read) | Retrieves verified phone data, risk score, and verification date |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ContactVerificationService role | EXECUTE permission | Caller | Called by the Contact Verification service to batch-retrieve phone verification status before initiating new verifications |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.ContactVerificationPhoneGetMany_JunkNoga240325 (procedure)
├── Customer.CustomerStatic (table)
├── BackOffice.Customer (table - cross-schema)
└── Customer.PhoneVerificationDetails (prod table) /
    Customer.PhoneVerificationDetails_JunkNoga0725 (SSDT - table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | INNER JOIN on GCID - primary driver; retrieves CID and Phone fallback |
| BackOffice.Customer | Table | INNER JOIN on CID - PhoneVerifiedID fallback value |
| Customer.PhoneVerificationDetails (SSDT: _JunkNoga0725) | Table | LEFT JOIN on CID (PhoneVerifiedID in (1,2)) - verification phone, status, date, risk score |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ContactVerificationService | External caller | Batch phone verification status retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Setting | Suppresses row count messages - improves performance for the calling service |
| PhoneVerifiedID in (1,2) | JOIN filter | Restricts LEFT JOIN to specific verification status values; excludes 0 (unverified) and 3 (fully verified) |

---

## 8. Sample Queries

### 8.1 Look up phone verification status for a set of customers (batch call simulation)

```sql
DECLARE @gcids dbo.IdIntList
INSERT @gcids VALUES (12345678), (23456789), (34567890)
EXEC Customer.ContactVerificationPhoneGetMany_JunkNoga240325 @GCIDs = @gcids
```

### 8.2 Find customers returned by this SP who have a risk score

```sql
SELECT
    cc.GCID,
    ISNULL(pvd.PhoneNumber, cc.Phone) AS PhoneNumber,
    pvd.CountryID,
    ISNULL(pvd.PhoneVerifiedID, boc.PhoneVerifiedID) AS PhoneVerifiedID,
    pvd.VerifacationDate,
    pvd.RiskInfoScore
FROM Customer.CustomerStatic AS cc WITH (NOLOCK)
INNER JOIN BackOffice.Customer AS boc WITH (NOLOCK) ON boc.CID = cc.CID
LEFT JOIN Customer.PhoneVerificationDetails_JunkNoga0725 AS pvd WITH (NOLOCK)
    ON pvd.CID = cc.CID AND pvd.PhoneVerifiedID IN (1, 2)
WHERE pvd.RiskInfoScore IS NOT NULL
ORDER BY pvd.RiskInfoScore DESC
```

### 8.3 Check which customers have no verification record (fallback to BackOffice only)

```sql
SELECT
    cc.GCID,
    cc.Phone AS FallbackPhone,
    boc.PhoneVerifiedID AS FallbackPhoneVerifiedID
FROM Customer.CustomerStatic AS cc WITH (NOLOCK)
INNER JOIN BackOffice.Customer AS boc WITH (NOLOCK) ON boc.CID = cc.CID
LEFT JOIN Customer.PhoneVerificationDetails_JunkNoga0725 AS pvd WITH (NOLOCK)
    ON pvd.CID = cc.CID AND pvd.PhoneVerifiedID IN (1, 2)
WHERE pvd.CID IS NULL
ORDER BY cc.GCID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [ONBRD-7931](https://etoro-jira.atlassian.net/browse/ONBRD-7931) | Jira | RiskInfoScore column added to output by Boris K & Noga - risk scoring added to phone verification lookup |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.ContactVerificationPhoneGetMany_JunkNoga240325 | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.ContactVerificationPhoneGetMany_JunkNoga240325.sql*
