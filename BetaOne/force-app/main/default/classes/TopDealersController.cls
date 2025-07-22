public with sharing class TopDealersController {
    @AuraEnabled(cacheable=true)
    public static List<AccountWrapper> getTopDealers(String region) {
        if (String.isBlank(region)) {
            return new List<AccountWrapper>();
        }

        Date startDate = Date.today().toStartOfMonth(); // Start of the current month
        
        // Convert region back to province codes
        Set<String> provinces = getProvincesForRegion(region);
        
        List<Master_LOS__c> records = [
            SELECT Applications_Dealer_Name__c, Applications_Last_Amount_To_Finance_Sum__c
            FROM Master_LOS__c
            WHERE Applications_Dealer_Province__c IN :provinces
            AND Applications_Booking_Date__c >= :startDate
            AND Applications_Last_Amount_To_Finance_Sum__c != null
            AND Applications_Risk_Tier_Code__c IN ('P1', 'P2', 'P3', 'P4', 'P+')
        ];

        Map<String, Decimal> dealerTotals = new Map<String, Decimal>();

        for (Master_LOS__c record : records) {
            String dealerName = record.Applications_Dealer_Name__c;
            
            if (dealerName != null) {
                Decimal currentTotal = dealerTotals.get(dealerName);
                if (currentTotal == null) {
                    currentTotal = 0;
                }
                currentTotal += record.Applications_Last_Amount_To_Finance_Sum__c;
                dealerTotals.put(dealerName, currentTotal);
            }
        }

        List<AccountWrapper> wrappers = new List<AccountWrapper>();
        for (String dealerName : dealerTotals.keySet()) {
            wrappers.add(new AccountWrapper(dealerName, dealerTotals.get(dealerName)));
        }

        wrappers.sort();

        List<AccountWrapper> topDealers = new List<AccountWrapper>();
        Integer maxDealers = Math.min(5, wrappers.size()); // Changed to top 5 dealers
        for (Integer i = 0; i < maxDealers; i++) {
            topDealers.add(wrappers[i]);
        }

        return topDealers;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getRegions() {
        return new List<String>{'Ontario', 'Alberta', 'Quebec', 'Atlantic', 'British Columbia', 'Saskatchewan', 'Manitoba'};
    }
    
    private static Set<String> getProvincesForRegion(String region) {
        Set<String> provinces = new Set<String>();
        
        if (region == 'Ontario') {
            provinces.add('ON');
        } else if (region == 'Alberta') {
            provinces.add('AB');
        } else if (region == 'Quebec') {
            provinces.add('QC');
        } else if (region == 'Atlantic') {
            provinces.addAll(new Set<String>{'NB', 'NS', 'PE', 'NL'});
        } else if (region == 'British Columbia') {
            provinces.add('BC');
        } else if (region == 'Saskatchewan') {
            provinces.add('SK');
        } else if (region == 'Manitoba') {
            provinces.add('MB');
        }
        
        return provinces;
    }
    
    private static String mapProvinceToRegion(String province) {
        if (province == 'ON') return 'Ontario';
        if (province == 'AB') return 'Alberta';
        if (province == 'QC') return 'Quebec';
        if (province == 'NB' || province == 'NS' || province == 'PE' || province == 'NL') return 'Atlantic';
        if (province == 'BC') return 'British Columbia';
        if (province == 'SK') return 'Saskatchewan';
        if (province == 'MB') return 'Manitoba';
        return null; // Return null for unknown provinces to filter them out
    }

    @AuraEnabled(cacheable=true)
    public static AccountLinkWrapper findAccountByDealerName(String dealerName) {
        if (String.isBlank(dealerName)) {
            return null;
        }
        
        // Get all accounts first for reverse matching
        List<Account> allAccounts = [
            SELECT Id, Name FROM Account 
            WHERE Name != null 
            ORDER BY Name
        ];
        
        // Strategy 1: Exact SOSL search
        List<List<SObject>> searchResults = [
            FIND :dealerName IN NAME FIELDS RETURNING Account(Id, Name LIMIT 1)
        ];
        if (!searchResults.isEmpty() && !searchResults[0].isEmpty()) {
            Account acc = (Account)searchResults[0][0];
            return new AccountLinkWrapper(acc.Id, acc.Name);
        }
        
        // Strategy 2: Exact SOQL match
        List<Account> exactMatch = [
            SELECT Id, Name FROM Account WHERE Name = :dealerName LIMIT 1
        ];
        if (!exactMatch.isEmpty()) {
            Account acc = exactMatch[0];
            return new AccountLinkWrapper(acc.Id, acc.Name);
        }
        
        // Strategy 3: Reverse search - check if any Account name is contained in dealer name
        for (Account acc : allAccounts) {
            if (dealerName.toLowerCase().contains(acc.Name.toLowerCase())) {
                return new AccountLinkWrapper(acc.Id, acc.Name);
            }
        }
        
        // Strategy 4: Progressive word removal from the beginning
        String[] words = dealerName.split('\\s+');
        for (Integer i = 0; i < words.size(); i++) {
            // Build partial name by taking words from index i to end
            List<String> partialWords = new List<String>();
            for (Integer j = i; j < words.size(); j++) {
                partialWords.add(words[j]);
            }
            String partialName = String.join(partialWords, ' ');
            if (String.isNotBlank(partialName)) {
                // Try exact match with partial name
                List<Account> partialExact = [
                    SELECT Id, Name FROM Account WHERE Name = :partialName LIMIT 1
                ];
                if (!partialExact.isEmpty()) {
                    Account acc = partialExact[0];
                    return new AccountLinkWrapper(acc.Id, acc.Name);
                }
                
                // Try reverse search with partial name
                for (Account acc : allAccounts) {
                    if (partialName.toLowerCase().contains(acc.Name.toLowerCase())) {
                        return new AccountLinkWrapper(acc.Id, acc.Name);
                    }
                }
            }
        }
        
        // Strategy 5: Traditional "starts with" and "contains" patterns
        String startsWithPattern = dealerName + '%';
        List<Account> startsWith = [
            SELECT Id, Name FROM Account WHERE Name LIKE :startsWithPattern LIMIT 1
        ];
        if (!startsWith.isEmpty()) {
            Account acc = startsWith[0];
            return new AccountLinkWrapper(acc.Id, acc.Name);
        }
        
        String containsPattern = '%' + dealerName + '%';
        List<Account> contains = [
            SELECT Id, Name FROM Account WHERE Name LIKE :containsPattern LIMIT 1
        ];
        if (!contains.isEmpty()) {
            Account acc = contains[0];
            return new AccountLinkWrapper(acc.Id, acc.Name);
        }
        
        // Strategy 6: Hyphen-based search (existing logic)
        if (dealerName.contains(' - ')) {
            String[] parts = dealerName.split(' - ');
            if (parts.size() > 1) {
                String nameAfterHyphen = parts[1].trim();
                if (String.isNotBlank(nameAfterHyphen)) {
                    // Try reverse search with after-hyphen name
                    for (Account acc : allAccounts) {
                        if (nameAfterHyphen.toLowerCase().contains(acc.Name.toLowerCase())) {
                            return new AccountLinkWrapper(acc.Id, acc.Name);
                        }
                    }
                    
                    // Try traditional searches with after-hyphen name
                    List<List<SObject>> afterSearchResults = [
                        FIND :nameAfterHyphen IN NAME FIELDS RETURNING Account(Id, Name LIMIT 1)
                    ];
                    if (!afterSearchResults.isEmpty() && !afterSearchResults[0].isEmpty()) {
                        Account acc = (Account)afterSearchResults[0][0];
                        return new AccountLinkWrapper(acc.Id, acc.Name);
                    }
                    
                    String afterStartsWithPattern = nameAfterHyphen + '%';
                    List<Account> afterStartsWith = [
                        SELECT Id, Name FROM Account WHERE Name LIKE :afterStartsWithPattern LIMIT 1
                    ];
                    if (!afterStartsWith.isEmpty()) {
                        Account acc = afterStartsWith[0];
                        return new AccountLinkWrapper(acc.Id, acc.Name);
                    }
                    
                    String afterContainsPattern = '%' + nameAfterHyphen + '%';
                    List<Account> afterContains = [
                        SELECT Id, Name FROM Account WHERE Name LIKE :afterContainsPattern LIMIT 1
                    ];
                    if (!afterContains.isEmpty()) {
                        Account acc = afterContains[0];
                        return new AccountLinkWrapper(acc.Id, acc.Name);
                    }
                }
            }
        }
        
        // If not found, return wrapper with searched name and null Id
        return new AccountLinkWrapper(null, dealerName + ' (account not found)');
    }

    public class AccountWrapper implements Comparable {
        @AuraEnabled
        public String accountName { get; set; }
        @AuraEnabled
        public Decimal totalAmount { get; set; }

        public AccountWrapper(String accountName, Decimal totalAmount) {
            this.accountName = accountName;
            this.totalAmount = totalAmount;
        }

        public Integer compareTo(Object compareTo) {
            AccountWrapper compareToWrapper = (AccountWrapper)compareTo;
            if (totalAmount < compareToWrapper.totalAmount) {
                return 1;
            } else if (totalAmount > compareToWrapper.totalAmount) {
                return -1;
            }
            return 0;
        }
    }

    public class AccountLinkWrapper {
        @AuraEnabled public String accountId { get; set; }
        @AuraEnabled public String accountName { get; set; }
        public AccountLinkWrapper(String accountId, String accountName) {
            this.accountId = accountId;
            this.accountName = accountName;
        }
    }
}
