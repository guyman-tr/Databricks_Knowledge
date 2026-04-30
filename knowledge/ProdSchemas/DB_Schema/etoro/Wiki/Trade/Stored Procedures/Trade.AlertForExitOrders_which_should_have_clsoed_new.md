# Trade.AlertForExitOrders_which_should_have_clsoed_new

> Improved variant of the orphaned exit orders alert that uses temp table staging with partition-aligned JOINs for better performance on partitioned tables. Misspelled name retained for compatibility.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Recipients, @Copy_Recipients |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a performance-improved variant of the orphaned exit orders alert. It detects pending exit orders that should have triggered based on market prices but remain open. The "_new" suffix indicates this was developed as a replacement for the older `_clsoed` variant (note: the typo is preserved from the original).

The key improvement over the original is the use of **temp table staging** with a two-step approach: (1) first identify candidate positions by joining OrdersExitTbl to PositionTbl with partition alignment, (2) then filter those candidates against CurrencyPrice. This avoids the large cross-join that occurs when CurrencyPrice is joined directly in a single query. It also adds a partition column (`PartitionCol`) to the JOIN between OrdersExitTbl and PositionTbl, which was added by Ran on 08/07/2020 to enable partition elimination.

The email output and alerting behavior are identical to the other variants in this family.

---

## 2. Business Logic

### 2.1 Two-Stage Orphan Detection

**What**: Splits the detection into two stages for performance.

**Columns/Parameters Involved**: `OrdersExitTbl.StatusID`, `PositionTbl.PartitionCol`, `CurrencyPrice.ReceivedOnPriceServer`

**Rules**:
- Stage 1: INSERT pending exit orders (StatusID=1) joined to PositionTbl (with PartitionCol alignment) into #position temp table
- Stage 2: JOIN #position to CurrencyPrice, filtering where OpenOccurred < ReceivedOnPriceServer, into #data temp table
- #position has a clustered PK on PositionID and NC index on (OpenOccurred, InstrumentID)
- OPTION(RECOMPILE) on Stage 1 to account for varying StatusID=1 population
- Enrichment: Joins #data back to detail tables and adds fail history via OUTER APPLY

### 2.2 Partition Alignment

**What**: Uses PartitionCol in the JOIN between OrdersExitTbl and PositionTbl for partition elimination.

**Rules**:
- `ON O.PositionID = P.PositionID AND O.PartitionCol = P.PartitionCol`
- Added by Ran on 08/07/2020 to improve scan performance on partitioned tables
- Also used in the detail enrichment step

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Recipients | varchar(max) | YES | 'tradingbackend@etoro.com;pinikr@etoro.com;yitzchakwa@etoro.com;' | CODE-BACKED | Email recipients for the alert. |
| 2 | @Copy_Recipients | varchar(max) | YES | '' | CODE-BACKED | CC recipients. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Trade.OrdersExitTbl | READER | Pending exit orders (StatusID=1) |
| JOIN | Trade.PositionTbl | READER | Position details with partition alignment |
| JOIN | Trade.Position (view) | READER | Amount/units for email detail |
| JOIN | Trade.CurrencyPrice | READER | Market price timestamps |
| JOIN | Trade.InstrumentMetaData | READER | Instrument display names |
| OUTER APPLY | History.PositionFail | READER | Recent failure reasons |
| EXEC | msdb.dbo.sp_send_dbmail | System call | HTML email alert |

### 5.2 Referenced By (other objects point to this)

No SQL-level dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AlertForExitOrders_which_should_have_clsoed_new (procedure)
+-- Trade.OrdersExitTbl (table)
+-- Trade.PositionTbl (table)
+-- Trade.Position (view)
+-- Trade.CurrencyPrice (table)
+-- Trade.InstrumentMetaData (table)
+-- History.PositionFail (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExitTbl | Table | Pending exit orders |
| Trade.PositionTbl | Table | Position details (partition-aligned) |
| Trade.Position | View | Amount/units for detail display |
| Trade.CurrencyPrice | Table | Market price timestamps |
| Trade.InstrumentMetaData | Table | Instrument names |
| History.PositionFail | Table | Fail history enrichment |

### 6.2 Objects That Depend On This

No SQL-level dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| #position PK | Temp table | Clustered PK on PositionID |
| #position IX | Temp table | NC index on (OpenOccurred, InstrumentID) for CurrencyPrice join |
| OPTION(RECOMPILE) | Hint | On initial join for accurate cardinality estimation |

---

## 8. Sample Queries

### 8.1 Run the improved alert

```sql
EXEC Trade.AlertForExitOrders_which_should_have_clsoed_new;
```

### 8.2 Run with custom recipients

```sql
EXEC Trade.AlertForExitOrders_which_should_have_clsoed_new
    @Recipients = 'dba_team@etoro.com;';
```

### 8.3 Preview staged candidate positions

```sql
SELECT  O.PositionID, P.InstrumentID, O.OpenOccurred, O.PartitionCol
FROM    Trade.OrdersExitTbl O WITH (NOLOCK)
JOIN    Trade.PositionTbl P WITH (NOLOCK) ON O.PositionID = P.PositionID AND O.PartitionCol = P.PartitionCol
WHERE   O.StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AlertForExitOrders_which_should_have_clsoed_new | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AlertForExitOrders_which_should_have_clsoed_new.sql*
