# Billing.DD_CashoutSentToProvider

> DataDog monitoring check that returns a boolean alert flag when any withdrawal payment legs are stuck in "SentToProvider" status (CashoutStatusID=10) for longer than 2 weeks, plus a detail list of affected WithdrawIDs.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: result set 1 = value (0=OK, 1=alert); result set 2 = list of WithdrawIDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_CashoutSentToProvider` is a DataDog synthetic monitor procedure (DBAD-17, initial version September 2022). It detects withdrawal payment legs in `Billing.WithdrawToFunding` that are stuck in `CashoutStatusID=10` (SentToProvider) for longer than 2 weeks - a sign that a payment was transmitted to a provider but no confirmation ever arrived.

`CashoutStatusID=10` (SentToProvider) is a non-final intermediate state in the withdrawal pipeline. Normally, providers acknowledge payment instructions within hours or a few business days. Records remaining in this state for 2+ weeks are operationally problematic: the customer may not have received their money, the funds may be in limbo between eToro and the provider, and manual reconciliation is required.

This procedure returns TWO result sets:
1. A single row with `value` = 1 (alert) or 0 (clear) - the boolean DataDog alert trigger
2. An ordered list of individual `WithdrawID` values - for direct investigation

This dual result set design differs from `DD_Alert_CashoutSentToProvider`, which returns a COUNT (numeric) as a single result set. Both procedures implement the same detection logic (CashoutStatusID=10, 2-week lower bound, 1-month upper bound) but with different output formats for different DataDog monitor types.

Data flows into this check from: `Billing.WithdrawToFunding`, which is written by the cashout processing pipeline (`Billing.CashoutProcess*` procedures) when a withdrawal request is routed to a payment provider.

---

## 2. Business Logic

### 2.1 Stuck Cashout Detection Window

**What**: Identifies withdrawal payment legs in SentToProvider state within a defined age window (2 weeks to 1 month old).

**Columns/Parameters Involved**: `@FromDate`, `@ToDate`, `Billing.WithdrawToFunding.CashoutStatusID`, `Billing.WithdrawToFunding.ModificationDate`

**Rules**:
- Default window: `ModificationDate < DATEADD(WEEK, -2, GETUTCDATE())` AND `ModificationDate > DATEADD(MONTH, -1, GETDATE())`
- Lower bound (older than 2 weeks): defines the "stuck" threshold - records this old that are still SentToProvider are anomalous
- Upper bound (newer than 1 month): limits scope to recent records; records older than 1 month are considered "known issues" or have been handled via other channels
- Parameters can override both bounds for targeted queries

**Diagram**:
```
Timeline:
  [1 month ago]  [2 weeks ago]       [now]
       |               |                |
       |<--- window -->|   (excluded)   |
       |               |
  AND CashoutStatusID = 10 (SentToProvider)
          |
   EXISTS? --> value=1 (alert)
   !EXISTS? --> value=0 (clear)
   Result set 2: WithdrawIDs ordered ASC
```

### 2.2 Two-Result-Set DataDog Output Pattern

**What**: Returns a control result set (value flag) followed by a data result set (detail list) - a pattern used by DataDog for monitors that need both alerting and detail.

**Rules**:
- Result set 1: always 1 row with `value` = 0 or 1 only (boolean)
- Result set 2: 0 or more rows, each a single `WithdrawID INT` - ordered ascending
- DataDog consumes result set 1 for alert triggering; the payments team reads result set 2 for investigation
- When no stuck cashouts exist: result set 1 returns `value=0`, result set 2 returns empty

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | YES | NULL (2 weeks ago) | CODE-BACKED | Upper bound on ModificationDate (records must be older than this date). When NULL, defaults to DATEADD(WEEK, -2, GETUTCDATE()) - the 2-week stuck threshold. Override to investigate a specific historical window. |
| 2 | @ToDate | DATETIME | YES | NULL (1 month ago) | CODE-BACKED | Lower bound on ModificationDate (records must be newer than this date). When NULL, defaults to DATEADD(MONTH, -1, GETDATE()) - limits scope to recent records within the past month. Override to expand the window. |
| 3 | value (output, RS1) | INT | NO | - | CODE-BACKED | Boolean alert flag in result set 1: 1 = at least one WithdrawToFunding record is stuck in CashoutStatusID=10 within the detection window; 0 = no stuck cashouts detected. DataDog uses this to trigger or clear an alert. |
| 4 | WithdrawID (output, RS2) | INT | NO | - | CODE-BACKED | Individual WithdrawID from Billing.WithdrawToFunding in result set 2, one row per stuck cashout. Ordered ascending. Empty result set when value=0. Used by the payments team to identify and investigate specific stalled transactions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CashoutStatusID=10 filter | Billing.WithdrawToFunding | Read | Reads WithdrawToFunding to detect payment legs stuck in SentToProvider (=10) state. See [Billing.WithdrawToFunding](../Tables/Billing.WithdrawToFunding.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by DataDog synthetic monitors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_CashoutSentToProvider (procedure)
└── Billing.WithdrawToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Direct read via temp table @List; filters on CashoutStatusID=10 and ModificationDate bounds to identify stalled payment legs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure; uses first result set value for alert trigger; payments team inspects second result set for investigation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run with default 2-week detection window

```sql
EXEC Billing.DD_CashoutSentToProvider;
-- Result set 1: value (0 or 1)
-- Result set 2: list of stuck WithdrawIDs
```

### 8.2 Override to investigate a specific historical date range

```sql
EXEC Billing.DD_CashoutSentToProvider
    @FromDate = '2026-02-15',
    @ToDate = '2026-02-01';
```

### 8.3 Join stuck WithdrawIDs to full withdrawal details for investigation

```sql
SELECT wtf.WithdrawID,
       wtf.CashoutStatusID,
       wtf.ModificationDate,
       wtf.FundingID,
       wtf.Amount,
       wtf.CashoutTypeID,
       DATEDIFF(DAY, wtf.ModificationDate, GETUTCDATE()) AS DaysStuck
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.CashoutStatusID = 10
  AND wtf.ModificationDate < DATEADD(WEEK, -2, GETUTCDATE())
  AND wtf.ModificationDate > DATEADD(MONTH, -1, GETDATE())
ORDER BY wtf.ModificationDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_CashoutSentToProvider | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_CashoutSentToProvider.sql*
