# BackOffice.CustomerSetPhoneVerified_JunkNoga240325

> JUNK/DEPRECATED - Sets a customer's phone verification status in both BackOffice.Customer and Customer.PhoneVerificationDetails simultaneously. Marked for removal (Noga, 2024-03-25).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - internal customer identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerSetPhoneVerified_JunkNoga240325 sets the phone verification result (`PhoneVerifiedID`) for a customer in two places simultaneously: the BackOffice customer profile (`BackOffice.Customer`) and the phone-specific verification record (`Customer.PhoneVerificationDetails`). The `_JunkNoga240325` suffix indicates this procedure was flagged for deletion by the developer Noga on 2024-03-25 and should be considered deprecated.

The procedure exists because phone verification state is maintained in two tables. `BackOffice.Customer.PhoneVerifiedID` is the agent-visible compliance flag, while `Customer.PhoneVerificationDetails` holds the per-phone-number verification record. An inline comment states a trigger on `BackOffice.Customer` already propagates the update to `Customer.PhoneVerificationDetails` - however, the procedure body also performs the update directly, making it redundant or belt-and-suspenders depending on the trigger's current state. The error message in the CATCH block incorrectly references `CustomerSetDocumentStatus` (copy-paste artifact).

No SQL-layer callers were found. This procedure was likely invoked from application layer or BackOffice tooling for a specific use case that is now handled differently. Its JUNK designation indicates it is no longer in active use.

---

## 2. Business Logic

### 2.1 Dual-Table Phone Verification Update

**What**: Updates PhoneVerifiedID in two locations to keep compliance and verification records in sync.

**Columns/Parameters Involved**: `@CID`, `@PhoneVerifiedID`, `BackOffice.Customer.PhoneVerifiedID`, `Customer.Customer.Phone`, `Customer.PhoneVerificationDetails.PhoneVerifiedID`

**Rules**:
- Step 1: UPDATE `BackOffice.Customer.PhoneVerifiedID = @PhoneVerifiedID` WHERE CID = @CID.
- Step 2: Fetch current phone number from `Customer.Customer` WHERE CID = @CID.
- Step 3: UPDATE `Customer.PhoneVerificationDetails.PhoneVerifiedID = @PhoneVerifiedID` WHERE CID = @CID AND PhoneNumber = @PhoneNumber (matches the specific phone record using live phone number).
- If `Customer.Customer.Phone` is NULL or the phone number does not match any row in `Customer.PhoneVerificationDetails`, the second UPDATE affects 0 rows silently.
- An inline code comment notes a trigger on `BackOffice.Customer` already handles the sync to `Customer.PhoneVerificationDetails` - making the direct second UPDATE potentially redundant.

**Diagram**:
```
EXEC CustomerSetPhoneVerified_JunkNoga240325 @CID, @PhoneVerifiedID
  |
  +--> UPDATE BackOffice.Customer SET PhoneVerifiedID = @PhoneVerifiedID WHERE CID = @CID
  |
  +--> SELECT Phone FROM Customer.Customer WHERE CID = @CID
  |
  +--> UPDATE Customer.PhoneVerificationDetails
         SET PhoneVerifiedID = @PhoneVerifiedID
         WHERE CID = @CID AND PhoneNumber = @Phone
```

### 2.2 Error Handling

**What**: TRY/CATCH block re-raises all errors as error code 60000 with a descriptive message.

**Columns/Parameters Involved**: RAISERROR(60000), @@ERROR

**Rules**:
- Any SQL error in the TRY block triggers the CATCH.
- CATCH builds an error string with line number and original error message, then raises RAISERROR(60000, 16, 1, ...).
- Error message string incorrectly says "BackOffice.CustomerSetDocumentStatus" - this is a copy-paste artifact from another procedure.
- Procedure returns 60000 on error.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Internal Customer ID. Used to target the customer's row in BackOffice.Customer, fetch their phone from Customer.Customer, and match the PhoneVerificationDetails record. |
| 2 | @PhoneVerifiedID | INTEGER | NO | - | CODE-BACKED | The phone verification result code to apply. Written to both BackOffice.Customer.PhoneVerifiedID and Customer.PhoneVerificationDetails.PhoneVerifiedID. Value meanings defined in the Dictionary layer (FK to Dictionary.PhoneVerification or similar). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Modifier | UPDATE target - sets PhoneVerifiedID on the BackOffice compliance profile. |
| @CID | Customer.Customer | Lookup | SELECT Phone to get the current phone number for matching in PhoneVerificationDetails. |
| @CID + Phone | Customer.PhoneVerificationDetails | Modifier | UPDATE target - sets PhoneVerifiedID on the phone-level verification record matching CID + PhoneNumber. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No SQL callers found | - | - | JUNK designation confirms this is no longer called from SQL layer. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetPhoneVerified_JunkNoga240325 (procedure)
├── BackOffice.Customer (table) - UPDATE PhoneVerifiedID
├── Customer.Customer (table) - SELECT Phone for lookup
└── Customer.PhoneVerificationDetails (table) - UPDATE PhoneVerifiedID by CID + PhoneNumber
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE - sets PhoneVerifiedID WHERE CID = @CID |
| Customer.Customer | Table | SELECT Phone WHERE CID = @CID - retrieves current phone number |
| Customer.PhoneVerificationDetails | Table | UPDATE - sets PhoneVerifiedID WHERE CID = @CID AND PhoneNumber = @Phone |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found | - | JUNK - no active callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH | Error handling | All errors caught and re-raised as RAISERROR(60000). Note: error message text contains a copy-paste artifact referencing "CustomerSetDocumentStatus". |
| JUNK designation | Lifecycle | Procedure is named with _JunkNoga240325 suffix - scheduled for removal, do not add new callers. |
| Trigger overlap | Behavior | A trigger on BackOffice.Customer may already sync PhoneVerifiedID to Customer.PhoneVerificationDetails, making the second UPDATE redundant. |

---

## 8. Sample Queries

### 8.1 Check current phone verification status for a customer
```sql
SELECT
    bc.CID,
    bc.PhoneVerifiedID,
    cc.Phone,
    pvd.PhoneVerifiedID AS DetailPhoneVerifiedID,
    pvd.PhoneNumber
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = bc.CID
LEFT JOIN Customer.PhoneVerificationDetails pvd WITH (NOLOCK)
    ON pvd.CID = bc.CID AND pvd.PhoneNumber = cc.Phone
WHERE bc.CID = 12345678
```

### 8.2 Find customers where the two PhoneVerifiedID values are out of sync
```sql
SELECT
    bc.CID,
    bc.PhoneVerifiedID AS BackOfficePhoneVerifiedID,
    pvd.PhoneVerifiedID AS DetailsPhoneVerifiedID,
    cc.Phone
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = bc.CID
JOIN Customer.PhoneVerificationDetails pvd WITH (NOLOCK)
    ON pvd.CID = bc.CID AND pvd.PhoneNumber = cc.Phone
WHERE bc.PhoneVerifiedID <> pvd.PhoneVerifiedID
```

### 8.3 Invoke the procedure (deprecated - use replacement procedure instead)
```sql
-- DEPRECATED: Use the non-JUNK replacement procedure
EXEC BackOffice.CustomerSetPhoneVerified_JunkNoga240325 @CID = 12345678, @PhoneVerifiedID = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure. General phone verification documentation exists in the TRAD space (Telesign integration), but no page references this procedure by name.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerSetPhoneVerified_JunkNoga240325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetPhoneVerified_JunkNoga240325.sql*
