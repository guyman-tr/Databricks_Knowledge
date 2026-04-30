# Billing.RoutingReason

> Lookup catalog of the 7 credit-card deposit routing decision factors - each row names one reason why a deposit was assigned to a specific depot/processor, used to audit and verify routing correctness.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | RoutingReasonID (PRIMARY KEY CLUSTERED) |
| **Row Count** | 7 rows (all FundingTypeID=1 CreditCard) |
| **Partition** | N/A - filegroup DICTIONARY |
| **Indexes** | 1 - PK CLUSTERED on RoutingReasonID |

---

## 1. Business Meaning

`Billing.RoutingReason` defines the 7 reasons a credit card deposit can be routed to a particular payment processor (depot). The credit card routing engine evaluates routing criteria in a hierarchical order and assigns the deposit to the winning depot, recording which criterion prevailed as `RoutingReasonID` on `Billing.Deposit`.

This table serves as both a configuration catalog and an audit reference: when a deposit is processed, its `RoutingReasonID` allows operations teams to trace which routing rule was applied and verify the routing logic was correct. The `Billing.CreditCardRoutingTransactionsVerification` SP queries `RoutingReason` to validate that recent deposits were routed according to the configured rules.

All 7 rows have `FundingTypeID=1` (CreditCard) - indicating routing reasons are currently only defined for credit card payments.

---

## 2. Business Logic

### 2.1 Credit Card Routing Hierarchy

**What**: The routing engine applies criteria in priority order, assigning the first matching rule as the `RoutingReasonID` on the deposit. Higher `RoutingReasonID` values represent more specific (lower-precedence) criteria.

**Columns Involved**: `RoutingReasonID`, `FundingTypeID`, `RoutingReason`, `Meaning`

**Routing Decision Hierarchy** (from live data and SP analysis):

| RoutingReasonID | RoutingReason | What It Means |
|----------------|---------------|---------------|
| 1 | Quota | Routed based on monthly volume quota distribution across processors |
| 2 | Priority | Routed based on configured processor priority ordering when quotas are not exceeded |
| 3 | Bin | Routed based on card BIN code matching `Billing.ProtocolByBin` rules |
| 4 | USBin | Routed based on US-specific BIN code routing rules |
| 5 | Regulation | Routed based on customer's designated regulation (`BackOffice.Customer.DesignatedRegulationID`) matching `Billing.ProtocolToRegulation` |
| 6 | Country | Routed based on card's country of origin (BIN country) matching `Billing.ProtocolCountry` |
| 7 | ByAft | Routed as an Account Funding Transaction (AFT) - a specific card-to-wallet transfer flow |

- `RoutingReasonID=0` (Undefined) appears in code but is NOT in this table - it represents failed/misconfigured routing and triggers a verification alert
- `FundingTypeID=1` on all rows - routing reasons are only defined for CreditCard; other funding types (Neteller, PayPal, etc.) use different depot assignment logic

### 2.2 Routing Verification

The `Billing.CreditCardRoutingTransactionsVerification` SP audits the last hour of credit card deposits:
- Finds deposits with `RoutingReasonID=0` (undefined routing - configuration error)
- Verifies Priority-routed deposits (ID=2) are consistent with current quota states
- Validates Regulation-routed deposits (ID=5) match customer's DesignatedRegulationID
- Validates Bin-routed deposits (ID=3) have a valid BIN in `Billing.ProtocolByBin`
- Validates Country-routed deposits (ID=6) have a valid BIN country in `Billing.ProtocolCountry`
- Returns discrepancy records for alerting

---

## 3. Data Overview

