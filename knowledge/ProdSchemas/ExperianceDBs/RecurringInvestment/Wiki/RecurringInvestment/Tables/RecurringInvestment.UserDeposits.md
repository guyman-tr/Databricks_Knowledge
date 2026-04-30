# RecurringInvestment.UserDeposits

> Stores deposit data per user per cycle, tracking the aggregated deposit amount and timing for recurring investment plan execution.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Table |
| **Key Identifier** | GCID + DepositID (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK + IX_UserDeposits_DepositDate) |

---

## 1. Business Meaning

This table stores deposit data for recurring investment users. Each row represents a single deposit or deposit attempt for a specific user (GCID) in a specific cycle. The deposit amount is the aggregated total of all the user's active plan amounts for that cycle, collected via the Money Group's recurring deposit system.

Without this table, the recurring investment system would have no local record of deposit data. While the primary deposit source is the Billing DB ([Recurring].[Payment]), this table provides a local cache of deposit information needed by the recurring investment service for processing plan instances.

Data flows in from the Money ServiceBus via the Deposit Message Handler in the recurring investment backend service. When a deposit event occurs (success, soft decline, or hard decline), the handler receives the message and upserts the deposit data here via the PlanInstanceUserDepositUpsert or PlanInstanceUserDepositsUpsert stored procedures.

---

## 2. Business Logic

### 2.1 Aggregated User-Level Deposits

**What**: Each deposit represents the aggregated amount across all of a user's active recurring investment plans for a single cycle.

**Columns/Parameters Involved**: `GCID`, `DepositID`, `DepositAmountUsd`, `DepositAmountCurrency`

**Rules**:
- A user makes ONE deposit per cycle that covers ALL their active plans
- The deposit amount equals the sum of all active plan amounts for that user
- DepositAmountUsd and DepositAmountCurrency may differ when the user's plans use a non-USD currency
- Zero-amount deposits (DepositAmountUsd=0, DepositAmountCurrency=0) indicate deposit attempts that were recorded but had no associated monetary value (possibly soft/hard declines)

### 2.2 Deposit-to-Instance Relationship

**What**: Each deposit record links to multiple plan instances that share the same deposit cycle.

**Columns/Parameters Involved**: `GCID`, `DepositID`

**Rules**:
- The same DepositID appears in multiple PlanInstances rows (one per active plan)
- PlanInstances.DepositID references UserDeposits.DepositID
- The DepositID comes from the Money ServiceBus message and maps to Billing DB [Recurring].[Payment]

---

## 3. Data Overview

| GCID | DepositID | DepositAmountUsd | DepositAmountCurrency | Meaning |
|------|-----------|------------------|-----------------------|---------|
| 44738729 | 75103187 | 35.00 | 50.00 | A non-USD user deposited 50 in their local currency (approximately $35 USD). The difference indicates a currency conversion. This deposit funds all their active recurring investment plans for this cycle. |
| 34423667 | 75103183 | 3520.00 | 3000.00 | A high-value deposit of 3000 in local currency ($3520 USD). This user likely has multiple active plans or large plan amounts to require this deposit size. |
| 13807546 | 75103182 | 50.00 | 50.00 | A USD-denominated user deposited $50. Amounts match because the plan currency is USD. This represents a typical small recurring investment deposit. |
| 45596136 | 75103190 | 0.00 | 0.00 | A zero-amount deposit record. This likely represents a deposit attempt that was declined (soft or hard) where no money was actually transferred, but the attempt was still recorded. |
| 42408089 | 75103188 | 0.00 | 0.00 | Another zero-amount deposit record from the same batch. Multiple users may experience declines in the same deposit processing window. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | bigint | NO | - | VERIFIED | Global Customer ID uniquely identifying the eToro user. Part of the composite primary key. Each user has one deposit record per cycle. (Source: Confluence confirms GCID is "unique identifier of the user") |
| 2 | DepositID | int | NO | - | VERIFIED | Unique identifier of the deposit or deposit attempt for this cycle. Part of the composite primary key. Data comes from Money ServiceBus and maps to Billing DB [Recurring].[Payment]. (Source: Confluence) |
| 3 | DepositAmountUsd | decimal(18,2) | YES | - | VERIFIED | The deposit amount in USD. May differ from DepositAmountCurrency when the user's plan currency is not USD due to currency conversion. Zero indicates a failed/declined deposit attempt. Data comes from Money ServiceBus. (Source: Confluence) |
| 4 | DepositAmountCurrency | decimal(18,2) | YES | - | VERIFIED | The deposit amount in the plan's currency. The plan's currency can be found in RecurringInvestment.Plans.CurrencyID. Equal to DepositAmountUsd for USD-denominated plans. Data comes from Money ServiceBus. (Source: Confluence) |
| 5 | DepositDate | datetime | YES | - | VERIFIED | The date and time the deposit or deposit attempt was made. Data comes from Money ServiceBus. Used for temporal queries and deposit tracking. (Source: Confluence) |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. GCID references the external user system; DepositID references Billing DB [Recurring].[Payment].

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.PlanInstances | DepositID | Implicit Lookup | Plan instances reference the same DepositID from this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstanceUserDepositUpsert | Stored Procedure | Writes deposit data to this table |
| RecurringInvestment.PlanInstanceUserDepositsUpsert | Stored Procedure | Batch-writes deposit data to this table |
| RecurringInvestment.PlanInstanceUserDepositsUpsert_CopyVersion | Stored Procedure | Batch-writes deposit data for copy plans |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UserDeposits_GCID | CLUSTERED PK | GCID, DepositID | - | - | Active |
| IX_UserDeposits_DepositDate | NONCLUSTERED | DepositDate | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get recent deposits for a user
```sql
SELECT GCID, DepositID, DepositAmountUsd, DepositAmountCurrency, DepositDate
FROM [RecurringInvestment].[UserDeposits] WITH (NOLOCK)
WHERE GCID = 12345678
ORDER BY DepositDate DESC
```

### 8.2 Find zero-amount (failed) deposits in a date range
```sql
SELECT GCID, DepositID, DepositDate
FROM [RecurringInvestment].[UserDeposits] WITH (NOLOCK)
WHERE DepositAmountUsd = 0
  AND DepositDate >= '2026-04-01'
ORDER BY DepositDate DESC
```

### 8.3 Join deposits with plan instances to see the full cycle
```sql
SELECT ud.GCID, ud.DepositID, ud.DepositAmountUsd, ud.DepositDate,
       pi.PlanID, pi.InstanceID, pi.OrderStatusId, pi.PositionStatus
FROM [RecurringInvestment].[UserDeposits] ud WITH (NOLOCK)
JOIN [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK) ON ud.DepositID = pi.DepositID
WHERE ud.GCID = 12345678
ORDER BY ud.DepositDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | UserDeposits contains deposit data; each user has specific deposit per cycle; amount is aggregated across all plans; data comes from Money ServiceBus |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Deposit Message Handler listens to deposit messages and saves data to Instances Plans table and UserDeposits |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.UserDeposits | Type: Table | Source: RecurringInvestment/RecurringInvestment/Tables/RecurringInvestment.UserDeposits.sql*
