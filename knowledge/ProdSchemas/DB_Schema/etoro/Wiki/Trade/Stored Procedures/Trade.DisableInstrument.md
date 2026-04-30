# Trade.DisableInstrument

> Fully disables a financial instrument by marking it non-tradable, invisible, and disabled across all providers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a **quick instrument kill-switch** used by operations teams to completely remove a financial instrument from trading availability. Unlike `Trade.DelistStock` (which also closes open positions and cancels orders), this procedure only updates metadata — it does **not** handle existing open positions or pending orders. It performs three operations:

1. Sets Tradable=0 and InstrumentVisible=0 on Trade.InstrumentMetaData (hides from all trading)
2. Sets DisplayOrder=-1 on Trade.ProviderToInstrument for legacy instruments (InstrumentID < 1000)
3. Sets Enabled=0 on Trade.ProviderToInstrument for all providers

This is typically used for temporary suspensions or pre-delist preparation where positions are handled separately.

---

## 2. Business Logic

### 2.1 Disable Instrument Metadata

**What**: Marks the instrument as non-tradable and invisible.

**Columns/Parameters Involved**: `Trade.InstrumentMetaData.Tradable`, `Trade.InstrumentMetaData.InstrumentVisible`

**Rules**:
- UPDATE Trade.InstrumentMetaData SET Tradable=0, InstrumentVisible=0 WHERE InstrumentID=@InstrumentID
- Immediately prevents new position opens and hides instrument from discovery

### 2.2 Disable Provider Mappings

**What**: Disables the instrument on all liquidity providers.

**Columns/Parameters Involved**: `Trade.ProviderToInstrument.DisplayOrder`, `Trade.ProviderToInstrument.Enabled`

**Rules**:
- For legacy instruments (InstrumentID < 1000): SET DisplayOrder=-1 (removes from display ordering)
- For all instruments: SET Enabled=0 (disables on all providers)
- No transaction wrapping — three independent UPDATE statements

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument to disable. Applied to both InstrumentMetaData and ProviderToInstrument tables. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.InstrumentMetaData | Write | Sets Tradable=0, InstrumentVisible=0 |
| @InstrumentID | Trade.ProviderToInstrument | Write | Sets DisplayOrder=-1 (legacy), Enabled=0 (all) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Operations/Admin) | N/A | Direct caller | Manual instrument suspension |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DisableInstrument (procedure)
+-- Trade.InstrumentMetaData (table)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | Instrument trading/visibility flags |
| Trade.ProviderToInstrument | Table | Provider-level enablement and display order |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: No transaction wrapping — if one UPDATE fails, the others may have already committed. The DisplayOrder=-1 update only applies to InstrumentID < 1000 (legacy instruments, likely original ETF/stock IDs). No XACT_ABORT, no error handling.

---

## 8. Sample Queries

### 8.1 Check instrument current state

```sql
SELECT  InstrumentID, Tradable, InstrumentVisible
FROM    Trade.InstrumentMetaData WITH (NOLOCK)
WHERE   InstrumentID = @InstrumentID;
```

### 8.2 Check provider enablement

```sql
SELECT  InstrumentID, ProviderID, Enabled, DisplayOrder
FROM    Trade.ProviderToInstrument WITH (NOLOCK)
WHERE   InstrumentID = @InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DisableInstrument | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DisableInstrument.sql*
