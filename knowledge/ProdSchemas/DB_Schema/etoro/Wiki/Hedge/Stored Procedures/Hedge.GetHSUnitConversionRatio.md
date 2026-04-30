# Hedge.GetHSUnitConversionRatio

> Returns the unit conversion ratios for all instruments supported by a specific hedge server's liquidity provider. Navigates the chain: hedge server -> liquidity account -> provider type -> ProviderUnitConversionRatio. Used by the hedge engine to translate eToro internal units to provider-native order quantities.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @HedgeServerID int - required; identifies the hedge server |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHSUnitConversionRatio is the server-specific loader for the unit conversion table. When the hedge engine starts or reconfigures for a given hedge server, it calls this procedure to load the mapping: "for each instrument, how many provider-native units correspond to one eToro unit?"

This conversion is essential because eToro measures positions internally in "eToro units" while external liquidity providers use their own quantity systems (lots for Forex, shares for equities, etc.). Without the conversion ratio, the hedge engine cannot compute the correct order quantity to send to the provider.

The navigation chain resolves this: given a HedgeServerID, find its LiquidityAccountID (via HedgeServerToLiquidityAccount), then the LiquidityProviderTypeID (via Accounts), then look up the conversion ratios in ProviderUnitConversionRatio where LiquidityProviderID = LiquidityProviderTypeID.

**Key naming note**: ProviderUnitConversionRatio.LiquidityProviderID is actually a provider TYPE ID (FK to Trade.LiquidityProviderType.LiquidityProviderTypeID) - the join `HPUCR.LiquidityProviderID = TLPT.LiquidityProviderTypeID` confirms this.

The procedure returns only (InstrumentID, UnitConversionRatio) - the LotSize from ProviderUnitConversionRatio is NOT returned here (use Hedge.GetProviderUnitConversion for that broader read).

---

## 2. Business Logic

### 2.1 Four-Table Navigation Chain

**What**: Resolves @HedgeServerID through three join hops to reach the conversion ratios.

**Columns/Parameters Involved**: @HedgeServerID, HHSLA.HedgeServerID, HHSLA.LiquidityAccountID, HA.ID, HA.LiquidityProviderTypeID, TLPT.LiquidityProviderTypeID, HPUCR.LiquidityProviderID

**Rules**:
- Step 1: `Hedge.Accounts HA INNER JOIN Trade.LiquidityProviderType TLPT ON HA.LiquidityProviderTypeID = TLPT.LiquidityProviderTypeID` - resolves provider type for the account.
- Step 2: `INNER JOIN Hedge.HedgeServerToLiquidityAccount HHSLA ON HHSLA.LiquidityAccountID = HA.ID` - filters to accounts belonging to the hedge server.
- Step 3: `INNER JOIN Hedge.ProviderUnitConversionRatio HPUCR ON HPUCR.LiquidityProviderID = TLPT.LiquidityProviderTypeID` - gets conversion ratios for the provider type.
- WHERE `HHSLA.HedgeServerID = @HedgeServerID` - filter to the specific server.
- All joins are INNER - if any link in the chain is missing (no account mapping, no provider type, no ratio), the instrument is excluded.
- NOLOCK on all tables via inline hint `(nolock)`.

### 2.2 UnitConversionRatio Semantics

**What**: The ratio translates eToro units to provider-native quantity.

