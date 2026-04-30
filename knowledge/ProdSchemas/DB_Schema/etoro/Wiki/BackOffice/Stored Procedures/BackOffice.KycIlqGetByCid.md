# BackOffice.KycIlqGetByCid

> Returns all columns from Customer.Customer LEFT JOINed with BackOffice.KYC for a given CID - the full view of a customer's core profile and ILQ KYC data combined.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer ID); returns Customer.Customer + BackOffice.KYC columns |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`KycIlqGetByCid` retrieves the complete customer profile used by the US KYC ILQ form - combining the base customer record from `Customer.Customer` with the full ILQ regulatory dataset from `BackOffice.KYC` in a single result. Created by Amir Moualem in 2012 as part of the US KYC ILQ system.

The LEFT OUTER JOIN means this procedure always returns a row if the CID exists in `Customer.Customer`, even if no ILQ KYC record has been submitted yet (BackOffice.KYC columns will be NULL). This is intentional: the form needs to pre-fill customer basics (name, address) even before the full ILQ is completed.

The Back Office KYC management UI uses this to display and pre-populate the ILQ form for review, editing, or re-submission. The `SELECT TOP 1 *` pattern returns all columns from both tables without specifying individual columns.

---

## 2. Business Logic

### 2.1 Customer + KYC Combined Lookup

**What**: Left-joins the primary customer record with the ILQ KYC record for the given CID.

**Columns/Parameters Involved**: `@CID`, `Customer.Customer.CID`, `BackOffice.KYC.CID`

**Rules**:
- `SELECT TOP 1 * FROM Customer.Customer t1 LEFT OUTER JOIN BackOffice.KYC t2 ON t1.CID = t2.CID WHERE t1.CID = @CID`
- LEFT OUTER JOIN: returns customer row even if no BackOffice.KYC record exists (KYC columns = NULL)
- TOP 1: defensive guard in case of duplicate CIDs (should not occur due to PK constraints)
- WITH (NOLOCK) on both tables: dirty read
- `SELECT *`: returns all columns from both Customer.Customer and BackOffice.KYC

**Diagram**:
```
@CID
  |
  v
Customer.Customer (CID = @CID)
  |
  LEFT OUTER JOIN BackOffice.KYC (t1.CID = t2.CID)
  |
  SELECT TOP 1 * (all Customer + all KYC columns)
  --> Customer always returned; KYC columns NULL if not yet submitted
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | BIGINT | NO | - | CODE-BACKED | Customer ID to look up. Must exist in Customer.Customer for a row to be returned. |

**Output (result set):**

All columns from `Customer.Customer` followed by all columns from `BackOffice.KYC` (SELECT *). KYC columns will be NULL if no ILQ record has been submitted for this CID. Key columns include:

- From Customer.Customer: CID, FirstName, LastName, UserName, Email, BirthDate, Gender, Address, City, Zip, Phone, RegulationID, VerificationLevelID, etc.
- From BackOffice.KYC: CID, ManagerID, Title, Citizenship, SocialSecurityNumber, DriversLicenseOrStateIdCard, IssuingState, EmploymentStatus, Income, NetWorth, LiquidAssets, HasFiledBankruptcy, agreement flags, Signature, UpdateDate, etc.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Lookup | Primary customer record (anchor of the LEFT JOIN) |
| @CID | BackOffice.KYC | Lookup (LEFT JOIN) | ILQ KYC data; NULL columns if not yet submitted |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.KycIlqGetByCid (procedure)
├── Customer.Customer (table) [SELECT anchor - WHERE CID = @CID]
└── BackOffice.KYC (table) [LEFT OUTER JOIN on CID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Anchor table - WHERE CID = @CID filter |
| BackOffice.KYC | Table | LEFT OUTER JOIN to retrieve ILQ KYC data (NULL if not submitted) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by KYC form service to pre-fill and display ILQ data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| WITH (NOLOCK) on both tables | Query hint | Dirty reads - in-flight KYC submissions may not be visible |
| LEFT OUTER JOIN | Design | Returns customer row even if no KYC record exists yet |
| TOP 1 | Defensive | Guards against duplicate CID rows (should not occur with PK) |
| SELECT * | Design | Returns all columns from both tables without column enumeration |

---

## 8. Sample Queries

### 8.1 Get customer ILQ data by CID

```sql
EXEC [BackOffice].[KycIlqGetByCid] @CID = 12345;
-- Returns: all Customer.Customer columns + all BackOffice.KYC columns
-- KYC columns are NULL if no ILQ has been submitted
```

### 8.2 Check KYC submission status for a customer

```sql
SELECT
    c.CID,
    c.FirstName, c.LastName,
    c.VerificationLevelID,
    CASE WHEN k.CID IS NULL THEN 'No ILQ submitted' ELSE 'ILQ on file' END AS KycStatus,
    k.UpdateDate AS KycLastUpdated
FROM Customer.Customer c WITH (NOLOCK)
LEFT OUTER JOIN BackOffice.KYC k WITH (NOLOCK) ON k.CID = c.CID
WHERE c.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 7.5/10, Logic: 7.5/10, Relationships: 7.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.KycIlqGetByCid | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.KycIlqGetByCid.sql*
