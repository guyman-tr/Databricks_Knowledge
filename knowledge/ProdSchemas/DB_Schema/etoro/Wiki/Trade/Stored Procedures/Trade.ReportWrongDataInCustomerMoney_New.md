# Trade.ReportWrongDataInCustomerMoney_New

> Variant of Trade.ReportWrongDataInCustomerMoney that uses a two-phase scan for performance and sends HTML email alerts with hardcoded recipients. No hardcoded CID exclusion list, no IsCopied flag, no RealizedEquityList persistence.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; scans all customers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReportWrongDataInCustomerMoney_New is another variant in the RealizedEquity monitoring family. It detects customers whose Customer.CustomerMoney.RealizedEquity deviates by >= $0.01 from the calculated value (Credit + MirrorAmount + PositionAmount - PendingCashouts), then sends an HTML email alert. It uses the same two-phase scan architecture as Trade.ReportWrongDataInCustomerMoney_1 but differs in key ways:

1. **Hardcoded recipients**: Sends email directly to 'tradingbackend@etoro.com;dba@etoro.com;tier2@etoro.com;mimoproductionissues@etoro.com' rather than reading from Maintenance.Feature. This makes it independent of the Feature table configuration.
2. **No IsCopied flag**: @Tbl has only CID and ColumnsNames (no IsCopied INT column). The HTML email table has only two data columns (CID, wrong columns).
3. **No persistence**: Does NOT insert to RealizedEquityList (unlike the _1 variant).
4. **No exclusion list**: No hardcoded CIDs are excluded from detection (unlike the original).

The "_New" suffix suggests this was meant as an improved version of the original procedure, adopting the two-phase scan for better performance. The hardcoded recipients suggest it may have been created to send to a wider/different audience than the original (which uses Maintenance.Feature recipients).

Data flow: No parameters. Same temp table + CTE two-phase scan as _1. Builds HTML email. Sends via sp_send_dbmail to hardcoded address list. Email send is NOT commented out - this procedure actively sends email when discrepancies are found.

---

## 2. Business Logic

### 2.1 Two-Phase Scan Architecture (Same as _1)

**What**: Phase 1 uses pre-aggregated temp tables for broad identification; phase 2 uses CTEs on suspect CIDs for precise re-verification.

**Columns/Parameters Involved**: `#suspectCid`, CTEs `ActualMirrorData`, `PositionData`, `ActualData`, `HistoryCredit`, `Requests`, `Approved`, `Disc`

**Rules**: Identical to Trade.ReportWrongDataInCustomerMoney_1. See that procedure for full algorithm details.

- Phase 1: Build #TradeMirror, #TradePosition, #ActualData with CLUSTERED indexes. Calculate #Disc (pending cashouts). Flag suspects into #suspectCid.
- Phase 2: Re-query Trade.Mirror, Trade.Position, Customer.CustomerMoney, History.Credit via CTEs but inner-joined to #suspectCid.
- Final INSERT INTO @Tbl: ABS(deviation) >= $0.01 -> ColumnsNames = 'RealizedEquity '.
- No IsCopied check (no OUTER APPLY to Trade.Mirror ParentCID).

### 2.2 Hardcoded Email Recipients

**What**: Sends directly to a hardcoded distribution list, bypassing the Maintenance.Feature configuration.

**Columns/Parameters Involved**: `@recipients` (hardcoded string)

**Rules**:
- Recipients: 'tradingbackend@etoro.com;dba@etoro.com;tier2@etoro.com;mimoproductionissues@etoro.com'
- @blind_copy_recipients = NULL (no BCC).
- This is the ACTIVE email send path (not commented out), unlike the _1 variant where email is disabled.
- Subject: 'CIDs with wrong data in Customer.CustomerMoney found at: {date}'.
- Body: HTML table with CID and ColumnsNames columns (no IsCopied column in this variant).
- Format: 'HTML'.

### 2.3 No Exclusion List, No IsCopied, No Persistence

**What**: Compared to siblings, this variant is simpler in scope and output.

**Rules**:
- No @ExcludedUsers table variable (scan all customers).
- @Tbl has only 2 columns: CID BIGINT, ColumnsNames VARCHAR(40). No IsCopied INT.
- No INSERT INTO RealizedEquityList (no historical persistence).
- HTML email shows CID and ColumnsNames only.

