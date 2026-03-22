# DWH_dbo.Dim_ExtendedUserField

> KYC extended user field dimension - maps field IDs to descriptive names for jurisdiction-specific and regulatory data fields collected from customers during onboarding.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | UserApiDB.Dictionary.ExtendedUserField |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_ExtendedUserField` is a 12-row dictionary (FieldIDs 0-11) mapping integer codes to names for jurisdiction-specific KYC (Know Your Customer) and regulatory data fields collected from eToro customers. "Extended user fields" are additional data points collected beyond the standard registration form, required by specific regulatory regimes or payment systems. The fields include address supplements (province, sub-building number), national identity documents (CodeFiscale for Italy, SocialInsuranceNumber for Canada, NIF for Spain), tax identifiers, national PIN numbers, employer information, and suitability/compliance questions.

The data originates from `UserApiDB.Dictionary.ExtendedUserField` on the `UserApiDB-REAL` production server. No upstream wiki exists for UserApiDB.Dictionary. The ETL loads from `DWH_staging.UserApiDB_Dictionary_ExtendedUserField` via `SP_Dictionaries_DL_To_Synapse` (TRUNCATE + INSERT pattern). Daily refresh; last updated 2026-03-11 (~8 days stale as of 2026-03-19).

The `FieldTypeID` column categorizes fields into type groups (e.g., address, national ID, tax) but there is no separate `Dim_FieldType` dimension in DWH to resolve these codes. No active DWH fact/dimension table uses `FieldID` as a foreign key in the current SSDT repo.

---

## 2. Business Logic

### 2.1 Extended Field Categories

**What**: The 12 fields group into regulatory/KYC categories by FieldTypeID.

**Columns Involved**: `FieldID`, `FieldTypeID`, `ExtendedUserFieldName`

**Rules**:
- FieldTypeID 0 (address): province, SubBuildingNumber
- FieldTypeID 1 (name): SecondSurname (Spanish/Latin naming conventions)
- FieldTypeID 2 (national ID documents): CodeFiscale (Italy), SocialInsuranceNumber (Canada), NIF (Spain/National Identity)
- FieldTypeID 3 (tax): TaxId
- FieldTypeID 4 (national pin): NationalPin
- FieldTypeID 5 (employment): EmployerName
- FieldTypeID 6 (deposit compliance): DepositQuestion
- FieldTypeID 7 (withdrawal compliance): WithdrawQuestion
- FieldTypeID 9 (EV): DedicatedEv (dedicated eVerification)
- FieldTypeID 8 is absent (no fields assigned)

**Diagram**:
```
FieldID | FieldTypeID | ExtendedUserFieldName  | Context
--------|-------------|------------------------|------------------
0       | 0           | province               | Address (jurisdiction)
1       | 1           | SecondSurname          | Spanish/Latin name
2       | 2           | CodeFiscale            | Italian tax code (national ID)
3       | 2           | SocialInsuranceNumber  | Canadian SIN (national ID)
4       | 2           | NIF                    | Spanish national ID
5       | 0           | SubBuildingNumber      | Address (unit/floor)
6       | 3           | TaxId                  | Tax identifier
7       | 4           | NationalPin            | National PIN
8       | 5           | EmployerName           | Employment
9       | 6           | DepositQuestion        | Compliance (deposit)
10      | 7           | WithdrawQuestion       | Compliance (withdrawal)
11      | 9           | DedicatedEv            | EV verification
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed (12 rows - appropriate). HEAP (no clustered index) - lookups perform full table scans, but with 12 rows this is negligible. REPLICATE means joins from any table incur no data movement.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 12 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode FieldID to field name | `LEFT JOIN DWH_dbo.Dim_ExtendedUserField ON FieldID` |
| Find all national ID fields | `WHERE FieldTypeID = 2` |
| Find compliance question fields | `WHERE FieldTypeID IN (6, 7)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| (No active FK consumers) | FieldID | Field is not currently used as FK in DWH |

### 3.4 Gotchas

- **HEAP index**: Unlike most Dim_ tables which use a CLUSTERED INDEX, this table uses HEAP. Synapse point-lookups on HEAP are full scans (fine for 12 rows, but structurally inconsistent).
- **FieldTypeID is unresolved**: There is no separate dimension table for FieldTypeID values. The type codes are understood only from the field names (inferred grouping).
- **Country-specific fields**: CodeFiscale is Italy-specific, SocialInsuranceNumber is Canada-specific, NIF is Spain-specific. These fields are only collected from users registered in those jurisdictions.
- **PII-sensitive names**: Several field names reference PII categories (TaxId, NationalPin, SocialInsuranceNumber). The field names themselves are safe but the UserApiDB table that stores field values (not this DWH dimension) would contain PII data.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FieldID | int | YES | Primary key. Integer identifier for an extended user field. Values: 0=province, 1=SecondSurname, 2=CodeFiscale, 3=SocialInsuranceNumber, 4=NIF, 5=SubBuildingNumber, 6=TaxId, 7=NationalPin, 8=EmployerName, 9=DepositQuestion, 10=WithdrawQuestion, 11=DedicatedEv. Renamed from `FieldId` in source. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 2 | FieldTypeID | int | YES | Category code grouping fields by type. Values observed: 0=address fields, 1=name fields, 2=national ID documents, 3=tax ID, 4=national PIN, 5=employment, 6=deposit compliance question, 7=withdrawal compliance question, 9=EV verification. No separate dimension table exists to decode FieldTypeID. Renamed from `FieldTypeId` in source. (Tier 3 - live data sampling) |
| 3 | ExtendedUserFieldName | varchar(30) | YES | Human-readable field name. Renamed from `Name` in source (prefix added). Values are short camelCase identifiers (e.g., province, CodeFiscale, NationalPin). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. Not from source. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FieldID | UserApiDB.Dictionary.ExtendedUserField | FieldId | rename: FieldId -> FieldID |
| FieldTypeID | UserApiDB.Dictionary.ExtendedUserField | FieldTypeId | rename: FieldTypeId -> FieldTypeID |
| ExtendedUserFieldName | UserApiDB.Dictionary.ExtendedUserField | Name | rename: Name -> ExtendedUserFieldName |
| UpdateDate | - | - | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
UserApiDB.Dictionary.ExtendedUserField -> Staging -> DWH_staging.UserApiDB_Dictionary_ExtendedUserField -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_ExtendedUserField
```

