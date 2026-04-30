# History.PositionFailInfo_Get

> Back-office query procedure that returns enriched position failure records for a customer within a date range - joining failure type name, instrument name, and copy-trade parent context (ParentCID, ParentUserName). Due to an INNER JOIN on History.Mirror, this procedure returns ONLY failures for mirrored (copy-trade) positions; regular position failures are excluded.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @StartDate + @EndDate - customer and date window for failure lookup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PositionFailInfo_Get` is a back-office reporting procedure that retrieves a customer's position failure records from the Azure read replica (`History.PositionFail` synonym -> `PositionFailRealAzureSecondary`) for a specified date range. It enriches the raw failure data with the failure type name (Dictionary.FailType), instrument name (Trade.GetInstrument), and copy-trade parent trader details (ParentCID, ParentUserName from History.Mirror).

The procedure is designed specifically for **copy-trading failure investigation**. The INNER JOIN to `History.Mirror` means it only returns failures where a matching mirror record exists (PF.MirrorID matches History.Mirror.MirrorID). For a customer's regular (non-copy-trade) position failures, this procedure returns no rows - those are accessible directly from History.PositionFail or via other tooling.

Back-office agents use this procedure to investigate scenarios like: "Customer X's copy-trade positions kept failing during this date range - what were the failure types and which popular investors were they copying?"

Data flow: (1) SELECT DISTINCT from History.PositionFail (Azure secondary read replica) filtered by CID and FailOccurred date range; (2) INNER JOIN Dictionary.FailType to resolve FailTypeID to human-readable Name; (3) INNER JOIN Trade.GetInstrument to resolve InstrumentID to instrument Name; (4) INNER JOIN History.Mirror to get the copy-trade parent trader's CID and UserName; (5) return the enriched result set. All tables read WITH (NOLOCK).

---

## 2. Business Logic

### 2.1 Mirror-Only Filter (INNER JOIN Behavioral Note)

**What**: The INNER JOIN to History.Mirror on PF.MirrorID effectively restricts results to copy-trade position failures only.

**Columns/Parameters Involved**: `PF.MirrorID`, `History.Mirror.MirrorID`

**Rules**:
- JOIN condition: `History.Mirror M ON M.MirrorID = PF.MirrorID`
- INNER JOIN (not LEFT JOIN) -> positions where MirrorID is NULL, 0, or not in History.Mirror are excluded
- Regular (non-copy-trade) position failures have MirrorID = 0 or NULL -> they do NOT appear in results
- This is the intended use case: the procedure provides the parent trader context (ParentCID, ParentUserName) that is only meaningful for copy-trade positions

**Diagram**:
```
History.PositionFail WHERE CID=@CID AND FailOccurred BETWEEN @StartDate AND @EndDate
    |
    INNER JOIN History.Mirror ON MirrorID  <- excludes non-mirror positions
    |
