# RecurringInvestment Schema Overview

## Purpose

The RecurringInvestment schema manages eToro's **Recurring Investment** feature - an automated investment system that enables users to set up recurring plans that automatically deposit funds and purchase financial instruments (stocks, ETFs, crypto) or copy other traders (Popular Investors, SmartPortfolios) on a scheduled basis.

## Architecture

The system operates as a **three-stage pipeline** per execution cycle:

```
Plan Instances Job (daily 18:20)
    |
    v
[1. DEPOSIT] --> Deposit Message Handler (Money ServiceBus)
    |
    v
[2. ORDER] --> Order Execution Job (Trading API / TAPI)
    |
    v
[3. POSITION] --> Position Confirmation Flow
```

### Backend Service

- **Repository**: eToro/recurring-investment-back (.NET)
- **Jobs**: Create Plan Job (17:05), Plan Instances Job (18:20), Before Deposit Job (21:00), Order Execution Job
- **Handlers**: Deposit Message Handler (Money ServiceBus listener)

### External Dependencies

- **Money Group / MIMO**: Manages recurring deposit plans (Billing DB [Recurring].[Payment])
- **Trading API (TAPI)**: Places orders and opens positions
- **Currency System**: [etoro].[Dictionary].[Currency] for multi-currency support

## Core Tables

| Table | Rows | Purpose |
|-------|------|---------|
| **Plans** | 75,129 (17,673 active) | Plan subscriptions - one per user per instrument/copy target |
| **PlanInstances** | 227,402 | Execution cycle records - deposit/order/position per cycle |
| **UserDeposits** | 78,130 | Deposit data per user per cycle from Money ServiceBus |
| 7 BlackList tables | varies | Eligibility restrictions by country, instrument, exchange, trader |

## Plan Types

| PlanType | CopyType | Description | Key Columns |
|----------|----------|-------------|-------------|
| 1 (Instrument) | 0 (None) | Direct instrument investment | InstrumentID |
| 2 (Copy) | 1 (PI) | Copy a Popular Investor | CopyParentCID, CopyParentGCID |
| 2 (Copy) | 4 (SmartPortfolio) | Copy a managed portfolio | CopyParentCID, CopyParentGCID |

## Plan Lifecycle

```
Initializing (0) --> Active (1) --> Cancelled (2)
     [failed creation]    [operational]    [terminal]
```

Only Active (1) plans generate instances. Unique constraint ensures one active plan per user per instrument per copy parent.

## Instance Lifecycle

```
Created --> InProgress (5) --> Success (1) | Cancelled (2) | Skipped (3) |
                               UserSkipped (4) | Technical Issue (6) |
                               Completed without position (7)
```

## Blacklist System

Seven blacklist tables enforce eligibility restrictions at different granularity levels:

| Level | Table | Scope |
|-------|-------|-------|
| Global instrument | BlackListInstrumentID (54 entries) | Block specific instruments everywhere |
| Instrument + Country | BlackListInstrumentIDCountryID (8,127) | Block instruments per country |
| Instrument Type + Country | BlackListInstrumentTypeCountryID (10) | Block instrument categories per country |
| Exchange + Country | BlackListExchangeIDCountryID (0) | Block exchanges per country (unused) |
| Copy Parent (global) | BlackListCopyParentCID (22) | Block specific traders from being copied |
| Copy Parent + Country | BlackListCopyParentCIDAndCopierCountryID | Block trader+country combinations |
| Copier Country | BlackListCopierCountryID (2) | Block countries from all copy trading |

## Dictionary Tables (13)

All value domains used by Plans and PlanInstances: PlanStatus, PlanType, PlanFrequencies, CopyType, MopType, HighLevelDepositStatus, OrderStatus, PositionStatus, InstanceStatusID, MirrorOrderCreated, CopyPositionStatusID, CopyFailErrorCode, PlanEventCode (67 event codes across 12 ranges).

## User Defined Types (11)

Table-valued parameter types for batch operations: CancelPlansType, PlansType/CopyVersion, PlanInstancesType, PlanInstancesDepositsType/V2/CopyVersion, PlanInstancesTypeUpdateStatus/UpdateStatus, IntType, RecurringDepositIDListType.

## Stored Procedures (52)

| Category | Count | Examples |
|----------|-------|---------|
| Blacklist getters | 7 | BlacklistInstrumentIDsGetAll, BlacklistCopierCountryIDGetAll |
| Plan CRUD | 5 | PlanInsert, PlanUpdate, PlansGetByGCID, PlansGetByPlanID |
| Plan queries | 10 | PlansGetActivePlansToCreateNewInstanceRecord, PlansGetPlansMissingDepositPlanID |
| Instance CRUD | 4 | PlanInstanceInsert, PlanInstanceUpdate, PlanInstancesInsertMultiple |
| Instance queries | 15 | PlanInstanceGetPendingOrders, PlanInstanceGetCopyPendingOrders |
| Deposit upserts | 3 | PlanInstanceUserDepositUpsert, ...Upsert_CopyVersion |
| Batch operations | 4 | UpdatePlansAndUpsertInstances, PlansCancelAllUserPlansUpdateInstanceStatus |
| Combined queries | 4 | PlanGetPlanAndItsInstanceByInstanceId, PlansGetPlansAndItsLatestInstance |

## Confluence Sources

- [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) - Complete table documentation
- [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) - System architecture, jobs, sequence diagrams
- [Recurring Investment - Available Balance HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13828784154) - Balance checking

---

*Schema documentation completed: 2026-04-13 | Objects: 86 | Average quality: 9.1 | Batches: 4*
