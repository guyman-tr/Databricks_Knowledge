# Column Lineage — BI_DB_dbo.BI_DB_Client_New_CompensationBreakdown

**Writer SP**: `BI_DB_dbo.SP_Client_Balance_New` (Priority 99 — FinanceReportSPS)
**ETL Pattern**: DELETE-INSERT by DateID (daily incremental)
**Filter**: Fact_CustomerAction.ActionTypeID = 36 (compensation payments only)

**Note**: SP_Client_Balance_New is a massive (~9500 line) SP that writes to 3 BI_DB tables in one execution: BI_DB_Client_New_CompensationBreakdown, BI_DB_Client_Balance_CID_Level_New (documented), and BI_DB_Client_Balance_Aggregate_Level_New.

---

## Source Chain

```
Fact_CustomerAction (ActionTypeID=36) ──→ #fca (compensation actions)
Fact_SnapshotCustomer + dimensions ──→ #CIDAgg (customer classification)
Fact_RegulationTransfer ──→ #transfers (dedup)
                                 ↓
Dim_CompensationReason ──────────┐
Dim_MoveMoneyReason ─────────────┤
#findDiffsDLT ───────────────────┤──→ #compensationReasons (final temp)
Dim_Customer ────────────────────┤
External_UserApiDB_Dict_TanganyStatus ┤
Dim_State_and_Province ──────────┘
                                 ↓
         INSERT INTO BI_DB_Client_New_CompensationBreakdown
```

---

## Column-Level Lineage

⛔ **Alias-level source attribution applied**

### A. Identity & Date (5 columns)

| BI_DB Column | Source (alias) | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| CID | #fca (a) | RealCID | Direct. Customer who received compensation |
| DateID | computed | @dateID | YYYYMMDD int from SP parameter |
| Date | computed | @date | SP parameter date |
| YearMonth | computed | @date | CONVERT(VARCHAR(6),@date,112) → YYYYMM int |
| YearQuarter | computed | @date | YEAR(@date) * 100 + DATEPART(qq, @date) → YYYYQQ int |
| Year | computed | @date | YEAR(@date) |

### B. Compensation Details (3 columns)

| BI_DB Column | Source (alias) | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| CompensationType | Dim_CompensationReason (c) | Name | Direct via CompensationReasonID. Values: "Interest Payment", "Special Promotion", "Promotion - Leads", etc. |
| CompensationAmount | #fca (a) | Amount | SUM(CAST(Amount AS DECIMAL(18,4))). Aggregated by CID × CompensationReasonID |
| CompensationReasonID | #fca (a) | CompensationReasonID | Direct FK to Dim_CompensationReason |
| MoveMoneyReason | Dim_MoveMoneyReason (dmmr) | MoveMoneyReason | LEFT JOIN via MoveMoneyReasonID |

### C. Customer Classification (8 columns — from #CIDAgg via c1)

| BI_DB Column | Source (alias) | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| AccountType | #CIDAgg (c1) | AccountType | "Private", "Corporate" |
| Country | #CIDAgg (c1) | Country | Full country name |
| MifidCategory | #CIDAgg (c1) | MifidCategory | MiFID categorization |
| PlayerStatus | #CIDAgg (c1) | PlayerStatus | Account status name |
| Regulation | #CIDAgg (c1) | Regulation | Current regulation name |
| IsCreditReportValidCB | #CIDAgg (c1) | IsCreditReportValidCB | CB validity flag |
| IsValidCustomer | #CIDAgg (c1) | IsValidCustomer | Legacy valid customer flag |
| IsGermanBaFin | #CIDAgg (c1) | IsGermanBaFin | German BaFin regulatory flag |

### D. Transfer Indicators (5 columns)

| BI_DB Column | Source (alias) | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| TransferDirection | #CIDAgg (c1) | TransferDirection | 1 = incoming (to regulation) |
| DidRegulationTransfer | #CIDAgg (c1) | DidRegulationTransfer | 0/1 flag from Fact_RegulationTransfer |
| DidCBValidTransfer | #CIDAgg (c1) | DidCBValidTransfer | 0/1 flag |
| FromRegulation | #CIDAgg (c1) | FromRegulation | Source regulation before transfer |
| ToRegulation | #CIDAgg (c1) | ToRegulation | Target regulation after transfer |

### E. Account Type Flags (3 columns)

| BI_DB Column | Source (alias) | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| IsEtoroTradingCID | #CIDAgg (c1) | IsEtoroTradingCID | eToro internal trading account flag |
| eToroTradingGroupUser | #CIDAgg (c1) | eToroTradingGroupUser | "NotEtoroGroupAccount" for regular users |
| IsGlenEagleAccount | #CIDAgg (c1) | IsGlenEagleAccount | Glen Eagle account flag |

### F. DLT & Crypto (3 columns)

| BI_DB Column | Source (alias) | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| TanganyStatus | External_UserApiDB_Dictionary_TanganyStatus (dtstu) | Name | Via Dim_Customer.TanganyStatusID. Tangany crypto custody status |
| IsDLTUser | #findDiffsDLT (fdd) | IsDLTUser | DLT (Digital Ledger Technology) user flag |
| DidDLTTransfer | #findDiffsDLT (fdd) | DidDLTTransfer | DLT transfer on this date flag |

### G. Geographic (1 column)

| BI_DB Column | Source (alias) | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| US_State | Dim_State_and_Province (dsap) | ShortName | LEFT JOIN via Dim_Customer.RegionID WHERE CountryID = 219 (US only). 2-char state code |

### H. Metadata (1 column)

| BI_DB Column | Source (alias) | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| UpdateDate | computed | GETDATE() | SP execution timestamp |
