# Trade.GetEstimatedTreeUnitsByCID

> Production version of copy-tree unit estimation for position opens. Traverses the mirror hierarchy upward from a customer to sum total hedgeable units when opening a new position. Excludes SPAC instruments and zeroes for PlayerLevelID=4.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - returns estimated total units for hedge calculation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure estimates the total units across the copy-trading tree when a customer opens a new position. It walks the mirror hierarchy: the customer's direct copiers, their copiers' copiers, and so on. For each copier it checks if the calculated units meet the minimum copy amount threshold (different for funds vs regular customers) and whether they have sufficient equity and active non-paused mirrors. The final sum is the total units the platform will need to hedge when the position opens.

The procedure exists because opening a position in a copy-trading context creates a cascade: the leader opens, and all copiers (and their copiers) open proportional positions. The hedge service needs to know the aggregate exposure before executing. Without this, hedge calculations would be wrong.

Data flow: Gets min copy amounts from Trade.GetMinCopyPositonAmountMaintenanceFeatureValues. Converts cents to dollars. Excludes PlayerLevelID=4 (zeroes), Funds use Customer.IsCustomerFund. Excludes SPAC instruments (hardcoded list). Recursive CTE on Trade.Mirror with Customer.IsCustomerFund. Returns SUM(Units) + @Units WHERE IsHedged=1.

---

## 2. Business Logic

### 2.1 Recursive Mirror Tree Traversal

**What**: Walks the copy-trading hierarchy upward from @CID - direct copiers, then copiers of copiers - collecting those whose calculated units meet the minimum threshold.

**Columns/Parameters Involved**: `@CID`, `@Units`, `@Ratio`, `@Leverage`, `@InstrumentUnitMargin`, `Trade.Mirror`, `Customer.IsCustomerFund`

**Rules**:
- Anchor: direct copiers of @CID where calculated units >= minimum (different threshold for Fund vs Regular)
- Filters: Active mirror, not paused, not blocked/test player (PlayerStatusID NOT IN 2,9), positive equity, sufficient funds
- Recursive: copiers of copiers with same filters
- Final: SUM(Units) + @Units WHERE IsHedged=1

### 2.2 Minimum Copy Amount and Fund Handling

**What**: Minimum copy amount comes from maintenance feature values. Funds have a different threshold than regular customers.

**Columns/Parameters Involved**: `Trade.GetMinCopyPositonAmountMaintenanceFeatureValues`, `Customer.IsCustomerFund`

**Rules**:
- EXEC Trade.GetMinCopyPositonAmountMaintenanceFeatureValues - returns min amounts in cents
- Convert to dollars (/100)
- Fund customers use different threshold for inclusion in tree

### 2.3 SPAC and PlayerLevel Exclusions

**What**: SPAC instruments (hardcoded list of ~24 instrument IDs) return early with just @Units. PlayerLevelID=4 zeroes out units.

**Columns/Parameters Involved**: `@InstrumentID`, `@Units`, `PlayerLevelID`

**Rules**:
- If @InstrumentID in SPAC list: return @Units only (no tree traversal)
- If CID has PlayerLevelID=4: return 0 units

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Root of mirror tree - direct copiers of this CID are anchor |
| 2 | @Leverage | INT | NO | - | CODE-BACKED | Leverage for unit calculation |
| 3 | @Ratio | DECIMAL(12,8) | NO | - | CODE-BACKED | Copy ratio for unit calculation |
| 4 | @Units | MONEY | NO | - | CODE-BACKED | Base units from the initiating position |
| 5 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument. If in SPAC list, returns @Units early |
| 6 | @InstrumentUnitMargin | DECIMAL(12,5) | NO | - | CODE-BACKED | Unit margin for instrument - used in unit calculation (FB 51345) |
| 7 | (return) | - | - | - | CODE-BACKED | Estimated total units for hedge (SUM across tree + @Units) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | Trade.GetMinCopyPositonAmountMaintenanceFeatureValues | Call | Min copy amounts in cents |
| FROM | Trade.Mirror | Table | Mirror hierarchy - ParentCID, CID, copier relationships |
| FROM | Customer.IsCustomerFund | Function | Fund detection for threshold |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge / position open logic | Caller | Call | Unit estimation before position open |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetEstimatedTreeUnitsByCID (procedure)
+-- Trade.GetMinCopyPositonAmountMaintenanceFeatureValues (procedure)
+-- Trade.Mirror (table)
+-- Customer.IsCustomerFund (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMinCopyPositonAmountMaintenanceFeatureValues | Procedure | EXEC - min copy amounts |
| Trade.Mirror | Table | Recursive CTE - copy hierarchy |
| Customer.IsCustomerFund | Function | Fund detection |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge / position open | Service | Unit estimation for opens |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Change history: FB 50817 UnitMargin from CurrencyPrice (2018), FB 51345 InstrumentUnitMargin as param (2018), TRADEX-851 SPACs exclusion (2021)
- Hardcoded SPAC instrument ID list (~24 IDs)

---

## 8. Sample Queries

### 8.1 Estimate tree units for position open

```sql
EXEC Trade.GetEstimatedTreeUnitsByCID
    @CID = 10001,
    @Leverage = 5,
    @Ratio = 1.0,
    @Units = 100,
    @InstrumentID = 100,
    @InstrumentUnitMargin = 0.5;
```

### 8.2 Query mirror hierarchy directly

```sql
;WITH Copiers AS (
    SELECT m.CID, m.ParentCID, m.MirrorID
    FROM Trade.Mirror m WITH (NOLOCK)
    WHERE m.ParentCID = 10001
      AND m.MirrorStatusID = 1
    UNION ALL
    SELECT m.CID, m.ParentCID, m.MirrorID
    FROM Trade.Mirror m WITH (NOLOCK)
    INNER JOIN Copiers c ON c.CID = m.ParentCID
    WHERE m.MirrorStatusID = 1
)
SELECT * FROM Copiers;
```

### 8.3 Check if customer is fund

```sql
SELECT Customer.IsCustomerFund(10001);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetEstimatedTreeUnitsByCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetEstimatedTreeUnitsByCID.sql*
