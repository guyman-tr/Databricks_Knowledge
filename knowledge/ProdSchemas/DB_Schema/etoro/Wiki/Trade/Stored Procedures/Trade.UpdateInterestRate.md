# Trade.UpdateInterestRate

> Updates the base interest rate (buy/sell rates and markups) on Dictionary.InterestRate for rows matching (InterestRateID, InstrumentTypeID), restricted to SettlementTypeID = 0 for backward compatibility; superseded by UpdateInterestRates_TRDOPS which handles all settlement types.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UpdateInterestRateTbl.(InterestRateID, InstrumentTypeID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Interest rates in eToro determine the daily financing cost (or credit) applied to leveraged positions. Dictionary.InterestRate holds the base reference rates (e.g., LIBOR-derived or broker-set rates) by (InstrumentTypeID, InterestRateID), while InterestRateOverride holds instrument-specific overrides. This procedure updates the base rates.

The procedure is marked with a comment "Temporary. Only for backwards compatibility, should be removed in the future" on its SettlementTypeID = 0 filter. This restriction means it only updates rows where SettlementTypeID = 0 (standard CFD settlement), silently ignoring rows for other settlement types (e.g., crypto TRS with SettlementTypeID = 4). The TRDOPS variant (Trade.UpdateInterestRates_TRDOPS) was created to replace this procedure with full settlement type support.

No internal SP callers were found; the procedure is called directly from external fee/rate management tooling.

---

## 2. Business Logic

### 2.1 Base Interest Rate Update (SettlementTypeID = 0 Only)

**What**: Updates InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell for matching rows in Dictionary.InterestRate.

**Columns/Parameters Involved**: `InterestRateID`, `InstrumentTypeID`, `InterestRateBuy`, `InterestRateSell`, `MarkupBuy`, `MarkupSell`, `UpdatedByUser`

**Rules**:
- JOIN condition: `IR.InterestRateID = UIR.InterestRateID AND IR.InstrumentTypeID = UIR.InstrumentTypeID`
- WHERE clause: `IR.SettlementTypeID = 0` (hard-coded - backward compatibility restriction)
- Rows in Dictionary.InterestRate with SettlementTypeID != 0 are NOT updated by this procedure
- UpdatedByUser set to @UserName for audit trail
- No transaction wrapper - auto-commit mode
- No INSERT path: only UPDATE (rows must already exist)

**Rate field semantics**:
- InterestRateBuy: Base financing rate charged on leveraged long positions
- InterestRateSell: Base financing rate charged on leveraged short positions
- MarkupBuy: Broker markup added on top of InterestRateBuy
- MarkupSell: Broker markup added on top of InterestRateSell
- Effective rate = InterestRate + Markup

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UpdateInterestRateTbl | Trade.UpdateInterestRateTbl (TVP, READONLY) | NO | - | CODE-BACKED | Batch of interest rate updates. Contains: InstrumentTypeID (int NOT NULL), InterestRateID (int NOT NULL - composite key with InstrumentTypeID for the join), InterestRateBuy (decimal(16,8) NOT NULL), InterestRateSell (decimal(16,8) NOT NULL), MarkupBuy (decimal(16,8) NOT NULL), MarkupSell (decimal(16,8) NOT NULL). No SettlementTypeID column - procedure always targets SettlementTypeID = 0 rows. |
| 2 | @UserName | nvarchar(50) | NO | - | CODE-BACKED | Username of the person or service making the update. Written to Dictionary.InterestRate.UpdatedByUser for audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (InterestRateID, InstrumentTypeID) | Dictionary.InterestRate | UPDATE | Updates 4 rate fields on matching rows, restricted to SettlementTypeID = 0 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External rate management tooling | Application call | Caller | No internal SP callers found; called from rate/fee management systems for base interest rate updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInterestRate (procedure) [BACKWARD COMPAT - SettlementTypeID=0 only]
+-- Dictionary.InterestRate (table) [UPDATE - 4 rate fields where SettlementTypeID=0]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestRate | Table | UPDATEd: InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell, UpdatedByUser - restricted to SettlementTypeID=0 rows |
| Trade.UpdateInterestRateTbl | User Defined Type | TVP type for @UpdateInterestRateTbl |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External rate management application | Application | Calls this deprecated procedure; should migrate to Trade.UpdateInterestRates_TRDOPS |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SettlementTypeID=0 filter | Backward compatibility | Hard-coded WHERE IR.SettlementTypeID = 0; comment: "Temporary. Only for backwards compatibility, should be removed in the future" |
| No INSERT path | Design | UPDATE only; caller must ensure target rows already exist in Dictionary.InterestRate |
| No transaction | Design | Auto-commit mode; no explicit transaction |
| SET ANSI_NULLS ON | Session | Standard null comparison behavior |

---

## 8. Sample Queries

### 8.1 Update base interest rates for an instrument type

```sql
DECLARE @Rates [Trade].[UpdateInterestRateTbl]
INSERT INTO @Rates (InstrumentTypeID, InterestRateID,
                    InterestRateBuy, InterestRateSell,
                    MarkupBuy, MarkupSell)
VALUES (1, 42, 0.01500000, 0.01500000, 0.00500000, 0.00500000)

EXEC Trade.UpdateInterestRate
    @UpdateInterestRateTbl = @Rates,
    @UserName = 'rate_admin'
```

### 8.2 Check current base interest rates

```sql
SELECT
    ir.InterestRateID,
    ir.InstrumentTypeID,
    ir.SettlementTypeID,
    ir.InterestRateBuy,
    ir.InterestRateSell,
    ir.MarkupBuy,
    ir.MarkupSell,
    ir.UpdatedByUser
FROM Dictionary.InterestRate ir WITH (NOLOCK)
WHERE ir.InstrumentTypeID = 1
ORDER BY ir.SettlementTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInterestRate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInterestRate.sql*
