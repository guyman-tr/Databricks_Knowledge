# Price.SpotInstrumentMapping

> Configuration table for futures contract roll-over logic that maps each spot instrument to its corresponding futures liquidity accounts and the first and second next contract instruments, enabling the pricing engine to swap pricing from expiring to upcoming futures contracts.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, SpotLiquidityAccountID) - composite CLUSTERED PK |
| **Partition** | Yes - MAIN partition scheme |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

SpotInstrumentMapping supports the futures contract roll process. When a futures contract approaches expiry, the pricing engine needs to seamlessly transition price sourcing from the expiring front-month contract to the next-nearest contract. This table provides the mapping needed for that transition:

- **SpotLiquidityAccountID**: The liquidity account providing spot (current front-month) prices
- **FutureLiquidityAccountID**: The liquidity account providing futures/next-month prices
- **FirstNextInstrumentId**: The first near-month contract that will become the active front-month
- **SecondNextInstrumentId**: The second upcoming contract (for additional rollover chain support)

The `Price.SwapContracts` stored procedure uses this table to orchestrate the actual contract swap: it looks up the spot mapping for the given instrument and liquidity account, then uses the `FirstNextInstrumentId`/`SecondNextInstrumentId` to identify the next valid contract from `Price.FuturesContracts` and update `Trade.LiquidityProviderContracts`.

The table is currently empty (0 rows) but has temporal versioning and the full ASM no-op trigger - it was provisioned for live use. The composite PK `(InstrumentID, SpotLiquidityAccountID)` allows the same spot instrument to have different mappings per liquidity account (different providers may roll contracts on different schedules).

---

## 2. Business Logic

### 2.1 Futures Contract Roll Mapping

**What**: For each spot instrument + spot liquidity account combination, defines which futures accounts and instruments handle the next two contract months.

**Columns/Parameters Involved**: `InstrumentID`, `SpotLiquidityAccountID`, `FutureLiquidityAccountID`, `FirstNextInstrumentId`, `SecondNextInstrumentId`

**Rules**:
- Composite PK (InstrumentID, SpotLiquidityAccountID) - one futures mapping per (instrument, spot account) pair
- FutureLiquidityAccountID FK -> Trade.LiquidityAccounts; SpotLiquidityAccountID FK -> Trade.LiquidityAccounts
- FirstNextInstrumentId and SecondNextInstrumentId are NOT FK-constrained - they reference other instrument IDs in Trade.Instrument but no DB-level enforcement
- `Price.SwapContracts` uses `SELECT TOP 1 ... WHERE InstrumentID=@InstrumentID AND FutureLiquidityAccountID=@LiquidityAccountID` to retrieve the mapping

### 2.2 Contract Swap Procedure (SwapContracts)

**What**: `Price.SwapContracts` reads this table to execute a futures contract rollover.

**Columns/Parameters Involved**: `InstrumentID`, `FutureLiquidityAccountID`, `FirstNextInstrumentId`, `SecondNextInstrumentId`

**Rules**:
- Only executes if unexpired futures contracts exist (checks Price.FuturesContracts WHERE Expired=0)
- Reads FirstNextInstrumentId and SecondNextInstrumentId to find the new front-month contract
- Updates Trade.LiquidityProviderContracts to point to the newly active contract ticker
- Outputs @IsNotExpiredExist to indicate whether the swap could proceed

---

## 3. Data Overview

The table is currently empty (0 rows). No spot-to-futures mappings are configured.

*When populated, rows would appear as:*

