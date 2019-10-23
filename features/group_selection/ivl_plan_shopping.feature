Feature: IVL plan purchase

  Scenario: when IVL purchase plan for self & dependent
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    When consumer visits home page after successful ridp
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer clicked on shop for new plan
    Then consumer should see both dependent and primary

  Scenario: when IVL purchase plan only for dependent
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    When consumer visits home page after successful ridp
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    When consumer unchecks the primary person
    And consumer clicked on shop for new plan
    Then consumer should only see the dependent name

  Scenario: IVL having an ineligible family member & doing plan shop
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    When consumer visits home page after successful ridp
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer should see the ineligible family member disabled and unchecked
    And consumer should see the eligible family member enabled and checked
    And consumer should also see the reason for ineligibility
    And consumer should see the dental radio button
    When consumer unchecks the primary person
    And consumer switched to dental benefits
    Then the primary person checkbox should be in unchecked status
    And consumer should also see the reason for ineligibility
    When consumer checks the primary person
    And consumer clicked on shop for new plan
    Then consumer should see primary person

  Scenario: IVL plan shopping by clicking on 'make changes' button on enrollment
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has a dependent in spouse relationship with age greater than 26
    And consumer also has a health enrollment with primary person covered
    When consumer visits home page after successful ridp
    Then consumer should see the enrollment with make changes button
    When consumer clicked on make changes button
    Then consumer should see the ineligible family member disabled and unchecked
    And consumer should see the eligible family member enabled and checked
    And consumer should also see the reason for ineligibility
    When consumer clicked on shop for new plan
    Then consumer should see primary and valid dependent

  Scenario: IVL plan shopping by clicking on 'make changes' button on enrollment
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has a dependent in spouse relationship with age greater than 26
    And consumer also has a health enrollment with primary person covered
    When consumer visits home page after successful ridp
    Then consumer should see the enrollment with make changes button
    When consumer clicked on make changes button
    Then consumer should see the ineligible family member disabled and unchecked
    When consumer clicked on keep existing plan button
    Then consumer should land on confirm page
    And consumer clicks Confirm
    Then consumer should enrollment submitted confirmation page
    And consumer clicks back to my account button
    Then cosumer should see the home page


  Scenario: IVL plan shopping by clicking on 'shop for plan' button should land on Plan shopping page
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer also has a health enrollment with primary person covered
    When consumer visits home page after successful ridp
    Then consumer should see the enrollment with make changes button
    When consumer clicked on make changes button
    And consumer clicked on shop for new plan
    Then consumer should see both dependent and primary

  Scenario: IVL plan shopping by clicking on 'make changes' button on dental enrollment
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has a dependent in spouse relationship with age greater than 26
    And consumer also has a dental enrollment with primary person covered
    When consumer visits home page after successful ridp
    Then consumer should see the dental enrollment with make changes button
    When consumer clicked on make changes button
    Then consumer should see the ineligible family member disabled and unchecked
    And consumer should see the eligible family member enabled and checked
    And consumer should also see the reason for ineligibility
    Then consumer should see keep existing plan and select plan to terminate button
    When consumer clicked on shop for new plan
    Then consumer should see primary and valid dependent
