# Trade.AddCopyTradeSettlementRestriction

> Bulk-inserts copy trade settlement restriction rules from a TVP into Trade.CopyTradeSettlementRestrictions, defining which instrument/country/regulation combinations are blocked for CopyTrader settlement.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RequestedRestrictionsTable (Trade.BulkCopyTradeSettlementRestrictionsTbl TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure adds new **copy trade settlement restrictions** that control which instrument/exchange/country/regulation combinations are blocked from being copied as real stock (settled) positions. When a CopyTrader leader opens a real stock position, the system checks these restrictions to determine whether the copier should receive a CFD position instead of a real stock copy.

These restrictions exist because regulatory rules differ by country and instrument type. For example, a copier in a jurisdiction that does not allow real stock ownership through copy trading would be restricted, and the system would convert their copy to a CFD.

The caller (typically an admin API or operations tool) populates a `Trade.BulkCopyTradeSettlementRestrictionsTbl` TVP with the restriction rules and passes it to this procedure for bulk insertion.

---

## 2. Business Logic

### 2.1 Bulk Insert Without Deduplication

**What**: The procedure performs a straight INSERT without checking for existing restrictions.

**Columns/Parameters Involved**: `CountryID`, `RegulationID`, `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `RestrictionTypeID`

**Rules**:
- All rows from the TVP are inserted into Trade.CopyTradeSettlementRestrictions
- No duplicate checking - if a restriction already exists, it will fail on any unique constraint
- No transaction wrapping - partial inserts are possible if an error occurs mid-batch
- The combination of columns defines the scope: a restriction can target a specific country + regulation + instrument type + exchange + instrument, or use NULLs/wildcards for broader rules

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestedRestrictionsTable | Trade.BulkCopyTradeSettlementRestrictionsTbl (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing the restriction rules to insert. Columns: CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID. Each row defines one restriction rule for copy trade settlement. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Trade.CopyTradeSettlementRestrictions | INSERT | Inserts restriction rules from the TVP |
| @RequestedRestrictionsTable | Trade.BulkCopyTradeSettlementRestrictionsTbl | Parameter (TVP) | Input type definition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Admin API / Operations tool) | - | Caller | Called to add new settlement restriction rules |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AddCopyTradeSettlementRestriction (procedure)
+-- Trade.CopyTradeSettlementRestrictions (table)
+-- Trade.BulkCopyTradeSettlementRestrictionsTbl (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CopyTradeSettlementRestrictions | Table | INSERT target for restriction rules |
| Trade.BulkCopyTradeSettlementRestrictionsTbl | User Defined Type | READONLY TVP parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Add a settlement restriction for a specific country and instrument type

```sql
DECLARE @Restrictions Trade.BulkCopyTradeSettlementRestrictionsTbl;
INSERT INTO @Restrictions (CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID)
VALUES (1, 2, 5, NULL, NULL, 1);

EXEC Trade.AddCopyTradeSettlementRestriction @RequestedRestrictionsTable = @Restrictions;
```

### 8.2 View current copy trade settlement restrictions

```sql
SELECT  CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID
FROM    Trade.CopyTradeSettlementRestrictions WITH (NOLOCK)
ORDER BY CountryID, InstrumentTypeID;
```

### 8.3 Check if a specific instrument is restricted for a country

```sql
SELECT  *
FROM    Trade.CopyTradeSettlementRestrictions WITH (NOLOCK)
WHERE   CountryID = 1
        AND (InstrumentID = 1001 OR InstrumentID IS NULL)
ORDER BY InstrumentID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AddCopyTradeSettlementRestriction | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AddCopyTradeSettlementRestriction.sql*
