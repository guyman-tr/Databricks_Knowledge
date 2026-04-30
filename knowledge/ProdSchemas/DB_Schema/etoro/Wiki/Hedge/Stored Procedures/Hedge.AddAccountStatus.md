# Hedge.AddAccountStatus

> Inserts a financial snapshot of a liquidity provider account into Hedge.AccountStatus, applying provider-specific balance recalculation for FD and IB provider types before persisting.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.AccountStatus; reads Trade.LiquidityAccounts + Trade.LiquidityProviders |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddAccountStatus` is the primary writer for the `Hedge.AccountStatus` table. Each invocation records a point-in-time financial snapshot of a liquidity provider account: its cash balance, unrealized P&L, equity, margin utilization, leverage, and gross position value at a given moment. This snapshot is used for account health monitoring, hedge cost reporting, and reconciliation.

What distinguishes this procedure from its sibling `Hedge.AddHedgeAccountStatus` is provider-type awareness: before inserting, it looks up the `LiquidityProviderTypeID` for the account and recalculates `@Balance` if the provider reports balance in a non-standard way. FD providers (type 3) report balance as the sum of used margin, usable margin, minus net P&L. IB (Interactive Brokers, type 11) reports balance as equity minus net P&L.

Data flows: the hedge server's monitoring loop polls each liquidity account's financial state, then calls this procedure. `Hedge.DelAccountStatus` enforces a 30-day rolling retention window. `Hedge.GetCurrentAccountStatus` reads the most recent row. Per Confluence ("Production Data comparison 31/01/21"), `NetPL` stores **unrealized P&L** (floating P&L on open positions), not realized.

---

## 2. Business Logic

### 2.1 Provider-Specific Balance Recalculation

**What**: Two liquidity provider types require balance to be recalculated before storage because they report balance differently from the standard (cash-in-account) definition.

**Columns/Parameters Involved**: `@Balance`, `@UsedMargin`, `@UsableMargin`, `@NetPL`, `@Equity`, `@LiquidityAccountID`

**Rules**:
- Lookup: `LiquidityProviderTypeID` from Trade.LiquidityAccounts JOIN Trade.LiquidityProviders ON LiquidityProviderID
- If `LiquidityProviderTypeID = 3` (FD provider): `@Balance = @UsedMargin + @UsableMargin - @NetPL`
- If `LiquidityProviderTypeID = 11` (IB - Interactive Brokers): `@Balance = @Equity - @NetPL`
- All other providers: `@Balance` is stored as-received from the hedge server
- This normalization ensures that `AccountStatus.Balance` always represents cash balance regardless of how the LP reports it

**Diagram**:
```
Input @LiquidityAccountID
      |
      v
Lookup LiquidityProviderTypeID via Trade.LiquidityAccounts + Trade.LiquidityProviders
      |
      +--TypeID = 3 (FD)-->  @Balance = @UsedMargin + @UsableMargin - @NetPL
      |
      +--TypeID = 11 (IB)--> @Balance = @Equity - @NetPL
      |
      +--Other------------>  @Balance unchanged
      |
      v
