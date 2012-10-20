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

trigger AttachmentRollupTrigger on Attachment (after delete, after insert, after undelete, after update) {

    List<sObject> recordsToRollup = new List<sObject>(); 
    Map<String,Set<Id>> parentMap = new Map<String,Set<Id>>();

    if (AttachmentRollupHelper.validRollups.size() > 0){//use custom setting as switch. if no entries, then no action!
        List<Attachment> atts = Trigger.isDelete ? Trigger.old : Trigger.new;
        
        for (Attachment att : atts) {
            String prefix = att.ParentId.getSObjectType().getDescribe().getKeyPrefix();
            if (AttachmentRollupHelper.validRollups.keyset().contains(prefix)){
                if (parentMap.keyset().contains(prefix)){ 
                    parentMap.get(prefix).add(att.ParentId);
                } else {
                    parentMap.put(prefix,new Set<id>{att.ParentId});
                }
            } 
        }
        
        if (parentMap.size() > 0) {
            System.debug('Attachment rollup processing: ' + parentMap.size() + ' object types with ' + parentMap.values());
            AttachmentRollupHelper.rollupAttachSummary(parentMap);
        } else {
            System.debug('no attachment parents. We are done here');
        }
    }

}