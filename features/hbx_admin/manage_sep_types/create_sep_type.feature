Feature: Admin has ability to create a new SEP type for users
  Background:
    Given a Hbx admin with hbx_tier3 permissions exists
    When Hbx Admin logs on to the Hbx Portal
    Given the user is on the Main Page
    And Qualifying life events of all markets are present
    And the user will see the Manage SEP Types under admin dropdown
    When Admin clicks Manage SEP Types

  Scenario Outline: Admin will create a new <market_kind> SEP type
    Given the Admin is navigated to the Manage SEP Types screen
    And expired Qualifying life events of <market_kind> market is present
    When Admin clicks on the Create SEP Type button
    Then Admin navigates to Create SEP Type page
    When Admin fills Create SEP Type form with start and end dates
    And Admin fills Create SEP Type form with Title
    And Admin fills Create SEP Type form with Event label
    And Admin fills Create SEP Type form with Tool Tip
    And Admin selects <market_kind> market radio button and their reason
    And Admin selects effective on kinds for Create SEP Type
    And Admin <action> select termination on kinds for <market_kind> SEP Type
    And Admin fills Create SEP Type form with Pre Event SEP and Post Event SEP dates
    And Admin clicks on Create Draft button
    Then Admin should see SEP Type Created Successfully message
    When Admin navigates to SEP Types List page
    When Admin clicks <market_kind> filter on SEP Types datatable
    And clicks on Draft filter of <market_kind> market filter
    Then Admin should see newly SEP created title on Datatable
    And Hbx Admin logs out

  Examples:
    | market_kind | action |
    | individual  | cannot |
    | shop        |  can   |
    | fehb        |  can   |
