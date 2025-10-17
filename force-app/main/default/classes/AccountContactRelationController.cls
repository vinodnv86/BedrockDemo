public with sharing class AccountContactRelationController {

    @AuraEnabled(cacheable=true)
    public static List<ContactRelationWrapper> getRelatedContacts(Id accountId, Integer limitSize, String sortBy) {
        if (accountId == null) return new List<ContactRelationWrapper>();
        if (limitSize == null || limitSize <= 0) limitSize = 10;

        List<AccountContactRelation> acrList = new List<AccountContactRelation>();

        // Step 1: Query AccountContactRelation sorted by Name if sortBy != 'Count'
        if (sortBy == 'Count') {
            acrList = [
                SELECT ContactId, Contact.Name, Contact.Email, Contact.Phone
                FROM AccountContactRelation
                WHERE AccountId = :accountId
                AND IsDeleted = false
                AND ContactId != null
            ];
        } else {
            acrList = [
                SELECT ContactId, Contact.Name, Contact.Email, Contact.Phone
                FROM AccountContactRelation
                WHERE AccountId = :accountId
                AND IsDeleted = false
                AND ContactId != null
                ORDER BY Contact.Name ASC
            ];
        }

        if (acrList.isEmpty()) return new List<ContactRelationWrapper>();

        // Step 2: Count how many accounts each Contact is related to
        Map<Id, Integer> contactCountMap = new Map<Id, Integer>();
        List<AggregateResult> countResults = [
            SELECT ContactId, COUNT(Id) cnt
            FROM AccountContactRelation
            WHERE ContactId IN :new Map<Id, AccountContactRelation>(acrList).keySet()
            GROUP BY ContactId
        ];

        for (AggregateResult ar : countResults) {
            contactCountMap.put((Id)ar.get('ContactId'), Integer.valueOf(ar.get('cnt')));
        }

        // Step 3: Build wrapper list
        List<ContactRelationWrapper> wrapperList = new List<ContactRelationWrapper>();
        for (AccountContactRelation acr : acrList) {
            Integer relCount = contactCountMap.containsKey(acr.ContactId) ? contactCountMap.get(acr.ContactId) : 1;
            wrapperList.add(new ContactRelationWrapper(
                acr.ContactId,
                acr.Contact.Name,
                acr.Contact.Email,
                acr.Contact.Phone,
                relCount
            ));
        }

        // Step 4: Sort by Count if requested
        if (sortBy == 'Count') {
            // Map of count -> list of wrapper objects
            Map<Integer, List<ContactRelationWrapper>> countMap = new Map<Integer, List<ContactRelationWrapper>>();
            for (ContactRelationWrapper w : wrapperList) {
                Integer c = w.relationCount != null ? w.relationCount : 0;
                if (!countMap.containsKey(c)) countMap.put(c, new List<ContactRelationWrapper>());
                countMap.get(c).add(w);
            }

            // Sort counts ascending and reverse manually
            List<Integer> counts = new List<Integer>(countMap.keySet());
            counts.sort();
            List<Integer> reversedCounts = new List<Integer>();
            for (Integer i = counts.size() - 1; i >= 0; i--) {
                reversedCounts.add(counts[i]);
            }

            // Build sorted wrapper list
            List<ContactRelationWrapper> sortedList = new List<ContactRelationWrapper>();
            for (Integer c : reversedCounts) {
                sortedList.addAll(countMap.get(c));
            }
            wrapperList = sortedList;
        }

        // Step 5: Limit results manually
        List<ContactRelationWrapper> limitedList = new List<ContactRelationWrapper>();
        Integer max = Math.min(limitSize, wrapperList.size());
        for (Integer i = 0; i < max; i++) {
            limitedList.add(wrapperList[i]);
        }
        wrapperList = limitedList;

        return wrapperList;
    }

    // ===========================
    // Wrapper Class
    // ===========================
    public class ContactRelationWrapper {
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public String contactEmail { get; set; }
        @AuraEnabled public String contactPhone { get; set; }
        @AuraEnabled public Integer relationCount { get; set; }

        public ContactRelationWrapper(Id cId, String name, String email, String phone, Integer count) {
            contactId = cId;
            contactName = name;
            contactEmail = email;
            contactPhone = phone;
            relationCount = count;
        }
    }
}
