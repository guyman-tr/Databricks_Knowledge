# Trade.Gain_GetActiveCustomers

> Returns all distinct customer IDs that had trading activity (open or closed positions) overlapping with a specified date range, used by the Gain calculation system to determine which customers need P&L processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MinDate / @MaxDate date range |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies all customers who had any trading activity during a specified period. The Gain (P&L calculation) system uses this to determine which customers need gain/loss calculations. It uses a four-way UNION to catch every possible scenario: positions closed during the period, positions still open that were opened before the period end, positions that were open at the start of the period but closed after, and positions that were open at the end of the period but closed after.

---

## 2. Business Logic

### 2.1 Four-Way Activity Detection

**What**: Captures all customers with position overlap in the date range.

**Columns/Parameters Involved**: `@MinDate`, `@MaxDate`, `CloseOccurred`, `OpenOccurred`, `InitDateTime`

**Rules**:
- Query 1: Positions CLOSED within the range (CloseOccurred BETWEEN @MinDate AND @MaxDate) - from History.Position
- Query 2: Positions CURRENTLY OPEN that were opened before @MaxDate (InitDateTime < @MaxDate) - from Trade.Position
- Query 3: Positions that STRADDLED the start date (opened before @MinDate, closed after @MinDate) - from History.Position
- Query 4: Positions that STRADDLED the end date (opened before @MaxDate, closed after @MaxDate) - from History.Position
- UNION deduplicates across all four queries

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinDate | datetime | NO | - | CODE-BACKED | Start of the gain calculation period. Positions active on or after this date are included. |
| 2 | @MaxDate | datetime | NO | - | CODE-BACKED | End of the gain calculation period. Positions active on or before this date are included. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | History.Position | READER | Reads closed positions for period overlap detection |
| SELECT | Trade.Position (view) | READER | Reads currently open positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Gain calculation service | EXEC | Caller | Determines which customers need gain processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Gain_GetActiveCustomers (procedure)
+-- History.Position (table)
+-- Trade.Position (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | SELECT DISTINCT CID - closed positions |
| Trade.Position | View | SELECT DISTINCT CID - open positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called by external Gain service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get Active Customers for March 2026

```sql
EXEC Trade.Gain_GetActiveCustomers @MinDate = '2026-03-01', @MaxDate = '2026-03-31'
```

### 8.2 Count Active Customers by Month

```sql
SELECT DISTINCT CID
  FROM History.Position WITH (NOLOCK)
 WHERE CloseOccurred BETWEEN '2026-03-01' AND '2026-03-31'
```

### 8.3 Find Customers with Currently Open Positions

```sql
SELECT DISTINCT CID FROM Trade.Position WITH (NOLOCK) WHERE InitDateTime < GETUTCDATE()
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_GetActiveCustomers | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Gain_GetActiveCustomers.sql*
