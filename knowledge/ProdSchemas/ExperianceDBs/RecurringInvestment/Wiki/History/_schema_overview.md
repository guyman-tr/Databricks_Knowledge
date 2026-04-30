# History Schema Overview

## Purpose

The History schema contains **SQL Server system-versioning (temporal) history tables** for the RecurringInvestment schema. These tables are automatically managed by SQL Server's SYSTEM_VERSIONING feature and store previous versions of rows from their parent tables.

## How It Works

When a row in a system-versioned RecurringInvestment table is UPDATE'd or DELETE'd, SQL Server automatically copies the previous version of the row into the corresponding History table before applying the change. The ValidFrom and ValidTo columns define the time period when each historical row version was the "current" version.

This enables temporal queries using `FOR SYSTEM_TIME` syntax to see what data looked like at any point in the past.

## Object Inventory

| History Table | Parent Table | Columns | Purpose |
|--------------|-------------|---------|---------|
| RecurringInvestmentPlans | RecurringInvestment.Plans | 27 | Full plan configuration history (status changes, amount changes, cancellations) |
| RecurringInvestmentPlanInstances | RecurringInvestment.PlanInstances | 33 | Full instance execution history (every deposit/order/position stage change) |
| RecurringInvestmentBlackListCopierCountryID | RecurringInvestment.BlackListCopierCountryID | 4 | Copier country blacklist changes |
| RecurringInvestmentBlackListCopyParentCID | RecurringInvestment.BlackListCopyParentCID | 4 | Copy parent trader blacklist changes |
| RecurringInvestmentBlackListCopyParentCIDAndCopierCountryID | RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID | 5 | Trader+country blacklist changes |
| RecurringInvestmentBlackListExchangeIDCountryID | RecurringInvestment.BlackListExchangeIDCountryID | 5 | Exchange+country blacklist changes |
| RecurringInvestmentBlackListInstrumentID | RecurringInvestment.BlackListInstrumentID | 4 | Instrument blacklist changes |
| RecurringInvestmentBlackListInstrumentIDCountryID | RecurringInvestment.BlackListInstrumentIDCountryID | 6 | Instrument+country blacklist changes |
| RecurringInvestmentBlackListInstrumentTypeCountryID | RecurringInvestment.BlackListInstrumentTypeCountryID | 6 | Instrument type+country blacklist changes |

## Common Technical Pattern

All 9 tables share these characteristics:
- **No PK constraints** (multiple historical versions of the same row can exist)
- **Clustered index on (ValidTo, ValidFrom)** for efficient temporal range queries
- **DATA_COMPRESSION = PAGE** for storage efficiency
- **Trace column**: nvarchar(733) NOT NULL (materialized copy, not computed like the parent)
- **Never written to directly** by application code - managed by SQL Server
- Plans and PlanInstances tables also have nonclustered indexes on their primary ID columns for point-in-time lookups

---

*Schema documentation completed: 2026-04-13 | Objects: 9 | Average quality: 9.0 | Batches: 1*
