# Trade.PositionEditTakeProfit25102021

> Dated variant of Trade.PositionEditTakeProfit (snapshot: Oct 25 2021) that routes TP updates through Trade.UpdateTree25102021 and uses error 60004 for position-not-found.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (partition key: @PositionID%50 on Trade.Position) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionEditTakeProfit25102021 is a versioned snapshot of Trade.PositionEditTakeProfit, created on October 25, 2021 as part of a parallel-deployment or safe-migration strategy. The "25102021" suffix (DDMMYYYY) is a date stamp common in this codebase for procedure variants that run alongside the original during feature rollouts or A/B testing of architectural changes.

The functional behavior is identical to Trade.PositionEditTakeProfit with two differences:
1. **Tree update target**: calls Trade.UpdateTree25102021 instead of Trade.UpdateTree - the dated variant of the tree update procedure
2. **Position-not-found error**: raises 60004 instead of 60115 when the position is not found
3. **No @IsNoTakeProfit parameter**: this variant predates the "remove TP" feature added to the main SP

No callers were found in the SSDT repo for this variant. It is likely inactive or retained for rollback capability.

---

## 2. Business Logic

Identical to Trade.PositionEditTakeProfit except:

### 2.1 Differences from Trade.PositionEditTakeProfit

| Aspect | Trade.PositionEditTakeProfit | This SP (25102021 variant) |
|--------|------------------------------|---------------------------|
| Tree update SP | Trade.UpdateTree | Trade.UpdateTree25102021 |
| Position-not-found error | 60115 | 60004 |
| @IsNoTakeProfit parameter | YES (remove TP) | NO (not present) |
| Callers in SSDT | None found | None found |

### 2.2 Shared Logic (from Trade.PositionEditTakeProfit)

1. **Position existence check**: SELECT ParentPositionID, TreeID, MirrorID FROM Trade.Position WHERE PositionID=@PositionID AND @PositionID%50=PartitionCol (NOLOCK)
2. **Mirror protection**: IF ParentPositionID > 0 AND MirrorID > 0 AND @IsInitiatedByUser <> 0 -> RAISERROR(60084, 16, 1)
3. **TP tree update**: EXEC Trade.UpdateTree25102021 @TreeID, @StopRate=NULL, @LimitRate OUTPUT, @CloseOnEndOfWeek=NULL, @FromEditProd=1, @Credit=0, @SessionID, @ClientRequestGuid
4. **Error handling**: @ErrOut OUTPUT, RAISERROR(60000), nested transaction support

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

Same parameters as Trade.PositionEditTakeProfit except @IsNoTakeProfit is NOT present in this variant.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position to edit. Partition key: @PositionID%50. |
| 2 | @LimitRate | dtPrice | NO | - | CODE-BACKED | New Take Profit rate. INPUT/OUTPUT to Trade.UpdateTree25102021. |
| 3 | @NetProfit | MONEY | NO | - | CODE-BACKED | Declared but unused. Comment notes 'in cents'. |
| 4 | @XMLResult | XML | NO | - | CODE-BACKED | OUTPUT. Declared but never populated. Vestigial. |
| 5 | @LastOpPriceRate | dtPrice | YES | NULL | CODE-BACKED | Declared but unused. Present for API compatibility. |
| 6 | @LastOpPriceRateID | BIGINT | YES | NULL | CODE-BACKED | Declared but unused. |
| 7 | @LastOpConversionRate | dtPrice | YES | NULL | CODE-BACKED | Declared but unused. |
| 8 | @LastOpConversionRateID | BIGINT | YES | NULL | CODE-BACKED | Declared but unused. |
| 9 | @IsInitiatedByUser | INT | NO | - | CODE-BACKED | 1=user-initiated, 0=system-initiated. Controls mirror-position protection check. |
| 10 | @ErrOut | NVARCHAR(4000) | YES | '' | CODE-BACKED | OUTPUT. Error context string on failure. |
| 11 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Session identifier for audit. |
| 12 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Idempotency key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (NOLOCK) | Trade.Position | DML read | ParentPositionID, TreeID, MirrorID with partition elimination |
| EXEC | Trade.UpdateTree25102021 | Procedure call | Dated variant of UpdateTree for TP propagation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in SSDT repo. Likely inactive or retained for rollback.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionEditTakeProfit25102021 (procedure)
+-- Trade.Position (view/table) - existence check and context read
+-- Trade.UpdateTree25102021 (procedure) - TP propagation (dated variant)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View/Table | SELECT ParentPositionID, TreeID, MirrorID |
| Trade.UpdateTree25102021 | Stored Procedure | EXEC to propagate LimitRate change through tree |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Error 60004: position not found (vs 60115 in the main PositionEditTakeProfit SP)
- Error 60084: mirrored position cannot be user-modified
- No @IsNoTakeProfit support - cannot remove TP via this variant

---

## 8. Sample Queries

### 8.1 Set a take profit level (via dated variant)

```sql
DECLARE @LimitRate dtPrice = 1.1200;
DECLARE @XMLResult XML;
DECLARE @ErrOut NVARCHAR(4000) = '';
EXEC Trade.PositionEditTakeProfit25102021
    @PositionID        = 123456789,
    @LimitRate         = @LimitRate OUTPUT,
    @NetProfit         = 0,
    @XMLResult         = @XMLResult OUTPUT,
    @IsInitiatedByUser = 1,
    @SessionID         = 999,
    @ErrOut            = @ErrOut OUTPUT;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionEditTakeProfit25102021 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionEditTakeProfit25102021.sql*
