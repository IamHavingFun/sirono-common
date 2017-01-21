public with sharing class InvoiceUtil {

    /*
     * Method takes a set of invoice Ids and updates the Invoice Status Index with the MAX Status Index value from
     * related charge groups.
     *
     * @param Set<Id> invoiceIdsFromChargeGroup - invoice Ids from charge groups that have been inserted, updated, deleted
     */

    public static void updateInvoiceStatusIndex(Set<Id> invoiceIdsFromChargeGroup) {
        // Get the max index value from related charge groups and insert into Invoice Status Index field
        if(invoiceIdsFromChargeGroup.size() != 0) {
            AggregateResult[] queryResults = [
                    SELECT Invoice__c, MAX(Sub_Status_Index__c) maxStatusValue
                    FROM Charge_Group__c
                    WHERE Invoice__c IN :invoiceIdsFromChargeGroup
                    AND Active__c = TRUE
                    GROUP BY Invoice__c
            ];

            if(queryResults.size() > 0){
                List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();

                for(AggregateResult qr : queryResults) {
                    Invoice__c tempInvoice = new Invoice__c();

                    system.debug('Updated invoice values >>>>> [Invoice Id]: ' + qr.get('Invoice__c')
                            + '[Max Status Value]: ' + qr.get('maxStatusValue'));
                    tempInvoice.Id = (Id) qr.get('Invoice__c');
                    tempInvoice.Invoice_Status_Index__c = Integer.valueOf(qr.get('maxStatusValue'));

                    invoicesToUpdate.add(tempInvoice);
                }

                update invoicesToUpdate;
            }
        }
    }
}