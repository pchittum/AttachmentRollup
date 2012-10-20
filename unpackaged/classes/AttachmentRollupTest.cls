/*
Copyright (c) 2012 , Peter Chittum
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of 
conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list 
of conditions and the following disclaimer in the documentation and/or other materials 
provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGE.
*/

@isTest
public with sharing class AttachmentRollupTest {
    
    //base test object strings. Change these for new test object
    //I don't actually use these values for the test, rather I use them for describe calls
    //to dynamically create test data based on what is entered here. 
    private static final String kTestObjectName = 'Attachment_Rollup_Tester__c';
    private static final String kTestCtFieldName = 'Count_Test__c';
    private static final String kTestDtFieldName = 'Max_Date_Test__c';
    
    private static final Schema.sObjectType kTestObjType;  
    private static final Schema.sObjectField kTestCtField;  
    private static final Schema.sObjectField kTestDtField;  

    public static final Integer kTestObjSetSize = 20; 
    public static final Integer kAttachSize = 10;
    public static final Blob kAttachmentTextBody = Blob.valueOf('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec tincidunt rutrum augue, at consectetur est placerat eget. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris eget massa vitae massa placerat ultricies vel ut augue. Mauris at diam a mi semper aliquam eu nec enim. Sed consectetur risus nec enim eleifend euismod. Nullam augue erat, tempus nec molestie ac, condimentum vel nibh. Nam blandit vestibulum felis sed gravida. Proin mollis, eros vitae vulputate tempor, mauris velit iaculis ligula, vitae dignissim enim massa ut est. Mauris elementum nisi at odio eleifend sed auctor lorem accumsan. Vivamus quis mollis diam. Fusce eleifend.');

    
    //test describe objects
    static {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        kTestObjType = schemaMap.get(kTestObjectName);
        
        //verify test object type is valid
        Boolean hasAttachmentRel = false;
        for (Schema.ChildRelationship objRel : kTestObjType.getDescribe().getChildRelationships()){
            hasAttachmentRel = (objRel.getChildSObject() == Attachment.sObjectType);
            if (hasAttachmentRel) break;
        }
        System.assert(hasAttachmentRel, 'The sObject chosen ('+kTestObjType.getDescribe().getName()+') for Attachment Rollup Testing must have Attachments as a child relationship. Please select another.');
        
        kTestCtField = kTestObjType.getDescribe().fields.getMap().get(kTestCtFieldName);
        kTestDtField = kTestObjType.getDescribe().fields.getMap().get(kTestDtFieldName);
        
        System.assert(kTestCtField.getDescribe().getType()==Schema.DisplayType.Integer || kTestCtField.getDescribe().getType()==Schema.DisplayType.Double,'The Count Rollup Field set for testing is not valid. It must be a Number data type.');
        System.assertEquals(kTestDtField.getDescribe().getType(),Schema.DisplayType.DateTime,'The Max Date Rollup Field set for testing is not valid. It must be a DateTime data type.');
    }
        
    //NOTE: Complete
    //- Basic Insert Success Test. n number of test records with attachments results in corresponding updates to parents. 
    private static testMethod void insertSuccessTest(){
        
        //populate the custom setting with information about our test object
        createCustSettingEntry();
        
        //create lists for test data
        List<sObject> parentRecs = new List<sObject>();
        List<Attachment> attachments = new List<Attachment>();
        
        //get parent records and insert
        parentRecs = createParents(kTestObjType, kTestObjSetSize);
        insert parentRecs; 
        
        attachments = createAttachments(parentRecs, kAttachSize);
        
        Test.startTest();
        insert attachments;
        Test.stopTest();
        
        Set<Id> parentIds = (new Map<Id,sObject>(parentRecs)).keyset();
        
        //assert that each parent record has the correct count.
        String q = 'Select Name, ' + kTestCtField.getDescribe().getName() + ', ' + kTestDtField.getDescribe().getName() 
                        + ', (select CreatedDate from Attachments Order By CreatedDate DESC Limit 1) '
                        + ' FROM ' + kTestObjType.getDescribe().getName()
                        + ' WHERE Id in : parentIds ';
                                
        //get updated values from DB and test for accurate counts and dates             
        for (sObject rec : Database.query(q)){
            System.assertEquals(kAttachSize,rec.get(kTestCtField.getDescribe().getName()),'the count in the attachment count field does not match the test set size for attachments.');
            System.assertEquals(rec.get(kTestDtField.getDescribe().getName()),((List<Attachment>)rec.getSObjects('Attachments')).get(0).CreatedDate,'The max date recorded on the parent record does not match the attachments max date.');
        }
    }
    
    //NOTE: Complete
    //- Basic Insert Success No Date Field Test. n number of test records with attachments results in corresponding updates to parents. 
    private static testMethod void insertNoDateRollupSuccessTest(){
        
        //populate the custom setting with information about our test object
        createCustSettingEntry(false);
        
        //create lists for test data
        List<sObject> parentRecs = new List<sObject>();
        List<Attachment> attachments = new List<Attachment>();
        
        //get parent records and insert
        parentRecs = createParents(kTestObjType, kTestObjSetSize);
        insert parentRecs; 
        
        attachments = createAttachments(parentRecs, kAttachSize);
        
        Test.startTest();
        insert attachments;
        Test.stopTest();
        
        Set<Id> parentIds = (new Map<Id,sObject>(parentRecs)).keyset();
        
        //assert that each parent record has the correct count.
        String q = 'Select Name, ' + kTestCtField.getDescribe().getName() + ', ' + kTestDtField.getDescribe().getName() 
                        + ', (select CreatedDate from Attachments Order By CreatedDate DESC Limit 1) '
                        + ' FROM ' + kTestObjType.getDescribe().getName()
                        + ' WHERE Id in : parentIds ';
                                
        //get updated values from DB and test for accurate counts and dates             
        for (sObject rec : Database.query(q)){
            System.assertEquals(kAttachSize,rec.get(kTestCtField.getDescribe().getName()),'the count in the attachment count field does not match the test set size for attachments.');
            System.assertEquals(null,rec.get(kTestDtField.getDescribe().getName()),'The max date should be null but is not.' );
        }
    }

    //NOTE: Complete
    //- Basic Delete Success Test. n number of deleted test records with attachments results in corresponding updates to parents.
    private static testMethod void deleteSuccessTest(){
        
        //populate the custom setting with information about our test object
        createCustSettingEntry();
        
        //create lists for test data
        List<sObject> parentRecs = new List<sObject>();
        List<Attachment> attachments = new List<Attachment>();
        
        //get parent records and insert
        parentRecs = createParents(kTestObjType, kTestObjSetSize);
        insert parentRecs; 

        Set<Id> parentIds = (new Map<Id,sObject>(parentRecs)).keyset();
        
        attachments = createAttachments(parentRecs, kAttachSize);
        insert attachments;

        String q = 'Select Name, ' + kTestCtField.getDescribe().getName() + ', ' + kTestDtField.getDescribe().getName() 
                        + ', (select CreatedDate from Attachments Order By CreatedDate DESC Limit 1) '
                        + ' FROM ' + kTestObjType.getDescribe().getName()
                        + ' WHERE Id in : parentIds';
        
        List<Attachment> attsToDelete = new List<Attachment>(); 
        Map<Id,Integer> parentCountCache = new Map<Id,Integer>();                       
        //get updated values from DB and test for accurate counts and dates             
        for (sObject rec : Database.query(q)){
            attsToDelete.add(((List<Attachment>)rec.getSObjects('Attachments')).get(0));
            parentCountCache.put((Id)rec.get('Id'),Integer.valueOf(rec.get(kTestCtField.getDescribe().getName())));
        }
        
        Test.startTest();
        delete attsToDelete; 
        Test.stopTest();
        
        for (sObject rec : Database.query(q)){
            System.assertNotEquals(parentCountCache.get((Id)rec.get('Id')),Integer.valueof(rec.get(kTestCtField.getDescribe().getName())),'The old count and new count of attachments matches after deletion. They should not be the same.');
            System.assertEquals(kAttachSize-1,rec.get(kTestCtField.getDescribe().getName()),'the number in the attachment count field does not match the test set size for attachments');
            System.assertEquals(rec.get(kTestDtField.getDescribe().getName()),((List<Attachment>)rec.getSObjects('Attachments')).get(0).CreatedDate,'The max date recorded on the parent record does not match the max date of the attachments after delete.');
        }
    }   

    //NOTE: Complete
    //- Basic Undelete Success Test. n number of test records with attachments results in corresponding updates to parents.
    private static testMethod void undeleteSuccessTest(){
        
        //populate the custom setting with information about our test object
        createCustSettingEntry();
        
        //create lists for test data
        List<sObject> parentRecs = new List<sObject>();
        List<Attachment> attachments = new List<Attachment>();
        
        //get parent records and insert
        parentRecs = createParents(kTestObjType, kTestObjSetSize);
        insert parentRecs; 
        
        Set<Id> parentIds = (new Map<Id,sObject>(parentRecs)).keyset();
        
        attachments = createAttachments(parentRecs, kAttachSize);
        insert attachments;

        String q = 'Select Name, ' + kTestCtField.getDescribe().getName() + ', ' + kTestDtField.getDescribe().getName() 
                        + ', (select CreatedDate from Attachments Order By CreatedDate DESC Limit 1) '
                        + ' FROM ' + kTestObjType.getDescribe().getName()
                        + ' WHERE Id in : parentIds';// + setIdsToStrings(parentMap.keyset());
        
        List<Attachment> attsToDelete = new List<Attachment>(); 
        List<Attachment> attsToUndelete = new List<Attachment>();
        Map<Id,Integer> parentCountCache = new Map<Id,Integer>();                       
        //get updated values from DB and test for accurate counts and dates             
        for (sObject rec : Database.query(q)){
            attsToDelete.add(((List<Attachment>)rec.getSObjects('Attachments')).get(0));
            attsToUndelete.add(new Attachment(id=((List<Attachment>)rec.getSObjects('Attachments')).get(0).Id)) ; //cache secondary list for use when calling undelete. 
            parentCountCache.put((Id)rec.get('Id'),Integer.valueOf(rec.get(kTestCtField.getDescribe().getName())));
        }
        
        //Delete
        delete attsToDelete; 
        
        System.debug('>>>>> current value of deleted attachments' + attsToDelete); 
        
        Test.startTest();
        undelete attsToUndelete;
        Test.stopTest();

        for (sObject rec : Database.query(q)){
            System.assertEquals(parentCountCache.get((Id)rec.get('Id')),Integer.valueof(rec.get(kTestCtField.getDescribe().getName())),'The old count and new count of attachments does not match after undeletion. They should be the same.');
            System.assertEquals(kAttachSize,rec.get(kTestCtField.getDescribe().getName()),'the number recorded in the attachment count field does not match the test set size for attachments');
            System.assertEquals(rec.get(kTestDtField.getDescribe().getName()),((List<Attachment>)rec.getSObjects('Attachments')).get(0).CreatedDate,'The max date recorded on the parent record does not match the max date of attachments after undelete');
        }       
    }

    //NOTE: Complete
    //- Execute trigger with empty custom setting. No result.
        private static testMethod void noCustomSettingTest(){
        
        //populate the custom setting with information about our test object
        
        //create lists for test data
        List<sObject> parentRecs = new List<sObject>();
        List<Attachment> attachments = new List<Attachment>();
        
        //get parent records and insert
        parentRecs = createParents(kTestObjType, kTestObjSetSize);
        insert parentRecs; 
        
        attachments = createAttachments(parentRecs, kAttachSize);
        
        insert attachments;
        
        Set<Id> parentIds = (new Map<Id,sObject>(parentRecs)).keyset();
        
        //assert that each parent record has the correct count.
        String q = 'Select Name, ' + kTestCtField.getDescribe().getName() + ', ' + kTestDtField.getDescribe().getName() 
                        + ', (select CreatedDate from Attachments Order By CreatedDate DESC Limit 1) '
                        + ' FROM ' + kTestObjType.getDescribe().getName()
                        + ' WHERE Id in : parentIds';// + setIdsToStrings(parentMap.keyset());
                                
        //get updated values from DB and test for no counts or dates                
        for (sObject rec : Database.query(q)){
            System.assert(rec.get(kTestCtField.getDescribe().getName()) == null,'the attachment count field is not null when it should be null.');
            System.assert(rec.get(kTestDtField.getDescribe().getName()) == null,'the max date field is not null when it should be null.');
        }
    }
    
    //NOTE: Complete
    //- Create bogus custom setting to produce AttachmentRollupException.
    private static testMethod void invalidSObjectFieldTest(){
        
        //populate the custom setting with information about our test object
        createBogusCustomSetting();
        
        //create lists for test data
        List<sObject> parentRecs = new List<sObject>();
        List<Attachment> attachments = new List<Attachment>();
        
        //get parent records and insert
        parentRecs = createParents(kTestObjType, kTestObjSetSize);
        insert parentRecs; 
        
        attachments = createAttachments(parentRecs, kAttachSize);
        
        Boolean hadException = false;
        try {
            Test.startTest();
            insert attachments;
            Test.stopTest();
        } catch (Exception e) {
            hadException = true; 
            System.assert(e.getCause() instanceof AttachmentRollupException, 'There was an exception in test invalidSObjectFieldTest, but not of the correct exception type');
        }
        System.assert(hadException,'The test invalidSObjectFieldTest should have produced an exception, but did not');
    }
    
    public static List<sObject> createParents(Schema.sObjectType objType, Integer parentSize){
        
        List<sObject> newParents = new List<sObject>();
        for (Integer i = 0 ; i < parentSize ; i ++){
            sObject thisParent = objType.newSObject();
            if (!objType.getDescribe().fields.getMap().get('Name').getDescribe().isAutonumber()){
                thisParent.put('Name','TEST PARENT ' + i);
            }
            newParents.add(thisParent);
        }
        return newParents; 
    }
    
    public static List<Attachment> createAttachments(List<sObject> recs, Integer attSize){
        List<Attachment> newAttaches = new List<Attachment>();
        for (sObject rec : recs) {
            for (Integer i = 0 ; i < attSize ; i++){
                newAttaches.add(new Attachment(ParentId=(Id)rec.get('Id'),body=kAttachmentTextBody,name='attachment'+i+'.txt'));
            }
        }
        return newAttaches;     
    }
    
    //overloaded - planned to do a test where the custom setting has no date set, but didn't complete it. 
    private static void createCustSettingEntry(){
        createCustSettingEntry(true);
    }
    
    private static void createCustSettingEntry(Boolean populateDate){
        csRollupObj__c testSetting = new csRollupObj__c();
        testSetting.Name = kTestObjType.getDescribe().getKeyPrefix();
        testSetting.sObject__c = kTestObjType.getDescribe().getName();
        testSetting.Count_Field__c = kTestCtField.getDescribe().getName();
        if (populateDate) {
            testSetting.Max_Date_Field__c = kTestDtField.getDescribe().getName();
        }
        insert testSetting; 
    }
    
    private static void createBogusCustomSetting(){
        csRollupObj__c testSetting = new csRollupObj__c();
        testSetting.Name = kTestObjType.getDescribe().getKeyPrefix();
        testSetting.sObject__c = kTestObjType.getDescribe().getName();
        testSetting.Count_Field__c = 'somefakefieldname';
        insert testSetting; 
    }
}