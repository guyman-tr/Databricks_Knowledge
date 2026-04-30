# Trade.GetInstrumentRateSources

> Enriches Trade.InstrumentRateSources with liquidity account and provider names by joining to GetLiquidityAccounts and LiquidityProviders - provides a human-readable rate source configuration per instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentRateSourceID (from base table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentRateSources answers: "For each instrument, which liquidity accounts provide price feeds, at what priority, and which liquidity provider owns those accounts?" The view joins the raw rate source configuration (Trade.InstrumentRateSources) with human-readable names from Trade.GetLiquidityAccounts and Trade.LiquidityProviders, so callers get a complete picture without needing to resolve IDs manually.

This view exists to centralize the rate-source-to-provider resolution. Without it, every consumer would need to join InstrumentRateSources to GetLiquidityAccounts to LiquidityProviders. The LEFT JOINs ensure that even rate sources with missing or unlinked liquidity accounts still appear (with NULL names), which is important for diagnostics.

Data flows: The view reads from Trade.InstrumentRateSources (base configuration), Trade.GetLiquidityAccounts (view providing account details), and Trade.LiquidityProviders (provider master). All three use WITH (NOLOCK). The view is defined identically in both etoro and tradonomi databases. A parallel view exists in the Price schema (Price.GetInstrumentRateSources).

---

## 2. Business Logic

### 2.1 Rate Source Priority Chain

**What**: Each instrument can have multiple rate sources (liquidity accounts) ranked by priority.

**Columns/Parameters Involved**: `InstrumentID`, `LiquidityAccountID`, `Priority`

**Rules**:
- Lower Priority value = higher precedence (the pricing engine uses the first available source)
- Each rate source belongs to a PriceServerID, which determines which price server instance handles that feed
- LEFT JOINs ensure orphaned rate sources (where the liquidity account or provider was removed) remain visible for troubleshooting

### 2.2 Provider Resolution via Liquidity Account

**What**: The view resolves the chain: InstrumentRateSource -> LiquidityAccount -> LiquidityProvider.

**Columns/Parameters Involved**: `LiquidityAccountID`, `LiquidityAccountName`, `LiquidityProviderID`, `LiquidityProviderName`

**Rules**:
- LiquidityAccountName comes from Trade.GetLiquidityAccounts (which itself resolves from Trade.LiquidityAccounts)
- LiquidityProviderID and LiquidityProviderName come from Trade.LiquidityProviders, joined via the account's provider ID
- A NULL LiquidityProviderName indicates the account is not linked to an active provider

---

## 3. Data Overview

No rows returned in the current environment (InstrumentRateSources may be empty or not deployed in this instance).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentRateSourceID | int | NO | - | CODE-BACKED | Primary key from Trade.InstrumentRateSources. Uniquely identifies a rate source assignment for a specific instrument on a specific price server. |
| 2 | PriceServerID | int | NO | - | CODE-BACKED | Identifies which price server instance handles this rate feed. From Trade.InstrumentRateSources. Multiple price servers can feed the same instrument for redundancy. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | The tradeable instrument receiving the price feed. FK to Trade.Instrument.InstrumentID. From Trade.InstrumentRateSources. |
| 4 | LiquidityAccountID | int | YES | - | CODE-BACKED | The liquidity account providing the price feed. FK to Trade.LiquidityAccounts.LiquidityAccountID. From Trade.InstrumentRateSources. NULL if not assigned. |
| 5 | LiquidityAccountName | nvarchar | YES | - | CODE-BACKED | Human-readable name of the liquidity account. From Trade.GetLiquidityAccounts via LEFT JOIN. NULL if the account is missing or unlinked. |
| 6 | LiquidityProviderID | int | YES | - | CODE-BACKED | The liquidity provider that owns the liquidity account. From Trade.LiquidityProviders via LEFT JOIN through GetLiquidityAccounts. NULL if no provider is linked. |
| 7 | LiquidityProviderName | nvarchar | YES | - | CODE-BACKED | Human-readable name of the liquidity provider. From Trade.LiquidityProviders. NULL if the provider record is missing. |
| 8 | Priority | int | NO | - | CODE-BACKED | Rank of this rate source for the instrument. Lower value = higher priority. The pricing engine uses the highest-priority available source. From Trade.InstrumentRateSources. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentRateSourceID, InstrumentID, PriceServerID, LiquidityAccountID, Priority | Trade.InstrumentRateSources | FROM | Base table providing rate source configuration |
| LiquidityAccountID, LiquidityAccountName | Trade.GetLiquidityAccounts | LEFT JOIN | View providing liquidity account names |
| LiquidityProviderID, LiquidityProviderName | Trade.LiquidityProviders | LEFT JOIN | Provider master for LP names |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views in the SSDT repo directly reference Trade.GetInstrumentRateSources. A parallel view (Price.GetInstrumentRateSources) exists in the Price schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentRateSources (view)
+-- Trade.InstrumentRateSources (table)
+-- Trade.GetLiquidityAccounts (view)
|     +-- Trade.LiquidityAccounts (table)
+-- Trade.LiquidityProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentRateSources | Table | FROM - base rate source data |
| Trade.GetLiquidityAccounts | View | LEFT JOIN on LiquidityAccountID for account names |
| Trade.LiquidityProviders | Table | LEFT JOIN on LiquidityProviderID for provider names |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 List all rate sources for a specific instrument

```sql
SELECT  *
FROM    Trade.GetInstrumentRateSources WITH (NOLOCK)
WHERE   InstrumentID = 1
ORDER BY Priority
```

### 8.2 Find instruments with multiple rate sources

```sql
SELECT  InstrumentID,
        COUNT(*) AS SourceCount
FROM    Trade.GetInstrumentRateSources WITH (NOLOCK)
GROUP BY InstrumentID
HAVING COUNT(*) > 1
ORDER BY SourceCount DESC
```

### 8.3 Show rate sources grouped by liquidity provider

```sql
SELECT  LiquidityProviderName,
        COUNT(DISTINCT InstrumentID) AS InstrumentsCovered,
        COUNT(*) AS TotalSources
FROM    Trade.GetInstrumentRateSources WITH (NOLOCK)
WHERE   LiquidityProviderName IS NOT NULL
GROUP BY LiquidityProviderName
ORDER BY InstrumentsCovered DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentRateSources | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentRateSources.sql*
