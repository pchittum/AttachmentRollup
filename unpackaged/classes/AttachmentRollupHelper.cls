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

public with sharing class AttachmentRollupHelper{

    public static Map<String,csRollupObj__c> validRollups = csRollupObj__c.getAll();
    
    public static void rollupAttachSummary(Map<String,Set<Id>> parentIdMap) {
        Integer rollupObjCount = 0; 
        List<sObject> updates = new List<sObject>();
        Set<Id> lookupIds = new Set<Id>();
        
        //the map gives me discrete chunks of object types to work with. 
        //I only want to go through 10, since my Attachments input set might be for more different 
        //sObject types than the "chunking" feature will allow. 
        for (Set<Id> thisObjSet : parentIdMap.values()){
            lookupIds.addAll(thisObjSet);
            rollupObjCount++;
            if (rollupObjCount == 10) {
                System.debug('***** WARNING reached max of 10 Attachment parent types for rollups *****');
                break; //since I'll be chunking together like sObjects, can only support 10 before hitting governor limit
            }
        }
        
        List<AggregateResult> aggs = [select ParentId, count(Id) attCount, max(CreatedDate) maxCreateDate 
                                        from Attachment 
                                        where ParentId in : lookupIds
                                        group by ParentId
                                        order by ParentId ASC];
                                        
        try{                                
            for (AggregateResult ar : aggs) {
                //refactor this so I'm creating an instance of PSE_monitoring_record__c and comment out the Type dynamic stuff for now
                Schema.sObjectType objType = ((Id) ar.get('ParentId')).getSObjectType();
                csRollupObj__c rollupInfo = validRollups.get(objType.getDescribe().getKeyPrefix());
                sObject newRollup = objType.newSObject((Id)ar.get('ParentId'));
                newRollup.put(rollupInfo.Count_Field__c,ar.get('attCount'));
                if (rollupInfo.Max_Date_Field__c != null) {
                    newRollup.put(rollupInfo.Max_Date_Field__c,ar.get('maxCreateDate'));            
                }
                updates.add(newRollup);
            }
            System.debug('rollups ready to commit: ' + updates);
        } catch (Exception e) {
            AttachmentRollupException ex = new AttachmentRollupException();
            ex.initCause(e);
            ex.setMessage('An exception occurred while trying to rollup Attachment information. Check the Attachment Rollup Object custom setting to ensure that all configured sObjects and fields are correctly named and conform to specifications: Name (3 characters), sObject (valid API name), Count Field (Number), Max Date Field (DateTime)');
            throw ex; 
        }
        
        update updates; 
        
    }

}