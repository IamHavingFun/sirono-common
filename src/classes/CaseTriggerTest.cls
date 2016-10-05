/*
* @author Sirono
* @version 1.0.1
* @Date: 05-05-2016
* @description 
* Test class for the Case trigger
*/

@isTest
private class CaseTriggerTest {
    static testMethod void myUnitTest() {
        TestUtility objTestUtil = new TestUtility();

        Map<String, Id> rtMap = new Map<String, Id>();
        for (RecordType rt : [Select Id, Name From RecordType Where sObjectType = 'Case']) {
            rtMap.put(rt.Name, rt.Id);
        }

        Case c = TestUtility.generateCase(rtMap.get('Internal Case'), 'Address Change', null);
        c.Reason = 'Charge Group';
        c.Charge_Group_IDs__c = '1234,1235';
        insert c;

        CaseComment cc = TestUtility.generateCaseComment(c.Id);
        insert cc;

        List<CaseComment> lstCaseComment = [Select id from CaseComment];
        System.assertEquals(1, lstCaseComment.Size());
    }

    static testMethod void myUnitTest1() {
        TestUtility objTestUtil = new TestUtility();
        Test.startTest();
        TestUtility.status = 'CREATED';
        TestUtility.statusCode = 201;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorTest());
        String str = '1212121';
        PayStaffWSUtill.addNoteFuture(str.split(','), 'test');
        Test.stopTest();
    }

    static testMethod void myUnitTest2() {
        TestUtility objTestUtil = new TestUtility();
        Test.startTest();
        TestUtility.status = 'CREATED';
        TestUtility.statusCode = 200;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorTest());
        String str = '1212121';
        PayStaffWSUtill.addNoteFuture(str.split(','), 'test');
        Test.stopTest();
    }

    static testMethod void myUnitTest3() {

        Case cc = new Case(Description = 'Test Case', Charge_Group_IDs__c = '12345,54321');
        insert cc;
        Test.startTest();
        TestUtility.status = 'CREATED';
        TestUtility.statusCode = 200;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorTest());
        for (Case ob : [Select Id, Description, Charge_Group_IDs__c From Case Where Id = :cc.Id AND CreatedBy.Name != 'Sirono Integration' AND Charge_Group_IDs__c != null]) {
            PayStaffWSUtill.addNoteFuture(ob.Charge_Group_IDs__c.split(','), ob.Description);
        }
        Test.stopTest();
    }

}