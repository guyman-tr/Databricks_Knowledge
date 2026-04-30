# Customer.GetRealCIDByGCID

> Returns the internal CID(s) associated with a GCID, providing the reverse mapping from Group Customer ID to platform-specific Customer IDs.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID; returns CID (may be multiple rows for multi-CID GCIDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRealCIDByGCID resolves a GCID (Group Customer ID) to its associated CID(s). The GCID is a cross-product identity that may link multiple platform accounts; this procedure retrieves all CIDs under a given GCID.

The name "Real CID" distinguishes this from OriginalCID (the pre-migration source account). GetRealCIDByGCID returns the current active CID(s), while GetOriginalCIDByGCID returns the historical source CID. In most cases a GCID maps to exactly one CID; in cross-product or migrated accounts it may return multiple rows.

This is a thin lookup wrapper used when only the GCID is available and the caller needs to work with CID-keyed tables.

---

## 2. Business Logic

### 2.1 GCID-to-CID Resolution

**What**: Returns all CIDs associated with the given GCID.

**Columns/Parameters Involved**: `@GCID`, `CID`

**Rules**:
- `SELECT CID FROM Customer.Customer WITH(NOLOCK) WHERE GCID=@GCID`
- No TOP 1 limit: may return multiple rows if multiple CIDs share the GCID
- No additional filtering: returns CIDs for all account states (active, closed, suspended)
- Returns empty result set if GCID not found (not an error)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Input: Group Customer ID. Used to filter Customer.Customer.GCID. |
| 2 | CID | int (output) | NO | - | CODE-BACKED | Internal platform Customer ID. May return multiple rows if the GCID is shared by multiple accounts (cross-product or migrated). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.Customer | FROM + WHERE filter | Resolves GCID to one or more CIDs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRealCIDByGCID (procedure)
`-- Customer.Customer (view)
      |-- Customer.CustomerStatic (table)
      `-- Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM - source of CID, filtered by GCID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get CID(s) for a GCID
```sql
EXEC Customer.GetRealCIDByGCID @GCID = 1983785;
```

### 8.2 Direct query equivalent
```sql
SELECT CID FROM Customer.Customer WITH (NOLOCK) WHERE GCID = 1983785;
```

### 8.3 Compare: GetRealCIDByGCID vs GetOriginalCIDByGCID
```sql
-- GetRealCIDByGCID: returns current CID(s), may return multiple rows
EXEC Customer.GetRealCIDByGCID @GCID = 1983785;

-- GetOriginalCIDByGCID: returns OUTPUT scalar @CID = OriginalCID (pre-migration source account, single value)
DECLARE @OrigCID INT;
EXEC Customer.GetOriginalCIDByGCID @GCID = 1983785, @CID = @OrigCID OUTPUT;
SELECT @OrigCID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related SP compared | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRealCIDByGCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetRealCIDByGCID.sql*
