# Hedge.AddHedgeAccountStatus

> Simplified variant of AddAccountStatus: inserts a liquidity provider account financial snapshot into Hedge.AccountStatus without applying any provider-type-specific balance adjustments.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.AccountStatus (same target as AddAccountStatus) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddHedgeAccountStatus` is the simpler sibling of `Hedge.AddAccountStatus`. Both procedures insert into `Hedge.AccountStatus`, but this one skips the provider-type lookup and balance adjustment step - it stores `@Balance` exactly as received from the caller, regardless of the liquidity provider type.

The differences between the two procedures are:
1. **This procedure**: No lookup of LiquidityProviderTypeID. No balance recalculation. Direct INSERT only.
2. **AddAccountStatus**: Looks up LiquidityProviderTypeID; recalculates @Balance for FD (type 3) and IB (type 11) providers before inserting.

This procedure is used when the caller has already pre-calculated or normalized the balance value, or when writing from a context where the provider type is already known to not require adjustment. The `@Balance` and `@NetPL` fields use wider decimal types here (Decimal(18,4) vs Decimal(16,4) in AddAccountStatus), suggesting this variant was developed slightly later with a larger precision allowance.

Data flow: Same target table as AddAccountStatus. `Hedge.DelAccountStatus` manages the 30-day rolling retention on both writers' data. See `Hedge.AccountStatus` table documentation for full field semantics.

---

## 2. Business Logic

### 2.1 No Provider-Type Adjustment (Direct Insert)

**What**: Unlike AddAccountStatus, no provider-type lookup is performed. @Balance is stored as-is.

**Columns/Parameters Involved**: `@Balance`, `@NetPL`, `@Equity`

**Rules**:
- No SELECT from Trade.LiquidityAccounts or Trade.LiquidityProviders
- `@Balance` is inserted directly without modification
- Caller is responsible for passing the normalized balance value
- HedgeServerID is part of the composite PK in AccountStatus (same as AddAccountStatus)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | Integer | NO | - | CODE-BACKED | Hedge server that polled this account. Part of Hedge.AccountStatus composite PK. FK to Trade.HedgeServer. |
| 2 | @LiquidityAccountID | Integer | NO | - | CODE-BACKED | Liquidity provider account being snapshotted. FK to Trade.LiquidityAccounts. No provider-type lookup performed (contrast with AddAccountStatus). |
| 3 | @OccurredAtAccount | Datetime | NO | - | CODE-BACKED | LP's own clock timestamp when this snapshot was captured. Part of composite PK. |
| 4 | @Balance | Decimal(18,4) | NO | - | CODE-BACKED | Cash balance stored as-is - no adjustment applied. Wider precision than AddAccountStatus (18 vs 16). Caller must supply the normalized balance. |
| 5 | @NetPL | Decimal(18,4) | NO | - | VERIFIED | Unrealized (floating) P&L on open hedge positions. Wider precision (18,4) than AddAccountStatus. Per Confluence "Production Data comparison 31/01/21": represents unrealized P&L. |
| 6 | @Equity | Decimal(18,4) | NO | - | CODE-BACKED | Account equity = Balance + UnrealizedPL. Wider precision (18,4). |
| 7 | @UsedMargin | Decimal(16,4) | NO | - | CODE-BACKED | Margin currently in use by open positions. |
| 8 | @UsableMargin | Decimal(16,4) | NO | - | CODE-BACKED | Free margin available to open new positions. |
| 9 | @MaintenanceMargin | Decimal(16,4) | NO | - | CODE-BACKED | Minimum margin required to keep current positions open. |
| 10 | @CurrentLeverage | Decimal(16,4) | NO | - | CODE-BACKED | Current leverage ratio of the account. |
| 11 | @Cushion | Decimal(16,4) | NO | - | CODE-BACKED | Buffer between current equity and maintenance margin (cushion = free margin / equity). |
| 12 | @GrossPositionsValue | Decimal(16,4) | NO | - | CODE-BACKED | Total notional value of all open hedge positions in account currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (writes to) | Hedge.AccountStatus | INSERT | Same target as Hedge.AddAccountStatus |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called externally by the hedge server monitoring pipeline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddHedgeAccountStatus (procedure)
└── Hedge.AccountStatus (table) - INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountStatus | Table | INSERT target for the financial snapshot |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountStatus | Table | Written by this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- `SET NOCOUNT ON` - suppresses row count messages
- No TRY/CATCH
- Key difference vs AddAccountStatus: no Trade.LiquidityAccounts/LiquidityProviders join; no conditional balance adjustment

---

## 8. Sample Queries

### 8.1 Execute: Insert AccountStatus snapshot (no adjustment)

```sql
EXEC Hedge.AddHedgeAccountStatus
    @HedgeServerID      = 1,
    @LiquidityAccountID = 101,
    @OccurredAtAccount  = '2026-03-19 10:00:00',
    @Balance            = 100000.00,
    @NetPL              = 250.75,
    @Equity             = 100250.75,
    @UsedMargin         = 5000.00,
    @UsableMargin       = 95000.00,
    @MaintenanceMargin  = 2000.00,
    @CurrentLeverage    = 0.05,
    @Cushion            = 0.95,
    @GrossPositionsValue = 500000.00
```

### 8.2 Compare: Which accounts use AddAccountStatus vs AddHedgeAccountStatus

```sql
-- Both write to Hedge.AccountStatus - data is mixed in the same table
SELECT TOP 10
    HedgeServerID, LiquidityAccountID, OccurredAt, Balance, NetPL
FROM Hedge.AccountStatus WITH (NOLOCK)
WHERE HedgeServerID = 1
ORDER BY OccurredAt DESC
```

### 8.3 Check precision difference: rows with balance > 9999999999999999

```sql
-- Rows with Balance needing the wider decimal(18,4) precision
SELECT COUNT(*) AS WiderPrecisionRows
FROM Hedge.AccountStatus WITH (NOLOCK)
WHERE ABS(Balance) > 9999999999999999
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Production Data comparison 31/01/21 (referenced in Hedge.AccountStatus doc) | Confluence | NetPL represents unrealized P&L (floating P&L on open positions) |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.2/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddHedgeAccountStatus | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddHedgeAccountStatus.sql*
