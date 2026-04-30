# Trade.UpdateInstrumentsSymbolFull

> Synchronizes the full symbol name (SymbolFull) for a batch of instruments across all tables that store or display it - InstrumentMetaData, ProviderToInstrument, TradonomiContracts, and Dictionary.Currency (for currency instruments).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentMetaDataConfigTbl (TVP with InstrumentID + SymbolFull) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the single point of truth for propagating a symbol full name change across all downstream tables that reference or display it. When an instrument's full trading symbol is updated (e.g., "Apple Inc." becomes "Apple Inc. (AAPL)"), this procedure fans the change out to four different storage locations in a single atomic transaction.

The procedure exists because symbol metadata is denormalized across multiple tables for performance and integration reasons. Without a coordinated update, InstrumentMetaData, ProviderToInstrument (which drives presentation in trading UIs), and TradonomiContracts (LP routing descriptions) would become inconsistent. Inconsistency in displayed symbols leads to user confusion and potential operational errors.

This procedure is called by the metadata configuration orchestrator procedures (Trade.UpdateInstrumentsMetaDataConfigurations and Trade.UpdateInstrumentsMetaDataConfigurationsExtend) as part of a larger instrument configuration refresh flow. It can also be called independently with the @ShouldUpdateInstrumentMetaData flag controlling whether the canonical metadata store is updated (useful for partial refreshes that target only the presentation/integration layers).

---

## 2. Business Logic

### 2.1 Selective Symbol Update Guard

**What**: The procedure exits early if the input batch contains no non-null SymbolFull values, avoiding unnecessary transaction overhead.

**Columns/Parameters Involved**: `@InstrumentMetaDataConfigTbl.SymbolFull`

**Rules**:
- If ALL rows in the TVP have NULL SymbolFull, the procedure PRINTs 'No symbols to update' and returns immediately
- Only rows with a non-null SymbolFull are loaded into #NewSymbols and processed
- This means a caller can pass a mixed TVP (some rows with symbol changes, some without) and only the relevant instruments are affected

**Diagram**:
```
Input TVP
  |
  +-- Any rows where SymbolFull IS NOT NULL?
        |
       YES --> Load into #NewSymbols --> Run Updates --> COMMIT
        |
        NO  --> PRINT 'No symbols to update' --> RETURN (no transaction opened)
```

### 2.2 Conditional Metadata Store Update

**What**: Controls whether the canonical Trade.InstrumentMetaData store is updated alongside the presentation/integration tables.

**Columns/Parameters Involved**: `@ShouldUpdateInstrumentMetaData`

**Rules**:
- When @ShouldUpdateInstrumentMetaData = 1 (default): all four targets are updated
- When @ShouldUpdateInstrumentMetaData = 0: InstrumentMetaData is skipped; ProviderToInstrument, TradonomiContracts, and Dictionary.Currency are still updated
- This flag supports scenarios where metadata has already been synced via another path but the presentation layer still needs updating

**Diagram**:
```
@ShouldUpdateInstrumentMetaData
  |
  1 --> UPDATE InstrumentMetaData.SymbolFull
  |     UPDATE ProviderToInstrument.PresentationCode = SymbolFull + '='
  |     UPDATE TradonomiContracts.Description = SymbolFull
  |     UPDATE Dictionary.Currency.Abbreviation (currency instruments only)
  |
  0 --> SKIP InstrumentMetaData
        UPDATE ProviderToInstrument.PresentationCode = SymbolFull + '='
        UPDATE TradonomiContracts.Description = SymbolFull
        UPDATE Dictionary.Currency.Abbreviation (currency instruments only)
```

### 2.3 Currency Instrument Special Case

**What**: For instruments that represent a currency directly (where InstrumentID = BuyCurrencyID), the Dictionary.Currency abbreviation is also updated.

**Columns/Parameters Involved**: `Trade.Instrument.InstrumentID`, `Trade.Instrument.BuyCurrencyID`, `Dictionary.Currency.Abbreviation`

