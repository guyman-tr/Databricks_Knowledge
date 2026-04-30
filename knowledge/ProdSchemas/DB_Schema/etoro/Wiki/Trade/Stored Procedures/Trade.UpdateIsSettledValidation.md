# Trade.UpdateIsSettledValidation

> Pre-flight validation procedure for settlement type conversion (CFD<->REAL) that returns a result set listing all positions ineligible for the requested conversion and the specific reason each fails, enabling callers to screen positions before invoking UpdateIsSettled.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionIDsTbl.PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Before converting positions between CFD and REAL settlement using Trade.UpdateIsSettled, operational tooling should validate that all target positions are eligible for the conversion. This procedure checks each position against a set of business rules and returns only the positions that would fail, along with a descriptive reason. A clean run (empty result set) means all positions are eligible to proceed.

The validation checks vary by direction:

**CFD to REAL (IsSettledToSet = 1)**:
- Position must exist (not closed)
- Must be in a valid settlement state (0 or 1; not an unusual state)
- Must not already be REAL
- Must be non-leveraged (Leverage = 1)
- Must be a Buy position (not short)
- Must not be on Italian or Scandinavian exchanges (ExchangeID IN 15, 16, 17, 11, 14)

**REAL to CFD (IsSettledToSet = 0)**:
- Position must exist
- Must be in a valid settlement state
- Must not already be CFD
- Must not be in a redeem process (RedeemStatus > 0)

---

## 2. Business Logic

### 2.1 Multi-Condition Validation Filter

**What**: A single SELECT with a multi-condition WHERE clause returns only positions that fail at least one rule. For each failing position, a concatenated FailReason string lists all applicable failure reasons.

**Columns/Parameters Involved**: `Trade.Position.*`, `Trade.InstrumentMetaData.ExchangeID`, `@IsSettledToSet`

**Rules**:

| Condition | Direction | FailReason Token |
|-----------|-----------|-----------------|
| Position not found (NULL in LEFT JOIN) | Both | 'Position not found - might be closed;' |
| SettlementTypeID / IsSettled not in (0,1) | Both | 'Position is not REAL or CFD;' |
| Already in target state | Both | 'IsSettled already set to {0 or 1};' |
| Leverage > 1 | CFD->REAL only | 'leverage high - {N} (CFD2REAL);' |
| IsBuy = 0 (short position) | CFD->REAL only | 'Sell position(CFD2REAL);' |
| ExchangeID IN (15,16,17,11,14) | CFD->REAL only | '{Exchange} stock Exchange(CFD2REAL);' |
| RedeemStatus > 0 | REAL->CFD only | 'position in redeem(REAL2CFD);' |

**SettlementTypeID fallback**: `ISNULL(tp.SettlementTypeID, tp.IsSettled)` - if SettlementTypeID is NULL, falls back to IsSettled for the check. This handles older positions where SettlementTypeID was not yet populated.

### 2.2 Exchange Restriction for CFD->REAL

**What**: Certain exchanges are excluded from REAL stock settlement conversion.

**Columns/Parameters Involved**: `Trade.InstrumentMetaData.ExchangeID`, `Trade.InstrumentMetaData.Exchange`

**Rules**:
- ExchangeID IN (15, 16, 17, 11, 14): Italian and Scandinavian stock exchanges are not eligible for CFD->REAL conversion
- The Exchange name column is included in the FailReason string for human-readable reporting

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionIDsTbl | Trade.PositionIDsTbl (TVP, READONLY) | NO | - | CODE-BACKED | Batch of PositionIDs (bigint) to validate. All positions are checked; those failing one or more rules are returned in the result set. Positions that pass all rules are NOT returned (not included in result set). |
| 2 | @IsSettledToSet | bit | NO | - | CODE-BACKED | Target settlement state: 1 = validate for CFD->REAL conversion, 0 = validate for REAL->CFD conversion. Determines which direction-specific rules are applied. |

**Result set columns**:
| Column | Type | Description |
|--------|------|-------------|
| PositionID | bigint | The failing position |
| FailReason | varchar | Concatenated string of all failure reasons for this position, each terminated with ';' |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.Position | LEFT JOIN (read) | Retrieves current position state for validation (Leverage, IsBuy, IsSettled, SettlementTypeID, RedeemStatus) |
| InstrumentID | Trade.InstrumentMetaData | LEFT JOIN (read) | Retrieves ExchangeID and Exchange name for exchange restriction check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External settlement management tooling | Application call | Caller | No internal SP callers found; called before Trade.UpdateIsSettled to screen ineligible positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateIsSettledValidation (procedure)
|- Trade.Position (view) [LEFT JOIN - position state validation]
+-- Trade.InstrumentMetaData (table) [LEFT JOIN - exchange restriction check]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | LEFT JOIN: Reads Leverage, IsBuy, IsSettled, SettlementTypeID, RedeemStatus for validation |
| Trade.InstrumentMetaData | Table | LEFT JOIN via InstrumentID: Reads ExchangeID and Exchange name for CFD->REAL exchange restriction |
| Trade.PositionIDsTbl | User Defined Type | TVP type for @PositionIDsTbl |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External operational tooling | Application | Called as pre-flight check before Trade.UpdateIsSettled |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Result set = failures only | Design | Positions passing all validations are NOT returned; empty result = all eligible |
| SettlementTypeID fallback | Compatibility | ISNULL(tp.SettlementTypeID, tp.IsSettled) handles older positions without SettlementTypeID |
| Exchange restriction | Business rule | ExchangeID IN (15,16,17,11,14) = Italian and Scandinavian exchanges not eligible for CFD->REAL |
| No DML | Read-only | Validation only; no changes to any table |

---

## 8. Sample Queries

### 8.1 Validate positions before CFD to REAL conversion

```sql
DECLARE @Positions [Trade].[PositionIDsTbl]
INSERT INTO @Positions (PositionID)
VALUES (100001), (100002), (100003)

-- Returns only FAILING positions with FailReason
-- Empty result = all positions are eligible
EXEC Trade.UpdateIsSettledValidation
    @PositionIDsTbl = @Positions,
    @IsSettledToSet = 1   -- Validate for CFD->REAL
```

### 8.2 Validate positions before REAL to CFD conversion

```sql
DECLARE @Positions [Trade].[PositionIDsTbl]
INSERT INTO @Positions (PositionID)
VALUES (100001), (100002)

EXEC Trade.UpdateIsSettledValidation
    @PositionIDsTbl = @Positions,
    @IsSettledToSet = 0   -- Validate for REAL->CFD
```

### 8.3 Check current settlement state of positions

```sql
SELECT
    tp.PositionID,
    tp.IsSettled,
    tp.SettlementTypeID,
    tp.Leverage,
    tp.IsBuy,
    tp.RedeemStatus,
    tm.ExchangeID,
    tm.Exchange
FROM Trade.Position tp WITH (NOLOCK)
LEFT JOIN Trade.InstrumentMetaData tm WITH (NOLOCK) ON tm.InstrumentID = tp.InstrumentID
WHERE tp.PositionID IN (100001, 100002, 100003)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateIsSettledValidation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateIsSettledValidation.sql*
