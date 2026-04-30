# Trade.UpdateInstrumentToFeeConfigTable

> OBSOLETE backward-compatibility shim that converts the legacy V1 fee configuration TVP format to V2, applying SettlementTypeID derivation and CFD fee overrides, then delegates to Trade.UpdateInstrumentToFeeConfigTableV2. New callers should use UpdateInstrumentToFeeConfigTableV2 directly.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FeeValuesTbl.InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is explicitly marked obsolete in its source code comment: "This stored procedure is obsolete and created for backward compatibility. Will be removed in the future. Use Trade.UpdateInstrumentToFeeConfigTableV2 instead."

It exists to preserve compatibility with legacy callers that still send overnight/end-of-week fee data using the original V1 TVP format (InstrumentToFeeConfigType). The V1 format predates the addition of SettlementTypeID and FeeCalculationTypeID fields to the fee configuration model. This procedure acts as an adapter: it translates the V1 payload to V2, enriches it with SettlementTypeID (derived from InstrumentGroups membership) and FeeCalculationTypeID (preserved from the existing InstrumentToFeeConfigV2 rows), applies a CFD-specific fee override for eligible instrument types, and then calls the V2 procedure.

The procedure has no internal callers within the Trade stored procedure layer, suggesting the only consumers are external legacy applications that have not yet been migrated to the V2 interface.

---

## 2. Business Logic

### 2.1 V1 to V2 TVP Conversion

**What**: The V1 TVP (InstrumentToFeeConfigType) lacks SettlementTypeID and FeeCalculationTypeID. This procedure derives those missing values before calling V2.

**Columns/Parameters Involved**: `@FeeValuesTbl.InstrumentID`, `Trade.InstrumentGroups.GroupID`

**Rules**:
- SettlementTypeID derivation: 4 if the instrument is in InstrumentGroups with GroupID = 25, else 0
- GroupID = 25 identifies instruments using settlement type 4 (likely crypto TRS or a specific settlement class)
- FeeCalculationTypeID = 0 as default; then overridden by the current value from InstrumentToFeeConfigV2 if a matching row exists
- All other fee fields are copied directly from V1 to V2 with no transformation (same column names)

**Diagram**:
```
V1 TVP (@FeeValuesTbl)
  InstrumentID, 8 fee fields (NonLeveraged/Leveraged Buy/Sell EOW/ON)
  + NonLeveragedBuyCFDOverNightFee (V1-only field for CFD override)
    |
    Step 1: Build @FeeValuesTblV2
      SettlementTypeID = CASE InstrumentGroups.GroupID = 25 THEN 4 ELSE 0
      FeeCalculationTypeID = 0 (default)
      Fee fields copied as-is
    |
    Step 2: CFD override (for CFD-eligible instrument types)
      WHERE SettlementTypeID = 0 (CFD instruments)
      SET NonLeveragedBuyOverNightFee = V1.NonLeveragedBuyCFDOverNightFee
          NonLeveragedBuyEndOfWeekFee = V1.NonLeveragedBuyCFDOverNightFee * 3
    |
    Step 3: Preserve FeeCalculationTypeID from existing InstrumentToFeeConfigV2 rows
      UPDATE @FeeValuesTblV2.FeeCalculationTypeID = InstrumentToFeeConfigV2.FeeCalculationTypeID
    |
    Step 4: EXEC UpdateInstrumentToFeeConfigTableV2 (@FeeValuesTblV2)
```

### 2.2 CFD Fee Override Logic

**What**: For CFD instruments (SettlementTypeID = 0) of eligible instrument types, the NonLeveragedBuy fees are overridden with CFD-specific values.

**Columns/Parameters Involved**: `NonLeveragedBuyOverNightFee`, `NonLeveragedBuyEndOfWeekFee`, `NonLeveragedBuyCFDOverNightFee`