**Rules**:
- The condition `WHERE ti.InstrumentID = ti.BuyCurrencyID` identifies instruments that ARE currencies (e.g., a EUR/USD instrument where the instrument's "buy currency" is itself the instrument)
- For these instruments, the SymbolFull value propagates as the currency abbreviation in Dictionary.Currency
- This ensures currency abbreviations shown in multi-currency calculations remain consistent with the instrument symbol

**Diagram**:
```
For each instrument in #NewSymbols:
  JOIN Trade.Instrument ti ON InstrumentID
  JOIN Dictionary.Currency dc ON dc.CurrencyID = ti.BuyCurrencyID
  WHERE ti.InstrumentID = ti.BuyCurrencyID
    --> This instrument IS a currency
    --> UPDATE Dictionary.Currency.Abbreviation = SymbolFull
```

### 2.4 PresentationCode Formatting Convention

**What**: ProviderToInstrument.PresentationCode is set to SymbolFull + '=' (with a trailing equals sign).

**Columns/Parameters Involved**: `Trade.ProviderToInstrument.PresentationCode`

**Rules**:
- The trailing '=' is a formatting convention for liquidity provider presentation codes
- All instruments are updated to SymbolFull + '=' regardless of their current PresentationCode value
- This convention is specific to how LP routing systems identify instruments in their order flow

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentMetaDataConfigTbl | Trade.InstrumentsMetaDataConfigTbl (TVP, READONLY) | NO | - | CODE-BACKED | Input batch of instrument configuration records. Only rows where SymbolFull IS NOT NULL are processed. The TVP type contains InstrumentID (key), SymbolFull (the full display name to propagate), and other metadata fields not used by this procedure. |
| 2 | @ShouldUpdateInstrumentMetaData | bit | NO | 1 | CODE-BACKED | Controls whether Trade.InstrumentMetaData.SymbolFull is updated. 1 = update all four targets (default behavior); 0 = skip InstrumentMetaData, update only ProviderToInstrument, TradonomiContracts, and Dictionary.Currency. Used when the metadata store has already been refreshed via another path. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentMetaDataConfigTbl.InstrumentID | Trade.InstrumentMetaData | Implicit JOIN | Updates SymbolFull on matching InstrumentID when @ShouldUpdateInstrumentMetaData = 1 |
| @InstrumentMetaDataConfigTbl.InstrumentID | Trade.ProviderToInstrument | Implicit JOIN | Updates PresentationCode = SymbolFull + '=' for all LP-instrument mappings |
| @InstrumentMetaDataConfigTbl.InstrumentID | Trade.TradonomiContracts | Implicit JOIN | Updates Description = SymbolFull for Tradonomi LP routing contracts |
| @InstrumentMetaDataConfigTbl.InstrumentID | Trade.Instrument | Lookup JOIN | Read-only; used to find BuyCurrencyID for currency instrument detection |
| Trade.Instrument.BuyCurrencyID | Dictionary.Currency | Implicit FK | Updates Abbreviation for currency instruments where InstrumentID = BuyCurrencyID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsMetaDataConfigurations | EXEC call | Caller | Calls this procedure as part of the full instrument metadata configuration refresh |
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | EXEC call | Caller | Extended version of the configuration refresh that also calls this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsSymbolFull (procedure)
├── Trade.InstrumentMetaData (table) [conditional - @ShouldUpdateInstrumentMetaData=1]
├── Trade.ProviderToInstrument (table)
├── Trade.TradonomiContracts (table)
├── Trade.Instrument (table) [read - BuyCurrencyID lookup]
└── Dictionary.Currency (table) [currency instruments only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | UPDATEd: SymbolFull column updated for matching InstrumentIDs (conditional on flag) |
| Trade.ProviderToInstrument | Table | UPDATEd: PresentationCode set to SymbolFull + '=' for all LP-instrument records |
| Trade.TradonomiContracts | Table | UPDATEd: Description set to SymbolFull for Tradonomi LP contracts |
| Trade.Instrument | Table | READ: JOINed to get BuyCurrencyID for currency instrument detection |
| Dictionary.Currency | Table | UPDATEd: Abbreviation set to SymbolFull for instruments where InstrumentID = BuyCurrencyID |
| Trade.InstrumentsMetaDataConfigTbl | User Defined Type | TVP type for input parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsMetaDataConfigurations | Procedure | Calls this procedure to propagate symbol name changes as part of full metadata refresh |
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | Procedure | Calls this procedure in the extended configuration refresh flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Early exit guard | Logic | IF NOT EXISTS (SELECT * FROM TVP WHERE SymbolFull IS NOT NULL) -> RETURN. Prevents empty-batch transactions. |
| Atomic transaction | TRY/CATCH | All four UPDATE statements wrapped in BEGIN TRAN / COMMIT with ROLLBACK on error via THROW. |

---

## 8. Sample Queries

### 8.1 Update symbol full name for a specific instrument

```sql
-- Build a TVP and call the procedure to update SymbolFull for instrument 1234
DECLARE @Config [Trade].[InstrumentsMetaDataConfigTbl]
INSERT INTO @Config (InstrumentID, SymbolFull)
VALUES (1234, 'Apple Inc.')

EXEC Trade.UpdateInstrumentsSymbolFull
    @InstrumentMetaDataConfigTbl = @Config,
    @ShouldUpdateInstrumentMetaData = 1
```

### 8.2 Update presentation layer only (skip InstrumentMetaData)

```sql
-- Update ProviderToInstrument, TradonomiContracts, and Dictionary.Currency
-- without touching InstrumentMetaData (already updated via another path)
DECLARE @Config [Trade].[InstrumentsMetaDataConfigTbl]
INSERT INTO @Config (InstrumentID, SymbolFull)
VALUES (1234, 'Apple Inc.'), (5678, 'Tesla Inc.')

EXEC Trade.UpdateInstrumentsSymbolFull
    @InstrumentMetaDataConfigTbl = @Config,
    @ShouldUpdateInstrumentMetaData = 0
```

### 8.3 Verify symbol propagation after update

```sql
-- Check that SymbolFull was consistently propagated across all tables
SELECT
    ti.InstrumentID,
    timd.SymbolFull AS MetaDataSymbolFull,
    tpti.PresentationCode AS ProviderCode,
    ttc.Description AS TradonomiDescription,
    dc.Abbreviation AS CurrencyAbbrev
FROM Trade.Instrument ti WITH (NOLOCK)
LEFT JOIN Trade.InstrumentMetaData timd WITH (NOLOCK) ON timd.InstrumentID = ti.InstrumentID
LEFT JOIN Trade.ProviderToInstrument tpti WITH (NOLOCK) ON tpti.InstrumentID = ti.InstrumentID
LEFT JOIN Trade.TradonomiContracts ttc WITH (NOLOCK) ON ttc.InstrumentID = ti.InstrumentID
LEFT JOIN Dictionary.Currency dc WITH (NOLOCK) ON dc.CurrencyID = ti.BuyCurrencyID AND ti.InstrumentID = ti.BuyCurrencyID
WHERE ti.InstrumentID = 1234
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentsSymbolFull | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsSymbolFull.sql*
