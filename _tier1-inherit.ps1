$emdash = [char]0x2014

# ── Upstream wiki column descriptions ──
# Extracted verbatim from DB_Schema wikis
$tier1 = @{}

# Source: Customer.CustomerStatic
$cs = 'Customer.CustomerStatic'
$tier1['RealCID']            = @($cs, 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.')
$tier1['GCID']               = @($cs, 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction.')
$tier1['OriginalCID']        = @($cs, 'Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0.')
$tier1['ID']                 = @($cs, 'System GUID for REST API identity. Default=newsequentialid() (sequential for index performance).')
$tier1['ExternalID']         = @($cs, 'APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format.')
$tier1['UserName']           = @($cs, 'Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).')
$tier1['FirstName']          = @($cs, 'Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1.')
$tier1['LastName']           = @($cs, 'Legal last name in Unicode. Used in LinkedAccountHash1.')
$tier1['MiddleName']         = @($cs, 'Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking.')
$tier1['Gender']             = @($cs, 'Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1.')
$tier1['BirthDate']          = @($cs, 'Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification.')
$tier1['Email']              = @($cs, 'Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger.')
$tier1['Phone']              = @($cs, 'Phone number from production Customer.CustomerStatic.')
$tier1['IP']                 = @($cs, 'Registration IP address.')
$tier1['Zip']                = @($cs, 'Postal code. Used in LinkedAccountHash1.')
$tier1['City']               = @($cs, 'City in Unicode.')
$tier1['Address']            = @($cs, 'Street address in Unicode.')
$tier1['BuildingNumber']     = @($cs, 'Building/apartment number. Separate from Address for structured address storage.')
$tier1['AffiliateID']        = @($cs, 'Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations.')
$tier1['CampaignID']         = @($cs, 'Marketing campaign ID under which the customer was acquired. FK to BackOffice.Campaign. NULL for organically acquired customers.')
$tier1['LabelID']            = @($cs, 'Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer (triggers IsHedged=0). Default=0.')
$tier1['BannerID']           = @($cs, 'Advertising banner ID that led to registration. Legacy acquisition tracking.')
$tier1['FunnelID']           = @($cs, 'Registration funnel ID. FK to Dictionary.Funnel. Tracks which user journey/funnel variant the customer came through. NULL when not tracked.')
$tier1['FunnelFromID']       = @($cs, 'Source funnel variant ID tracking where the customer came from within the acquisition funnel.')
$tier1['DownloadID']         = @($cs, 'Platform download source ID. Legacy tracking for which platform installer the customer used.')
$tier1['ReferralID']         = @($cs, 'Referral CID - the customer who referred this customer (for RAF program tracking).')
$tier1['SubSerialID']        = @($cs, 'Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths.')
$tier1['RegisteredReal']     = @($cs, 'Account registration date (renamed from Registered). Default=getdate().')
$tier1['AccountExpirationDate'] = @($cs, 'Expiration date for demo or time-limited accounts. NULL for standard real-money accounts.')
$tier1['AccountStatusID']    = @($cs, 'Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted.')
$tier1['PlayerStatusID']     = @($cs, 'Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0.')
$tier1['PlayerStatusReasonID'] = @($cs, 'Reason code for current PlayerStatusID. Provides the why behind a non-Active status.')
$tier1['PlayerStatusSubReasonID'] = @($cs, 'Sub-reason code for PlayerStatus (hierarchical). FK to Dictionary.PlayerStatusSubReasons. Added 2022 (COINF-1989).')
$tier1['PendingClosureStatusID'] = @($cs, 'Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure.')
$tier1['PlayerLevelID']      = @($cs, 'Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0.')
$tier1['CountryID']          = @($cs, 'Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0.')
$tier1['CountryIDByIP']      = @($cs, 'Country detected from the customer IP address at registration. Used for fraud detection and geo-comparison (CountryID vs CountryIDByIP mismatch flagging).')
$tier1['CitizenshipCountryID'] = @($cs, 'Country of citizenship (may differ from CountryID/residence). FK to Dictionary.Country. Added 2018 for enhanced KYC.')
$tier1['POBCountryID']       = @($cs, 'Place of birth country. FK to Dictionary.Country. Added for KYC (HLD: RD-4436).')
$tier1['RegionID']           = @($cs, 'Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation.')
$tier1['RegionByIP_ID']      = @($cs, 'Region detected from IP address. Separate from RegionID (profile-based) to allow mismatch detection.')
$tier1['LanguageID']         = @($cs, 'Customer preferred platform language. FK to Dictionary.Language. Controls UI language. Default=0.')
$tier1['CommunicationLanguageID'] = @($cs, 'Language for customer communications (emails, notifications). May differ from LanguageID if customer has different communication preferences.')
$tier1['IsEmailVerified']    = @($cs, 'Whether the email address has been verified by clicking a confirmation link. NULL for older accounts predating this flag.')
$tier1['PrivacyPolicyID']    = @($cs, 'Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy.')
$tier1['WeekendFeePrecentage'] = @($cs, 'Weekend swap fee percentage. Default=100 (full fee). Values below 100 indicate discounted weekend fees for select customers. Note: column name has typo Precentage.')
$tier1['ApexID']             = @($cs, 'APEX US stocks broker account ID. Only populated for US-regulated customers at Level >= 2 who have APEX accounts.')

# Source: BackOffice.Customer
$bo = 'BackOffice.Customer'
$tier1['AccountManagerID']   = @($bo, 'Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned.')
$tier1['GuruStatusID']       = @($bo, 'eToro Popular Investor/Guru program status - whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus.')
$tier1['RiskStatusID']       = @($bo, 'Legacy single-value risk status. Distinct from the multi-row BackOffice.CustomerRisk (which allows multiple simultaneous risk flags).')
$tier1['RiskClassificationID'] = @($bo, 'Operational risk tier assigned by risk management. FK to Dictionary.RiskClassification. Tracked in UPDATE trigger audit.')
$tier1['EmployeeAccount']    = @($bo, '1 if this is an eToro employee personal trading account (renamed from isEmployeeAccount). Flags employee accounts for special monitoring and compliance checks.')
$tier1['AccountTypeID']      = @($bo, 'Customer account classification. Default=1 (real retail account). Distribution: 1=18.614M, 0=44K, 2=37K, 6=17K, others <6K.')
$tier1['VerificationLevelID'] = @($bo, 'KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0.')
$tier1['RegulationID']       = @($bo, 'Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update.')
$tier1['DesignatedRegulationID'] = @($bo, 'Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation.')
$tier1['RegulationChangeDate'] = @($bo, 'Timestamp when RegulationID was last changed. Updated automatically by the CustomerHistoryUpdate trigger. NULL if never changed since creation.')
$tier1['DocumentStatusID']   = @($bo, 'Current state of the customer KYC document submission and review queue. NULL if no documents submitted.')
$tier1['SuitabilityTestStatusID'] = @($bo, 'MiFID II appropriateness/suitability test result. NULL if test not completed.')
$tier1['MifidCategorizationID'] = @($bo, 'MiFID II investor classification. FK to Dictionary.MifidCategorization. Values: 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%). Default=1.')
$tier1['IsCopyBlocked']      = @($bo, '1 if the customer is blocked from copy trading. 0 in all current rows - feature exists but currently unused/not enforced.')
$tier1['IsEDD']              = @($bo, 'Enhanced Due Diligence required flag. 1 = customer requires deeper AML/KYC investigation (PEP, high-risk country, large transactions). 23,944 customers (0.13%) flagged. Default=0.')
$tier1['EvMatchStatus']      = @($bo, 'Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed.')
$tier1['WorldCheckID']       = @($bo, 'Refinitiv/LSEG World-Check sanctions and PEP screening result. FK to Dictionary.WorldCheck. Default=0.')
$tier1['CashoutFeeGroupID']  = @($bo, 'Determines which withdrawal fee schedule applies to this customer. FK to Dictionary.CashoutFeeGroup. NULL = default fee group.')
$tier1['SalesForceAccountID'] = @($bo, 'Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced.')
$tier1['HasWallet']          = @($bo, '1 if the customer has an active eToro Money wallet linked to their trading account. Default=0.')
$tier1['PhoneVerifiedID']    = @($bo, 'Result code of phone number verification process. NULL if not yet attempted.')

# Columns that remain Tier 2 (DWH-computed or from sources without upstream wiki)
$tier2Source = 'SP_Dim_Customer'

# ── Process file ──
$path = 'knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md'
$content = Get-Content $path -Encoding UTF8
$output = [System.Collections.ArrayList]@()
$t1Count = 0
$t2Count = 0
$t1Names = [System.Collections.ArrayList]@()
$t2Names = [System.Collections.ArrayList]@()

foreach ($line in $content) {
    $trimmed = $line.Trim()
    
    # Match element rows: | number | ColumnName | ...rest... |
    if ($trimmed -match '^\|\s*(\d+)\s*\|\s*([A-Za-z0-9_]+)\s*\|') {
        $rowNum = $Matches[1]
        $colName = $Matches[2]
        
        if ($tier1.ContainsKey($colName)) {
            $src = $tier1[$colName][0]
            $desc = $tier1[$colName][1]
            $suffix = "(Tier 1 $emdash $src)"
            
            # Split line by | to rebuild
            $parts = $trimmed -split '\|'
            # parts[0] = '' (before first |)
            # parts[1] = ' 1 ' (row number)
            # parts[2] = ' RealCID ' (column name)
            # parts[3..N-2] = middle cells (Type, Nullable, Masked, etc.)
            # parts[N-1] = ' Description... '
            # parts[N] = '' (after last |)
            
            # Replace the second-to-last part (description)
            $lastIdx = $parts.Count - 2  # last non-empty cell index
            $parts[$lastIdx] = " $desc $suffix "
            
            $newLine = $parts -join '|'
            [void]$output.Add($newLine)
            $t1Count++
            [void]$t1Names.Add("  T1 #$rowNum $colName <- $src")
            continue
        }
        else {
            # Keep as Tier 2 - verify suffix exists
            if ($trimmed -match '\(Tier 2') {
                $t2Count++
                [void]$t2Names.Add("  T2 #$rowNum $colName")
            }
        }
    }
    
    [void]$output.Add($line)
}

# Update the footer tier counts
for ($i = $output.Count - 1; $i -ge 0; $i--) {
    if ($output[$i] -match '^\*Tiers:') {
        $output[$i] = "*Tiers: $t1Count T1, $t2Count T2, 0 T3, 0 T4, 0 T5 | Phases: 1,5,7,8,9,9B,10,10.5,13,11*"
        break
    }
}

$output | Set-Content $path -Encoding UTF8
Write-Host "Dim_Customer updated: $t1Count Tier 1, $t2Count Tier 2"
Write-Host ""
Write-Host "=== Tier 1 (upstream wiki inherited) ==="
$t1Names | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "=== Tier 2 (no upstream wiki / DWH-computed) ==="
$t2Names | ForEach-Object { Write-Host $_ }
