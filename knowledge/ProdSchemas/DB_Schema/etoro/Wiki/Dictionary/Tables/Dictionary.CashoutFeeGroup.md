# Dictionary.CashoutFeeGroup

> Lookup table defining the 3 withdrawal fee groups — Default, Exempt, and Discount — controlling which fee schedule applies to a customer's cashout transactions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CashoutFeeGroupID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Row Count** | 3 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.CashoutFeeGroup classifies customers into fee tiers for withdrawal processing. Each customer's BackOffice.Customer record carries a CashoutFeeGroupID that determines which withdrawal fee schedule applies. The fee group is automatically calculated based on the customer's PlayerLevel (eToro Club tier) and GuruStatus (Popular Investor tier) via mapping tables, but can also be manually overridden by BackOffice operators.

The three groups represent: Default (1) — standard withdrawal fees apply; Exempt (2) — no withdrawal fees charged (typically for high-tier customers, PIs, or promotional offers); Discount (3) — reduced withdrawal fees. The fee group links to Trade.CashoutRange, which defines the actual fee amounts per group.

The fee group is determined dynamically by Billing.ProcessCashoutFeeGroupUpdate, which looks up the customer's PlayerLevel and GuruStatus in Billing.PlayerLevelToCashoutFeeGroup and Billing.GuruStatusToCashoutFeeGroup mapping tables to find the appropriate fee group. This means tier upgrades/downgrades automatically adjust withdrawal fees.

---

## 2. Business Logic

### 2.1 Fee Group Assignment

**What**: How a customer's withdrawal fee group is determined and updated.

**Columns/Parameters Involved**: `CashoutFeeGroupID`, `Name`

**Rules**:
- **Default (1)**: Standard withdrawal fees apply. Default for new customers at registration (set in Customer.InsertRealCustomer). Most customers are in this group.
- **Exempt (2)**: Zero withdrawal fees. Typically granted to high-tier eToro Club members, active Popular Investors, or through promotional campaigns.
- **Discount (3)**: Reduced withdrawal fees. Mid-tier benefit — lower than Default but not completely waived.

**Diagram**:
```
Fee Group Determination Flow:

  Customer Tier Changes
       │
       ├── PlayerLevel upgrade/downgrade
       │        └──► Billing.PlayerLevelToCashoutFeeGroup ──► CashoutFeeGroupID
       │
       ├── GuruStatus change
       │        └──► Billing.GuruStatusToCashoutFeeGroup ──► CashoutFeeGroupID
       │
       └── Billing.ProcessCashoutFeeGroupUpdate
                └──► Updates BackOffice.Customer.CashoutFeeGroupID
                └──► CashoutFeeGroupID → Trade.CashoutRange → Actual fee amounts
```

### 2.2 Fee Application in Withdrawals

**What**: How the fee group is used during withdrawal processing.

**Columns/Parameters Involved**: `CashoutFeeGroupID`

**Rules**:
- Billing.WithdrawRequestAdd reads from Trade.CashoutRange WHERE CashoutFeeGroupID matches customer's group
- Trade.CashoutRange defines fee amounts per group (minimum fee, percentage, maximum fee)
- BackOffice.CustomerSetCashoutFeeGroup allows manual override by operators
- BackOffice.CashoutFeeGroupBulkUpdate enables bulk updates via TVP (BackOffice.TBL_CashoutFeeGroup)
- Customer.GetMiscData returns CashoutFeeGroupID as part of customer configuration data
- Billing.WithdrawalService_GetCustomerFeeGroups JOINs to resolve group names

---

## 3. Data Overview

