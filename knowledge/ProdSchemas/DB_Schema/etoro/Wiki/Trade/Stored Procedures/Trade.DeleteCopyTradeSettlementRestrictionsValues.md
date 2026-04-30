# Trade.DeleteCopyTradeSettlementRestrictionsValues

> Removes copy-trade settlement restrictions matching extended multi-column criteria (country, regulation, instrument type, exchange, instrument, unblock reason, group, registration date, restriction type) with audit trail support.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RequestedRestrictionsTable (TVP of restriction criteria to match and delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteCopyTradeSettlementRestrictionsValues is an extended version of Trade.DeleteCopyTradeSettlementRestriction that supports additional matching dimensions (UnblockReasonId, GroupID, RegistrationDate) and provides audit trail capability via CONTEXT_INFO. It removes specific copy-trade settlement restriction rules from Trade.CopyTradeSettlementRestrictions based on a richer set of criteria.

This procedure exists to allow fine-grained removal of restriction rules that include group-level and registration-date-based restrictions. The audit trail (@AppLoginName written to CONTEXT_INFO) enables temporal table or trigger-based tracking of who made the change.

Data flow: The caller provides a TVP and optionally an app login name. If login name is provided, it is stored in CONTEXT_INFO for audit purposes. Then matching rows are deleted using NULL-safe equality across 9 dimensions.

---

## 2. Business Logic

### 2.1 Extended Multi-Dimensional NULL-Safe Matching

**What**: Restriction rows are matched on 9 dimensions with NULL treated as a wildcard match.

**Columns/Parameters Involved**: `CountryID`, `RegulationID`, `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `UnblockReasonId`, `GroupID`, `RegistrationDate`, `RestrictionTypeID`

**Rules**:
- Same NULL-safe pattern as DeleteCopyTradeSettlementRestriction but with 3 additional dimensions
- UnblockReasonId, GroupID, and RegistrationDate all use NULL-safe comparison
- RestrictionTypeID remains strict equality (never NULL)

### 2.2 Audit Trail via CONTEXT_INFO

**What**: Records the application login name for change tracking.

**Columns/Parameters Involved**: `@AppLoginName`

**Rules**:
- When @AppLoginName is non-empty, it is cast to VARBINARY(128) and set as CONTEXT_INFO
- This value is available to triggers or temporal table history for audit purposes
- When empty, no CONTEXT_INFO is set (anonymous operation)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestedRestrictionsTable | Trade.CopyTradeSettlementRestrictionsTbl (READONLY) | NO | - | CODE-BACKED | TVP containing extended restriction criteria to match for deletion. Includes CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, UnblockReasonId, GroupID, RegistrationDate, and RestrictionTypeID. |
| 2 | @AppLoginName | VARCHAR(50) | YES | '' | CODE-BACKED | Application login name for audit trail. When non-empty, stored in CONTEXT_INFO to enable change tracking via triggers or temporal tables. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (DELETE) | Trade.CopyTradeSettlementRestrictions | DELETER | Removes rows matching the 9-dimensional criteria |
| (@RequestedRestrictionsTable) | Trade.CopyTradeSettlementRestrictionsTbl | Type Reference | Uses this UDT for batch input |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteCopyTradeSettlementRestrictionsValues (procedure)
+-- Trade.CopyTradeSettlementRestrictions (table)
+-- Trade.CopyTradeSettlementRestrictionsTbl (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CopyTradeSettlementRestrictions | Table | DELETE target based on multi-column match |
| Trade.CopyTradeSettlementRestrictionsTbl | User Defined Type | Input parameter type |

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

### 8.1 Delete restrictions with audit trail

```sql
DECLARE @Restrictions Trade.CopyTradeSettlementRestrictionsTbl
INSERT INTO @Restrictions (CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, UnblockReasonId, GroupID, RegistrationDate, RestrictionTypeID)
VALUES (1, NULL, 5, NULL, NULL, NULL, 10, NULL, 2)
EXEC Trade.DeleteCopyTradeSettlementRestrictionsValues @RequestedRestrictionsTable = @Restrictions, @AppLoginName = 'admin@etoro.com'
```

### 8.2 Preview restrictions with extended dimensions

```sql
SELECT  CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID,
        UnblockReasonId, GroupID, RegistrationDate, RestrictionTypeID
FROM    Trade.CopyTradeSettlementRestrictions WITH (NOLOCK)
ORDER BY RestrictionTypeID, CountryID
```

### 8.3 Check CONTEXT_INFO for audit

```sql
SELECT CAST(CONTEXT_INFO() AS VARCHAR(50)) AS LastModifiedBy
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteCopyTradeSettlementRestrictionsValues | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteCopyTradeSettlementRestrictionsValues.sql*
