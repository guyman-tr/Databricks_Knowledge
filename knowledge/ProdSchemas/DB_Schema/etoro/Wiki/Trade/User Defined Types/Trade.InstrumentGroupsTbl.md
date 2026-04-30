# Trade.InstrumentGroupsTbl

> TVP for bulk-managing instrument-to-group memberships. Links provider, instrument, and group for insert and delete operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | ProviderID, InstrumentID, GroupID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.InstrumentGroupsTbl is a table-valued parameter for bulk-managing instrument-to-group memberships. Each row links a provider (ProviderID), instrument (InstrumentID), and group (GroupID). ProviderID references Trade.Provider, InstrumentID references Trade.Instrument, GroupID references Trade.InstrumentGroups. Used for both insert (add memberships) and delete (remove memberships) operations on the instrument group mapping.

---

## 2. Business Logic

### 2.1 Bulk insert and delete of instrument group memberships

**What**: The TVP passes rows linking instruments to groups per provider. InsertInstrumentGroup adds memberships; DeleteInstrumentGroup removes them.

**Columns/Parameters Involved**: ProviderID, InstrumentID, GroupID

**Rules**: All three IDs required. ProviderID, InstrumentID, and GroupID must exist in their respective tables. Same TVP shape used for both insert and delete.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | No | - | 10 | Provider identifier (Trade.Provider) |
| 2 | InstrumentID | int | No | - | 10 | Instrument identifier (Trade.Instrument) |
| 3 | GroupID | int | No | - | 10 | Instrument group identifier (Trade.InstrumentGroups) |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Trade.Provider (ProviderID) | Implicit reference |
| Trade.Instrument (InstrumentID) | Implicit reference |
| Trade.InstrumentGroups (GroupID) | Implicit reference |
| Trade instrument group mapping | Target for insert/delete |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.InsertInstrumentGroup | Parameter @InstrumentGroupsTable |
| Trade.DeleteInstrumentGroup | Parameter @DeleteInstrumentGroupsTable |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Trade.InsertInstrumentGroup
- Trade.DeleteInstrumentGroup

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert instrument group memberships

```sql
DECLARE @InstrumentGroupsTable Trade.InstrumentGroupsTbl;
INSERT INTO @InstrumentGroupsTable (ProviderID, InstrumentID, GroupID)
VALUES (1, 100, 5), (1, 101, 5), (1, 102, 6);
EXEC Trade.InsertInstrumentGroup @InstrumentGroupsTable = @InstrumentGroupsTable;
```

### 8.2 Delete instrument group memberships

```sql
DECLARE @DeleteInstrumentGroupsTable Trade.InstrumentGroupsTbl;
INSERT INTO @DeleteInstrumentGroupsTable (ProviderID, InstrumentID, GroupID)
VALUES (1, 100, 5), (1, 101, 5);
EXEC Trade.DeleteInstrumentGroup @DeleteInstrumentGroupsTable = @DeleteInstrumentGroupsTable;
```

### 8.3 Verify type columns

```sql
SELECT c.name, t.name AS type_name
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'InstrumentGroupsTbl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure references)*
*Sources: DDL, Trade.InsertInstrumentGroup, Trade.DeleteInstrumentGroup*
*Object: Trade.InstrumentGroupsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentGroupsTbl.sql*
