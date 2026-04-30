# Trade.HedgeRequest

> Pending hedge execution requests. Queues open and close requests for hedges before they are executed at liquidity providers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | HedgeID, RequestType (composite CLUSTERED PK) |
| **Partition** | Yes - ON [MAIN] |
| **Indexes** | 5 active (PK + 4 NC) |

---

## 1. Business Meaning

Trade.HedgeRequest stores pending hedge operations that have been submitted but not yet fully executed by the hedge subsystem. Each row represents either an open request (RequestType=1) - "hedge this exposure at the liquidity provider" - or a close request (RequestType=2) - "close this hedge position". The hedge server processes these requests asynchronously; when an open is executed, Trade.HedgeOpen moves the request data into Trade.Hedge and deletes the RequestType=1 row. When a close is executed, Trade.HedgeClose deletes the RequestType=2 row after copying the hedge to History.Hedge.

This table exists because hedge execution is asynchronous. The trading engine needs to record that a hedge was requested (amount, instrument, direction, hedge server) before the external broker confirms execution. Without it, the system could not track in-flight hedge requests, reconcile with hedge servers, or recover from failures. Trade.GetHedgeRequest, Trade.HedgeExposureAndRequestQuery, and Trade.GetExposuresForAllHedgeServers all join to this table to expose pending requests alongside live hedge exposure.

Data flows: open requests are created by `Trade.HedgeOpenRequestAdd` (RequestType=1), close requests by `Trade.HedgeCloseRequestAdd` (RequestType=2). `Trade.HedgeOpen` reads RequestType=1, inserts into Trade.Hedge, then DELETEs the request. `Trade.HedgeClose` reads and DELETEs RequestType=2 after closing. `Trade.HedgeRequestRemove` and `Trade.HedgeRemove` delete rows for cleanup. HedgeID is allocated by Internal.GetHedgeID; the same HedgeID can have both RequestType=1 (open) and RequestType=2 (close) at different times.

---

## 2. Business Logic

### 2.1 RequestType: Open vs Close

**What**: RequestType distinguishes open requests (1) from close requests (2). Each HedgeID progresses: open request (1) -> executed -> live Trade.Hedge -> close request (2) -> executed -> History.Hedge.

**Columns/Parameters Involved**: `RequestType`, `HedgeID`

**Rules**:
- RequestType=1: Open request. HedgeOpenRequestAdd INSERTs. HedgeOpen reads WHERE RequestType=1, inserts into Trade.Hedge, then DELETE from HedgeRequest WHERE RequestType=1.
- RequestType=2: Close request. HedgeCloseRequestAdd INSERTs (after deleting any existing RequestType=2 for same HedgeID). HedgeClose reads, copies to History.Hedge, DELETEs.
- CHECK constraint THRQ_REQUESTTYPE enforces RequestType IN (1, 2).
- Same HedgeID can appear with RequestType=1 (pending open) or RequestType=2 (pending close), but not both simultaneously for the same hedge lifecycle stage.

**Diagram**:
```
HedgeOpenRequestAdd -> HedgeRequest (RequestType=1)
       |
       v
HedgeOpen -> Trade.Hedge (live) + DELETE HedgeRequest RequestType=1
       |
       v
HedgeCloseRequestAdd -> HedgeRequest (RequestType=2)
       |
       v
HedgeClose -> History.Hedge + DELETE HedgeRequest RequestType=2
```

### 2.2 HedgeID as Request Identifier

**What**: HedgeID is allocated once at open-request time and reused for the close request. It does not reference Trade.Hedge until the open is executed.

**Columns/Parameters Involved**: `HedgeID`

**Rules**:
- Internal.GetHedgeID allocates HedgeID in HedgeOpenRequestAdd before INSERT.
- HedgeID is the same for both open and close request rows - the close request references the hedge that was created from the open.
- HedgeOpen receives HedgeID as input and uses it for the Trade.Hedge INSERT.
- HedgeCloseRequestAdd looks up the hedge by HedgeID to build the close request.

---

## 3. Data Overview

| HedgeID | RequestType | InstrumentID | HedgeServerID | Amount | IsBuy | Occurred | Meaning |
|---------|-------------|--------------|---------------|--------|-------|----------|---------|
| 27164041 | 1 | 1 | 8 | 7.5 | 1 | 2014-03-19 | Open request for EUR/USD (Instrument 1), long, 7.5 units, hedge server 8. Pending execution at time of sample. |
| 26727436 | 1 | 15 | 11 | 25 | 0 | 2014-03-05 | Open request for Instrument 15, short, 25 units, hedge server 11. |
| 26653657 | 1 | 3 | 5 | 25 | 0 | 2014-02-28 | Open request for NZD/USD (3), short, 25 units. |
| 26651512 | 1 | 1 | 5 | 50 | 0 | 2014-02-28 | Open request for EUR/USD short, 50 units. Multiple requests same instrument/server show batching. |
| 26645613 | 1 | 1 | 5 | 125 | 1 | 2014-02-28 | Open request for EUR/USD long, 125 units. |

