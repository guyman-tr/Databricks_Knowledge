# Billing.FundingStatus

> Per-funding validity status override table. Each row marks a specific FundingID as either Partial (0) or Valid (1), overriding its completeness state. One row per FundingID (enforced by application MERGE logic). Currently empty - designed but not yet populated in production.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID - IDENTITY(1,1) PRIMARY KEY CLUSTERED |
| **Row Count** | 0 rows (empty) |
| **Partition** | N/A - filegroup DICTIONARY (unusual for Billing table) |
| **Indexes** | 1 CLUSTERED PK on ID |

---

## 1. Business Meaning

`Billing.FundingStatus` is a lightweight override table that records the data-completeness status of individual payment instruments. While `Billing.Funding` stores the instrument data itself and `Billing.CustomerToFunding` records per-customer activation status, `Billing.FundingStatus` records whether the underlying funding data is fully populated (Valid) or only partially collected (Partial).

The table is designed with one row per FundingID (the `UpsertFundingStatus` MERGE keys on FundingID). The IDENTITY `ID` column is the physical PK but has no application-layer significance.

**Current state**: 0 rows. The table was created and the upsert procedure exists, but no data has been written. This suggests the feature is either in development, only used in non-production environments, or recently deprecated.

**Filegroup note**: Stored on `DICTIONARY` filegroup, which typically holds reference/lookup data. This is unusual for a transaction-adjacent Billing table.

---

## 2. Business Logic

### 2.1 Upsert Pattern - One Row Per Funding

**Procedure**: `Billing.UpsertFundingStatus(@FundingID, @FundingStatusID)`

MERGE on FundingID (not ID):
- Row exists for FundingID -> UPDATE FundingStatusID
- No row -> INSERT new (FundingID, FundingStatusID)

The IDENTITY `ID` is not used for lookup. FundingID is the logical key by application convention.

### 2.2 FundingStatusID Values (Dictionary.FundingStatus)

| FundingStatusID | Name | Meaning |
|----------------|------|---------|
| 0 | Partial | Payment instrument data is incomplete (e.g., missing required fields) |
| 1 | Valid | Payment instrument data is fully populated and usable |

---

## 3. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **ID** | int IDENTITY(1,1) | NOT NULL | Auto | - | [CODE-BACKED] Surrogate PK. Auto-incrementing identity; not used as application-layer key. |
| **FundingID** | int | NOT NULL | - | Billing.Funding(FundingID) [implicit] | [CODE-BACKED] Payment instrument ID. Application-layer unique key (MERGE keys on this). References Billing.Funding. No explicit FK constraint defined. |
| **FundingStatusID** | int | NOT NULL | - | Dictionary.FundingStatus(FundingStatusID) [implicit] | [CODE-BACKED] Validity status. 0=Partial, 1=Valid. No explicit FK constraint. See 2.2 for values. |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| (unnamed PK) | CLUSTERED | ID ASC | FILLFACTOR=95. Physical PK on identity column. |

---

## 5. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.UpsertFundingStatus` | MERGE on FundingID: INSERT new status row or UPDATE existing FundingStatusID |

---

## 6. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Funding | Many-to-one | FundingStatus.FundingID = Funding.FundingID | Implicit (no FK constraint). One status row per funding. |
| Dictionary.FundingStatus | Many-to-one | FundingStatus.FundingStatusID = FundingStatus.FundingStatusID | Implicit (no FK constraint). 2-value lookup: 0=Partial, 1=Valid. |

---

*Quality: 8.8/10 | 3 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,8,9,11 | Note: Table is empty in production*
