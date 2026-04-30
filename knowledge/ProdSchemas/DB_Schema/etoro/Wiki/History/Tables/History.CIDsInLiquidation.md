# History.CIDsInLiquidation

> Active audit log of completed account liquidation windows - records each customer's liquidation period (StartTime to EndTime) and whether it was BSL-triggered or manual.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (CID, StartTime) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CIDsInLiquidation records the complete history of account liquidation events. When a customer's account enters the liquidation process - either triggered by BSL (Balance Stop Loss) automatically or initiated manually by operations - the customer is added to Trade.CIDsInLiquidation. When the liquidation process ends (successfully or otherwise), Trade.CIDsInLiquidationRemove deletes them from the live table and captures the completed liquidation window here.

Each row captures: which customer (CID), when liquidation started (StartTime), what triggered it (AccountLiquidationAcionTypeID), and when it ended (EndTime = GETUTCDATE() at delete time).

This is an **active, continuously-written** table. 13,198 rows as of 2026-03-19, with records as recent as 2026-03-17. The vast majority (13,123 rows = 99.4%) are BSL-triggered; only 75 rows are manual liquidations.

Note: Column name `AccountLiquidationAcionTypeID` has a typo ("Acion" instead of "Action") - this typo is present in both Trade.CIDsInLiquidation and this History table, as well as in Dictionary.AccountLiquidationActionType.ActionTypeID. It is a historic naming bug propagated consistently.

---

## 2. Business Logic

### 2.1 Liquidation Window Capture

**What**: Records each completed customer account liquidation event.

**Columns/Parameters Involved**: `CID`, `StartTime`, `AccountLiquidationAcionTypeID`, `EndTime`

**Rules**:
- ADD to liquidation: Trade.CIDsInLiquidationAdd(@CID, @LiquidationActionTypeID) -> INSERT Trade.CIDsInLiquidation (StartTime=GETUTCDATE())
- REMOVE from liquidation: Trade.CIDsInLiquidationRemove(@CID) ->
  - Calls Customer.SetBalanceDataFix to recalculate BSLRealFunds after liquidation
  - DELETE Trade.CIDsInLiquidation OUTPUT deleted.CID, deleted.StartTime, deleted.AccountLiquidationAcionTypeID, GETUTCDATE() INTO History.CIDsInLiquidation
- EndTime = GETUTCDATE() at remove time
- Liquidation duration = EndTime - StartTime (ranges from ~1 second to ~20 minutes in observed data)

### 2.2 Liquidation Action Types

| AccountLiquidationAcionTypeID | Description | Rows in History |
|------------------------------|-------------|-----------------|
| 1 | Manual | 75 (0.6%) |
| 2 | BSL | 13,123 (99.4%) |

BSL-triggered liquidations (type 2) are overwhelmingly dominant. Manual liquidations (type 1) are rare administrative interventions.

---

## 3. Data Overview

| CID | StartTime | AccountLiquidationAcionTypeID | EndTime | Duration |
|-----|-----------|------------------------------|---------|---------|
| 3739199 | 2026-03-17 08:47 | 1 (Manual) | 2026-03-17 08:51 | ~4 min |
| 3739199 | 2026-03-17 07:57 | 1 (Manual) | 2026-03-17 08:17 | ~20 min |
| 3739199 | 2026-03-16 17:10 | 1 (Manual) | 2026-03-16 17:10 | ~1 sec |
| 24416936 | 2026-03-16 15:25 | 2 (BSL) | 2026-03-16 15:25 | ~5 sec |

13,198 rows total | ACTIVE table (latest: 2026-03-17)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID whose account underwent liquidation. PK component. Same customer can appear multiple times if liquidated on different occasions. Implicit FK to Customer.CustomerStatic. |
| 2 | StartTime | datetime | NO | - | VERIFIED | UTC timestamp when the liquidation process began. Copied from Trade.CIDsInLiquidation.StartTime via DELETE OUTPUT. PK component. |
| 3 | AccountLiquidationAcionTypeID | int | NO | - | VERIFIED | What triggered the liquidation. FK to Dictionary.AccountLiquidationActionType. Values: 1=Manual, 2=BSL. Note: column name has a typo ("Acion" vs "Action") - consistent across all related tables. |
| 4 | EndTime | datetime | NO | - | VERIFIED | UTC timestamp when the liquidation process ended. Set to GETUTCDATE() in Trade.CIDsInLiquidationRemove at delete time. Duration = EndTime - StartTime. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | The customer who was liquidated. |
| AccountLiquidationAcionTypeID | Dictionary.AccountLiquidationActionType | Implicit | Liquidation trigger type: 1=Manual, 2=BSL. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CIDsInLiquidationRemove | CID, StartTime | Writer | Sole writer - captures completed liquidation via DELETE OUTPUT. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CIDsInLiquidation (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CIDsInLiquidationRemove | Stored Procedure | Writer - captures liquidation end events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryCIDsInLiquidation | CLUSTERED PK | CID ASC, StartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryCIDsInLiquidation | PRIMARY KEY CLUSTERED | (CID, StartTime), FILLFACTOR=95 |

---

## 8. Sample Queries

### 8.1 Get liquidation history for a customer
```sql
SELECT CID, StartTime, EndTime,
       AccountLiquidationAcionTypeID,
       DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds
FROM History.CIDsInLiquidation WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY StartTime DESC;
```

### 8.2 Get recent BSL liquidations (last 7 days)
```sql
SELECT CID, StartTime, EndTime,
       DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds
FROM History.CIDsInLiquidation WITH (NOLOCK)
WHERE AccountLiquidationAcionTypeID = 2
  AND StartTime >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY StartTime DESC;
```

### 8.3 Check if customer is currently in liquidation (live state)
```sql
-- Current liquidation state is in Trade.CIDsInLiquidation
SELECT CID, StartTime, AccountLiquidationAcionTypeID
FROM Trade.CIDsInLiquidation WITH (NOLOCK)
WHERE CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CIDsInLiquidation | Type: Table | Source: etoro/etoro/History/Tables/History.CIDsInLiquidation.sql*
