# Price.FuturesContracts

> Registry of available futures contract delivery dates per instrument per liquidity account, storing the upcoming front-month and back-month contract windows with their exchange tickers and expiry status - consumed by Price.SwapContracts to execute futures contract rolls when the front-month expires.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID + LiquidityAccountID + FromDate (CLUSTERED composite PK) |
| **Partition** | No (ON [MAIN] filegroup) |
| **Indexes** | 1 (PK clustered, FILLFACTOR=90, ON [MAIN]) |

---

## 1. Business Meaning

Price.FuturesContracts is the futures contract schedule for eToro's futures-based instruments. Futures instruments (indices, commodities, certain forex) do not trade on a single continuous basis - they trade through sequential delivery contracts, each expiring on a specific date. As the front-month contract approaches expiry, the pricing engine must "roll" to the next contract - switching to the next available delivery window.

This table maintains the upcoming contract windows available for each instrument+liquidity account combination. Each row represents one available contract:
- Its active date window (FromDate to ToDate)
- The exchange-specific ticker for that contract (e.g., "ESZ24" for S&P 500 December 2024)
- Whether it has been consumed/expired (Expired=1)

The `Price.SwapContracts` stored procedure reads this table to execute a contract roll:
1. Checks if any unexpired contracts exist
2. Finds the nearest unexpired contract
3. Updates Trade.LiquidityProviderContracts to point to the next/second-next contracts
4. Marks the consumed contract as Expired=1

Data lifecycle: rows are inserted by pricing operations when new contract windows are published. Rows are never deleted - expired contracts are soft-deleted via the Expired flag, preserving audit history.

The table uses the [MAIN] filegroup (not [PRIMARY]), indicating it is part of the primary operational data partition.

---

## 2. Business Logic

### 2.1 Contract Roll Mechanism

**What**: When a futures contract expires, Price.SwapContracts reads the next available unexpired contract and updates the live pricing configuration accordingly.

**Columns/Parameters Involved**: `InstrumentID`, `LiquidityAccountID`, `FromDate`, `ToDate`, `Ticker`, `Expired`

**Rules**:
- Expired=0: contract is available for rolling into
- Expired=1: contract has been consumed (promoted to live) or has passed its delivery date
- SwapContracts selects TOP 1 unexpired contract ordered by FromDate ASC = "nearest future"
- After a roll: the consumed contract's Expired is set to 1
- The "first next" instrument in Price.SpotInstrumentMapping is updated with "second next" values
- The "second next" is updated with the newly-found nearest future from this table
- Multiple rows per InstrumentID+LiquidityAccountID: one per upcoming contract window

**Diagram**:
```
Futures Contract Schedule for InstrumentID=X, LiquidityAccountID=Y:
  (Expired=1) FromDate=Sep 1, ToDate=Sep 19 - EXPIRED (consumed, now live)
  (Expired=0) FromDate=Sep 20, ToDate=Dec 19 -> "First Next" contract (nearest)
  (Expired=0) FromDate=Dec 20, ToDate=Mar 19 -> "Second Next" contract

Contract Roll (Price.SwapContracts):
  1. Check: any Expired=0 rows exist? YES
  2. Get nearest future: Sep 20-Dec 19 row (lowest FromDate, Expired=0)
  3. Update Trade.LiquidityProviderContracts:
     - FirstNext instrument <- SecondNext values (Dec 20-Mar 19)
     - SecondNext instrument <- nearest future values (Sep 20-Dec 19)
  4. Mark Sep 20-Dec 19 as Expired=1
```

---

## 3. Data Overview

