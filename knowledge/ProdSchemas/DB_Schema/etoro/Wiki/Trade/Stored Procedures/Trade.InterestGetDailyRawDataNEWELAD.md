# Trade.InterestGetDailyRawDataNEWELAD

> Development variant of Trade.InterestGetDailyRawData with an alternate cashout calculation strategy: uses a materialized temp table with CROSS APPLY TOP 1 instead of ROW_NUMBER() in a CTE to resolve the most recent cashout status per (WithdrawID, FundingID) pair.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ListOfCids - TVP of CIDs to compute interest data for |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InterestGetDailyRawDataNEWELAD is a development/performance experiment variant of Trade.InterestGetDailyRawData. The name suffix "NEWELAD" appears to reference a developer or team who authored the alternative approach (not an acronym with documented business meaning). The output schema is identical to the base procedure; only the cashout calculation strategy differs.

The procedure exists as a candidate replacement for the production daily variant, testing whether materializing the most-recent-cashout-per-withdrawal lookup into a temp table (#a + CROSS APPLY) performs better than the ROW_NUMBER()-based CTE used in InterestGetDailyRawData. The base procedure and this variant are run and compared to validate correctness and performance before committing to a production change.

Data flow: Same as Trade.InterestGetDailyRawData. The calling service can swap between variants for A/B performance testing.

---

## 2. Business Logic

### 2.1 Steps 1-4 (Identical to Base Procedure)

**What**: Time window initialization, CID loading, customer snapshot, credit adjustment, and MinRealMoney computation are identical to Trade.InterestGetDailyRawData with one minor variation.

**Differences from base**:
- MinRealMoney UPDATE uses **INNER JOIN** instead of RIGHT JOIN on the subquery. The practical effect is the same for customers in #Snapshot, but customers with no activity records in #HistoryCredit will NOT have MinRealMoney set (remains NULL) rather than being included in the RIGHT JOIN result. This difference only matters for edge cases where customers are in #Snapshot but have no credit activity in the window.
- All other steps (time window, #ListOfCids, #step3, #Snapshot population, early exit, #HistoryCredit, credit adjustment) are byte-for-byte identical.

See Trade.InterestGetDailyRawData Section 2.1-2.4 for full logic documentation.

### 2.2 Alternate Cashout Calculation (Key Difference)

**What**: Replaces the ROW_NUMBER() CTE approach with a two-step materialized temp table strategy for resolving the most recent cashout status per (WithdrawID, FundingID).

**Columns/Parameters Involved**: `#a`, `#AllCashoutRecords`, `History.WithdrawToFundingAction`, `Billing.Withdraw`

**Step 1 - Build #a (latest modification date per pair)**:
```
SELECT WithdrawID, FundingID, CID, MAX(ModificationDate) AS ModificationDate
INTO #a
FROM History.WithdrawToFundingAction HWTFA
     JOIN Billing.Withdraw BW ON BW.WithdrawID = HWTFA.WithdrawID
     JOIN #ListOfCids S ON BW.CID = S.CID
     JOIN Dictionary.CashoutStatus DCS ON HWTFA.CashoutStatusID = DCS.CashoutStatusID
WHERE HWTFA.ModificationDate IN [last 30 days to @EndTime]
GROUP BY WithdrawID, FundingID, CID
```
Creates clustered index on #a(WithdrawID, FundingID, ModificationDate).

**Step 2 - Build #AllCashoutRecords (latest record per pair)**:
```
SELECT CID, WithdrawID, FundingID, CashoutStatusID, Amount, ModificationDate, 1 AS RowNum
FROM #a
CROSS APPLY (
    SELECT TOP 1 ... FROM History.WithdrawToFundingAction b
    WHERE a.WithdrawID = b.WithdrawID AND a.FundingID = b.FundingID
      AND a.ModificationDate = b.ModificationDate
    ORDER BY WithdrawToFundingActionID DESC
) b

UNION ALL

SELECT BW.CID, ... FROM Billing.Withdraw BW
     JOIN #Snapshot S ON BW.CID = S.CID
WHERE BW.CashoutStatusID = 1 AND BW.RequestDate < @EndTime
```
Creates clustered index on #AllCashoutRecords(CID).

**Rationale for the alternate approach**: The base procedure uses a ROW_NUMBER() window function over the full WithdrawToFundingAction scan to get the latest record per (WithdrawID, FundingID). The NEWELAD variant pre-aggregates the latest date in #a, then uses CROSS APPLY TOP 1 to fetch just that record, potentially reducing the window function overhead on large history tables.

### 2.3 Final Output

Identical to Trade.InterestGetDailyRawData: `SELECT * FROM #Snapshot`.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ListOfCids | Trade.CidList READONLY | NO | - | CODE-BACKED | Input TVP. List of CIDs to compute interest data for. Same as Trade.InterestGetDailyRawData. |
| RS.1-13 | (same columns as Trade.InterestGetDailyRawData) | - | - | CODE-BACKED | Output schema is identical: CID, GCID, Date, CountryID, PlayerLevelID, AccountTypeID, RegulationID, Credit, RealizedEquity, Bonus, MinRealMoney, SumOfPendingCashoutRequests, PlayerStatusID. See Trade.InterestGetDailyRawData for column descriptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Customer.Customer | Reader | Customer demographic and financial snapshot |
| JOIN | BackOffice.Customer | Reader | AccountTypeID and RegulationID |
| JOIN | History.ActiveCreditView | Reader | Credit activity history for the interest window |
| JOIN | History.WithdrawToFundingAction | Reader | Two-pass: MAX(ModificationDate) into #a, then CROSS APPLY TOP 1 for latest cashout record |
| JOIN | Billing.Withdraw | Reader | Pending withdrawal records (CashoutStatusID=1) |
| JOIN | Dictionary.CashoutStatus | Reader | IsFinalStatus classification for pending cashout filter |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Development variant - not known to be called in production.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InterestGetDailyRawDataNEWELAD (procedure)
├── Trade.CidList (TVP type) - input parameter type
├── Customer.Customer (table) - customer snapshot
├── BackOffice.Customer (table) - account classification
├── History.ActiveCreditView (view) - credit activity
├── History.WithdrawToFundingAction (table) - cashout status history (two-pass)
├── Billing.Withdraw (table) - pending withdrawals
└── Dictionary.CashoutStatus (table) - IsFinalStatus classification
```

### 6.1 Objects This Depends On

Same as Trade.InterestGetDailyRawData. See that document for details.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Interest calculation service | External (Application) | Development/testing variant; may be called for A/B comparison against base procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Performance | Forces plan recompilation per execution |
| TRY/CATCH + THROW | Error handling | Same as base procedure; full exception propagation |
| INNER JOIN for MinRealMoney | Variation | Uses INNER JOIN (not RIGHT JOIN) when updating MinRealMoney; customers with no history in the window do not get MinRealMoney set |
| Two-pass cashout strategy | Performance experiment | #a materializes MAX(ModificationDate); CROSS APPLY TOP 1 then fetches the matching record; avoids ROW_NUMBER() window function |
| Clustered index on #AllCashoutRecords(CID) | Performance | Added in this variant (not present in base procedure) to speed up the final cashout sum join |

---

## 8. Sample Queries

### 8.1 Execute for a batch of CIDs (identical to base procedure)

```sql
DECLARE @CidList Trade.CidList;
INSERT INTO @CidList (CID) VALUES (1001), (1002), (1003);

EXEC Trade.InterestGetDailyRawDataNEWELAD @ListOfCids = @CidList;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InterestGetDailyRawDataNEWELAD | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InterestGetDailyRawDataNEWELAD.sql*
