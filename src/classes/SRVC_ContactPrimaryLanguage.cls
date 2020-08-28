public virtual with sharing class SRVC_ContactPrimaryLanguage {

    /*********************************************
    * @description Instance for Singleton Pattern.
    **********************************************/
    @TestVisible
    private static SRVC_ContactPrimaryLanguage instance;

    /*********************************************************************
    * @description Empty constructor is not public for Singleton Pattern.
    **********************************************************************/
    protected SRVC_ContactPrimaryLanguage() {}

    /*****************************************************************************
    * @description Static method to get the current instance for Singleton pattern.
    * @return The instance of SRVC_ContactPrimaryLanguage.
    ******************************************************************************/
    public static SRVC_ContactPrimaryLanguage getInstance() {
        if (instance == NULL) {
            instance = new SRVC_ContactPrimaryLanguage();
        }

        return instance;
    }

    /**
     * @description Generate a list of Contact Language records for a list of specified Contacts.
     * @param  contactsList A list of Contacts from which to generate Contact Language records for insertion.
     * @return              A list of Contact Language records to be inserted.
     */
    public virtual List<Contact_Language__c> getContactLanguagesToCreate(List<Contact> contactsList){
        List<Contact_Language__c> contactLanguagesToInsertList = new List<Contact_Language__c>();

        for (Contact con : contactsList){
            if (String.isNotBlank(con.Primary_Language__c)){
                Contact_Language__c conLang = new Contact_Language__c(
                                                    Primary_Language__c = true,
                                                    Contact__c = con.Id,
                                                    Language__c = con.Primary_Language__c,
                                                    Fluency__c = this.getDefaultFluencyFromSettings()
                                                );

                contactLanguagesToInsertList.add(conLang);
            }
        }

        return contactLanguagesToInsertList;
    }

    /**
     * @description Determines if changes to the Primary Language on Contact records are associated with existing Contact Language records or if they require the creation of new Contact Language records.             
     * @param  newContactsById A map of updated contact records by Id.
     * @param  oldContactsById A map containing the previous state of the updated contact records by Id.
     * @return                 A ContactLanguageCategorization value object containing a list of new Contact Language records to insert and a list of existing Contact Language records to update.
     */
    @TestVisible
    public virtual ContactLanguageCategorization getContactLanguagesToCreateOrUpdate(Map<Id, Contact> newContactsById, Map<Id, Contact> oldContactsById){
        Set<Id> contactIdsToUpdateConLangsToNonPrimarySet = new Set<Id>();
        Map<Id, Contact_Language__c> contactLanguageToInsertByContactId = new Map<Id, Contact_Language__c>();
        Map<Id, Id> languageIdToCheckForUpdateByContactId = new Map<Id, Id>();

        for (Contact con : newContactsById.values()){
            List<Contact_Language__c> relatedContactLanguagesList = new List<Contact_Language__c>();
            List<Id> languageIdsToCheckList = new List<Id>();
            Contact oldContact = oldContactsById.get(con.Id);

            if (con.Primary_Language__c == oldContact.Primary_Language__c){
                continue;
            }

            if (oldContact.Primary_Language__c == null || con.Primary_Language__c != null ){
                Contact_Language__c conLang = new Contact_Language__c(
                                                Primary_Language__c = true,
                                                Contact__c = con.Id,
                                                Language__c = con.Primary_Language__c,
                                                Fluency__c = this.getDefaultFluencyFromSettings()
                                            );

                contactLanguageToInsertByContactId.put(con.Id, conLang); 
                languageIdToCheckForUpdateByContactId.put(con.Id, con.Primary_Language__c);
            }

            if (oldContact.Primary_Language__c != null || con.Primary_Language__c == null){
                contactIdsToUpdateConLangsToNonPrimarySet.add(con.Id);
            }
        }

        List<Contact_Language__c> contactLanguagesToUpdateAsNonPrimaryList = this.getContactLanguagesToUpdateAsNonPrimary(contactIdsToUpdateConLangsToNonPrimarySet);
        ContactLanguageCategorization contactLanguageInsUp = this.getPrimaryContactLanguagesToInsertOrUpdate(contactLanguageToInsertByContactId.clone(),
                                                                                                                languageIdToCheckForUpdateByContactId.clone());
        
        contactLanguageInsUp.addContactLanguagesToUpdate(contactLanguagesToUpdateAsNonPrimaryList);
        return contactLanguageInsUp;
    }


    /**
     * @description Retrieves a list of Contact Languages currently marked as primary that are to be updated as non-primary.
     * @param  contactIdsToMarkAsNonPrimarySet A set of Contact Ids associated with Contact Languages to process.
     * @return A list of Contact Language records to be updated as non-primary.
     */
    @TestVisible
    protected virtual List<Contact_Language__c> getContactLanguagesToUpdateAsNonPrimary(Set<Id> contactIdsToMarkAsNonPrimarySet){

        List<Contact_Language__c> contactLanguagesToUpdateAsNonPrimary = new List<Contact_Language__c>();

        contactLanguagesToUpdateAsNonPrimary = [SELECT Id,
                                                       Contact__c,
                                                       Language__c,
                                                       Primary_Language__c
                                                FROM Contact_Language__c
                                                WHERE Contact__c IN :contactIdsToMarkAsNonPrimarySet
                                                AND Primary_Language__c = true];

        for (Contact_Language__c conLang : contactLanguagesToUpdateAsNonPrimary){
            conLang.Primary_Language__c = false;
        }

        return contactLanguagesToUpdateAsNonPrimary;
    }

    /**
     * @description Retrieves the default language fluency setting specified in EDA Settings.
     * @return   The default language fluency value set in EDA Settings.
     */
    @TestVisible
    private String getDefaultFluencyFromSettings(){
        return UTIL_CustomSettingsFacade.getSettings().Default_Contact_Language_Fluency__c;
    }

    /**
     * @description Determines if a Contact Language record flagged for insertion is marked as primary on the corresponding contact record.  If so,
     * separates the Contact Language into a list for update; marking its Primary Language status and removing it from the insertion list.
     * @param contactLanguagesToInsertByContactId A map of Contact Languages to be inserted by Contact Id.
     * @param languageIdToCheckForUpdateByContactId A map of Languages currently marked as primary by Contact Id.
     * @return A ContactLanguageCategorization value object containing one list containing Contact Language records to be inserted and 
     *         another containing Contact Language records to be updated.                                         
     */
    @TestVisible
    protected virtual ContactLanguageCategorization getPrimaryContactLanguagesToInsertOrUpdate(Map<Id, Contact_Language__c> contactLanguagesToInsertByContactId,
                                                                                    Map<Id, Id> languageIdToCheckForUpdateByContactId){

        List<Contact_Language__c> contactLanguagesToUpdateToPrimaryList = new List<Contact_Language__c>();

        List<Contact_Language__c> existingContactLanguagesList = [SELECT Id,
                                                                          Language__c,
                                                                          Contact__c,
                                                                          Primary_Language__c
                                                                  FROM Contact_Language__c
                                                                  WHERE Contact__c IN :languageIdToCheckForUpdateByContactId.keySet()
                                                                  AND (Language__c IN :languageIdToCheckForUpdateByContactId.values()
                                                                                   OR Primary_Language__c = true)
                                                                 ];
                                                                        
        for (Contact_Language__c conLang : existingContactLanguagesList){
            if (languageIdToCheckForUpdateByContactId.containsKey(conLang.Contact__c) &&
                languageIdToCheckForUpdateByContactId.get(conLang.Contact__c) == conLang.Language__c){
                
                conLang.Primary_Language__c = true;
                contactLanguagesToUpdateToPrimaryList.add(conLang);
                contactLanguagesToInsertByContactId.remove(conLang.Contact__c);
            } 
        }

        ContactLanguageCategorization contactLangInsUp = new ContactLanguageCategorization(contactLanguagesToInsertByContactId.values(), 
                                                                                            contactLanguagesToUpdateToPrimaryList);

        return contactLangInsUp;
    }

    /**
     * @description Value object containing a list of Contact Language records to be inserted and a list of Contact Language records to be updated.
     */
    public class ContactLanguageCategorization{
        private List<Contact_Language__c> contactLanguagesToInsertList;
        private List<Contact_Language__c> contactLanguagesToUpdateList;
        
        public ContactLanguageCategorization(List<Contact_Language__c> contactLanguagesToInsertList, 
                                            List<Contact_Language__c> contactLanguagesToUpdateList){

            this.contactLanguagesToInsertList = contactLanguagesToInsertList;
            this.contactLanguagesToUpdateList = contactLanguagesToUpdateList;
        }

        /**
         * @description Combines a list of Contact Language records with existing records in contactLanguagesToUpdateList.
         * @param  contactLanguagesToAddList A list of Contact Languages to add.
         */ 
        public void addContactLanguagesToUpdate(List<Contact_Language__c> contactLanguagesToAddList){
            this.contactLanguagesToUpdateList.addAll(contactLanguagesToAddList);
        } 

        /**
         * @description Accessor method for contactLanguagesToInsertList.
         * @return   A list of Contact Languages to be inserted.
         */
        public List<Contact_Language__c> getContactLanguagesToInsert(){
            return this.contactLanguagesToInsertList;
        }

        /**
         * @description Accessor method for contactLanguagesToUpdateList.
         * @return   A list of Contact Languages to be updated.
         */
        public List<Contact_Language__c> getContactLanguagesToUpdate(){
            return this.contactLanguagesToUpdateList;
        }
    }
}

