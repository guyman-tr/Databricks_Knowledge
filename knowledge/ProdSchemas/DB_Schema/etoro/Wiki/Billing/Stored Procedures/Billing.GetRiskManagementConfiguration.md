# Billing.GetRiskManagementConfiguration

> Full-table SELECT returning all rows from Billing.RiskManagementConfiguration; used by the risk management service to load its ACH/PWMB fraud detection threshold rules into memory at startup or on refresh.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns all rows (currently 4) from Billing.RiskManagementConfiguration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRiskManagementConfiguration` is the configuration loader for eToro's ACH and PWMB fraud detection rule set. When the risk management service initializes or needs to refresh its rule cache, it calls this procedure to retrieve the full set of velocity and aggregated-amount thresholds.

The procedure is a thin wrapper over `Billing.RiskManagementConfiguration` - it returns all 4 currently configured rows unchanged. The application then uses these rows to evaluate whether a customer's recent deposit activity with ACH (FundingTypeID=29) or PWMB (FundingTypeID=32) exceeds the configured limits, blocking further deposits if it does.

Current configuration loaded by this procedure (all 4 rows, all Active=1):
- ACH: max 2 deposits per 24h (velocity); max $10,000 per 24h (amount)
- PWMB: max 30 deposits per 24h (velocity); max $20,000 per 24h (amount)

The `Active` column allows individual rules to be soft-disabled without deleting the configuration row; the application layer filters on this.

---

## 2. Business Logic

### 2.1 Full Configuration Load

**What**: Returns all configuration rows with no filtering or transformation.

**Columns/Parameters Involved**: All columns from `Billing.RiskManagementConfiguration`

**Rules**:
- No WHERE clause - all rows returned regardless of Active flag
- Application is responsible for filtering on `Active=1` when evaluating rules
- NOLOCK read - configuration data is infrequently updated; minor staleness is acceptable
- Returning all rows (including inactive) allows the application to display the full configuration matrix in admin UI

### 2.2 Rule Set Context (Inherited from Billing.RiskManagementConfiguration)

**What**: The returned rows define two types of checks per funding type.

**Rules**:
- `RiskManagementStatusID=50` (FundingTypeVelocity): applies when COUNT(deposits in TimeUnitInterval hours) > Threshold
- `RiskManagementStatusID=51` (FundingTypeAggregatedAmount): applies when SUM(deposit amounts in TimeUnitInterval hours) > Threshold
- Currently 4 rows: ACH velocity, ACH amount, PWMB velocity, PWMB amount
- All rows use TimeUnitInterval=24 (24-hour rolling window)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

None. This procedure takes no parameters.

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | - | CODE-BACKED | Surrogate PK of the rule row. |
| 2 | FundingTypeID | INT | YES | - | CODE-BACKED | Payment method this rule applies to. Currently 29=ACH or 32=PWMB. FK (implicit) to `Dictionary.FundingType`. |
| 3 | RiskManagementStatusID | INT | NO | - | CODE-BACKED | The risk block status to assign when threshold is exceeded. 50=FundingTypeVelocity (count breach), 51=FundingTypeAggregatedAmount (volume breach). FK (implicit) to `Dictionary.RiskManagementStatus`. |
| 4 | Active | BIT | NO | - | CODE-BACKED | Whether this rule is active. 1=enabled, 0=disabled. Application should filter on Active=1 for rule evaluation. All current rows are Active=1. |
| 5 | Threshold | INT | YES | - | CODE-BACKED | The limit value for the check. For velocity rules: maximum deposit count. For amount rules: maximum total deposit sum (USD). Current values: ACH velocity=2, ACH amount=10000, PWMB velocity=30, PWMB amount=20000. |
| 6 | TimeUnitInterval | INT | YES | - | CODE-BACKED | Rolling window size in hours. All current rows=24 (24-hour rolling window). |
| 7 | MinAmount | INT | YES | - | CODE-BACKED | Minimum individual deposit amount for this rule to apply. NULL for all current rows (no lower bound). |
| 8 | MaxAmount | INT | YES | - | CODE-BACKED | Maximum individual deposit amount for this rule to apply. NULL for all current rows (no upper bound). |
| 9 | IDList | VARCHAR(100) | YES | - | CODE-BACKED | Comma-separated IDs used by the risk management application layer for routing/action targeting. Currently "2, 13" for all rows. Exact semantics require application code review. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Billing.RiskManagementConfiguration | SELECT (full table) | Returns all risk threshold configuration rows |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Risk management service | (none) | EXEC | Loads fraud detection configuration at startup or on cache refresh |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRiskManagementConfiguration (procedure)
+-- Billing.RiskManagementConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RiskManagementConfiguration | Table | SELECT source for all fraud detection rule rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Risk management service | External | Configuration loading for ACH/PWMB deposit fraud detection |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No parameter filtering | Design | Returns ALL rows including inactive; caller is responsible for Active=1 filter |
| NOLOCK | Concurrency | Acceptable for configuration data with infrequent updates |
| SET NOCOUNT ON | Performance | Prevents extra row-count message in result |

---

## 8. Sample Queries

### 8.1 Load full risk configuration (equivalent to this procedure)
```sql
SELECT ID, FundingTypeID, RiskManagementStatusID, Active, Threshold,
       TimeUnitInterval, MinAmount, MaxAmount, IDList
FROM Billing.RiskManagementConfiguration WITH (NOLOCK);
```

### 8.2 View active rules only with resolved names
```sql
SELECT
    rmc.ID,
    ft.Name AS FundingType,
    rms.Name AS RiskStatus,
    rmc.Threshold,
    rmc.TimeUnitInterval AS WindowHours
FROM Billing.RiskManagementConfiguration rmc WITH (NOLOCK)
LEFT JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = rmc.FundingTypeID
LEFT JOIN Dictionary.RiskManagementStatus rms WITH (NOLOCK) ON rms.RiskManagementStatusID = rmc.RiskManagementStatusID
WHERE rmc.Active = 1
ORDER BY rmc.FundingTypeID, rmc.RiskManagementStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.2/10 (Elements: 9/10, Logic: 6/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRiskManagementConfiguration | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRiskManagementConfiguration.sql*
