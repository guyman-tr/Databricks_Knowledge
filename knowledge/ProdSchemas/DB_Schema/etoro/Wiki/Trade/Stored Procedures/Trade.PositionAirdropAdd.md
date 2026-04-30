# Trade.PositionAirdropAdd

> Bulk-inserts airdrop position records into the legacy airdrop log, returning the inserted rows with their generated IDs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT: AirdropID (generated on INSERT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionAirdropAdd is the write entry-point for logging airdrop operations for US brokerage customers (APEX/Broker Dealer). An airdrop in this context is an administrative credit of a position - e.g., a stock dividend received as shares, a corporate action allocation, or a compensation grant - where a customer receives a position without placing a trade. Each row in the TVP parameter represents one customer's airdrop to log and persist.

The procedure was created in August 2021 for the APEX US General Availability (GA) launch (Jira TRADCD-753 / PROD-187: APEX US Corporate Actions). It covers the scenario where Trading Ops initiates a bulk airdrop event affecting many customers simultaneously - the caller assembles all affected records into the Trade.PositionAirdropTbl TVP and passes it in a single call.

The procedure uses an OUTPUT clause to return all inserted rows immediately - including the database-generated AirdropID - so the caller can associate each airdrop record with its persistence key without a subsequent SELECT. Architecturally, this SP targets Trade.PositionAirdropLog, which has since been replaced as a table by Trade.AdminPositionLog (with PositionAirdropLog becoming a backward-compatibility view). Newer airdrop flows use the AdminPositionLog path directly; this SP represents the original airdrop logging mechanism.

---

## 2. Business Logic

### 2.1 Bulk Airdrop Logging with OUTPUT

**What**: A single procedure call persists an entire batch of airdrop records and returns their identities.

**Columns/Parameters Involved**: `@positionAirdropTbl`, `@userName`, OUTPUT columns

**Rules**:
- All rows in @positionAirdropTbl are inserted atomically in a single INSERT...SELECT statement.
- @userName is applied uniformly to all inserted rows (the operator who initiated the airdrop batch), overriding any UserName in the TVP.
- The OUTPUT clause returns the inserted rows immediately, including database-generated AirdropID values, so the caller does not need a follow-up SELECT.
- TerminalID is sourced per-row from the TVP (each row can have a different terminal source).

**Diagram**:
```
Caller (Trading Ops tool)
  |
  +--> DECLARE @batch Trade.PositionAirdropTbl
  |    INSERT @batch (CID, InstrumentID, Amount, ...)  -- one row per customer
  |
  +--> EXEC Trade.PositionAirdropAdd @batch, @userName='ops-user'
            |
            +--> INSERT INTO Trade.PositionAirdropLog (...)
                 OUTPUT inserted.AirdropID, inserted.CID, ...
                 SELECT CID, InstrumentID, ..., @userName, ...
                 FROM @positionAirdropTbl
            |
            <-- Result set: one row per inserted record with AirdropID
```

### 2.2 Architectural Migration Note

**What**: This SP targets Trade.PositionAirdropLog, which transitioned from a table to a backward-compatibility view.

**Columns/Parameters Involved**: Target object Trade.PositionAirdropLog

**Rules**:
- Originally, Trade.PositionAirdropLog was a physical table; this SP inserted into it directly.
- The table was renamed to Trade.PositionAirdropLogOldD_DoNotdelete when the airdrop feature evolved into the AdminPositionLog pattern (per "OpenPosition formerly AirDrop" Confluence doc).
- Trade.PositionAirdropLog is now a UNION ALL view over both old and new tables.
- INSERT into a UNION ALL view requires an INSTEAD OF trigger; if no trigger exists, this SP is effectively superseded by the newer AdminPositionLog-based flow.
- The SP remains in the SSDT repo for historical reference and potential legacy tooling compatibility.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @positionAirdropTbl | Trade.PositionAirdropTbl | NO | - | CODE-BACKED | Input TVP (READONLY). Batch of airdrop records to insert. Each row is one customer airdrop event with CID, InstrumentID, amounts, hedge server, rate, and terminal. See Trade.PositionAirdropTbl for full column definitions. |
| 2 | @userName | VARCHAR(100) | NO | - | CODE-BACKED | Operator name applied to all inserted rows as the UserName column. Identifies which Trading Ops user or automated job initiated the airdrop batch. |

**OUTPUT columns returned (result set):**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | AirdropID | (per target table PK) | NO | CODE-BACKED | Database-generated identifier for the inserted airdrop record. Returned immediately via OUTPUT clause so callers can associate each TVP row with its persisted ID. |
| 2 | CID | int | NO | CODE-BACKED | Customer ID - echoed from inserted row. Identifies which customer received the airdrop. |
| 3 | InstrumentID | int | NO | CODE-BACKED | Instrument of the airdrop - echoed from inserted row. FK to Trade.Instrument. |
| 4 | Cusip | varchar | YES | CODE-BACKED | CUSIP identifier for US securities - echoed from inserted row. Relevant for stock dividends and corporate actions. |
| 5 | ApexID | varchar | YES | CODE-BACKED | Apex custodian reference ID - echoed from inserted row. Links the airdrop to the Apex brokerage account. |
| 6 | Amount | money | YES | CODE-BACKED | Dollar amount of the airdrop - echoed from inserted row. |
| 7 | AmountInUnits | decimal | YES | CODE-BACKED | Position size in shares or tokens - echoed from inserted row. |
| 8 | HedgeServerID | int | YES | CODE-BACKED | Hedge server where the position is held - echoed from inserted row. |
| 9 | Rate | decimal | YES | CODE-BACKED | Execution or reference rate for the airdrop - echoed from inserted row. |
| 10 | TerminalID | varchar | YES | CODE-BACKED | Terminal or system identifier for the airdrop source - echoed from inserted row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @positionAirdropTbl | Trade.PositionAirdropTbl | Parameter (TVP) | Input type defining the structure of airdrop rows to insert |
| INSERT target | Trade.PositionAirdropLog | DML write | The view (historically a table) where airdrop records are persisted |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in the SSDT repo. Called by external Trading Ops tooling (not in this repo).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionAirdropAdd (procedure)
├── Trade.PositionAirdropTbl (type) - TVP parameter type
└── Trade.PositionAirdropLog (view) - INSERT target
      ├── Trade.PositionAirdropLogOldD_DoNotdelete (table)
      └── Trade.AdminPositionLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionAirdropTbl | User Defined Type | READONLY TVP parameter - defines structure of input rows |
| Trade.PositionAirdropLog | View (formerly Table) | INSERT target for all airdrop records |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repo. Called by external Trading Ops tooling or ETL jobs not present in this repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Input validation is caller-responsibility. The procedure does not perform explicit parameter validation.

---

## 8. Sample Queries

### 8.1 Execute a single-customer airdrop

```sql
DECLARE @Airdrops Trade.PositionAirdropTbl;
INSERT INTO @Airdrops (CID, InstrumentID, Cusip, ApexID, Amount, AmountInUnits, HedgeServerID, Rate, TerminalID)
VALUES (12345678, 100, 'AAPL123456', 'APX-ACC-001', 50.00, 0.25, 1, 200.00, 'CORP-ACTION');

EXEC Trade.PositionAirdropAdd
    @positionAirdropTbl = @Airdrops,
    @userName = 'trading-ops-user';
```

### 8.2 Bulk airdrop from staging table

```sql
DECLARE @Airdrops Trade.PositionAirdropTbl;
INSERT INTO @Airdrops (CID, InstrumentID, Cusip, ApexID, Amount, AmountInUnits, HedgeServerID, Rate, TerminalID)
SELECT  s.CID, s.InstrumentID, s.Cusip, s.ApexID,
        s.Amount, s.AmountInUnits, s.HedgeServerID, s.Rate, 'DIVIDEND-EVENT'
FROM    #StagingDividendAirdrops s WITH (NOLOCK)
WHERE   s.EventID = @EventID;

EXEC Trade.PositionAirdropAdd
    @positionAirdropTbl = @Airdrops,
    @userName = @OperatorName;
```

### 8.3 Verify inserted airdrops via the log view

```sql
SELECT  al.AirdropID, al.CID, al.InstrumentID, al.Amount, al.AmountInUnits,
        al.RequestOccurred, al.Result, al.PositionID
FROM    Trade.PositionAirdropLog al WITH (NOLOCK)
WHERE   al.RequestOccurred >= DATEADD(hour, -1, GETDATE())
ORDER BY al.RequestOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [TRADCD-753: Airdrop tool adjustments for GA](https://etoro-jira.atlassian.net/browse/TRADCD-753) | Jira | SP created for APEX US GA launch; part of PROD-187 Corporate Actions must-haves |
| [OpenPosition (formerly AirDrop) - Trading Perspective - WIP](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/11681398792) | Confluence | Airdrop feature evolved into AdminPositionLog pattern; original table renamed to DoNotDelete |

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 1 Confluence + 1 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionAirdropAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionAirdropAdd.sql*
