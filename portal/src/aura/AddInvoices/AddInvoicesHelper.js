/*
 * Copyright (c) 2017-present Sirono LLC, All rights reserved
 */

({
    showError: function (cmp, message) {
        cmp.set('v.hasError', true);
        var supportCmp = cmp.find('notificationCmp');

    },
    toggleSections: function (cmp) {
        var cardCmp = cmp.find('editCreditCard');
        var termsCmp = cmp.find('editTerms');
        $A.util.toggleClass(termsCmp, 'slds-hide');
        $A.util.toggleClass(cardCmp, 'slds-hide');
    },
    getCalculatedMinInstallmentAmount: function (Settings, totalAmount) {
        var minimumInstallmentAmount = Settings.sPRS__Min_Installment_Amount__c || 0;
        if (Settings.sPRS__Max_Number_Plan_Installments__c && Settings.sPRS__Max_Number_Plan_Installments__c > 0) {
            minimumInstallmentAmount = parseFloat(totalAmount / Settings.sPRS__Max_Number_Plan_Installments__c);
            minimumInstallmentAmount.toFixed(2);
            if (Settings.sPRS__Min_Installment_Amount__c >= minimumInstallmentAmount) {
                minimumInstallmentAmount = 50;
            }

        }
        return parseFloat(minimumInstallmentAmount, 10);
    },
    getCalculatedIntallments: function (total, part) {
        var _total = Math.round(total * 100) / 100;
        var _part = Math.round(part * 100) / 100;
        var totalInstallment = Math.round(_total / _part);
        totalInstallment = Math.round(totalInstallment * _part * 100) / 100 < Math.round(_total * 100) / 100 ? totalInstallment + 1 : totalInstallment;
        return totalInstallment;
    }
})