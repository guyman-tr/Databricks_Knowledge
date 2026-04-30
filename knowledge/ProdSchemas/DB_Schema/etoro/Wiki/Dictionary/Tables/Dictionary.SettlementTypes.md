# Dictionary.SettlementTypes

> Lookup table defining how trading positions are settled — whether the customer owns the underlying asset or holds a derivative contract. One of the most critical business classifications in the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | SettlementTypeID (TINYINT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.SettlementTypes defines the fundamental classification of how a trading position is financially settled. This determines whether the customer actually owns the underlying asset (stocks, crypto) or holds a derivative contract that tracks its price (CFD, TRS). This distinction affects every aspect of a position: regulatory treatment, leverage eligibility, dividend handling, tax reporting, voting rights, and risk management.

This table is foundational to eToro's dual-model business — the platform simultaneously operates as both a CFD broker (derivative contracts) and a securities broker (real asset ownership). Without this classification, the system cannot correctly calculate PnL, apply the right fee structures, route hedge orders, or comply with securities regulations across different jurisdictions.

SettlementTypeID is set when a position is opened (Trade.PositionTbl) and is determined by the instrument, the user's regulation, and the chosen leverage. Leverage=1 positions on eligible instruments are REAL (1); leveraged positions are CFD (0). The settlement type is then referenced throughout the position lifecycle — in close operations, PnL calculations, interest rate application, copy-trading restrictions, and hedge execution. The legacy `IsSettled` BIT column in PositionTbl predates this table and maps 0→CFD, 1→REAL.

---

## 2. Business Logic

### 2.1 Settlement Model Selection

**What**: The rules that determine which settlement type a position receives at open time.

**Columns/Parameters Involved**: `SettlementTypeID`, `SettlementType`

**Rules**:
- **CFD (0)**: Default for all leveraged positions (Leverage > 1), all short positions, and all instruments that don't support real ownership (e.g., forex pairs, indices)
- **REAL (1)**: Applied when Leverage=1 AND the instrument supports real ownership (stocks, ETFs, crypto) AND the user's regulation permits it. Customer owns actual shares/crypto held by eToro's custodian
- **TRS (2)**: Total Return Swap — used in jurisdictions where CFDs face restrictions but direct ownership isn't feasible. Functionally similar to CFD from user perspective
- **CMT (3)**: Commitment — operational/internal scenario for pre-trade commitments
- **REAL_FUTURES (4)**: Real ownership of futures contracts (distinct from CFD on futures)
- **MARGIN_TRADE (5)**: Margin-based trading with borrowing, combining aspects of real ownership and leverage

**Diagram**:
```
Position Open Request
    │
    ├── Leverage > 1? ──► YES ──► SettlementTypeID = 0 (CFD)
    │
    ├── Instrument supports REAL? ──► NO ──► SettlementTypeID = 0 (CFD)
    │
    ├── Regulation allows REAL? ──► NO ──► SettlementTypeID = 2 (TRS) or 0 (CFD)
    │
    └── All conditions met ──► SettlementTypeID = 1 (REAL)
```

### 2.2 Legacy IsSettled Compatibility

**What**: The relationship between SettlementTypeID and the legacy IsSettled BIT column.

**Columns/Parameters Involved**: `SettlementTypeID`

**Rules**:
- Before SettlementTypeID was introduced, positions used `IsSettled` BIT: 0=CFD, 1=REAL
- Code uses `ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint))` to handle legacy positions
- Functions like `Trade.FnIsRealPosition(IsSettled, InstrumentID)` operate on the legacy column
- New positions always have SettlementTypeID populated; IsSettled is maintained for backward compatibility

### 2.3 Impact on Position Lifecycle

**What**: How settlement type affects position behavior throughout its lifetime.

**Columns/Parameters Involved**: `SettlementTypeID`

**Rules**:
- **Dividends**: REAL positions receive actual dividends; CFD positions receive dividend adjustments
- **Interest/Overnight fees**: Different overnight fee patterns apply based on settlement type (Dictionary.OverNightFeePattern)
- **Hedge routing**: REAL positions may route to different liquidity providers than CFD positions
- **Copy-trading**: Settlement restrictions per copy relationship are stored in Trade.CopyTradeSettlementRestrictions
- **Tax reporting**: REAL positions generate different tax events (capital gains on shares vs CFD P&L)

---

## 3. Data Overview

| SettlementTypeID | SettlementType | Meaning |
|---|---|---|
| 0 | CFD | Contract for Difference — the customer holds a derivative contract tracking the asset's price movement. Allows leverage, short selling, and overnight fee application. No asset ownership, no voting rights, no real dividends (only adjustments). The original and most common settlement type on eToro. |
| 1 | REAL | Real asset ownership — the customer owns actual shares or cryptocurrency held by eToro's custodian (Citi, etc.). Requires Leverage=1 (no leverage), long-only. Entitles the customer to dividends, corporate action participation, and potential voting rights. Introduced as eToro expanded from CFD-only to multi-asset. |
| 2 | TRS | Total Return Swap — a derivative where eToro swaps the total return of the underlying asset with the customer. Used in regulatory jurisdictions where CFDs are restricted but direct ownership isn't operationally supported. Functionally similar to CFD from the user's perspective. |
| 3 | CMT | Commitment — reserved for internal/operational scenarios involving pre-trade commitment tracking. Rarely used in production customer positions. |
| 4 | REAL_FUTURES | Real futures contract ownership — the customer holds an actual futures contract rather than a CFD on futures. Specific to futures-eligible instruments and regulations. |
| 5 | MARGIN_TRADE | Margin-based trading — positions with borrowing capability. Combines elements of real ownership with leverage through margin lending rather than CFD mechanics. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SettlementTypeID | tinyint | NO | - | VERIFIED | Primary key identifying the settlement model. 0=CFD (derivative, leverageable, short-eligible), 1=REAL (asset ownership, leverage=1, long-only), 2=TRS (total return swap, regulatory alternative to CFD), 3=CMT (commitment, internal), 4=REAL_FUTURES (futures ownership), 5=MARGIN_TRADE (leveraged ownership via margin lending). This is the most consequential classification for a position — it determines dividend treatment, fee structure, hedge routing, regulatory reporting, and tax implications. Stored in Trade.PositionTbl.SettlementTypeID. See [Settlement Type](_glossary.md#settlement-type). (Dictionary.SettlementTypes) |
| 2 | SettlementType | varchar(20) | NO | - | VERIFIED | Human-readable code for the settlement model. Used in procedure logic for CASE/IIF branching (e.g., `SettlementType='REAL'`), in reporting outputs, and in API responses. Not a display label — it's a code string used in business logic comparisons. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionTbl | SettlementTypeID | Implicit Lookup | Every open/closed position stores its settlement type |
| Trade.OrderForClose | SettlementTypeID | Implicit Lookup | Close orders reference settlement type for routing |
| Trade.CopyTradeSettlementRestrictions | SettlementTypeID | Implicit Lookup | Copy-trading restrictions per settlement type |
| Trade.GetPositionData (view) | SettlementTypeID | JOIN | Main position data view includes settlement type |
| Trade.GetPositionData_WithIsComputeForHedge (view) | SettlementTypeID | JOIN | Hedge computation view includes settlement type |
| History.PositionForExternalUse (view) | SettlementTypeID | JOIN | External reporting view includes settlement type |
| History.PositionChangeLog_Active (view) | SettlementTypeID | JOIN | Position change audit includes settlement type |
| Trade.OrderEntryOpen | SettlementTypeID | Read | Open order procedure selects settlement type based on instrument/leverage/regulation |
| Trade.DeleteOrderForCloseJob | SettlementTypeID | Read | Close order cleanup references settlement type |
| Trade.GetCIDAccountAssetsForLiquidation | SettlementTypeID | Read | Liquidation procedure routes by settlement type |
| Trade.UpdateInterestRate | SettlementTypeID | Read | Overnight fee calculation varies by settlement type |
| Trade.InsertBSLMessagesIntoQueue | SettlementTypeID | Read | BSL (Below Stop Loss) processing references settlement type |
| Trade.PositionReopen | SettlementTypeID | Read | Position reopen preserves settlement type |
| Dictionary.SettlementRestrictions | SettlementTypeID | Implicit Lookup | Settlement restrictions per instrument/regulation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Stores SettlementTypeID per position |
| Trade.OrderForClose | Table | Close orders reference settlement type |
| Trade.CopyTradeSettlementRestrictions | Table | Settlement restrictions per copy relationship |
| Dictionary.SettlementRestrictions | Table | Per-instrument settlement restrictions |
| Dictionary.SettlementMethodValues | Table | Settlement method value mappings |
| Trade.GetPositionData | View | Main position data view |
| Trade.GetPositionData_WithIsComputeForHedge | View | Hedge computation view |
| History.PositionForExternalUse | View | External reporting view |
| Trade.OrderEntryOpen | Stored Procedure | Determines settlement type at position open |
| Trade.GetCIDAccountAssetsForLiquidation | Stored Procedure | Liquidation routing by settlement type |
| Trade.UpdateInterestRate | Stored Procedure | Overnight fee calculation |
| Trade.UpdateIsSettledValidation | Stored Procedure | Validates settlement type changes |
| Trade.GetPositionsDataWithCIDForAPI | Stored Procedure | API position data includes settlement type |
| Trade.UpdateInstrumentToFeeConfigTableV2 | Stored Procedure | Fee config per settlement type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SettlementTypes_SettlementTypeID | CLUSTERED PK | SettlementTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SettlementTypes_SettlementTypeID | PRIMARY KEY | Unique settlement type identifier |

---

## 8. Sample Queries

### 8.1 List all settlement types
```sql
SELECT  SettlementTypeID,
        SettlementType
FROM    [Dictionary].[SettlementTypes] WITH (NOLOCK)
ORDER BY SettlementTypeID;
```

### 8.2 Count open positions by settlement type
```sql
SELECT  dst.SettlementType,
        COUNT(*) AS PositionCount
FROM    [Trade].[PositionTbl] tp WITH (NOLOCK)
JOIN    [Dictionary].[SettlementTypes] dst WITH (NOLOCK)
        ON ISNULL(tp.SettlementTypeID, CAST(tp.IsSettled AS tinyint)) = dst.SettlementTypeID
WHERE   tp.IsClosed = 0
GROUP BY dst.SettlementType
ORDER BY PositionCount DESC;
```

### 8.3 Find REAL stock positions for a specific customer
```sql
SELECT  tp.PositionID,
        dc.Name AS InstrumentName,
        dst.SettlementType,
        tp.Amount,
        tp.OpenDateTime
FROM    [Trade].[PositionTbl] tp WITH (NOLOCK)
JOIN    [Dictionary].[SettlementTypes] dst WITH (NOLOCK)
        ON tp.SettlementTypeID = dst.SettlementTypeID
JOIN    [Dictionary].[Currency] dc WITH (NOLOCK)
        ON tp.CurrencyID = dc.CurrencyID
WHERE   tp.CID = @CID
        AND tp.SettlementTypeID = 1
        AND tp.IsClosed = 0
ORDER BY tp.OpenDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.SettlementTypes. Business meaning derived from extensive codebase analysis of Trade schema procedures and the legacy IsSettled→SettlementTypeID migration pattern.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.SettlementTypes | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.SettlementTypes.sql*