**Selection criteria for the 5 rows:**
- All RequestType=1 (open requests). Close requests (2) are typically short-lived and may not appear in sampled data.
- Mix of instruments (1, 3, 10, 15), hedge servers (5, 8, 11), directions (IsBuy 0/1).
- CurrencyID=0, ProviderID=1 common in sample. InitForexRate, LimitRate, StopRate NULL until execution.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeID | int | NO | - | CODE-BACKED | Primary key (part 1). Allocated by Internal.GetHedgeID in HedgeOpenRequestAdd. Identifies the hedge request; after execution becomes the HedgeID in Trade.Hedge. Same HedgeID used for close request (RequestType=2). |
| 2 | RequestType | int | NO | - | CODE-BACKED | Primary key (part 2). 1=Open request, 2=Close request. CHECK THRQ_REQUESTTYPE enforces (1, 2). HedgeOpen reads 1, HedgeClose reads 2. |
| 3 | CurrencyID | int | YES | - | CODE-BACKED | FK to Dictionary.Currency. Denomination currency for the hedge. HedgeOpenRequestAdd passes @CurrencyID; HedgeCloseRequestAdd copies from Trade.Hedge. NULL for some legacy rows. |
| 4 | ProviderID | int | YES | - | CODE-BACKED | FK part to Trade.ProviderToInstrument. Execution provider. Sourced from HedgeOpenRequestAdd. |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | FK part to Trade.ProviderToInstrument. Tradeable instrument. Instrument 1=EUR/USD, 3=NZD/USD, etc. |
| 6 | HedgeServerID | int | YES | - | CODE-BACKED | FK to Trade.HedgeServer. Which hedge server should process this request. Used for routing and exposure queries. |
| 7 | Leverage | int | YES | - | CODE-BACKED | Leverage multiple (e.g., 400). Passed from HedgeOpenRequestAdd; used when opening the hedge. |
| 8 | Amount | money | YES | - | CODE-BACKED | Hedge position size in currency. Open: requested amount. Close: amount being closed. |
| 9 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units. Provider-specific. Sample shows 10000, 20000, 50000 for different lot sizes. |
| 10 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count. 10 lots, 20 lots, etc. Used for broker execution. |
| 11 | NetProfit | money | YES | - | CODE-BACKED | P&L. NULL for open requests; populated on close when known. |
| 12 | InitForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Rate at open. NULL until hedge executed; HedgeOpen passes and Trade.Hedge stores. For close requests may hold original open rate. |
| 13 | InitDateTime | datetime | YES | - | CODE-BACKED | When the hedge was/will be opened. NULL until execution. |
| 14 | LimitRate | dbo.dtPrice | YES | - | CODE-BACKED | Take-profit rate. HedgeOpen passes; NULL in request until set. |
| 15 | StopRate | dbo.dtPrice | YES | - | CODE-BACKED | Stop-loss rate. HedgeOpen passes; NULL in request until set. |
| 16 | IsBuy | bit | YES | - | CODE-BACKED | 1=long (buy), 0=short (sell). Passed from HedgeOpenRequestAdd. Opposite of client position direction. |
| 17 | OrderID | varchar(50) | YES | - | CODE-BACKED | Broker order ID. Set by Trade.SetHedgeOrderID after broker assigns. NULL until order sent. |
| 18 | EndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Actual close rate. For close requests; populated when close executes. |
| 19 | RequestedEndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Requested close rate. For limit/stop closes. |
| 20 | EndDateTime | datetime | YES | - | CODE-BACKED | When the hedge was closed. NULL for open requests. |
| 21 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | When the request was submitted. Default THRQ_OCCURRED. Used for ordering and audit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | FK | Denomination currency. |
| ProviderID, InstrumentID | Trade.ProviderToInstrument | FK (implicit) | Instrument-provider config. |
| HedgeServerID | Trade.HedgeServer | FK | Hedge server for routing. |

