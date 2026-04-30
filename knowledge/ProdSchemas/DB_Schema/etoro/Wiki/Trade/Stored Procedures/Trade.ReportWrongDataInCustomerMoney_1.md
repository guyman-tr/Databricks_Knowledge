# Trade.ReportWrongDataInCustomerMoney_1

> Variant of Trade.ReportWrongDataInCustomerMoney that uses a two-phase scan for performance, persists flagged CIDs to the RealizedEquityList table for historical tracking, includes the IsCopied flag, but has its email send disabled (commented out). No hardcoded exclusion list.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; scans all customers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReportWrongDataInCustomerMoney_1 is a variant of the original Trade.ReportWrongDataInCustomerMoney that detects RealizedEquity discrepancies in Customer.CustomerMoney. It uses the same core algorithm (Expected = Credit + MirrorAmount + PositionAmount - PendingCashouts vs. stored RealizedEquity; flag if ABS deviation >= $0.01) but differs in three key ways:

1. **Two-phase scan**: First builds a #suspectCid quick-filter using the pre-aggregated temp table data, then re-queries the live tables only for those suspects using CTEs. This reduces the final result set re-scan from the full customer base to only suspects, improving accuracy of the final numbers.
2. **Persistence**: Inserts flagged CIDs into the `RealizedEquityList` table (with CreatedDate=GETUTCDATE()) for historical tracking and downstream processing.
3. **Email disabled**: The `sp_send_dbmail` call is wrapped in a block comment (`/* ... */`). This procedure persists data but does NOT send email alerts. It may be used by downstream processes that read RealizedEquityList rather than relying on email notifications.

Unlike the original procedure, this variant has no hardcoded exclusion list (no CIDs are excluded from detection), no UserName column in the output, and uses a table-variable (@Tbl) that includes IsCopied.

Data flow: No parameters. Builds temp tables with CLUSTERED indexes. Two-pass scan: pass 1 identifies suspects via temp tables, pass 2 re-scans suspects via CTEs for precise final numbers. Inserts to RealizedEquityList. Builds HTML email body but does NOT send it. Modified as a tracking/persistence variant of the original alert procedure.

---

## 2. Business Logic

### 2.1 Two-Phase Scan Architecture

**What**: First pass uses pre-aggregated temp tables for a broad sweep; second pass uses CTEs on suspect CIDs for precise re-verification.

**Columns/Parameters Involved**: `#suspectCid`, CTE `ActualMirrorData`, `PositionData`, `ActualData`, `HistoryCredit`

**Rules**:
- **Phase 1**: Builds #TradeMirror and #TradePosition from full Trade.Mirror and Trade.Position tables. Joins to Customer.CustomerMoney via #ActualData. Calculates PendingCashouts via #Disc. Flags CIDs where ABS(deviation) >= $0.01 into #suspectCid.
- **Phase 2**: Re-joins Trade.Mirror, Trade.Position, Customer.CustomerMoney, and History.Credit but only for CIDs in #suspectCid (via inner join). Uses CTEs (ActualMirrorData, PositionData, ActualData, HistoryCredit, Requests, Approved, Disc) to produce precise recalculated values.
- Phase 2 re-validates the same formula: ABS(Credit + MirrorAmount + PositionAmount - RwithoutA - RealizedEquity) >= $0.01.
- The two-phase approach trades additional code complexity for more precise final numbers (phase 2 re-reads live data for suspects rather than relying on potentially stale phase-1 temp tables).

### 2.2 RealizedEquityList Persistence

**What**: Persists flagged CIDs to a permanent table for historical tracking.

**Columns/Parameters Involved**: `RealizedEquityList.CID`, `RealizedEquityList.CreatedDate`

**Rules**:
- INSERT RealizedEquityList (CID, CreatedDate) SELECT CID, GETUTCDATE() FROM @Tbl.
- This INSERT happens BEFORE the email early-return check.
- Unlike the original procedure which only sends email, this variant persists the suspects for downstream consumption (e.g., automated remediation jobs or dashboards reading RealizedEquityList).
- Note: `RealizedEquityList` table is in the Trade schema (implied by context). This table accumulates rows over time; callers should query by CreatedDate for recent runs.

### 2.3 Email Send Disabled

**What**: The sp_send_dbmail call is commented out - this procedure does NOT send email.

**Rules**:
- The HTML email is constructed (SET @tableHTML = ...) but the EXEC msdb.dbo.sp_send_dbmail block is commented out: `/* EXEC msdb.dbo.sp_send_dbmail ... */`.
- Unlike the original (which sends to Maintenance.Feature FeatureID=150003 recipients), this variant produces no email notification.
- The early return `IF NOT EXISTS (SELECT top 1 1 FROM @Tbl) RETURN` still exits early if no discrepancies are found (before the commented-out email call).
- This procedure is likely used as a data-collection step that feeds RealizedEquityList, with alerting handled separately.

### 2.4 No Exclusion List

**What**: All customers are checked; no CIDs are hardcoded for exclusion.

**Rules**:
- The original Trade.ReportWrongDataInCustomerMoney excludes 5 hardcoded CIDs (10132052, 24916605, 29759462, 18031957, 24252438) via a table variable @ExcludedUsers.
- This _1 variant has no such exclusion. All customers in Customer.CustomerMoney are scanned.
- This may cause the same internal/test accounts to appear in RealizedEquityList; callers should filter accordingly.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters.

