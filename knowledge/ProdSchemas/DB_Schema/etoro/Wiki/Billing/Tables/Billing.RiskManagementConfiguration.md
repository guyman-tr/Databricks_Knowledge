# Billing.RiskManagementConfiguration

> Configuration table defining fraud detection thresholds for ACH and PWMB payment methods - triggers velocity (frequency) and aggregated amount limits that block further deposits when exceeded.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 2 (PK + 1 UNIQUE NCI) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.RiskManagementConfiguration defines the fraud prevention thresholds for bank-transfer payment methods (ACH and PWMB). For each funding type, two types of rules can be configured: velocity limits (how many deposits are allowed within a time window) and aggregated amount limits (maximum total deposit amount within a time window).

When a customer attempts a deposit via ACH or PWMB, the risk management layer reads this configuration and checks whether the customer's recent deposit activity exceeds the configured thresholds. If it does, the deposit is blocked and a specific RiskManagementStatus is assigned.

**4 rows** covering 2 funding types (ACH=29, PWMB=32) x 2 check types (velocity=50, amount=51):
- ACH: Block if > 2 deposits OR > $10,000 in any 24-hour window
- PWMB: Block if > 30 deposits OR > $20,000 in any 24-hour window

All 4 rows are active. MinAmount and MaxAmount are not used in current configuration.

---

## 2. Business Logic

### 2.1 Velocity Check (FundingTypeVelocity)

**What**: Limits the number of deposits a customer can make with a specific payment method within a rolling time window.

**Columns/Parameters Involved**: `FundingTypeID`, `RiskManagementStatusID`=50, `Threshold`, `TimeUnitInterval`, `Active`

**Rules**:
- If COUNT(deposits via FundingTypeID in last TimeUnitInterval hours) > Threshold -> BLOCK
- ACH (FundingTypeID=29): Threshold=2, TimeUnitInterval=24 -> max 2 ACH deposits per 24 hours
- PWMB (FundingTypeID=32): Threshold=30, TimeUnitInterval=24 -> max 30 PWMB deposits per 24 hours
- Blocked deposits receive RiskManagementStatusID=50 (FundingTypeVelocity)

### 2.2 Aggregated Amount Check (FundingTypeAggregatedAmount)

**What**: Limits the total monetary amount a customer can deposit via a specific payment method within a rolling time window.

**Columns/Parameters Involved**: `FundingTypeID`, `RiskManagementStatusID`=51, `Threshold`, `TimeUnitInterval`, `Active`

**Rules**:
- If SUM(deposit amounts via FundingTypeID in last TimeUnitInterval hours) > Threshold -> BLOCK
- ACH (FundingTypeID=29): Threshold=10000 ($10,000), TimeUnitInterval=24 -> max $10K ACH per 24 hours
- PWMB (FundingTypeID=32): Threshold=20000 ($20,000), TimeUnitInterval=24 -> max $20K PWMB per 24 hours
- Blocked deposits receive RiskManagementStatusID=51 (FundingTypeAggregatedAmount)

**Configuration matrix**:
```
FundingTypeID  | Check Type                    | Threshold | Window | Block Status
---------------|-------------------------------|-----------|--------|---------------------
ACH (29)       | Velocity (count)              | 2         | 24h    | 50 (FundingTypeVelocity)
ACH (29)       | Aggregated Amount             | $10,000   | 24h    | 51 (FundingTypeAggregatedAmount)
PWMB (32)      | Velocity (count)              | 30        | 24h    | 50 (FundingTypeVelocity)
PWMB (32)      | Aggregated Amount             | $20,000   | 24h    | 51 (FundingTypeAggregatedAmount)
```

---

## 3. Data Overview

| ID | FundingTypeID | FundingType | RiskManagementStatusID | Status Name | Threshold | TimeUnitInterval | IDList | Active |
|----|--------------|-------------|----------------------|-------------|-----------|-----------------|--------|--------|
| 1 | 29 | ACH | 51 | FundingTypeAggregatedAmount | $10,000 | 24h | 2, 13 | true |
| 2 | 29 | ACH | 50 | FundingTypeVelocity | 2 deposits | 24h | 2, 13 | true |
| 3 | 32 | PWMB | 51 | FundingTypeAggregatedAmount | $20,000 | 24h | 2, 13 | true |
| 4 | 32 | PWMB | 50 | FundingTypeVelocity | 30 deposits | 24h | 2, 13 | true |

