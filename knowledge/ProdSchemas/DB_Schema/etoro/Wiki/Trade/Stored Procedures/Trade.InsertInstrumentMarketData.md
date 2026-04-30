# Trade.InsertInstrumentMarketData

> Atomically provisions market data infrastructure for a new instrument: initializes a 1:1 split ratio baseline, inserts liquidity provider contracts, and creates the three standard CDN image records.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertInstrumentMarketData is a **market data provisioning SP** called during instrument onboarding to set up three market data foundations: a base split ratio record (1:1, no adjustments yet applied), liquidity provider contract(s) for pricing, and standard CDN image URLs. All three are inserted in a single atomic transaction.

The SP's commented-out parameters (SellCurrencyID, InstrumentTypeID, ShardID, etc.) indicate it was originally planned as a broader metadata insert but was split from metadata concerns - the full metadata insert is handled by `Trade.InsertInstrumentMetaData`.

---

## 2. Business Logic

### 2.1 Split Ratio Baseline Initialization

**What**: Inserts a baseline 1:1 split ratio row into History.SplitRatio, establishing the split adjustment foundation for the new instrument.

**Target**: `History.SplitRatio`

**Rules**:
- MinDate = GETUTCDATE(), MaxDate = '2100-01-01' (open-ended record)
- PriceRatio = 1, AmountRatio = 1 (no split adjustment)
- PriceRatioUnAdjusted = 1.0, AmountRatioUnAdjusted = 1.0
- All IsCompleted* and notification flags = 0 (no actions yet taken)
- This baseline row allows the split adjustment logic to calculate P&L correctly from day one

### 2.2 Liquidity Provider Contracts

**What**: Inserts LP contract records from the TVP, associating liquidity providers with this instrument.

**Target**: `Trade.LiquidityProviderContracts`

**Columns/Parameters Involved**: `@LiquidityProviderContract dbo.LiquidityProviderContractTableType`

**Rules**:
- FromDate = GETUTCDATE(), ToDate = '2100-01-01' (open-ended contracts)
- ExchangeID = @ExchangeID (same for all LP contracts in this call)
- LiquidityProviderID, Ticker, RateConversionFactor from TVP

### 2.3 Instrument Images (3 Standard CDN Sizes)

**What**: Creates the three standard instrument avatar image records using the eToro CDN URL pattern.

**Target**: `Trade.InstrumentImages`

**Rules**:
- Image URLs constructed as: `https://etoro-cdn.etorostatic.com/market-avatars/{InstrumentID}/{WxH}.png`
- Three sizes: 35x35, 50x50, 150x150
- Images must be uploaded to CDN separately; this SP only creates the DB records pointing to where they will be

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument being onboarded. Used as PK for all three insert targets and in CDN image URL construction. |
| 2 | @ExchangeID | INT | NO | - | CODE-BACKED | Exchange ID applied to all LP contracts in the TVP. All contracts for this onboarding call are assigned to the same exchange. |
| 3 | @LiquidityProviderContract | dbo.LiquidityProviderContractTableType | NO | - | CODE-BACKED | TVP (READONLY) of liquidity provider contracts. Each row: LiquidityProviderID, Ticker, RateConversionFactor. All get InstrumentID=@InstrumentID and ExchangeID=@ExchangeID. Uses dbo schema UDT (not Trade schema). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (inserts into) | History.SplitRatio | WRITER (cross-schema) | Baseline 1:1 split ratio initialization |
| (inserts into) | Trade.LiquidityProviderContracts | WRITER | LP contract records for pricing |
| (inserts into) | Trade.InstrumentImages | WRITER | 3 standard CDN image URL records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations/admin tooling (external) | EXEC Trade.InsertInstrumentMarketData | Caller | Called during instrument onboarding workflow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertInstrumentMarketData (procedure)
|- History.SplitRatio (table - cross-schema)
|- Trade.LiquidityProviderContracts (table)
|- Trade.InstrumentImages (table)
`-- dbo.LiquidityProviderContractTableType (UDT, TVP type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table (cross-schema) | Insert: baseline split ratio |
| Trade.LiquidityProviderContracts | Table | Insert: LP contracts |
| Trade.InstrumentImages | Table | Insert: 3 CDN image records |
| dbo.LiquidityProviderContractTableType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Instrument onboarding workflow | Process | Calls this SP as part of new instrument setup |
| Trade.InsertInstrumentMetaData | Procedure | Sibling SP - handles core metadata/instrument table inserts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | BEGIN TRAN / COMMIT / ROLLBACK | All three inserts are atomic |
| CDN URLs | Hardcoded pattern | Image URLs use eToro CDN pattern; actual images must be uploaded separately |
| Split ratio defaults | Hardcoded | 1:1 ratio, all IsCompleted* = 0, open-ended date to 2100 |
| LP contract dates | Hardcoded | FromDate = GETUTCDATE(), ToDate = 2100-01-01 |

---

## 8. Sample Queries

### 8.1 Verify market data provisioning

```sql
SELECT * FROM History.SplitRatio WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
SELECT * FROM Trade.LiquidityProviderContracts WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
SELECT * FROM Trade.InstrumentImages WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertInstrumentMarketData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertInstrumentMarketData.sql*
