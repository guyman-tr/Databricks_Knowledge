# Trade.ChangeMirrorAmount_testJunk

> DEPRECATED test/debug procedure - a diagnostic version of Trade.ChangeMirrorAmount with SELECT statements for debugging and most write operations commented out.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @MirrorID, @DeltaAmountInCents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ChangeMirrorAmount_testJunk is a test/debug variant of the CopyTrader mirror balance change procedure. Unlike the production version, this procedure includes diagnostic SELECT statements (outputting intermediate values like TotalMirrorFunds, CID, RetVal) and has most write operations (UPDATE Trade.Mirror, INSERT History.Mirror, EXEC Customer.SetBalance) commented out.

This procedure exists as a DBA debugging tool - it runs the validation logic and amount calculations without actually modifying data, allowing developers to test what would happen without side effects. The "Junk" suffix indicates it is not part of the production codebase.

Key differences from production: (1) calculates TotalMirrorFunds using aggregation on Trade.Position (older method), (2) outputs debug SELECTs, (3) all DML against Trade.Mirror and History.Mirror is commented out, (4) calls Trade.ValidateSmallAmountsRangePercentage for deposit validation.

---

## 2. Business Logic

### 2.1 Mirror Balance Validation (Debug Mode)

**What**: Runs all validations of a mirror amount change without executing the change.

**Columns/Parameters Involved**: `@CID`, `@MirrorID`, `@DeltaAmountInCents`

**Rules**:
- Calculates TotalMirrorFunds by summing Trade.Position amounts for child positions (legacy method using SUM on Position table)
- Validates mirror exists and is active (errors 60050, 60051)
- Validates sufficient funds for withdrawal (60052) and deposit (60054)
- Validates CID ownership (60064)
- For deposits: calls Trade.ValidateSmallAmountsRangePercentage to check minimum thresholds
- Debug SELECTs output: CID, TotalMirrorFunds, MirrorTypeID, Credit, RealizedEquity, RetVal

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to validate against Trade.Mirror.CID. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | The CopyTrader mirror to validate. |
| 3 | @DeltaAmountInCents | dtPrice | NO | - | CODE-BACKED | Amount to simulate adding/removing in cents. Positive = deposit, negative = withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | SELECT | Reads mirror state (IsActive, Amount, MirrorTypeID) |
| @CID | Customer.Customer | SELECT | Reads Credit and RealizedEquity for validation |
| @CID, @MirrorID | Trade.Position | SELECT | Sums child position amounts for TotalMirrorFunds calculation |
| (calls) | Trade.ValidateSmallAmountsRangePercentage | Function call | Validates minimum deposit thresholds |

### 5.2 Referenced By (other objects point to this)

This is a deprecated test procedure. No production code should reference it.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ChangeMirrorAmount_testJunk (procedure)
+-- Trade.Mirror (table)
+-- Customer.Customer (table)
+-- Trade.Position (view)
+-- Trade.ValidateSmallAmountsRangePercentage (function)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | SELECT mirror state |
| Customer.Customer | Table | SELECT credit/equity |
| Trade.Position | View | SELECT SUM(Amount) for child positions |
| Trade.ValidateSmallAmountsRangePercentage | Function | Called for deposit validation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none) | - | Deprecated test procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH | Error Handling | RAISERROR on validation failure; commented-out write operations |

---

## 8. Sample Queries

### 8.1 Test mirror amount change without side effects

```sql
EXEC Trade.ChangeMirrorAmount_testJunk
    @CID = 12345,
    @MirrorID = 67890,
    @DeltaAmountInCents = 10000;
```

### 8.2 Check mirror state directly

```sql
SELECT MirrorID, CID, Amount, IsActive, MirrorTypeID, RealizedEquity
FROM   Trade.Mirror WITH (NOLOCK)
WHERE  MirrorID = @MirrorID;
```

### 8.3 Check child position totals for a mirror

```sql
SELECT CID, MirrorID, SUM(Amount) AS TotalPositionAmount
FROM   Trade.Position WITH (NOLOCK)
WHERE  CID = @CID
       AND MirrorID = @MirrorID
       AND ISNULL(ParentPositionID, 0) <> 0
GROUP BY CID, MirrorID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ChangeMirrorAmount_testJunk | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ChangeMirrorAmount_testJunk.sql*
