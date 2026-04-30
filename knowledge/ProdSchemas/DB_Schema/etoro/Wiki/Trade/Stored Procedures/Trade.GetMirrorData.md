# Trade.GetMirrorData

> Returns CopyTrader mirror relationship data with customer details, using dynamic SQL to query by either MirrorID or CID+ParentCID combination.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Mirror + CustomerStatic data (MirrorID, amounts, status, GCID, Registered) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorData retrieves CopyTrader mirror relationship information enriched with customer registration details. It supports two query modes: lookup by MirrorID (direct mirror lookup), or lookup by CID+ParentCID (find the mirror between a copier and a copied trader). If neither valid combination is provided, it returns no rows (AND 1=0 safety).

This procedure exists as a general-purpose mirror data reader used by the Portfolio Alignment Service and other internal tools. The dynamic SQL approach allows a single procedure to serve both lookup patterns efficiently. Amounts are returned in cents (multiplied by 100) for consistency with internal financial APIs.

Called by PortfolioAlignmentService and PROD_BIadmins. Also called by Trade.GetUserInfoWithCopyRestrictions.

---

## 2. Business Logic

### 2.1 Dynamic Query Mode Selection

**What**: Builds a query dynamically based on which parameters are provided.

**Columns/Parameters Involved**: `@MirrorID`, `@CID`, `@ParentCID`

**Rules**:
- If @MirrorID IS NOT NULL -> filter by MirrorID only
- Else if @CID IS NOT NULL AND @ParentCID IS NOT NULL -> filter by CID AND ParentCID
- Else -> returns no rows (AND 1=0 safety clause)
- Uses sp_executesql with parameterized dynamic SQL
- Joins Trade.Mirror to Customer.CustomerStatic to get GCID and Registered date

### 2.2 Amount Conversion to Cents

**What**: Financial amounts are multiplied by 100 to convert to cents for API consumption.

**Columns/Parameters Involved**: `Amount`, `MirrorSL`, `RealizedEquity`

**Rules**:
- MirrorAmount = Amount * 100
- MirrorSLAmount = MirrorSL * 100
- RealizedEquity = RealizedEquity * 100
- This matches the internal API convention of using cent values

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @MirrorID | int | IN | NULL | CODE-BACKED | Direct mirror ID lookup. When provided, @CID and @ParentCID are ignored. |
| 2 | @CID | int | IN | NULL | CODE-BACKED | Copier's customer ID. Used with @ParentCID when @MirrorID is NULL. |
| 3 | @ParentCID | int | IN | NULL | CODE-BACKED | Copied trader's customer ID. Used with @CID when @MirrorID is NULL. |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | MirrorID | int | NO | CODE-BACKED | Unique CopyTrader mirror relationship ID. |
| 2 | MirrorAmount | money | YES | CODE-BACKED | Current mirror investment amount in cents (Amount * 100). |
| 3 | MirrorSLAmount | money | YES | CODE-BACKED | Mirror stop-loss amount in cents (MirrorSL * 100). |
| 4 | CID | int | NO | CODE-BACKED | Copier's customer ID. |
| 5 | RealizedEquity | money | YES | CODE-BACKED | Mirror's realized equity in cents (RealizedEquity * 100). |
| 6 | MirrorSLPercentage | decimal | YES | CODE-BACKED | Mirror stop-loss as a percentage of investment. |
| 7 | IsActive | bit | YES | CODE-BACKED | Whether the mirror relationship is currently active. |
| 8 | MirrorTypeID | int | YES | CODE-BACKED | Type of mirror (CopyTrader type classification). |
| 9 | ParentCID | int | YES | CODE-BACKED | The copied trader's customer ID. |
| 10 | PauseCopy | bit | YES | CODE-BACKED | Whether copying is currently paused. |
| 11 | MirrorCalculationType | int | YES | CODE-BACKED | How mirror allocations are calculated. |
| 12 | MirrorStatusID | int | YES | CODE-BACKED | Mirror lifecycle status. |
| 13 | GCID | int | YES | CODE-BACKED | Global Customer ID from Customer.CustomerStatic. |
| 14 | Registered | datetime | YES | CODE-BACKED | Customer registration date from Customer.CustomerStatic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Mirror | SELECT (READER) | Reads mirror relationship data |
| JOIN | Customer.CustomerStatic | SELECT (READER) | Enriches with GCID and registration date |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetUserInfoWithCopyRestrictions | EXEC | Stored Procedure | Calls to get mirror data for user info |
| PortfolioAlignmentService | GRANT EXECUTE | Application User | Portfolio alignment |
| PROD_BIadmins | GRANT EXECUTE | Application User | Analytics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorData (procedure)
+-- Trade.Mirror (table)
+-- Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Dynamic SQL SELECT for mirror data |
| Customer.CustomerStatic | Table | JOIN to get GCID and Registered |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUserInfoWithCopyRestrictions | Stored Procedure | Calls this |
| PortfolioAlignmentService | Application User | Mirror data |
| PROD_BIadmins | Application User | Analytics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Uses dynamic SQL via sp_executesql with proper parameterization.

---

## 8. Sample Queries

### 8.1 Get mirror data by MirrorID

```sql
EXEC Trade.GetMirrorData @MirrorID = 12345;
```

### 8.2 Get mirror between copier and trader

```sql
EXEC Trade.GetMirrorData @CID = 67890, @ParentCID = 11111;
```

### 8.3 Direct query equivalent

```sql
SELECT  mr.MirrorID,
        mr.Amount * 100 AS MirrorAmount,
        mr.MirrorSL * 100 AS MirrorSLAmount,
        mr.CID,
        mr.RealizedEquity * 100 AS RealizedEquity,
        mr.MirrorStatusID,
        cc.GCID,
        cc.Registered
FROM    Trade.Mirror mr WITH (NOLOCK)
        JOIN Customer.CustomerStatic cc WITH (NOLOCK) ON mr.CID = cc.CID
WHERE   mr.MirrorID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorData.sql*
