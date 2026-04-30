# AffiliateCommission.InsertRegistration

> Atomically creates a registration record with commission and metadata in a single transaction, with idempotency that returns the existing RegistrationID for duplicate CIDs.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RegistrationID OUTPUT - generated or existing |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertRegistration is the primary data writer for customer registrations entering the affiliate commission system. When a customer registers on the platform and is attributed to an affiliate, this procedure atomically creates three linked records: Registration (the event), RegistrationCommission (the affiliate's commission for the referral), and RegistrationMetaData (the full attribution context).

The procedure implements idempotency by checking if a registration already exists for the CID. If it does, the existing RegistrationID is returned without creating duplicates. If it's a new registration, all three records are created in a single transaction with the generated RegistrationID linking them together.

This procedure is the entry point for the entire registration commission pipeline. The RegistrationMetaData created here is subsequently used by all other commission calculations (credit, closed position) to attribute revenue to the correct affiliate.

---

## 2. Business Logic

### 2.1 Idempotent Registration with Three-Table Insert

**What**: Creates Registration + RegistrationCommission + RegistrationMetaData atomically, or returns existing RegistrationID for duplicate CIDs.

**Columns/Parameters Involved**: `@CID`, `@RegistrationID` (OUTPUT)

**Rules**:
- First: SELECT existing RegistrationID WHERE CID = @CID
- If exists: returns the existing ID, no further inserts (idempotent)
- If new: BEGIN TRAN -> INSERT Registration (generates RegistrationID via SCOPE_IDENTITY()) -> INSERT RegistrationCommission from TVP -> INSERT RegistrationMetaData -> COMMIT
- @RegistrationID OUTPUT is always set - either existing or newly generated
- Error handling: conditional ROLLBACK/COMMIT for nested transactions, always re-THROW

### 2.2 Comprehensive Attribution Capture

**What**: RegistrationMetaData captures the complete attribution context at registration time.

**Columns/Parameters Involved**: `@AffiliateID`, `@AffiliateCampaign`, `@BannerID`, `@DownloadID`, `@CountryID`, `@FunnelID`, `@PlayerLevelID`, `@OriginalCID`, `@GCID`, `@AdditionalData`, `@EtoroUserName`

**Rules**:
- All attribution fields are captured once at registration time
- Subsequent changes to attribution are handled by UpdateMetaData (not this procedure)
- The metadata becomes the source of truth for all commission attribution queries via GetMetaDataByCID/GetMetaDataByGCID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateCampaign | nvarchar(1024) (IN) | YES | NULL | CODE-BACKED | Campaign from affiliate tracking link. |
| 2 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | Referring affiliate. |
| 3 | @RegistrationDate | datetime (IN) | NO | - | CODE-BACKED | When the customer registered. |
| 4 | @BannerID | int (IN) | NO | - | CODE-BACKED | Banner/creative identifier. |
| 5 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID. Used for idempotency check. |
| 6 | @GCID | bigint (IN) | NO | - | CODE-BACKED | Global Customer ID. |
| 7 | @OriginalCID | bigint (IN) | NO | - | CODE-BACKED | Original CID for legacy mapping. |
| 8 | @DownloadID | bigint (IN) | NO | - | CODE-BACKED | Mobile app download ID from AppsFlyer. |
| 9 | @ProviderID | bigint (IN) | NO | - | CODE-BACKED | Current provider. |
| 10 | @OriginalProviderID | bigint (IN) | NO | - | CODE-BACKED | Original provider. |
| 11 | @RealProviderID | bigint (IN) | NO | - | CODE-BACKED | Actual executing provider. |
| 12 | @CountryID | bigint (IN) | NO | - | CODE-BACKED | Customer's country. |
| 13 | @FunnelID | int (IN) | YES | NULL | CODE-BACKED | Registration funnel. |
| 14 | @PlayerLevelID | int (IN) | YES | NULL | CODE-BACKED | Player level classification. |
| 15 | @AdditionalData | varchar(512) (IN) | YES | NULL | CODE-BACKED | Free-form extended tracking data. Added PART-3606. |
| 16 | @TrackingDate | datetime (IN) | NO | - | CODE-BACKED | When the registration was tracked. Used for anti-fraud timing validation. |
| 17 | @Valid | bit (IN) | NO | - | CODE-BACKED | Whether the registration is eligible for commission. |
| 18 | @EtoroUserName | varchar(50) (IN) | YES | NULL | CODE-BACKED | Customer's username. Added ONBRD-9494. |
| 19 | @AffiliateCommission | RegistrationCommissionType (IN, TVP) | NO | - | CODE-BACKED | TVP with per-affiliate, per-tier registration commission rows. |
| 20 | @RegistrationID | bigint (OUTPUT) | NO | - | CODE-BACKED | Generated or existing RegistrationID. Always set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.Registration | WRITE (INSERT) + READ (SELECT) | Creates registration; checks for existing CID |
| - | AffiliateCommission.RegistrationCommission | WRITE (INSERT) | Creates commission rows from TVP |
| - | AffiliateCommission.RegistrationMetaData | WRITE (INSERT) | Creates attribution metadata |
| @AffiliateCommission | AffiliateCommission.RegistrationCommissionType | TVP | Table-valued parameter type |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the registration processing pipeline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.InsertRegistration (procedure)
+-- AffiliateCommission.Registration (table)
+-- AffiliateCommission.RegistrationCommission (table)
+-- AffiliateCommission.RegistrationMetaData (table)
+-- AffiliateCommission.RegistrationCommissionType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Registration | Table | INSERT + SELECT for idempotency, SCOPE_IDENTITY() for RegistrationID |
| AffiliateCommission.RegistrationCommission | Table | INSERT from TVP |
| AffiliateCommission.RegistrationMetaData | Table | INSERT with attribution context |
| AffiliateCommission.RegistrationCommissionType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Registration processing pipeline) | External | Persists processed registrations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | TRAN | Atomic insert of Registration + RegistrationCommission + RegistrationMetaData |

