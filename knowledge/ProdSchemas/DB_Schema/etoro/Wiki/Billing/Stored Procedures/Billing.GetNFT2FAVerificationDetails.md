# Billing.GetNFT2FAVerificationDetails

> Returns the 2FA verification record for a specific NFT operation - a cross-schema lookup from Billing into Customer.TwoFactorVerificationDetails by GCID and ReferenceID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @ReferenceID - returns the 2FA challenge record for this NFT operation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetNFT2FAVerificationDetails` retrieves the 2FA (two-factor authentication) record associated with an NFT redemption or transfer operation. When a customer initiates an NFT withdrawal, the system requires 2FA confirmation before executing the blockchain transfer. This procedure checks whether the 2FA challenge for that specific operation has been completed successfully.

Despite residing in the `Billing` schema, the procedure reads from `Customer.TwoFactorVerificationDetails` - the cross-schema dependency reflects that NFT operations require the billing layer to verify authentication state from the customer identity layer.

The `ReferenceID` (a GUID) is the application-generated correlation key that ties a business operation (e.g., an NFT withdrawal) to a specific 2FA challenge. The `GCID` (Group Customer ID) scopes the lookup to the customer.

Created by Alexei 30/06/2022 (PTL-76).

---

## 2. Business Logic

### 2.1 2FA Record Lookup for NFT Operations

**What**: Looks up the 2FA verification record for a specific customer + operation reference.

**Columns/Parameters Involved**: `@GCID`, `@ReferenceID`, `Customer.TwoFactorVerificationDetails`

**Rules**:
- `WHERE GCID = @GCID AND ReferenceID = @ReferenceID` - exact match on both dimensions
- Returns at most one row (ReferenceID is a GUID PK in TwoFactorVerificationDetails, unique per 2FA challenge)
- Returns empty set if no 2FA challenge was issued for this operation
- `Success` in results indicates whether the 2FA was completed (1) or still pending/failed (0)
- `VerifySuccessDate` is NULL if not yet verified

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Group Customer ID. Scopes the 2FA lookup to this customer (customer ownership check). FK to Customer.CustomerStatic.GCID. |
| 2 | @ReferenceID | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Application-generated GUID correlating the 2FA challenge to the specific NFT operation. Matches Customer.TwoFactorVerificationDetails.ReferenceID (GUID PK). |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | ReferenceID | uniqueidentifier | NO | - | CODE-BACKED | GUID PK of the 2FA challenge record (echoed from input). |
| 4 | GCID | int | NO | - | CODE-BACKED | Group Customer ID (echoed from input). |
| 5 | VerificationDate | datetime | NO | - | CODE-BACKED | When the 2FA code was dispatched to the customer (SMS or voice call). |
| 6 | VerifySuccessDate | datetime | YES | NULL | CODE-BACKED | When the customer successfully entered the correct code. NULL if not yet verified. |
| 7 | Success | bit | NO | 0 | CODE-BACKED | Whether the 2FA challenge was successfully completed. 1=verified (customer entered correct code), 0=pending or failed. |
| 8 | VerificationTries | int | NO | 0 | CODE-BACKED | Number of incorrect code entry attempts so far. Incremented on each wrong entry by UpdateTwoFactorVerificationTries. |
| 9 | VerificationSendMethodTypeID | int | YES | NULL | CODE-BACKED | Channel used to send the OTP code. Typically: 1=SMS, 2=Voice call. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Customer.TwoFactorVerificationDetails | Cross-Schema Read | Retrieves the 2FA challenge record for the NFT operation's ReferenceID and GCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers. Called from the NFT withdrawal service to verify 2FA completion status. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetNFT2FAVerificationDetails (procedure)
└── Customer.TwoFactorVerificationDetails (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TwoFactorVerificationDetails | Table | FROM - reads 2FA challenge record by (GCID, ReferenceID) |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note**: `Customer.TwoFactorVerificationDetails` has a CLUSTERED index on (GCID, VerificationDate DESC) and a NONCLUSTERED PK on ReferenceID. The WHERE clause uses both GCID and ReferenceID - the query will use the NONCLUSTERED index on ReferenceID first (more selective as a GUID) or the clustered index depending on the optimizer's choice.

---

## 8. Sample Queries

### 8.1 Check 2FA status for an NFT operation

```sql
EXEC Billing.GetNFT2FAVerificationDetails
    @GCID        = 123456,
    @ReferenceID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
-- Returns the 2FA record; check Success=1 to confirm verification complete
```

### 8.2 Equivalent ad-hoc query

```sql
SELECT ReferenceID, GCID, VerificationDate, VerifySuccessDate,
       Success, VerificationTries, VerificationSendMethodTypeID
FROM Customer.TwoFactorVerificationDetails WITH (NOLOCK)
WHERE GCID = 123456
  AND ReferenceID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
```

---

## 9. Atlassian Knowledge Sources

PTL-76 (Alexei, 30/06/2022): Added procedure to support NFT 2FA verification in the crypto withdrawal flow.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetNFT2FAVerificationDetails | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetNFT2FAVerificationDetails.sql*
