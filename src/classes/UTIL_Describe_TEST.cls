/*
    Copyright (c) 2014 Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
/**
* @author Salesforce Foundation
* @date 2014
* @group Utilities
* @group-content ../../ApexDocContent/Utilities.htm
* @description This class allows easy access to object and field description information from within other classes.
*
* It is called statically, and therefore will supply the same information to all calls made from
* within one transaction, or set of trigger calls. This is beneficial because this info should
* be the same for all calls in a transaction, and by calling it statically we reduce the calls
* that are made, making the total transaction more efficient.
*/
@isTest
public with sharing class UTIL_Describe_TEST {

    // TEST
    static testmethod void testDescribe() {
        
        string s;
        
        Schema.DescribeSObjectResult res = UTIL_Describe_API.getObjectDescribe('Contact');        
        System.assertEquals(res.getName(), 'Contact');
        s = UTIL_Describe_API.getObjectLabel('Contact');
        System.assertEquals (s, res.getLabel());

        account a = new account(name='Test');
        insert a;
        System.assert(UTIL_Describe_API.isObjectIdThisType(a.id, 'Account'));
        
        s = UTIL_Describe_API.getFieldLabelSafe('Account', 'LastModifiedDate');
        
        Schema.DescribeFieldResult fr = UTIL_Describe_API.getFieldDescribe('Account', 'CreatedDate');     
        s = UTIL_Describe_API.getFieldLabelSafe('Account', 'CreatedDate');
        System.assertEquals (s, fr.getLabel());

        Map<String, Schema.DescribeFieldResult> afd = UTIL_Describe_API.getAllFieldsDescribe('Account');
        System.assertEquals ('BillingCity', afd.get('billingcity').getName());
        afd = UTIL_Describe_API.getAllFieldsDescribe('Account');

        SObject acctObj = UTIL_Describe_API.getPrototypeObject('Account');
        // should be able to cast to account
        account acct = (account)(acctObj);

        s = UTIL_Describe_API.getFieldType('Account', 'CreatedDate');
        System.assertEquals('DATETIME', s);
        
        try {
            s = UTIL_Describe_API.getObjectLabel('sdlkfjsdlkfjsldkfjlsdkfj');
        } catch (exception e) {
            System.assertEquals('Invalid object name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
        } 
        try {
            s = UTIL_Describe_API.getFieldLabel('Opportunity', 'sdlkfjsdlkfjsldkfjlsdkfj');
        } catch (exception e) {
            System.assertEquals('Invalid field name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
        }

        System.assertEquals(true, 
            UTIL_Describe_API.canDisplaytypesCopy(Schema.Displaytype.DATE, Schema.Displaytype.DATETIME));

        Map<String, Id> acctTypesMap = UTIL_Describe_API.getRecTypesMapByName('Account');
        System.assertEquals(true, acctTypesMap.size() > 1);

        System.assertEquals(Schema.Displaytype.DATETIME, 
            UTIL_Describe_API.getFieldDisplaytype('Account', 'CreatedDate'));

        Map<String, Schema.DescribeFieldResult> acctIdFieldMap = UTIL_Describe_API.getFieldsOfType('Account', 'ID');
        System.assertEquals(1, acctIdFieldMap.size());

        Map<String, String> picklistEntries = UTIL_Describe_API.getPicklistActiveValuesMap('Account', 'AccountSource');
        System.assert(picklistEntries.size() > 0);

        try {
            picklistEntries = UTIL_Describe_API.getPicklistActiveValuesMap('Account', 'id');
        } catch(UTIL_Describe.SchemaDescribeException sde){}
    } 

    // Test for childRelationshipNamesService functionality
    @isTest
    private static void childRelationshipNamesServiceTest() {

        // Insert Account
        Account adminAccount = UTIL_UnitTestData_API.getMultipleTestAccounts(1, UTIL_Describe_API.getAdminAccRecTypeID())[0];
        adminAccount.Name = 'Test Account 000';
        insert adminAccount;

        Test.startTest();
            Schema.SObjectType sObjectTypeAcc = adminAccount.getSObjectType();
            List<String> allChildRelationshipNames = UTIL_Describe.getAllChildRelationshipNames(sObjectTypeAcc);
        Test.stopTest();

        System.assertNotEquals(NULL, allChildRelationshipNames);
        System.assertNotEquals(0, allChildRelationshipNames.size());
        System.assert(allChildRelationshipNames.contains('Contacts'));
    }

    // NPE Test for childRelationshipNamesService functionality
    @isTest
    private static void childRelationshipNamesNPETest() {
        try {
            Test.startTest();
                List<String> allChildRelationshipNames = UTIL_Describe.getAllChildRelationshipNames(NULL);
            Test.stopTest();
            System.assert(false, 'Always throw an exception when NULL is passed as a parameter');
        } catch (System.NullPointerException npe) { }
    }

    //Test for getCustomAdminAccRecTypeId if the value of Administrative Account Record Type is empty
    @isTest
    private static void getCustomAdminAccRecTypeIdEmptyTest() {                      
        UTIL_CustomSettings_API.getSettingsForTests(new Hierarchy_Settings__c(Administrative_Account_Record_Type__c = null));
        
        Test.startTest();
            Id testCustomAdminAccRecTypeId = Util_Describe.getCustomAdminAccRecTypeId();
        Test.stopTest();

        System.assertEquals(Util_Describe.getAdminAccRecTypeID(), testCustomAdminAccRecTypeId);
    }

    //Test for getCustomAdminAccRecTypeId if the value of Administrative Account Record Type is not empty but the record type does not exist
    @isTest
    private static void getCustomAdminAccRecTypeIdNotEmptyNotExistTest() {    
        UTIL_CustomSettings_API.getSettingsForTests(new Hierarchy_Settings__c(Administrative_Account_Record_Type__c = '000000000000000000'));
        
        Test.startTest();
            Id testCustomAdminAccRecTypeId = Util_Describe.getCustomAdminAccRecTypeId();
        Test.stopTest();

        System.assertEquals(Util_Describe.getAdminAccRecTypeID(), testCustomAdminAccRecTypeId);
    }

    //Test for getCustomAdminAccRecTypeId if the value of Administrative Account Record Type is not empty and the record type exists
    @isTest
    private static void getCustomAdminAccRecTypeIdNotEmptyExistsTest() {
        UTIL_CustomSettings_API.getSettingsForTests(new Hierarchy_Settings__c(Administrative_Account_Record_Type__c = Util_Describe_API.getRecTypesMapByDevName('Account').values()[1]));
        
        Test.startTest();
            Id testCustomAdminAccRecTypeId = Util_Describe.getCustomAdminAccRecTypeId();
        Test.stopTest();

        System.assertEquals(Util_Describe_API.getRecTypesMapByDevName('Account').values()[1], testCustomAdminAccRecTypeId);
    }
}
