# BackOffice.UpdateAffiliateMetaData

> Updates the affiliate sub-serial tracking identifier for a customer across both the current and legacy customer tables, routing by GCID or real/demo flag.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID / @GCID - targets Customer.Customer (view) and legacy dbo.RealCustomers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateAffiliateMetaData` writes an affiliate sub-serial identifier (`SubSerialID`) onto a customer's record. `SubSerialID` is a varchar(1024) affiliate tracking token that links a customer to a specific affiliate sub-campaign or sub-channel - it comes from the affiliate network and is stored on the customer for attribution and commission calculation.

The procedure exists because eToro's customer data was historically stored in two parallel tables: the current `Customer.CustomerStatic` (accessed via the `Customer.Customer` view) and a legacy `dbo.RealCustomers` table. A single back-office update must propagate to both tables to ensure consistency. Without this procedure, real-money customers could have mismatched affiliate attribution between the two systems.

The routing logic determines which table(s) to update: if the customer has a valid GCID (`GCID > 0`), both tables are updated (the customer exists in both systems). If GCID is absent, the `@IsReal` flag decides: `0` = demo customer in `Customer.Customer` only, `1` = real customer in `RealCustomers` only. The SP also returns `@UpdatedID` via `SCOPE_IDENTITY()` - however, since no INSERT is performed, this will always return NULL (legacy template artifact).

---

## 2. Business Logic

### 2.1 Dual-Table Routing by GCID and Real Flag

**What**: Ensures the SubSerialID affiliate token is consistently updated in both the current and legacy customer storage systems.

**Columns/Parameters Involved**: `@GCID`, `@IsReal`, `@CID`, `@SubSerial`

**Rules**:
- If `GCID > 0`: both `Customer.Customer` and `RealCustomers` are updated for that GCID. The customer has records in both systems.
- If `GCID = 0` (or not set): only one system is updated, determined by `@IsReal`:
  - `@IsReal = 0`: demo customer - update `Customer.Customer` WHERE `CID = @CID` only.
  - `@IsReal = 1`: real-money customer in legacy system - update `RealCustomers` WHERE `CID = @CID` only.
- `RealCustomers` requires GCID to be NOT NULL in its condition (additional safety check absent from the `Customer.Customer` condition).

**Diagram**:
```
@GCID > 0?
  YES -> UPDATE Customer.Customer WHERE GCID=@GCID
         UPDATE RealCustomers     WHERE GCID=@GCID (AND GCID IS NOT NULL)
  NO  -> @IsReal=0? UPDATE Customer.Customer WHERE CID=@CID
          @IsReal=1? UPDATE RealCustomers     WHERE CID=@CID
```

### 2.2 @UpdatedID Always Returns NULL (Legacy Artifact)

**What**: The OUTPUT parameter `@UpdatedID` is set via `SCOPE_IDENTITY()` after UPDATE statements, not after an INSERT. `SCOPE_IDENTITY()` returns NULL in this context.

**Columns/Parameters Involved**: `@UpdatedID`

**Rules**:
- Callers should not rely on `@UpdatedID` for a meaningful value - it will always be NULL.
- This pattern is a copy-paste artifact from INSERT-based procedure templates (ticket 48576, 2017).
- The procedure always returns `RETURN 0` regardless of rows affected or GCID routing path.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID (integer). Used as the fallback key when GCID is absent (0). In the GCID=0 path with @IsReal=0, targets demo customer in Customer.Customer by CID. |
| 2 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. When > 0, this is the primary routing key: both Customer.Customer and RealCustomers are updated for this GCID. When = 0, routing falls back to @CID + @IsReal flag. |
| 3 | @SubSerial | varchar(1024) | NO | - | CODE-BACKED | Affiliate sub-serial identifier token. Written to `Customer.CustomerStatic.SubSerialID` (via Customer.Customer view) and `dbo.RealCustomers.SubSerialID`. Represents the affiliate sub-channel or sub-campaign attribution code. |
| 4 | @IsReal | int | NO | - | CODE-BACKED | Customer account type flag: 0 = demo account (update Customer.Customer by CID), 1 = real-money account in legacy system (update RealCustomers by CID). Only consulted when GCID = 0; ignored when GCID > 0. |
| 5 | @UpdatedID | int | YES | - | CODE-BACKED | OUTPUT parameter. Always returns NULL because `SCOPE_IDENTITY()` is called after UPDATE statements (not INSERT). Legacy template artifact - callers should not rely on this value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / @GCID | Customer.Customer (view -> CustomerStatic) | Implicit JOIN | Updates SubSerialID for matched customer records |
| @CID / @GCID | dbo.RealCustomers | Implicit (legacy) | Updates SubSerialID in the legacy customer table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No callers found in BackOffice SPs. | - | - | Called from affiliate management workflows in the back-office application. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateAffiliateMetaData (procedure)
+-- Customer.Customer (view) [UPDATE target - routes to Customer.CustomerStatic]
+-- dbo.RealCustomers (table) [UPDATE target - legacy table, no schema prefix]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | UPDATE target for SubSerialID on current customer records (via GCID or CID) |
| dbo.RealCustomers | Table (legacy) | UPDATE target for SubSerialID on legacy real-customer records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from application affiliate update flows. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update SubSerialID for a customer with a valid GCID (updates both tables)

```sql
DECLARE @UpdatedID int;
EXEC BackOffice.UpdateAffiliateMetaData
    @CID       = 12345,
    @GCID      = 98765,
    @SubSerial = 'AFF-SUBSERIAL-XYZ-001',
    @IsReal    = 1,
    @UpdatedID = @UpdatedID OUTPUT;
-- @UpdatedID will be NULL (SCOPE_IDENTITY() after UPDATE, not INSERT)
```

### 8.2 Update SubSerialID for a demo customer (GCID = 0, IsReal = 0)

```sql
DECLARE @UpdatedID int;
EXEC BackOffice.UpdateAffiliateMetaData
    @CID       = 12345,
    @GCID      = 0,
    @SubSerial = 'AFF-DEMO-SUBSERIAL-002',
    @IsReal    = 0,
    @UpdatedID = @UpdatedID OUTPUT;
-- Updates only Customer.Customer WHERE CID=12345
```

### 8.3 Verify SubSerialID after update

```sql
SELECT c.CID, c.GCID, cs.SubSerialID
FROM Customer.Customer c WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON c.CID = cs.CID
WHERE c.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateAffiliateMetaData | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateAffiliateMetaData.sql*