| CashoutFeeGroupID | Name | Meaning |
|---|---|---|
| 1 | Default | Standard withdrawal fee schedule. Applied to most customers by default at registration. Fees defined in Trade.CashoutRange for this group. May include fixed fee per withdrawal, percentage-based fees, or tiered amounts based on withdrawal size. |
| 2 | Exempt | Zero withdrawal fees. Granted to premium customers (high eToro Club tiers, active Popular Investors) or through special promotions. Mapped via Billing.GuruStatusToCashoutFeeGroup and Billing.PlayerLevelToCashoutFeeGroup. |
| 3 | Discount | Reduced withdrawal fees. Intermediate tier between Default and Exempt. Applied to mid-tier loyalty program members. Lower fixed/percentage fees than Default but not fully waived. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CashoutFeeGroupID | int | NO | - | VERIFIED | Primary key identifying the fee group. 1=Default, 2=Exempt, 3=Discount. Stored in BackOffice.Customer (FK), Trade.CashoutRange (FK). Mapped from PlayerLevel via Billing.PlayerLevelToCashoutFeeGroup and from GuruStatus via Billing.GuruStatusToCashoutFeeGroup. Auto-updated by Billing.ProcessCashoutFeeGroupUpdate when tier changes. |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Human-readable fee group name. Nullable. Joined in Billing.WithdrawalService_GetCustomerFeeGroups for display. Values: 'Default', 'Exempt', 'Discount'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | CashoutFeeGroupID | Explicit FK | Customer's assigned fee group |
| History.BackOfficeCustomer | CashoutFeeGroupID | Explicit FK | Historical fee group snapshots |
| Billing.GuruStatusToCashoutFeeGroup | CashoutFeeGroupID | Explicit FK | Maps GuruStatus → fee group |
| Billing.PlayerLevelToCashoutFeeGroup | CashoutFeeGroupID | Explicit FK | Maps PlayerLevel → fee group |
| Trade.CashoutRange | CashoutFeeGroupID | Explicit FK | Fee amounts per group |
| History.CashoutRange | CashoutFeeGroupID | Explicit FK | Historical fee range snapshots |
| BackOffice.TBL_CashoutFeeGroup | CashoutFeeGroupID | UDT column | TVP for bulk updates |
| BackOffice.CustomerSafty | CashoutFeeGroupID | View SELECT | Schema-bound customer view |
| BackOffice.CustomerSetCashoutFeeGroup | @CashoutFeeGroupID | Parameter UPDATE | Manual fee group override |
| BackOffice.CashoutFeeGroupBulkUpdate | - | TVP UPDATE | Bulk fee group updates |
| Billing.ProcessCashoutFeeGroupUpdate | @CashoutFeeGroupID | OUTPUT param | Auto-calculates and updates fee group |
| Billing.UpdateCashoutFeeGroupID | @CashoutFeeGroupID | Parameter UPDATE | Direct fee group update |
| Billing.WithdrawRequestAdd | CashoutFeeGroupID | WHERE | Fee lookup from CashoutRange |
| Billing.WithdrawalService_GetCustomerFeeGroups | CashoutFeeGroupID | JOIN | Resolves group name |
| Customer.InsertRealCustomer | @DefaultCashoutFeeGroupID | Parameter INSERT | Sets default at registration |
| Customer.RegisterReal | @DefaultCashoutFeeGroupID | Parameter INSERT | Sets default at registration |
| Customer.GetMiscData | CashoutFeeGroupID | SELECT | Returns customer's fee group |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CashoutFeeGroup (table)
  └── referenced by BackOffice.Customer (FK)
  └── referenced by Trade.CashoutRange (FK)
  └── referenced by Billing.GuruStatusToCashoutFeeGroup (FK)
  └── referenced by Billing.PlayerLevelToCashoutFeeGroup (FK)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FK — customer's fee group |
| Trade.CashoutRange | Table | FK — fee amounts per group |
| Billing.GuruStatusToCashoutFeeGroup | Table | FK — GuruStatus mapping |
| Billing.PlayerLevelToCashoutFeeGroup | Table | FK — PlayerLevel mapping |
| History.BackOfficeCustomer | Table | FK — historical snapshots |
| History.CashoutRange | Table | FK — historical fee ranges |
| Billing.ProcessCashoutFeeGroupUpdate | Stored Procedure | Auto-calculates fee group |
| BackOffice.CustomerSetCashoutFeeGroup | Stored Procedure | Manual override |
| Billing.WithdrawRequestAdd | Stored Procedure | Fee lookup at withdrawal time |
| Customer.InsertRealCustomer | Stored Procedure | Sets default at registration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCCF | CLUSTERED PK | CashoutFeeGroupID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCCF | PRIMARY KEY | Unique fee group identifier, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all fee groups
```sql
SELECT  CashoutFeeGroupID,
        Name
FROM    Dictionary.CashoutFeeGroup WITH (NOLOCK)
ORDER BY CashoutFeeGroupID;
```

### 8.2 Count customers by fee group
```sql
SELECT  dcfg.Name           AS FeeGroup,
        COUNT(*)            AS CustomerCount
FROM    BackOffice.Customer boc WITH (NOLOCK)
JOIN    Dictionary.CashoutFeeGroup dcfg WITH (NOLOCK)
        ON boc.CashoutFeeGroupID = dcfg.CashoutFeeGroupID
GROUP BY dcfg.Name
ORDER BY CustomerCount DESC;
```

### 8.3 Show fee ranges per group
```sql
SELECT  dcfg.Name           AS FeeGroup,
        cr.*
FROM    Trade.CashoutRange cr WITH (NOLOCK)
JOIN    Dictionary.CashoutFeeGroup dcfg WITH (NOLOCK)
        ON cr.CashoutFeeGroupID = dcfg.CashoutFeeGroupID
ORDER BY dcfg.CashoutFeeGroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and codebase analysis across 12+ procedures with 6 FK-constrained tables.

---

*Generated: 2026-03-13 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CashoutFeeGroup | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CashoutFeeGroup.sql*
