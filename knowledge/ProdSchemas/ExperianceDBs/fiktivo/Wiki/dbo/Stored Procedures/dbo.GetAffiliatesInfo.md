# dbo.GetAffiliatesInfo

> Returns rich textual and financial profile information for a batch of affiliates, including formatted payment details across three payment slots, commission plan name, group, and eToro CID resolved by cross-referencing trading account usernames and GCIDs against the real-money platform.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateIDs (batch via IDTableType) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary bulk affiliate info loader used by the AffWiz back office for displaying affiliate summaries in grids and reports. It accepts a table-valued parameter of AffiliateIDs and returns a single denormalized summary row per affiliate including: contact/entity name, affiliate group, marketing channel, commission plan name, all three payment details as formatted human-readable strings (with method-specific details), verification status per payment slot, and the affiliate's CID on the eToro real-money trading platform. The CID resolution is the most complex step: it dynamically calls GetAffiliatesInfo_RealCustomers (a separate SP) to match trading account usernames and GCIDs to real customer CIDs across all three payment slots. Has been updated through multiple versions (FB25693, RD-369, ticket 52808, PART-76, PART-5531).

---

## 2. Business Logic

- Drops and recreates three temp tables (#A, #UserNameFromReal, #GCIDFromReal) at the start.
- Builds temp table #A by joining tblaff_Affiliates to AffiliateAdmin.AffiliatesGroups, tblaff_MarketingExpense, tblaff_AffiliateTypes, and all three PaymentDetails records.
- Contact display logic: uses EntityName if available and non-empty, otherwise concatenates Contact + AffiliateCustom1 (trimmed).
- Payment details are formatted as human-readable strings using CASE on PaymentMethodID (1-8: None, PayPal, Wire Transfer, eToro Trading, Neteller, Moneybookers, Webmoney, Credit Card).
- CID resolution: collects all trading account usernames (PaymentMethodID = 4) from all three payment slots plus LoginName_LOWER into a comma-separated string. Also collects GCIDs. Calls GetAffiliatesInfo_RealCustomers which returns (CID, GCID, UserName_LOWER) triples. Then performs five sequential UPDATEs to #A to match CIDs by UserName1, UserName2, UserName3, UserName4, and GCID (only updating rows still at CID = 0).
- Username comparisons use Latin1_General_BIN collation for case-sensitive matching.
- Final SELECT projects the summary columns from #A.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @AffiliateIDs | IDTableType (READONLY) | IN | (required) | High | Set of affiliate IDs to retrieve info for |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | dbo.tblaff_Affiliates | Read | Core affiliate record |
| LEFT JOIN | AffiliateAdmin.AffiliatesGroups | Read | Affiliate group name |
| LEFT JOIN | dbo.tblaff_MarketingExpense | Read | Marketing channel/expense name |
| LEFT JOIN | dbo.tblaff_AffiliateTypes | Read | Commission plan description |
| LEFT JOIN | dbo.tblaff_PaymentDetails (x3) | Read | Payment detail records for all three slots |
| EXEC | dbo.GetAffiliatesInfo_RealCustomers | Call | Cross-DB lookup to resolve CIDs from eToro trading platform |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliatesInfo
  ├── dbo.tblaff_Affiliates                  (READ)
  ├── AffiliateAdmin.AffiliatesGroups        (READ)
  ├── dbo.tblaff_MarketingExpense            (READ)
  ├── dbo.tblaff_AffiliateTypes              (READ)
  ├── dbo.tblaff_PaymentDetails              (READ x3)
  ├── dbo.GetAffiliatesInfo_RealCustomers    (EXEC - CID resolution)
  └── dbo.IDTableType                        (User-Defined Table Type)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Affiliates | Table | Core affiliate records |
| AffiliateAdmin.AffiliatesGroups | Table | Group names (migrated PART-5531) |
| dbo.tblaff_MarketingExpense | Table | Marketing channel names |
| dbo.tblaff_AffiliateTypes | Table | Commission plan descriptions |
| dbo.tblaff_PaymentDetails | Table | Payment method records (all three slots) |
| dbo.GetAffiliatesInfo_RealCustomers | Stored Procedure | CID resolution via cross-DB trading platform query |
| dbo.IDTableType | User-Defined Table Type | Input parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Load info for a specific set of affiliates
DECLARE @AffIDs dbo.IDTableType;
INSERT INTO @AffIDs (ID) VALUES (10001), (10002), (10003);
EXEC dbo.GetAffiliatesInfo @AffiliateIDs = @AffIDs;

-- Load info for a range of affiliates
DECLARE @AffIDs2 dbo.IDTableType;
INSERT INTO @AffIDs2
SELECT AffiliateID FROM dbo.tblaff_Affiliates WHERE AffiliateID BETWEEN 10001 AND 11000;
EXEC dbo.GetAffiliatesInfo @AffiliateIDs = @AffIDs2;

-- Load info for a single affiliate
DECLARE @Single dbo.IDTableType;
INSERT INTO @Single (ID) VALUES (12345);
EXEC dbo.GetAffiliatesInfo @AffiliateIDs = @Single;
```

---

## 9. Atlassian Knowledge Sources

- PART-5531 - Gil Haba, 08/02/2026: Migrated to new AffiliateAdmin.AffiliatesGroups table.
- PART-76 - Gil Haba (Noga), 23/03/2022: Adding ISNULL to Description to solve bug.
- Ticket 52808 - Geri Reshef, 14/10/2018: AffWiz Fix Contact Name Presentation - DB Changes.
- RD-369 - Geri Reshef, 20/08/2018: Affwizz performance improvements.
- FB 25693 - Geri Reshef, 20/05/2015: Original creation.

---

*Generated: 2026-04-12 | Quality: 8.6/10*
*Object: dbo.GetAffiliatesInfo | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliatesInfo.sql*
