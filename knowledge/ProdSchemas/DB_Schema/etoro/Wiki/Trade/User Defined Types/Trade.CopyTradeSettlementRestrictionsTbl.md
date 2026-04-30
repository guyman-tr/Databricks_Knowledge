# Trade.CopyTradeSettlementRestrictionsTbl

> A table-valued parameter type for batch insert and delete of copy-trade settlement restrictions, controlling which instruments copy traders can trade as real stock vs CFD based on country, regulation, instrument type, exchange, and instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | RestrictionTypeID (only required field) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.CopyTradeSettlementRestrictionsTbl is a table-valued parameter (TVP) type used to pass batches of copy-trade settlement restriction rules into procedures. Copy trading allows users to automatically mirror trades from leader accounts. Settlement restrictions control whether a position is opened as real stock (actual ownership) or CFD (contract for difference) - a critical distinction for regulatory compliance and margin treatment.

Without this type, restriction management would require row-by-row procedure calls. Compliance and Trading Operations teams bulk-load restrictions from config sources; the TVP enables efficient batch insert and delete operations against the settlement restrictions table.

Data flows into procedures Trade.InsertCopyTradeSettlementRestrictions and Trade.DeleteCopyTradeSettlementRestrictionsValues. Each row defines a restriction rule that can be scoped by country, regulation, instrument type, exchange, or specific instrument. RestrictionTypeID is the only required field; other columns narrow the scope. UnblockReasonId records why a restriction was removed. GroupID groups related rules. RegistrationDate captures when the restriction took effect.

---

## 2. Business Logic

### 2.1 Restriction Scope Hierarchy

**What**: Restrictions can be defined at multiple granularity levels - from broad (all instruments in a country) to narrow (one specific instrument).

**Columns/Parameters Involved**: `CountryID`, `RegulationID`, `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `RestrictionTypeID`

**Rules**:
- RestrictionTypeID is always required; it defines the restriction category
- Narrower scopes (InstrumentID) override broader scopes (CountryID) when both apply
- NULL in a scope column means "all" for that dimension (e.g., NULL CountryID = applies to all countries)
- The combination of non-NULL scope columns defines the target audience for the restriction

**Diagram**:
```
Broad                                                    Narrow
CountryID -> RegulationID -> InstrumentTypeID -> ExchangeID -> InstrumentID
(NULL = all)  (NULL = all)     (NULL = all)       (NULL = all)  (NULL = all)
```

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | YES | - | CODE-BACKED | Country scope for the restriction. NULL = applies to all countries. References country lookup; restricts copy-trade settlement for instruments in this jurisdiction. |
| 2 | RegulationID | int | YES | - | CODE-BACKED | Regulation scope. NULL = all regulations. Used to apply restrictions per regulatory regime (e.g., EU MiFID vs US). |
| 3 | InstrumentTypeID | int | YES | - | CODE-BACKED | Instrument category scope (e.g., stocks, ETFs, indices). NULL = all types. |
| 4 | ExchangeID | int | YES | - | CODE-BACKED | Exchange scope. NULL = all exchanges. Further narrows which instruments the restriction applies to. |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | Specific instrument scope. NULL = restriction applies at broader level. Most granular scope. |
| 6 | RestrictionTypeID | tinyint | NO | - | CODE-BACKED | Restriction category - the only required field. Defines what type of settlement restriction applies (e.g., block real stock, require CFD). |
| 7 | UnblockReasonId | int | NULL | - | CODE-BACKED | When deleting a restriction, records why it was removed. Tracks audit trail for compliance. NULL on insert. |
| 8 | GroupID | int | YES | - | CODE-BACKED | Groups related restrictions for batch management. Allows logical grouping of rules that were added together. |
| 9 | RegistrationDate | datetime | YES | - | CODE-BACKED | When the restriction took effect or was registered. Captures the effective date for audit and historical tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary/country lookup | Implicit | Country scope for restriction |
| RegulationID | Dictionary/regulation lookup | Implicit | Regulatory regime scope |
| InstrumentTypeID | Dictionary/instrument type | Implicit | Instrument category scope |
| ExchangeID | Dictionary/exchange lookup | Implicit | Exchange scope |
| InstrumentID | Trade.InstrumentTbl | Implicit | Specific instrument reference |
| RestrictionTypeID | Dictionary/restriction type | Implicit | Restriction category |
| UnblockReasonId | Dictionary/unblock reason | Implicit | Reason for removing restriction |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertCopyTradeSettlementRestrictions | @Restrictions (or similar TVP param) | Parameter (TVP) | Batch-inserts settlement restrictions |
| Trade.DeleteCopyTradeSettlementRestrictionsValues | @Restrictions (or similar TVP param) | Parameter (TVP) | Batch-deletes settlement restrictions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertCopyTradeSettlementRestrictions | Stored Procedure | READONLY parameter for batch insert |
| Trade.DeleteCopyTradeSettlementRestrictionsValues | Stored Procedure | READONLY parameter for batch delete |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert copy-trade settlement restrictions for a specific country

```sql
DECLARE @Restrictions Trade.CopyTradeSettlementRestrictionsTbl;
INSERT INTO @Restrictions (CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID, UnblockReasonId, GroupID, RegistrationDate)
VALUES (840, 1, 1, NULL, NULL, 2, NULL, 100, GETUTCDATE());

EXEC Trade.InsertCopyTradeSettlementRestrictions @Restrictions = @Restrictions;
```

### 8.2 Delete restrictions by GroupID

```sql
DECLARE @ToDelete Trade.CopyTradeSettlementRestrictionsTbl;
INSERT INTO @ToDelete (CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID, UnblockReasonId, GroupID, RegistrationDate)
SELECT  CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID, 1, GroupID, NULL
FROM    Trade.CopyTradeSettlementRestrictionsTbl WITH (NOLOCK)
WHERE   GroupID = 100;

EXEC Trade.DeleteCopyTradeSettlementRestrictionsValues @Restrictions = @ToDelete;
```

### 8.3 Build restriction batch from config source

```sql
DECLARE @Restrictions Trade.CopyTradeSettlementRestrictionsTbl;
INSERT INTO @Restrictions (CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID, GroupID, RegistrationDate)
SELECT  CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID, @BatchGroupID, GETUTCDATE()
FROM    ExternalConfigSource WITH (NOLOCK)
WHERE   EffectiveDate <= GETUTCDATE();
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CopyTradeSettlementRestrictionsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CopyTradeSettlementRestrictionsTbl.sql*
