# Trade.TradingOperationTypeIDs

> TVP used to pass a list of trading operation type IDs for restriction lookup - restricts results to the specified operation types.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | TradingOperationTypeID (int, nullable) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

TradingOperationTypeIDs carries a set of trading operation type identifiers. Each row holds one TradingOperationTypeID (nullable int). The type models a simple ID list used to filter restriction lookups by operation type.

This type exists because GetRestrictionsByTradingOperationTypes needs to accept a variable list of operation types from the caller. Passing a TVP avoids dynamic SQL or string parsing and allows efficient JOIN/filtering.

The type flows from application or admin code into Trade.GetRestrictionsByTradingOperationTypes (and debug/test variants). Procedures JOIN the TVP against restriction tables to return only restrictions matching the given operation types.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-column list of IDs.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TradingOperationTypeID | int | YES | - | CODE-BACKED | Trading operation type identifier |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetRestrictionsByTradingOperationTypes | @OperationTypeIDs | Parameter (TVP) | Filters restrictions by operation type IDs |
| Trade.GetRestrictionsByTradingOperationTypes_Debug | @OperationTypeIDs | Parameter (TVP) | Debug variant of restriction lookup |
| Trade.GetRestrictionsByTradingOperationTypesTest | @OperationTypeIDs | Parameter (TVP) | Test variant of restriction lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetRestrictionsByTradingOperationTypes | Stored Procedure | READONLY parameter for restriction filter |
| Trade.GetRestrictionsByTradingOperationTypes_Debug | Stored Procedure | READONLY parameter for debug |
| Trade.GetRestrictionsByTradingOperationTypesTest | Stored Procedure | READONLY parameter for test |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get restrictions for specific operation types
```sql
DECLARE @OperationTypeIDs Trade.TradingOperationTypeIDs;
INSERT INTO @OperationTypeIDs (TradingOperationTypeID) VALUES (1), (2), (3);
EXEC Trade.GetRestrictionsByTradingOperationTypes @OperationTypeIDs = @OperationTypeIDs;
```

### 8.2 Single operation type filter
```sql
DECLARE @OperationTypeIDs Trade.TradingOperationTypeIDs;
INSERT INTO @OperationTypeIDs (TradingOperationTypeID) VALUES (5);
EXEC Trade.GetRestrictionsByTradingOperationTypes @OperationTypeIDs = @OperationTypeIDs;
```

### 8.3 Declare empty TVP (all operation types)
```sql
DECLARE @OperationTypeIDs Trade.TradingOperationTypeIDs;
EXEC Trade.GetRestrictionsByTradingOperationTypes @OperationTypeIDs = @OperationTypeIDs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 6.7/10 (Elements: 10/10, Logic: 2/10, Relationships: 3/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TradingOperationTypeIDs | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.TradingOperationTypeIDs.sql*
