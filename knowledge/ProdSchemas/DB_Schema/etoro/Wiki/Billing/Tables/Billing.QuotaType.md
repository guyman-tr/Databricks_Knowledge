# Billing.QuotaType

> Lookup table defining the four time-period buckets (Daily, Weekly, Monthly, Yearly) used in the `Billing.QuotaManagement` funding-limit system.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (PRIMARY KEY CLUSTERED) |
| **Row Count** | 4 rows |
| **Partition** | N/A - filegroup PRIMARY |
| **Indexes** | 1 - PK CLUSTERED on ID |

---

## 1. Business Meaning

`Billing.QuotaType` is a four-row enumeration table that defines the time-period granularities for the deposit/withdrawal quota system. The quota system tracks how much a customer has transacted within a given rolling window, and `QuotaType` specifies which windows are supported.

Each quota period corresponds to a rolling window: a **Daily** quota resets every 24 hours, **Weekly** every 7 days, **Monthly** every 30/calendar days, and **Yearly** annually. When a deposit or withdrawal is processed, the `Billing.QuotaManagement` table accumulates transaction amounts per customer per funding type per quota type, allowing the platform to enforce per-period limits (e.g., "a customer on this plan can deposit no more than $X per month using method Y").

The values are: 1=Yearly, 2=Monthly, 3=Weekly, 4=Daily (ordered from longest to shortest period).

---

## 2. Business Logic

### 2.1 Quota Period Definitions

**What**: Defines the four time-period granularities at which transaction volume limits can be enforced per customer per funding type.

**Columns Involved**: `ID`, `Name`

**Rules**:
- ID=1 Yearly: cumulative limit over a 12-month rolling or calendar year window
- ID=2 Monthly: cumulative limit over a 30-day or calendar month window
- ID=3 Weekly: cumulative limit over a 7-day rolling window
- ID=4 Daily: cumulative limit over a 24-hour rolling window
- Used by `Billing.CountTransactionsWithTimeLimitForStatus` (which reads `Billing.FundingTypeStatusLimitList` containing `QuotaTypeID`) to determine what time window to apply when checking if a customer has exceeded a funding-type limit

---

## 3. Data Overview

| ID | Name |
|----|------|
| 1 | Yearly |
| 2 | Monthly |
| 3 | Weekly |
| 4 | Daily |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key. Quota period type: 1=Yearly, 2=Monthly, 3=Weekly, 4=Daily. Referenced as `QuotaTypeID` (implied) by `Billing.QuotaManagement` and `Billing.FundingTypeStatusLimitList`. No IDENTITY - values are static. |
| 2 | Name | varchar(20) | YES | NULL | CODE-BACKED | Human-readable period label: 'Yearly', 'Monthly', 'Weekly', 'Daily'. Used in admin reporting and configuration UIs to display quota period names. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No outbound FKs.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.QuotaManagement | QuotaTypeID | FK (implicit) | Each quota accumulation record is tagged with one of these period types |
| Billing.FundingTypeStatusLimitList (UDT) | IsByDays | Related | The IsByDays flag in this TVP interacts with the quota period logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies - static lookup table.

---

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.QuotaManagement | Table | FK on QuotaTypeID (period bucket for quota tracking) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_QuotaType | CLUSTERED PK | ID ASC | - | - | Active; FILLFACTOR=95 |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_QuotaType | PRIMARY KEY CLUSTERED | One row per quota type ID |

---

## 8. Sample Queries

### 8.1 View all quota types

```sql
SELECT ID, Name
FROM Billing.QuotaType WITH (NOLOCK)
ORDER BY ID
```

### 8.2 View quota accumulations by period type for a customer

```sql
SELECT
    qt.Name AS QuotaTypeName,
    qm.FundingTypeID,
    qm.CumulativeAmount,
    qm.LastUpdated
FROM Billing.QuotaManagement qm WITH (NOLOCK)
JOIN Billing.QuotaType qt WITH (NOLOCK) ON qt.ID = qm.QuotaTypeID
-- WHERE qm.CID = @CID
ORDER BY qt.ID, qm.FundingTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.QuotaType | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.QuotaType.sql*
