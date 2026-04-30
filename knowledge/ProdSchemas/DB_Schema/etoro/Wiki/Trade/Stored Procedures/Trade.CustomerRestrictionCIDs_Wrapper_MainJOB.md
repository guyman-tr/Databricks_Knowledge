# Trade.CustomerRestrictionCIDs_Wrapper_MainJOB

> Scheduled job that identifies high-risk customers based on DWH risk scores, waits for daily DWH data refresh, excludes professional accounts (AccountTypeID=9), and synchronizes trading restrictions via Trade.CustomerRestrictionCIDs_Wrapper.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters - scheduled job) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CustomerRestrictionCIDs_Wrapper_MainJOB is a scheduled job procedure that automatically restricts trading for customers whose risk score exceeds a configured threshold. It implements a risk-score-based trading restriction system using data from the Data Warehouse (DWH).

The procedure:
1. **Reads configuration**: Gets the lookback window (Internal.RiskScoreConfig ConfigID=1) and minimum risk score threshold (ConfigID=2)
2. **Waits for DWH refresh**: Polls RiskScore_FROMDWH every 15 minutes until the daily data is available, ensuring decisions are based on fresh data
3. **Identifies high-risk CIDs**: Selects customers whose average AvgSTD risk score over the lookback period exceeds the configured minimum
4. **Excludes professionals**: Removes AccountTypeID=9 (professional/institutional accounts) from the restriction list
5. **Synchronizes restrictions**: Calls Trade.CustomerRestrictionCIDs_Wrapper, which adds new restrictions and removes expired ones

This ensures that retail customers with elevated risk patterns are automatically restricted from certain trading operations, while professional accounts are exempt.

---

## 2. Business Logic

### 2.1 Configuration-Driven Risk Threshold

**What**: Uses Internal.RiskScoreConfig for dynamic configuration.

**Rules**:
- ConfigID=1: NumValue = number of days to look back for risk score aggregation
- ConfigID=2: NumValue = risk score level; joined to Internal.RiskScore to get MinValue threshold
- MinDate = TODAY - lookback days

### 2.2 DWH Data Freshness Wait

**What**: Ensures risk scores are from today's DWH refresh before proceeding.

**Rules**:
- Polls MAX(UpdateDate) from RiskScore_FROMDWH WHERE FullDate >= @MinDate
- Continues polling every 15 minutes if UpdateDate < today
- No timeout — will wait indefinitely for DWH data (relies on external monitoring)

### 2.3 Risk Score Aggregation

**What**: Computes average risk score per customer over the lookback period.

**Rules**:
- Source: RiskScore_FROMDWH WHERE FullDate >= @MinDate
- GROUP BY CID, HAVING AVG(AvgSTD) >= @MinScore
- Only CIDs above the threshold are included in the restriction list

### 2.4 Professional Account Exclusion

**What**: Removes professional/institutional accounts from restrictions.

**Rules**:
- BackOffice.Customer.AccountTypeID = 9 → excluded
- DELETE FROM @CIDs WHERE CID IN (SELECT CID FROM BackOffice.Customer WHERE AccountTypeID=9)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters. It is a self-contained scheduled job.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Internal.RiskScoreConfig | SELECT | Reads lookback days and risk score level |
| FROM | Internal.RiskScore | SELECT | Resolves risk score level to MinValue threshold |
| FROM | RiskScore_FROMDWH | SELECT | DWH risk score data for CID aggregation |
| FROM | BackOffice.Customer | SELECT | Excludes professional accounts |
| EXEC | Trade.CustomerRestrictionCIDs_Wrapper | EXEC | Synchronizes the restriction set |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found in SSDT) | - | - | Called by SQL Agent scheduled job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CustomerRestrictionCIDs_Wrapper_MainJOB (procedure)
+-- Internal.RiskScoreConfig (table)
+-- Internal.RiskScore (table)
+-- RiskScore_FROMDWH (table/view - DWH data)
+-- BackOffice.Customer (table)
+-- Trade.CustomerRestrictionCIDs_Wrapper (procedure)
    +-- Trade.CustomerRestrictionSet_CIDs (procedure)
    +-- Trade.CustomerRestrictionRemove_CIDs (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.RiskScoreConfig | Table | SELECT - configuration parameters |
| Internal.RiskScore | Table | SELECT - risk score threshold resolution |
| RiskScore_FROMDWH | Table/View | SELECT - DWH risk data |
| BackOffice.Customer | Table | SELECT - account type exclusion |
| Trade.CustomerRestrictionCIDs_Wrapper | Procedure | EXEC - restriction sync |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT) | - | SQL Agent job |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DWH freshness | Blocking wait | Loops every 15 minutes until DWH data is current |
| No timeout | Risk | Procedure will wait indefinitely if DWH never refreshes |
| NOLOCK reads | Consistency | Uses NOLOCK on DWH and config tables |

---

## 8. Sample Queries

### 8.1 Preview current risk score configuration

```sql
SELECT  a.ConfigID, a.NumValue AS ConfigValue,
        b.RiskScore, b.MinValue AS Threshold
FROM    Internal.RiskScoreConfig a WITH (NOLOCK)
LEFT JOIN Internal.RiskScore b WITH (NOLOCK) ON a.NumValue = b.RiskScore AND a.ConfigID = 2
WHERE   a.ConfigID IN (1, 2);
```

### 8.2 Preview which CIDs would be restricted

```sql
DECLARE @MinDate DATE = DATEADD(DAY, -(SELECT NumValue FROM Internal.RiskScoreConfig WHERE ConfigID = 1), GETUTCDATE());
DECLARE @MinScore MONEY = (SELECT b.MinValue FROM Internal.RiskScoreConfig a JOIN Internal.RiskScore b ON a.NumValue = b.RiskScore WHERE a.ConfigID = 2);

SELECT  CID, AVG(AvgSTD) AS AvgRiskScore
FROM    RiskScore_FROMDWH WITH (NOLOCK)
WHERE   FullDate >= @MinDate
GROUP BY CID
HAVING AVG(AvgSTD) >= @MinScore;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CustomerRestrictionCIDs_Wrapper_MainJOB | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CustomerRestrictionCIDs_Wrapper_MainJOB.sql*
