# Hedge.AddProviderAccountStatus

> Inserts a financial snapshot for a liquidity provider account into Hedge.ProviderAccountStatus - provider-centric variant that operates at account level without a HedgeServerID dimension.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.ProviderAccountStatus (no HedgeServerID parameter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddProviderAccountStatus` records a liquidity provider account's financial state directly at the account level, without tying it to a specific hedge server. It is the writer for `Hedge.ProviderAccountStatus` - a table that is not tracked in the SSDT Hedge schema project.

The key distinction from `Hedge.AddAccountStatus` and `Hedge.AddHedgeAccountStatus`:
- Those procedures write to `Hedge.AccountStatus` and include a `@HedgeServerID` parameter - they capture account state from a specific hedge server's perspective
- This procedure writes to `Hedge.ProviderAccountStatus` with NO `@HedgeServerID` - it captures the provider account's financial state independently of which hedge server polled it

This makes the table suitable for provider-level reporting and reconciliation that must be server-agnostic: when the same LP account is managed by multiple hedge servers, this view collapses to just the account's financial state.

No balance adjustment logic exists in this procedure (unlike `AddAccountStatus`) - balance is stored as-is.

---

## 2. Business Logic

### 2.1 Account-Level Snapshot Without Server Context

**What**: Stores the financial state of an LP account without associating it with a particular hedge server.

**Columns/Parameters Involved**: All parameters (note: no @HedgeServerID)

**Rules**:
- No @HedgeServerID parameter - target table key is based only on LiquidityAccountID + OccurredAtAccount
- No balance adjustment logic (no provider type lookup)
- Pure INSERT - no upsert or duplicate check

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityAccountID | Integer | NO | - | CODE-BACKED | Liquidity provider account being snapshotted. Key field in ProviderAccountStatus. FK to Trade.LiquidityAccounts. |
| 2 | @OccurredAtAccount | Datetime | NO | - | CODE-BACKED | LP's own clock timestamp for this snapshot. Used as part of the row's time key. |
| 3 | @Balance | Decimal(18,4) | NO | - | CODE-BACKED | Cash balance of the LP account, stored as-is (no adjustment). Wide precision (18,4). |
| 4 | @NetPL | Decimal(18,4) | NO | - | CODE-BACKED | Unrealized (floating) P&L on open hedge positions. Wide precision (18,4). |
| 5 | @Equity | Decimal(18,4) | NO | - | CODE-BACKED | Account equity = Balance + UnrealizedPL. Wide precision (18,4). |
| 6 | @UsedMargin | Decimal(16,4) | NO | - | CODE-BACKED | Margin currently in use by open positions. |
| 7 | @UsableMargin | Decimal(16,4) | NO | - | CODE-BACKED | Free margin available to open new positions. |
| 8 | @MaintenanceMargin | Decimal(16,4) | NO | - | CODE-BACKED | Minimum margin required to maintain current positions. |
| 9 | @CurrentLeverage | Decimal(16,4) | NO | - | CODE-BACKED | Current leverage ratio of the account. |
| 10 | @Cushion | Decimal(16,4) | NO | - | CODE-BACKED | Buffer between equity and maintenance margin. |
| 11 | @GrossPositionsValue | Decimal(16,4) | NO | - | CODE-BACKED | Total notional value of all open positions in account currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LiquidityAccountID | Trade.LiquidityAccounts | Implicit | LP account being snapshotted |
| (writes to) | Hedge.ProviderAccountStatus | INSERT | Target table (not in SSDT project) |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the hedge monitoring infrastructure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddProviderAccountStatus (procedure)
└── Hedge.ProviderAccountStatus (table - not in Hedge SSDT project)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ProviderAccountStatus | Table | INSERT target (not tracked in SSDT) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Hedge monitoring infrastructure) | External | Writes account-level snapshots |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`
- No TRY/CATCH, no transaction
- No balance adjustment (contrast with AddAccountStatus)

---

## 8. Sample Queries

### 8.1 Execute: Insert a provider account status snapshot

```sql
EXEC Hedge.AddProviderAccountStatus
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

### 8.2 Query: Recent provider account snapshots

```sql
SELECT TOP 20
    LiquidityAccountID,
    OccurredAtAccount,
    Balance,
    NetPL,
    Equity,
    CurrentLeverage
FROM Hedge.ProviderAccountStatus WITH (NOLOCK)
WHERE LiquidityAccountID = 101
ORDER BY OccurredAtAccount DESC
```

### 8.3 Compare: ProviderAccountStatus vs AccountStatus for the same account

```sql
-- Provider-level view (no server split)
SELECT 'ProviderAccountStatus' AS Source, OccurredAtAccount, Balance, NetPL
FROM Hedge.ProviderAccountStatus WITH (NOLOCK)
WHERE LiquidityAccountID = 101 AND OccurredAtAccount > DATEADD(HOUR,-1,GETUTCDATE())

UNION ALL

-- Server-level view (split by HedgeServerID)
SELECT 'AccountStatus - Server ' + CAST(HedgeServerID AS VARCHAR), OccurredAtAccount, Balance, NetPL
FROM Hedge.AccountStatus WITH (NOLOCK)
WHERE LiquidityAccountID = 101 AND OccurredAt > DATEADD(HOUR,-1,GETUTCDATE())
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 9.2/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddProviderAccountStatus | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddProviderAccountStatus.sql*
