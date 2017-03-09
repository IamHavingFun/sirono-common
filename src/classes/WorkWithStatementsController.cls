public with sharing class WorkWithStatementsController {
	public static final String VIEW_URL_SUFFIX = '/guarantor/servlet/servlet.FileDownload?file=';

	public class StatementWrapper {
		@AuraEnabled
		public String pdf_Url 			{get;set;}
		@AuraEnabled
		public Statement__c statement 	{get;set;}

		public StatementWrapper(Statement__c statement) {
			this.statement 	= statement;
			if(statement.Attachments != null && statement.Attachments.size() > 0) {
				this.pdf_Url = WorkWithStatementsController.VIEW_URL_SUFFIX + statement.Attachments[0].Id;
			}
		}
	}

	@AuraEnabled
	public static List<StatementWrapper> getAllInfo() {
		List<StatementWrapper> result = new List<StatementWrapper>();
		User currentUser = [SELECT Id, ContactId FROM User WHERE Id = :userInfo.getUserId()];
		if(currentUser.ContactId == null) {
			return result;
		}
		List<Statement__c> statementList = [
												SELECT 
															Id, 
															PdfUrl__c, 
															Statement_Date__c,
															(
																SELECT
																		 Id
																FROM	 Attachments
																ORDER BY CreatedDate DESC
																LIMIT	 1
															)
												FROM 		Statement__c 
												WHERE 		Guarantor__c = :currentUser.ContactId
												ORDER BY 	Statement_Date__c DESC 
												LIMIT 50000
											];
		for(Integer i = 0; i < statementList.size(); i++) {
			result.add(new StatementWrapper(statementList.get(i)));
		}
		return result;
	}
}