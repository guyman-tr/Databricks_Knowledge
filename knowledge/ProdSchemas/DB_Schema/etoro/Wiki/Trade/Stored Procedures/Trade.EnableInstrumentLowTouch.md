# Trade.EnableInstrumentLowTouch

> Enables a financial instrument for trading by activating its provider mapping and making it visible and tradable in a single atomic transaction.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is part of the instrument lifecycle management system. It re-enables a previously disabled instrument for live trading by performing two coordinated updates: activating the provider-to-instrument mapping (so liquidity providers can quote prices) and marking the instrument as tradable and visible (so users can see and trade it on the platform).

The "LowTouch" naming suggests this is a simplified, operational procedure intended for quick instrument re-enablement without complex validation - likely used by operations teams or automated recovery processes when an instrument needs to be brought back online after a temporary suspension.

Both updates are wrapped in an explicit transaction with TRY/CATCH error handling. If either update fails, the entire operation rolls back, preventing a state where the provider is enabled but the instrument remains invisible to users (or vice versa).

---

## 2. Business Logic

### 2.1 Atomic Instrument Enablement

**What**: Two-step enablement that must succeed or fail together.

**Columns/Parameters Involved**: `@InstrumentID`, `Enabled`, `Tradable`, `InstrumentVisible`

**Rules**:
- Step 1: Sets `Trade.ProviderToInstrument.Enabled = 1` for all provider mappings of this instrument - this activates price feeds from liquidity providers
- Step 2: Sets `Trade.InstrumentMetaData.Tradable = 1` and `InstrumentMetaData.InstrumentVisible = 1` - this makes the instrument available for trading and visible in the UI
- Both updates filter by @InstrumentID only (no provider filtering), meaning ALL providers for this instrument are enabled
- Transaction ensures atomicity: if the metadata update fails, the provider activation is rolled back

**Diagram**:
```
@InstrumentID
  |
  +-> Trade.ProviderToInstrument: Enabled = 1  (activate all providers)
  |
  +-> Trade.InstrumentMetaData: Tradable = 1, InstrumentVisible = 1  (show to users)
  |
  All-or-nothing (BEGIN TRAN / COMMIT / ROLLBACK)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | The financial instrument to enable. Must exist in both Trade.ProviderToInstrument and Trade.InstrumentMetaData. Corresponds to the platform-wide instrument identifier used across all trading tables. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.ProviderToInstrument | MODIFIER | Enables all provider mappings for the instrument (sets Enabled=1) |
| @InstrumentID | Trade.InstrumentMetaData | MODIFIER | Makes instrument tradable and visible (sets Tradable=1, InstrumentVisible=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.EnableInstrumentLowTouch (procedure)
+-- Trade.ProviderToInstrument (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | UPDATE - enables provider mappings |
| Trade.InstrumentMetaData | Table | UPDATE - sets tradable and visible flags |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Error Handling**: Uses TRY/CATCH with explicit ROLLBACK and THROW to propagate errors to the caller while ensuring transactional consistency.

---

## 8. Sample Queries

### 8.1 Enable a Specific Instrument

```sql
EXEC Trade.EnableInstrumentLowTouch @InstrumentID = 1001
```

### 8.2 Check Current Instrument State Before Enabling

```sql
SELECT imd.InstrumentID,
       imd.Tradable,
       imd.InstrumentVisible,
       pti.ProviderID,
       pti.Enabled AS ProviderEnabled
  FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
  LEFT JOIN Trade.ProviderToInstrument pti WITH (NOLOCK)
    ON imd.InstrumentID = pti.InstrumentID
 WHERE imd.InstrumentID = 1001
```

### 8.3 Find All Disabled Instruments That Could Be Re-Enabled

```sql
SELECT imd.InstrumentID,
       imd.Tradable,
       imd.InstrumentVisible,
       COUNT(pti.ProviderID) AS ProviderCount,
       SUM(CAST(pti.Enabled AS INT)) AS EnabledProviders
  FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
  LEFT JOIN Trade.ProviderToInstrument pti WITH (NOLOCK)
    ON imd.InstrumentID = pti.InstrumentID
 WHERE imd.Tradable = 0 OR imd.InstrumentVisible = 0
 GROUP BY imd.InstrumentID, imd.Tradable, imd.InstrumentVisible
 ORDER BY imd.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.EnableInstrumentLowTouch | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.EnableInstrumentLowTouch.sql*
