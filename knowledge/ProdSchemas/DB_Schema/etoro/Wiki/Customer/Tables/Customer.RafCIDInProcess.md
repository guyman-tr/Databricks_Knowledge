# Customer.RafCIDInProcess

> Concurrency lock table for the RAF compensation pipeline: a CID present here means that customer's compensation is currently being processed, preventing duplicate concurrent awards.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID (bigint, PK) |
| **Partition** | No (DICTIONARY filegroup) |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

Customer.RafCIDInProcess acts as an application-level mutex for the RAF compensation process. When Customer.SetRafCompensation begins processing compensation for a referrer, it immediately inserts the ReferringCID into this table. If another concurrent invocation tries to process the same ReferringCID simultaneously, the INSERT will fail with a primary key violation (error 2627), which the CATCH block detects and retries up to 6 times with 500ms delays. If all 6 retries fail, the procedure returns code 1 ("Busy - try again").

Once the compensation is awarded (or fails), SetRafCompensation DELETEs the CID from this table to release the lock.

Currently 0 rows - no RAF compensation processing in progress. The table is always empty between processing runs.

The DICTIONARY filegroup placement co-locates this with other reference/lock tables for fast row-level locking.

---

## 2. Business Logic

### 2.1 Mutex Pattern via PK Violation

**What**: INSERT success = lock acquired. PK violation = lock already held by another process.

**Columns/Parameters Involved**: `CID`

**Rules**:
- Customer.SetRafCompensation: INSERT INTO RafCIDInProcess (CID) VALUES (@ReferringCID) at the start of processing
- PK violation (ERROR_NUMBER() = 2627): another process is running for this CID -> WAITFOR 500ms, retry
- Max 6 retries: if all fail -> return 1 (Busy)
- On success (compensation given or failed): DELETE FROM RafCIDInProcess WHERE CID = @ReferringCID
- CID is bigint (not int like most CID columns) - larger type for future-proofing or compatibility with the procedure parameter types

---

## 3. Data Overview

*Customer.RafCIDInProcess is currently empty (0 rows). This is the normal state between RAF processing runs.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | bigint | NO | - | VERIFIED | Referring customer ID currently being processed. PK ensures only one concurrent process per CID. bigint (wider than the int CID in CustomerStatic - allows casting from procedure parameter). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Referring customer being locked; no FK |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetRafCompensation | CID | MUTEX WRITER | INSERT on start, DELETE on completion/failure |

---

## 6. Dependencies

No FK dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RafCIDInProcess_CID | CLUSTERED | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RafCIDInProcess_CID | PRIMARY KEY | CID must be unique - enforces the mutex; duplicate INSERT fails with error 2627 |

---

## 8. Sample Queries

### 8.1 Check for stuck locks (CIDs currently being processed)

```sql
SELECT CID
FROM Customer.RafCIDInProcess WITH (NOLOCK)
-- Should be empty between processing runs
-- Non-empty = processing in progress or stuck lock
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RafCIDInProcess | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.RafCIDInProcess.sql*
