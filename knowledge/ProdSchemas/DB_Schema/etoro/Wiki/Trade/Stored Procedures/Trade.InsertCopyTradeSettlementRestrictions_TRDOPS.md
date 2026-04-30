# Trade.InsertCopyTradeSettlementRestrictions_TRDOPS

> TRDOPS-access variant of InsertCopyTradeSettlementRestrictions: bulk-inserts copy-trade settlement restriction rows from the TRDOPS-typed TVP, adding AccountTypeID support compared to the base variant.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RequestedRestrictionsTable Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertCopyTradeSettlementRestrictions_TRDOPS is the **TRDOPS-path write gateway** for copy-trading settlement restrictions. It is the sibling of `Trade.InsertCopyTradeSettlementRestrictions` and performs the same function - validating and bulk-inserting restriction configuration rows into `Trade.CopyTradeSettlementRestrictions` - but uses the `Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS` TVP type, which additionally carries an `AccountTypeID` column.

The _TRDOPS suffix indicates this SP is called through the Trading Operations (TRDOPS) access context, which is a separate permission boundary used by the operational tooling (e.g., the TRDOPS portal). The functional difference from the base SP is the inclusion of `AccountTypeID` in the INSERT, allowing TRDOPS users to set account-type-specific restrictions directly.

Data flow is identical to the base SP: caller builds a TVP of type `Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS`, validates (RAISERROR on unknown RestrictionTypeIDs), sets CONTEXT_INFO for auditing, and bulk-inserts.

---

## 2. Business Logic

### 2.1 RestrictionTypeID Validation (Identical to Base SP)

**What**: Rejects the entire batch if any row contains a RestrictionTypeID not in Dictionary.RestrictionType.

**Columns/Parameters Involved**: `RestrictionTypeID` (in TVP), `Dictionary.RestrictionType.RestrictionTypeID`

**Rules**:
- Same EXISTS check as base SP
- RAISERROR severity 16, RETURN on failure
- All-or-nothing: one bad row aborts the whole batch

### 2.2 Operator Audit via CONTEXT_INFO (Identical to Base SP)

**What**: Propagates operator identity for system-versioning audit.

**Rules**:
- If `@AppLoginName != ''`: cast to VARBINARY(128) and SET CONTEXT_INFO
- Default: empty string, no context info set

### 2.3 AccountTypeID - TRDOPS Extension

**What**: The TRDOPS TVP includes `AccountTypeID`, enabling restrictions scoped to a specific account type (e.g., Real vs Demo).

**Columns Inserted**: `CountryID`, `RegulationID`, `AccountTypeID`, `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `RestrictionTypeID`, `UnblockReasonId`, `GroupID`, `RegistrationDate`

**Rules**:
- `AccountTypeID` is included in the INSERT column list - the base SP omits this column
- Allows TRDOPS operators to create account-type-scoped restrictions without a separate API call
- All other logic identical to `Trade.InsertCopyTradeSettlementRestrictions`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestedRestrictionsTable | Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS | NO | - | CODE-BACKED | TRDOPS-typed TVP (READONLY) containing the batch of restriction rows. Compared to the base UDT, this type includes `AccountTypeID`, enabling account-type-scoped restrictions. |
| 2 | @AppLoginName | VARCHAR(50) | YES | '' | CODE-BACKED | Operator login name for audit. When non-empty, cast to VARBINARY(128) and set as CONTEXT_INFO for the session. Identical semantics to the base SP. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (validates against) | Dictionary.RestrictionType | READER | Validates all RestrictionTypeIDs in TVP exist in the dictionary |
| (inserts into) | Trade.CopyTradeSettlementRestrictions | WRITER | Target table (same as base SP) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TRDOPS portal/API (external) | EXEC Trade.InsertCopyTradeSettlementRestrictions_TRDOPS | Caller | Called by Trading Operations tooling under TRDOPS permissions context |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertCopyTradeSettlementRestrictions_TRDOPS (procedure)
|- Dictionary.RestrictionType (table - cross-schema, validation)
|- Trade.CopyTradeSettlementRestrictions (table, write target)
`-- Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS (UDT, TVP type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RestrictionType | Table (cross-schema) | Validates RestrictionTypeIDs in TVP |
| Trade.CopyTradeSettlementRestrictions | Table | Insert destination |
| Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS | User-Defined Table Type | Parameter type; extends base UDT with AccountTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TRDOPS portal/API | Application | Calls this SP via TRDOPS permission context |
| Trade.InsertCopyTradeSettlementRestrictions | Procedure | Sibling - base variant (no AccountTypeID) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RestrictionTypeID validation | Pre-check | RAISERROR + RETURN if any TVP row has unknown RestrictionTypeID |
| CK_CopyTradeSettlementRestriction_Asset | Table CHECK (inherited) | At least one of InstrumentTypeID/ExchangeID/InstrumentID/GroupID non-NULL |
| CONTEXT_INFO | Session-level | Operator identity propagation for audit |
| AccountTypeID inclusion | Column list difference | This SP includes AccountTypeID in INSERT; base SP does not |

---

## 8. Sample Queries

### 8.1 Insert an account-type-scoped restriction via TRDOPS SP

```sql
DECLARE @Restrictions Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS
INSERT INTO @Restrictions (CountryID, RegulationID, AccountTypeID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID, UnblockReasonId, GroupID, RegistrationDate)
VALUES (35, NULL, 1, 5, NULL, NULL, 2, NULL, NULL, GETDATE())

EXEC Trade.InsertCopyTradeSettlementRestrictions_TRDOPS
    @RequestedRestrictionsTable = @Restrictions,
    @AppLoginName = 'trdops_user_jane'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers (TRDOPS external) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertCopyTradeSettlementRestrictions_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertCopyTradeSettlementRestrictions_TRDOPS.sql*
