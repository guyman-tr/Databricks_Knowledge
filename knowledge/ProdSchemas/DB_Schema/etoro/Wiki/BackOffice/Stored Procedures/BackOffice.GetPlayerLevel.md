# BackOffice.GetPlayerLevel

> Computes and returns (via OUTPUT parameter) the player tier level for a customer based on their lifetime trading volume (lot count) and total deposits, taking the higher tier from either metric.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (input) -> @PlayerLevelID (OUTPUT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure computes a customer's player tier level - the loyalty/classification tier (e.g., Silver, Gold, Diamond) that determines account benefits, service level, and manager assignment priority. It evaluates the customer across two dimensions - total deposits and total trading lot volume - and assigns the highest tier the customer qualifies for under either dimension.

The dual-metric approach means a customer can earn a higher tier through either depositing more money OR trading more volume, whichever puts them in a higher bracket. This is used for tier re-evaluation and assignment logic in the BackOffice system.

**Key design**: Returns the result as an OUTPUT parameter (not a result set). Callers receive `@PlayerLevelID` as an INT output, no rows are returned.

**Permission**: VIEW DEFINITION granted to PROD\BIadmins only. No active EXECUTE grants to application services - likely used as a utility called from other BackOffice SPs or ad-hoc queries.

---

## 2. Business Logic

### 2.1 Customer Activity Aggregation

**What**: Retrieves the customer's lifetime trading volume and total deposits.

**Columns/Parameters Involved**: BackOffice.CustomerAllTimeAggregatedData.TotalLot, BackOffice.CustomerAllTimeAggregatedData.TotalDeposit

**Rules**:
- `COALESCE((SELECT TotalLot FROM ... WHERE CID = @CID), 0)`: If no aggregated data record exists, defaults to 0 (new/inactive customers).
- `COALESCE((SELECT TotalDeposit FROM ... WHERE CID = @CID), 0)`: Same null-safety for deposits.
- Both are read from `BackOffice.CustomerAllTimeAggregatedData` - the pre-computed lifetime aggregate table, avoiding real-time position/deposit counting.

### 2.2 Tier Determination - Highest Qualifying Level

**What**: Finds the player level tier by comparing both metrics against Dictionary.PlayerLevel ranges.

**Columns/Parameters Involved**: Dictionary.PlayerLevel.Sort, FromSumLotCount, ToSumLotCount, FromSumDeposit, ToSumDeposit, PlayerLevelID

**Rules**:
- **Lot tier**: `SELECT TOP 1 Sort ... WHERE @OpenPositionsLotCount BETWEEN FromSumLotCount AND ToSumLotCount ORDER BY Sort DESC` - finds the tier bracket containing the customer's lot volume.
- **Deposit tier**: Same pattern using `TotalDeposited BETWEEN FromSumDeposit AND ToSumDeposit`.
- **Final selection**: `WHERE Sort = CASE WHEN @SortFromDeposit > @SortFromLot THEN @SortFromDeposit ELSE @SortFromLot END` - takes the HIGHER Sort value (higher Sort = higher tier).
- `Sort` is a numeric ordering field in `Dictionary.PlayerLevel` - higher value = higher tier.
- If the customer's metrics don't fall within any tier range, the Sort variables remain NULL, and the final SELECT may return no rows (leaving @PlayerLevelID unchanged/NULL).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Input parameter. The customer whose player level is to be computed. |
| 2 | @PlayerLevelID | INT | YES | (unchanged) | CODE-BACKED | OUTPUT parameter. Set to the PlayerLevelID from Dictionary.PlayerLevel that corresponds to the customer's highest qualifying tier. NULL if the customer's metrics fall outside all defined tier ranges. |

**Output**: No result set. Result is returned via the @PlayerLevelID OUTPUT parameter.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TotalLot, TotalDeposit | BackOffice.CustomerAllTimeAggregatedData | Read (scalar subquery) | Customer lifetime trading metrics |
| Tier lookup (lots) | Dictionary.PlayerLevel | Read (TOP 1) | Tier ranges by lot count (FromSumLotCount, ToSumLotCount) |
| Tier lookup (deposits) | Dictionary.PlayerLevel | Read (TOP 1) | Tier ranges by deposit amount (FromSumDeposit, ToSumDeposit) |
| Final tier ID | Dictionary.PlayerLevel | Read (scalar) | PlayerLevelID for the winning Sort value |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. VIEW DEFINITION only (no EXECUTE to app services).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetPlayerLevel (procedure)
+-- BackOffice.CustomerAllTimeAggregatedData (table - TotalLot, TotalDeposit)
+-- Dictionary.PlayerLevel (table - tier ranges and sort order)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerAllTimeAggregatedData | Table | Lifetime TotalLot and TotalDeposit for the customer |
| Dictionary.PlayerLevel | Table | Tier range definitions (FromSumLotCount/ToSumLotCount/FromSumDeposit/ToSumDeposit) and Sort order |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | VIEW DEFINITION to PROD\BIadmins only |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OUTPUT parameter | Interface | Returns result as @PlayerLevelID output, not a rowset - callers must declare and pass the output variable |
| COALESCE with 0 | Null safety | Missing aggregated data defaults to 0 rather than NULL |
| Sort DESC ordering | Business rule | Ensures the highest applicable tier is selected when multiple ranges overlap |
| Dual-metric max | Business rule | Customer qualifies for the better of deposit tier vs lot tier |

---

## 8. Sample Queries

### 8.1 Compute player level for a customer

```sql
DECLARE @Level INT;
EXEC BackOffice.GetPlayerLevel @CID = 12345678, @PlayerLevelID = @Level OUTPUT;
SELECT @Level AS PlayerLevelID;
```

### 8.2 View player level tier ranges

```sql
SELECT PlayerLevelID, Name, Sort,
       FromSumLotCount, ToSumLotCount,
       FromSumDeposit, ToSumDeposit
FROM Dictionary.PlayerLevel WITH (NOLOCK)
ORDER BY Sort DESC;
```

### 8.3 Check a customer's current aggregated metrics

```sql
SELECT CID, TotalLot, TotalDeposit
FROM BackOffice.CustomerAllTimeAggregatedData WITH (NOLOCK)
WHERE CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetPlayerLevel | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetPlayerLevel.sql*
