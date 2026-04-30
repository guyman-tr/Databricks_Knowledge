# Trade.ClosePositionsByInstrumentID

> Closes all open positions for a given instrument at the current market rate, used for contract expiration rolling and end-of-week closeouts. Validates the instrument has ContractHasExpiration=1, prevents weekend-mode execution, then iterates via cursor calling Trade.ManualPositionClose for each qualifying position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID (instrument whose positions are closed) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ClosePositionsByInstrumentID is an operational procedure that closes all open positions on a specific instrument. This is primarily used for two scenarios:

1. **Contract expiration/rolling** (ActionType=7): When a futures contract expires, all positions on that instrument must be closed before the new contract period begins (e.g., OIL, Copper, NATGAS, China50).
2. **End-of-week closeout** (ActionType=2): Positions flagged with CloseOnEndOfWeek=1 are closed at market close on Friday.

The procedure validates that the instrument is eligible by checking Trade.GetInstrumentMetaData.ContractHasExpiration=1 — instruments without contract expiration cannot be batch-closed this way. It also blocks execution during weekend mode (Maintenance.Feature FeatureID=1) when ActionType=7 to prevent erroneous closes.

Each position is closed at the current market closing rate calculated by Trade.FnGetCurrentClosingRate, using bid/ask spreads from Trade.CurrencyPrice.

---

## 2. Business Logic

### 2.1 Instrument Eligibility

**What**: Only instruments with contract expiration can be batch-closed.

**Rules**:
- Trade.GetInstrumentMetaData.ContractHasExpiration must be 1
- Originally designed for: OIL(20), Copper(21), NATGAS(22), China50(26)
- Other instruments with ContractHasExpiration=1 are also eligible

### 2.2 Weekend Mode Block

**What**: Prevents contract rolling during weekend mode.

**Rules**:
- Maintenance.Feature FeatureID=1 value=1 → weekend mode active
- Weekend mode + ActionType=7 → RAISERROR 60000 and return
- CloseOnEndOfWeek closes (ActionType=2) are not blocked by weekend mode

### 2.3 Position Selection

**What**: Determines which positions to close based on ActionType.

**Rules**:
- ActionType=7 (contract rolling): closes ALL positions regardless of CloseOnEndOfWeek
- ActionType=2 (end-of-week): only closes positions where CloseOnEndOfWeek=1
- @CloseAll=1 includes hedged positions (HedgeID IS NOT NULL); @CloseAll=0 excludes them
- EndForexRate is calculated per position by Trade.FnGetCurrentClosingRate (accounts for IsBuy, IsSettled, markup)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INTEGER | NO | - | VERIFIED | Instrument whose positions should be batch-closed. Must have ContractHasExpiration=1. |
| 2 | @ActionType | INTEGER | YES | 2 | CODE-BACKED | Close action type: 2=End-of-week close (default), 7=Contract rolling close. Determines which positions qualify. |
| 3 | @CloseAll | BIT | YES | 1 | CODE-BACKED | When 1, includes hedged positions. When 0, only non-hedged positions are closed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Position | SELECT | Reads open positions for the instrument |
| JOIN | Trade.CurrencyPrice | SELECT | Gets spreads and PriceRateID |
| APPLY | Trade.FnGetCurrentClosingRate | FUNCTION | Calculates per-position closing rate |
| FROM | Trade.GetInstrumentMetaData | SELECT | Validates instrument has ContractHasExpiration |
| FROM | Maintenance.Feature | SELECT | Checks weekend mode (FeatureID=1) |
| EXEC | Trade.ManualPositionClose | EXEC | Closes each individual position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found in SSDT) | - | - | Called by scheduled jobs for contract rolling and end-of-week close |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ClosePositionsByInstrumentID (procedure)
+-- Trade.Position (view)
+-- Trade.CurrencyPrice (table)
+-- Trade.FnGetCurrentClosingRate (function)
+-- Trade.GetInstrumentMetaData (view/TVF)
+-- Maintenance.Feature (table)
+-- Trade.ManualPositionClose (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT - open positions |
| Trade.CurrencyPrice | Table | SELECT - spreads and price rate |
| Trade.FnGetCurrentClosingRate | Function | CROSS APPLY - closing rate calculation |
| Trade.GetInstrumentMetaData | View/TVF | SELECT - eligibility check |
| Maintenance.Feature | Table | SELECT - weekend mode |
| Trade.ManualPositionClose | Procedure | EXEC - closes each position |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT) | - | Called by jobs |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ContractHasExpiration | Validation | Must be 1 for the instrument |
| Weekend mode block | Safety | Weekend mode + ActionType=7 → blocked |

---

## 8. Sample Queries

### 8.1 Check eligible instruments for batch close

```sql
SELECT  InstrumentID, ContractHasExpiration
FROM    Trade.GetInstrumentMetaData
WHERE   ContractHasExpiration = 1;
```

### 8.2 Execute contract rolling close

```sql
EXEC Trade.ClosePositionsByInstrumentID @InstrumentID = 20, @ActionType = 7, @CloseAll = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ClosePositionsByInstrumentID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ClosePositionsByInstrumentID.sql*
