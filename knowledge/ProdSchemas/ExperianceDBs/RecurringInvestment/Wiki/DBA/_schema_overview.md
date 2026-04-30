# DBA Schema Overview

## Purpose

The DBA schema contains database administration infrastructure. Currently holds a single table used for deployment tracking.

## Object Inventory

| Type | Count | Objects |
|------|-------|---------|
| Tables | 1 | DBA.UpgradeScript |

## DBA.UpgradeScript

Migration tracking table recording every upgrade script executed against the RecurringInvestment database. Contains 52 records tracking deployments from database creation through the most recent migration (EDGE-6637, 2026-02-10). Features an INSERT trigger that stores the script name in CONTEXT_INFO for session-level audit tracking.

Primary deployer: nogaro@etoro.com (Noga). All scripts reference EDGE Jira tickets.

---

*Schema documentation completed: 2026-04-13 | Objects: 1 | Quality: 9.2 | Batches: 1*
