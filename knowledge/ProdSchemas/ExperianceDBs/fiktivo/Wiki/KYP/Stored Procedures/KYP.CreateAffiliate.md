# KYP.CreateAffiliate

> Initializes a new KYP (Know Your Partner) record for an affiliate by inserting into KYP.Affiliate and bulk-inserting their promoted countries of operation.

| Property | Value |
|----------|-------|
| **Schema** | KYP |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AffiliateID (identifies the new KYP record) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYP.CreateAffiliate is the entry point for the KYP compliance flow. When an affiliate begins the Know Your Partner verification process, this procedure creates their initial KYP record with a starting status and progress value, and bulk-inserts their promoted countries of operation. This is typically called when the affiliate first accesses the KYP form in the affiliate portal.

The procedure runs in a transaction with XACT_ABORT ON, ensuring atomicity - either both the Affiliate record and CountriesOfOperation rows are created, or neither is. The TRY/CATCH block handles nested transaction semantics (rolling back only if this is the outermost transaction).

Created by Ran Ovadia (11/08/2020) for the KYP feature. Updated (06/03/2022, ONBRD-5948) by Gil Haba via Noga Rozen to add promoted countries to affiliate registration.

---

## 2. Business Logic

### 2.1 Transactional KYP Initialization

**What**: Creates KYP record and countries of operation atomically.

**Columns/Parameters Involved**: `@AffiliateID`, `@CountriesOfOperationIDs`, `@StatusID`, `@Progress`

**Rules**:
- Step 1: INSERT into KYP.Affiliate with (AffiliateID, KYPStatusID=@StatusID, Progress=@Progress)
- Step 2: INSERT into KYP.AffiliateCountriesOfOperation by SELECT from @CountriesOfOperationIDs TVP
- @CountriesOfOperationIDs is an IDTableType (table-valued parameter with ID column) containing the promoted/default countries
- Typical initial values: KYPStatusID=2 (Unverified), Progress=25
- Transaction ensures both inserts succeed or both fail

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | The affiliate ID to create a KYP record for. Must not already exist in KYP.Affiliate (PK violation otherwise). References dbo.tblaff_Affiliates. |
| 2 | @CountriesOfOperationIDs | IDTableType (IN, READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing country IDs to insert as initial countries of operation. Each row has an ID column mapping to dbo.tblaff_Country.CountryID. Typically pre-populated with promoted/default countries. |
| 3 | @StatusID | int (IN) | NO | - | CODE-BACKED | Initial KYP status. Maps to Dictionary.KYPStatus. Typically 2 (Unverified) for new affiliates. |
| 4 | @Progress | int (IN) | NO | - | CODE-BACKED | Initial form completion percentage. Typically 25 (starting value). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateID | KYP.Affiliate | INSERT | Creates the KYP record |
| @CountriesOfOperationIDs | KYP.AffiliateCountriesOfOperation | INSERT | Bulk inserts initial countries |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYP.CreateAffiliate (procedure)
├── KYP.Affiliate (table)
└── KYP.AffiliateCountriesOfOperation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | INSERT new KYP record |
| KYP.AffiliateCountriesOfOperation | Table | INSERT initial countries |
| IDTableType | UDT (dbo) | TVP for country IDs |

### 6.2 Objects That Depend On This

No dependents found in the KYP schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Create a new KYP record with countries
```sql
DECLARE @Countries IDTableType
INSERT @Countries VALUES (1), (106), (219)
EXEC KYP.CreateAffiliate @AffiliateID = 99999, @CountriesOfOperationIDs = @Countries, @StatusID = 2, @Progress = 25
```

### 8.2 Verify the record was created
```sql
SELECT AffiliateID, KYPStatusID, Progress
FROM KYP.Affiliate WITH (NOLOCK)
WHERE AffiliateID = 99999
```

### 8.3 Check the countries were inserted
```sql
SELECT CountryID FROM KYP.AffiliateCountriesOfOperation WITH (NOLOCK) WHERE AffiliateID = 99999
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: KYP.CreateAffiliate | Type: Stored Procedure | Source: fiktivo/KYP/Stored Procedures/KYP.CreateAffiliate.sql*
