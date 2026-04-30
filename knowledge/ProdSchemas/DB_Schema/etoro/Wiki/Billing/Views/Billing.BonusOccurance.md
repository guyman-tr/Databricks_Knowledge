# Billing.BonusOccurance

> Aggregation view that counts how many bonus credits (CreditType 5=Champ Winner or 7=Bonus) each customer has received per campaign and bonus type, sourced from the History.Credit archive.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | Grouped by (CID, CampaignID, BonusTypeID) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.BonusOccurance` answers "how many times has this customer received a bonus of this type for this campaign?" It provides per-customer bonus occurrence counts, scoped to credit entries categorized as champion-tier rewards (CreditTypeID=5, "Champ Winner") or direct monetary bonuses (CreditTypeID=7, "Bonus") in the History.Credit ledger.

The view exists to support bonus eligibility checks and campaign reporting. Before issuing a new bonus credit, the system can query this view to determine whether a customer has already received a bonus for a given campaign, preventing duplicate payouts. Without this aggregation, each eligibility check would require a full GROUP BY scan of the multi-billion-row History.Credit archive.

Data flows from `History.Credit` (in the EtoroArchive database) - the append-only ledger of all financial credit events. This view is a read-only aggregation over that ledger. Note: `History.Credit` resides in EtoroArchive and requires appropriate database access. The view uses `WITH (NOLOCK)` to avoid locking the archive during busy periods.

---

## 2. Business Logic

### 2.1 Bonus Credit Type Filtering

**What**: Only credit entries classified as bonus-type events are counted; deposits, cashouts, position credits, and other credit types are excluded.

**Columns/Parameters Involved**: `CreditTypeID` (from History.Credit, filtered in WHERE clause)

**Rules**:
- CreditTypeID = 5 ("Champ Winner"): Credit issued to customers who win an eToro trading championship event. Linked to a specific CampaignID and BonusTypeID.
- CreditTypeID = 7 ("Bonus"): Standard monetary bonus credit issued as part of a promotional campaign (e.g., deposit matching, referral rewards).
- All other CreditType values (1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 6=Compensation, etc.) are excluded.

**Diagram**:
```
History.Credit rows (all types)
  |
  +-- WHERE CreditTypeID IN (5, 7) --> Only bonus events
  |
  +-- GROUP BY CID, CampaignID, BonusTypeID --> Count per customer per campaign
  |
  = Billing.BonusOccurance (BonusOccurance = how many bonus credits received)
```

### 2.2 Bonus Deduplication / Eligibility Check Pattern

**What**: The view enables callers to check whether a customer is eligible for a new bonus by verifying whether the customer has already received one for this campaign and bonus type.

**Columns/Parameters Involved**: `CID`, `CampaignID`, `BonusTypeID`, `BonusOccurance`

**Rules**:
- If a row exists for (CID, CampaignID, BonusTypeID), the customer has previously received that bonus type.
- `BonusOccurance > 1` indicates repeated bonus grants (either allowed by campaign rules or an anomaly to investigate).
- Absence of a row (no match) indicates the customer has not yet received this bonus - eligible for first grant.

---

## 3. Data Overview

N/A - `History.Credit` resides in the EtoroArchive database which is inaccessible to the read-only MCP connection. Sample data cannot be queried directly.

The view is expected to return rows like:

| CID | CampaignID | BonusTypeID | BonusOccurance | Meaning |
|-----|-----------|------------|----------------|---------|
| 1234567 | 101 | 3 | 1 | Customer 1234567 received exactly one Bonus credit for campaign 101 / bonus type 3. Eligible for first-time bonus processing. |
| 7654321 | 101 | 3 | 2 | Customer received the same bonus twice - either campaign rules permit repeat grants or this is a data anomaly worth investigating. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID from History.Credit. Identifies the eToro customer who received the bonus credits. Implicit FK to Customer.Customer. Groups all bonus credit events by customer within each campaign-bonus combination. |
| 2 | CampaignID | int | NO | - | CODE-BACKED | Campaign identifier from History.Credit. Groups bonus credits by the marketing or promotional campaign that triggered them. References BackOffice.Campaign (campaign definitions and metadata). A CampaignID of 0 or NULL may indicate a non-campaign system bonus. |
| 3 | BonusTypeID | int | NO | - | CODE-BACKED | Bonus type identifier from History.Credit. Categorizes the kind of bonus award within a campaign. References BackOffice.BonusType (bonus type definitions). Used together with CampaignID to uniquely identify a bonus grant scenario. |
| 4 | BonusOccurance | int | NO | - | CODE-BACKED | COUNT(*) aggregate: the number of bonus credit rows (CreditTypeID IN (5, 7)) in History.Credit for this (CID, CampaignID, BonusTypeID) combination. A value of 1 means one bonus granted; values > 1 indicate repeat grants. Note: column name is misspelled in DDL ("Occurance" instead of "Occurrence") - matches the DDL exactly. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CampaignID, BonusTypeID, CreditTypeID | History.Credit | Source (FROM with NOLOCK) | The sole base table. All rows originate from the credit ledger filtered to bonus credit types (5=Champ Winner, 7=Bonus). History.Credit is in the EtoroArchive database. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not discovered in Billing schema | - | - | No stored procedures in the Billing schema reference this view by name. Likely consumed by BackOffice or application-layer bonus eligibility checks. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BonusOccurance (view)
└── History.Credit (table, EtoroArchive DB - cross-database)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (EtoroArchive) | FROM source: all bonus credit events, filtered by CreditTypeID IN (5,7) and aggregated by (CID, CampaignID, BonusTypeID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered in Billing schema | - | Admin/reporting use |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Uses `WITH (NOLOCK)` on the base table to avoid blocking the archive during reads. No SCHEMABINDING (cross-database views cannot be schema-bound).

---

## 8. Sample Queries

### 8.1 Check if a customer has already received a specific campaign bonus

```sql
-- Requires access to EtoroArchive database
SELECT BonusOccurance
FROM Billing.BonusOccurance WITH (NOLOCK)
WHERE CID = @CustomerID
  AND CampaignID = @CampaignID
  AND BonusTypeID = @BonusTypeID
-- Returns 0 rows -> eligible for first bonus
-- Returns BonusOccurance = 1 -> already received once
-- Returns BonusOccurance > 1 -> received multiple times
```

### 8.2 Find customers who received more than one bonus for a campaign

```sql
-- Requires access to EtoroArchive database
SELECT CID, CampaignID, BonusTypeID, BonusOccurance
FROM Billing.BonusOccurance WITH (NOLOCK)
WHERE CampaignID = @CampaignID
  AND BonusOccurance > 1
ORDER BY BonusOccurance DESC
```

### 8.3 Count distinct customers who received bonuses per campaign

```sql
-- Requires access to EtoroArchive database
SELECT CampaignID, BonusTypeID, COUNT(DISTINCT CID) AS UniqueCustomers, SUM(BonusOccurance) AS TotalBonusEvents
FROM Billing.BonusOccurance WITH (NOLOCK)
GROUP BY CampaignID, BonusTypeID
ORDER BY CampaignID, BonusTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.BonusOccurance | Type: View | Source: etoro/etoro/Billing/Views/Billing.BonusOccurance.sql*
