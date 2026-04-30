# Customer.UpdateManyRiskClassificationInfo

> Bulk-updates RiskClassificationID in BackOffice.Customer for a set of customers supplied by the caller via the #BulkUpdateRiskClassificationInfo temp table; resolves GCID to CID via Customer.CustomerStatic and uses ISNULL-preserve semantics to skip NULLs.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | #BulkUpdateRiskClassificationInfo.GCID - temp table supplied by caller |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateManyRiskClassificationInfo is a batch setter for the RiskClassificationID field in BackOffice.Customer. It accepts no parameters; instead the caller populates a temp table (`#BulkUpdateRiskClassificationInfo`) with (GCID, RiskClassificationId) pairs before calling this procedure.

RiskClassificationID is a regulatory risk segmentation field - it categorises customers for compliance and risk management purposes. Bulk updates are needed during regulatory re-classification campaigns (e.g., MiFID II re-assessments) where many customers must be reclassified simultaneously.

The procedure bridges the Customer schema (GCID-based identity) to BackOffice.Customer (CID-based) via a JOIN through CustomerStatic. ISNULL-preserve semantics mean that rows with NULL RiskClassificationId in the temp table are silently skipped, protecting against accidental overwrites.

---

## 2. Business Logic

### 2.1 Bulk GCID-to-CID Resolution and Update

**What**: Joins the caller-supplied temp table to CustomerStatic (for GCID->CID resolution) and BackOffice.Customer (for the actual update target).

**Rules**:
- UPDATE BackOffice.Customer SET RiskClassificationID = ISNULL(b.RiskClassificationId, RiskClassificationID)
- JOIN Customer.CustomerStatic WITH (NOLOCK) ON cc.GCID = b.GCID -> resolves GCID to CID
- JOIN BackOffice.Customer boc WITH (NOLOCK) ON boc.CID = cc.CID -> targets the BackOffice record
- ISNULL(b.RiskClassificationId, RiskClassificationID): if the temp table row carries a NULL, the existing value is preserved (no-op for that row)
- No explicit WHERE filter beyond the JOIN - all rows in #BulkUpdateRiskClassificationInfo are processed

**Diagram**:
```
Caller creates #BulkUpdateRiskClassificationInfo (GCID, RiskClassificationId)
  |
  v
UPDATE BackOffice.Customer boc
  SET RiskClassificationID = ISNULL(b.RiskClassificationId, boc.RiskClassificationID)
  FROM #BulkUpdateRiskClassificationInfo b
  JOIN Customer.CustomerStatic cc ON cc.GCID = b.GCID   <- GCID resolution
  JOIN BackOffice.Customer boc ON boc.CID = cc.CID       <- update target
```

### 2.2 Caller Protocol

**Rules**:
- Caller MUST create and populate #BulkUpdateRiskClassificationInfo before calling this procedure
- Temp table must have at minimum: GCID (int), RiskClassificationId (nullable int)
- If a GCID in the temp table has no matching CustomerStatic row, that row is silently skipped (JOIN miss)
- SET NOCOUNT ON suppresses row-count messages

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | #BulkUpdateRiskClassificationInfo.GCID | int | NO | - | CODE-BACKED | Global Customer ID. Used to JOIN Customer.CustomerStatic for CID resolution. GCIDs with no CustomerStatic match are silently skipped. |
| 2 | #BulkUpdateRiskClassificationInfo.RiskClassificationId | int | YES | - | CODE-BACKED | Target RiskClassificationID value. NULL rows are skipped via ISNULL-preserve pattern (ISNULL(b.RiskClassificationId, boc.RiskClassificationID)). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| #BulkUpdateRiskClassificationInfo.GCID | Customer.CustomerStatic | Reader | JOIN on GCID to resolve CID for each customer |
| CustomerStatic.CID | BackOffice.Customer | Modifier | UPDATE target for RiskClassificationID column via CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; invoked by batch risk re-classification jobs that populate #BulkUpdateRiskClassificationInfo first |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateManyRiskClassificationInfo (procedure)
├── #BulkUpdateRiskClassificationInfo (temp table - caller-supplied)
├── Customer.CustomerStatic (table - GCID to CID resolution)
└── BackOffice.Customer (table - UPDATE target for RiskClassificationID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| #BulkUpdateRiskClassificationInfo | Temp Table (caller-created) | Source of (GCID, RiskClassificationId) pairs to process |
| Customer.CustomerStatic | Table | GCID to CID resolution JOIN |
| BackOffice.Customer | Table (cross-schema) | UPDATE target: RiskClassificationID column |

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
| ISNULL-preserve | Safety | ISNULL(b.RiskClassificationId, boc.RiskClassificationID) - NULL in temp table leaves existing value unchanged |
| Caller protocol | Contract | #BulkUpdateRiskClassificationInfo must be created and populated by caller before EXEC |
| NOLOCK hints | Performance | CustomerStatic and BackOffice.Customer joined WITH (NOLOCK) - dirty reads acceptable in bulk classification context |

---

## 8. Sample Queries

### 8.1 Bulk re-classify a set of customers
```sql
CREATE TABLE #BulkUpdateRiskClassificationInfo (GCID INT, RiskClassificationId INT);
INSERT INTO #BulkUpdateRiskClassificationInfo VALUES (12345, 3), (67890, 5), (11111, NULL);
EXEC Customer.UpdateManyRiskClassificationInfo;
-- GCID 11111 is silently skipped (NULL RiskClassificationId)
DROP TABLE #BulkUpdateRiskClassificationInfo;
```

### 8.2 Verify classification after update
```sql
SELECT cc.GCID, boc.CID, boc.RiskClassificationID
FROM Customer.CustomerStatic cc WITH (NOLOCK)
JOIN BackOffice.Customer boc WITH (NOLOCK) ON boc.CID = cc.CID
WHERE cc.GCID IN (12345, 67890);
```

### 8.3 Find customers by RiskClassificationID
```sql
SELECT boc.CID, cc.GCID, boc.RiskClassificationID
FROM BackOffice.Customer boc WITH (NOLOCK)
JOIN Customer.CustomerStatic cc WITH (NOLOCK) ON cc.CID = boc.CID
WHERE boc.RiskClassificationID = 3
ORDER BY boc.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 7/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateManyRiskClassificationInfo | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateManyRiskClassificationInfo.sql*
