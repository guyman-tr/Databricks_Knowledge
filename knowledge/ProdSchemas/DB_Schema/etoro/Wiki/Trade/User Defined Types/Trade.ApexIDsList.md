# Trade.ApexIDsList

> A table-valued parameter type for passing batches of Apex clearing broker account IDs (max 8 chars) to Data API procedures. Apex is the US-based clearing broker for eToro's US stock trading.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | ApexID (varchar(8)) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.ApexIDsList is a table-valued parameter type for passing sets of Apex account IDs to Trade Data API procedures. Apex is the US-based clearing broker that holds and settles eToro US stock positions. Each ApexID is a short identifier (max 8 characters) that maps to a customer's clearing account at Apex.

This type enables batch queries by Apex account: orders, positions, position changes, and aggregates. Data API procedures use it to filter responses to only the requested Apex accounts - critical for US stock operations and regulatory reporting. Without it, each Apex account would require a separate call.

Data flow: Data API clients (internal services, compliance tools) collect Apex IDs from configuration or user selection, populate the TVP, and pass it to GetOrdersForDataApi, GetPositionsForDataApi, GetPositionsChangesForDataApi, GetAggregatedPositionsForDataApi, or GetPositionsBreakdownForDataApi. The procedure JOINs against the TVP to restrict results.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a single-column utility type specialized for Apex account ID filtering.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ApexID | varchar(8) | NO | - | CODE-BACKED | Apex clearing broker account ID. Max 8 characters. Used to filter Data API results to specific US clearing accounts. Each ApexID maps to one or more eToro customers with US stock exposure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no declared FK. ApexID semantically references Apex clearing system account identifiers.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOrdersForDataApi | @ApexIDs (or similar) | Parameter (TVP) | Filters orders by Apex account |
| Trade.GetPositionsChangesForDataApi | @ApexIDs (or similar) | Parameter (TVP) | Filters position changes by Apex account |
| Trade.GetAggregatedPositionsForDataApi | @ApexIDs (or similar) | Parameter (TVP) | Filters aggregated positions by Apex account |
| Trade.GetPositionsForDataApi | @ApexIDs (or similar) | Parameter (TVP) | Filters positions by Apex account |
| Trade.GetPositionsBreakdownForDataApi | @ApexIDs (or similar) | Parameter (TVP) | Filters position breakdown by Apex account |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrdersForDataApi | Stored Procedure | READONLY parameter for order filtering |
| Trade.GetPositionsChangesForDataApi | Stored Procedure | READONLY parameter for position changes |
| Trade.GetAggregatedPositionsForDataApi | Stored Procedure | READONLY parameter for aggregated positions |
| Trade.GetPositionsForDataApi | Stored Procedure | READONLY parameter for positions |
| Trade.GetPositionsBreakdownForDataApi | Stored Procedure | READONLY parameter for position breakdown |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate ApexIDsList for Data API position query

```sql
DECLARE @ApexIDs Trade.ApexIDsList;
INSERT INTO @ApexIDs (ApexID) VALUES ('APX001'), ('APX002'), ('APX003');
EXEC Trade.GetPositionsForDataApi @ApexIDs = @ApexIDs;
```

### 8.2 Populate ApexIDsList from a table of active US accounts

```sql
DECLARE @ApexIDs Trade.ApexIDsList;
INSERT INTO @ApexIDs (ApexID)
SELECT  DISTINCT ApexID
FROM    Customer.USAccountTbl WITH (NOLOCK)
WHERE   IsActive = 1;

EXEC Trade.GetAggregatedPositionsForDataApi @ApexIDs = @ApexIDs;
```

### 8.3 Single Apex account for order retrieval

```sql
DECLARE @ApexIDs Trade.ApexIDsList;
INSERT INTO @ApexIDs (ApexID) VALUES ('APX12345');
EXEC Trade.GetOrdersForDataApi @ApexIDs = @ApexIDs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ApexIDsList | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.ApexIDsList.sql*
