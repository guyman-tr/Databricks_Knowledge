# History.RolloverFeeMarkup

> Audit log of changes to the global rollover fee markup values, recording each update to the Buy or Sell markup applied on top of base rollover fees across all instruments.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on ID) |

---

## 1. Business Meaning

This table is an **OUTPUT INTO audit log** maintained by `Trade.UpdateRolloverFeeMarkup`. Whenever the global rollover fee markup is changed in `Maintenance.Feature`, the SQL Server OUTPUT clause captures the before and after values and inserts them here.

The rollover fee markup system works as follows: eToro applies a global markup on top of the base rollover fee for all instruments. Two markup values exist:
- **FeatureID 100050** = Buy markup (applied to long positions' overnight/weekend rollover fees)
- **FeatureID 100051** = Sell markup (applied to short positions' overnight/weekend rollover fees)

`IsBuy=1` identifies which markup was changed. `PreviousValue` captures the old markup before the update; `NewValue` captures what it was changed to. This enables auditing: who changed the global rollover markup from what to what and when.

The table currently has 0 rows, indicating the markup values have not been changed via `Trade.UpdateRolloverFeeMarkup` in this environment.

---

## 2. Business Logic

### 2.1 Rollover Fee Markup Change Audit

**What**: Records each time an operator changes the global rollover fee markup (buy or sell direction).

**Columns/Parameters Involved**: `IsBuy`, `PreviousValue`, `NewValue`, `UpdatedByUser`

**Rules**:
- `Trade.UpdateRolloverFeeMarkup` only logs a change if the new value differs from the current value: `WHERE [Value] != @RolloverFeeMarkup`
- If no change (new value equals current), no row is inserted - preventing duplicate audit entries
- `IsBuy=1` -> Buy markup changed (FeatureID 100050); `IsBuy=0` -> Sell markup changed (FeatureID 100051)
- The actual markup values are stored in `Maintenance.Feature.[Value]`; this table only stores the change history

**Diagram**:
```
Trade.UpdateRolloverFeeMarkup(@IsBuy, @RolloverFeeMarkup, @UpdatedByUser):
  UPDATE Maintenance.Feature
  SET Value = @RolloverFeeMarkup
  OUTPUT (IsBuy, NewValue, PreviousValue, UpdatedByUser, UpdatedAt)
  INTO History.RolloverFeeMarkup
  WHERE FeatureID = IIF(@IsBuy=1, 100050, 100051)
    AND Value != @RolloverFeeMarkup
```

---

## 3. Data Overview

The table has no rows in production. No representative rows available.

| ID | IsBuy | NewValue | PreviousValue | UpdatedByUser | UpdatedAt | Meaning |
|---|---|---|---|---|---|---|
| (no rows) | - | - | - | - | - | No rollover fee markup changes have been recorded; current markup values are in Maintenance.Feature (FeatureID 100050/100051) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key, auto-incremented. Uniquely identifies each rollover fee markup change event. |
| 2 | IsBuy | bit | NO | - | VERIFIED | Identifies which markup direction was changed. 1=Buy markup (FeatureID 100050 in Maintenance.Feature, applied to long/buy overnight and weekend rollover fees); 0=Sell markup (FeatureID 100051, applied to short/sell direction fees). From OUTPUT clause: `@IsBuy as IsBuy`. |
| 3 | NewValue | decimal(16,8) | NO | - | VERIFIED | The new markup value that was applied, captured from the `@RolloverFeeMarkup` parameter. Sourced from OUTPUT as `@RolloverFeeMarkup as NewValue`. High precision (16,8) allows fine-grained markup adjustments. |
| 4 | PreviousValue | decimal(16,8) | NO | - | VERIFIED | The markup value that existed before this change, captured from the DELETED virtual table in the OUTPUT clause: `Convert(decimal(16,8), deleted.Value)`. Enables full delta tracking: `NewValue - PreviousValue = markup change`. |
| 5 | UpdatedByUser | varchar(50) | NO | - | VERIFIED | Username or identifier of the operator who initiated the markup change, from the `@UpdatedByUser` parameter. Sourced from OUTPUT as `@UpdatedByUser as UpdateByUser` (note the column alias typo in the OUTPUT clause is "UpdateByUser" but the column is "UpdatedByUser"). |
| 6 | UpdatedAt | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the markup change was applied. Captured from OUTPUT as `GetUtcDate() as UpdateAt`. Default constraint also provides getutcdate() as a safety fallback. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IsBuy (=1) | Maintenance.Feature (FeatureID 100050) | Implicit | Buy rollover fee markup; the value being changed is stored in Maintenance.Feature.Value for FeatureID=100050. |
| IsBuy (=0) | Maintenance.Feature (FeatureID 100051) | Implicit | Sell rollover fee markup; stored in Maintenance.Feature.Value for FeatureID=100051. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateRolloverFeeMarkup | OUTPUT INTO | Writer | Inserts rows via OUTPUT clause when Maintenance.Feature is updated for rollover markup FeatureIDs. |
| Trade.GetRolloverFeeMarkups | SELECT | Reader | Reads this table to return historical markup change records. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RolloverFeeMarkup (table)
  (leaf - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateRolloverFeeMarkup | Procedure | Inserts via OUTPUT INTO when markup is changed in Maintenance.Feature |
| Trade.GetRolloverFeeMarkups | Procedure | Reads historical markup changes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RolloverFeeMarkup | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RolloverFeeMarkup | PRIMARY KEY | Uniqueness on ID. CLUSTERED. FILLFACTOR=90. |
| DF_RolloverFeeMarkup_UpdatedAt | DEFAULT | UpdatedAt defaults to getutcdate() on INSERT. |

---

## 8. Sample Queries

### 8.1 View all rollover fee markup changes
```sql
SELECT
    ID,
    CASE IsBuy WHEN 1 THEN 'Buy (FeatureID 100050)' ELSE 'Sell (FeatureID 100051)' END AS MarkupDirection,
    PreviousValue,
    NewValue,
    NewValue - PreviousValue AS Delta,
    UpdatedByUser,
    UpdatedAt
FROM [History].[RolloverFeeMarkup] WITH (NOLOCK)
ORDER BY UpdatedAt DESC
```

### 8.2 Track buy vs sell markup changes over time
```sql
SELECT
    IsBuy,
    UpdatedAt,
    PreviousValue,
    NewValue,
    UpdatedByUser
FROM [History].[RolloverFeeMarkup] WITH (NOLOCK)
WHERE IsBuy = @IsBuy
ORDER BY UpdatedAt DESC
```

### 8.3 Get current markup values from source
```sql
SELECT
    FeatureID,
    CASE FeatureID
        WHEN 100050 THEN 'Buy Rollover Markup'
        WHEN 100051 THEN 'Sell Rollover Markup'
    END AS MarkupType,
    CAST([Value] AS decimal(16,8)) AS CurrentMarkup
FROM [Maintenance].[Feature] WITH (NOLOCK)
WHERE FeatureID IN (100050, 100051)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RolloverFeeMarkup | Type: Table | Source: etoro/etoro/History/Tables/History.RolloverFeeMarkup.sql*
