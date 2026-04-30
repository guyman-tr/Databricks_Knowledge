# Trade.BulkCopyTradeSettlementRestrictionsTbl

> A table-valued parameter type for bulk-adding or deleting copy-trade settlement restrictions. Controls which instruments copy traders can trade as settled (real stock) vs CFD, based on country, regulation, instrument type, exchange, or specific instrument. RestrictionTypeID is required; other columns are nullable filters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | Composite (CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.BulkCopyTradeSettlementRestrictionsTbl is a table-valued parameter type for bulk operations on copy-trade settlement restrictions. Settlement restrictions determine whether copy traders can hold positions as real stock (settled) or only as CFD, based on jurisdiction, regulation, instrument type, exchange, or specific instrument. This supports compliance and product rules across regions.

This type enables bulk add and delete via Trade.AddCopyTradeSettlementRestriction and Trade.DeleteCopyTradeSettlementRestriction. Configuration jobs or admin tools populate the TVP with restriction rows - RestrictionTypeID is required; CountryID, RegulationID, InstrumentTypeID, ExchangeID, and InstrumentID are optional filters that narrow the scope. A row with only RestrictionTypeID applies broadly; adding filters narrows to specific combinations.

Data flow: Config scripts or admin UI build the TVP from policy rules (e.g., "block real stock for instrument type X in regulation Y"), then call Add or Delete. The procedure applies each row as a new restriction or removes matching restrictions. Nullable filter columns allow coarse (regulation-wide) or fine (instrument-specific) scoping.

---

## 2. Business Logic

### 2.1 Restriction Scope Hierarchy

**What**: Restriction rows can be broad (RestrictionTypeID only) or narrow (additional filters).

**Columns/Parameters Involved**: `CountryID`, `RegulationID`, `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `RestrictionTypeID`

**Rules**:
- RestrictionTypeID is the only NOT NULL column - it defines the restriction type
- CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID are nullable filters
- When NULL, that dimension is "all" - e.g., NULL CountryID means applies to all countries
- More filters = more specific rule: InstrumentID narrows to one instrument; ExchangeID to one exchange
- AddCopyTradeSettlementRestriction inserts; DeleteCopyTradeSettlementRestriction removes matching rows

**Diagram**:
```
RestrictionTypeID (required) + optional filters:
  CountryID? + RegulationID? + InstrumentTypeID? + ExchangeID? + InstrumentID?
  -> Broader (all NULL except RestrictionTypeID) to Narrower (all specified)
```

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | YES | - | CODE-BACKED | Country filter. When set, restriction applies only to this country. NULL = all countries. References Dictionary/Geography. |
| 2 | RegulationID | int | YES | - | CODE-BACKED | Regulation filter. When set, restriction applies only to this regulation. NULL = all regulations. |
| 3 | InstrumentTypeID | int | YES | - | CODE-BACKED | Instrument type filter (e.g., stock, crypto). When set, restriction applies only to this type. NULL = all types. |
| 4 | ExchangeID | int | YES | - | CODE-BACKED | Exchange filter. When set, restriction applies only to this exchange. NULL = all exchanges. |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | Instrument filter. When set, restriction applies only to this instrument. NULL = all instruments. Most specific filter. |
| 6 | RestrictionTypeID | tinyint | NO | - | CODE-BACKED | Restriction type. Required. Defines what kind of settlement restriction (e.g., block real, allow CFD only). References restriction type dictionary. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary/Geography | Lookup | Country filter |
| RegulationID | Dictionary | Lookup | Regulation filter |
| InstrumentTypeID | Instrument/Dictionary | Lookup | Instrument type filter |
| ExchangeID | Dictionary | Lookup | Exchange filter |
| InstrumentID | Instrument.InstrumentTbl | Implicit | Instrument filter |
| RestrictionTypeID | Dictionary | Lookup | Restriction type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.AddCopyTradeSettlementRestriction | @Restrictions (or similar) | Parameter (TVP) | Bulk-adds settlement restrictions |
| Trade.DeleteCopyTradeSettlementRestriction | @Restrictions (or similar) | Parameter (TVP) | Bulk-deletes settlement restrictions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.AddCopyTradeSettlementRestriction | Stored Procedure | READONLY parameter for bulk add |
| Trade.DeleteCopyTradeSettlementRestriction | Stored Procedure | READONLY parameter for bulk delete |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk-add restriction for a regulation and instrument type

```sql
DECLARE @Restrictions Trade.BulkCopyTradeSettlementRestrictionsTbl;
INSERT INTO @Restrictions (RegulationID, InstrumentTypeID, RestrictionTypeID)
VALUES (2, 1, 1);  -- Block real stock for instrument type 1 in regulation 2

EXEC Trade.AddCopyTradeSettlementRestriction @Restrictions = @Restrictions;
```

### 8.2 Bulk-add multiple restrictions for different scopes

```sql
DECLARE @Restrictions Trade.BulkCopyTradeSettlementRestrictionsTbl;
INSERT INTO @Restrictions (CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID)
VALUES (1, 1, 2, NULL, NULL, 1),   -- Country 1, Reg 1, Type 2
       (NULL, 2, 1, NULL, NULL, 2); -- All countries, Reg 2, Type 1

EXEC Trade.AddCopyTradeSettlementRestriction @Restrictions = @Restrictions;
```

### 8.3 Bulk-delete restrictions matching criteria

```sql
DECLARE @Restrictions Trade.BulkCopyTradeSettlementRestrictionsTbl;
INSERT INTO @Restrictions (RegulationID, InstrumentTypeID, RestrictionTypeID)
VALUES (2, 1, 1);

EXEC Trade.DeleteCopyTradeSettlementRestriction @Restrictions = @Restrictions;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BulkCopyTradeSettlementRestrictionsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.BulkCopyTradeSettlementRestrictionsTbl.sql*
