# Trade.LiquidityProviderInstuments

> Mapping table that associates liquidity provider instances with the instruments they support, with validity periods (FromDate-ToDate). Note: table name contains intentional typo "Instuments" (not "Instruments").

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | LiquidityInstrumentID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

Trade.LiquidityProviderInstuments maps liquidity provider instances to the instruments they can offer. Each row represents "provider X supports instrument Y from date A to date B." This enables the system to know which external liquidity providers (e.g., FXCM Real, FD Production) can hedge or provide prices for which instruments. The table supports time-bound mappings via FromDate and ToDate - an instrument may be added to or removed from a provider's offering over time.

This table exists to support instrument validation and routing. Trade.CheckValidInstruments validates that instruments are configured with valid liquidity providers. Without this table, the system could not enforce that an instrument is only assigned to providers that actually support it. The LiquidityInstrumentID is allocated by Internal.GetLiquidityProviderInstrumentsID, which inserts into Internal.GenLiquidityProviderInstrumentsID to obtain the next ID.

Data flow: Rows are inserted when instruments are configured with liquidity providers (e.g., during instrument setup or via admin tools). The table is read by CheckValidInstruments and referenced by Trade.LiquidityProviderContracts for contract-to-instrument mappings. As of the analysis date, the table has zero rows - the structure exists for future or legacy use; Trade.LiquidityProviderContracts may have superseded this for primary mapping.

---

## 2. Business Logic

### 2.1 Provider-Instrument Validity Window

**What**: Each mapping has a validity period during which the provider supports the instrument.

**Columns/Parameters Involved**: `FromDate`, `ToDate`, `LiguidityProviderID`, `InstrumentID`

**Rules**:
- FromDate and ToDate define the inclusive date range when the provider offers this instrument
- A row with ToDate in the past indicates the mapping is no longer active
- Multiple rows per (Provider, Instrument) can exist for non-overlapping periods (e.g., provider paused and resumed)

**Diagram**:
```
Provider 2 (FXCM Real) | Instrument 1 (EUR/USD) | 2020-01-01 to 9999-12-31
Provider 3 (FXCM Demo) | Instrument 1 (EUR/USD) | 2020-01-01 to 2024-06-01
```

### 2.2 Abbreviation for Display

**What**: Optional short name for the instrument in the provider context.

**Columns/Parameters Involved**: `Abbreviation`

**Rules**:
- Nullable; used when the provider uses a different ticker/symbol than eToro
- Helps display and reconciliation across systems

---

## 3. Data Overview

The table is currently empty (0 rows). The structure supports mappings such as:

| LiquidityInstrumentID | LiguidityProviderID | InstrumentID | FromDate | ToDate | Abbreviation | Meaning |
|-----------------------|--------------------|--------------|----------|--------|--------------|---------|
| (no rows) | - | - | - | - | - | Table structure ready for provider-instrument mappings. Trade.LiquidityProviderContracts may handle primary mappings; this table serves as alternate or legacy configuration. |

**Selection criteria**: With zero rows, no sample data available. Structure indicates intent: map (LiquidityProviderID, InstrumentID) with validity window and optional abbreviation.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityInstrumentID | int | NO | - | CODE-BACKED | Surrogate primary key. Allocated by Internal.GetLiquidityProviderInstrumentsID (inserts into Internal.GenLiquidityProviderInstrumentsID). Unique per provider-instrument-period row. |
| 2 | LiguidityProviderID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityProviders(LiquidityProviderID). Note: column name has typo "Liguidity" (missing 'd'). The liquidity provider instance (e.g., FXCM Real, FD Production) that supports this instrument. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument(InstrumentID). The tradeable instrument this provider supports. |
| 4 | FromDate | datetime | NO | - | NAME-INFERRED | Start of validity period. From this date (inclusive), the provider offers this instrument. |
| 5 | ToDate | datetime | NO | - | NAME-INFERRED | End of validity period. Through this date (inclusive), the provider offers this instrument. Use 9999-12-31 for "no end date." |
| 6 | Abbreviation | nvarchar(50) | YES | - | NAME-INFERRED | Optional provider-specific symbol/ticker for the instrument. Used when provider uses different naming than eToro. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiguidityProviderID | Trade.LiquidityProviders | FK | Each row links to a provider instance (e.g., FXCM Real, FD Production). |
| InstrumentID | Trade.Instrument | FK | Each row links to a tradeable instrument. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CheckValidInstruments | - | Implicit | Procedure validates instrument configuration; LiquidityProviderInstuments referenced in schema for provider-instrument checks. |
| Trade.LiquidityProviderContracts | - | Related | Trade.LiquidityProviderContracts links provider contracts to instruments; may overlap or supersede this table. |
| Internal.GetLiquidityProviderInstrumentsID | GenLiquidityProviderInstrumentsID | ID allocation | Allocates LiquidityInstrumentID for new rows. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.LiquidityProviderInstuments (table)
```

Tables have no code-level dependencies. This table is a leaf.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target for InstrumentID |
| Trade.LiquidityProviders | Table | FK target for LiguidityProviderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetLiquidityProviderInstrumentsID | Procedure | Allocates LiquidityInstrumentID via Internal.GenLiquidityProviderInstrumentsID |
| Trade.CheckValidInstruments | Procedure | Validates instrument-provider configuration (schema-level reference) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Trade_LiquidityProviderInstuments | CLUSTERED | LiquidityInstrumentID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Trade_LiquidityProviderInstuments | PRIMARY KEY | Enforces unique LiquidityInstrumentID |
| FK_LiquidityProviderInstruments__Instrument | FOREIGN KEY | InstrumentID must exist in Trade.Instrument |
| FK_LiquidityProviderInstruments__LiquidityProviders | FOREIGN KEY | LiguidityProviderID must exist in Trade.LiquidityProviders |

---

## 8. Sample Queries

### 8.1 All active provider-instrument mappings (if populated)
```sql
SELECT   lpi.LiquidityInstrumentID,
         lpi.LiguidityProviderID,
         lp.LiquidityProviderName,
         lpi.InstrumentID,
         lpi.FromDate,
         lpi.ToDate,
         lpi.Abbreviation
FROM     Trade.LiquidityProviderInstuments lpi WITH (NOLOCK)
         INNER JOIN Trade.LiquidityProviders lp WITH (NOLOCK)
           ON lp.LiquidityProviderID = lpi.LiguidityProviderID
WHERE    lpi.ToDate >= CAST(GETUTCDATE() AS DATE)
ORDER BY lpi.LiguidityProviderID,
         lpi.InstrumentID;
```

### 8.2 Instruments supported by a specific provider
```sql
SELECT   lpi.InstrumentID,
         i.BuyCurrencyID,
         i.SellCurrencyID,
         lpi.FromDate,
         lpi.ToDate
FROM     Trade.LiquidityProviderInstuments lpi WITH (NOLOCK)
         INNER JOIN Trade.Instrument i WITH (NOLOCK)
           ON i.InstrumentID = lpi.InstrumentID
WHERE    lpi.LiguidityProviderID = 2
         AND lpi.ToDate >= GETUTCDATE();
```

### 8.3 Row count (table status)
```sql
SELECT   COUNT(*) AS cnt
FROM     Trade.LiquidityProviderInstuments WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 6.8/10 (Elements: 6.7/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 5/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.LiquidityProviderInstuments | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.LiquidityProviderInstuments.sql*
