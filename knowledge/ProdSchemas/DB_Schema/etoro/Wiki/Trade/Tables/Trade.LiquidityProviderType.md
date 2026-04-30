# Trade.LiquidityProviderType

> Dictionary table that defines liquidity provider types (e.g., eToro internal, FXCM, BMFN, FD) with pluggable price and execution provider configurations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | LiquidityProviderTypeID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

Trade.LiquidityProviderType is the dictionary table that defines each **type** of liquidity provider in eToro's trading infrastructure. A liquidity provider type represents a category of price/execution source - such as "eToro" (internal), "FXCM", "BMFN", "FD" (First Derivatives), "XIGNITE", or "BitStamp" - each with its own assembly and class configuration for price feeds, hedging execution, and provider-specific settings.

This table exists because the hedge and price subsystems need to know which .NET assemblies and classes to load for each provider type. When a hedge account is configured (Hedge.Accounts.LiquidityProviderTypeID) or when a liquidity provider instance is created (Trade.LiquidityProviders.LiquidityProviderTypeID), the system joins to this table to read TypeSettingsXML and resolve the correct price provider, execution client, and PCS (Price Collection Service) implementations. Without it, the system cannot route hedging and pricing to external brokers or internal feeds.

Data flows as follows: rows are seeded by deployment or admin scripts when a new provider type is integrated. The table is read by Trade.GetLiquidityProviders, Trade.GetLiquidityAccountsDetails, Hedge procedures (GetHSUnitConversionRatio, GetAllLiquidityAccountsMetadata, GetHedgeServerMetaData), Internal.Newcurrency for unit conversion and contract setup, and OMS sync. System versioning records all changes to History.LiquidityProviderType.

---

## 2. Business Logic

### 2.1 Provider Type Configuration via TypeSettingsXML

**What**: Each liquidity provider type specifies pluggable components (price provider, execution client, hedging provider) via XML configuration.

**Columns/Parameters Involved**: `LiquidityProviderTypeID`, `Name`, `TypeSettingsXML`

**Rules**:
- TypeSettingsXML contains assembly and class references: priceClassInfo (PriceProviders.dll), PCSClassInfo (eToro.Trading.PCS.Provider.Price.dll), executionClassInfo (Hedge.exe), HedgingProviderClassInfo (Hedge.exe)
- eToro (ID=0) uses CustomInstrumentPriceProvider for internal/custom instruments
- External providers (BMFN, FXCM, FD, CNX, GFT) include ProviderExecutionSettings (e.g., default_lot_size) and OnixSEngineSettings (reconnect interval/attempts)
- Crypto providers (BitStamp, MT_GOX) typically have only PCSClassInfo for price feeds
- Hedge.AddAccountStatus branches on LiquidityProviderTypeID=3 (FD) and 11 (IB) for provider-specific logic

**Diagram**:
```
LiquidityProviderTypeID 0 (eToro)  -> CustomInstrumentPriceProvider (internal)
LiquidityProviderTypeID 1 (BMFN)  -> CbfxPriceProvider, HedgedCbfxFxClient
LiquidityProviderTypeID 2 (FXCM)  -> FxcmPriceProvider, FXCMHedgingProvider
LiquidityProviderTypeID 3 (FD)    -> FirstDerivativesPriceProvider, FDHedgingProvider
LiquidityProviderTypeID 5 (XIGNITE)-> XigniteRealQuotesPriceProvider (stocks)
LiquidityProviderTypeID 8 (BitStamp)-> BitStampPriceProvider (crypto)
```

### 2.2 System Versioning for Configuration History

**What**: All changes to provider type configuration are retained for auditing and rollback.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- PERIOD FOR SYSTEM_TIME stores valid-from and valid-to timestamps
- History.LiquidityProviderType holds superseded rows when Name or TypeSettingsXML is updated
- Enables point-in-time queries for "what was the FD configuration last month?"

---

## 3. Data Overview

| LiquidityProviderTypeID | Name | Meaning |
|-------------------------|------|---------|
| 0 | eToro | Internal platform. Uses CustomInstrumentPriceProvider for instruments priced by eToro. No external hedge execution. |
| 1 | BMFN | BMFN forex broker. CBFX price provider, HedgedCbfxFxClient for execution. default_lot_size=10000. |
| 2 | FXCM | FXCM forex broker. OnixS FxcmPriceProvider and FXCMHedgingProvider. Used for forex hedging. |
| 3 | FD | First Derivatives (DFLM). Used for specific hedge routing; Hedge.AddAccountStatus has FD-specific logic when LiquidityProviderTypeID=3. |
| 5 | XIGNITE | Xignite real quotes web service. Stock/crypto price feed; no hedge execution. |

