# Trade.ExchangeHedgeGroupsTbl

> TVP for bulk-inserting exchange-to-hedge-group mappings that configure which exchanges belong to which hedge groups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | ExchangeID, GroupID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.ExchangeHedgeGroupsTbl is a table-valued parameter used to bulk-add exchange-to-hedge-group associations. ExchangeID maps to Dictionary.Exchanges; GroupID maps to Trade.InstrumentGroups. The procedure Trade.AddExchangesHedgeGroups consumes this TVP via the @ExchangeGroups parameter to configure which exchanges belong to which hedge groups.

This supports operational setup and maintenance of hedge routing and exposure configuration. Multiple exchange-group pairs can be inserted in a single call.

---

## 2. Business Logic

### 2.1 Exchange-to-group mapping

**What**: Each row links an exchange to an instrument group (hedge group). AddExchangesHedgeGroups inserts these mappings.

**Columns/Parameters Involved**: ExchangeID, GroupID

**Rules**: ExchangeID must reference Dictionary.Exchanges. GroupID must reference Trade.InstrumentGroups. Duplicate pairs may be rejected by the procedure.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | No | - | 10 | Exchange (Dictionary.Exchanges) |
| 2 | GroupID | int | No | - | 10 | Hedge group (Trade.InstrumentGroups) |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Dictionary.Exchanges (ExchangeID) | Implicit reference |
| Trade.InstrumentGroups (GroupID) | Implicit reference |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.AddExchangesHedgeGroups | Parameter @ExchangeGroups |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Trade.AddExchangesHedgeGroups

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Add exchange-group mappings

```sql
DECLARE @ExchangeGroups Trade.ExchangeHedgeGroupsTbl;
INSERT INTO @ExchangeGroups (ExchangeID, GroupID)
VALUES (1, 10), (2, 10), (3, 11);
EXEC Trade.AddExchangesHedgeGroups @ExchangeGroups = @ExchangeGroups;
```

### 8.2 Build from staging table

```sql
DECLARE @EG Trade.ExchangeHedgeGroupsTbl;
INSERT INTO @EG (ExchangeID, GroupID)
SELECT ExchangeID, GroupID FROM Staging.ExchangeHedgeGroupMapping;
EXEC Trade.AddExchangesHedgeGroups @ExchangeGroups = @EG;
```

### 8.3 List type columns

```sql
SELECT c.name, t.name AS type_name
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'ExchangeHedgeGroupsTbl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure reference)*
*Sources: DDL, Trade.AddExchangesHedgeGroups procedure*
*Object: Trade.ExchangeHedgeGroupsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.ExchangeHedgeGroupsTbl.sql*
