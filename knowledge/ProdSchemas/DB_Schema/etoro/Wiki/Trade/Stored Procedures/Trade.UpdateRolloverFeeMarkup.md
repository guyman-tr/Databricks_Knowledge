# Trade.UpdateRolloverFeeMarkup

> Updates the global rollover fee markup (buy or sell direction) stored in Maintenance.Feature (FeatureID 100050 for buy, 100051 for sell), with change-detection (no-op if value unchanged) and history logging via OUTPUT clause into History.RolloverFeeMarkup.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsBuy (determines FeatureID 100050 or 100051) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Rollover fees applied to overnight positions consist of a base interest rate plus a markup. This markup is a global add-on applied across all leveraged overnight positions in the respective direction (buy or sell). The markup values are stored in Maintenance.Feature as configuration records:
- FeatureID 100050: Buy direction rollover fee markup
- FeatureID 100051: Sell direction rollover fee markup

This procedure allows operations to update either markup with full audit trail support. The OUTPUT clause captures the old and new values directly into History.RolloverFeeMarkup without a separate INSERT - an efficient pattern that ensures no update goes unlogged. The procedure is change-aware: if the new value equals the current value, no update (and no history record) is written.

No internal SP callers were found; called from the fee management tooling.

---

## 2. Business Logic

### 2.1 Direction-to-FeatureID Mapping

**What**: IsBuy determines which Feature record to update.

**Columns/Parameters Involved**: `@IsBuy`, `@FeatureID`, `Maintenance.Feature.FeatureID`

**Rules**:
- @IsBuy = 1 -> @FeatureID = 100050 (buy markup)
- @IsBuy = 0 -> @FeatureID = 100051 (sell markup)

### 2.2 Change-Detecting Update with OUTPUT History

**What**: The UPDATE only fires if the new value differs from the current value; the OUTPUT clause atomically records the change.

**Columns/Parameters Involved**: `Maintenance.Feature.Value`, `History.RolloverFeeMarkup`

**Rules**:
- `WHERE FeatureID = @FeatureID AND [Value] != @RolloverFeeMarkup` - no-op if value unchanged
- OUTPUT clause inserts into History.RolloverFeeMarkup: IsBuy, NewValue (=@RolloverFeeMarkup), PreviousValue (=deleted.Value cast to decimal(16,8)), UpdateByUser, UpdateAt (GETUTCDATE())
- If no row updated (@@ROWCOUNT = 0): no history record written; RETURN 0
- RETURN @rowcount: 1 if updated, 0 if no change

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsBuy | bit | NO | - | CODE-BACKED | Direction flag: 1 = buy markup (FeatureID 100050), 0 = sell markup (FeatureID 100051). Determines which Maintenance.Feature row is updated and recorded in the history log. |
| 2 | @RolloverFeeMarkup | decimal(16,8) | NO | - | CODE-BACKED | New markup value to apply. If equal to the current Maintenance.Feature.Value, no update is performed. Typical values are small decimals (e.g., 0.00050000 = 0.05%). |
| 3 | @UpdatedByUser | varchar(50) | NO | - | CODE-BACKED | Username or service name recorded in History.RolloverFeeMarkup.UpdateByUser for audit trail. |

**Return value**: INT - 1 if the markup was changed, 0 if the new value was the same as the current value (no-op).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID (100050/100051) | Maintenance.Feature | UPDATE | Sets Value to @RolloverFeeMarkup; no-op if value unchanged |
| Change record | History.RolloverFeeMarkup | INSERT (via OUTPUT) | Atomically records before/after values when update occurs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External fee management tooling | Application call | Caller | No internal SP callers found; called from rollover fee configuration system |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateRolloverFeeMarkup (procedure)
|- Maintenance.Feature (table) [UPDATE - FeatureID 100050 (buy) or 100051 (sell)]
+-- History.RolloverFeeMarkup (table) [INSERT via OUTPUT - change audit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | UPDATEd: Value column for FeatureID 100050 or 100051 (rollover fee markups) |
| History.RolloverFeeMarkup | Table | INSERTed via OUTPUT clause: IsBuy, NewValue, PreviousValue, UpdateByUser, UpdateAt |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Fee management tooling | Application | Calls to update global rollover fee markup for buy or sell direction |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Change detection | Logic | AND [Value] != @RolloverFeeMarkup - no UPDATE or history record if value unchanged |
| OUTPUT history | Design | History record inserted atomically within the UPDATE statement; no separate INSERT needed |
| Atomic transaction | TRY/CATCH | BEGIN TRANSACTION / COMMIT; ROLLBACK on error |
| RETURN @@ROWCOUNT | API | Caller receives 1 (updated) or 0 (no change) as return value |

---

## 8. Sample Queries

### 8.1 Update buy direction markup

```sql
DECLARE @RowsAffected int
EXEC @RowsAffected = Trade.UpdateRolloverFeeMarkup
    @IsBuy = 1,
    @RolloverFeeMarkup = 0.00050000,
    @UpdatedByUser = 'fee_admin'

SELECT @RowsAffected AS Changed  -- 1 if updated, 0 if same value
```

### 8.2 Update sell direction markup

```sql
EXEC Trade.UpdateRolloverFeeMarkup
    @IsBuy = 0,
    @RolloverFeeMarkup = 0.00060000,
    @UpdatedByUser = 'fee_admin'
```

### 8.3 Check current markup values and history

```sql
-- Current values
SELECT FeatureID, Value
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID IN (100050, 100051)

-- Recent changes
SELECT TOP 10
    rfm.IsBuy,
    rfm.PreviousValue,
    rfm.NewValue,
    rfm.UpdateByUser,
    rfm.UpdateAt
FROM History.RolloverFeeMarkup rfm WITH (NOLOCK)
ORDER BY rfm.UpdateAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateRolloverFeeMarkup | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateRolloverFeeMarkup.sql*
