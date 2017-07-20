/**
 * Tests to check Invoice's Invoice_Status__c and Charge Group's Sub_Status_Index__c values which are generated by Formula field.
 **/

@isTest
public with sharing class InvoiceStatusTest {

    public static final String GUARANTOR_CONTACT = 'guarantorContact';
    private static Decimal CG_SIRONO_ID = 56789;

    /**
     * This method is used to setup preliminary data to let's all testmethods to execute as expected.
     **/
    @testSetup
    public static void setupData() {
        Test.startTest();
        // Create Guarantor Contact record.
        Contact guarantorContact = TestUtility.generateGuarantorContactByName(GUARANTOR_CONTACT);
        INSERT guarantorContact;

        // Create Patient Contact record.
        Contact patientContact = TestUtility.generatePatientContact();
        INSERT patientContact;

        // Create Invoice record.
        Invoice__c invoice = TestUtility.generateInvoice(guarantorContact.Id, patientContact.Id);
        INSERT invoice;
        Test.stopTest();

        // Check system assert.
        System.assertNotEquals(guarantorContact.Id, null, 'Contact record does not exists/created.');
    }

    private static Contact getTestContact() {
        return [
            SELECT Id
            FROM Contact
            WHERE LastName = :GUARANTOR_CONTACT
        ];
    }

    private static Charge_Group__c getTestChargeGroup() {
        return [
            SELECT Id, Account_Sub_Status__c, Sub_Status_Index__c
            FROM Charge_Group__c
            WHERE Sirono_ID__c = :CG_SIRONO_ID
        ];
    }

    private static Invoice__c getTestInvoice() {
        return [
            SELECT Id, Guarantor__c, Invoice_Status__c
            FROM Invoice__c
        ];
    }

    /**
     * This method checks logic when CG Account_Sub_Status__c field is inserted as "Credit".
     **/
    @isTest
    public static void cgInsertTest() {
        Contact guarantor = getTestContact();
        Invoice__c invoice = getTestInvoice();

        Test.startTest();
        // Create Charge Group record.
        Charge_Group__c chargeGroup = TestUtility.generateChargeGroup(guarantor.Id, null, CG_SIRONO_ID);
        chargeGroup.Sirono_ID__c = CG_SIRONO_ID;
        chargeGroup.Invoice__c = invoice.Id;
        chargeGroup.Account_Sub_Status__c = Constants.ACCT_SUBSTATUS_CREDIT;
        INSERT chargeGroup;

        Transaction__c objTransaction = TestUtility.generateTransaction(chargeGroup, 5000, Constants.AUTOMATIC);
        INSERT objTransaction;
        Test.stopTest();

        // Check system assert
        chargeGroup = getTestChargeGroup();
        invoice = getTestInvoice();
        System.assertEquals(5, chargeGroup.Sub_Status_Index__c, 'Expected CG Sub_Status_Index__c equals to 5 but we got ' + chargeGroup.Sub_Status_Index__c);
        System.assertEquals(Constants.ACCT_SUBSTATUS_CREDIT, invoice.Invoice_Status__c,
            'Expected Invoice\'s Invoice_Status__c equals to ' + Constants.ACCT_SUBSTATUS_CREDIT + ' but we got ' + invoice.Invoice_Status__c);
    }

    /**
     * This method checks logic when Account_Sub_Status__c field is updated to "Credit".
     **/
    @isTest
    public static void cgUpdateTest() {
        Contact guarantor = getTestContact();
        Invoice__c invoice = getTestInvoice();

        // Create Charge Group record.
        Charge_Group__c chargeGroup = TestUtility.generateChargeGroup(guarantor.Id, null, CG_SIRONO_ID);
        chargeGroup.Sirono_ID__c = CG_SIRONO_ID;
        chargeGroup.Invoice__c = invoice.Id;
        chargeGroup.Account_Sub_Status__c = Constants.ACCT_SUBSTATUS_OVERDUE;
        INSERT chargeGroup;

        Transaction__c objTransaction = TestUtility.generateTransaction(chargeGroup, 5000, Constants.AUTOMATIC);
        INSERT objTransaction;

        // Check system assert
        chargeGroup = getTestChargeGroup();
        invoice = getTestInvoice();
        System.assertEquals(8, chargeGroup.Sub_Status_Index__c,
            'Based on CG Account_Sub_Status__c equals to ' + Constants.ACCT_SUBSTATUS_OVERDUE + ' Sub_Status_Index__c should be 8 but we got ' + chargeGroup.Sub_Status_Index__c);
        System.assertEquals(Constants.ACCT_SUBSTATUS_OVERDUE, invoice.Invoice_Status__c,
            'Expected Invoice\'s Invoice_Status__c equals to ' + Constants.ACCT_SUBSTATUS_OVERDUE + ' but we got ' + invoice.Invoice_Status__c);

        Test.startTest();
        chargeGroup.Account_Sub_Status__c = Constants.ACCT_SUBSTATUS_CREDIT;
        UPDATE chargeGroup;
        Test.stopTest();

        // Check system assert
        chargeGroup = getTestChargeGroup();
        invoice = getTestInvoice();
        System.assertEquals(5, chargeGroup.Sub_Status_Index__c, 'Expected CG Sub_Status_Index__c equals to 5 but we got ' + chargeGroup.Sub_Status_Index__c);
        System.assertEquals(Constants.ACCT_SUBSTATUS_CREDIT, invoice.Invoice_Status__c,
            'Expected Invoice\'s Invoice_Status__c equals to ' + Constants.ACCT_SUBSTATUS_CREDIT + ' but we got ' + invoice.Invoice_Status__c);
    }

    /**
     * This method checks logic when Charge Group record is deleted.
     **/
    @isTest
    public static void cgDeleteTest() {
        Contact guarantor = getTestContact();
        Invoice__c invoice = getTestInvoice();

        // Inserting Charge Group object
        Charge_Group__c chargeGroup = TestUtility.generateChargeGroup(guarantor.Id, null, CG_SIRONO_ID);
        chargeGroup.Sirono_ID__c = CG_SIRONO_ID;
        chargeGroup.Invoice__c = invoice.Id;
        chargeGroup.Account_Sub_Status__c = Constants.ACCT_SUBSTATUS_CREDIT;
        INSERT chargeGroup;

        // Inserting Transaction object
        Transaction__c objTransaction = TestUtility.generateTransaction(chargeGroup, 5000, Constants.AUTOMATIC);
        INSERT objTransaction;

        // Check System assert.
        chargeGroup = getTestChargeGroup();
        invoice = getTestInvoice();
        System.assertEquals(5, chargeGroup.Sub_Status_Index__c, 'Expected CG Sub_Status_Index__c equals to 5 but we got ' + chargeGroup.Sub_Status_Index__c);
        System.assertEquals(Constants.ACCT_SUBSTATUS_CREDIT, invoice.Invoice_Status__c,
            'Expected Invoice\'s Invoice_Status__c equals to ' + Constants.ACCT_SUBSTATUS_CREDIT + ' but we got ' + invoice.Invoice_Status__c);

        Test.startTest();
        DELETE chargeGroup;
        Test.stopTest();

        // Check System assert.
        invoice = getTestInvoice();
        System.assertEquals('Invoice Voided', invoice.Invoice_Status__c,
            'Should be Invoice\'s Invoice_Status__c equals to "Invoice Voided" but we got ' + invoice.Invoice_Status__c);
    }

    /**
     * This method negative testing when there is default value in Sub Status.
     **/
    @isTest
    public static void statusNegativeTest() {
        Contact guarantor = getTestContact();
        Invoice__c invoice = getTestInvoice();

        // Inserting Charge Group object
        Test.startTest();
        Charge_Group__c chargeGroup = TestUtility.generateChargeGroup(guarantor.Id, null, CG_SIRONO_ID);
        chargeGroup.Sirono_ID__c = CG_SIRONO_ID;
        chargeGroup.Invoice__c = invoice.Id;
        INSERT chargeGroup;

        // Inserting Transaction object
        Transaction__c objTransaction = TestUtility.generateTransaction(chargeGroup, 5000, Constants.AUTOMATIC);
        INSERT objTransaction;
        Test.stopTest();

        // Check System assert.
        chargeGroup = getTestChargeGroup();
        invoice = getTestInvoice();
        System.assertEquals(0, chargeGroup.Sub_Status_Index__c, 'Should be default CG Sub_Status_Index__c equals to 0 but we got ' + chargeGroup.Sub_Status_Index__c);
        System.assertEquals('Invoice Voided', invoice.Invoice_Status__c,
            'Should be Invoice\'s Invoice_Status__c equals to "Invoice Voided" but we got ' + invoice.Invoice_Status__c);
    }
}