# Trade.GetMirrorCloseSagasByModAndResult

> Retrieves mirror close sagas partitioned by modular arithmetic on MirrorID, enabling parallel processing of close sagas across multiple service instances.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: MirrorCloseSaga records where MirrorID % @Mod = @Result |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorCloseSagasByModAndResult retrieves a partition of mirror close sagas using modular arithmetic (MirrorID % @Mod = @Result). This partitioning pattern allows multiple service instances to process close sagas in parallel without overlap - each instance claims a different @Result value while sharing the same @Mod.

This procedure exists to support horizontal scaling of the CopyTrader close saga processor. When many mirrors are being closed simultaneously, a single processor can't keep up. By partitioning on MirrorID modulo N, N instances can each process 1/N of the sagas with zero coordination.

Called by PROD_BIadmins. The partitioning approach is noted in a code comment as a "manipulation on MirrorID."

---

## 2. Business Logic

### 2.1 Modular Partitioning

**What**: Divides all close sagas into @Mod partitions and returns only the partition matching @Result.

**Columns/Parameters Involved**: `@Mod`, `@Result`, `Trade.MirrorCloseSaga.MirrorID`

**Rules**:
- MirrorID % @Mod = @Result selects a consistent partition
- Example: @Mod=4, @Result=0 returns MirrorIDs 4, 8, 12, 16...
- @Mod=4, @Result=1 returns MirrorIDs 1, 5, 9, 13...
- This ensures each saga is processed by exactly one instance
- Returns all saga fields: MirrorID, CID, CurrentStepIndex, InitialRequestGuid, MirrorCloseActionType, ClientRequestId, CreateDate

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @Mod | int | IN | - | CODE-BACKED | The divisor for modular partitioning. Typically equals the number of processing instances. |
| 2 | @Result | int | IN | - | CODE-BACKED | The remainder to match. Each instance uses a unique @Result (0 through @Mod-1). |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | MirrorID | int | NO | CODE-BACKED | CopyTrader mirror relationship ID. |
| 2 | CID | int | NO | CODE-BACKED | Copier customer ID. |
| 3 | CurrentStepIndex | int | YES | CODE-BACKED | Current saga step index. |
| 4 | InitialRequestGuid | uniqueidentifier | YES | CODE-BACKED | Correlation GUID for distributed tracing. |
| 5 | MirrorCloseActionType | int | YES | CODE-BACKED | How the close was initiated. |
| 6 | ClientRequestId | varchar | YES | CODE-BACKED | Client-side request identifier. |
| 7 | CreateDate | datetime | YES | CODE-BACKED | When the saga was created. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.MirrorCloseSaga | SELECT (READER) | Reads close sagas with modular partition filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | GRANT EXECUTE | Application User | Partitioned saga processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorCloseSagasByModAndResult (procedure)
+-- Trade.MirrorCloseSaga (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.MirrorCloseSaga | Table | SELECT with modular filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | Application User | Saga processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get partition 0 of 4

```sql
EXEC Trade.GetMirrorCloseSagasByModAndResult @Mod = 4, @Result = 0;
```

### 8.2 Get all sagas (single instance - @Mod=1)

```sql
EXEC Trade.GetMirrorCloseSagasByModAndResult @Mod = 1, @Result = 0;
```

### 8.3 Verify partition distribution

```sql
SELECT  MirrorID % 4 AS Partition,
        COUNT(*) AS SagaCount
FROM    Trade.MirrorCloseSaga WITH (NOLOCK)
GROUP BY MirrorID % 4
ORDER BY Partition;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorCloseSagasByModAndResult | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorCloseSagasByModAndResult.sql*
