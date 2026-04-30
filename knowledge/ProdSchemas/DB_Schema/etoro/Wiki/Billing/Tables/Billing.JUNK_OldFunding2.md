# Billing.JUNK_OldFunding2

> Historical copy of the Billing.Funding structure from a prior schema iteration; marked as "JUNK" (deprecated) and dropped from the live database but preserved in SSDT source control. The "JUNK_" prefix is eToro's convention for tables pending removal.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | FundingID - IDENTITY(1000,1) PK CLUSTERED |
| **Partition** | MAIN filegroup |
| **Indexes** | 6 (PK + 4 nonclustered + 1 primary XML) |
| **Live Status** | DROPPED - does not exist in the database |

---

## 1. Business Meaning

`Billing.JUNK_OldFunding2` is a historical artifact - a copy of the `Billing.Funding` table structure from a prior iteration of the funding data model. The "JUNK_" prefix is eToro's convention for tables that have been deprecated and are pending removal from source control.

The table no longer exists in the live database (attempting to query it returns "Invalid object name"). The SSDT source file was preserved but the object was dropped. This is the second archived version of the old funding table structure ("OldFunding2" suggests "OldFunding" or "OldFunding1" predated it).

The structure mirrors `Billing.Funding` with:
- IDENTITY starting at 1000 (not 1) - indicates it was likely a renamed copy of a table already containing records
- DDM masking on FundingData (`MASKED WITH (FUNCTION = 'default()')`)
- Computed columns: FundingDataCheckSum, SecuredCardData (via `[dbo].[SecuredCardData]()`), Parameter (via `[dbo].[F_FundingData]()`)
- FK to BackOffice.Manager(ManagerID)
- 5 indexes on key query patterns + 1 primary XML index on FundingData

---

## 2. Business Logic

No active business logic. The table is dropped from the database.

For the current funding data model, see `Billing.Funding`.

---

## 3. Data Overview

Table does not exist in the live database. Row count cannot be determined. The IDENTITY(1000,1) seed suggests the table previously held data (records with FundingID >= 1000 from a prior era of the schema).

---

## 4. Elements

All elements mirror `Billing.Funding` - see that table for current definitions.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int IDENTITY(1000,1) NOT FOR REPLICATION | NO | auto | CODE-BACKED | Historical surrogate PK. IDENTITY starting at 1000 (not 1) - table was a renamed copy of an existing table. NOT FOR REPLICATION flag. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. Implicit FK to Dictionary.FundingType. |
| 3 | ManagerID | int | YES | - | CODE-BACKED | Manager/agent associated with this funding record. FK to BackOffice.Manager(ManagerID) via FK_BMNG_BNFND. |
| 4 | IsBlocked | bit | NO | - | CODE-BACKED | Whether this funding instrument was blocked. |
| 5 | BlockedDescription | varchar(255) | YES | - | CODE-BACKED | Reason for blocking. |
| 6 | BlockedAt | datetime | YES | - | CODE-BACKED | When blocking occurred. |
| 7 | FundingData | xml MASKED | YES | - | CODE-BACKED | XML funding instrument details. DDM masked (default()) - non-privileged users see NULL. |
| 8 | IsRefundExcluded | bit | NO | 0 | CODE-BACKED | Refund exclusion flag. |
| 9 | DocumentRequired | bit | NO | 0 | CODE-BACKED | Document requirement flag. |
| 10 | FundingDataCheckSum | computed | NO | - | CODE-BACKED | CHECKSUM(CONVERT(nvarchar(1000), FundingData)) - deduplication hash for the FundingData XML. |
| 11 | SecuredCardData | computed | NO | - | CODE-BACKED | Result of [dbo].[SecuredCardData](FundingData) - extracts the secured card token from FundingData XML. |
| 12 | DateCreated | datetime | YES | GETUTCDATE() | CODE-BACKED | UTC creation timestamp. |
| 13 | Parameter | computed | NO | - | CODE-BACKED | Result of [dbo].[F_FundingData](FundingTypeID, FundingData) - extracts a key parameter from FundingData based on funding type. Indexed for lookups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerID | BackOffice.Manager | FK (explicit: FK_BMNG_BNFND) | Agent/manager association |

### 5.2 Referenced By (other objects point to this)

No references found. This table is not referenced by any stored procedures (it is dropped from the database).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.JUNK_OldFunding2 (table - DROPPED from live DB)
|- BackOffice.Manager (table) [FK: ManagerID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | FK target - manager association |
| dbo.SecuredCardData | Scalar Function | Computed column extraction |
| dbo.F_FundingData | Scalar Function | Computed column extraction |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_BillingNewFund | CLUSTERED PK | FundingID ASC | FILLFACTOR 100 |
| BFND_FUNDINGTYPE | NONCLUSTERED | FundingTypeID ASC | - |
| IX_BillingFundingParameter | NONCLUSTERED | Parameter ASC | Computed column index |
| IX_BillingFunding_FundingDataCheckSum | NONCLUSTERED | FundingDataCheckSum ASC | Dedup hash index |
| Idx_BillingFunding_Parameter | NONCLUSTERED | FundingTypeID ASC, Parameter ASC | Composite |
| Idx_Billing_Funding_SecuredCardData_FundingTypeID | NONCLUSTERED | SecuredCardData ASC, FundingTypeID ASC | Card token lookup |
| BFND_XMLPRIMARY | PRIMARY XML INDEX | FundingData | XML query optimization |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingNewFund | PRIMARY KEY CLUSTERED | FundingID |
| DF_NewFunding_IsRefundExcluded | DEFAULT | IsRefundExcluded = 0 |
| DF_BNF_DocumentRequired | DEFAULT | DocumentRequired = 0 |
| DF_BillingFunding_DateCreated | DEFAULT | DateCreated = GETUTCDATE() |
| FK_BMNG_BNFND | FOREIGN KEY | ManagerID -> BackOffice.Manager |

---

## 8. Sample Queries

### 8.1 This table does not exist in the live database
```sql
-- This will fail with "Invalid object name":
SELECT COUNT(*) FROM Billing.JUNK_OldFunding2;

-- Use the active Funding table instead:
SELECT TOP 5 FundingID, FundingTypeID, IsBlocked, DateCreated
FROM   Billing.Funding WITH (NOLOCK)
ORDER BY FundingID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 6.0/10 (Elements: 7/10, Logic: 3/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.JUNK_OldFunding2 | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.JUNK_OldFunding2.sql*
