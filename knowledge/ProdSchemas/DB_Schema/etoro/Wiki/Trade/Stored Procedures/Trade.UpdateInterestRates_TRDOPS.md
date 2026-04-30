# Trade.UpdateInterestRates_TRDOPS

> TRDOPS replacement for UpdateInterestRate that updates base interest rates on Dictionary.InterestRate using a four-column composite join (InterestRateID, InstrumentTypeID, SettlementTypeID, OverNightFeePatternID), enabling full multi-settlement-type rate management without the SettlementTypeID=0 restriction of the legacy procedure.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UpdateInterestRateTbl.(InterestRateID, InstrumentTypeID, SettlementTypeID, OverNightFeePatternID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the current, preferred procedure for updating base interest rates in Dictionary.InterestRate. It replaces Trade.UpdateInterestRate, which was restricted to SettlementTypeID = 0 (standard CFD) due to backward compatibility. This TRDOPS version uses a four-column composite join key that includes SettlementTypeID and OverNightFeePatternID, allowing rate updates for all settlement types (e.g., 0 = standard CFD, 4 = crypto TRS) and across different overnight fee patterns.

The four-column join is the entire difference from the legacy procedure: it adds SettlementTypeID and OverNightFeePatternID to the join condition. The update operation (setting 4 rate fields + UpdatedByUser) is otherwise identical.

No internal SP callers were found. Called directly from TRDOPS rate management tooling.

---

## 2. Business Logic

### 2.1 Full Composite Key Rate Update

**What**: Updates InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell for rows matching all four join columns.

**Columns/Parameters Involved**: `InterestRateID`, `InstrumentTypeID`, `SettlementTypeID`, `OverNightFeePatternID`, all 4 rate fields, `UpdatedByUser`

**Rules**:
- JOIN: `IR.InterestRateID = UIR.InterestRateID AND IR.InstrumentTypeID = UIR.InstrumentTypeID AND IR.SettlementTypeID = UIR.SettlementTypeID AND IR.OverNightFeePatternID = UIR.OverNightFeePatternID`
- All four columns must match - no partial key lookup
- No INSERT path: only UPDATE (rows must already exist in Dictionary.InterestRate)
- No transaction wrapper - auto-commit mode
- Note: Uses `WITH (NOLOCK)` hint on the UPDATE source table - unusual but present in DDL

**Rate field semantics**:
- InterestRateBuy: Base financing rate for long (buy) positions
- InterestRateSell: Base financing rate for short (sell) positions
- MarkupBuy: Broker markup on buy rate (effective rate = InterestRateBuy + MarkupBuy)
- MarkupSell: Broker markup on sell rate (effective rate = InterestRateSell + MarkupSell)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UpdateInterestRateTbl | Trade.UpdateInterestRateTbl_TRDOPS (TVP, READONLY) | NO | - | CODE-BACKED | TRDOPS V2 rate update TVP. Composite join key: InstrumentTypeID (int NOT NULL), InterestRateID (int NOT NULL), SettlementTypeID (tinyint NOT NULL - 0=standard CFD, 4=crypto TRS), OverNightFeePatternID (tinyint NOT NULL - overnight fee pattern). Rate fields (decimal(16,8) NOT NULL): InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell. All four key fields must match Dictionary.InterestRate for the UPDATE to affect a row. |
| 2 | @AppLoginName | varchar(50) | NO | - | CODE-BACKED | Username or service name written to Dictionary.InterestRate.UpdatedByUser for audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (InterestRateID, InstrumentTypeID, SettlementTypeID, OverNightFeePatternID) | Dictionary.InterestRate | UPDATE | Updates 4 rate fields on rows matching all four join columns |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TRDOPS rate management tooling | Application call | Caller | No internal SP callers found; preferred replacement for Trade.UpdateInterestRate |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInterestRates_TRDOPS (procedure)
+-- Dictionary.InterestRate (table) [UPDATE - 4 rate fields, 4-column composite key join]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestRate | Table | UPDATEd: InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell, UpdatedByUser - joined on all four key columns |
| Trade.UpdateInterestRateTbl_TRDOPS | User Defined Type | TVP type for @UpdateInterestRateTbl; includes SettlementTypeID and OverNightFeePatternID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TRDOPS rate management application | Application | Current preferred procedure for base interest rate updates across all settlement types |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Four-column join | Design | All of InterestRateID + InstrumentTypeID + SettlementTypeID + OverNightFeePatternID must match for UPDATE to fire |
| No INSERT path | Design | UPDATE only; rows must pre-exist in Dictionary.InterestRate |
| No transaction | Design | Auto-commit mode; no explicit BEGIN TRAN |
| NOLOCK hint | Isolation | WITH (NOLOCK) on the Dictionary.InterestRate source in FROM clause - reads may include uncommitted data |

---

## 8. Sample Queries

### 8.1 Update base rates for standard CFD instruments (SettlementTypeID = 0)

```sql
DECLARE @Rates [Trade].[UpdateInterestRateTbl_TRDOPS]
INSERT INTO @Rates (InstrumentTypeID, InterestRateID, SettlementTypeID, OverNightFeePatternID,
                    InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell)
VALUES (1, 42, 0, 1, 0.01500000, 0.01500000, 0.00500000, 0.00500000)

EXEC Trade.UpdateInterestRates_TRDOPS
    @UpdateInterestRateTbl = @Rates,
    @AppLoginName = 'trdops_admin'
```

### 8.2 Update rates for crypto TRS instruments (SettlementTypeID = 4)

```sql
DECLARE @Rates [Trade].[UpdateInterestRateTbl_TRDOPS]
INSERT INTO @Rates (InstrumentTypeID, InterestRateID, SettlementTypeID, OverNightFeePatternID,
                    InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell)
VALUES (5, 100, 4, 2, 0.02000000, 0.02000000, 0.00750000, 0.00750000)

EXEC Trade.UpdateInterestRates_TRDOPS
    @UpdateInterestRateTbl = @Rates,
    @AppLoginName = 'trdops_admin'
```

### 8.3 Check current base interest rates

```sql
SELECT
    ir.InterestRateID,
    ir.InstrumentTypeID,
    ir.SettlementTypeID,
    ir.OverNightFeePatternID,
    ir.InterestRateBuy,
    ir.InterestRateSell,
    ir.MarkupBuy,
    ir.MarkupSell,
    ir.UpdatedByUser
FROM Dictionary.InterestRate ir WITH (NOLOCK)
WHERE ir.InstrumentTypeID = 1
ORDER BY ir.SettlementTypeID, ir.OverNightFeePatternID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInterestRates_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInterestRates_TRDOPS.sql*
