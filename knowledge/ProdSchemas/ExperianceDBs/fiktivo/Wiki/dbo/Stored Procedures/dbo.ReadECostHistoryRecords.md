# dbo.ReadECostHistoryRecords

## 1. Overview

Returns a summary report of all eCost history records, aggregating the total, processed, unprocessed, rejected, and unscheduled amounts in both the plan's native currency and USD. Each row represents one eCost plan (or commission plan adjustment) and includes the associated cost date range, creator, last updater, and scheduling status. Used by the eCost management UI to display the current state of all cost plans.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_eCostHistory |
| Secondary Tables | dbo.tblaff_PaymentHistory, dbo.tblaff_eCost, dbo.tblaff_eCost_Commissions, dbo.tblaff_User, Dictionary.Currency |
| Operation | SELECT |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

Returns one row per `eCostHistoryID` that has at least one paid, unprocessed commission entry in `tblaff_eCost_Commissions`.

| Column | Description |
|---|---|
| eCostHistoryID | Primary key of the eCost history record |
| AffiliateID | Affiliate associated with this cost plan |
| Type | "eCost Plan" or "Commission Plan Adjustment" |
| CreatedOn | Date the plan was requested |
| CreatedBy | Name of the user who created the plan |
| TotalAmount | Original planned total amount |
| Currency | Currency name for TotalAmount |
| TotalAmountUSD | Sum of commissions (USD) from `tblaff_eCost_Commissions` |
| StartDate / EndDate | Planned cost date range |
| CostStartDate / CostEndDate | Actual min/max `ORDER_DATE` from `tblaff_eCost` |
| Description | Description of the plan |
| ProcessedAmount | Amount already processed (PaymentRowStatusID = 8) in plan currency |
| UnprocessedAmount | Amount not yet processed in plan currency |
| RejectedAmount | Amount rejected (PaymentRowStatusID = 16) in plan currency |
| UnscheduledAmount | TotalAmount minus all scheduled payment amounts |
| LastUpdateDate | Timestamp of the last update to the plan |
| LastUpdatedBy | Name of the user who last updated the plan |

## 4. Parameters

No parameters. This procedure takes no inputs and always returns the full dataset.

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| (none) | - | - | - | - |

## 5. Business Logic

1. **Step 1 - Payment stats temp table:** Aggregates `tblaff_PaymentHistory` by `eCostHistoryID` (where `eCostHistoryID IS NOT NULL`) into `#ecostPlanPaymentsStats`. Computes scheduled, unprocessed (status != 8), processed (status = 8), and rejected (status = 16) amounts in both currency and USD. Creates a covering index on `eCostHistoryID`.
2. **Step 2 - eCost stats temp table:** Joins `tblaff_eCost` to `tblaff_eCost_Commissions` (where `Paid = 1 AND PaymentID = 0`) to compute `TotalAmountUSD` (sum of commissions) and the actual `CostStartDate`/`CostEndDate` per `eCostHistoryID`. Creates a covering index.
3. **Step 3 - Final SELECT:** Joins `tblaff_eCostHistory` to both temp tables, `tblaff_User` twice (creator and updater), and `Dictionary.Currency`. Applies `IsCommissionPlanAdjustment` to switch between currency-based and USD-based amounts. Computes `UnscheduledAmount` as `TotalAmount - ScheduledAmount`.
4. Drops both temp tables at the end.
5. `SET NOCOUNT ON` suppresses row-count messages.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_eCostHistory | Table | dbo | Master eCost plan records |
| dbo.tblaff_PaymentHistory | Table | dbo | Payment rows linked to eCost plans; source of processed/unprocessed amounts |
| dbo.tblaff_eCost | Table | dbo | Individual eCost transactions |
| dbo.tblaff_eCost_Commissions | Table | dbo | Commission rows for eCost transactions |
| dbo.tblaff_User | Table | dbo | User names for CreatedBy and LastUpdatedBy |
| Dictionary.Currency | Table | Dictionary | Currency name lookup |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- Two temp table indexes are created inline to accelerate the joins in the final SELECT.
- `NOLOCK` hints are used on all base table reads to avoid blocking; results may include uncommitted data.
- The `Dictionary.Currency` table reference was updated in July 2024 (PART-3147) from the old `dbo.Dictionary.Currency` qualified name; ensure the schema rename is reflected in all dependent queries.

## 8. Usage Examples

```sql
-- Retrieve all eCost history records with aggregated payment status
EXEC dbo.ReadECostHistoryRecords;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2024-07-10 | Noga Rozen | PART-3147 | Renamed table reference from dbo.Dictionary.Currency to Dictionary.Currency |

---
*Object: dbo.ReadECostHistoryRecords | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.ReadECostHistoryRecords.sql*