**Rules**:
- Only applies to instruments whose InstrumentTypeID is in Trade.GetInstrumentTypeIDsForCFDFee() AND SettlementTypeID = 0
- NonLeveragedBuyOverNightFee is overridden with V1.NonLeveragedBuyCFDOverNightFee
- NonLeveragedBuyEndOfWeekFee is overridden with NonLeveragedBuyCFDOverNightFee * 3 (3x the nightly rate = weekly rate)
- This CFD-specific field (NonLeveragedBuyCFDOverNightFee) only exists in the V1 TVP; V2 handles CFDs differently via SettlementTypeID

### 2.3 FeeCalculationTypeID Preservation

**What**: The FeeCalculationTypeID is not passed by V1 callers, so it must be preserved from the current database state to avoid resetting it to 0.

**Columns/Parameters Involved**: `FeeCalculationTypeID`, `Trade.InstrumentToFeeConfigV2`

**Rules**:
- Default from conversion is FeeCalculationTypeID = 0
- If a row already exists in InstrumentToFeeConfigV2 for the same InstrumentID + SettlementTypeID, its FeeCalculationTypeID is preserved
- This prevents V1 callers from accidentally resetting a fee calculation type that was set via the V2 interface

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FeeValuesTbl | Trade.InstrumentToFeeConfigType (TVP, READONLY) | NO | - | CODE-BACKED | Legacy V1 fee configuration TVP. Contains InstrumentID (key) and 9 fee rate fields: NonLeveragedSellEndOfWeekFee, NonLeveragedBuyEndOfWeekFee, NonLeveragedBuyOverNightFee, NonLeveragedSellOverNightFee, LeveragedSellEndOfWeekFee, LeveragedBuyEndOfWeekFee, LeveragedBuyOverNightFee, LeveragedSellOverNightFee, and NonLeveragedBuyCFDOverNightFee (V1-only CFD override field). Lacks SettlementTypeID and FeeCalculationTypeID which are derived by this procedure before calling V2. |
| 2 | @UpdatedByUser | varchar(50) | YES | NULL | CODE-BACKED | Username of the person or service making the update. Passed through to Trade.UpdateInstrumentToFeeConfigTableV2 for audit trail purposes. |
| 3 | @IsAlertTriggered | bit (OUTPUT) | NO | 0 | CODE-BACKED | Output parameter indicating whether a fee change alert was triggered by the underlying V2 procedure (Trade.RolloverFeesAlertIfNeeded). Returns 1 if an alert was sent; 0 otherwise. Passed through from UpdateInstrumentToFeeConfigTableV2. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FeeValuesTbl.InstrumentID | Trade.InstrumentGroups | Lookup JOIN | Reads GroupID = 25 membership to derive SettlementTypeID for V2 conversion |
| @FeeValuesTbl.InstrumentID | Trade.InstrumentMetaData | Lookup JOIN | Reads InstrumentTypeID to identify CFD-eligible instruments for fee override |
| Instrument InstrumentTypeID | Trade.GetInstrumentTypeIDsForCFDFee | Function call | Returns the set of instrument type IDs eligible for CFD overnight fee calculation |
| InstrumentID + SettlementTypeID | Trade.InstrumentToFeeConfigV2 | Lookup JOIN | Reads existing FeeCalculationTypeID to preserve it during V1->V2 conversion |
| @FeeValuesTblV2 | Trade.UpdateInstrumentToFeeConfigTableV2 | EXEC delegate | The actual upsert logic; this procedure delegates to it after V1->V2 conversion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External legacy application | Application call | Caller | No internal SP callers; called from legacy fee management systems not yet migrated to V2 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentToFeeConfigTable (procedure) [OBSOLETE]
├── Trade.GetInstrumentTypeIDsForCFDFee (function) [reads CFD-eligible instrument types]
├── Trade.InstrumentGroups (table) [read - GroupID=25 lookup for SettlementTypeID]
├── Trade.InstrumentMetaData (table) [read - InstrumentTypeID for CFD check]
├── Trade.InstrumentToFeeConfigV2 (table) [read - FeeCalculationTypeID preservation]
└── Trade.UpdateInstrumentToFeeConfigTableV2 (procedure) [EXEC delegate - actual upsert]
      └── [see Trade.UpdateInstrumentToFeeConfigTableV2.md for full chain]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentTypeIDsForCFDFee | Function | Called to identify which instrument types receive the CFD overnight fee override |
