# Trade.InterestGetDailyRawDataTest

> Test variant of Trade.InterestGetDailyRawData with an alternate three-step cashout record resolution: materializes distinct (WithdrawID, FundingID) pairs into #step1, fetches the most recent status into #step2 via CROSS APPLY, then unions with direct Billing.Withdraw pending records.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ListOfCids - TVP of CIDs to compute interest data for |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InterestGetDailyRawDataTest is a test/experimental variant of Trade.InterestGetDailyRawData. It was created to validate an alternative implementation of the cashout record deduplication logic before potentially replacing the production procedure. The output schema is identical to the base procedure; the cashout calculation section is restructured into a more explicit multi-step approach.

The "Test" suffix indicates this is not intended for production use in its current state. It may have been retained for debugging or comparison purposes.

---

## 2. Business Logic

### 2.1 Steps 1-4 (Identical to Base Procedure)

**What**: Time window initialization, CID loading, customer snapshot, credit adjustment, and MinRealMoney computation are identical to Trade.InterestGetDailyRawData.

MinRealMoney uses RIGHT JOIN (same as the base procedure - different from the NEWELAD variant).

See Trade.InterestGetDailyRawData Section 2.1-2.4 for full logic documentation.

### 2.2 Three-Step Cashout Calculation (Key Difference)

**What**: Replaces the ROW_NUMBER() CTE with a three-step materialized approach: distinct pair discovery, latest-record fetch, then final aggregation.

**Step 1 - #step1 (distinct withdrawal-funding pairs)**:
```sql
SELECT DISTINCT HWTFA.WithdrawID, HWTFA.FundingID, S.CID
INTO #step1
FROM History.WithdrawToFundingAction HWTFA
     JOIN Dictionary.CashoutStatus DCS ON HWTFA.CashoutStatusID = DCS.CashoutStatusID
     JOIN Billing.Withdraw BW ON BW.WithdrawID = HWTFA.WithdrawID
     JOIN #Snapshot S ON BW.CID = S.CID
WHERE HWTFA.ModificationDate IN [last 30 days to @EndTime]
```
Creates clustered index on #step1(WithdrawID, FundingID).

Note: Joins Dictionary.CashoutStatus but does NOT filter by IsFinalStatus here - all statuses included in the DISTINCT set.

**Step 2 - #step2 (most recent status per pair)**:
```sql
SELECT k.CID, k.WithdrawID, k.FundingID, X.CashoutStatusID, X.Amount, X.ModificationDate
INTO #step2
FROM #step1 k
CROSS APPLY (
    SELECT TOP 1 CashoutStatusID, Amount, ModificationDate
    FROM History.WithdrawToFundingAction HWTFA
    WHERE HWTFA.WithdrawID = k.WithdrawID AND HWTFA.FundingID = k.FundingID
      AND HWTFA.ModificationDate IN [same 30-day window]
    ORDER BY ModificationDate DESC, WithdrawToFundingActionID DESC
) AS X
```
Most recent status record per (WithdrawID, FundingID) pair.

**Step 3 - AllCashoutRecords CTE + final UPDATE**:
```sql
WITH AllCashoutRecords AS (
    SELECT CID, WithdrawID, FundingID, CashoutStatusID, Amount, ModificationDate
    FROM #step2          -- historical: latest status per pair

    UNION ALL

    SELECT BW.CID, WithdrawID, FundingID, CashoutStatusID, Amount, ModificationDate
    FROM Billing.Withdraw BW
         JOIN #Snapshot S ON BW.CID = S.CID
    WHERE BW.CashoutStatusID = 1 AND BW.RequestDate < @EndTime
)
UPDATE #Snapshot
SET SumOfPendingCashoutRequests = b.SumOfPendingCashoutRequests
FROM #Snapshot a
     INNER JOIN (
         SELECT CID, ABS(SUM(Amount)) AS SumOfPendingCashoutRequests
         FROM AllCashoutRecords ACR
              INNER JOIN Dictionary.CashoutStatus DC
                  ON ACR.CashoutStatusID = DC.CashoutStatusID
                 AND (DC.IsFinalStatus = 0 OR DC.IsFinalStatus IS NULL)
         GROUP BY CID
     ) b ON a.CID = b.CID
```

