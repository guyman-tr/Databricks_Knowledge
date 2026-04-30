# Trade.UpdateInstrumentsSymbolFullExtend

> Extended version of UpdateInstrumentsSymbolFull that additionally updates InstrumentMetaData.Symbol and propagates the symbol name to Price.DictionaryCurrency, covering both the Trade and Price databases in a single atomic transaction.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentMetaDataConfigTbl (TVP with InstrumentID + SymbolFull) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the "extended" variant of Trade.UpdateInstrumentsSymbolFull, created in January 2022 to merge two predecessor stored procedures and add cross-database synchronization to the Price schema. It propagates the full symbol name for a batch of instruments to five storage locations: InstrumentMetaData (both SymbolFull and Symbol columns), ProviderToInstrument, TradonomiContracts, Dictionary.Currency, and Price.DictionaryCurrency.

The key distinction from the base version is the additional update to Price.DictionaryCurrency.Abbreviation. The Price database maintains its own currency dictionary (separate from Dictionary.Currency) and must also reflect updated currency abbreviations for price feed calculations. Without this step, currency instruments updated via the base procedure would be inconsistent between the Trade and Price databases.

This procedure is the exclusive callee of Trade.UpdateInstrumentsMetaDataConfigurationsExtend, which orchestrates the full extended metadata configuration refresh. The Extend suffix across the procedure family (UpdateInstrumentsMetaDataConfigurationsExtend -> UpdateInstrumentsSymbolFullExtend) signals a consistent pattern where the extended version covers additional cross-schema targets.

---

## 2. Business Logic

### 2.1 Selective Symbol Update Guard

**What**: Exits early if no rows in the input TVP have a non-null SymbolFull, avoiding an empty transaction.

**Columns/Parameters Involved**: `@InstrumentMetaDataConfigTbl.SymbolFull`

**Rules**:
- IF NOT EXISTS check on the TVP before any transaction is opened
- Only rows where SymbolFull IS NOT NULL are loaded into #NewSymbols
- Caller can pass a mixed-purpose TVP; only symbol rows are processed

**Diagram**:
```
Input TVP
  |
  +-- Any rows where SymbolFull IS NOT NULL?
        |
       YES --> #NewSymbols --> 5 UPDATE statements --> COMMIT
        |
        NO  --> PRINT 'No symbols to update' --> RETURN
```

### 2.2 Dual Symbol Column Update (Extended Behavior)

**What**: When @ShouldUpdateInstrumentMetaData = 1, both InstrumentMetaData.SymbolFull AND InstrumentMetaData.Symbol are updated - unlike the base version which only updates SymbolFull.

**Columns/Parameters Involved**: `Trade.InstrumentMetaData.SymbolFull`, `Trade.InstrumentMetaData.Symbol`, `@ShouldUpdateInstrumentMetaData`

**Rules**:
- Symbol and SymbolFull are both set to the same value from the TVP's SymbolFull field
- The base version (UpdateInstrumentsSymbolFull) only updates SymbolFull; this extended version keeps Symbol in sync as well
- When @ShouldUpdateInstrumentMetaData = 0, both columns are skipped

**Diagram**:
```
@ShouldUpdateInstrumentMetaData = 1:
  UPDATE InstrumentMetaData SET SymbolFull = ns.SymbolFull, Symbol = ns.SymbolFull

@ShouldUpdateInstrumentMetaData = 0:
  SKIP InstrumentMetaData entirely
```

### 2.3 Cross-Database Currency Synchronization (Extended Behavior)

**What**: For currency instruments, synchronizes the abbreviation to both Dictionary.Currency (Trade DB) and Price.DictionaryCurrency (Price DB), ensuring both databases show consistent currency names.

**Columns/Parameters Involved**: `Dictionary.Currency.Abbreviation`, `Price.DictionaryCurrency.Abbreviation`, `Trade.Instrument.BuyCurrencyID`, `Trade.Instrument.InstrumentID`

**Rules**:
- Condition: `WHERE ti.InstrumentID = ti.BuyCurrencyID` identifies currency instruments (instruments that ARE currencies)
- Two separate UPDATEs: one for Dictionary.Currency, one for Price.DictionaryCurrency
- Both are within the same transaction, so either both update or neither does

**Diagram**:
```
For each instrument in #NewSymbols where InstrumentID = BuyCurrencyID:
  +-- UPDATE Dictionary.Currency.Abbreviation = SymbolFull
  +-- UPDATE Price.DictionaryCurrency.Abbreviation = SymbolFull
  Both in same transaction - atomic cross-schema update
```

### 2.4 PresentationCode Formatting Convention

**What**: ProviderToInstrument.PresentationCode is set to SymbolFull + '=' (trailing equals sign).

**Columns/Parameters Involved**: `Trade.ProviderToInstrument.PresentationCode`

