# Customer.FailedRAFCompensation

> Error capture table for RAF (Refer-a-Friend) compensation failures: records referring/referred CID pairs where Customer.SetRafCompensation encountered an exception during balance award, enabling manual investigation and re-processing.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (clustered PK, fillfactor=95) |

---

## 1. Business Meaning

Customer.FailedRAFCompensation is the exception log for the RAF (Refer-a-Friend) compensation pipeline. When Customer.SetRafCompensation attempts to award a bonus to the referring and/or referred customer but encounters an error (database exception, deadlock, constraint violation), the CATCH block records the failing CID pair here with IsFixed=0 (unfixed).

Operations teams or automated jobs then inspect this table for unresolved failures (IsFixed=0), investigate the cause, and either manually reprocess the compensation or mark the row as fixed (IsFixed=1) once resolved.

80 rows currently, all involving the same CID pair (10908497 / 10908498 and nearby CIDs), suggesting a repeated failure for a specific customer relationship - possibly a configuration issue or data integrity problem for this referral chain. The FailueDate column (note: deliberate typo in the column name) is NULL in all 80 rows despite the procedure setting GETUTCDATE() at insert time, which may indicate the 80 rows were loaded via a different path or the timestamp was added to the procedure after this data was inserted.

The PK name `PK_BillingFailedARFCompensation` (note: ARF vs RAF) indicates this table was originally in the Billing schema or built by the billing team before being moved to the Customer schema.

---

## 2. Business Logic

### 2.1 Exception Capture in SetRafCompensation

**What**: Customer.SetRafCompensation inserts into this table only in its CATCH block - this table only receives rows when compensation awards fail.

**Columns/Parameters Involved**: `ReferringCID`, `ReferredCID`, `IsFixed`, `FailueDate`

**Rules**:
- Row inserted when: Customer.SetBalanceCompensation raises an error during the RAF bonus transaction
- IsFixed=0 on insert (default): indicates unresolved failure awaiting remediation
- IsFixed=1: manually set by operations when the failure has been investigated and resolved
- FailueDate: should be GETUTCDATE() at insert time per procedure code; NULL values in current data suggest historical load or earlier procedure version
- Return code 5 ("Failed to give RAF") is raised by SetRafCompensation when this CATCH path executes
- The procedure also handles return code 3 ("compensation already given") via the same catch path - distinguishes between actual failures (5) and duplicate attempts (3) using @ErrOut

### 2.2 Manual Remediation Pattern

**What**: IsFixed flag enables operational workflow - find all IsFixed=0 rows and manually re-trigger compensation for those pairs.

**Rules**:
- Standard remediation: query WHERE IsFixed=0, investigate reason, re-run SetRafCompensation or manual SetBalanceCompensation, then UPDATE IsFixed=1
- No automated re-processing logic found in SSDT - this is a manual queue

---

## 3. Data Overview

| ID | ReferringCID | ReferredCID | IsFixed | FailueDate | Meaning |
|---|---|---|---|---|---|
| 80 | 10908497 | 10908498 | 0 | NULL | Repeated failure: same CID pair appears in all 80 rows - compensation for this referral pair failed 80 times |
| 79 | 10908497 | 10908498 | 0 | NULL | Same pair - suggests a persistent data/config issue for this specific referral relationship |

*80 total rows. All IsFixed=0 (none resolved). All involve the same or adjacent CID pairs around 10908497-10908498. FailueDate=NULL for all rows.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-increment surrogate PK. NOT FOR REPLICATION prevents identity seed firing during replication. |
| 2 | ReferringCID | int | NO | - | CODE-BACKED | CID of the customer who made the referral (the referrer). The customer who should receive the referring compensation. |
| 3 | ReferredCID | int | NO | - | CODE-BACKED | CID of the customer who was referred (the referred/new customer). The customer who should receive the referred compensation. |
| 4 | IsFixed | int | NO | 0 | CODE-BACKED | Resolution status: 0=unresolved (awaiting investigation), 1=fixed (manually resolved). Default=0. |
| 5 | FailueDate | datetime | YES | - | CODE-BACKED | Timestamp when the failure was recorded. Nullable; set to GETUTCDATE() by Customer.SetRafCompensation. Note: column name has a typo ("FailueDate" instead of "FailureDate"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReferringCID | Customer.CustomerStatic | Implicit | Referrer customer; no FK constraint |
| ReferredCID | Customer.CustomerStatic | Implicit | Referred customer; no FK constraint |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetRafCompensation | ReferringCID, ReferredCID | WRITER | Inserts on CATCH - records compensation failures |

---

## 6. Dependencies

No FK dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingFailedARFCompensation | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingFailedARFCompensation | PRIMARY KEY | ID unique (note: ARF typo in constraint name vs RAF table name) |
| DF_BillingFailedRAFCompensationIsFixed | DEFAULT | IsFixed = 0 - all failures start as unresolved |

---

## 8. Sample Queries

### 8.1 Find all unresolved RAF compensation failures

```sql
SELECT
    ID,
    ReferringCID,
    ReferredCID,
    IsFixed,
    FailueDate
FROM Customer.FailedRAFCompensation WITH (NOLOCK)
WHERE IsFixed = 0
ORDER BY ID DESC
```

### 8.2 Check if a specific referral pair has failures

```sql
SELECT COUNT(*) AS FailureCount
FROM Customer.FailedRAFCompensation WITH (NOLOCK)
WHERE ReferringCID = 10908497
  AND ReferredCID = 10908498
  AND IsFixed = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.FailedRAFCompensation | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.FailedRAFCompensation.sql*
