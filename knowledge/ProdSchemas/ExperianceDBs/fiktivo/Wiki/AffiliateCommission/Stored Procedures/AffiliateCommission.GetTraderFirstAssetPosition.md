# AffiliateCommission.GetTraderFirstAssetPosition

> Retrieves the first asset position type and date for a customer, used to determine CPA first-position commission eligibility.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns FirstPositionAssetTypeID, DateAdded |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetTraderFirstAssetPosition checks whether a customer has opened their first trading position and what asset type it was. This information determines whether the affiliate qualifies for a "first position" CPA commission under the FirstPositionAssetPlan - a compensation model where affiliates earn a one-time payment when their referred customer makes their first trade.

This procedure reads from AffiliateConfiguration.TraderFirstAssetPosition, which is populated when a customer opens their first position. The DateAdded timestamp is used in change detection logic (see GetCreditTriggeredEvents) to trigger commission re-evaluation when a first position is recorded.

---

## 2. Business Logic

### 2.1 First Position Lookup with Partition Pruning

**What**: Checks if a customer has a recorded first position and what type it was.

**Columns/Parameters Involved**: `@CID`, `FirstPositionAssetTypeID`, `DateAdded`, `PartitionCol`

**Rules**:
- Looks up TraderFirstAssetPosition by CID with PartitionCol = CID % 50 for partition pruning
- FirstPositionAssetTypeID identifies the asset class of the first trade (e.g., stocks, crypto, CFD)
- DateAdded records when the first position was tracked
- Returns empty result set if the customer has not yet opened any position
- This data drives the FirstPositionAssetPlan commission: the affiliate earns a CPA payment based on CountryID + PositionAssetTypeID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID to look up. Matched against TraderFirstAssetPosition.CID with partition pruning on CID%50. |

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | FirstPositionAssetTypeID | int | - | - | CODE-BACKED | Asset type of the customer's first position (e.g., stock, crypto, CFD). Used to match against FirstPositionAssetPlan rates. |
| 3 | DateAdded | datetime | - | - | CODE-BACKED | When the first position was recorded. Used in change detection for commission re-evaluation triggers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateConfiguration.TraderFirstAssetPosition | READ (SELECT) | Retrieves first position data by CID with partition pruning |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission engine for CPA first-position eligibility.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetTraderFirstAssetPosition (procedure)
+-- AffiliateConfiguration.TraderFirstAssetPosition (table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateConfiguration.TraderFirstAssetPosition | Table (external) | SELECT by CID with PartitionCol=CID%50 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission engine) | External | Checks first-position CPA eligibility |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get first asset position for customer 12345
```sql
EXEC [AffiliateCommission].[GetTraderFirstAssetPosition] @CID = 12345
```

### 8.2 Check all first positions for recent customers
```sql
SELECT CID, FirstPositionAssetTypeID, DateAdded
FROM AffiliateConfiguration.TraderFirstAssetPosition WITH (NOLOCK)
ORDER BY DateAdded DESC
```

### 8.3 Count first positions by asset type
```sql
SELECT FirstPositionAssetTypeID, COUNT(*) AS CustomerCount
FROM AffiliateConfiguration.TraderFirstAssetPosition WITH (NOLOCK)
GROUP BY FirstPositionAssetTypeID
ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-2448: CPA New Compensation Design (2023-12-17)
- Unlabeled: Fix PartitionCol WHERE clause (2024-02-07)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetTraderFirstAssetPosition | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetTraderFirstAssetPosition.sql*
