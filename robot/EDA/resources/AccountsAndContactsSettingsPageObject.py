from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from locators import eda_lex_locators
from selenium.webdriver.common.keys import Keys


@pageobject("Accounts_and_Contacts", "HEDA_Settings")
class AccountsAndContactsSettingsPage(BasePage):

    @property
    def eda(self):
        return self.builtin.get_library_instance('EDA')

    def _is_current_page(self):
        """
            Verify we are on the EDA Settings page for Accounts and Contacts
            by verifying the HEDA Settings URL and the Accounts and Contacts tab
        """
        location = "/lightning/n/{}{}".format(self.eda.get_eda_namespace_prefix(), self._object_name)
        self.selenium.location_should_contain(location)

        locator_tab = eda_lex_locators["eda_settings"]["tab"].format("Affiliations")
        self.selenium.wait_until_page_contains_element(
            locator_tab,
            error=f"Accounts and Contacts tab with locator '{locator_tab}' is not available on the page"
        )

    def clear_the_disable_preferred_phone_enforcement(self):
        """ Verify that Disable Preferred Phone enforcement checkbox is not checked
            Clear the checkbox if it is set
            Do nothing if the checkbox is already empty
        """
        # Checkbox for 'Disable Preferred Phone enforcement' should be empty
        if self.eda._check_if_element_exists(eda_lex_locators["accounts_contacts_settings_locators"]["disable_preferred_phone"]):
            self.builtin.log("Disable Preferred Phone enforcement is clear.")
        else:

            # Click on Edit button
            self.selenium.click_button("Edit")
            self.builtin.log("Setting 'Disable Preferred Phone enforcement' checkbox.")
            self.builtin.log(
                "Disable Preferred Phone enforcement is currently checked.\n" +
                "In EDIT mode"
            )
            self.builtin.log("Clearing 'Disable Preferred Phone enforcement' checkbox.")
            self.selenium.driver.execute_script(
                "arguments[0].click()",
                self.selenium.driver.find_element_by_xpath(eda_lex_locators["accounts_contacts_settings_locators"]["disable_checked"])
            )
            self.selenium.click_button("Save")
            self.eda.close_toast_message()

        # Before running the 'Run Cleanup', we need to choose a
        # field for the Preferred Phone to copy the value from,
        # if you're not using the standard Phone field (or it has
        # no value) and more than one 'Phone' field is defined.
        # We'll choose 'Work Phone'

        self.selenium.click_button("Edit")

        locator_copy_from = eda_lex_locators["accounts_contacts_settings_locators"]["copy_from"]
        if self.eda._check_if_element_exists(locator_copy_from):
            self.selenium.driver.execute_script(
                "arguments[0].click()",
                self.selenium.driver.find_element_by_xpath(locator_copy_from)
            )
        self.selenium.get_webelement(locator_copy_from).send_keys("H" + Keys.ENTER)

        # Click Save
        self.selenium.click_button("Save")
        self.eda.close_toast_message()
        self.builtin.log(
            "Disable Preferred Phone enforcement checkbox has been cleared.\n" +
            "Saving changes.\n" +
            "Proper configuration is in place for testing 'Disable Preferred Phone enforcement'."
        )

    def disable_enhanced_checkbox(self):
        """ Verify that Enable Enhanced Preferred Phone Functionality checkbox is not checked
            Clear the checkbox if it is set
            Do nothing if the checkbox is already empty
        """
        # Click on Edit button
        self.selenium.click_button("Edit")
        self.builtin.log("Clearing 'Enable Enhanced Preferred Phone Functionality' checkbox.")

        # Checkbox for 'Enable Enhanced Preferred Phone Functionality' should be empty
        if self.eda._check_if_element_exists(eda_lex_locators["accounts_contacts_settings_locators"]["enhanced_preferred_clear"]):
            self.builtin.log("Enable Enhanced Preferred Phone Functionality is clear.")
            return
        else:
            self.builtin.log(
                "Enable Enhanced Preferred Phone Functionality is checked.\n" +
                "Opening EDIT mode"
            )
            self.builtin.log("Clearing 'Enable Enhanced Preferred Phone Functionality' checkbox.")

            # Clear the check in the checkbox
            self.selenium.driver.execute_script(
                "arguments[0].click()",
                self.selenium.driver.find_element_by_xpath(eda_lex_locators["accounts_contacts_settings_locators"]["enhanced_preferred_set_faux"])
            )
        # Click Save
        self.selenium.click_button("Save")
        self.eda.close_toast_message()
        self.builtin.log(
            "Enable Enhanced Preferred Phone Functionality setting has been cleared.\n" +
            "Saving changes.\n" +
            "Proper configuration is in place for testing 'Disable Preferred Phone enforcement'."
        )

    def enable_enhanced_checkbox(self):
        """ Ensure that the Enhanced Preferred Phone Functionality checkbox is checked
            Set the checkbox if it is not set
            Do nothing if the checkbox is already set
        """
        # Checkbox for 'Disable Preferred Phone enforcement' needs to be marked as checked
        locator_preferred_set = eda_lex_locators["accounts_contacts_settings_locators"]["enhanced_preferred_set"]
        locator_preferred_clear_faux = eda_lex_locators["accounts_contacts_settings_locators"]["enhanced_preferred_clear_faux"]
        if self.eda._check_if_element_exists(locator_preferred_set):
            self.builtin.log("Enable Enhanced Preferred Phone Functionality is checked.")
            return
        else:
            self.builtin.log(
                "Enable Enhanced Preferred Phone Functionality is NOT checked.\n" +
                "Opening EDIT mode"
            )
            self.selenium.click_button("Edit")
            self.builtin.log("Setting 'Enable Enhanced Preferred Phone Functionality' checkbox.")
            self.selenium.wait_until_page_contains_element(locator_preferred_clear_faux, timeout=60)
            self.salesforce._jsclick(locator_preferred_clear_faux)
            self.selenium.click_button("Save")
            self.eda.close_toast_message()
            self.builtin.log(
                "Enable Enhanced Preferred Phone Functionality setting has been set.\n" +
                "Saving changes.\n" +
                "Proper configuration is in place for testing 'Disable Preferred Phone enforcement'."
            )

    def set_the_disable_preferred_phone_enforcement(self):
        """ Verify that Disable Preferred Phone enforcement checkbox is checked.
            Set the checkbox if it is not already set.
            Do nothing if the checkbox is already checked.
        """
        # Checkbox for 'Disable Preferred Phone enforcement' needs to be marked as checked
        if self.eda._check_if_element_exists(eda_lex_locators["accounts_contacts_settings_locators"]["preferred_phone_active"]):
            self.builtin.log("Disable Preferred Phone enforcement is checked.")
            return
        else:
            self.builtin.log(
                "Disable Preferred Phone enforcement is NOT checked.\n" +
                "Opening EDIT mode"
            )
            self.selenium.click_button("Edit")
            self.builtin.log("Setting 'Disable Preferred Phone enforcement' checkbox.")

            self.selenium.wait_until_page_contains_element(
                eda_lex_locators["accounts_contacts_settings_locators"]["disable_checked"],
                timeout=60,
            )
            self.selenium.driver.execute_script(
                "arguments[0].click()",
                self.selenium.driver.find_element_by_xpath(eda_lex_locators["accounts_contacts_settings_locators"]["disable_checked"])
            )
            self.selenium.click_button("Save")
            self.eda.close_toast_message()
            self.builtin.log(
                "Disable Preferred Phone enforcement checkbox has been checked.\n" +
                "Saving changes.\n" +
                "Proper configuration is in place for testing 'Disable Preferred Phone enforcement'."
            )
