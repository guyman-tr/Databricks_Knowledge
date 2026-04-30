# Dictionary.GetAllocationSourceID

> Stored procedure that resolves an allocation source name to its numeric ID from Dictionary.AllocationSource.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: ID from AllocationSource |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetAllocationSourceID performs a name-to-ID lookup on the Dictionary.AllocationSource table. Given a human-readable allocation source name (e.g., "Dealing Residuals", "Trading Residuals", "Trading Allocator"), it returns the corresponding numeric ID. This is the standard eToro pattern for resolving symbolic names to database IDs at the application boundary.

Allocation sources identify where trade execution residuals originate in the hedge/dealing pipeline. When the allocation engine distributes trade fills across customer positions, any residual amounts (fractional shares, rounding differences) are tracked by their source. The three allocation sources are:
- **Dealing Residuals** (ID=1): Residuals from the dealing desk's execution
- **Trading Residuals** (ID=2): Residuals from the automated trading engine
- **Trading Allocator** (ID=3): Residuals from the allocation engine itself

The procedure is consumed by Trade.GetAllocationData, Trade.GetAllocationDataResiduals, Trade.GetAleErrorReport, and related order execution reporting procedures via the ExternalOperations database (where the AllocationSource table also exists as a cross-database reference).

---

## 2. Business Logic

### 2.1 Name-to-ID Resolution Pattern

**What**: Converts human-readable allocation source names into database IDs for use in queries and storage.

**Columns/Parameters Involved**: `@AllocationSourceName` (input), `ID` (output)

**Rules**:
- Exact string match on AllocationSourceName column — case-sensitive comparison depends on database collation
- Returns empty result set (not NULL, not error) if the name doesn't exist — callers must handle no-result case
- No SET NOCOUNT ON — row count message is returned to the caller
- The AllocationSource table has a PK on ID with constraint named `pk_EMSOrders` (historical naming from the Execution Management System)

**Diagram**:
```
Application/Service Layer
│
├── Knows: "Dealing Residuals" (human name)
│
├── Calls: Dictionary.GetAllocationSourceID
│          @AllocationSourceName = 'Dealing Residuals'
│
│   ┌─────────────────────────────────────────┐
│   │ Dictionary.AllocationSource              │
│   │ ┌────┬──────────────────────┐           │
│   │ │ ID │ AllocationSourceName │           │
│   │ ├────┼──────────────────────┤           │
│   │ │  1 │ Dealing Residuals    │ ← MATCH  │
│   │ │  2 │ Trading Residuals    │           │
│   │ │  3 │ Trading Allocator    │           │
│   │ └────┴──────────────────────┘           │
│   └─────────────────────────────────────────┘
│
└── Returns: ID = 1
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| P1 | @AllocationSourceName | VARCHAR(50) | NO | - | VERIFIED | Input: The human-readable allocation source name to look up. Must exactly match one of: "Dealing Residuals" (ID=1), "Trading Residuals" (ID=2), "Trading Allocator" (ID=3). Case sensitivity depends on database collation. |
| R1 | ID | int | NO | - | VERIFIED | Output: The numeric identifier of the matching allocation source. Used as a foreign key in trade allocation and residual tracking tables. If no match is found, the result set is empty (zero rows). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AllocationSourceName | Dictionary.AllocationSource | WHERE lookup | Queries AllocationSource table by name to return ID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetAllocationData | - | EXEC | Resolves allocation source for fill distribution reporting |
| Trade.GetAllocationDataResiduals | - | EXEC | Residual allocation source resolution |
| Trade.GetAleErrorReport | - | EXEC | ALE error reporting with allocation context |
| Trade.GetAleErrorReportNew | - | EXEC | Updated ALE error reporting |
| Trade.GetAleErrorReportV2 | - | EXEC | V2 ALE error reporting |
| Trade.GetOrdersForExecutionReportDrillDown | - | EXEC | Order execution detail drill-down |
| ExternalOperations database | - | Cross-DB | AllocationSource table also exists in ExternalOperations schema |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetAllocationSourceID (procedure)
└── Dictionary.AllocationSource (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AllocationSource | Table | WHERE AllocationSourceName = @AllocationSourceName — exact match lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetAllocationData | Procedure | Allocation source resolution |
| Trade.GetAllocationDataResiduals | Procedure | Residual tracking |
| Trade.GetAleErrorReport | Procedure | Error reporting |
| Trade.GetAleErrorReportNew | Procedure | Updated error reporting |
| Trade.GetAleErrorReportV2 | Procedure | V2 error reporting |
| Trade.GetOrdersForExecutionReportDrillDown | Procedure | Execution detail reports |
| Trade.FunGetAleErrorReportNew | Function | ALE error function |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. The AllocationSource table has a clustered PK (`pk_EMSOrders`) on ID. The lookup is on AllocationSourceName which has no dedicated index — acceptable given the table has only 3 rows.

### 7.2 Constraints

None on the procedure. The AllocationSource table PK is named `pk_EMSOrders` (historical naming from the Execution Management System that originally owned this table).

---

## 8. Sample Queries

### 8.1 Look up Dealing Residuals allocation source
```sql
SELECT  ID
FROM    Dictionary.AllocationSource WITH (NOLOCK)
WHERE   AllocationSourceName = 'Dealing Residuals'
```

### 8.2 List all allocation sources
```sql
SELECT  ID, AllocationSourceName
FROM    Dictionary.AllocationSource WITH (NOLOCK)
ORDER BY ID
```

### 8.3 Check if an allocation source name exists
```sql
SELECT  CASE WHEN EXISTS (
            SELECT 1 FROM Dictionary.AllocationSource WITH (NOLOCK)
            WHERE AllocationSourceName = 'Trading Allocator'
        ) THEN 'Exists' ELSE 'Not Found' END AS Result
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetAllocationSourceID | Type: Stored Procedure | Source: etoro/etoro/Dictionary/Stored Procedures/Dictionary.GetAllocationSourceID.sql*
