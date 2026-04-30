# Customer.GDPRDeleteUser

> GDPR right-to-erasure procedure that overwrites all PII fields in CustomerStatic and History.Customer with placeholder values keyed to an ExecutionID, and on the real environment additionally scrubs UserApiDB and BackOffice tables - implementing the right to be forgotten across the eToro database stack.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (customer to erase), @ExecutionID (audit/traceability key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GDPRDeleteUser implements the GDPR Article 17 right to erasure ("right to be forgotten") for eToro customers. It overwrites all personally identifiable information (PII) fields in Customer.CustomerStatic and History.Customer with traceable placeholder values, making the fields no longer identifiable while preserving the account record structure for financial and regulatory purposes.

The procedure exists because GDPR requires that upon a customer's erasure request, all PII must be removed from the database - but eToro cannot simply DELETE the row because financial transaction records must be retained. The solution is PII-in-place overwriting: the CID, GCID, and financial data remain intact; all identity fields are replaced with `Del{FieldName}_{ExecutionID}` strings. The @ExecutionID parameter makes each erasure traceable - if two different customers were erased in the same batch, their placeholders have different @ExecutionIDs, enabling audit tracing without re-identifying the subjects.

BirthDate is handled specially: `DATEADD(m, DATEDIFF(m, 0, BirthDate), 0)` truncates to the first of the month, preserving only the month/year for potential age-related regulatory use while removing the specific day of birth.

On the real environment only (Maintenance.Feature FeatureID=22 = 1), the procedure also scrubs UserApiDB tables - the cross-product identity store, KYC answers, and social profile data (Publications Sticky and AboutMe). PhoneVerificationDetails was previously included but was disabled on 2025-03-24 per ONBRD-8506.

---

## 2. Business Logic

### 2.1 PII Field Overwriting Pattern

**What**: All PII fields are replaced with `Del{FieldName}_{ExecutionID}` placeholder strings.

**Columns/Parameters Involved**: `@ExecutionID`, all PII columns in CustomerStatic and History.Customer

**Rules**:
- UserName, FirstName, LastName, Phone, Fax, Address, Zip, City, IP, Email, Mobile, BuildingNumber: replaced with `CONCAT('Del{FieldName}_', @ExecutionID)`
- PhonePrefix, PhoneBody: replaced with literal '0'
- BirthDate: `DATEADD(m, DATEDIFF(m, 0, BirthDate), 0)` - truncated to first of month (2-Feb-1985 -> 1-Feb-1985)
- PrivacyPolicyID: set to 2 (GDPR erasure consent state)
- Same overwriting applied to History.Customer (all historical versions of the customer)

### 2.2 Real Environment Extended Scrubbing

**What**: On the real trading environment, additional tables in UserApiDB are also scrubbed.

**Columns/Parameters Involved**: `@GCID`, `@CID`, Maintenance.Feature FeatureID=22

**Rules**:
- Only executes if Maintenance.Feature FeatureID=22 = 1 (real environment)
- UserApiDB.dbo.GlobalCustomer: UserName and Email replaced
- UserApiDB.Customer.ExtendedUserField: Value replaced (current KYC/profile fields)
- UserApiDB.Customer.ExtendedUserField_History: Value replaced (historical field values)
- UserApiDB.dbo.Publications: Sticky and AboutMe cleared to empty string (social profile)
- UserApiDB.KYC.CustomerAnswers: FreeText answers replaced (if not null)
- UserApiDB.History.CustomerAnswers: FreeText replaced in history
- BackOffice.CustomerAllTimeAggregatedData_1: LastClientIp set to '127.0.0.1'
- PhoneVerificationDetails: previously scrubbed but DISABLED per ONBRD-8506 (2025-03-24)

### 2.3 GCID-Based Address, CID-Based History

**What**: The live CustomerStatic row is targeted by GCID; History is targeted by CID.

**Rules**:
- CustomerStatic UPDATE WHERE GCID = @GCID (primary identity key in that table)
- @CID resolved first: SELECT CID FROM Customer.CustomerStatic WHERE GCID = @GCID
- History.Customer UPDATE WHERE CID = @CID (history uses CID, not GCID)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Group Customer ID of the customer to erase. Used to identify the CustomerStatic row (WHERE GCID = @GCID) and to resolve @CID for History.Customer and UserApiDB. |
| 2 | @ExecutionID | INT | NO | - | CODE-BACKED | Unique identifier for this erasure execution. Used as the suffix in all placeholder values (Del{FieldName}_{ExecutionID}). Enables audit tracing - each erasure batch has a distinct ID, allowing compliance auditors to identify which batch erased which record without re-identifying the subject. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerStatic | UPDATE (PII scrub) | Overwrites all PII fields for the target customer |
| @CID | History.Customer | UPDATE (PII scrub) | Overwrites all PII fields in all historical versions |
| FeatureID=22 | Maintenance.Feature | Read | Real vs demo environment detection |
| @GCID | UserApiDB.dbo.GlobalCustomer | UPDATE (real env only) | Cross-product identity scrub |
| @GCID | UserApiDB.Customer.ExtendedUserField | UPDATE (real env only) | Extended field scrub |
| @CID | BackOffice.CustomerAllTimeAggregatedData_1 | UPDATE (real env only) | Last IP scrub |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from the GDPR erasure service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GDPRDeleteUser (procedure)
├── Customer.CustomerStatic (table - UPDATE)
├── History.Customer (table - cross-schema UPDATE)
├── Maintenance.Feature (table - cross-schema read)
├── UserApiDB.dbo.GlobalCustomer (linked database - UPDATE, real env only)
├── UserApiDB.Customer.ExtendedUserField (linked database - UPDATE, real env only)
├── UserApiDB.Customer.ExtendedUserField_History (linked database - UPDATE, real env only)
├── UserApiDB.dbo.Publications (linked database - UPDATE, real env only)
├── UserApiDB.KYC.CustomerAnswers (linked database - UPDATE, real env only)
├── UserApiDB.History.CustomerAnswers (linked database - UPDATE, real env only)
└── BackOffice.CustomerAllTimeAggregatedData_1 (table - cross-schema UPDATE, real env only)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | PII field overwriting |
| History.Customer | Table | Historical PII overwriting |
| Maintenance.Feature (FeatureID=22) | Table | Real/demo environment detection |
| BackOffice.CustomerAllTimeAggregatedData_1 | Table | LastClientIp scrub |
| UserApiDB.* | External database | Extended scrubbing on real environment |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called from GDPR erasure service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATEADD(m, DATEDIFF(m, 0, BirthDate), 0) | BirthDate pseudonymization | Truncates to first of month - removes day, preserves month/year |
| PrivacyPolicyID = 2 | Business rule | Marks the account as GDPR-erased (value 2 = erasure) |
| PhoneVerificationDetails commented out | Disabled feature | Per ONBRD-8506 (2025-03-24) - phone scrub disabled |
| No transaction wrapper | Design | Multiple UPDATEs without a transaction - partial erasure possible if error mid-procedure |

---

## 8. Sample Queries

### 8.1 Execute GDPR erasure for a customer

```sql
EXEC Customer.GDPRDeleteUser @GCID = 9876543, @ExecutionID = 20260317001
```

### 8.2 Verify erasure was applied

```sql
SELECT GCID, UserName, FirstName, LastName, Email, PrivacyPolicyID, BirthDate
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE GCID = 9876543
-- Should show: DelUserName_20260317001, DelFirstName_20260317001, PrivacyPolicyID=2
```

### 8.3 Find all erased customers (by placeholder pattern)

```sql
SELECT GCID, CID, UserName, PrivacyPolicyID, Registered
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE UserName LIKE 'DelUserName_%'
ORDER BY Registered DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [ONBRD-8506](https://etoro-jira.atlassian.net/browse/ONBRD-8506) | Jira | PhoneVerificationDetails scrubbing disabled (2025-03-24) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GDPRDeleteUser | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GDPRDeleteUser.sql*
