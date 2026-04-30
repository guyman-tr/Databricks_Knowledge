# Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS

> TRDOPS variant for removing copy-trade settlement restrictions, adding AccountTypeID to the matching criteria and using the TRDOPS-specific TVP type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RequestedRestrictionsTable (TRDOPS TVP of restriction criteria to match and delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS is the Trading Operations (TRDOPS) variant of Trade.DeleteCopyTradeSettlementRestrictionsValues. It adds AccountTypeID as an additional matching dimension and uses a dedicated TVP type (Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS). This procedure is called by the TRDOPS admin tooling when operations staff need to remove restriction rules that include account-type-specific criteria.

This variant exists because the TRDOPS interface manages restrictions at a more granular level that includes AccountTypeID, which the standard version does not support. The rest of the logic is identical: NULL-safe multi-dimensional matching with CONTEXT_INFO audit trail.

Data flow: Same as DeleteCopyTradeSettlementRestrictionsValues but with 10 matching dimensions (adding AccountTypeID). Audit trail via @AppLoginName and CONTEXT_INFO.

---

## 2. Business Logic

### 2.1 Extended Multi-Dimensional NULL-Safe Matching (10 dimensions)

**What**: Restriction rows are matched on 10 dimensions with NULL treated as a wildcard match.

**Columns/Parameters Involved**: `CountryID`, `RegulationID`, `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `AccountTypeID`, `UnblockReasonId`, `GroupID`, `RegistrationDate`, `RestrictionTypeID`

**Rules**:
- Same pattern as DeleteCopyTradeSettlementRestrictionsValues with added AccountTypeID dimension
- AccountTypeID uses NULL-safe comparison (NULL matches NULL, meaning "applies to all account types")
- RestrictionTypeID remains strict equality

### 2.2 Audit Trail via CONTEXT_INFO

**What**: Records the application login name for change tracking.

**Columns/Parameters Involved**: `@AppLoginName`

**Rules**:
- Same as DeleteCopyTradeSettlementRestrictionsValues
- @AppLoginName cast to VARBINARY(128) and set as CONTEXT_INFO when non-empty

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestedRestrictionsTable | Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS (READONLY) | NO | - | CODE-BACKED | TVP containing extended restriction criteria including AccountTypeID. 10 matching dimensions total. |
| 2 | @AppLoginName | VARCHAR(50) | YES | '' | CODE-BACKED | Application login name for audit trail. Stored in CONTEXT_INFO when non-empty. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (DELETE) | Trade.CopyTradeSettlementRestrictions | DELETER | Removes rows matching the 10-dimensional criteria |
| (@RequestedRestrictionsTable) | Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS | Type Reference | TRDOPS-specific UDT with AccountTypeID column |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS (procedure)
+-- Trade.CopyTradeSettlementRestrictions (table)
+-- Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CopyTradeSettlementRestrictions | Table | DELETE target based on 10-column match |
| Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS | User Defined Type | TRDOPS input parameter type |

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

### 8.1 Delete TRDOPS restrictions with audit trail

```sql
DECLARE @Restrictions Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS
INSERT INTO @Restrictions (CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, AccountTypeID, UnblockReasonId, GroupID, RegistrationDate, RestrictionTypeID)
VALUES (1, NULL, 5, NULL, NULL, 2, NULL, 10, NULL, 2)
EXEC Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS @RequestedRestrictionsTable = @Restrictions, @AppLoginName = 'trdops-admin'
```

### 8.2 Compare standard vs TRDOPS restriction counts

```sql
SELECT  RestrictionTypeID, AccountTypeID, COUNT(*) AS RuleCount
FROM    Trade.CopyTradeSettlementRestrictions WITH (NOLOCK)
GROUP BY RestrictionTypeID, AccountTypeID
ORDER BY RestrictionTypeID, AccountTypeID
```

### 8.3 Preview restrictions with AccountTypeID

```sql
SELECT  TOP 20 CountryID, RegulationID, InstrumentTypeID, AccountTypeID, RestrictionTypeID
FROM    Trade.CopyTradeSettlementRestrictions WITH (NOLOCK)
WHERE   AccountTypeID IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS.sql*