INSERT INTO Hedge.AccountStatus
```

### 2.2 Snapshot Storage (No Deduplication)

**What**: Each call creates a new row - no upsert or duplicate check.

**Columns/Parameters Involved**: Composite PK (OccurredAtAccount, HedgeServerID, LiquidityAccountID)

**Rules**:
- OccurredAtAccount is the LP's own clock timestamp (provided by caller)
- OccurredAt (auto-stamped by table DEFAULT GETUTCDATE()) records DB server receipt time
- If the same (HedgeServerID, LiquidityAccountID, OccurredAtAccount) is inserted twice, a PK violation will occur - the caller is responsible for deduplication

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | Integer | NO | - | CODE-BACKED | Hedge server instance that polled this account. Part of the AccountStatus composite PK. FK to Trade.HedgeServer. |
| 2 | @LiquidityAccountID | Integer | NO | - | CODE-BACKED | Liquidity provider account being snapshotted. Used to look up LiquidityProviderTypeID for balance adjustment. FK to Trade.LiquidityAccounts. |
| 3 | @OccurredAtAccount | Datetime | NO | - | CODE-BACKED | Timestamp from the liquidity provider's own clock when this snapshot was captured. Distinct from OccurredAt (DB server time). Part of composite PK. |
| 4 | @Balance | Decimal(16,4) | NO | - | VERIFIED | Cash balance of the LP account in account currency. Recalculated before storage for FD (type 3) and IB (type 11) providers. See Business Logic 2.1 for adjustment formulas. |
| 5 | @NetPL | Decimal(16,4) | NO | - | VERIFIED | Unrealized (floating) P&L on all currently open hedge positions, in account currency. Per Confluence "Production Data comparison 31/01/21", this is unrealized P&L. Used in Balance recalculation for FD and IB providers. |
| 6 | @Equity | Decimal(16,4) | NO | - | CODE-BACKED | Account equity = Balance + UnrealizedPL. Used in Balance recalculation for IB (type 11) providers: @Balance = @Equity - @NetPL. |
| 7 | @UsedMargin | Decimal(16,4) | NO | - | CODE-BACKED | Margin currently in use by open positions. Used in Balance recalculation for FD (type 3) providers. |
| 8 | @UsableMargin | Decimal(16,4) | NO | - | CODE-BACKED | Free margin available to open new positions. Used in Balance recalculation for FD (type 3) providers. |
| 9 | @MaintenanceMargin | Decimal(16,4) | NO | - | CODE-BACKED | Minimum margin required to keep current positions open. Below this level triggers margin call. |
| 10 | @CurrentLeverage | Decimal(16,4) | NO | - | CODE-BACKED | Current leverage ratio of the account (total exposure / equity). Monitoring threshold for over-leveraged accounts. |
| 11 | @Cushion | Decimal(16,4) | NO | - | CODE-BACKED | Buffer between current equity and maintenance margin. Cushion = UsableMargin / Equity. Low cushion indicates margin call risk. |
| 12 | @GrossPositionsValue | Decimal(16,4) | NO | - | CODE-BACKED | Total notional value of all open hedge positions in account currency, before netting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LiquidityAccountID | Trade.LiquidityAccounts | Lookup | Reads LiquidityProviderID to join to LiquidityProviders |
| (via LiquidityProviderID) | Trade.LiquidityProviders | Lookup | Reads LiquidityProviderTypeID to determine balance adjustment logic |
| (writes to) | Hedge.AccountStatus | INSERT | Target table for financial snapshots |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the hedge server monitoring loop.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddAccountStatus (procedure)
├── Trade.LiquidityAccounts (table) - provider type lookup
├── Trade.LiquidityProviders (table) - provider type lookup
└── Hedge.AccountStatus (table) - INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | JOIN to find LiquidityProviderID for the account |
| Trade.LiquidityProviders | Table | JOIN to find LiquidityProviderTypeID (3=FD, 11=IB) |
| Hedge.AccountStatus | Table | INSERT target for the financial snapshot |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountStatus | Table | Written by this procedure (writer) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- `SET NOCOUNT ON` - suppresses row count messages
- No TRY/CATCH - exceptions propagate to caller
- Balance adjustment is conditional on LiquidityProviderTypeID; if lookup returns NULL (account not found), no adjustment is applied

---

## 8. Sample Queries

### 8.1 Execute: Insert an AccountStatus snapshot (standard provider)

```sql
EXEC Hedge.AddAccountStatus
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

### 8.2 Verify: Check the balance adjustment logic for a given account

```sql
SELECT
    TLA.LiquidityAccountID,
    TLP.LiquidityProviderTypeID,
    CASE TLP.LiquidityProviderTypeID
        WHEN 3  THEN 'FD: Balance = UsedMargin + UsableMargin - NetPL'
        WHEN 11 THEN 'IB: Balance = Equity - NetPL'
        ELSE         'Standard: Balance as reported'
    END AS BalanceAdjustmentRule
FROM Trade.LiquidityAccounts TLA WITH (NOLOCK)
JOIN Trade.LiquidityProviders TLP WITH (NOLOCK) ON TLA.LiquidityProviderID = TLP.LiquidityProviderID
WHERE TLA.LiquidityAccountID = 101
```

### 8.3 Query: Recent AccountStatus snapshots for a hedge server

```sql
SELECT TOP 20
    HedgeServerID,
    LiquidityAccountID,
    OccurredAt,
    Balance,
    NetPL,
    Equity,
    CurrentLeverage,
    Cushion
FROM Hedge.AccountStatus WITH (NOLOCK)
WHERE HedgeServerID = 1
ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Production Data comparison 31/01/21 (referenced in Hedge.AccountStatus doc) | Confluence | NetPL in AccountStatus represents unrealized P&L (floating P&L on open positions, not realized) |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9.2/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddAccountStatus | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddAccountStatus.sql*
