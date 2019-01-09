Feature: As an admin user I should have the ability to extend the OE
  of a given Employer with an extended enrollment.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And this employer has a enrollment_extended benefit application
    And this benefit application has a benefit package containing health benefits

  Scenario: As an HBX Staff with Super Admin subroles I should not be able to extend Open Enrollment for an Employer with a enrollment_extended benefit application
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will see the Extend Open Enrollment button
