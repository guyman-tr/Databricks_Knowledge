# Customer.UpdateOriginalCID

> Sets Customer.Customer.OriginalCID for a GCID-identified customer, resolving the value via a priority rule: @OrigCID wins if non-zero, else @CID_Demo wins if non-zero, else the field is set to NULL/0.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID - GCID-based lookup for Customer.Customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateOriginalCID sets the OriginalCID field on Customer.Customer. OriginalCID records the customer's earliest or "original" Customer ID - typically the demo CID from which the account was promoted to real, or a CID migrated from a legacy system. It is used for lineage tracing and linking accounts to their registration origin.

The procedure accepts two candidate CID values and applies a priority rule: if an explicit original CID (@OrigCID) is provided (non-zero), it is used. Otherwise, the demo CID (@CID_Demo) is used. This handles the two main call sites: post-promotion (where @OrigCID carries the migrated CID) and post-registration (where @CID_Demo carries the demo account CID).

The lookup key is @GCID, meaning the update targets the unified Customer.Customer view rather than a legacy table.

---

## 2. Business Logic

### 2.1 OriginalCID Priority Resolution

**What**: Selects which CID value to write as OriginalCID based on non-zero priority.

**Rules**:
- IF ISNULL(@OrigCID, 0) != 0: OriginalCID = @OrigCID (explicit original wins)
- ELSE IF ISNULL(@CID_Demo, 0) != 0: OriginalCID = @CID_Demo (demo CID as fallback)
- ELSE: OriginalCID = @OrigCID (both are NULL/0 -> effectively NULL or 0)
- WHERE GCID = @GCID

**IIF nesting in DDL**:
```sql
SET OriginalCID = IIF(ISNULL(@OrigCID,0)=0,
                      IIF(ISNULL(@CID_Demo,0)=0, @OrigCID, @CID_Demo),
                      @OrigCID)
```
Outer IIF: @OrigCID is 0/NULL? -> enter inner IIF. Else use @OrigCID.
Inner IIF: @CID_Demo is 0/NULL? -> use @OrigCID (NULL). Else use @CID_Demo.

**Diagram**:
```
@OrigCID > 0?
  YES -> OriginalCID = @OrigCID
  NO  -> @CID_Demo > 0?
           YES -> OriginalCID = @CID_Demo
           NO  -> OriginalCID = @OrigCID (NULL/0)
```

**Note**: There is a commented-out simpler CASE expression in the DDL:
`-- SET OriginalCID = CASE WHEN ISNULL(@OrigCID,0) = 0 THEN @CID_Demo ELSE @OrigCID END`
This earlier version always fell back to @CID_Demo (even if NULL). The IIF version adds an inner NULL guard for @CID_Demo.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrigCID | int | NO | - | CODE-BACKED | Primary candidate for OriginalCID. If non-zero, this value wins unconditionally. Typically carries a migrated or explicitly known original CID. |
| 2 | @CID_Demo | int | NO | - | CODE-BACKED | Fallback candidate. Used as OriginalCID only if @OrigCID is 0/NULL. Typically the CID of the demo account from which the customer was promoted to real. |
| 3 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. WHERE GCID = @GCID targets the Customer.Customer row to update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.Customer | Modifier | UPDATE OriginalCID column via GCID lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from account promotion and migration flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateOriginalCID (procedure)
└── Customer.Customer (view - UPDATE target for OriginalCID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | UPDATE target for OriginalCID column via GCID lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Priority rule | Business rule | @OrigCID > 0 wins over @CID_Demo; else @CID_Demo > 0 is used; else NULL/0 written |
| No SET NOCOUNT ON | Implementation | Row-count message is not suppressed (unlike most procedures in this schema) |

---

## 8. Sample Queries

### 8.1 Set OriginalCID using an explicit original CID
```sql
EXEC Customer.UpdateOriginalCID @OrigCID = 99999, @CID_Demo = 0, @GCID = 67890;
-- OriginalCID = 99999 (explicit @OrigCID wins)
```

### 8.2 Set OriginalCID from demo CID (post-registration promotion)
```sql
EXEC Customer.UpdateOriginalCID @OrigCID = 0, @CID_Demo = 55555, @GCID = 67890;
-- OriginalCID = 55555 (@OrigCID is 0, @CID_Demo wins)
```

### 8.3 Check OriginalCID after update
```sql
SELECT CID, GCID, OriginalCID FROM Customer.Customer WITH (NOLOCK) WHERE GCID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateOriginalCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateOriginalCID.sql*
