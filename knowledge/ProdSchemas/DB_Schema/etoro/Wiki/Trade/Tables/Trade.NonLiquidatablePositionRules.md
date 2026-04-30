# Trade.NonLiquidatablePositionRules

## 1. Business Meaning

Defines (InstrumentTypeID, SettlementTypeID) combinations that must **not** be liquidated during account liquidation or margin-call events. Positions matching these rules are excluded from forced closure; only liquidatable positions are closed.

## 2. Business Logic

- **Exclusion rule**: A position is non-liquidatable when its InstrumentTypeID and SettlementTypeID match a row in this table.
- **Liquidation flow**: Procedures `GetAccountAssetsForLiquidation`, `GetAllAccountAssetsForLiquidation`, `GetCIDAccountAssetsForLiquidation` join `Trade.InstrumentMetaData` (InstrumentTypeID) and `Trade.PositionTbl` (SettlementTypeID) to `NonLiquidatablePositionRules`. Match → IsNonLiquidatable = 1.
- **Current rule**: InstrumentTypeID = 10 (Crypto), SettlementTypeID = 1 (e.g., Real/Settled). Crypto real positions are excluded from liquidation.
- **Dictionary table**: Small reference data; stored on DICTIONARY filegroup.

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count | 1 |
| Partitioning | None |
| Filegroup | DICTIONARY |
| Typical size | < 10 rows |

**Current rule:**
| InstrumentTypeID | SettlementTypeID |
|-----------------|------------------|
| 10 (Crypto)     | 1 (Real)         |

## 4. Elements

| # | Column | Type | Nullable | Default | Description |
|---|--------|------|----------|---------|-------------|
| 1 | InstrumentTypeID | int | NO | - | Asset class. FK to Dictionary.CurrencyType. 1=Forex, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto. |
| 2 | SettlementTypeID | int | NO | - | Settlement type (CFD vs Real). Matches Trade.PositionTbl.SettlementTypeID. |

## 5. Relationships

| From | To | Type | Join |
|------|-----|------|------|
| InstrumentTypeID | Dictionary.CurrencyType | Implicit FK | Instrument type lookup |
| InstrumentTypeID | Trade.InstrumentMetaData | Via position | IMT.InstrumentTypeID = NLPR.InstrumentTypeID |
| SettlementTypeID | Trade.PositionTbl | Via position | TP.SettlementTypeID = NLPR.SettlementTypeID |

## 6. Dependencies

**Referenced by procedures:**
- `Trade.GetAccountAssetsForLiquidation` – Positions for liquidation by CID.
- `Trade.GetAllAccountAssetsForLiquidation` – All account assets for liquidation.
- `Trade.GetCIDAccountAssetsForLiquidation` – CID-specific account assets for liquidation.

**Related tables:**
- `Trade.InstrumentMetaData` – Supplies InstrumentTypeID per instrument.
- `Trade.PositionTbl` – Supplies SettlementTypeID, CID, PositionID for liquidation decisions.

## 7. Technical Details

- **Primary key**: (InstrumentTypeID, SettlementTypeID)
- **Filegroup**: DICTIONARY (small lookup table).
- **Indexes**: PK only.
- **No triggers or defaults**.

## 8. Sample Queries

```sql
-- All non-liquidatable rules
SELECT InstrumentTypeID, SettlementTypeID
FROM Trade.NonLiquidatablePositionRules;

-- Check if a position (InstrumentTypeID, SettlementTypeID) is non-liquidatable
SELECT IIF(EXISTS (
  SELECT 1 FROM Trade.NonLiquidatablePositionRules
  WHERE InstrumentTypeID = 10 AND SettlementTypeID = 1
), 1, 0) AS IsNonLiquidatable;
```

## 9. Atlassian Knowledge Sources

- Jira/Confluence: Search for "non liquidatable", "liquidation rules", "exclude from liquidation", "crypto liquidation".
- No direct Confluence/Jira references found in codebase.

---

*Generated: 2026-03-14 | Quality: 8.5/10*
