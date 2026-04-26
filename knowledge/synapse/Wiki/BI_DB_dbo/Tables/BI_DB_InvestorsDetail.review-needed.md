# Review Needed: BI_DB_dbo.BI_DB_InvestorsDetail

> Sidecar to `BI_DB_InvestorsDetail.md`. Items requiring domain expert validation.

---

## SP Logic Concerns

### DELETE Bug — Identical Conditions
**Location**: SP_InvestorReportDetails, lines 44–47

**Current code**:
```sql
DELETE from BI_DB_dbo.BI_DB_InvestorsDetail 
WHERE DateID = @EndddINT
OR DateID = @EndddINT
```

Both `WHERE` conditions are `DateID = @EndddINT` — identical. The commented-out original block above had:
```sql
--DELETE ... WHERE DateID < @StartddINT OR DateID = @EndddINT
```
which also pruned rows older than 60 days. The current code **never prunes history**. With 898.4M rows and growing, confirm:
1. Is the missing pruning intentional (keep full history)?
2. Should the duplicate condition be fixed?

### AssetType 'Investment' Classification
**InstrumentTypeIDs 4, 5, 6**: The SP uses `InstrumentTypeID IN (4, 5, 6) AND Leverage < 3` to classify Manual positions as 'Investment'. The actual type names for IDs 4, 5, 6 were not confirmed from Dim_Instrument during documentation. Verify these are the correct IDs for the intended "investment" asset categories.

---

## Column Naming Concern

### ParentUserName Dual Meaning
For `ActionType='Manual'` rows, `ParentUserName` contains `Dim_Instrument.InstrumentDisplayName` — an instrument name, not a user. This contradicts the column name. Confirm this is intentional (legacy design) and that downstream report consumers are aware of the distinction. Consider aliasing or renaming in reports.

---

## Data Quality Observations

| Observation | Question |
|-------------|----------|
| DaysContacted NULL = 87.4% | Is this expected? High null rate could indicate that most customers are unmanaged (AccountManagerID=0) or that contact data in BI_DB_UsageTracking_SF has gaps. Confirm expected null rate. |
| DaysContactedPhone NULL = 91.2% | Higher null rate than DaysContacted (fewer phone calls vs emails). Confirm expected. |
| 898.4M rows, no pruning | No DELETE of old rows means unbounded growth. Confirm operational plan for table size management. |
| MoneyIn/MoneyOut can both be >0 for same row | For rows where the customer both opened and closed positions on the same date, SUM aggregation may produce non-zero values in both columns. Confirm this is expected behavior. |

---

## Not Migrated to UC

Before UC migration:
- `DWH_dbo.V_Liabilities` — confirm UC equivalent
- `BI_DB_dbo.BI_DB_UsageTracking_SF` — confirm UC path for Salesforce contact history
- `WITH (NOLOCK)` hints throughout SP — confirm these are removed in UC (Databricks doesn't support them)
- 898.4M rows — migration approach must address table size; consider partition strategy

---

*Generated: 2026-04-22 | Batch 27 | Reviewer: pending*