**Diagram**:
```
Trade.ReportWrongDataInCustomerMoney_New()
    |
    v
Phase 1: Build #TradeMirror, #TradePosition, #ActualData, #Disc (all customers)
    |
    v
Flag suspects into #suspectCid (ABS(deviation) >= $0.01)
    |
    v
Phase 2: CTE re-scan of suspects only -> INSERT INTO @Tbl(CID, ColumnsNames)
    |
    v
IF @Tbl empty -> RETURN (no email)
    |
    v
Build HTML email body (CID + ColumnsNames columns)
    |
    v
EXEC msdb.dbo.sp_send_dbmail
    @recipients = 'tradingbackend@etoro.com;dba@etoro.com;tier2@etoro.com;mimoproductionissues@etoro.com'
    @body_format = 'HTML'
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters.

**Output: HTML email alert. @Tbl columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | BIGINT | NO | - | CODE-BACKED | Customer ID with detected RealizedEquity discrepancy. Included in email body. |
| 2 | ColumnsNames | VARCHAR(40) | YES | - | CODE-BACKED | Which column has wrong data. Currently only 'RealizedEquity ' (trailing space) when ABS deviation >= $0.01. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerMoney | Reader (SELECT) | Source of Credit, RealizedEquity, TotalCash for both phases. |
| CID | Trade.Mirror | Reader (SELECT) | Aggregated for ActualMirrorAmount in both phases (no IsCopied check). |
| CID | Trade.Position | Reader (SELECT) | Aggregated for PositionAmount in both phases. |
| CID | History.Credit | Reader (SELECT) | Pending cashout calculation in both phases. |
| (hardcoded) | msdb.dbo.sp_send_dbmail | External system call | Sends HTML alert email to hardcoded recipients when discrepancies found. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent scheduled job | - | Caller | Typically called on a schedule for recurring financial data integrity monitoring. |
| Trade.ReportWrongDataInCustomerMoney | (sibling) | Sibling | Original procedure with exclusion list, Maintenance.Feature recipients, UserName column, IsCopied. |
| Trade.ReportWrongDataInCustomerMoney_1 | (sibling) | Sibling | Persistence variant: inserts to RealizedEquityList, email disabled. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReportWrongDataInCustomerMoney_New (procedure)
├── Customer.CustomerMoney (table)
├── Trade.Mirror (table)
├── Trade.Position (table)
├── History.Credit (table)
└── msdb.dbo.sp_send_dbmail (external system proc)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | Source of Credit, RealizedEquity, TotalCash in both phases. |
| Trade.Mirror | Table | Summed for ActualMirrorAmount in both phases. |
| Trade.Position | Table | Summed for PositionAmount in both phases. |
| History.Credit | Table | Pending cashout calculation (CreditTypeID 9,15 vs. 2,8) in both phases. |
| msdb.dbo.sp_send_dbmail | System procedure | Sends active HTML alert email to hardcoded recipients. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent scheduled job | External job | Calls this on a schedule for ongoing integrity monitoring. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Creates CLUSTERED indexes on temp tables (#TradeMirror, #TradePosition, #ActualData, #HistoryCredit, #Disc) on CID for join optimization. Does NOT create a #suspectCid clustered index (unlike the _1 variant which does).

### 7.2 Constraints

N/A for stored procedure.

**Recipient hardcoding implication**: Because recipients are hardcoded (not from Maintenance.Feature), updating the alert distribution list requires a schema change (ALTER PROCEDURE or source code change + SSDT deployment). The original procedure's Maintenance.Feature approach is more operationally flexible.

**Family comparison**:

| Aspect | Original | _1 | _New (this) |
|--------|----------|----|-------------|
| Exclusion list | 5 CIDs | None | None |
| Two-phase scan | No | Yes | Yes |
| IsCopied flag | Yes | Yes | No |
| UserName in output | Yes | No | No |
| RealizedEquityList insert | No | Yes | No |
| Email send | Yes (Feature 150003) | DISABLED | Yes (hardcoded) |
| blind_copy_recipients | Yes (same as recipients) | N/A | NULL |

---

## 8. Sample Queries

### 8.1 Execute the monitor (sends email if discrepancies found)

```sql
EXEC Trade.ReportWrongDataInCustomerMoney_New;
-- Scans all customers; sends to tradingbackend, dba, tier2, mimoproductionissues if deviations found
```

### 8.2 Compare all three variants in a test run

```sql
-- Preview discrepancies without any email or persistence
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
GROUP BY CM.CID, CM.Credit, CM.RealizedEquity
HAVING ABS((CM.Credit + ISNULL(SUM(M.Amount), 0) + ISNULL(SUM(P.Amount), 0)) - CM.RealizedEquity) >= 0.01
ORDER BY Deviation DESC;
```

### 8.3 Check email delivery for this procedure

```sql
-- View recent email log for this alert subject pattern
SELECT sent_date, recipients, subject, send_request_date
FROM msdb.dbo.sysmail_sentitems WITH (NOLOCK)
WHERE subject LIKE 'CIDs with wrong data in Customer.CustomerMoney%'
ORDER BY sent_date DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReportWrongDataInCustomerMoney_New | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReportWrongDataInCustomerMoney_New.sql*
