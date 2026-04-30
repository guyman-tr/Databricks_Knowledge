# Trade.OrderForOpenSummaryReportData

> Memory-optimized TVP for open-order summary: CID, OpenCorrelationID, MirrorID, and Units per open correlation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | OpenCorrelationID |
| **Partition** | N/A |
| **Indexes** | 1 (IDX_OpenCorrelationID nonclustered) |

---

## 1. Business Meaning

Trade.OrderForOpenSummaryReportData is a memory-optimized table-valued parameter type for open-order execution summaries. Each row associates a customer (CID), an open correlation ID (grouping related opens), a mirror ID (copy-trade context), and the units opened. It supports reporting and reconciliation of open-order execution.

This type exists to aggregate open-order results by correlation. Procedures such as OrderForOpenUpdate use it as a local table variable (currently commented) for open-execution summary reporting.

The type flows as a local table variable within procedures that execute open orders. Results are inserted per open correlation and used for JOINs or output.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type groups open-execution identifiers (CID, OpenCorrelationID, MirrorID) with units.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. |
| 2 | OpenCorrelationID | uniqueidentifier | NO | - | CODE-BACKED | Groups related open orders in a single execution batch. |
| 3 | MirrorID | int | NO | - | CODE-BACKED | Copy-trade mirror. |
| 4 | Units | decimal(16,6) | NO | - | CODE-BACKED | Units opened. |

---

## 5. Relationships

### 5.1 References To (this object points to)

CID references Customer; MirrorID references copy-trade mirror entities. No declared FK on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenUpdate | @ExecutionSummaryReport (commented) | Local variable (TVP) | Open-execution summary; usage currently commented out |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpenUpdate | Stored Procedure | Local table variable for open summary (commented) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Columns |
|------------|------|---------|
| IDX_OpenCorrelationID | NONCLUSTERED | OpenCorrelationID |

Memory-optimized type (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate OrderForOpenSummaryReportData

```sql
DECLARE @ExecutionSummaryReport [Trade].[OrderForOpenSummaryReportData];
INSERT INTO @ExecutionSummaryReport (CID, OpenCorrelationID, MirrorID, Units)
VALUES (50001, NEWID(), 100, 1000.5);
```

### 8.2 Populate from open execution batch

```sql
INSERT INTO @ExecutionSummaryReport (CID, OpenCorrelationID, MirrorID, Units)
SELECT @CID, @OpenCorrelationID, @MirrorID, @Units;
```

### 8.3 Multiple rows per correlation

```sql
INSERT INTO @ExecutionSummaryReport (CID, OpenCorrelationID, MirrorID, Units)
VALUES (50001, @CorrID, 100, 500),
       (50001, @CorrID, 101, 500);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderForOpenSummaryReportData | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OrderForOpenSummaryReportData.sql*