**Rules**:
- Identical to the base version; the trailing '=' is a liquidity provider routing convention
- All instruments matching the TVP are updated unconditionally (no flag check)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentMetaDataConfigTbl | Trade.InstrumentsMetaDataConfigTblExtend (TVP, READONLY) | NO | - | CODE-BACKED | Input batch of instrument configuration records using the extended TVP type. Contains InstrumentID (key), SymbolFull (propagated to all targets), plus ExchangeID, UnderlyingExchangeID, PriceSourceID fields not used by this procedure. Only rows where SymbolFull IS NOT NULL are processed. Extended from the base InstrumentsMetaDataConfigTbl by adding exchange and price source fields. |
| 2 | @ShouldUpdateInstrumentMetaData | bit | NO | 1 | CODE-BACKED | Controls whether Trade.InstrumentMetaData is updated. 1 = update all five targets including InstrumentMetaData.SymbolFull and InstrumentMetaData.Symbol (default); 0 = skip InstrumentMetaData, update ProviderToInstrument, TradonomiContracts, Dictionary.Currency, and Price.DictionaryCurrency only. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentMetaDataConfigTbl.InstrumentID | Trade.InstrumentMetaData | Implicit JOIN | Updates SymbolFull and Symbol on matching InstrumentIDs (conditional on flag) |
| @InstrumentMetaDataConfigTbl.InstrumentID | Trade.ProviderToInstrument | Implicit JOIN | Updates PresentationCode = SymbolFull + '=' for all LP-instrument mappings |
| @InstrumentMetaDataConfigTbl.InstrumentID | Trade.TradonomiContracts | Implicit JOIN | Updates Description = SymbolFull for Tradonomi LP routing contracts |
| @InstrumentMetaDataConfigTbl.InstrumentID | Trade.Instrument | Lookup JOIN | Read-only; used to find BuyCurrencyID for currency instrument detection |
| Trade.Instrument.BuyCurrencyID | Dictionary.Currency | Implicit FK | Updates Abbreviation for currency instruments (Trade DB) |
| Trade.Instrument.BuyCurrencyID | Price.DictionaryCurrency | Cross-schema FK | Updates Abbreviation for currency instruments in the Price DB (extended behavior) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | EXEC call | Caller | Sole caller; calls this as part of the extended instrument metadata configuration refresh |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsSymbolFullExtend (procedure)
├── Trade.InstrumentMetaData (table) [conditional - @ShouldUpdateInstrumentMetaData=1; updates SymbolFull + Symbol]
├── Trade.ProviderToInstrument (table) [updates PresentationCode]
├── Trade.TradonomiContracts (table) [updates Description]
├── Trade.Instrument (table) [read - BuyCurrencyID lookup]
├── Dictionary.Currency (table) [currency instruments - updates Abbreviation]
└── Price.DictionaryCurrency (table) [cross-schema - currency instruments - updates Abbreviation]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | UPDATEd: SymbolFull and Symbol columns updated for matching InstrumentIDs (conditional) |
| Trade.ProviderToInstrument | Table | UPDATEd: PresentationCode set to SymbolFull + '=' |
| Trade.TradonomiContracts | Table | UPDATEd: Description set to SymbolFull |
| Trade.Instrument | Table | READ: JOINed to get BuyCurrencyID for currency instrument detection |
| Dictionary.Currency | Table | UPDATEd: Abbreviation set to SymbolFull for currency instruments (Trade DB) |
| Price.DictionaryCurrency | Table | UPDATEd: Abbreviation set to SymbolFull for currency instruments (Price DB cross-schema) |
| Trade.InstrumentsMetaDataConfigTblExtend | User Defined Type | TVP type for input parameter; extended version with ExchangeID/UnderlyingExchangeID/PriceSourceID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | Procedure | Calls this procedure in the extended metadata configuration refresh flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Early exit guard | Logic | IF NOT EXISTS (SELECT * FROM TVP WHERE SymbolFull IS NOT NULL) -> RETURN. Prevents empty-batch transactions. |
| Atomic cross-schema transaction | TRY/CATCH | All five UPDATE statements (including cross-schema Price.DictionaryCurrency) wrapped in BEGIN TRAN / COMMIT with ROLLBACK on error via THROW. |
| History note | Comment | Created 2022-01-17 by Shany: merged two predecessor SPs and added Price DB DictionaryCurrency table update. |

---

## 8. Sample Queries

### 8.1 Update symbol full name using extended TVP type

```sql
-- Use the extended TVP type which includes exchange and price source fields
DECLARE @Config [Trade].[InstrumentsMetaDataConfigTblExtend]
INSERT INTO @Config (InstrumentID, SymbolFull)
VALUES (1234, 'Apple Inc.')

EXEC Trade.UpdateInstrumentsSymbolFullExtend
    @InstrumentMetaDataConfigTbl = @Config,
    @ShouldUpdateInstrumentMetaData = 1
```

### 8.2 Update only the presentation and integration layers (skip metadata)

```sql
DECLARE @Config [Trade].[InstrumentsMetaDataConfigTblExtend]
INSERT INTO @Config (InstrumentID, SymbolFull)
VALUES (1234, 'Apple Inc.'), (5678, 'Tesla Inc.')

EXEC Trade.UpdateInstrumentsSymbolFullExtend
    @InstrumentMetaDataConfigTbl = @Config,
    @ShouldUpdateInstrumentMetaData = 0
```

### 8.3 Verify cross-database symbol consistency for currency instruments

```sql
-- Check that both Dictionary and Price databases have the same currency abbreviation
SELECT
    ti.InstrumentID,
    timd.SymbolFull,
    dc.Abbreviation AS DictionaryAbbrev,
    pdc.Abbreviation AS PriceAbbrev,
    CASE WHEN dc.Abbreviation = pdc.Abbreviation THEN 'IN SYNC' ELSE 'OUT OF SYNC' END AS SyncStatus
FROM Trade.Instrument ti WITH (NOLOCK)
JOIN Trade.InstrumentMetaData timd WITH (NOLOCK) ON timd.InstrumentID = ti.InstrumentID
JOIN Dictionary.Currency dc WITH (NOLOCK) ON dc.CurrencyID = ti.BuyCurrencyID
JOIN Price.DictionaryCurrency pdc WITH (NOLOCK) ON pdc.CurrencyID = ti.BuyCurrencyID
WHERE ti.InstrumentID = ti.BuyCurrencyID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentsSymbolFullExtend | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsSymbolFullExtend.sql*