IDList="2, 13" for all rows. This appears to reference downstream identifiers used by the risk management application layer (specific action IDs, country codes, or routing targets - exact meaning requires application code review).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key, auto-incremented. |
| 2 | FundingTypeID | INT | YES | - | CODE-BACKED | Payment method this rule applies to. Implicit FK to Dictionary.FundingType(FundingTypeID). Currently only ACH(29) and PWMB(32) are configured. NULL allowed but would result in a rule that applies to no specific funding type. |
| 3 | RiskManagementStatusID | INT | NO | - | CODE-BACKED | The risk status to apply when the threshold is exceeded. FK to Dictionary.RiskManagementStatus(RiskManagementStatusID). 50=FundingTypeVelocity (frequency breach), 51=FundingTypeAggregatedAmount (volume breach). |
| 4 | Active | BIT | NO | 0 | CODE-BACKED | Whether this rule is currently enabled. Default=0 (inactive). All current rows are Active=1. Set to 0 to disable a rule without deleting it. |
| 5 | Threshold | INT | YES | - | CODE-BACKED | The numeric limit for the check. For velocity rules (status=50): maximum number of deposits allowed. For amount rules (status=51): maximum total deposit amount in the time window. NULL would disable the threshold check. |
| 6 | TimeUnitInterval | INT | YES | - | CODE-BACKED | Rolling time window in hours for the threshold calculation. All current rows = 24 (24-hour rolling window). NULL would disable time-bounding. |
| 7 | MinAmount | INT | YES | - | CODE-BACKED | Minimum individual deposit amount for this rule to apply. NULL for all current rows - no lower bound filtering. Would allow rules that only trigger for deposits above a certain size. |
| 8 | MaxAmount | INT | YES | - | CODE-BACKED | Maximum individual deposit amount for this rule to apply. NULL for all current rows - no upper bound filtering. Would allow rules that only apply below a certain deposit size. |
| 9 | IDList | VARCHAR(100) | YES | - | CODE-BACKED | Comma-separated list of IDs used by the risk management application layer. Currently "2, 13" for all rows. Exact semantics require application code review - likely references action IDs, notification targets, or routing rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit FK (no DDL constraint) | Links the rule to the payment method being monitored. |
| RiskManagementStatusID | Dictionary.RiskManagementStatus | Implicit FK (no DDL constraint) | References the risk status to assign when the threshold is exceeded. Values: 50=FundingTypeVelocity, 51=FundingTypeAggregatedAmount. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetRiskManagementConfiguration | - | READER | Simple SELECT * - returns all rows to the application for runtime configuration loading. Called by the risk management service to load its rule set. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RiskManagementConfiguration (table)
|- Dictionary.FundingType (implicit - no DDL FK)
└-- Dictionary.RiskManagementStatus (implicit - no DDL FK)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingType | Table | Implicit FK - FundingTypeID identifies the payment method |
| Dictionary.RiskManagementStatus | Table | Implicit FK - RiskManagementStatusID identifies the block reason |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetRiskManagementConfiguration | Stored Procedure | READER - returns all configuration rows to the application |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RiskManagementCofiguration | CLUSTERED PK | ID ASC | - | - | Active |
| UNQ_FundingTypeID_RiskManagmentStatusID | NONCLUSTERED UNIQUE | FundingTypeID ASC, RiskManagementStatusID ASC | - | - | Active |

Index options: FILLFACTOR=95. Note: PK constraint name has typo "Cofiguration" (missing 'n').

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RiskManagementCofiguration | PRIMARY KEY CLUSTERED | ID must be unique |
| UNQ_FundingTypeID_RiskManagmentStatusID | UNIQUE NONCLUSTERED | (FundingTypeID, RiskManagementStatusID) must be unique - one rule per check type per funding type |
| DF_BillingRiskManagementConfiguration_Active | DEFAULT | Active defaults to 0 (inactive) on INSERT |

---

## 8. Sample Queries

### 8.1 View full risk configuration with names

```sql
SELECT
    rmc.ID,
    rmc.FundingTypeID,
    ft.Name AS FundingTypeName,
    rmc.RiskManagementStatusID,
    rms.Name AS RiskStatusName,
    rmc.Active,
    rmc.Threshold,
    rmc.TimeUnitInterval,
    rmc.MinAmount,
    rmc.MaxAmount,
    rmc.IDList
FROM [Billing].[RiskManagementConfiguration] rmc WITH (NOLOCK)
LEFT JOIN [Dictionary].[FundingType] ft WITH (NOLOCK) ON ft.FundingTypeID = rmc.FundingTypeID
LEFT JOIN [Dictionary].[RiskManagementStatus] rms WITH (NOLOCK) ON rms.RiskManagementStatusID = rmc.RiskManagementStatusID
ORDER BY rmc.FundingTypeID, rmc.RiskManagementStatusID
```

### 8.2 Find active rules for a specific funding type

```sql
DECLARE @FundingTypeID INT = 29  -- ACH

SELECT
    rmc.*,
    rms.Name AS StatusName
FROM [Billing].[RiskManagementConfiguration] rmc WITH (NOLOCK)
INNER JOIN [Dictionary].[RiskManagementStatus] rms WITH (NOLOCK) ON rms.RiskManagementStatusID = rmc.RiskManagementStatusID
WHERE rmc.FundingTypeID = @FundingTypeID
  AND rmc.Active = 1
ORDER BY rmc.RiskManagementStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources directly reference this table.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.4/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.RiskManagementConfiguration | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.RiskManagementConfiguration.sql*
