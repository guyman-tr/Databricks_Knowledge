SELECT 
  c.*,
  -- Assigning the Vendor Group
  CASE 
    WHEN c.Category IN ('Trulioo Global', 'Trulioo USA', 'GBG (USD Converted)', 'Melissa', 'DataZoo', 'IDMerit', 'Prove') THEN 'EV'
    WHEN c.Category IN ('AU10TIX (USD Converted)', 'Onfido (USD Converted)', 'SumSub (USD converted)') THEN 'Docs'
    WHEN c.Category IN ('CGS', 'Teleperformance') THEN 'Outsourcing'
    WHEN c.Category IN ('Telesign', 'Sinch') THEN 'Phone/SMS'
    WHEN c.Category IN ('IDNow', 'Solaris') THEN 'IDNow/Solaris'
    ELSE 'Other' 
  END AS `Vendor Group`,
  
  -- Assigning the Specific Values
  CASE 
    /* --- 2025 DATA --- */
    WHEN c.Year = 2025 THEN
        CASE 
            WHEN c.Category = 'Trulioo Global'           THEN 169930
            WHEN c.Category = 'Trulioo USA'              THEN 6500
            WHEN c.Category = 'GBG (USD Converted)'      THEN 32087
            WHEN c.Category = 'Melissa'                  THEN 57832
            WHEN c.Category = 'DataZoo'                  THEN 6994
            WHEN c.Category = 'Prove'                    THEN 14472
            WHEN c.Category = 'Onfido (USD Converted)'   THEN 66401
            WHEN c.Category = 'AU10TIX (USD Converted)'  THEN 2669
            WHEN c.Category = 'SumSub (USD converted)'   THEN 44631
            WHEN c.Category = 'ComplyAdvantage'          THEN 2475
            WHEN c.Category = 'Thompson Reuters'         THEN 28927
            WHEN c.Category = 'CGS'                      THEN 107946
            WHEN c.Category = 'Telesign'                 THEN 110000
            WHEN c.Category = 'Pangea'                   THEN 2000
            WHEN c.Category = 'Teleperformance'          THEN 54006
            WHEN c.Category = 'IDNow'                    THEN 44820
            WHEN c.Category = 'Solaris'                  THEN 4886
            ELSE 0 
        END

    /* --- 2026 DATA --- */
    WHEN c.Year = 2026 THEN
        CASE 
            -- Categories with Monthly Variation
            WHEN c.Category = 'CGS' THEN 
                CASE 
                    WHEN c.Month BETWEEN 1 AND 3  THEN 152745
                    WHEN c.Month BETWEEN 4 AND 6  THEN 140995
                    WHEN c.Month BETWEEN 7 AND 12 THEN 110446
                    ELSE 0 
                END
            
            WHEN c.Category = 'Teleperformance' THEN 
                CASE 
                    WHEN c.Month BETWEEN 1 AND 3  THEN 79174
                    WHEN c.Month BETWEEN 4 AND 6  THEN 61580
                    WHEN c.Month BETWEEN 7 AND 11 THEN 45745
                    WHEN c.Month = 12             THEN 43986
                    ELSE 0 
                END

            -- Categories with Flat Yearly Values
            WHEN c.Category = 'AU10TIX (USD Converted)'  THEN 1708
            WHEN c.Category = 'ComplyAdvantage'          THEN 2695
            WHEN c.Category = 'DataZoo'                  THEN 1650
            WHEN c.Category = 'GBG (USD Converted)'      THEN 43700
            WHEN c.Category = 'IDNow'                    THEN 2389
            WHEN c.Category = 'Melissa'                  THEN 51930
            WHEN c.Category = 'Onfido (USD Converted)'   THEN 49556
            WHEN c.Category = 'Prove'                    THEN 22971
            WHEN c.Category = 'Solaris'                  THEN 2577
            WHEN c.Category = 'SumSub (USD converted)'   THEN 33489
            WHEN c.Category = 'Telesign'                 THEN 66737
            WHEN c.Category = 'Sinch'                    THEN 53734
            WHEN c.Category = 'Thompson Reuters'         THEN 28927
            WHEN c.Category = 'Trulioo Global'           THEN 139463
            WHEN c.Category = 'Trulioo USA'              THEN 3182
            ELSE 0 
        END
        
    ELSE 0 
END AS `Category Value`

FROM main.bi_output_stg.bi_output_operations_cost_import_file c
WHERE c.Category IN (
  'AU10TIX (USD Converted)', 'CGS', 'ComplyAdvantage', 'DataZoo', 
  'GBG (USD Converted)', 'IDNow', 'Melissa', 'Onfido (USD Converted)', 
  'Pangea', 'Prove', 'Sinch', 'Solaris', 'SumSub (USD converted)', 
  'Teleperformance', 'Telesign', 'Thompson Reuters', 'Trulioo Global', 'Trulioo USA'
)