| Trade.InstrumentGroups | Table | READ: GroupID=25 lookup to derive SettlementTypeID = 4 for qualifying instruments |
| Trade.InstrumentMetaData | Table | READ: InstrumentTypeID used to filter CFD-eligible instruments |
| Trade.InstrumentToFeeConfigV2 | Table | READ: FeeCalculationTypeID preserved from existing rows during V1->V2 conversion |
| Trade.UpdateInstrumentToFeeConfigTableV2 | Procedure | EXECuted with converted V2 TVP; performs the actual upsert into InstrumentToFeeConfigV2 |
| Trade.InstrumentToFeeConfigType | User Defined Type | V1 TVP type for @FeeValuesTbl |
| Trade.InstrumentToFeeConfigTypeV2 | User Defined Type | V2 TVP type for internal @FeeValuesTblV2 variable |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Legacy external application | Application | Calls this deprecated procedure; should migrate to Trade.UpdateInstrumentToFeeConfigTableV2 |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Obsolete status | Comment | "This stored procedure is obsolete and created for backward compatibility. Will be removed in the future. Use Trade.UpdateInstrumentToFeeConfigTableV2 instead." |
| CFD fee formula | Logic | NonLeveragedBuyEndOfWeekFee = NonLeveragedBuyCFDOverNightFee * 3 (3x overnight = weekly rate) |
| SettlementTypeID derivation | Logic | 4 if InstrumentGroups.GroupID = 25, else 0 - derived from group membership, not passed by caller |

---

## 8. Sample Queries

### 8.1 Call via legacy V1 interface (for backward compatibility only)

```sql
DECLARE @Fees [Trade].[InstrumentToFeeConfigType]
INSERT INTO @Fees (InstrumentID, NonLeveragedBuyOverNightFee, NonLeveragedSellOverNightFee,
                   NonLeveragedBuyEndOfWeekFee, NonLeveragedSellEndOfWeekFee,
                   LeveragedBuyOverNightFee, LeveragedSellOverNightFee,
                   LeveragedBuyEndOfWeekFee, LeveragedSellEndOfWeekFee,
                   NonLeveragedBuyCFDOverNightFee)
VALUES (1234, 0.0025, 0.0025, 0.0075, 0.0075, 0.0035, 0.0035, 0.0105, 0.0105, 0.0020)

DECLARE @IsAlert bit = 0
EXEC Trade.UpdateInstrumentToFeeConfigTable
    @FeeValuesTbl = @Fees,
    @UpdatedByUser = 'admin',
    @IsAlertTriggered = @IsAlert OUTPUT

SELECT @IsAlert AS AlertTriggered
```

### 8.2 Preferred: Use the V2 procedure directly

```sql
-- New callers should use UpdateInstrumentToFeeConfigTableV2 directly
-- See Trade.UpdateInstrumentToFeeConfigTableV2 documentation
DECLARE @FeesV2 [Trade].[InstrumentToFeeConfigTypeV2]
-- (construct V2 TVP with SettlementTypeID and FeeCalculationTypeID)
EXEC Trade.UpdateInstrumentToFeeConfigTableV2 @FeesV2, 'admin', @IsAlert OUTPUT
```

### 8.3 Check current fee configuration for an instrument

```sql
SELECT
    fc.InstrumentID,
    fc.SettlementTypeID,
    fc.FeeCalculationTypeID,
    fc.NonLeveragedBuyOverNightFee,
    fc.NonLeveragedSellOverNightFee,
    fc.LeveragedBuyOverNightFee,
    fc.LeveragedSellOverNightFee
FROM Trade.InstrumentToFeeConfigV2 fc WITH (NOLOCK)
WHERE fc.InstrumentID = 1234
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentToFeeConfigTable | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentToFeeConfigTable.sql*
