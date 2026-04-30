# AffiliateCommission.CustomerAggregatedData

> Aggregated trading activity summary per customer, tracking cumulative commission amounts and last position timestamps for fast reporting and commission eligibility checks.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | CID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

CustomerAggregatedData stores a running summary of each customer's trading activity relevant to affiliate commission calculations. Each row represents one customer (identified by CID) and aggregates their total commissions earned (on open and close), last position timestamps, and currently open position commission value.

This table exists to provide fast lookups for commission-related customer metrics without needing to aggregate across the much larger ClosedPosition and related tables. It serves GetCustomerFinanceDetails and GetCreditTriggeredEvents procedures, which need quick access to customer-level commission totals for triggering events and reporting.

The table has 38,247 rows representing active or recently active customers. Note that CID is int here (vs bigint in most other tables), suggesting this was an earlier table in the schema's evolution. Some monetary columns allow NULL, and DateModified is frequently NULL, indicating partial or incremental updates.

---

## 2. Business Logic

### 2.1 Commission Tracking by Event Type

**What**: Separates commissions earned at position open vs position close.

**Columns/Parameters Involved**: `TotalCommissionOnOpen`, `TotalCommissionOnClose`, `OpenedPositionsCommissionOnOpen`

**Rules**:
- TotalCommissionOnOpen: Cumulative commission from position opening events (NULL when no open commissions recorded)
- TotalCommissionOnClose: Cumulative commission from position closing events
- OpenedPositionsCommissionOnOpen: Commission on currently open positions (changes as positions close)
- These three values together give a complete picture of a customer's commission profile

---

## 3. Data Overview

| CID | TotalCommissionOnClose | LastClosedPosition | OpenedPositionsCommissionOnOpen | Meaning |
|---|---|---|---|---|
| 25185010 | 15 | 2026-02-17 20:14 | 15 | Active customer with $15 close commission and $15 in open position commissions. Recent activity (Feb 2026). |
| 25184967 | 10 | 2026-02-17 20:07 | 0 | Customer with $10 close commission and no open position commissions. All positions closed. |
| 25184728 | 9 | 2026-02-17 19:46 | 0 | Similar pattern - small commission, no open positions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. PK. Uses int (vs bigint elsewhere) - earlier table design. One row per customer. |
| 2 | TotalCommissionOnOpen | money | YES | - | CODE-BACKED | Cumulative commission earned from position opening events across all time. NULL when no open commissions have been recorded for this customer. |
| 3 | TotalCommissionOnClose | money | YES | - | CODE-BACKED | Cumulative commission earned from position closing events across all time. Primary metric for affiliate commission reporting. |
| 4 | LastClosedPosition | datetime | YES | - | CODE-BACKED | Timestamp of the customer's most recent position close. NULL if the customer has never closed a position. Used for activity recency checks. |
| 5 | LastOpenedPosition | datetime | YES | - | CODE-BACKED | Timestamp of the customer's most recent position open. NULL if the customer has never opened a position. |
| 6 | OpenedPositionsCommissionOnOpen | money | NO | - | CODE-BACKED | Current total commission on positions that are still open. Decreases as positions close (commission moves to TotalCommissionOnClose). NOT NULL - defaults to 0. |
| 7 | DateModified | datetime | YES | - | CODE-BACKED | Last time this aggregate was updated. NULL in most records observed, suggesting incremental update logic may not always set this field. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.GetCustomerFinanceDetails | SELECT | Reader | Reads customer finance summary |
| AffiliateCommission.GetCreditTriggeredEvents | SELECT | Reader | Uses customer data for credit event triggering |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.GetCustomerFinanceDetails | Stored Procedure | Reader |
| AffiliateCommission.GetCreditTriggeredEvents | Stored Procedure | Reader |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerAggregatedData | CLUSTERED PK | CID ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerAggregatedData | PRIMARY KEY | Unique customer identifier |

---

## 8. Sample Queries

### 8.1 Top customers by commission earned
```sql
SELECT TOP 20 CID, TotalCommissionOnClose, TotalCommissionOnOpen,
       OpenedPositionsCommissionOnOpen, LastClosedPosition
FROM AffiliateCommission.CustomerAggregatedData WITH (NOLOCK)
ORDER BY ISNULL(TotalCommissionOnClose, 0) DESC;
```

### 8.2 Recently active customers
```sql
SELECT CID, LastClosedPosition, LastOpenedPosition, TotalCommissionOnClose
FROM AffiliateCommission.CustomerAggregatedData WITH (NOLOCK)
WHERE LastClosedPosition >= DATEADD(day, -30, GETUTCDATE())
ORDER BY LastClosedPosition DESC;
```

### 8.3 Customers with open position commissions
```sql
SELECT CID, OpenedPositionsCommissionOnOpen, LastOpenedPosition
FROM AffiliateCommission.CustomerAggregatedData WITH (NOLOCK)
WHERE OpenedPositionsCommissionOnOpen > 0
ORDER BY OpenedPositionsCommissionOnOpen DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CustomerAggregatedData | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.CustomerAggregatedData.sql*