| InstrumentID | SpotLiquidityAccountID | FutureLiquidityAccountID | FirstNextInstrumentId | SecondNextInstrumentId | Meaning |
|---|---|---|---|---|---|
| 1005 (WTI Crude) | 21 (FD spot) | 22 (FD futures) | 1050 (WTI Mar) | 1051 (WTI Apr) | When WTI Feb expires, roll pricing to Mar contract (FD provider) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. FK to Trade.Instrument. The spot instrument (front-month) for which this roll mapping applies. (Trade.Instrument) |
| 2 | SpotLiquidityAccountID | int | NOT NULL | - | VERIFIED | Part 2 of composite PK. FK to Trade.LiquidityAccounts. The liquidity account currently providing spot/front-month prices. Different providers may have different roll schedules for the same instrument. (Trade.LiquidityAccounts) |
| 3 | FutureLiquidityAccountID | int | NOT NULL | - | VERIFIED | FK to Trade.LiquidityAccounts. The liquidity account providing futures prices used for the roll destination. Used by SwapContracts to look up the correct mapping via FutureLiquidityAccountID=@LiquidityAccountID filter. (Trade.LiquidityAccounts) |
| 4 | FirstNextInstrumentId | int | NOT NULL | - | VERIFIED | The instrument ID of the first upcoming contract (nearest expiry after current). After a roll, this becomes the new front-month instrument. No FK constraint in DDL. |
| 5 | SecondNextInstrumentId | int | NOT NULL | - | VERIFIED | The instrument ID of the second upcoming contract (one month beyond FirstNextInstrumentId). Supports double-roll scenarios. No FK constraint in DDL. |
| 6 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. |
| 7 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). |
| 8 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. |
| 9 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Historical versions in History.SpotInstrumentMapping. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_SpotInstrumentMapping_InstrumentID) | The spot instrument being configured for roll |
| SpotLiquidityAccountID | Trade.LiquidityAccounts | FK (FK_SpotInstrumentMapping_SpotAccountId) | The spot price liquidity account |
| FutureLiquidityAccountID | Trade.LiquidityAccounts | FK (FK_SpotInstrumentMapping_AccountId) | The futures price liquidity account |
| FirstNextInstrumentId | Trade.Instrument | Logical (no FK) | The first upcoming contract instrument |
| SecondNextInstrumentId | Trade.Instrument | Logical (no FK) | The second upcoming contract instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SwapContracts | InstrumentID, FutureLiquidityAccountID | READER | Looks up roll mapping to execute futures contract swap |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SpotInstrumentMapping (table)
|- Trade.Instrument (table, FK target - leaf)
|- Trade.LiquidityAccounts (table, FK target - leaf, x2: spot and future accounts)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target - InstrumentID must reference a valid instrument |
| Trade.LiquidityAccounts | Table | FK target (x2) - both spot and future liquidity account IDs must be valid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.SwapContracts | Stored Procedure | READER - reads this table to resolve futures contract roll chain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SpotInstrumentMapping | CLUSTERED PK | InstrumentID ASC, SpotLiquidityAccountID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SpotInstrumentMapping | PRIMARY KEY | One roll mapping per (instrument, spot account) pair |
| FK_SpotInstrumentMapping_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_SpotInstrumentMapping_SpotAccountId | FK | SpotLiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |
| FK_SpotInstrumentMapping_AccountId | FK | FutureLiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |
| DF_SpotInstrumentMapping_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_SpotInstrumentMapping_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.SpotInstrumentMapping |
| TRG_T_SpotInstrumentMapping | TRIGGER (INSERT) | ASM no-op: self-update on InstrumentID after insert |

---

## 8. Sample Queries

### 8.1 View all spot-to-futures roll mappings

```sql
SELECT
    SIM.InstrumentID,
    SIM.SpotLiquidityAccountID,
    LA1.LiquidityAccountName AS SpotAccountName,
    SIM.FutureLiquidityAccountID,
    LA2.LiquidityAccountName AS FutureAccountName,
    SIM.FirstNextInstrumentId,
    SIM.SecondNextInstrumentId
FROM Price.SpotInstrumentMapping SIM WITH (NOLOCK)
JOIN Trade.LiquidityAccounts LA1 WITH (NOLOCK)
    ON LA1.LiquidityAccountID = SIM.SpotLiquidityAccountID
JOIN Trade.LiquidityAccounts LA2 WITH (NOLOCK)
    ON LA2.LiquidityAccountID = SIM.FutureLiquidityAccountID
ORDER BY SIM.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 4, 5, 6, 7, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SpotInstrumentMapping | Type: Table | Source: etoro/etoro/Price/Tables/Price.SpotInstrumentMapping.sql*
