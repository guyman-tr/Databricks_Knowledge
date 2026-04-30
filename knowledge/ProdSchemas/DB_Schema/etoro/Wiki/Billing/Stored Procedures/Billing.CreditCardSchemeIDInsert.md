# Billing.CreditCardSchemeIDInsert

> Upserts a checkout.com SchemeID (recurring-payment token) for a CID+FundingID pair into `Billing.CreditCardSchemeID`; upgrades a non-3DS entry to a 3DS-verified one if @IsThreeDs=1, but never downgrades an existing 3DS entry.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID (composite MERGE key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CreditCardSchemeIDInsert` maintains the `Billing.CreditCardSchemeID` table, which stores checkout.com SchemeIDs that enable Merchant Initiated Transactions (MIT) - recurring charges made without requiring the customer to re-authenticate. When a customer successfully deposits using a credit card, checkout.com returns a SchemeID that can be used for future charges on the same card.

The procedure was created June 2021 by Shay O. (PAYUS-2720) as the central writer for `Billing.CreditCardSchemeID`. It implements a quality-preserving upsert: if a card already has a 3DS-verified SchemeID (IsThreeDs=1), it is never overwritten - 3DS authentication provides the strongest liability protection. If only a non-3DS SchemeID exists and a 3DS-verified one arrives, the record is upgraded.

As of 2026-03-17, the table holds ~2.82M records: 17.8K (0.6%) with IsThreeDs=1 (3DS-verified) and 2.80M (99.4%) with IsThreeDs=0 (non-3DS tokens).

---

## 2. Business Logic

### 2.1 MERGE: 3DS-Quality-Preserving Upsert

**What**: Atomically inserts or conditionally updates the SchemeID record for a CID+FundingID pair.

**MERGE Key**: `CCS.CID = @CID AND CCS.FundingID = @FundingID`

**INSERT path** (WHEN NOT MATCHED): Record does not exist for this CID+FundingID -> insert new row with all provided values.

**UPDATE path** (WHEN MATCHED AND CCS.IsThreeDs = 0 AND @IsThreeDs = 1): Existing record is non-3DS, incoming SchemeID is 3DS-verified -> upgrade the record (SchemeID, DepositID, IsThreeDs all updated).

**No-op path** (implicitly, WHEN MATCHED but condition not met):
- Existing IsThreeDs=1 and @IsThreeDs=1 -> no update (3DS entry already at highest quality)
- Existing IsThreeDs=1 and @IsThreeDs=0 -> no update (never downgrade 3DS to non-3DS)
- Existing IsThreeDs=0 and @IsThreeDs=0 -> no update (same quality, first-write wins)

**Logic summary**:
```
IsThreeDs matrix (existing -> incoming):
  0 -> 0: no update  (keep first non-3DS SchemeID)
  0 -> 1: UPDATE     (upgrade to 3DS-verified - liability shift benefit)
  1 -> 0: no update  (never downgrade from 3DS)
  1 -> 1: no update  (already 3DS, keep original)
```

### 2.2 OUTPUT Clause

**What**: `OUTPUT Inserted.*` returns the full inserted or updated row to the caller.

**Rules**: Only rows actually modified (INSERT or UPDATE) produce OUTPUT rows. The no-op case (WHEN MATCHED but condition not met) produces no output row.

**Caller use**: The caller (Deposit service) uses the output to confirm the SchemeID was stored and to obtain the final stored values.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | NO | - | VERIFIED | The customer's payment instrument (registered card) record. Part of the MERGE composite key. References Billing.Funding.FundingID. One customer may have multiple FundingIDs (multiple cards). |
| 2 | @CID | INT | NO | - | VERIFIED | Customer ID whose card is being associated with a SchemeID. Part of the MERGE composite key. Implicit FK to Customer.CustomerStatic. |
| 3 | @SchemeID | NVARCHAR(255) | NO | - | VERIFIED | checkout.com SchemeID returned after a successful deposit. This token enables future MIT (Merchant Initiated Transaction) charges on this card without customer re-authentication. Stored in Billing.CreditCardSchemeID.SchemeID. |
| 4 | @DepositID | INT | NO | - | VERIFIED | The deposit transaction that produced this SchemeID. Used for audit trail - traces which specific deposit generated the token. Written to Billing.CreditCardSchemeID.DepositID. Updated when upgrading from non-3DS to 3DS. |
| 5 | @IsThreeDs | BIT | NO | - | VERIFIED | Whether the SchemeID was obtained via 3DS authentication. 1=3DS-verified (highest quality, provides liability shift to card network). 0=non-3DS. Governs the upgrade logic: a 3DS SchemeID always wins over a non-3DS one; once stored, a 3DS entry is never overwritten. |

**Result set** (via OUTPUT Inserted.*): Returns all columns of `Billing.CreditCardSchemeID` for the inserted/updated row. Returns nothing (no rows) on no-op MERGE paths.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID | Billing.CreditCardSchemeID | Write (UPSERT) | Inserts or upgrades SchemeID record for the CID+FundingID pair |
| @FundingID | Billing.Funding | Implicit | The card being used for the deposit; Funding record must exist |
| @DepositID | Billing.Deposit | Implicit | The deposit that generated the SchemeID; audit trail reference |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit service | All params | Caller | Called after a successful CC deposit to store/upgrade the SchemeID returned by checkout.com (PAYUS-2720) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CreditCardSchemeIDInsert (procedure)
+-- Billing.CreditCardSchemeID (table) [MERGE target]
      +-- Billing.Funding (implicit FK on FundingID)
      +-- Customer.CustomerStatic (implicit FK on CID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardSchemeID | Table | MERGE target for SchemeID upsert |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit service | External | Calls after successful CC deposit to persist SchemeID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**MERGE semantics**: Unlike `CreditCardAuthentication_Update` which uses ISNULL partial-update, this procedure uses SQL MERGE for true atomicity. The INSERT and conditional UPDATE happen in a single atomic statement - no race condition between check and write.

**No transaction wrapper**: MERGE is inherently atomic for the single target row. No explicit transaction needed.

**OUTPUT Inserted.***: Note this returns `Inserted.*` not `$action, Inserted.*, Deleted.*`. For an UPDATE, `Inserted` contains the new row values (not the old values). The caller only gets the final state.

---

## 8. Sample Queries

### 8.1 Store a new non-3DS SchemeID after deposit

```sql
EXEC Billing.CreditCardSchemeIDInsert
    @FundingID = 2147794,
    @CID = 25466492,
    @SchemeID = N'060720116005060',
    @DepositID = 10782266,
    @IsThreeDs = 0
-- Returns Inserted.* if new record created, or nothing if already exists
```

### 8.2 Upgrade existing non-3DS to 3DS-verified SchemeID

```sql
EXEC Billing.CreditCardSchemeIDInsert
    @FundingID = 2147794,
    @CID = 25466492,
    @SchemeID = N'src_abc123_3ds_verified',
    @DepositID = 10999999,
    @IsThreeDs = 1
-- If existing IsThreeDs=0: updates record, returns new row
-- If existing IsThreeDs=1: no-op, returns nothing
```

### 8.3 View 3DS vs non-3DS SchemeID distribution

```sql
SELECT
    CASE IsThreeDs WHEN 1 THEN '3DS-Verified' ELSE 'Non-3DS' END AS Type,
    COUNT(*) AS Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(10,2)) AS Pct
FROM Billing.CreditCardSchemeID WITH(NOLOCK)
GROUP BY IsThreeDs
-- As of 2026-03-17: ~17.8K 3DS, ~2.80M non-3DS
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUS-2720 | Jira | Initial implementation ticket (Shay O., June 2021) - SchemeID storage for recurring/MIT payment enablement |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CreditCardSchemeIDInsert | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CreditCardSchemeIDInsert.sql*
