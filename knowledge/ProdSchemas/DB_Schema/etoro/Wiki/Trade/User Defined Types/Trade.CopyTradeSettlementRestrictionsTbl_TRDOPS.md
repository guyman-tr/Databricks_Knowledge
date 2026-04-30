# Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS

> A table-valued parameter type for Trading Operations (TRDOPS) procedures that insert or delete copy-trade settlement restrictions. Identical to CopyTradeSettlementRestrictionsTbl but adds AccountTypeID, allowing restrictions to be scoped by account type (Private, Corporate, IB, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | RestrictionTypeID (required); CountryID, RegulationID, AccountTypeID, InstrumentTypeID, ExchangeID, InstrumentID, GroupID (scoping) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS is the Trading Operations (TRDOPS) variant of the copy-trade settlement restrictions TVP. It mirrors CopyTradeSettlementRestrictionsTbl but adds AccountTypeID, enabling restrictions to be scoped by account type - Private, Corporate, Introducing Broker (IB), etc.

This separation exists because Trading Operations manages a distinct set of procedures with account-type-aware logic. The TRDOPS procedures (InsertCopyTradeSettlementRestrictions_TRDOPS, DeleteCopyTradeSettlementRestrictionsValues_TRDOPS) use this type exclusively.

Without AccountTypeID, restrictions would apply uniformly across all account types. With it, TRDOPS can enforce different settlement rules for retail vs corporate vs IB accounts on the same instrument.

---

## 2. Business Logic

### 2.1 Hierarchical Scoping with Account Type

**What**: Restrictions are scoped by country, regulation, account type, instrument type, exchange, and instrument. Null means "all" at that level.

**Columns/Parameters Involved**: `CountryID`, `RegulationID`, `AccountTypeID`, `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `GroupID`

**Rules**:
- RestrictionTypeID is always required. Other columns are optional.
- AccountTypeID differentiates this type from CopyTradeSettlementRestrictionsTbl. NULL = all account types.
- NULL in any scoping column means the restriction applies to all values at that level.
- More specific combinations override broader ones when multiple rows match.

**Diagram**:
```
CountryID -> RegulationID -> AccountTypeID -> InstrumentTypeID -> ExchangeID -> InstrumentID
   |              |                |                  |               |              |
  broad      regulatory      TRDOPS-specific      asset class     venue      instrument
  (null=all) (null=all)      (null=all)         (null=all)   (null=all)   (null=all)
```

### 2.2 Unblock and Registration Metadata

**What**: UnblockReasonId and RegistrationDate support audit and lifecycle tracking.

**Columns/Parameters Involved**: `UnblockReasonId`, `RegistrationDate`

**Rules**:
- Same semantics as CopyTradeSettlementRestrictionsTbl. UnblockReasonId tracks why a restriction was removed; RegistrationDate captures when it took effect.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | YES | - | CODE-BACKED | Country identifier. NULL = all countries. Restricts copy-trade settlement by customer country. |
| 2 | RegulationID | int | YES | - | CODE-BACKED | Regulation identifier. NULL = all regulations. Scopes by regulatory regime. |
| 3 | AccountTypeID | int | YES | - | CODE-BACKED | Account type identifier. NULL = all account types. TRDOPS-specific: scopes by Private, Corporate, IB, etc. Differentiates this type from CopyTradeSettlementRestrictionsTbl. |
| 4 | InstrumentTypeID | int | YES | - | CODE-BACKED | Instrument type identifier. NULL = all types. Scopes by asset class. |
| 5 | ExchangeID | int | YES | - | CODE-BACKED | Exchange identifier. NULL = all exchanges. Scopes by trading venue. |
| 6 | InstrumentID | int | YES | - | CODE-BACKED | Instrument identifier. NULL = all instruments. Most specific scoping level. |
| 7 | RestrictionTypeID | tinyint | NO | - | CODE-BACKED | Restriction type - the only required field. Defines the kind of restriction. Dictionary lookup. |
| 8 | UnblockReasonId | int | YES | - | CODE-BACKED | Reason why a restriction was removed. Maps to unblock reason lookup table. |
| 9 | GroupID | int | YES | - | CODE-BACKED | Groups related restrictions for batch operations or logical grouping. |
| 10 | RegistrationDate | datetime | YES | - | CODE-BACKED | When the restriction took effect or was registered. Audit and lifecycle tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no declared outgoing references. All ID columns semantically reference lookup tables, but there are no FK constraints on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertCopyTradeSettlementRestrictions_TRDOPS | @Table parameter | Parameter (TVP) | TRDOPS batch insert of settlement restrictions with account-type scoping |
| Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS | @Table parameter | Parameter (TVP) | TRDOPS batch delete of settlement restrictions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertCopyTradeSettlementRestrictions_TRDOPS | Stored Procedure | READONLY parameter - TRDOPS batch insert |
| Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS | Stored Procedure | READONLY parameter - TRDOPS batch delete |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert TRDOPS restrictions scoped by account type

```sql
DECLARE @Restrictions Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS;
INSERT INTO @Restrictions (CountryID, RegulationID, AccountTypeID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID, UnblockReasonId, GroupID, RegistrationDate)
VALUES (1, 2, 1, 1, NULL, NULL, 3, NULL, 100, GETUTCDATE()),
       (1, 2, 2, 1, NULL, NULL, 3, NULL, 100, GETUTCDATE());
EXEC Trade.InsertCopyTradeSettlementRestrictions_TRDOPS @Restrictions = @Restrictions;
```

### 8.2 Delete TRDOPS restrictions by group

```sql
DECLARE @ToDelete Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS;
INSERT INTO @ToDelete (CountryID, RegulationID, AccountTypeID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID, UnblockReasonId, GroupID, RegistrationDate)
SELECT  CountryID, RegulationID, AccountTypeID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID, 5, GroupID, NULL
FROM    Trade.CopyTradeSettlementRestrictions_BaseTable WITH (NOLOCK)
WHERE   GroupID = 100;
EXEC Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS @Restrictions = @ToDelete;
```

### 8.3 Insert restriction for specific account type and instrument

```sql
DECLARE @Restrictions Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS;
INSERT INTO @Restrictions (CountryID, RegulationID, AccountTypeID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID, UnblockReasonId, GroupID, RegistrationDate)
VALUES (NULL, NULL, 1, NULL, NULL, 12345, 3, NULL, NULL, GETUTCDATE());
EXEC Trade.InsertCopyTradeSettlementRestrictions_TRDOPS @Restrictions = @Restrictions;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS.sql*
