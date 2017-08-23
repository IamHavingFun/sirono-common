/*
 * Copyright (c) 2017-present Sirono LLC, All rights reserved
 */

public with sharing class EarlyOutSchedulerBatch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {
    public Campaign callList;
    public Set<Id> existingMembers;

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new EarlyOutSchedulerBatch(), 200);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        //Sirono : 08-30-2016 - #128375287 Update Salesforce Campaign Names
        Map<String, String> mapCampaignMapping = CaseUtil.campaignMapping(new Set<String> {
            Constants.CAMPAIGN_NAME_OVERDUE
        });
        String earlyOut = mapCampaignMapping.get(Constants.CAMPAIGN_NAME_OVERDUE);

        if (CampaignSecurityContext.SELECT_CONTEXT.actionAllowed()) {
            for (Campaign cl : [
                SELECT Id, Name
                FROM Campaign
                WHERE Name = :earlyOut
                AND IsActive = TRUE
            ]) {
                callList = cl;
            }
        }

        if (callList != null) {
            existingMembers = new Set<Id>();
            if (CmpnMemberSecurityContext.SELECT_CONTEXT.actionAllowed()) {
                for (CampaignMember cm : [
                    SELECT Id, ContactId
                    FROM CampaignMember
                    WHERE CampaignId = :callList.Id
                    AND ContactId != NULL
                ]) {
                    existingMembers.add(cm.ContactId);
                }
            }
            return Database.getQueryLocator(GuarantorService.getBatchContactsQuery());
        } else {
            return Database.getQueryLocator(GuarantorService.getNoContactsQuery());
        }
        return null;
    }

    //Adding Guarantors based on their overdue balance and creates to new CampaignMember list 
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Contact> guarantors = (List<Contact>) scope;
        Map<Id, Contact> guarantorMap = new Map<Id, Contact>(GuarantorService.getGuarantorsWithStatement(guarantors));

        Date dt = System.today().addDays(-50);
        if (callList != null) {
            List<CampaignMember> memberList = new List<CampaignMember>();
            if (InvoiceSecurityContext.SELECT_CONTEXT.actionAllowed()) {
                for (Invoice__c invoice : [
                    SELECT Id, Name, Guarantor__c, Date__c,
                        Guarantor__r.Overdue_Balance__c, Guarantor__r.Delinquent_Balance__c
                    FROM Invoice__c
                    WHERE Guarantor__c IN :guarantors
                    AND Date__c = :dt
                ]) {
                    Double bal = invoice.Guarantor__r.Overdue_Balance__c + invoice.Guarantor__r.Delinquent_Balance__c;
                    if (invoice.Guarantor__r.Overdue_Balance__c < 0 && bal <= -100 && bal > -5000
                        && guarantorMap.containsKey(invoice.Guarantor__c)
                        && guarantorMap.get(invoice.Guarantor__c).Statements__r != null
                        && guarantorMap.get(invoice.Guarantor__c).Statements__r.size() != 0
                        && guarantorMap.get(invoice.Guarantor__c).Statements__r.get(0).Statement_Date__c > invoice.Date__c
                        && !existingMembers.contains(invoice.Guarantor__c)) {
                        existingMembers.add(invoice.Guarantor__c);
                        memberList.add(new CampaignMember(
                            CampaignId = callList.Id,
                            ContactId = invoice.Guarantor__c,
                            Status = Constants.SENT
                        ));
                    }
                }
            }

            if (memberList.size() > 0) {
                if (CmpnMemberSecurityContext.SB_CREATE_CONTEXT.actionAllowed()) {
                    insert memberList;
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {

    }
}