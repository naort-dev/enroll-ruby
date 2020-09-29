Feature: User should be able to pay for plan

  Background: Hbx Admin navigates to create a user applications
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin creates a consumer application
    Then Hbx Admin logs out

  Scenario Outline: Hbx Admin uploads and verifies application document
    Given that a person exists in EA
    And the person has an active <role>
    And the person goes plan shopping in the individual for a new plan
    When the person enrolls in a Kaiser plan
    And I click on purchase confirm button for matched person
    Then I should click on pay now button
    And I should see model pop up
    Then I should see Leave DC Health LINK buttton
    And I should be able to click  Leave DC Health LINK buttton
    And I should see an alert with error message

  Examples:
  | role          |
  | consumer role |
  | resident role |

  Scenario Outline: Hbx Admin uploads and verifies application document
    Given that a person exists in EA
    And the person has an active <role>
    And the person goes plan shopping in the individual for a new plan
    When the person enrolls in a Kaiser plan
    And I click on purchase confirm button for matched person
    And tries to purchase with a break in coverage
    Then I click on purchase confirm button for matched person
    And I should click on pay now button

    Examples:
      | role          |
      | consumer role |
      | resident role |