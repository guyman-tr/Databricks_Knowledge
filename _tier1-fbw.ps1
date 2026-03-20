$emdash = [char]0x2014
$tier1 = @{}

$bw = 'Billing.Withdraw'
$tier1['CID']                      = @($bw, 'Customer ID. FK to Customer.CustomerStatic.')
$tier1['WithdrawID']               = @($bw, 'Withdrawal request identifier. Primary key, IDENTITY starting at 1.')
$tier1['CurrencyID']               = @($bw, 'Currency of the withdrawal amount. FK to Dictionary.Currency.')
$tier1['FundingTypeID_Withdraw']   = @($bw, 'Payment method type of the withdrawal request (Visa/Wire/Neteller/eToroMoney/etc.). 26 distinct values in production.')
$tier1['RequestDate']              = @($bw, 'Timestamp when the customer submitted the withdrawal request.')
$tier1['Amount_Withdraw']          = @($bw, 'Gross withdrawal amount in CurrencyID denomination (renamed from Amount).')
$tier1['Commission']               = @($bw, 'Broker commission on this withdrawal. DEFAULT=0. Typically 0 for retail customers.')
$tier1['Approved']                 = @($bw, 'Whether the withdrawal has received required approval. 1=Approved, 0=Pending approval. DEFAULT=0.')
$tier1['ModificationDate']         = @($bw, 'UTC timestamp of the most recent status change or update.')
$tier1['Fee']                      = @($bw, 'Platform fee charged for this withdrawal. Subtracted from the gross Amount.')
$tier1['FundingID']                = @($bw, 'FK to Billing.Funding - the payment instrument to which the withdrawal should be paid. NULL if no specific instrument selected.')
$tier1['CashoutReasonID']          = @($bw, 'Internal reason code for the withdrawal decision (e.g., why cancelled or flagged).')
$tier1['ClientWithdrawReasonID']   = @($bw, 'Customer-selected reason for the withdrawal (e.g., taking profits, funds needed, dissatisfied).')
$tier1['AccountCurrencyID']        = @($bw, 'Customer eToro account currency, if different from CurrencyID. Used when account and withdrawal currencies differ.')
$tier1['CashoutStatusID_Withdraw'] = @($bw, 'Withdrawal request-level status. FK to Dictionary.CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled.')
$tier1['Comment']                  = @($bw, 'Operations comment on the withdrawal request.')
$tier1['FlowID']                   = @($bw, 'Processing flow identifier. NULL=legacy, 0=standard, 2=eToroMoney (triggers MoveMoneyReasonID=5), 3=alternate (triggers MoveMoneyReasonID=6).')
$tier1['WithdrawTypeID']           = @($bw, 'Withdrawal type classification. NULL=legacy (55%), 0=standard (41%), 1=special/alternate (3.7%), 2=second alternate (0.5%).')

$wtf = 'Billing.WithdrawToFunding'
$tier1['CashoutStatusID_Funding']  = @($wtf, 'Execution-level status of the payment leg. FK to Dictionary.CashoutStatus. Values: 3=Processed (31.5%), 4=Canceled (67.7%), 14=Pending Review, 17=Partially Reversed.')
$tier1['ProcessCurrencyID']        = @($wtf, 'Currency used for the actual payment processing. May differ from withdrawal CurrencyID when cross-currency routing is applied.')
$tier1['ExchangeRate']             = @($wtf, 'Exchange rate applied to convert from withdrawal currency to ProcessCurrencyID. NULL for same-currency payouts.')
$tier1['Amount_WithdrawToFunding'] = @($wtf, 'Payout amount in ProcessCurrencyID currency (renamed from Amount). For refunds, the amount being refunded to the instrument.')
$tier1['ModificationDate_WithdrawToFunding'] = @($wtf, 'UTC timestamp of the most recent status change on the payment execution leg (renamed from ModificationDate).')
$tier1['DepositID']                = @($wtf, 'For refund legs (CashoutTypeID=2): references the source Billing.Deposit being refunded. Value 0 is null-equivalent for cashout legs.')
$tier1['CashoutTypeID']            = @($wtf, 'Categorizes the type of payment execution: 1=Cashout (standard withdrawal, 69%), 2=Refund (refund of a prior deposit, 31%).')
$tier1['VerificationCode']         = @($wtf, 'Verification code supplied or received during withdrawal processing.')
$tier1['ProcessorValueDate']       = @($wtf, 'Value date from the payment processor - when funds are considered available. Set for wire/ACH payouts; NULL for instant methods.')
$tier1['DepotID']                  = @($wtf, 'Which Billing.Depot (acquirer/gateway configuration) processed this payment leg.')
$tier1['ExchangeFee']              = @($wtf, 'Exchange fee in provider-specific integer units.')
$tier1['WithdrawPaymentID']        = @($wtf, 'Surrogate primary key of the WithdrawToFunding execution leg (renamed from ID).')
$tier1['BaseExchangeRate']         = @($wtf, 'Reference exchange rate before fee markup. Spread = ExchangeRate minus BaseExchangeRate.')
$tier1['ProtocolMIDSettingsID']    = @($wtf, 'MID configuration profile used for this payment leg. FK to Billing.ProtocolMIDSettings. Default=0.')
$tier1['CashoutModeID']            = @($wtf, 'Mode of withdrawal execution: 1=Standard (75.2%), NULL=legacy (17%), 2=Alternate e.g. eToroMoney/ACH (4%), 0=Unknown/fallback (3.8%).')

$bf = 'Billing.Funding'
$tier1['FundingTypeID_Funding']    = @($bf, 'Payment method type of the funding instrument receiving the payout. 34 distinct types (renamed from FundingTypeID).')

$path = 'knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md'
$content = Get-Content $path -Encoding UTF8
$output = [System.Collections.ArrayList]@()
$t1Count = 0
$t2Count = 0
$t1Names = [System.Collections.ArrayList]@()
$t2Names = [System.Collections.ArrayList]@()

foreach ($line in $content) {
    $trimmed = $line.Trim()
    if ($trimmed -match '^\|\s*(\d+)\s*\|\s*([A-Za-z0-9_]+)\s*\|') {
        $rowNum = $Matches[1]
        $colName = $Matches[2]
        if ($tier1.ContainsKey($colName)) {
            $src = $tier1[$colName][0]
            $desc = $tier1[$colName][1]
            $suffix = "(Tier 1 $emdash $src)"
            $parts = $trimmed -split '\|'
            $lastIdx = $parts.Count - 2
            $parts[$lastIdx] = " $desc $suffix "
            [void]$output.Add(($parts -join '|'))
            $t1Count++
            [void]$t1Names.Add("  T1 #$rowNum $colName <- $src")
            continue
        } else {
            if ($trimmed -match '\(Tier 2') { $t2Count++ }
            [void]$t2Names.Add("  T2 #$rowNum $colName")
        }
    }
    [void]$output.Add($line)
}

for ($i = $output.Count - 1; $i -ge 0; $i--) {
    if ($output[$i] -match '^\*Tiers:') {
        $output[$i] = "*Tiers: $t1Count T1, $t2Count T2, 0 T3, 0 T4, 0 T5 | Phases: 1,5,7,8,9,9B,10,10.5,13,11*"
        break
    }
}

$output | Set-Content $path -Encoding UTF8
Write-Host "Fact_BillingWithdraw updated: $t1Count Tier 1, $t2Count Tier 2"
Write-Host ""
Write-Host "=== Tier 1 ==="
$t1Names | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "=== Tier 2 (XML-extracted / DWH-computed) ==="
$t2Names | ForEach-Object { Write-Host $_ }