---

## 8. Sample Queries

### 8.1 Insert a registration
```sql
DECLARE @CommData AffiliateCommission.RegistrationCommissionType
INSERT @CommData (AffiliateID, Commission, Tier, Paid, PaymentID)
VALUES (3, 10.00, 1, 0, 0)

DECLARE @NewRegID BIGINT
EXEC [AffiliateCommission].[InsertRegistration]
    @AffiliateID = 3, @RegistrationDate = '2026-04-12',
    @BannerID = 100, @CID = 12345, @GCID = 67890,
    @OriginalCID = 12345, @DownloadID = 0,
    @ProviderID = 1, @OriginalProviderID = 1, @RealProviderID = 1,
    @CountryID = 1, @TrackingDate = '2026-04-12', @Valid = 1,
    @AffiliateCommission = @CommData, @RegistrationID = @NewRegID OUTPUT

SELECT @NewRegID AS RegistrationID
```

### 8.2 Check registration and metadata for a customer
```sql
SELECT r.RegistrationID, r.CID, r.RegistrationDate, m.AffiliateID, m.AffiliateCampaign, m.CountryID
FROM [AffiliateCommission].[Registration] AS r WITH (NOLOCK)
INNER JOIN [AffiliateCommission].[RegistrationMetaData] AS m WITH (NOLOCK)
    ON r.CID = m.CID AND m.PartitionCol = r.CID % 50
WHERE r.CID = 12345
```

### 8.3 View registration with commission breakdown
```sql
SELECT r.RegistrationID, r.CID, rc.AffiliateID, rc.Commission, rc.Tier
FROM [AffiliateCommission].[Registration] AS r WITH (NOLOCK)
INNER JOIN [AffiliateCommission].[RegistrationCommission] AS rc WITH (NOLOCK)
    ON r.RegistrationID = rc.RegistrationID
WHERE r.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- ONBRD-9494: Added EtoroUserName (2026-03-04)
- PART-3606: Added AdditionalData (2024-10-21)
- PART-2448: CPA New Compensation Design + CountryID (2023-12-17)
- PART-1278: Add update of IsProcess field (2023-03-22)
- PART-1195: Added SP output RegistrationID (2022-02-22)
- Unlabeled: Disabled write to old tblaff tables (2023-04-19)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.InsertRegistration | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.InsertRegistration.sql*
