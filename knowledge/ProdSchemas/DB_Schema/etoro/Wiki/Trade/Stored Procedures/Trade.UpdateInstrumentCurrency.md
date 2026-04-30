# Trade.UpdateInstrumentCurrency

> Updates BuyCurrencyID and SellCurrencyID for a single instrument in Trade.Instrument; sets the denomination currencies used for buy and sell order pricing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID - identifies the instrument to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateInstrumentCurrency sets the buy and sell denomination currencies for a single trading instrument in `Trade.Instrument`. BuyCurrencyID and SellCurrencyID determine the currency in which buy-side and sell-side orders for this instrument are priced and settled.

For most instruments, the buy and sell currencies are identical (e.g., both USD for US stocks). Some instruments, however, may have asymmetric currency configurations - particularly FX pairs, where the buy-side and sell-side pricing may reference different base or quote currencies. This procedure is the controlled update path for these currency assignments, typically called during instrument onboarding or when correcting currency configuration after a corporate restructuring or instrument reclassification.

No callers were found in the SSDT permissions files, suggesting this is invoked by internal tooling or direct admin access.

---

## 2. Business Logic

### 2.1 Currency Assignment Update

**What**: Updates both BuyCurrencyID and SellCurrencyID simultaneously for the target instrument.

**Columns/Parameters Involved**: `@InstrumentID`, `@BuyCurrencyID`, `@SellCurrencyID`, `Trade.Instrument.BuyCurrencyID`, `Trade.Instrument.SellCurrencyID`

**Rules**:
- `UPDATE Trade.Instrument SET BuyCurrencyID=@BuyCurrencyID, SellCurrencyID=@SellCurrencyID WHERE InstrumentID=@InstrumentID`
- Single-row UPDATE (InstrumentID is PK of Trade.Instrument)
- No existence check - silent no-op if InstrumentID not found (@@ROWCOUNT=0, no error)
- Both currencies are set in the same statement - no risk of partial update
- No validation of currency IDs against Dictionary.Currency (the procedure trusts the caller)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Primary key of the instrument to update. Targets Trade.Instrument.InstrumentID. |
| 2 | @BuyCurrencyID | INT | NO | - | CODE-BACKED | Currency ID for the buy-side denomination. FK to Dictionary.Currency. Sets Trade.Instrument.BuyCurrencyID. |
| 3 | @SellCurrencyID | INT | NO | - | CODE-BACKED | Currency ID for the sell-side denomination. FK to Dictionary.Currency. Sets Trade.Instrument.SellCurrencyID. For most instruments equals @BuyCurrencyID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Trade.Instrument | Modifier | Updates BuyCurrencyID and SellCurrencyID WHERE InstrumentID=@InstrumentID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no callers found in SSDT permissions files. Invoked by instrument configuration tooling or admin scripts.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentCurrency (procedure)
+-- Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | UPDATE target for BuyCurrencyID and SellCurrencyID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (instrument configuration tooling) | - | Called during onboarding or currency reassignment |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No SET NOCOUNT ON. No TRY/CATCH. No currency ID validation. Single-statement UPDATE in a BEGIN/END block.

---

## 8. Sample Queries

### 8.1 Update currencies for an instrument
```sql
EXEC Trade.UpdateInstrumentCurrency
    @InstrumentID  = 1001,
    @BuyCurrencyID = 4,    -- USD
    @SellCurrencyID = 4;   -- USD
```

### 8.2 Check current currency settings for an instrument
```sql
SELECT i.InstrumentID, i.BuyCurrencyID, i.SellCurrencyID,
       bc.CurrencyID AS BuyCurrency, sc.CurrencyID AS SellCurrency
FROM   Trade.Instrument i WITH (NOLOCK)
LEFT JOIN Dictionary.Currency bc WITH (NOLOCK) ON bc.CurrencyID = i.BuyCurrencyID
LEFT JOIN Dictionary.Currency sc WITH (NOLOCK) ON sc.CurrencyID = i.SellCurrencyID
WHERE  i.InstrumentID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentCurrency | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentCurrency.sql*
