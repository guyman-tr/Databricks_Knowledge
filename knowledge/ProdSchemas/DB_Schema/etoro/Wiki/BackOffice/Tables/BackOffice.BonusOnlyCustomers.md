# BackOffice.BonusOnlyCustomers

> Hedge exclusion list of customers who have received bonus credits but have made no real deposits - presence here suppresses hedging of their positions since they have no real economic exposure.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, CLUSTERED PK) |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

BackOffice.BonusOnlyCustomers is a binary membership list - a customer's CID is either in it (bonus-only, unhedged) or not. Presence here signals: this customer has received bonus credits but has never made a real deposit (TotalDeposit=0 in CustomerAllTimeAggregatedData and TotalCompensation < $100). Because their account balance is entirely composed of non-real money, their open trading positions carry no real financial risk to eToro - there is nothing to hedge against.

The table drives a critical risk management behavior via its embedded trigger (TrBonusOnlyCustomers_InsDel): every INSERT sets Customer.Customer.IsHedged=0 (disable hedging for this customer), and every DELETE sets IsHedged=1 (re-enable hedging), subject to exclusions. This makes BonusOnlyCustomers a real-time hedge control mechanism - adding or removing a CID immediately changes how the trading engine treats that customer's positions.

With 414,151 rows, this list represents a large segment of the customer base - customers who registered, received a sign-up or promotional bonus, but never funded their accounts with real money. Trade procedures (GetUserInfo, GetOrderForOpenContextData) check this table to determine hedging behavior for each customer's positions.

A cross-database synonym dbo.RW_BonusOnlyCustomers (pointing to AO-REAL-DB.etoro.BackOffice.BonusOnlyCustomers) allows reads from external systems or linked server contexts.

---

## 2. Business Logic

### 2.1 Membership Insertion Criteria (from Billing.AmountAddBonus)

**What**: A customer is added to BonusOnlyCustomers when a bonus is granted AND the customer has never deposited real money.

**Columns Involved**: `CID`

**Rules**:
- Triggered by Billing.AmountAddBonus after every bonus grant.
- Customer is added ONLY IF both conditions are met:
  1. CID NOT already in BonusOnlyCustomers (no duplicate inserts)
  2. NOT EXISTS in BackOffice.CustomerAllTimeAggregatedData WHERE TotalDeposit <> 0 OR ABS(TotalCompensation) >= 100
- This means: first-time bonus recipients who have no deposit history and less than $100 in compensations are added.
- Once a customer makes a real deposit (TotalDeposit <> 0), they are never re-added even after subsequent bonuses.

**Diagram**:
```
Billing.AmountAddBonus called (bonus granted to @CID)
    |
    v
CID already in BonusOnlyCustomers? --> YES --> skip (already listed)
    | NO
    v
CustomerAllTimeAggregatedData: TotalDeposit=0 AND TotalCompensation<100?
    | NO --> skip (has real money)
    | YES
    v
INSERT INTO BackOffice.BonusOnlyCustomers (CID = @CID)
    |
    v [trigger fires automatically]
UPDATE Customer.Customer SET IsHedged=0 WHERE CID=@CID
```

### 2.2 Hedge State Control via Trigger

**What**: The TrBonusOnlyCustomers_InsDel trigger automatically synchronizes Customer.Customer.IsHedged based on membership changes.

**Columns Involved**: `CID` (triggers action on Customer.Customer.IsHedged)

**Rules**:
- **On INSERT**: Sets IsHedged=0 for all inserted CIDs unconditionally. Bonus-only customers are never hedged.
- **On DELETE**: Sets IsHedged=1 (re-hedge) for deleted CIDs, BUT only if ALL three exclusion conditions pass:
  - LabelID != 26 (specific label exempt from hedging)
  - PlayerLevelID != 4 (PlayerLevel 4 = exempt from hedging, likely VIP/special tier)
  - CID NOT IN (SELECT CID FROM CEP.ListCIDMappings WHERE NamedListID=3) (not on CEP exclusion list)
- The DELETE path uses INNER JOIN DELETED, so only the removed CIDs are re-hedged.

**Diagram**:
```
BonusOnlyCustomers INSERT (bonus-only added)
    --> Customer.Customer.IsHedged = 0 (unhedge, always)

BonusOnlyCustomers DELETE (customer made real deposit, removed)
    --> IF LabelID!=26 AND PlayerLevelID!=4 AND NOT IN CEP.ListCIDMappings(3)
        --> Customer.Customer.IsHedged = 1 (re-hedge)
    --> ELSE: remain unhedged (special exclusion applies)
```

---

## 3. Data Overview

| CID | Meaning |
|-----|---------|
| 29 | One of the earliest customer IDs in the system. Has received bonuses but never deposited real money. IsHedged=0 in Customer.Customer as a result. |
| 33 | Early customer account in the bonus-only pool. |
| 36 | Early customer account in the bonus-only pool. |
| 39 | Early customer account in the bonus-only pool. |
| 47 | Early customer account in the bonus-only pool. These low CIDs suggest the list includes very early eToro accounts that never converted to real-money trading. |