| RoutingReasonID | FundingTypeID | RoutingReason | Meaning (abbreviated) |
|----------------|---------------|---------------|----------------------|
| 1 | 1 (CreditCard) | Quota | Monthly quota distribution |
| 2 | 1 (CreditCard) | Priority | Processor priority ordering |
| 3 | 1 (CreditCard) | Bin | BIN code based routing |
| 4 | 1 (CreditCard) | USBin | US-specific BIN routing |
| 5 | 1 (CreditCard) | Regulation | Customer regulation based |
| 6 | 1 (CreditCard) | Country | Card country of origin |
| 7 | 1 (CreditCard) | ByAft | Account Funding Transaction |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RoutingReasonID | int | NO | - | CODE-BACKED | Primary key. Identifies the routing decision criterion: 1=Quota, 2=Priority, 3=Bin, 4=USBin, 5=Regulation, 6=Country, 7=ByAft. Referenced as `RoutingReasonID` by `Billing.Deposit` (each deposit records which criterion drove its processor selection). |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Funding type this routing reason applies to. All current rows = 1 (CreditCard). No FK constraint to `Dictionary.FundingType`, but value semantically references it. Allows future extension of routing reasons to other funding types. |
| 3 | RoutingReason | varchar(100) | NO | - | CODE-BACKED | Short code name for the routing criterion: 'Quota', 'Priority', 'Bin', 'USBin', 'Regulation', 'Country', 'ByAft'. Used in routing engine code to identify and apply the correct routing rule. Displayed in admin dashboards and routing discrepancy reports. |
| 4 | Meaning | varchar(200) | YES | NULL | CODE-BACKED | Human-readable description of the routing criterion. Used in audit reports and admin UIs to explain routing decisions to operations staff. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints defined, but semantically:
- `FundingTypeID` -> `Dictionary.FundingType` (implicit, value=1 is CreditCard)

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | RoutingReasonID | FK (implicit) | Records which routing criterion assigned this deposit to its depot |
| Billing.CreditCardRoutingTransactionsVerification | RoutingReasonID | Read | Validates routing of recent CC deposits against configured rules |
| Billing.vDeposit | RoutingReasonID | Join | View joining deposit with routing reason for reporting |
| Billing.DepositAdd | RoutingReasonID | Write | Sets RoutingReasonID when creating a new deposit |
| Billing.DepositUpdate | RoutingReasonID | Write | May update RoutingReasonID on deposit correction |

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies - static dictionary table on DICTIONARY filegroup.

---

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | FK on RoutingReasonID (records routing decision) |
| Billing.CreditCardRoutingTransactionsVerification | Stored Procedure | Validates routing correctness of recent CC deposits |
| Billing.DepositAdd | Stored Procedure | Sets RoutingReasonID when creating deposit |
| Billing.vDeposit | View | Joins to expose routing reason name in deposit view |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_RoutingReason | CLUSTERED PK | RoutingReasonID ASC | - | - | Active; FILLFACTOR=95; filegroup DICTIONARY |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RoutingReason | PRIMARY KEY CLUSTERED | One row per routing reason ID |

---

## 8. Sample Queries

### 8.1 View all routing reasons

```sql
SELECT RoutingReasonID, FundingTypeID, RoutingReason, Meaning
FROM Billing.RoutingReason WITH (NOLOCK)
ORDER BY RoutingReasonID
```

### 8.2 Distribution of routing reasons in recent deposits

```sql
SELECT
    rr.RoutingReason,
    COUNT(*) AS DepositCount
FROM Billing.Deposit d WITH (NOLOCK)
JOIN Billing.RoutingReason rr WITH (NOLOCK) ON rr.RoutingReasonID = d.RoutingReasonID
WHERE d.PaymentDate >= DATEADD(day, -7, GETUTCDATE())
GROUP BY rr.RoutingReason
ORDER BY DepositCount DESC
```

### 8.3 Find deposits with undefined routing (RoutingReasonID=0)

```sql
SELECT TOP 20
    d.DepositID,
    d.CID,
    d.DepotID,
    d.RoutingReasonID,
    d.PaymentDate,
    d.Amount
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.RoutingReasonID = 0  -- Undefined routing
  AND d.PaymentDate >= DATEADD(hour, -24, GETUTCDATE())
ORDER BY d.PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.RoutingReason | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.RoutingReason.sql*