| Step | Object | Description |
|------|--------|-------------|
| Source | UserApiDB.Dictionary.ExtendedUserField | Extended user field dictionary on UserApiDB-REAL |
| Staging | DWH_staging.UserApiDB_Dictionary_ExtendedUserField | Raw import |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. 3 renames + UpdateDate=GETDATE(). |
| Target | DWH_dbo.Dim_ExtendedUserField | 12-row REPLICATE/HEAP dictionary. Daily refresh. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (None active) | FieldID | No active FK references in current DWH SSDT repo. |

---

## 7. Sample Queries

### 7.1 List all extended fields with category

```sql
SELECT FieldID, FieldTypeID, ExtendedUserFieldName
FROM DWH_dbo.Dim_ExtendedUserField
ORDER BY FieldTypeID, FieldID
```

### 7.2 Find national ID document fields

```sql
SELECT FieldID, ExtendedUserFieldName
FROM DWH_dbo.Dim_ExtendedUserField
WHERE FieldTypeID = 2  -- national ID category
```

### 7.3 Find compliance question fields

```sql
SELECT FieldID, ExtendedUserFieldName
FROM DWH_dbo.Dim_ExtendedUserField
WHERE FieldTypeID IN (6, 7)  -- deposit and withdrawal compliance questions
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 0 T1, 3 T2, 1 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10*
*Object: DWH_dbo.Dim_ExtendedUserField | Type: Table | Production Source: UserApiDB.Dictionary.ExtendedUserField*