**Output: RealizedEquityList inserts + HTML email body built (but not sent). @Tbl columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | BIGINT | NO | - | CODE-BACKED | Customer ID with detected RealizedEquity discrepancy. Inserted to RealizedEquityList. |
| 2 | ColumnsNames | VARCHAR(40) | YES | - | CODE-BACKED | Identifies which column has wrong data. Currently only 'RealizedEquity ' (trailing space from source code) when deviation >= $0.01. |
| 3 | IsCopied | INT | NO | 0 | CODE-BACKED | 1=this customer has followers copying their trades (ParentCID in Trade.Mirror); 0=not a copy provider. Included in @Tbl and HTML email but not persisted to RealizedEquityList. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerMoney | Reader (SELECT) | Source of Credit, RealizedEquity, TotalCash for validation. Scanned in both phase 1 (via #ActualData) and phase 2 (CTE ActualData). |
| CID | Trade.Mirror | Reader (SELECT) | Phase 1 and phase 2: aggregated mirror amounts per CID. Phase 2 also checked for IsCopied (ParentCID). |
| CID | Trade.Position | Reader (SELECT) | Phase 1 and phase 2: aggregated open position amounts per CID. |
| CID | History.Credit | Reader (SELECT) | Phase 1 and phase 2: pending cashout calculation (CreditTypeID 9,15 requests vs. 2,8 approvals). |
| CID | RealizedEquityList | Writer (INSERT) | Persists flagged CIDs with CreatedDate for downstream processing and historical tracking. |
| FeatureID=150003 | Maintenance.Feature | Lookup | Email recipients retrieved (but email send is commented out). |
| (commented) | msdb.dbo.sp_send_dbmail | DISABLED | Email send code is present but commented out with block comments. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ReportWrongDataInCustomerMoney | (batch plan note) | Sibling | Original procedure that emails; this is a persistence-focused variant. |
| Trade.ReportWrongDataInCustomerMoney_New | (batch plan note) | Sibling | Another variant (hardcoded recipients, no IsCopied, no persistence). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReportWrongDataInCustomerMoney_1 (procedure)
├── Customer.CustomerMoney (table)
├── Trade.Mirror (table)
├── Trade.Position (table)
├── History.Credit (table)
├── RealizedEquityList (table)  [INSERT target]
└── Maintenance.Feature (table)  [email recipients, email disabled]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | Source of Credit, RealizedEquity, TotalCash in both phases. |
| Trade.Mirror | Table | Summed for ActualMirrorAmount in both phases; IsCopied (ParentCID) check in phase 2. |
| Trade.Position | Table | Summed for PositionAmount in both phases. |
| History.Credit | Table | Pending cashout calculation (CreditTypeID 9,15 vs. 2,8) in both phases. |
| RealizedEquityList | Table | INSERT target: persists flagged CIDs with timestamp. |
| Maintenance.Feature | Table | Reads FeatureID=150003 for email recipients (email disabled but query still runs). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Downstream remediation jobs | External consumers | Read RealizedEquityList for CIDs requiring financial data correction. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Note: Creates CLUSTERED indexes on all phase-1 temp tables (#TradeMirror, #TradePosition, #ActualData, #HistoryCredit, #Disc, #suspectCid) on the CID column to optimize multi-step JOINs.

### 7.2 Constraints

N/A for stored procedure.

**Comparison of the ReportWrongDataInCustomerMoney family**:

| Aspect | Original | _1 (this) | _New |
|--------|----------|-----------|------|
| Exclusion list | Yes (5 CIDs) | No | No |
| Two-phase scan | No | Yes | Yes |
| Persists to RealizedEquityList | No | Yes | No |
| IsCopied in output | Yes | Yes | No |
| UserName in output | Yes (added 12/12/24) | No | No |
| Email | Yes (Maintenance.Feature 150003) | DISABLED (commented out) | Yes (hardcoded recipients) |

---

## 8. Sample Queries

### 8.1 Execute the monitoring and persistence step

```sql
EXEC Trade.ReportWrongDataInCustomerMoney_1;
-- Scans all customers, inserts discrepancies to RealizedEquityList (no email sent)
```

### 8.2 Query recently flagged CIDs from RealizedEquityList

```sql
SELECT CID, CreatedDate
FROM RealizedEquityList WITH (NOLOCK)
WHERE CreatedDate >= DATEADD(day, -1, GETUTCDATE())
ORDER BY CreatedDate DESC;
```

### 8.3 Manually verify a specific CID

```sql
SELECT
    CM.CID,
    CM.Credit,
    CM.RealizedEquity,
    ISNULL(SUM(M.Amount), 0) AS ActualMirrorAmount,
    ISNULL(SUM(P.Amount), 0) AS SumOfPositions,
    ABS((CM.Credit + ISNULL(SUM(M.Amount), 0) + ISNULL(SUM(P.Amount), 0)) - CM.RealizedEquity) AS Deviation
FROM Customer.CustomerMoney CM WITH (NOLOCK)
LEFT JOIN Trade.Mirror M WITH (NOLOCK) ON M.CID = CM.CID
LEFT JOIN Trade.Position P WITH (NOLOCK) ON P.CID = CM.CID
WHERE CM.CID = 12345
GROUP BY CM.CID, CM.Credit, CM.RealizedEquity;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReportWrongDataInCustomerMoney_1 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReportWrongDataInCustomerMoney_1.sql*
