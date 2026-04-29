# BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation_Email — Column Lineage

## Writer SP
`BI_DB_dbo.SP_US_Mailing_Address_Non_US_Regulation` — daily TRUNCATE+INSERT (latest DateRelevance snapshot from parent table)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation | BI_DB_dbo | Parent table — reads WHERE DateRelevance = MAX(DateRelevance) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RealCID | BI_DB_US_Mailing_Address_Non_US_Regulation | RealCID | passthrough |
| FirstDepositDate | BI_DB_US_Mailing_Address_Non_US_Regulation | FirstDepositDate | passthrough |
| VerificationLevelID | BI_DB_US_Mailing_Address_Non_US_Regulation | VerificationLevelID | passthrough |
| Regulation | BI_DB_US_Mailing_Address_Non_US_Regulation | Regulation | passthrough |
| PlayerStatus | BI_DB_US_Mailing_Address_Non_US_Regulation | PlayerStatus | passthrough |
| VerificationLevel3Date | BI_DB_US_Mailing_Address_Non_US_Regulation | VerificationLevel3Date | passthrough |
| Equity | BI_DB_US_Mailing_Address_Non_US_Regulation | Equity | passthrough |
| DateRelevance | BI_DB_US_Mailing_Address_Non_US_Regulation | DateRelevance | passthrough (MAX value) |
| UpdateDate | BI_DB_US_Mailing_Address_Non_US_Regulation | UpdateDate | passthrough |
| KYC_Country | BI_DB_US_Mailing_Address_Non_US_Regulation | KYC_Country | passthrough |

**PHASE 10B CHECKPOINT: PASS**