414,151 total rows as of 2026-03-17. All rows are single-column CID values - there is no additional data beyond membership.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer account ID. Clustered PK (no duplicates possible). Implicit FK to Customer.Customer.CID. Presence here means: this customer has received bonuses but has no real deposit history (TotalDeposit=0 AND TotalCompensation<$100 in CustomerAllTimeAggregatedData). Triggers IsHedged=0 in Customer.Customer upon insertion. Removal triggers IsHedged=1 (with exclusions). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Membership maps to the customer's trading account. Trigger updates Customer.Customer.IsHedged on every insert/delete. |
| CID | BackOffice.CustomerAllTimeAggregatedData | Implicit (checked on insert) | Billing.AmountAddBonus checks TotalDeposit and TotalCompensation here before inserting |
| CID | CEP.ListCIDMappings (NamedListID=3) | Implicit (trigger exclusion) | Customers on this CEP list are exempt from re-hedging on removal |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AmountAddBonus | CID | WRITER | Inserts CID after a bonus grant if customer has no real deposit history |
| BackOffice.TrBonusOnlyCustomers_InsDel | - | TRIGGER (embedded) | Fires on INSERT/DELETE to sync Customer.Customer.IsHedged |
| Trade.GetUserInfo | CID | READER | Checks membership to determine hedging behavior for user context |
| Trade.GetUserInfoByGCIDs | CID | READER | Bulk version of GetUserInfo - checks membership for multiple users |
| Trade.GetOrderForOpenContextData | CID | READER | Checks membership to determine hedging for order placement context |
| BackOffice.UpsertIntoAggregationTablesAction | CID | READER | References BonusOnlyCustomers in aggregation logic |
| BackOffice.V_CustomerAllTimeAggregatedDat | CID | View JOIN | Aggregated data view checks membership |
| CEP.GetOpenPositionsCEPData | CID | READER | CEP open position data includes bonus-only flag |
| Stocks.OpenPosition | CID | READER | Stocks position opening checks bonus-only status |
| dbo.RW_BonusOnlyCustomers | - | Synonym | Cross-DB synonym pointing to AO-REAL-DB instance of this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BonusOnlyCustomers (table)
- Trigger: TrBonusOnlyCustomers_InsDel
  ├── Customer.Customer (table) - IsHedged updated on INSERT/DELETE
  └── CEP.ListCIDMappings (table) - exclusion check on DELETE
- Populated by: Billing.AmountAddBonus (checks CustomerAllTimeAggregatedData)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Trigger target: IsHedged updated on insert/delete |
| CEP.ListCIDMappings | Table | Trigger exclusion check (NamedListID=3) on delete path |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AmountAddBonus | Procedure | WRITER - inserts CID after bonus grant if no deposit history |
| Trade.GetUserInfo | Procedure | READER - hedge status determination |
| Trade.GetUserInfoByGCIDs | Procedure | READER - bulk hedge status |
| Trade.GetOrderForOpenContextData | Procedure | READER - order placement hedge check |
| BackOffice.V_CustomerAllTimeAggregatedDat | View | READER - references in aggregation view |
| CEP.GetOpenPositionsCEPData | View | READER - CEP position data |
| Stocks.OpenPosition | Procedure | READER - stock position opening |
| BackOffice.UpsertIntoAggregationTablesAction | Procedure | READER - aggregation logic |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BonusOnlyCustomers | CLUSTERED PK | CID ASC | - | - | Active (FILLFACTOR=80, STATISTICS_NORECOMPUTE=ON, ON [PRIMARY]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BonusOnlyCustomers | PK | CID uniqueness - each customer appears at most once |

### 7.3 Trigger Details

**TrBonusOnlyCustomers_InsDel** (FOR INSERT, DELETE):
- Comment in DDL: "Users that don't have any money and have only Bonus, should not be hedged"
- INSERT path: `UPDATE Customer.Customer SET IsHedged=0 WHERE CID IN (INSERTED)`
- DELETE path: `UPDATE Customer.Customer SET IsHedged=1 WHERE CID IN (DELETED) AND LabelID <> 26 AND PlayerLevelID <> 4 AND CID NOT IN (SELECT CID FROM CEP.ListCIDMappings WHERE NamedListID=3)`
- Note: No UPDATE trigger - this table is append/delete only; rows are not modified.

### 7.4 Cross-Database Access

`dbo.RW_BonusOnlyCustomers` is a synonym pointing to `[AO-REAL-DB].[etoro].[BackOffice].[BonusOnlyCustomers]`. Used to access the real-time (read-write) instance from other contexts or linked servers.

---

## 8. Sample Queries

### 8.1 Check if a customer is bonus-only (unhedged by bonus status)
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM BackOffice.BonusOnlyCustomers WITH (NOLOCK) WHERE CID = @CID
) THEN 1 ELSE 0 END AS IsBonusOnly
```

### 8.2 Find bonus-only customers with their current account balance
```sql
SELECT
    boc.CID,
    cc.IsHedged,
    cc.PlayerLevelID,
    cc.LabelID
FROM BackOffice.BonusOnlyCustomers boc WITH (NOLOCK)
JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = boc.CID
ORDER BY boc.CID
```

### 8.3 Find customers who are bonus-only but also have open positions
```sql
SELECT boc.CID
FROM BackOffice.BonusOnlyCustomers boc WITH (NOLOCK)
WHERE EXISTS (
    SELECT 1 FROM Trade.PositionTbl p WITH (NOLOCK)
    WHERE p.CID = boc.CID
    -- add relevant open position filter
)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.BonusOnlyCustomers | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.BonusOnlyCustomers.sql*