**Selection criteria for the 5 rows:**
- eToro (0): internal baseline
- BMFN, FXCM, FD: external forex hedge providers with execution
- XIGNITE: representative of web-service price-only providers

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderTypeID | int | NO | - | CODE-BACKED | Primary key. Provider type identifier. Value map from live data: 0=eToro, 1=BMFN, 2=FXCM, 3=FD, 4=CNX, 5=XIGNITE, 6=MT_GOX, 7=GFT, 8=BitStamp, 11=IB. Hedge.AddAccountStatus branches on 3 and 11. (Source: Trade.LiquidityProviderType) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable provider type name (e.g., eToro, FXCM, BMFN). Used in views and reports. |
| 3 | TypeSettingsXML | xml | YES | - | CODE-BACKED | Pluggable configuration: assembly/class for priceClassInfo, PCSClassInfo, executionClassInfo, HedgingProviderClassInfo. Includes ProviderExecutionSettings (default_lot_size) and OnixsEngineSettings for external providers. |
| 4 | DbLoginName | varchar(128) | NO | computed | CODE-BACKED | Computed: suser_name(). SQL login that last modified the row. Audit context. |
| 5 | AppLoginName | varchar(500) | NO | computed | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context from context_info. Often NULL when not set by caller. |
| 6 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning start. When this row became effective. GENERATED ALWAYS AS ROW START. |
| 7 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning end. When this row was superseded. GENERATED ALWAYS AS ROW END. 9999-12-31 means current. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a leaf dictionary table.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.LiquidityProviders | LiquidityProviderTypeID | FK | Each liquidity provider instance (e.g., FXCM-Production) references its type |
| Trade.LiquidityProviderExchanges | LiquidityProviderTypeID | FK | Exchange mappings per provider type |
| Trade.LiquidityProviderContracts | LiquidityProviderTypeID | FK | Instrument contracts per provider type (LPC.LiquidityProviderID stores LiquidityProviderTypeID per Internal.Newcurrency comments) |
| Hedge.Accounts | LiquidityProviderTypeID | FK | Hedge accounts link to provider type for routing |
| Hedge.ProviderInstrumentConfiguration | LiquidityProviderTypeID | FK | Order type and limit config per provider type and instrument |
| Hedge.ProviderUnitConversionRatio | LiquidityProviderID | FK | Unit conversion ratios; column actually references LiquidityProviderTypeID |
| Price.LiquidityProviderQuantities | LiquidityProviderTypeID | FK | Price quantities by provider type |
| Price.ExchangeNameToProvider | LiquidityProviderTypeID | FK | Exchange name to provider type mapping |
| Hedge.ProviderConditionalTags | LiquidityProviderTypeID | FK | Conditional tags per provider type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.LiquidityProviderType (table)
```

This object has no code-level dependencies. It is a leaf table.

---

### 6.1 Objects This Depends On

No dependencies. CREATE TABLE has no FROM/JOIN or referenced objects.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetLiquidityProviders | View | JOINs to resolve Name and TypeSettingsXML per provider |
| Trade.GetLiquidityAccountsDetails | View | JOINs to resolve provider type name in account details |
| Hedge.GetHSUnitConversionRatio | Procedure | JOINs for unit conversion by provider type |
| Hedge.GetAllLiquidityAccountsMetadata | Procedure | JOINs for metadata |
| Hedge.GetHedgeServerMetaData | Procedure | JOINs to return provider type as LiquidityProviderID |
| Hedge.GetHedgeServerAccountMapping | View | LEFT JOIN for provider type name |
| Hedge.GetActiveProviderLiquidityAccounts | View | INNER JOIN for provider type |
| Hedge.AddAccountStatus | Procedure | Branches on LiquidityProviderTypeID=3, 11 |
| Internal.Newcurrency | Procedure | JOINs for ProviderUnitConversionRatio and LiquidityProviderContracts |
| OMS.GetOMSInstrumentsforSync | Procedure | JOINs for OMS instrument sync |
| Hedge.SyncLiquidityAccounts | Procedure | Compares account ProviderTypeID to provider LiquidityProviderTypeID |
| Trade.SetNextLiquidityProviderID | Procedure | Reads/writes by LiquidityProviderTypeID |
| dbo.MyView | View | SELECTs from this table |
| dbo.SSRS_Crypto_Executions_Report | Procedure | JOINs provider_type to LiquidityProviderTypeID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeLiquidityProviderType | CLUSTERED | LiquidityProviderTypeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradeLiquidityProviderType | PRIMARY KEY | Enforces unique LiquidityProviderTypeID |
| DF_LiquidityProviderType_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_LiquidityProviderType_SysEnd | DEFAULT | SysEndTime = 9999-12-31 23:59:59.9999999 |
| PERIOD FOR SYSTEM_TIME | System versioning | (SysStartTime, SysEndTime) for temporal queries |
| SYSTEM_VERSIONING | System versioning | History table = History.LiquidityProviderType |

---

## 8. Sample Queries

### 8.1 List all liquidity provider types with names
```sql
SELECT LiquidityProviderTypeID,
       Name,
       TypeSettingsXML
FROM Trade.LiquidityProviderType WITH (NOLOCK)
ORDER BY LiquidityProviderTypeID;
```

### 8.2 Resolve provider type name for liquidity accounts
```sql
SELECT TLPT.LiquidityProviderTypeID,
       TLPT.Name,
       TLP.LiquidityProviderID,
       TLP.LiquidityProviderName
FROM Trade.LiquidityProviders TLP WITH (NOLOCK)
INNER JOIN Trade.LiquidityProviderType TLPT WITH (NOLOCK)
    ON TLP.LiquidityProviderTypeID = TLPT.LiquidityProviderTypeID;
```

### 8.3 Check provider-specific configuration (FD vs IB)
```sql
SELECT LiquidityProviderTypeID,
       Name,
       TypeSettingsXML.value('(typeSettings/executionClassInfo/@class)[1]', 'varchar(500)') AS ExecutionClass
FROM Trade.LiquidityProviderType WITH (NOLOCK)
WHERE LiquidityProviderTypeID IN (3, 11);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Confluence search for "LiquidityProvider" returned pages on dynamic prices, MBO/MBL feeds, and OMS ZBFX impersonation; none specifically document Trade.LiquidityProviderType.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15+ analyzed | App Code: N/A | Corrections: 0 applied*
*Object: Trade.LiquidityProviderType | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.LiquidityProviderType.sql*