**Notable: IsFinalStatus filter in JOIN ON clause**: The `AND (DC.IsFinalStatus = 0 OR DC.IsFinalStatus IS NULL)` condition appears as part of the JOIN ON clause rather than a WHERE clause. This is syntactically valid SQL - it restricts which CashoutStatus rows participate in the join, effectively filtering to non-final statuses.

**Note: No RowNum filter** in the final aggregation (unlike the base procedure). The #step2 materialization already ensures one record per (WithdrawID, FundingID) pair, so no deduplication is needed in the CTE.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ListOfCids | Trade.CidList READONLY | NO | - | CODE-BACKED | Input TVP. List of CIDs to compute interest data for. Identical to Trade.InterestGetDailyRawData. |
| RS.1-13 | (same columns as Trade.InterestGetDailyRawData) | - | - | CODE-BACKED | Output schema is identical: CID, GCID, Date, CountryID, PlayerLevelID, AccountTypeID, RegulationID, Credit, RealizedEquity, Bonus, MinRealMoney, SumOfPendingCashoutRequests, PlayerStatusID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Customer.Customer | Reader | Customer snapshot data |
| JOIN | BackOffice.Customer | Reader | AccountTypeID and RegulationID |
| JOIN | History.ActiveCreditView | Reader | Credit activity history for the interest window |
| JOIN (#step1, #step2) | History.WithdrawToFundingAction | Reader | Two-pass distinct pair discovery + latest record fetch |
| JOIN | Billing.Withdraw | Reader | Pending withdrawal records and history join key |
| JOIN | Dictionary.CashoutStatus | Reader | Status lookup in both #step1 and final CTE aggregation |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Test/experimental variant.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InterestGetDailyRawDataTest (procedure)
├── Trade.CidList (TVP type) - input parameter type
├── Customer.Customer (table) - customer snapshot
├── BackOffice.Customer (table) - account classification
├── History.ActiveCreditView (view) - credit activity
├── History.WithdrawToFundingAction (table) - cashout history (three-step)
├── Billing.Withdraw (table) - pending withdrawals
└── Dictionary.CashoutStatus (table) - status classification
```

### 6.1 Objects This Depends On

Same as Trade.InterestGetDailyRawData. See that document for details.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Development/testing | External | Test variant; not known to be called in production |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Performance | Forces plan recompilation per execution |
| TRY/CATCH + THROW | Error handling | Full exception propagation to caller |
| RIGHT JOIN for MinRealMoney | Same as base | Customers with no history in window get MinRealMoney = NULL |
| Three-step cashout materialization | Design | #step1 (DISTINCT pairs) -> #step2 (CROSS APPLY latest per pair) -> AllCashoutRecords CTE; more explicit but more temp table overhead than ROW_NUMBER approach |
| IsFinalStatus in JOIN ON | Syntax | `AND (DC.IsFinalStatus = 0 OR DC.IsFinalStatus IS NULL)` is part of the INNER JOIN ON clause, not a WHERE clause; valid SQL, restricts join to non-final statuses |
| No RowNum filter needed | Design | #step2 already contains one record per (WithdrawID, FundingID), so AllCashoutRecords CTE needs no deduplication filter |

---

## 8. Sample Queries

### 8.1 Execute for a batch of CIDs

```sql
DECLARE @CidList Trade.CidList;
INSERT INTO @CidList (CID) VALUES (1001), (1002), (1003);

EXEC Trade.InterestGetDailyRawDataTest @ListOfCids = @CidList;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InterestGetDailyRawDataTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InterestGetDailyRawDataTest.sql*
