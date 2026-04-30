# Hedge.SupportedInstrumentsAccountTable

> Table-valued parameter type carrying liquidity account / instrument support pairs, for batch operations that configure or verify which instruments each liquidity account can trade.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type) |
| **Key Identifier** | No primary key (heap TVP - composite LiquidityAccountID + InstrumentID) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

`Hedge.SupportedInstrumentsAccountTable` is a Table-Valued Parameter type that carries a set of (LiquidityAccountID, InstrumentID) pairs. Its structure mirrors `Hedge.SupportedInstrumentsAccount` - the table that records which instruments each liquidity (broker) account is permitted to trade on behalf of the hedge system.

This TVP is designed to pass a batch of account/instrument support mappings in a single call. No stored procedures in the current SSDT are found to reference it directly; it may be consumed by application code outside the SSDT project or reserved for future use.

Not all liquidity accounts support all instruments - brokers have instrument restrictions based on regulatory, contractual, or market-making capabilities. This type enables bulk operations against those restrictions.

---

## 2. Business Logic

### 2.1 Account-Instrument Support Mapping

**What**: Each row asserts that a given liquidity account supports trading a given instrument.

**Columns/Parameters Involved**: `LiquidityAccountID`, `InstrumentID`

**Rules**:
- Both columns are NOT NULL - a row must specify both an account and an instrument; neither can be ambiguous.
- No PK constraint - duplicate (LiquidityAccountID, InstrumentID) pairs are allowed by the type definition; consumer code must handle deduplication if required.
- The hedge server uses `Hedge.SupportedInstrumentsAccount` to route orders only to accounts that support the target instrument. This TVP carries the same data for batch operations.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | CODE-BACKED | Identifier of the liquidity (broker) account. Must be NOT NULL - every row must specify which account's instrument support is being declared. Implicit FK to Trade.LiquidityAccounts. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Identifier of the trading instrument that the liquidity account supports. Must be NOT NULL. Implicit FK to Trade.Instrument. Combined with LiquidityAccountID, forms the semantic key of the mapping. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | Implicit | Identifies the broker account whose instrument support is being specified |
| InstrumentID | Trade.Instrument | Implicit | Identifies the trading instrument being supported |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No stored procedures in the SSDT project were found to reference this type. Likely consumed by application code or reserved for future use.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the SSDT stored procedures. May be consumed by application code outside the repo.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (none) | - | - | - | - | - |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View supported instruments per liquidity account
```sql
SELECT SIA.LiquidityAccountID, SIA.InstrumentID,
       TI.Name AS InstrumentName
FROM [Hedge].[SupportedInstrumentsAccount] SIA WITH (NOLOCK)
JOIN [Trade].[Instrument] TI WITH (NOLOCK) ON SIA.InstrumentID = TI.InstrumentID
ORDER BY SIA.LiquidityAccountID, SIA.InstrumentID
```

### 8.2 Find liquidity accounts that do NOT support a specific instrument
```sql
SELECT LA.LiquidityAccountID
FROM [Trade].[LiquidityAccounts] LA WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM [Hedge].[SupportedInstrumentsAccount] SIA WITH (NOLOCK)
    WHERE SIA.LiquidityAccountID = LA.LiquidityAccountID
      AND SIA.InstrumentID = 100
)
```

### 8.3 Count instruments supported per account
```sql
SELECT LiquidityAccountID, COUNT(*) AS SupportedInstrumentCount
FROM [Hedge].[SupportedInstrumentsAccount] WITH (NOLOCK)
GROUP BY LiquidityAccountID
ORDER BY SupportedInstrumentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 7.5/10 (Elements: 10/10, Logic: 6/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.SupportedInstrumentsAccountTable | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.SupportedInstrumentsAccountTable.sql*
