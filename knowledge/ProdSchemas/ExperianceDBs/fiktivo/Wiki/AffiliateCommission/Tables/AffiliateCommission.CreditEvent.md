# AffiliateCommission.CreditEvent

> Event tracking table for credit transactions (deposits/chargebacks), storing the full attribution and financial context for each credit event as it flows through the commission processing pipeline.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | CreditID (bigint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (PK clustered + 1 unique NC + 2 NC) |

---

## 1. Business Meaning

CreditEvent is the event-level tracking table for credit transactions in the affiliate commission pipeline. While Credit stores the final processed state, CreditEvent tracks each credit as it flows through processing - capturing the initial event details, attribution checks (NonOrganicUpdated, ReAttributeUpdated), and processing metadata (Source, LastCheckDate). It is the credit-domain counterpart of ClosedPositionEvent.

This table exists to manage the intermediate processing state of credit events. When a deposit or chargeback arrives, it is recorded here with full financial and attribution context. The system then checks organic vs affiliate attribution, performs re-attribution, and tracks when these checks occurred. With 1.32 million rows (vs 4.75M in Credit), it holds events for the subset of credits actively being processed or recently processed.

The table includes a CHECK constraint (CreditTypeID < 6), limiting to valid credit types. CreditSource (int) tracks the source system that originated the credit event. The NONCLUSTERED unique index on ID alongside the CLUSTERED PK on CreditID supports both ID-ordered scanning and CreditID-based lookups.

---

## 2. Business Logic

### 2.1 Attribution Check Pipeline

**What**: Each credit event goes through organic/non-organic and re-attribution checks.

**Columns/Parameters Involved**: `NonOrganicUpdated`, `ReAttributeUpdated`, `LastCheckDate`, `Source`

**Rules**:
- NonOrganicUpdated: timestamp of non-organic attribution check. NULL = not checked
- ReAttributeUpdated: timestamp of re-attribution check. NULL = not checked
- Source: processing node identifier (e.g., "AzureWestEurope")
- CreditSource: integer identifying the source system (1 = standard deposit path)

---

## 3. Data Overview

| ID | CreditID | CreditDate | Amount | IsFirstDeposit | CreditTypeID | AffiliateID | Source | Meaning |
|---|---|---|---|---|---|---|---|---|
| 4450208 | 2168476045 | 2026-04-12 13:59 | 100 | 1 | 1 | 3 | AzureWestEurope | Active FTD event. $100 deposit, country 196. No organic/re-attribution checks yet. |
| 4450207 | 2168476044 | 2026-04-12 13:50 | 100 | 1 | 1 | 3 | AzureWestEurope | Same pattern - FTD, $100, pending attribution checks. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. Unique NC index for ordered scanning. |
| 2 | CreditID | bigint | NO | - | CODE-BACKED | Credit event this tracks. PK (clustered). References Credit.CreditID. |
| 3 | CreditDate | datetime | NO | - | CODE-BACKED | Timestamp of the credit event. |
| 4 | Amount | float | NO | - | CODE-BACKED | Credit amount. |
| 5 | IsFirstDeposit | bit | NO | - | CODE-BACKED | Whether this is the customer's first deposit (FTD). |
| 6 | CreditTypeID | tinyint | NO | - | CODE-BACKED | Credit type. CHECK constraint: CreditTypeID < 6. 1=Deposit, 4=Chargeback A, 5=Chargeback B. See [Credit Type](../_glossary.md#credit-type). |
| 7 | CountryID | bigint | NO | - | CODE-BACKED | Customer country. |
| 8 | ProviderID | bigint | NO | - | CODE-BACKED | Current provider. |
| 9 | RealProviderID | bigint | NO | - | CODE-BACKED | Execution entity. |
| 10 | OriginalProviderID | bigint | NO | - | CODE-BACKED | Original provider. |
| 11 | CID | bigint | NO | - | CODE-BACKED | Customer ID. Indexed with NonOrganicUpdated for targeted re-checks. |
| 12 | OriginalCID | bigint | YES | - | CODE-BACKED | Original customer in copy-trading scenarios. |
| 13 | LastCheckDate | datetime | YES | - | CODE-BACKED | Last pipeline examination timestamp. |
| 14 | Source | nvarchar(50) | YES | - | CODE-BACKED | Processing node identifier. |
| 15 | DateModified | datetime | NO | getutcdate() | CODE-BACKED | Last modification timestamp. |
| 16 | NonOrganicUpdated | datetime | YES | - | CODE-BACKED | Timestamp of non-organic attribution check. |
| 17 | ReAttributeUpdated | datetime | YES | - | CODE-BACKED | Timestamp of re-attribution check. |
| 18 | AffiliateID | int | NO | - | CODE-BACKED | Attributed affiliate. |
| 19 | GCID | bigint | YES | - | CODE-BACKED | Global Customer ID. Nullable (vs NOT NULL in ClosedPositionEvent). |
| 20 | CreditSource | int | YES | - | CODE-BACKED | Source system identifier. 1 = standard deposit path. |
| 21 | ProductID | varchar(50) | YES | - | CODE-BACKED | Product identifier for multi-product platforms (ISA MoneyFarm per PART-5458). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditID | AffiliateCommission.Credit | Implicit FK | Parent credit record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.CreditEventVW | JOIN | View | Event view with attribution |
| AffiliateCommission.InsertCreditEvent | INSERT | Writer | Creates event records |
| AffiliateCommission.RemoveCreditEvent | DELETE | Deleter | Removes processed events |
| AffiliateCommission.RemoveCreditExpiredEvents | DELETE | Deleter | Cleans up expired events |
| AffiliateCommission.GetCreditTriggeredEvents | SELECT | Reader | Reads triggered events |
| AffiliateCommission.UpdateCreditEventLastCheckDate | UPDATE | Modifier | Updates check timestamp |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CreditEvent (table)
└── AffiliateCommission.Credit (table) [implicit, via CreditID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | CreditID references credit events |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEventVW | View | Reads with RegistrationMetaData |
| AffiliateCommission.InsertCreditEvent | Stored Procedure | Writer |
| AffiliateCommission.RemoveCreditEvent | Stored Procedure | Deleter |
| AffiliateCommission.RemoveCreditExpiredEvents | Stored Procedure | Deleter |
| AffiliateCommission.GetCreditTriggeredEvents | Stored Procedure | Reader |
| AffiliateCommission.UpdateCreditEventLastCheckDate | Stored Procedure | Modifier |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CreditEvent | CLUSTERED PK | CreditID ASC | - | - | Active |
| UDX_CreditEvent_ID | UNIQUE NC | ID ASC | - | - | Active |
| IX_CreditEventCIDNonOrganicUpdated | NC | CID, NonOrganicUpdated | - | - | Active |
| IX_CreditEvent_CreditDate | NC | CreditDate, DateModified, Source | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CreditEvent | PRIMARY KEY | Unique CreditID |
| DF_CreditEvent_DateModified | DEFAULT | getutcdate() |
| Chk_CreditTypeID | CHECK | CreditTypeID < 6 - limits to valid credit types |

---

## 8. Sample Queries

### 8.1 Recent unprocessed credit events
```sql
SELECT TOP 20 ID, CreditID, CreditDate, Amount, CreditTypeID, AffiliateID, Source,
       NonOrganicUpdated, ReAttributeUpdated
FROM AffiliateCommission.CreditEvent WITH (NOLOCK)
WHERE NonOrganicUpdated IS NULL
ORDER BY ID DESC;
```

### 8.2 FTD events in the last 7 days
```sql
SELECT CreditID, CreditDate, CID, Amount, AffiliateID, GCID, Source
FROM AffiliateCommission.CreditEvent WITH (NOLOCK)
WHERE IsFirstDeposit = 1 AND CreditDate >= DATEADD(day, -7, GETUTCDATE())
ORDER BY CreditDate DESC;
```

### 8.3 Event with credit context
```sql
SELECT e.CreditID, e.CreditDate, e.Amount, e.CreditTypeID, e.AffiliateID,
       c.Valid, c.IsProcessed, c.CommissionSource
FROM AffiliateCommission.CreditEvent e WITH (NOLOCK)
JOIN AffiliateCommission.Credit c WITH (NOLOCK) ON e.CreditID = c.CreditID
WHERE e.CreditID = 2168476045;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-5458](https://etoro-jira.atlassian.net/browse/PART-5458) | Jira | ISA MoneyFarm - added ProductID support (Jan 2026) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CreditEvent | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.CreditEvent.sql*
