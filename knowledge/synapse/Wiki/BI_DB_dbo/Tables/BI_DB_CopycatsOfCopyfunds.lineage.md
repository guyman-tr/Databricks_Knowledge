# BI_DB_dbo.BI_DB_CopycatsOfCopyfunds — Lineage

**Generated**: 2026-04-23  
**Writer SP**: SP_CopycatsOfCopyfunds  
**Load Pattern**: TRUNCATE + INSERT (daily snapshot — no history)  

---

## Source Objects

| Object | Schema | Type | Role |
|---|---|---|---|
| Dim_Mirror | DWH_dbo | Dimension | Copy relationships: identifies customers (CID) copying CopyFund accounts (ParentCID with AccountTypeID=9); supplies ThisCopyEquity (RealizedEquity per mirror) |
| Dim_Customer | DWH_dbo | Dimension | CustomerStatic attributes: validates copier is NOT a CopyFund (AccountTypeID!=9), NOT Diamond Club (PlayerLevelID!=4); also supplies UserName, GuruStatusID for IS PI ? flag |
| V_Liabilities | DWH_dbo | View | AccountEquity (RealizedEquity as of @YesterdayDateID) for computing % Copying = ThisCopyEquity / AccountEquity * 100 |
| etoroGeneral_History_GuruCopiers | general | Table | CopyFund copier snapshots: supplies copier count and AUM for each CopyFund as of yesterday |
| External_etoro_Customer_BlockedCustomerOperations | BI_DB_dbo | External | Blocked copy operations list (OperationTypeID=2); customers on this list are excluded from the output |

---

## Writer

| SP | Load Pattern | Parameters |
|---|---|---|
| SP_CopycatsOfCopyfunds | TRUNCATE + INSERT | @Date Date (SP internally adds 1 day: set @Date = DateAdd(Day,1,@Date)) |

---

## Downstream Consumers

None identified in the SSDT repository. Operational feed for the PI Analytics and account manager teams identifying retail customers heavily concentrated in CopyFund investments.

---

## ETL Data Flow

```
[Blocked Operations Exclusion List]
External_etoro_Customer_BlockedCustomerOperations WHERE OperationTypeID=2
  → #CustomerBlockedCustomerOperations (CID list — excluded from output)

@YesterdayDateID = Convert(varchar(10), DateAdd(Day,-1,@Date), 112)
  (note: @Date is already incremented by 1 at SP entry, so @YesterdayDateID = original input date)

[Copier Population — heavy CopyFund investors]
DWH_dbo.Dim_Mirror (open mirrors where ParentCID is a CopyFund)
  JOIN Dim_Customer (copier: AccountTypeID != 9, NOT CopyFund itself)
  JOIN V_Liabilities (copier's total equity as of @YesterdayDateID; RealizedEquity > 0)
  JOIN Dim_Customer (parent: AccountTypeID = 9 — CopyFund manager)
  WHERE PlayerLevelID != 4 (exclude Diamond Club)
    AND tm.RealizedEquity / vl.RealizedEquity > 0.8 (>80% of total equity in this copy)
  → #children (CID, AccountEquity, ThisCopyEquity, % Copying)
    [NOTE: Distinct on all selected columns — one row per copy relationship per CID]

[CopyFund AUM and Copier Count]
general.etoroGeneral_History_GuruCopiers (Timestamp = yesterday)
  JOIN #children (c.CID = g.ParentCID — matches CopyFund CID to CopyFund's own copier history)
  JOIN Dim_Customer (copier of the CopyFund: PlayerLevelID != 4)
  → #CopyAUM_Data (ParentCID, ParentUserName, AUM, Copiers count)

[Final Assembly]
#children c
LEFT JOIN #CopyAUM_Data ca ON c.CID = ca.ParentCID
JOIN Dim_Customer child ON child.RealCID = c.CID       → UserName, GuruStatusID
LEFT JOIN #CustomerBlockedCustomerOperations cbo ON cbo.CID = c.CID
WHERE cbo.CID IS NULL                                  → exclude blocked customers
GROUP BY c.CID, AccountEquity, ThisCopyEquity, % Copying, UserName, GuruStatusID, Copiers, AUM

TRUNCATE TABLE BI_DB_dbo.BI_DB_CopycatsOfCopyfunds
INSERT INTO BI_DB_dbo.BI_DB_CopycatsOfCopyfunds (..., UpdateDate = GETDATE())
```
