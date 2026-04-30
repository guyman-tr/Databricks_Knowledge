# AffiliateCommission.SetTraderFirstAssetPosition

> Inserts a trader's first asset position record if one does not already exist, and returns the current record along with whether a new row was added.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Conditional INSERT into TraderFirstAssetPosition with existence check, returns result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records the first asset type that a trader opens a position in, which is a significant event in the CPA commission model. The first position's asset type (e.g., stocks, crypto, commodities) may influence commission tier calculations, partner compensation rules, and affiliate attribution logic.

The procedure uses an anti-join pattern to ensure idempotency - it only inserts a record when one does not already exist for the given CID. This prevents duplicate entries when the same event is processed more than once, which is critical for correctness in event-driven commission processing.

After the conditional insert, the procedure returns a result set containing the trader's first asset position data along with a RowAdded flag (1 if a new record was created, 0 if one already existed). This allows callers to determine whether this was a first-time event and react accordingly in downstream processing.

---

## 2. Business Logic

### 2.1 Conditional Insert with Anti-Join

**What**: Inserts a new TraderFirstAssetPosition record only if no record exists for the given CID, using a RIGHT JOIN anti-pattern for existence checking.

**Columns/Parameters Involved**: @CID, @FirstPositionAssetTypeID, @DateAdded, PartitionCol

**Rules**:
- Uses a RIGHT JOIN between existing records and a derived table of the input parameters
- Checks for existing records using CID and PartitionCol = CID % 50 (partition pruning)
- Only inserts WHERE T.CID IS NULL (no existing record found)
- @@ROWCOUNT captures whether the insert occurred (1 = inserted, 0 = already existed)

### 2.2 Result Set Return

**What**: Returns the trader's first asset position record along with whether a new row was added.

**Columns/Parameters Involved**: CID, FirstPositionAssetTypeID, DateAdded, RowAdded

**Rules**:
- Always returns a result set regardless of whether an insert occurred
- RowAdded is a BIT flag derived from @@ROWCOUNT (1 = new record, 0 = pre-existing)
- Uses partition pruning (PartitionCol = @CID % 50) for efficient lookup

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | BIGINT | No | - | CODE-BACKED | Customer ID identifying the trader |
| 2 | @FirstPositionAssetTypeID | INT | No | - | CODE-BACKED | Asset type ID of the trader's first opened position |
| 3 | @DateAdded | DATETIME | No | - | CODE-BACKED | Timestamp when the first position was opened |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateConfiguration.TraderFirstAssetPosition | INSERT/SELECT target | Conditionally inserts and reads from TraderFirstAssetPosition |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing service when a trader opens their first position, to record the asset type for downstream CPA calculations.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.SetTraderFirstAssetPosition
  --> AffiliateConfiguration.TraderFirstAssetPosition (INSERT + SELECT)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateConfiguration.TraderFirstAssetPosition | Table | INSERT target (conditional) and SELECT source for return result |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Commission processing service | Application | Calls this SP to record first asset position events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Record a trader's first asset position
```sql
EXEC AffiliateCommission.SetTraderFirstAssetPosition
    @CID = 500001,
    @FirstPositionAssetTypeID = 3,
    @DateAdded = '2026-04-12 10:30:00';
```

### 8.2 Verify existing first asset position for a trader
```sql
SELECT CID, FirstPositionAssetTypeID, DateAdded
FROM AffiliateConfiguration.TraderFirstAssetPosition WITH (NOLOCK)
WHERE CID = 500001 AND PartitionCol = 500001 % 50;
```

### 8.3 Find traders whose first position was in a specific asset type
```sql
SELECT CID, FirstPositionAssetTypeID, DateAdded
FROM AffiliateConfiguration.TraderFirstAssetPosition WITH (NOLOCK)
WHERE FirstPositionAssetTypeID = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-2448: CPA New Compensation Design (17/12/23)
- PART-3174: Update SP insert only records that don't exist for sure (23/06/24)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.SetTraderFirstAssetPosition | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.SetTraderFirstAssetPosition.sql*
