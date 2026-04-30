# Trade.GetAleErrorReportV2

> V2 of the ALE error report - identical to V1 (GetAleErrorReport) with minor output column differences. Reports FOF and Allocation errors from Apex integration.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns combined FOF and Allocation error events (V2 output format) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is version 2 of the ALE error report, functionally identical to Trade.GetAleErrorReport. It reports failed operations from the Apex Logistics Engine integration - both FOF money transfer failures and stock allocation failures. The V2 difference from V1 is the absence of the ErrorMessage column in the final output (though it is still present in the CTE).

The procedure serves the same operations monitoring purpose as V1. See [Trade.GetAleErrorReport](Trade.GetAleErrorReport.md) for the full business context. V2 may have been introduced for a specific consumer that did not need the ErrorMessage column.

Data flows through the same path as GetAleErrorReport: synonym tables for FOF and Allocation events, UNION ALL CTE, filtered by multiple optional parameters, joined with Customer.CustomerStatic for CID resolution.

---

## 2. Business Logic

Same as Trade.GetAleErrorReport. See [Trade.GetAleErrorReport](Trade.GetAleErrorReport.md) Section 2 for details.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @date | DATE | YES | NULL | CODE-BACKED | Filter by event date. |
| 2 | @symbol | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by instrument symbol. |
| 3 | @instrumentID | INT | YES | NULL | CODE-BACKED | Filter by instrument ID. |
| 4 | @cid | INT | YES | NULL | CODE-BACKED | Filter by customer ID. |
| 5 | @isBuy | INT | YES | NULL | CODE-BACKED | Filter by direction. |
| 6 | @ExternalID | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by external request ID. |
| 7 | @apexAccountID | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by Apex account ID. |
| 8 | @AleMessageType | VARCHAR(30) | YES | NULL | CODE-BACKED | Filter by message type. |
| 9 | @pageNumber | INT | YES | 1 | CODE-BACKED | Page number for pagination. |
| 10 | @itemsPerPage | INT | YES | 100 | CODE-BACKED | Items per page. |

**Output columns:** Same as GetAleErrorReport minus ErrorMessage: Date, ExternalID, Status, Message, CID, Symbol, InstrumentID, IsBuy, ApexAccountID, AleType, ID, OrderID.

---

## 5. Relationships

Same as Trade.GetAleErrorReport. See [Trade.GetAleErrorReport](Trade.GetAleErrorReport.md) Section 5.

### 5.1 References To (this object points to)

Same dependency chain as Trade.GetAleErrorReport.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

Same as Trade.GetAleErrorReport. See [Trade.GetAleErrorReport](Trade.GetAleErrorReport.md) Section 6.

### 6.1 Objects This Depends On

Same as Trade.GetAleErrorReport.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get ALE errors for today

```sql
EXEC Trade.GetAleErrorReportV2 @date = '2026-03-16';
```

### 8.2 Get errors for a specific customer

```sql
EXEC Trade.GetAleErrorReportV2 @cid = 12345678, @pageNumber = 1, @itemsPerPage = 50;
```

### 8.3 Get allocation errors only

```sql
EXEC Trade.GetAleErrorReportV2 @AleMessageType = 'Allocation', @date = '2026-03-16';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAleErrorReportV2 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAleErrorReportV2.sql*
