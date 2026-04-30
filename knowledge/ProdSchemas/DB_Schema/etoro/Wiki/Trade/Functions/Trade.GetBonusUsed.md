# Trade.GetBonusUsed

> Calculates the total bonus credit consumed by position closes within a specific one-hour window for a customer, by analyzing the delta in BonusCredit across History.Credit events.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INTEGER - bonus used in cents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetBonusUsed calculates how much promotional bonus credit a customer consumed through position closes during a specific one-hour period. eToro offers bonus credits that are applied against trading losses - when a position closes at a loss, the bonus absorbs part of the loss. This function tracks the bonus consumption by analyzing changes in the BonusCredit balance before and during the specified hour.

This function exists for billing and compliance reconciliation purposes. Bonus credit usage needs to be tracked per hour for regulatory reporting and customer activity auditing. The function reconstructs the usage by examining the BonusCredit field changes in History.Credit - specifically looking at position close events (CreditTypeID=4) and comparing each row's BonusCredit to the previous row's value.

The function was created by Geri Reshef on 10/01/2016 as part of the "Used Bonus Changes" feature (ticket 33426).

---

## 2. Business Logic

### 2.1 Hourly Bonus Consumption Tracking

**What**: Tracks bonus credit consumed by position closes in a one-hour window.

**Columns/Parameters Involved**: `@CID`, `@Y`, `@M`, `@D`, `@H`, `History.Credit.BonusCredit`, `CreditTypeID`

**Rules**:
- Constructs a one-hour window: StartOfHour to EndOfHour from the date/time parameters
- Gets the customer's BonusCredit balance from the last History.Credit row BEFORE the hour starts (baseline)
- Gets all credit events during the hour where CreditTypeID IN (4=Position Close, 7=Bonus Give, 1, 6)
- Joins each row with its predecessor to calculate the delta in BonusCredit
- Sums only the deltas from CreditTypeID=4 (position closes) - ignoring bonus deposits
- Returns the total bonus consumed (as absolute value * -1, in cents: multiplied by 100)
- Returns 0 if no bonus was used (ISNULL protection)

### 2.2 Credit Type Filtering

**What**: Only position close events count as "bonus used."

**Columns/Parameters Involved**: `CreditTypeID`

**Rules**:
- CreditTypeID=4 (Position Close): the ONLY type that counts as "bonus used"
- CreditTypeID=7 (Bonus Give): included in the window to track balance changes but NOT counted in the sum
- CreditTypeID=1 and 6: included for balance tracking but not in the final sum
- This ensures bonus GIVEN is not confused with bonus CONSUMED

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters History.Credit to this customer's events. |
| 2 | @Y | INT | NO | - | CODE-BACKED | Year of the target hour (e.g., 2026). |
| 3 | @M | INT | NO | - | CODE-BACKED | Month of the target hour (1-12). |
| 4 | @D | INT | NO | - | CODE-BACKED | Day of the target hour (1-31). |
| 5 | @H | INT | NO | - | CODE-BACKED | Hour of the target window (0-23). Defines a one-hour period starting at this hour. |
| 6 | Return value | INTEGER | NO | - | CODE-BACKED | Total bonus credit consumed by position closes in cents (multiplied by 100). Always non-negative (absolute values). 0 if no bonus was used. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | History.Credit | SELECT/WHERE | Reads credit history events for the customer within the hour window |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetBonusUsed (function)
  └── History.Credit (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | SELECT BonusCredit, CreditTypeID for baseline and hourly events |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS INTEGER | Return type | Bonus used in cents |
| WITH (NOLOCK) | Read hint | All History.Credit reads use NOLOCK |
| @ActionsInHour table variable | Internal | Temp storage for sequential row comparison via RN identity |

---

## 8. Sample Queries

### 8.1 Get bonus used by a customer in a specific hour

```sql
SELECT Trade.GetBonusUsed(12345678, 2026, 3, 15, 14) AS BonusUsedCents;
```

### 8.2 Get bonus used for every hour of a specific day

```sql
SELECT  h.HourNum,
        Trade.GetBonusUsed(12345678, 2026, 3, 15, h.HourNum) AS BonusUsedCents
FROM    (SELECT TOP 24 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS HourNum
         FROM sys.objects) h
ORDER BY h.HourNum;
```

### 8.3 Find customers with high bonus consumption

```sql
SELECT  CID,
        Trade.GetBonusUsed(CID, 2026, 3, 15, 14) AS BonusUsedCents
FROM    (SELECT DISTINCT CID FROM Trade.PositionTbl WITH (NOLOCK) WHERE StatusID = 1 AND CID < 100) top_cids
WHERE   Trade.GetBonusUsed(CID, 2026, 3, 15, 14) > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Original feature reference: ticket 33426 "Used Bonus Changes" (Geri Reshef, 2016-01-10).

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetBonusUsed | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetBonusUsed.sql*
