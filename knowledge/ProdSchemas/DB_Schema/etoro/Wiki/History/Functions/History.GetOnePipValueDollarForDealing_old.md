# History.GetOnePipValueDollarForDealing_old

> Older version of GetOnePipValueDollarForDealing using Trade.LastWeekPrices with simplified cross-pair spread logic (no SpreadGroup adjustment) - superseded by the current ForDealing variant, no active consumers.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetOnePipValueDollarForDealing_old(@CID, @InstrumentID, @ProviderID, @IsBuy, @pSpreadedPipBid, @pSpreadedPipAsk, @pPercision) RETURNS MONEY` |
| **Purpose** | Legacy version of GetOnePipValueDollarForDealing - cross pairs use simpler @SpreadBid-only adjustment |

---

## 1. Business Meaning

`History.GetOnePipValueDollarForDealing_old` is the older predecessor to `History.GetOnePipValueDollarForDealing`. The parameter signature and general three-case structure are identical, but the cross-pair case (Case 3) uses a simpler spread adjustment: it applies `@SpreadBid` directly (without the SpreadGroup lookup via Trade.GetSpreadGroup and Trade.ProviderToInstrument).

The "_old" suffix confirms this is a historical artifact retained in the database when the function was upgraded to include SpreadGroup-based spread adjustment for cross pairs. No stored procedures in the SSDT repo call this function. It has EXECUTE permission for the DATA_READER role.

**The `_org` variant (GetOnePipValueDollarForDealing_org) is byte-for-byte identical to this function.**

For full one-pip value formula, see `History.GetOnePipValueDollar.md`.

---

## 2. Business Logic

### 2.1 Differences from Current ForDealing

**Case 1 and Case 2**: Identical to current `GetOnePipValueDollarForDealing`.

**Case 3 (cross pair) - KEY DIFFERENCE**:
- **Current ForDealing**: Cross-pair price uses `TCRP.Bid + CAST(TGSG.Bid AS DECIMAL(16,8)) / POWER(10, TPVI.Precision)` - adds SpreadGroup bid from Trade.GetSpreadGroup, joining Customer.Customer, Trade.GetSpreadGroup, Trade.ProviderToInstrument
- **_old version**: Cross-pair price uses just `TCRP.Bid + @SpreadBid` - adds the raw spread parameter directly, no SpreadGroup or ProviderToInstrument joins needed

The _old version has fewer cross-schema dependencies for cross pairs and produces slightly different results for customers with non-zero SpreadGroup bids.

---

## 3. Data Overview

N/A - no active consumers.

---

## 4. Elements

### Parameters

Identical signature to `History.GetOnePipValueDollarForDealing` - see that document.

### Return Value

| Type | Description |
|------|-------------|
| MONEY | USD value of one pip. Slightly different from current ForDealing for cross pairs where SpreadGroup != 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Notes vs Current ForDealing |
|---------|---------------|------------------------------|
| Trade.Provider | Table | Same |
| Trade.Instrument | Table | Same |
| Dictionary.Currency | Table | Same |
| Customer.Customer | Table | Same (for spread init) |
| Trade.LastWeekPrices | Table | Same |
| Trade.GetSpreadGroup | View | NOT USED in this version |
| Trade.ProviderToInstrument | Table | NOT USED in this version |

### 5.2 Referenced By (other objects point to this)

No active consumers in the SSDT repo.

---

## 6. Dependencies

```
History.GetOnePipValueDollarForDealing_old (scalar function)
|--> Trade.Provider (cross-schema)
|--> Trade.Instrument (cross-schema)
|--> Dictionary.Currency (cross-schema)
|--> Customer.Customer (cross-schema)
+--> Trade.LastWeekPrices (cross-schema)
```

---

## 7. Technical Details

This function and `History.GetOnePipValueDollarForDealing_org` are identical. Both are retained as legacy artifacts. Candidates for removal.

---

## 8. Sample Queries

See `History.GetOnePipValueDollarForDealing.md`.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.0/10 (Elements: 7.8/10, Logic: 8.2/10, Relationships: 7.8/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/5 (1, 8, 10, 11) - legacy function*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetOnePipValueDollarForDealing_old | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetOnePipValueDollarForDealing_old.sql*