HedgeRequest has no explicit FK constraints to ProviderToInstrument or HedgeServer; the relationship is implicit via procedure logic. HedgeID does not FK to Trade.Hedge - it is allocated before the hedge exists.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetHedgeRequest | FROM | View | Exposes pending requests with joined data. |
| Trade.HedgeOpen | FROM/DELETE | Reader/Deleter | Reads RequestType=1, DELETEs after insert to Hedge. |
| Trade.HedgeClose | FROM/DELETE | Reader/Deleter | Reads RequestType=2, DELETEs after close. |
| Trade.HedgeOpenRequestAdd | INSERT | Writer | Creates open requests. |
| Trade.HedgeCloseRequestAdd | INSERT/DELETE | Writer/Deleter | Creates close requests; deletes existing RequestType=2 before insert. |
| Trade.HedgeRequestRemove | DELETE | Deleter | Removes requests by HedgeID. |
| Trade.HedgeRemove | FROM/DELETE | Reader/Deleter | Deletes HedgeRequest for hedge cleanup. |
| Trade.SetHedgeOrderID | UPDATE | Modifier | Sets OrderID after broker assigns. |
| Trade.GetExposuresForAllHedgeServers | JOIN | Reader | Includes pending requests in exposure view. |
| Trade.HedgeExposureAndRequestQuery | JOIN | Reader | Combines hedge exposure with requests. |
| Trade.HedgeExposureWithNoRequests | FROM | Reader | Checks for requests when validating exposure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeRequest (table)
```

Tables have no code-level dependencies. HedgeRequest is a leaf table. Procedure logic references Trade.Hedge, Trade.HedgeServer, Trade.ProviderToInstrument, Dictionary.Currency - but these are FK/lookup relationships, not FROM/JOIN in the CREATE TABLE.

### 6.1 Objects This Depends On

No explicit FK targets in CREATE TABLE. Implicit dependencies via procedure usage: Trade.ProviderToInstrument (ProviderID, InstrumentID), Trade.HedgeServer (HedgeServerID), Dictionary.Currency (CurrencyID).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetHedgeRequest | View | FROM Trade.HedgeRequest |
| Trade.HedgeOpen | Procedure | SELECT, DELETE |
| Trade.HedgeClose | Procedure | SELECT, DELETE |
| Trade.HedgeOpenRequestAdd | Procedure | INSERT |
| Trade.HedgeCloseRequestAdd | Procedure | INSERT, DELETE |
| Trade.HedgeRequestRemove | Procedure | DELETE |
| Trade.HedgeRemove | Procedure | DELETE |
| Trade.SetHedgeOrderID | Procedure | UPDATE |
| Trade.GetExposuresForAllHedgeServers | View | JOIN |
| Trade.HedgeExposureAndRequestQuery | Procedure | Via GetHedgeRequest |
| Trade.HedgeExposureWithNoRequests | Procedure | Via GetHedgeRequest |
| Trade.HedgeRemoveAll | Procedure | SELECT HedgeID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_THRQ | CLUSTERED | HedgeID, RequestType | - | - | Active |
| THRQ_CURRENCY | NC | CurrencyID | - | - | Active |
| THRQ_HEDGESERVER | NC | HedgeServerID, RequestType, Occurred | InstrumentID | - | Active |
| THRQ_INSTRUMENT | NC | InstrumentID | - | - | Active |
| THRQ_PROVIDER | NC | ProviderID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_THRQ | PK | HedgeID, RequestType - composite primary key |
| THRQ_OCCURRED | DEFAULT | Occurred = getutcdate() |
| THRQ_REQUESTTYPE | CHECK | RequestType IN (1, 2) - open or close only |

---

## 8. Sample Queries

### 8.1 List pending open requests by hedge server
```sql
SELECT HedgeID, InstrumentID, HedgeServerID, Amount, IsBuy, Occurred
  FROM Trade.HedgeRequest HR WITH (NOLOCK)
 WHERE RequestType = 1
 ORDER BY HedgeServerID, Occurred
```

### 8.2 Resolve request to instrument and provider
```sql
SELECT HR.HedgeID, HR.RequestType, PTI.PresentationCode, HR.Amount, HR.IsBuy,
       THS.HedgeServerName, HR.Occurred
  FROM Trade.HedgeRequest HR WITH (NOLOCK)
  JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK)
    ON HR.ProviderID = PTI.ProviderID AND HR.InstrumentID = PTI.InstrumentID
  LEFT JOIN Trade.HedgeServer THS WITH (NOLOCK)
    ON HR.HedgeServerID = THS.HedgeServerID
 WHERE HR.RequestType = 1
 ORDER BY HR.Occurred DESC
```

### 8.3 Count requests by type and hedge server
```sql
SELECT RequestType, HedgeServerID, COUNT(*) AS RequestCount
  FROM Trade.HedgeRequest HR WITH (NOLOCK)
 GROUP BY RequestType, HedgeServerID
 ORDER BY RequestType, HedgeServerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.HedgeRequest | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.HedgeRequest.sql*
