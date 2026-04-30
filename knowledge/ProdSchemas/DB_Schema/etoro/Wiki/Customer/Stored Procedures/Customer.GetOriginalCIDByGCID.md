# Customer.GetOriginalCIDByGCID

> Resolves a GCID to the customer's OriginalCID (pre-migration source account ID) via an OUTPUT parameter; returns the original provider CID for migration tracing.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID input; @CID OUTPUT (OriginalCID value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetOriginalCIDByGCID looks up the OriginalCID for a customer identified by their GCID. OriginalCID is the customer's ID in the source system before account migration to eToro's current platform. For customers who were migrated, OriginalCID holds their old account number; for natively registered accounts, OriginalCID is 0 (non-migrated default).

The procedure is used in migration-related flows that need to trace a customer back to their original identity in the source provider system. The GCID is used as the lookup key because cross-product operations often operate at the group identity level.

The result is returned as an OUTPUT parameter (@CID OUTPUT, default 0) rather than a result set - the caller receives the OriginalCID directly in the parameter. If @GCID is 0 or negative, the procedure skips the lookup and returns @CID=0 (guard clause: `IF @GCID > 0`).

---

## 2. Business Logic

### 2.1 GCID Guard and OUTPUT Return

**What**: Returns OriginalCID only for valid (positive) GCIDs; uses OUTPUT parameter pattern.

**Columns/Parameters Involved**: `@GCID`, `@CID OUTPUT`, `Customer.Customer.OriginalCID`

**Rules**:
- IF @GCID > 0: executes the SELECT; otherwise @CID stays at default 0
- @GCID <= 0 (e.g., 0 = unassigned GCID): returns @CID=0 without querying
- SELECT @CID = OriginalCID FROM Customer.Customer WHERE GCID = @GCID
- If GCID matches no customer: @CID remains at default 0 (the SELECT assigns nothing)
- OriginalCID=0 in result means either: customer not found, @GCID was 0, or this is a non-migrated native account

**Diagram**:
```
@GCID
  |
  +--[IF @GCID <= 0]--> return @CID = 0 (early exit)
  |
  +--[IF @GCID > 0]--> SELECT OriginalCID FROM Customer.Customer WHERE GCID = @GCID
                                    |
                                    v
                              @CID = OriginalCID (or 0 if not found)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Input: Group Customer ID to look up. Values <= 0 bypass the query and return @CID=0. |
| 2 | @CID | INT OUTPUT | NO | 0 | CODE-BACKED | Output: The customer's OriginalCID from Customer.Customer - their ID in the source system before migration. Default=0 (returned when @GCID is 0, negative, or not found in Customer.Customer). From Customer.Customer.OriginalCID: "Original customer ID from the source provider before any migration. Default=0 for non-migrated accounts." |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID / OriginalCID | Customer.Customer | FROM + WHERE filter | Reads OriginalCID for the given GCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (DB role) | - | GRANT EXECUTE | BI admin access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetOriginalCIDByGCID (procedure)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | SELECT OriginalCID WHERE GCID = @GCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | DB Role/User | EXECUTE permission granted |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get original CID for a known GCID
```sql
DECLARE @OrigCID INT = 0;
EXEC Customer.GetOriginalCIDByGCID @GCID = 1983785, @CID = @OrigCID OUTPUT;
SELECT @OrigCID AS OriginalCID;
```

### 8.2 Direct query equivalent
```sql
SELECT OriginalCID
FROM Customer.Customer WITH (NOLOCK)
WHERE GCID = 1983785;
```

### 8.3 Find all migrated customers by OriginalCID not zero
```sql
SELECT CID, GCID, OriginalCID, OriginalProviderID
FROM Customer.Customer WITH (NOLOCK)
WHERE OriginalCID != 0
ORDER BY OriginalCID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetOriginalCIDByGCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetOriginalCIDByGCID.sql*
