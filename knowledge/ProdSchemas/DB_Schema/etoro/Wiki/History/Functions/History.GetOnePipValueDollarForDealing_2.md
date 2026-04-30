# History.GetOnePipValueDollarForDealing_2

> Exact duplicate of History.GetOnePipValueDollarForDealing - same DDL, same logic, same Trade.LastWeekPrices price source. No active consumers in the SSDT repo.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetOnePipValueDollarForDealing_2(@CID, @InstrumentID, @ProviderID, @IsBuy, @pSpreadedPipBid, @pSpreadedPipAsk, @pPercision) RETURNS MONEY` |
| **Purpose** | Duplicate of GetOnePipValueDollarForDealing - likely an experimental/test copy |

---

## 1. Business Meaning

`History.GetOnePipValueDollarForDealing_2` is byte-for-byte identical to `History.GetOnePipValueDollarForDealing`. Both use `Trade.LastWeekPrices` as the price source, the same three-case currency logic (direct USD, indirect USD, cross pair with SpreadGroup adjustment), and the same parameter signature. The `_2` suffix indicates it was created as a copy - likely during a planned refactoring of the Dealing P&L calculation that never materialized, or as a test variant.

No stored procedures in the SSDT repo call this function. It exists in the database and has EXECUTE permission for the DATA_READER role (from `UsersPermissions/DATA_READER.sql`), but no active consumers.

**For full documentation of the logic, parameters, and behavior, see `History.GetOnePipValueDollarForDealing.md`** - the documentation is identical.

---

## 2. Business Logic

Identical to `History.GetOnePipValueDollarForDealing`. See that document for full logic description.

---

## 3. Data Overview

N/A - no active consumers. Behavior is identical to History.GetOnePipValueDollarForDealing.

---

## 4. Elements

### Parameters

Identical to `History.GetOnePipValueDollarForDealing` - see that document.

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @CID | INTEGER | Customer ID |
| 2 | @InstrumentID | INTEGER | Trading instrument |
| 3 | @ProviderID | INTEGER | Liquidity provider |
| 4 | @IsBuy | INTEGER | Direction: 1=buy, 0=sell |
| 5 | @pSpreadedPipBid | dtPrice | Spread bid in pips |
| 6 | @pSpreadedPipAsk | dtPrice | Spread ask in pips |
| 7 | @pPercision | TINYINT | Decimal precision |

### Return Value

| Type | Description |
|------|-------------|
| MONEY | USD value of one pip. Identical behavior to History.GetOnePipValueDollarForDealing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as History.GetOnePipValueDollarForDealing: Trade.Provider, Trade.Instrument, Dictionary.Currency, Customer.Customer, Trade.GetSpreadGroup, Trade.ProviderToInstrument, Trade.LastWeekPrices.

### 5.2 Referenced By (other objects point to this)

No active consumers in the SSDT repo.

---

## 6. Dependencies

Same as `History.GetOnePipValueDollarForDealing` - see that document.

---

## 7. Technical Details

This function is a maintenance liability - a duplicate with no active consumers. It should be considered for removal if the schema is cleaned up.

---

## 8. Sample Queries

See `History.GetOnePipValueDollarForDealing.md` - identical usage.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.0/10 (Elements: 8.0/10, Logic: 8.0/10, Relationships: 7.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/5 (1, 8, 10, 11) - identical to ForDealing*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetOnePipValueDollarForDealing_2 | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetOnePipValueDollarForDealing_2.sql*
