# dbo.tblaff_RecurringCommissions

> Configuration table for scheduled recurring commission payments to affiliates, supporting frequency-based automated payouts with tier-inclusion options.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NC) |
| **Partition** | No |
| **Indexes** | 2 active (PK + covering) |

---

## 1. Business Meaning

dbo.tblaff_RecurringCommissions defines scheduled recurring commission payments for affiliates. Each row configures an automated payout for a specific customer-affiliate pair, specifying the commission amount, frequency, and number of repetitions. This enables "revenue share" or "residual income" models where affiliates receive ongoing payments based on customer activity.

Without this table, the affiliate system could only handle one-time event-based commissions (CPA, per-sale, per-lead). The recurring commission model allows long-term revenue-sharing relationships between the platform and its affiliates.

The table is currently empty (0 rows) in this environment, suggesting the recurring commission feature is either not active, was deprecated, or is configured differently in production. The `qry_ValidRecurringCommissions` view references this table for processing valid (non-expired) recurring commissions.

---

## 2. Business Logic

### 2.1 Frequency-Based Payment Schedule

**What**: Configures how often and how many times a recurring commission is paid.

**Columns/Parameters Involved**: `Frequency`, `Repeat`, `NumberCompleted`, `LastDate`

**Rules**:
- `Frequency`: Number of days between payments (default 0 - pay every cycle)
- `Repeat`: Total number of payments to make (default 0 - unlimited)
- `NumberCompleted`: How many payments have been made so far (default 0)
- `LastDate`: When the last payment was processed
- A commission is "expired" when NumberCompleted >= Repeat (if Repeat > 0)
- A commission is "due" when DATEDIFF(DAY, LastDate, GETDATE()) >= Frequency

### 2.2 Tier Inclusion Control

**What**: Controls whether this recurring commission cascades through the tier hierarchy.

**Columns/Parameters Involved**: `IncludeTiers`, `AffiliateID`, `Commission`

**Rules**:
- `IncludeTiers = 1`: Commission amount is distributed across tiers (parent affiliates get their tier percentage)
- `IncludeTiers = 0`: Commission paid only to the direct affiliate, no tier cascade

---

## 3. Data Overview

Table is currently empty (0 rows). No sample data available.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION. |
| 2 | CUSTOMER_ID | nvarchar(50) | YES | - | NAME-INFERRED | Customer identifier for this recurring commission. Stored as string (nvarchar) rather than int, suggesting it may hold external system IDs or composite keys. |
| 3 | COUNTRY | nvarchar(50) | YES | - | NAME-INFERRED | Country associated with this recurring commission. Stored as string name rather than CountryID, indicating a denormalized or externally-sourced value. |
| 4 | GRAND_TOTAL | float | YES | 0 | NAME-INFERRED | Total accumulated commission paid for this recurring entry. Updated as payments are processed. |
| 5 | AffiliateID | int | YES | 0 | VERIFIED | The affiliate receiving this recurring commission. Maps to tblaff_Affiliates.AffiliateID. |
| 6 | Commission | real | YES | 0 | CODE-BACKED | Commission amount per payment cycle. This is the base amount paid each time the schedule triggers. |
| 7 | IncludeTiers | bit | NO | 0 | CODE-BACKED | Tier cascade flag: 1 = distribute across tiers (parent affiliates get percentages), 0 = direct affiliate only. |
| 8 | Frequency | int | YES | 0 | CODE-BACKED | Payment frequency in days. 0 = every processing cycle. Higher values = longer between payments. |
| 9 | Repeat | int | YES | 0 | CODE-BACKED | Maximum number of payments. 0 = unlimited (pay forever). Non-zero = stop after N payments. |
| 10 | NumberCompleted | int | YES | 0 | CODE-BACKED | Count of payments already processed. Compared to Repeat to determine if the schedule is expired. |
| 11 | LastDate | datetime | YES | getdate() | CODE-BACKED | Timestamp of the most recent payment. Used with Frequency to determine when the next payment is due. |
| 12 | Optional1 | nvarchar(25) | YES | - | NAME-INFERRED | Generic optional field 1. Purpose unknown - no data available. |
| 13 | Optional2 | nvarchar(25) | YES | - | NAME-INFERRED | Generic optional field 2. Purpose unknown. |
| 14 | Optional3 | bigint | YES | - | NAME-INFERRED | Generic optional field 3 (numeric). May store a CID or other reference like other tblaff_* tables. |
| 15 | SubAffiliateID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking tag for this recurring commission record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | dbo.tblaff_Affiliates | Implicit | The affiliate receiving recurring payments |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.qry_ValidRecurringCommissions | FROM | View (READER) | Filters for valid (non-expired) recurring commissions due for processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.qry_ValidRecurringCommissions | View | Reads valid recurring commissions for payment processing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_RecurringCommissions_PK | NC PK | ID ASC | - | - | Active |
| RecurringCommissions_Covered | NC | ID, CUSTOMER_ID, COUNTRY, GRAND_TOTAL, AffiliateID, Commission, Frequency, Repeat, NumberCompleted, LastDate | - | - | Active (covering) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_RecurringCommissions_GRAND_TOTAL | DEFAULT | 0 |
| DF_tblaff_RecurringCommissions_AffiliateID | DEFAULT | 0 |
| DF_tblaff_RecurringCommissions_Commission | DEFAULT | 0 |
| DF_tblaff_RecurringCommissions_IncludeTiers | DEFAULT | 0 - No tier cascade by default |
| DF_tblaff_RecurringCommissions_Frequency | DEFAULT | 0 - Every cycle |
| DF_tblaff_RecurringCommissions_Repeat | DEFAULT | 0 - Unlimited |
| DF_tblaff_RecurringCommissions_NumberCompleted | DEFAULT | 0 |
| DF_tblaff_RecurringCommissions_LastDate | DEFAULT | getdate() |

---

## 8. Sample Queries

### 8.1 Find all active recurring commissions
```sql
SELECT ID, AffiliateID, CUSTOMER_ID, Commission, Frequency, Repeat, NumberCompleted
FROM dbo.tblaff_RecurringCommissions WITH (NOLOCK)
WHERE Repeat = 0 OR NumberCompleted < Repeat
ORDER BY AffiliateID
```

### 8.2 Due recurring commissions
```sql
SELECT ID, AffiliateID, Commission, LastDate, Frequency,
       DATEDIFF(DAY, LastDate, GETDATE()) AS DaysSinceLastPayment
FROM dbo.tblaff_RecurringCommissions WITH (NOLOCK)
WHERE (Repeat = 0 OR NumberCompleted < Repeat)
  AND DATEDIFF(DAY, LastDate, GETDATE()) >= Frequency
ORDER BY DaysSinceLastPayment DESC
```

### 8.3 Total recurring commission liability by affiliate
```sql
SELECT AffiliateID, COUNT(*) AS ActiveSchedules,
       SUM(Commission) AS TotalPerCycleCommission, SUM(GRAND_TOTAL) AS TotalPaidToDate
FROM dbo.tblaff_RecurringCommissions WITH (NOLOCK)
WHERE Repeat = 0 OR NumberCompleted < Repeat
GROUP BY AffiliateID
ORDER BY TotalPerCycleCommission DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 6.7/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 6 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_RecurringCommissions | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_RecurringCommissions.sql*
