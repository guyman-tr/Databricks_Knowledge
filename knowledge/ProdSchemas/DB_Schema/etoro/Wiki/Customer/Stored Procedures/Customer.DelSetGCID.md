# Customer.DelSetGCID

> Updates the GCID field on linked-server synonyms RealCustomers and DemoCustomers for a given CID, only if the current GCID is different from the new value - a cross-server GCID synchronization procedure with a declared but unused @DemoCID parameter.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RealCID (CID to update) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DelSetGCID propagates a GCID (Group Customer ID) assignment to two linked-server customer tables: the production real customer database (dbo.RealCustomers -> [Real].[etoro].[Customer].[Customer]) and the demo environment customer database (dbo.DemoCustomers -> [Demo].[tradonomi].[Customer].[Customer]). GCID is the cross-product identity key that links a single physical person's accounts across eToro products.

The procedure exists to support GCID assignment workflows that must synchronize identity data across server boundaries. When eToro assigns or updates a customer's GCID, both the real and demo environments must be kept consistent. Using linked-server synonyms allows this single procedure to update both databases without requiring separate connection contexts.

The "Del" prefix in the name appears to be a legacy naming artifact or abbreviation - possibly short for "Delta" (only update if different) or a developer/team prefix, not "Delete". The procedure performs no deletion.

Two notable code issues: (1) @DemoCID is declared as a parameter but never used - both UPDATE statements use @RealCID. (2) @Err is declared but never assigned or returned. These suggest legacy code that was partially updated when the demo database was added or logic was simplified.

---

## 2. Business Logic

### 2.1 Conditional GCID Update (Delta Pattern)

**What**: Updates GCID only when the value is actually changing, preventing unnecessary writes.

**Columns/Parameters Involved**: `@GCID`, `@RealCID`, `GCID` (on both linked tables)

**Rules**:
- UPDATE RealCustomers SET GCID = @GCID WHERE CID = @RealCID AND ISNULL(GCID,0) <> @GCID
- UPDATE DemoCustomers SET GCID = @GCID WHERE CID = @RealCID AND ISNULL(GCID,0) <> @GCID
- ISNULL(GCID,0): treats NULL GCID as 0 for comparison purposes (customers with no GCID set)
- Only updates if GCID is NULL or different from @GCID - idempotent pattern
- Both UPDATEs use @RealCID (not @DemoCID - the second parameter is unused)

### 2.2 Cross-Server Linked Server Access

**What**: The procedure updates tables in two separate SQL Server instances via linked servers.

**Rules**:
- dbo.RealCustomers = synonym for [Real].[etoro].[Customer].[Customer] (production real accounts)
- dbo.DemoCustomers = synonym for [Demo].[tradonomi].[Customer].[Customer] (demo environment accounts)
- Linked server calls are not wrapped in a transaction - each UPDATE is auto-committed independently
- If the first UPDATE succeeds but the second fails, there is no rollback of the first
- No error handling - errors from linked server failures propagate to the caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | The new Group Customer ID to assign. Written to GCID column on both RealCustomers and DemoCustomers for rows matching @RealCID. |
| 2 | @RealCID | INT | NO | - | CODE-BACKED | The CID of the customer to update. Used in both UPDATE WHERE CID = @RealCID clauses. Note: despite the "Real" prefix, this parameter is used for BOTH the RealCustomers and DemoCustomers updates. |
| 3 | @DemoCID | INT | NO | - | CODE-BACKED | **UNUSED PARAMETER** - declared in the procedure signature but not referenced anywhere in the procedure body. Legacy parameter, kept for backward compatibility. Pass any integer value; it has no effect. |

**No result set - no return value defined (implicit NULL).**

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RealCID | dbo.RealCustomers (synonym -> [Real].[etoro].[Customer].[Customer]) | UPDATE (linked server) | Updates GCID on real customer database |
| @RealCID | dbo.DemoCustomers (synonym -> [Demo].[tradonomi].[Customer].[Customer]) | UPDATE (linked server) | Updates GCID on demo customer database |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called during GCID assignment flows.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DelSetGCID (procedure)
├── dbo.RealCustomers (synonym -> [Real].[etoro].[Customer].[Customer])
└── dbo.DemoCustomers (synonym -> [Demo].[tradonomi].[Customer].[Customer])
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.RealCustomers | Synonym (linked server) | UPDATE GCID on real customer database ([Real].[etoro].[Customer].[Customer]) |
| dbo.DemoCustomers | Synonym (linked server) | UPDATE GCID on demo customer database ([Demo].[tradonomi].[Customer].[Customer]) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called from GCID assignment flows. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL(GCID,0) <> @GCID | Update guard | Only writes if GCID is changing; prevents unnecessary linked-server writes |
| No transaction | Design | Two independent UPDATEs - not atomic. Demo GCID can be out of sync if second UPDATE fails after first succeeds. |
| @DemoCID unused | Legacy dead code | Accepted parameter with no effect - maintained for caller compatibility |

---

## 8. Sample Queries

### 8.1 Execute GCID update across real and demo environments

```sql
EXEC Customer.DelSetGCID
    @GCID = 9876543,
    @RealCID = 12345678,
    @DemoCID = 0  -- unused, pass any value
```

### 8.2 Verify GCID is consistent across real customer records

```sql
SELECT CID, GCID
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE CID = 12345678
-- Compare with RealCustomers via linked server if accessible:
-- SELECT CID, GCID FROM RealCustomers WHERE CID = 12345678
```

### 8.3 Find customers with unset GCID (NULL) that need synchronization

```sql
SELECT CID, GCID
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE GCID IS NULL OR GCID = 0
ORDER BY CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.DelSetGCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.DelSetGCID.sql*
