# Trade.UpdateInterestRateOverride

> Cursor-based upsert of instrument-specific interest rate overrides into Dictionary.InterestRateOverride, deriving SettlementTypeID from InstrumentGroups membership (GroupID=25 -> 4, else 0); intended to be replaced by UpdateInterestRateOverride_TRDOPS.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UpdateInterestRateOverrideTbl.(InterestRateOverrideID OR InstrumentID+ExchangeID+InstrumentTypeID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.InterestRateOverride allows per-instrument interest rate customization that overrides the base Dictionary.InterestRate rates for specific instruments (identified by InstrumentID+ExchangeID+InstrumentTypeID). This supports cases where a specific instrument needs a financing rate different from its instrument type's default - for example, a crypto asset with unusually high overnight costs or a promotional rate for a specific stock.

This procedure performs a two-path upsert:
- If a row is identified by InterestRateOverrideID and already exists with the derived SettlementTypeID -> UPDATE it
- If no such row exists but the natural key (InstrumentTypeID, InstrumentID, ExchangeID) also doesn't exist -> INSERT

The SettlementTypeID is derived from Trade.InstrumentGroups membership (same rule as UpdateInstrumentToFeeConfigTable): if the instrument belongs to GroupID = 25, SettlementTypeID = 4 (crypto TRS); otherwise SettlementTypeID = 0 (standard). This derivation means the TVP does not require callers to know the settlement type, maintaining backward compatibility.

The code has a comment "Temporary. Only for backwards compatibility, should be removed in the future" on the SettlementTypeID derivation block. The TRDOPS variant (Trade.UpdateInterestRateOverride_TRDOPS) was created to replace this with a direct settlement type pass-through.

The procedure uses a CURSOR loop rather than a set-based approach - a design from an earlier era of the codebase. No internal SP callers were found.

---

## 2. Business Logic

### 2.1 SettlementTypeID Derivation from InstrumentGroups

**What**: SettlementTypeID is derived for each row from InstrumentGroups membership rather than passed by the caller.

**Columns/Parameters Involved**: `InstrumentID`, `Trade.InstrumentGroups.GroupID`

**Rules**:
- LEFT JOIN Trade.InstrumentGroups g ON g.InstrumentID = t.InstrumentID AND g.GroupID = 25
- SettlementTypeID = IIF(g.InstrumentID IS NULL, 0, 4)
- GroupID = 25: crypto TRS instruments -> SettlementTypeID = 4
- All other instruments -> SettlementTypeID = 0

### 2.2 Cursor-Based Two-Path Upsert

**What**: Each row in the TVP is processed individually via a CURSOR, applying one of three paths.

**Columns/Parameters Involved**: `InterestRateOverrideID`, `InstrumentID`, `ExchangeID`, `InstrumentTypeID`, `SettlementTypeID` (derived)

**Rules**:
- Path 1 (UPDATE by ID): If @InterestRateOverrideID IS NOT NULL AND row exists in Dictionary.InterestRateOverride with matching (InterestRateOverrideID, SettlementTypeID) -> UPDATE 4 rate fields + UpdatedByUser
- Path 2 (INSERT by natural key): ELSE IF natural key (InstrumentTypeID, InstrumentID, ExchangeID) does NOT exist -> INSERT new row with all fields including derived SettlementTypeID
- Path 3 (no-op): If the natural key already exists but InterestRateOverrideID lookup failed -> no action (silent skip)

**Diagram**:
```
For each row in TVP (cursor iteration):
  Derive SettlementTypeID from InstrumentGroups
    |
    +-- InterestRateOverrideID exists in Dictionary.InterestRateOverride
    |   with matching SettlementTypeID?
    |     YES -> UPDATE rates + UpdatedByUser
    |
    +-- InterestRateOverrideID NOT found -> check natural key
          (InstrumentTypeID, InstrumentID, ExchangeID) NOT in table?
            YES -> INSERT new row
            NO  -> silent skip (no update)
```

### 2.3 UpdateRowCount Output

**What**: Returns a count of rows actually changed (updated or inserted).

**Columns/Parameters Involved**: `@UpdateRowCount`

**Rules**:
- `SET @UpdateRowCount = @UpdateRowCount + @@ROWCOUNT` after each successful UPDATE or INSERT
- The cumulative count returned to the caller on output

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UpdateInterestRateOverrideTbl | Trade.UpdateInterestRateOverrideTbl (TVP, READONLY) | NO | - | CODE-BACKED | Batch of interest rate override updates. All key fields nullable: InterestRateOverrideID (int NULL - if provided, used as primary lookup key), InstrumentID (int NULL), ExchangeID (int NULL), InstrumentTypeID (int NULL). Rate fields: InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell (all decimal(16,8) NOT NULL). No SettlementTypeID column - derived internally from InstrumentGroups.GroupID=25. |
| 2 | @UserName | nvarchar(50) | NO | - | CODE-BACKED | Username or service name written to Dictionary.InterestRateOverride.UpdatedByUser for audit trail. |
| 3 | @UpdateRowCount | int (OUTPUT) | NO | - | CODE-BACKED | Cumulative count of rows actually modified (updated or inserted) during cursor execution. Incremented by @@ROWCOUNT after each successful DML operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.InstrumentGroups | Lookup JOIN | GroupID=25 membership used to derive SettlementTypeID (4 if crypto TRS, else 0) |
| InterestRateOverrideID + SettlementTypeID | Dictionary.InterestRateOverride | UPDATE | Updates 4 rate fields when row found by ID + derived SettlementTypeID |
| (InstrumentTypeID, InstrumentID, ExchangeID) | Dictionary.InterestRateOverride | INSERT | Inserts new row when natural key not found |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External rate management tooling | Application call | Caller | No internal SP callers found; called from rate management systems for instrument-specific interest rate overrides |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInterestRateOverride (procedure) [BACKWARD COMPAT - derives SettlementTypeID internally]
|- Trade.InstrumentGroups (table) [READ - GroupID=25 for SettlementTypeID derivation]
+-- Dictionary.InterestRateOverride (table) [UPDATE + INSERT - interest rate overrides]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentGroups | Table | READ: GroupID=25 lookup to derive SettlementTypeID per instrument |
| Dictionary.InterestRateOverride | Table | UPDATEd (when row found by InterestRateOverrideID + SettlementTypeID) or INSERTed (when natural key not found) |
| Trade.UpdateInterestRateOverrideTbl | User Defined Type | TVP type for @UpdateInterestRateOverrideTbl |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External rate management application | Application | Calls this deprecated procedure; should migrate to Trade.UpdateInterestRateOverride_TRDOPS |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SettlementTypeID derivation | Backward compatibility | IIF(g.InstrumentID IS NULL, 0, 4) from InstrumentGroups.GroupID=25; comment: "Temporary. Only for backwards compatibility" |
| Cursor processing | Design | Row-by-row CURSOR FETCH rather than set-based DML; ORDER BY InstrumentID DESC |
| Silent skip on path 3 | Behavior | If ID lookup fails AND natural key already exists -> no action, no error |
| No transaction | Design | No explicit transaction wrapper; cursor operations auto-commit per row |
| SET QUOTED_IDENTIFIER OFF | Session | Non-standard; double-quoted strings treated as string literals rather than identifiers |

---

## 8. Sample Queries

### 8.1 Update an existing override by ID

```sql
DECLARE @Overrides [Trade].[UpdateInterestRateOverrideTbl]
INSERT INTO @Overrides (InterestRateOverrideID, InstrumentID, ExchangeID, InstrumentTypeID,
                        InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell)
VALUES (101, 1234, 5, 1, 0.02000000, 0.02000000, 0.00500000, 0.00500000)

DECLARE @RowCount int = 0
EXEC Trade.UpdateInterestRateOverride
    @UpdateInterestRateOverrideTbl = @Overrides,
    @UserName = 'rate_admin',
    @UpdateRowCount = @RowCount OUTPUT

SELECT @RowCount AS RowsModified
```

### 8.2 Insert a new override (no existing InterestRateOverrideID)

```sql
DECLARE @Overrides [Trade].[UpdateInterestRateOverrideTbl]
INSERT INTO @Overrides (InterestRateOverrideID, InstrumentID, ExchangeID, InstrumentTypeID,
                        InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell)
VALUES (NULL, 5678, 10, 1, 0.03000000, 0.03000000, 0.00800000, 0.00800000)

DECLARE @RowCount int = 0
EXEC Trade.UpdateInterestRateOverride
    @UpdateInterestRateOverrideTbl = @Overrides,
    @UserName = 'rate_admin',
    @UpdateRowCount = @RowCount OUTPUT
```

### 8.3 Check current overrides for an instrument

```sql
SELECT
    iro.InterestRateOverrideID,
    iro.InstrumentID,
    iro.ExchangeID,
    iro.InstrumentTypeID,
    iro.SettlementTypeID,
    iro.InterestRateBuy,
    iro.InterestRateSell,
    iro.MarkupBuy,
    iro.MarkupSell,
    iro.UpdatedByUser
FROM Dictionary.InterestRateOverride iro WITH (NOLOCK)
WHERE iro.InstrumentID = 1234
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInterestRateOverride | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInterestRateOverride.sql*
