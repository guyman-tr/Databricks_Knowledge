# Review Needed — BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT

## Items for Human Review

### 1. VBT Definition Confirmation
- **IsVBT** is derived from ComplianceStateDB KycFlow tables where KYCFlowTypeID=2. Confirm that KYCFlowTypeID=2 specifically means "Video-Based Trading" (VBT) onboarding flow vs. another KYC flow variant. The external tables `External_ComplianceStateDB_Compliance_KycFlow` and `External_ComplianceStateDB_History_KycFlow` have no upstream wiki.

### 2. UC Target Resolution
- UC target, format, and partitioning are pending. Resolve during write-objects phase.

### 3. Downstream Consumer Identification
- No downstream SPs or views referencing this table were found in the SSDT scan. Confirm whether this table feeds any dashboards, reports, or downstream aggregations outside of Synapse (e.g., Tableau, Power BI, Databricks notebooks).

### 4. Refresh Schedule / Orchestration
- The SP `SP_CID_Daily_AcquisitionFunnel_VBT` takes a `@date` parameter. Confirm which orchestration system (Service Broker, ADF, Airflow) triggers this SP and at what priority relative to its dependencies (Fact_SnapshotCustomer, BI_DB_CIDFirstDates must be loaded first).

### 5. PlayerStatus Exclusion Logic
- The SP excludes `PlayerStatusID NOT IN (2, 4, 13)`. Confirm this still aligns with business requirements — notably, statuses 6 (Under Investigation), 7 (Scalpers Block), 8 (PayPal Investigation), 14 (Failed Verification) are NOT excluded despite being full-block statuses. Is this intentional?

---

*Generated: 2026-04-28 | Tier 4 items: 0 | Review items: 5*