Result: ONLY copy-trade position failures, with parent trader identity
```

### 2.2 Date Range Filter

**What**: FailOccurred is filtered inclusive on both ends.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `PF.FailOccurred`

**Rules**:
- Filter: `PF.FailOccurred >= @StartDate AND PF.FailOccurred <= @EndDate`
- Both bounds are inclusive (>= and <=)
- @StartDate and @EndDate are DATETIME - time component matters; pass midnight boundaries for full-day queries

### 2.3 Buy/Sell Direction Display

**What**: IsBuy (BIT) is converted to a readable string for the result set.

**Columns/Parameters Involved**: `PF.IsBuy`

**Rules**:
- `CASE PF.IsBuy WHEN 0 THEN 'Sell' ELSE 'Buy' END` - 0='Sell', any non-zero='Buy'
- Returned as alias `[Buy/Sell]`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose position failures are to be retrieved. Filtered as History.PositionFail WHERE CID=@CID. |
| 2 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the failure date range (inclusive). Matched against FailOccurred >= @StartDate. |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the failure date range (inclusive). Matched against FailOccurred <= @EndDate. |

**Result Set Columns Returned:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| R1 | FailOccurred | History.PositionFail.FailOccurred | UTC timestamp when the position failure was recorded. |
| R2 | FailType | Dictionary.FailType.Name | Human-readable failure type name. Values: 1=Request To Open, 2=Request To Close, 3=Open, 4=Close, 5=Edit, 6=External Error, 7=Internal Error, 8=MM object disconnected from its parent, 9=MM Max StopLoss, 10=Min Position Amount, 11=Mirror edit StopLoss insufficient funds, 12=Max position amount in units, 13=Max Take Profit reached, 14=PositionRedeemCancelFail, 15=PositionRedeemPendingFail, 16=PositionRedeemCloseFail, 17=Detach. |
| R3 | FailReason | History.PositionFail.FailReason | Human-readable or system-generated text description of why the failure occurred. |
| R4 | PositionID | History.PositionFail.PositionID | Unique position identifier (BIGINT) for the failed position. |
| R5 | Buy/Sell | Derived from History.PositionFail.IsBuy | Trade direction: 'Buy' (IsBuy=1) or 'Sell' (IsBuy=0). |
| R6 | Amount | History.PositionFail.Amount | Invested amount for the failed position. |
| R7 | Instrument | Trade.GetInstrument.Name | Instrument name (e.g., 'AAPL', 'EUR/USD', 'BTC') for the failed position. |
| R8 | ParentCID | History.Mirror.ParentCID | CID of the popular investor (parent trader) being copied at the time of failure. |
| R9 | ParentUserName | History.Mirror.ParentUserName | Username of the popular investor being copied. |
| R10 | ParentPositionID | History.PositionFail.ParentPositionID | PositionID of the parent trader's (popular investor's) position being copied. |
| R11 | OrigParentPositionID | History.PositionFail.OrigParentPositionID | Original parent position ID at the time of the copy position's open (before any detachments). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID, PF.FailOccurred | History.PositionFail | READER (synonym) | Primary data source - reads from Azure secondary read replica of PositionFailReal database |
| PF.FailTypeID | Dictionary.FailType | INNER JOIN | Resolves failure type ID to human-readable Name |
| PF.InstrumentID | Trade.GetInstrument | INNER JOIN | Resolves instrument ID to instrument Name |
| PF.MirrorID | History.Mirror | INNER JOIN | Gets ParentCID and ParentUserName for the copy-trade relationship; also restricts results to mirror positions only |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. Called by back-office tooling for copy-trade failure investigation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionFailInfo_Get (procedure)
+-- History.PositionFail (synonym -> PositionFailRealAzureSecondary)
|     +-- [PositionFailRealAzureSecondary].[PositionFailReal].[History].[PositionFail] (Azure secondary)
+-- Dictionary.FailType (table)
+-- Trade.GetInstrument (table/view, cross-schema)
+-- History.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionFail | Synonym (Azure secondary read replica) | SELECT DISTINCT with CID and date range filter; source of all failure data |
| Dictionary.FailType | Table | INNER JOIN to resolve FailTypeID to Name |
| Trade.GetInstrument | Table/View (cross-schema) | INNER JOIN to resolve InstrumentID to instrument Name |
| History.Mirror | Table | INNER JOIN on MirrorID to get ParentCID and ParentUserName; also acts as implicit filter for copy-trade-only results |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN History.Mirror | Behavioral | Restricts results to copy-trade (mirrored) position failures only - regular position failures are excluded |
| WITH (NOLOCK) on all tables | Optimization | All reads use NOLOCK to avoid blocking on the history/reference tables |
| SELECT DISTINCT | Deduplication | Eliminates duplicate rows in case the same failure is recorded multiple times in the source tables |
| FailOccurred inclusive range | Boundary | Both @StartDate and @EndDate are inclusive (<= on upper bound, unlike some other procedures that use exclusive upper bound) |

---

## 8. Sample Queries

### 8.1 Get copy-trade failures for a customer in the last week

```sql
EXEC History.PositionFailInfo_Get
    @CID = 12345678,
    @StartDate = DATEADD(day, -7, GETUTCDATE()),
    @EndDate = GETUTCDATE()
```

### 8.2 Check raw failure count before calling

```sql
SELECT pf.FailTypeID, COUNT(*) AS FailCount
FROM History.PositionFail pf WITH (NOLOCK)
WHERE pf.CID = 12345678
  AND pf.FailOccurred >= DATEADD(day, -7, GETUTCDATE())
  AND pf.FailOccurred <= GETUTCDATE()
GROUP BY pf.FailTypeID
ORDER BY FailCount DESC
```

### 8.3 Find the most common failure types for copy-trade positions

```sql
SELECT ft.Name AS FailType, COUNT(*) AS FailCount
FROM History.PositionFail pf WITH (NOLOCK)
JOIN Dictionary.FailType ft WITH (NOLOCK) ON ft.FailTypeID = pf.FailTypeID
WHERE pf.MirrorID IS NOT NULL AND pf.MirrorID > 0
  AND pf.FailOccurred >= DATEADD(day, -30, GETUTCDATE())
GROUP BY ft.Name
ORDER BY FailCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionFailInfo_Get | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.PositionFailInfo_Get.sql*
