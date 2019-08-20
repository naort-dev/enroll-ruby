Feature: Create Benefit Application by admin UI

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role

  Scenario Outline: Existing Draft/Termination Pending Application
    Given initial employer ABC Widgets has <aasm_state> benefit application with terminated on <event>
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer
    And the user has clicked the Create Plan Year button
    And the user has a valid input for all required fields
    When the admin clicks SUBMIT
    Then the user will see a <message> message
    And staff role person logged in
    And ABC Widgets goes to the benefits tab I should see plan year information
    And the draft application will <action>
    And the existing applications for ABC Widgets will be <title>

  # draft_py_date_gt_term_on: 'draft benefit application' effective on is greater than 'termination pending benefit application' terminated on
  # draft_py_date_lt_term_on: 'draft benefit application' effective on is less than 'termination pending benefit application' terminated on
    Examples:
      | aasm_state          | title               |         event             | message                                             | action          |
      | draft               | Canceled            | draft_py_effective_on     | Successfully created a draft plan year              |  be created     |
      | termination_pending | Termination Pending | draft_py_date_gt_term_on  | Successfully created a draft plan year              |  be created     |
      | termination_pending | Termination Pending | draft_py_date_lt_term_on  | Existing plan year with overlapping coverage exists |  NOT be created |

  Scenario Outline: Existing <title> Application for cancel button
    Given initial employer ABC Widgets has <aasm_state> benefit application
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer
    And the user has clicked the Create Plan Year button
    And the user has a valid input for all required fields
    When the admin clicks SUBMIT
    Then the user will see a pop up modal with "Confirm" or "Cancel" action
    When the admin clicks Cancel
    And staff role person logged in
    And ABC Widgets goes to the benefits tab I should see plan year information
    Then the existing applications for ABC Widgets will be <title>
    And the draft application will NOT be created

    Examples:
      | title                 | aasm_state            |
      | Publish Pending       | pending               |
      | Enrolling             | enrollment_open       |
      | Enrollment Closed     | enrollment_closed     |
      | Enrolled              | binder_paid           |
      | Enrollment Ineligible | enrollment_ineligible |
      | Active                | active                |

  Scenario Outline: Existing <title> Application for confirm  button
    Given initial employer ABC Widgets has <aasm_state> benefit application
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer
    And the user has clicked the Create Plan Year button
    And the user has a valid input for all required fields
    When the admin clicks SUBMIT
    Then the user will see a pop up modal with "Confirm" or "Cancel" action
    When the admin clicks CONFIRM
    Then the user will see a <message> message
    And staff role person logged in
    And ABC Widgets goes to the benefits tab I should see plan year information
    And the draft application will be created
    And the existing applications for ABC Widgets will be <after_submit_title>

    Examples:
      | title                 | aasm_state            | after_submit_title  | message |
      | Publish Pending       | pending               | Canceled            | Successfully created a draft plan year |
      | Enrolling             | enrollment_open       | Canceled            | Successfully created a draft plan year |
      | Enrollment Closed     | enrollment_closed     | Canceled            | Successfully created a draft plan year |
      | Enrolled              | binder_paid           | Canceled            | Successfully created a draft plan year |
      | Enrollment Ineligible | enrollment_ineligible | Canceled            | Successfully created a draft plan year |
      | Active                | active                | Termination Pending | Successfully created a draft plan year |