# dbo Schema Overview

## Purpose

The dbo schema in the RecurringInvestment database contains two categories of objects:

1. **SQL Server Diagram Infrastructure** (9 objects): Standard system objects for managing database diagrams in SSMS - the sysdiagrams table, fn_diagramobjects function, and 7 sp_*diagram* stored procedures. These are automatically generated and have no business logic.

2. **Business View** (1 object): `dbo.VW_Plans` - a denormalized view that JOINs the three core RecurringInvestment tables (Plans + PlanInstances + UserDeposits) for reporting and troubleshooting.

## Object Inventory

| Type | Count | Business Objects |
|------|-------|-----------------|
| Tables | 1 | sysdiagrams (system) |
| Views | 1 | **VW_Plans** (business) |
| Functions | 1 | fn_diagramobjects (system) |
| Stored Procedures | 7 | sp_*diagram* (all system) |
| **Total** | **10** | **1 business, 9 system** |

## Key Business Object: dbo.VW_Plans

The only business-relevant object in this schema. Provides a flattened view of:
- **RecurringInvestment.Plans** (INNER JOIN) - plan configuration
- **RecurringInvestment.PlanInstances** (INNER JOIN) - execution cycle data
- **RecurringInvestment.UserDeposits** (LEFT JOIN) - deposit tracking

Created by Noga on 16/4/25 for ad-hoc querying and the AI Troubleshooting Service.

---

*Schema documentation completed: 2026-04-13 | Objects: 10 | Average quality: 9.0 | Batches: 1*