| Note | Value |
|------|-------|
| Row count (this environment) | 0 (read replica / pre-population state) |
| Soft-delete pattern | Expired=1 flags consumed contracts; no physical DELETE |
| One row per contract window | Yes - (InstrumentID, LiquidityAccountID, FromDate) is unique |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. Part of the composite PK. FK to Trade.Instrument. Identifies which futures-based instrument this contract window belongs to. |
| 2 | LiquidityAccountID | int | NOT NULL | - | CODE-BACKED | Liquidity account providing this futures contract. Part of the composite PK. FK to Trade.LiquidityAccounts. Allows per-liquidity-account contract schedules for the same instrument (different providers may use different contract windows). |
| 3 | FromDate | datetime2(7) | NOT NULL | - | CODE-BACKED | Start date of this futures contract delivery window. Part of the composite PK. Used to order available contracts - the roll selects the contract with the lowest FromDate among Expired=0 rows. |
| 4 | ToDate | datetime2(7) | NOT NULL | - | CODE-BACKED | End date (expiry date) of this futures contract delivery window. When this date is reached, the contract must be rolled. Used by SwapContracts to populate Trade.LiquidityProviderContracts.ToDate after a roll. |
| 5 | Ticker | varchar(50) | NOT NULL | - | CODE-BACKED | Exchange-specific ticker symbol for this contract (e.g., "ESZ24" for S&P 500 Dec 2024 front month). Used by SwapContracts to update Trade.LiquidityProviderContracts.Ticker after rolling to this contract. The liquidity provider uses this ticker to subscribe to the correct contract feed. |
| 6 | Expired | bit | NOT NULL | - | CODE-BACKED | Contract status: 0=available for rolling into, 1=already consumed or expired. SwapContracts marks the rolled-in contract as Expired=1. Enables soft-delete: expired contracts remain for audit history without being removed. Audited by ASM triggers (only column tracked in audit). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_FuturesContracts_InstrumentID) | Contract schedule is for an existing instrument |
| LiquidityAccountID | Trade.LiquidityAccounts | FK (FK_FuturesContracts_AccountId) | Contract is provided by an existing liquidity account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SwapContracts | Price.FuturesContracts | READER/UPDATER | Reads nearest unexpired contract; sets Expired=1 after roll |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.FuturesContracts (table)
  |-- FK -> Trade.Instrument
  |-- FK -> Trade.LiquidityAccounts
  ^-- Used by: Price.SwapContracts (contract roll procedure)
  ^-- Related: Price.SpotInstrumentMapping (maps spot to first/second next futures instruments)
  ^-- Output: Trade.LiquidityProviderContracts (Ticker, FromDate, ToDate updated after roll)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK - instrument must exist |
| Trade.LiquidityAccounts | Table | FK - liquidity account must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.SwapContracts | Stored Procedure | Reads next unexpired contract for roll; sets Expired=1 on consumed contract |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FutureContracts | CLUSTERED PK | InstrumentID ASC, LiquidityAccountID ASC, FromDate ASC | - | - | Active, FILLFACTOR=90, ON [MAIN] |

*Note: The constraint name uses "FutureContracts" (singular) while the table is named "FuturesContracts" (plural) - original DDL typo.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_FuturesContracts_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_FuturesContracts_AccountId | FK | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |
| AuditDelete_Price_FuturesContracts | TRIGGER (DELETE) | Logs Expired old value; PK_Value = 'InstrumentID,LiquidityAccountID,FromDate' |
| AuditInsert_Price_FuturesContracts | TRIGGER (INSERT) | Logs Expired new value |
| AuditUpdate_Price_FuturesContracts | TRIGGER (UPDATE) | Logs old/new Expired when changed |

---

## 8. Sample Queries

### 8.1 View all available (unexpired) contracts per instrument

```sql
SELECT InstrumentID, LiquidityAccountID, FromDate, ToDate, Ticker, Expired
FROM Price.FuturesContracts WITH (NOLOCK)
WHERE Expired = 0
ORDER BY InstrumentID, LiquidityAccountID, FromDate;
```

### 8.2 Find next contract to roll for a specific instrument

```sql
SELECT TOP 1 InstrumentID, LiquidityAccountID, FromDate, ToDate, Ticker
FROM Price.FuturesContracts WITH (NOLOCK)
WHERE InstrumentID = 1
  AND LiquidityAccountID = 100
  AND Expired = 0
ORDER BY FromDate ASC;
```

### 8.3 Recent contract roll audit history

```sql
SELECT AuditDate, UserName, AppName, ColumnName, OldValue, NewValue, PK_Value
FROM History.AuditHistory WITH (NOLOCK)
WHERE TableName = 'FuturesContracts'
  AND Operation = 'U'
ORDER BY AuditDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.FuturesContracts | Type: Table | Source: etoro/etoro/Price/Tables/Price.FuturesContracts.sql*