**Rules**:
- Formula: `providerQuantity = eToroUnits * UnitConversionRatio`
- Range: 0.001 to 10,000 across all providers and instruments (per ProviderUnitConversionRatio doc).
- ZBFX is the dominant provider with ratios for 5,213 instruments.
- LotSize (also in ProviderUnitConversionRatio) is NOT returned by this procedure - for lot-based rounding use Hedge.GetProviderUnitConversion.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | int | NO | - | CODE-BACKED | Required. The hedge server for which to load unit conversion ratios. Matched against HedgeServerToLiquidityAccount.HedgeServerID. |

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. PK component of ProviderUnitConversionRatio. One row per instrument supported by the server's provider. |
| 3 | UnitConversionRatio | decimal | NO | - | CODE-BACKED | Multiplier to convert eToro internal units to provider-native order quantity. Formula: providerQty = eToroUnits * UnitConversionRatio. Range: 0.001 to 10,000 across all providers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HA source + account filter | Hedge.Accounts | Lookup / Read | LiquidityProviderTypeID for the server's account. |
| TLPT join | Trade.LiquidityProviderType | Cross-schema Lookup | Resolves LiquidityProviderTypeID (bridge to ProviderUnitConversionRatio). |
| HHSLA join | Hedge.HedgeServerToLiquidityAccount | Lookup / Read | Filters to accounts belonging to @HedgeServerID. |
| HPUCR join | Hedge.ProviderUnitConversionRatio | Lookup / Read | InstrumentID, UnitConversionRatio for the provider type. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge engine (external) | @HedgeServerID | Caller | Loads unit conversion ratios at startup for order quantity translation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHSUnitConversionRatio (procedure)
├── Hedge.Accounts (table)
├── Trade.LiquidityProviderType (table) [cross-schema]
├── Hedge.HedgeServerToLiquidityAccount (table)
└── Hedge.ProviderUnitConversionRatio (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Accounts | Table | Starting table. LiquidityProviderTypeID for account. |
| Trade.LiquidityProviderType | Table | Cross-schema: bridge join (LiquidityProviderTypeID connects Accounts to ProviderUnitConversionRatio). |
| Hedge.HedgeServerToLiquidityAccount | Table | Filters to accounts for @HedgeServerID. |
| Hedge.ProviderUnitConversionRatio | Table | Data source: InstrumentID, UnitConversionRatio. Joined ON LiquidityProviderID = LiquidityProviderTypeID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge engine (external) | Application | Startup config load: unit conversion ratios for order size translation. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

No temp tables. Four INNER JOINs with NOLOCK hints. No SET TRAN ISOLATION LEVEL directive (unlike GetHedgeSupportedInstruments). Returns only 2 columns: InstrumentID and UnitConversionRatio - not LotSize. For LotSize, use Hedge.GetProviderUnitConversion.

---

## 8. Sample Queries

### 8.1 Get unit conversion ratios for a hedge server

```sql
EXEC Hedge.GetHSUnitConversionRatio @HedgeServerID = 1;
```

### 8.2 Manually compute provider order quantity

```sql
-- Example: how many provider units for 1000 eToro units of instrument 9920?
DECLARE @eToroUnits DECIMAL(18,8) = 1000;
SELECT InstrumentID,
       UnitConversionRatio,
       @eToroUnits * UnitConversionRatio AS ProviderOrderQuantity
FROM   Hedge.ProviderUnitConversionRatio HPUCR
JOIN   Hedge.Accounts HA ON HA.LiquidityProviderTypeID = HPUCR.LiquidityProviderID
JOIN   Hedge.HedgeServerToLiquidityAccount HHSLA ON HHSLA.LiquidityAccountID = HA.ID
WHERE  HHSLA.HedgeServerID = 1
AND    HPUCR.InstrumentID = 9920;
```

### 8.3 Identify instruments missing conversion ratios for a server

```sql
-- Instruments supported by provider contracts but missing unit conversion
SELECT DISTINCT LPC.InstrumentID
FROM   Hedge.HedgeServerToLiquidityAccount HSTLA
JOIN   Hedge.Accounts HA ON HSTLA.LiquidityAccountID = HA.ID
JOIN   Trade.LiquidityProviderContracts LPC ON HA.LiquidityProviderTypeID = LPC.LiquidityProviderID
WHERE  HSTLA.HedgeServerID = 1
AND    HA.AccountTypeID != 4
EXCEPT
SELECT InstrumentID FROM Hedge.ProviderUnitConversionRatio HPUCR
JOIN Trade.LiquidityProviderType TLPT ON HPUCR.LiquidityProviderID = TLPT.LiquidityProviderTypeID
JOIN Hedge.Accounts HA2 ON HA2.LiquidityProviderTypeID = TLPT.LiquidityProviderTypeID
JOIN Hedge.HedgeServerToLiquidityAccount HHSLA ON HHSLA.LiquidityAccountID = HA2.ID
WHERE HHSLA.HedgeServerID = 1;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Unit conversion for order quantity translation; provider-specific lot/unit systems. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHSUnitConversionRatio | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHSUnitConversionRatio.sql*
