# Trade.ManualPositionClose_Casing

> Thin wrapper that resolves the current Bid/Ask snapshot rates for a position's instrument and passes them to Trade.ManualPositionClose_Crisis to close the position at those captured rates.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID - the position to close |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ManualPositionClose_Casing is a convenience wrapper around Trade.ManualPositionClose_Crisis. Its sole purpose is to look up the current Bid and Ask prices from Trade.CurrencyPrice_SnapShot for the instrument associated with the target position, then pass those captured rates to ManualPositionClose_Crisis. This saves callers from having to resolve the snapshot rates themselves before invoking the crisis close.

The "Casing" name refers to the act of capturing ("casing") the current price snapshot rates at the moment the close is initiated, so that the crisis close executes at a specific known price rather than letting the crisis procedure calculate rates independently.

No callers were found in the Trade schema - this procedure is likely invoked directly by DBA operations, ad hoc scripts, or external tools that have a PositionID and OperationID but do not have the instrument's current prices available.

---

## 2. Business Logic

### 2.1 Rate Resolution from Snapshot

**What**: Fetches the Bid and Ask rates from the currency price snapshot for the position's instrument before delegating to ManualPositionClose_Crisis.

**Columns/Parameters Involved**: `@PositionID`, `Trade.CurrencyPrice_SnapShot.Bid`, `Trade.CurrencyPrice_SnapShot.Ask`

**Rules**:
- JOINs Trade.CurrencyPrice_SnapShot to Trade.PositionTbl ON InstrumentID, filtered by @PositionID.
- If no matching snapshot row exists (instrument not in CurrencyPrice_SnapShot), @BidSpread and @AskSpread remain NULL; ManualPositionClose_Crisis then falls back to its own rate resolution logic (FnGetCurrentClosingRate).
- The snapshot is read WITH (NOLOCK) - it captures the most recently written price without blocking.
- Delegates ALL close logic to Trade.ManualPositionClose_Crisis: tree traversal, markup calculation, History logging.

**Diagram**:
```
Caller -> ManualPositionClose_Casing(@PositionID, @OperationID)
              |
              v
          Trade.CurrencyPrice_SnapShot x Trade.PositionTbl
              -> @BidSpread = Bid, @AskSpread = Ask
              |
              v
          Trade.ManualPositionClose_Crisis(
              @PositionID, @BidSpread, @AskSpread, @OperationID
          )
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | ID of the position to close. Looked up in Trade.PositionTbl to find the InstrumentID, then passed directly to Trade.ManualPositionClose_Crisis. |
| 2 | @OperationID | INT | NO | - | CODE-BACKED | Operation identifier for audit logging. Passed through to Trade.ManualPositionClose_Crisis and written to History.ManualPositionClose_Crisis. Identifies the originating operation context (e.g., batch close, DBA script ID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID via InstrumentID | Trade.CurrencyPrice_SnapShot | JOIN/Read | Resolves current Bid/Ask rates for the position's instrument from the price snapshot table |
| @PositionID | Trade.PositionTbl | JOIN/Read | Looks up InstrumentID to JOIN with CurrencyPrice_SnapShot |
| @PositionID, @BidSpread, @AskSpread, @OperationID | Trade.ManualPositionClose_Crisis | EXEC | Full close logic delegated here with snapshot rates; handles tree traversal, history logging, and rate calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No callers found in Trade schema) | - | - | Invoked directly by DBA operations or external scripts; no SP callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ManualPositionClose_Casing (procedure)
├── Trade.CurrencyPrice_SnapShot (table)
├── Trade.PositionTbl (table)
└── Trade.ManualPositionClose_Crisis (procedure)
      ├── Trade.PositionTbl (table)
      ├── Trade.FnGetCurrentClosingRate (function)
      ├── Trade.FnIsRealPosition (function)
      ├── History.ManualPositionClose_Crisis (table)
      └── Trade.ManualPositionClose (procedure)
            └── ...
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice_SnapShot | Table | JOINed with NOLOCK to Trade.PositionTbl to read Bid and Ask for the position's instrument |
| Trade.PositionTbl | Table | JOINed to resolve InstrumentID from @PositionID |
| Trade.ManualPositionClose_Crisis | Procedure | EXECuted with resolved Bid/Ask rates and @OperationID; handles all close logic |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found) | - | No procedures call this wrapper; used directly by DBA tools. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. No transaction wrapping in this procedure - the transaction is managed inside Trade.ManualPositionClose_Crisis.

---

## 8. Sample Queries

### 8.1 Check current snapshot rates for a position's instrument before manual close

```sql
SELECT TCRP.InstrumentID, TCRP.Bid, TCRP.Ask, TISR.PositionID
FROM Trade.CurrencyPrice_SnapShot AS TCRP WITH (NOLOCK)
INNER JOIN Trade.PositionTbl AS TISR WITH (NOLOCK) ON TCRP.InstrumentID = TISR.InstrumentID
WHERE TISR.PositionID = <PositionID>;
```

### 8.2 Find positions whose instrument has no entry in CurrencyPrice_SnapShot

```sql
SELECT TISR.PositionID, TISR.InstrumentID, TISR.StatusID
FROM Trade.PositionTbl AS TISR WITH (NOLOCK)
LEFT JOIN Trade.CurrencyPrice_SnapShot AS TCRP WITH (NOLOCK) ON TCRP.InstrumentID = TISR.InstrumentID
WHERE TISR.StatusID = 1
  AND TCRP.InstrumentID IS NULL;
```

### 8.3 Review ManualPositionClose_Crisis audit log for closes initiated via this wrapper

```sql
SELECT TOP 20 MPC.PositionID, MPC.CID, MPC.OperationID,
       MPC.BidRate, MPC.AskRate, MPC.CloseDate
FROM History.ManualPositionClose_Crisis AS MPC WITH (NOLOCK)
ORDER BY MPC.CloseDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.ManualPositionClose_Casing | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ManualPositionClose_Casing.sql*
