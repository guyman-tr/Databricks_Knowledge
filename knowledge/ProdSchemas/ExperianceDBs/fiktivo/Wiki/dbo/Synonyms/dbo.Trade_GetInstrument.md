# dbo.Trade_GetInstrument

> Synonym pointing to [AORealRO].[etoro].[Trade].[GetInstrument], providing local access to the instrument lookup object in the Trade schema without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AORealRO].[etoro].[Trade].[GetInstrument] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.Trade_GetInstrument is a synonym that provides a local reference to [AORealRO].[etoro].[Trade].[GetInstrument]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the AORealRO linked server (a read-only replica of the etoro production database) under the Trade schema. Based on the name, Trade.GetInstrument is a table, view, or stored procedure that provides instrument (financial instrument / trading asset) definitions and metadata -- such as instrument ID, name, asset class, and related properties. Instrument data is needed in the affiliate context to categorize trading activity by asset type (e.g., stocks, forex, crypto, commodities) for reporting and potentially for commission tier calculations.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [AORealRO].[etoro].[Trade].[GetInstrument].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [AORealRO].[etoro].[Trade].[GetInstrument] | Synonym | Points to the instrument lookup object on the AORealRO linked server |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.Trade_GetInstrument (synonym)
  +-- [AORealRO].[etoro].[Trade].[GetInstrument] (table/view/procedure on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AORealRO].[etoro].[Trade].[GetInstrument] | Table, View, or Procedure | Synonym target |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes
N/A for synonym.

### 7.2 Constraints
N/A for synonym.

---

## 8. Sample Queries

### 8.1 Query through the synonym
```sql
SELECT TOP 5 * FROM dbo.Trade_GetInstrument WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'Trade_GetInstrument'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.Trade_GetInstrument WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.Trade_GetInstrument | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.Trade_GetInstrument.sql*
