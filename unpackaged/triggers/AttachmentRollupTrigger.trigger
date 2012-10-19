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