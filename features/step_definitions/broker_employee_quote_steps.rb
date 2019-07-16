#Capybara.ignore_hidden_elements = false

module BrokerWorld
  def broker(*traits)
    attributes = traits.extract_options!
    @broker ||= FactoryBot.create(:user, :broker_with_person, *traits, attributes)
  end

  def broker_agency(*traits)
    attributes = traits.extract_options!
    @broker_agency ||= FactoryBot.create :broker, *traits, attributes
  end
end

World(BrokerWorld)

Given (/^that a broker exists$/) do
  broker_agency
  broker :with_family, :broker_with_person, organization: broker_agency
  broker_agency_profile = broker_agency.broker_agency_profile
  broker_agency_account = FactoryBot.create(:broker_agency_account, broker_agency_profile: broker_agency_profile, writing_agent_id: broker_agency_profile.primary_broker_role.id)
  employer_profile = FactoryBot.create(:employer_profile)
  employer_profile.broker_agency_accounts << broker_agency_account
  employer_profile.save!
end

And(/^the broker is signed in$/) do
  login_as broker
end

When(/^he visits the Roster Quoting tool$/) do
  visit my_quotes_broker_agencies_broker_role_quotes_path(broker.person.broker_role.id)
end

When(/^click on the New Quote button$/) do
  click_link 'New Quote'
end

When(/^.+ clicks on the Add Prospect Employer button$/) do
  find('#myTabContent a', text: 'Add Prospect Employer').click
end

And(/^Primary Broker creates new Prospect Employer with default_office_location$/) do
  find('#organization_legal_name').click
  fill_in 'organization[legal_name]', :with => "emp1"
  fill_in 'organization[dba]', :with => 101010

  find('.interaction-choice-control-organization-entity-kind').click
  find(".interaction-choice-control-organization-entity-kind-2").click

  find(:xpath, "//select[@name='organization[entity_kind]']/option[@value='c_corporation']")
  fill_in 'organization[office_locations_attributes][0][address_attributes][address_1]', :with => "1818"
  fill_in 'organization[office_locations_attributes][0][address_attributes][address_2]', :with => "exp st"
  fill_in 'organization[office_locations_attributes][0][address_attributes][city]', :with => "Washington"
  fill_in 'organization[office_locations_attributes][0][address_attributes][zip]', :with => "20002"
  fill_in 'organization[office_locations_attributes][0][phone_attributes][area_code]', :with => "202"
  fill_in 'organization[office_locations_attributes][0][phone_attributes][number]', :with => "5551212"
  fill_in 'organization[office_locations_attributes][0][phone_attributes][extension]', :with => "22332"
  find('.interaction-click-control-confirm').click
end

When(/^click on the Upload Employee Roster button$/) do
  click_link "Upload Roster"
end

When(/^the broker clicks on the Select File to Upload button$/) do
  Capybara.ignore_hidden_elements = false
  find(:xpath,"//*[@id='modal-wrapper']/div/form/label").click
  within '.upload_csv' do
    attach_file('employee_roster_file', "#{Rails.root}/spec/test_data/employee_roster_import/Employee_Roster_sample.xlsx")
  end
  Capybara.ignore_hidden_elements = true
end

Then(/^the broker clicks upload button$/) do
  click_button 'Upload'
end

Then(/^the broker should see the data in the table$/) do
  expect(page).to have_selector("input#quote_quote_households_attributes_0_family_id[value=\"1\"]")
  expect(page).to have_selector("input#quote_quote_households_attributes_1_family_id[value=\"2\"]")
  expect(page).to have_selector('div.panel.panel-default div input.uidatepicker', count: 10)
  expect(page).to have_selector("#quote_quote_households_attributes_0_quote_members_attributes_0_dob[value=\"06/01/1980\"]")
  expect(page).to have_selector("input#quote_quote_households_attributes_2_quote_members_attributes_0_first_name[value=\"John\"]")
  expect(page).to have_selector("input#quote_quote_households_attributes_1_quote_members_attributes_0_last_name[value=\"Ba\"]")
end

Then(/^the broker enters the quote effective date$/) do
  select "#{(TimeKeeper.date_of_record+3.month).strftime("%B %Y")}", :from => "quote_start_on"
end

When(/^the broker selects employer type$/) do
 #find('.interaction-choice-control-quote-employer-type').click()
 select "Prospect", :from => "quote_employer_type"
 fill_in 'quote[employer_name]', with: "prospect test Employee"
end

When(/^broker enters valid information$/) do
  fill_in 'quote[quote_name]', with: 'Test Quote'
  fill_in 'quote[quote_households_attributes][0][quote_members_attributes][0][dob]', with: "11/11/1991"
  select "Employee", :from => "quote_quote_households_attributes_0_quote_members_attributes_0_employee_relationship"
  fill_in 'quote[quote_households_attributes][0][quote_members_attributes][0][first_name]', with: "John"
  fill_in 'quote[quote_households_attributes][0][quote_members_attributes][0][last_name]', with: "Bandari"
end

When(/^the broker clicks on the Save Changes button$/) do
  find('.interaction-click-control-save-changes').click
end

Then(/^the broker should see a successful message$/) do
  expect(page).to have_content('Successfully saved quote/employee roster.')
end

Then(/^the broker clicks on Home button$/) do
  sleep 2
  find('.interaction-click-control-home').click
end

Then(/^the broker clicks Actions dropdown$/) do
  find('.dropdown-toggle', :text => "Actions").click
end

When(/^the broker clicks delete$/) do
  find('a', text: "Delete"). click
end

Then(/^the broker sees the confirmation$/) do
  expect(page).to have_content('Are you sure you want to delete Test Quote?')
end

Then(/^the broker clicks Delete Quote$/) do
  expect(page).to have_content(/Test Quote/)
  click_link 'Delete Quote'
end

Then(/^the quote should be deleted$/) do
  sleep 1
  expect(page).not_to have_content(/Test Quote/)
  expect(page).to have_content(/No data available in table/)
end

Then(/^adds a new benefit group$/) do
  fill_in "quote[quote_benefit_groups_attributes][0][title]", with: 'My Benefit Group'
  find('.interaction-click-control-save-changes').click
end

Then(/^the broker saves the quote$/) do
  find('.interaction-click-control-save-changes').click
end

When(/^the broker clicks on quote$/) do
  sleep 1
  click_link 'Test Quote'
end

Given(/^the Plans exist$/) do
  open_enrollment_start_on = TimeKeeper.date_of_record.end_of_month + 1.day
  open_enrollment_end_on = open_enrollment_start_on + 12.days
  start_on = open_enrollment_start_on + 2.months
  end_on = start_on + 1.year - 1.day
  plan1 = FactoryBot.create(:plan, :with_rating_factors, :with_premium_tables, market: 'shop', metal_level: 'silver', active_year: start_on.year, deductible: 5000, csr_variant_id: "01", coverage_kind: 'health')
  plan2 = FactoryBot.create(:plan, :with_rating_factors, :with_premium_tables, market: 'shop', metal_level: 'bronze', active_year: start_on.year, deductible: 3000, csr_variant_id: "01", coverage_kind: 'health')
  plan3 = FactoryBot.create(:plan, :with_rating_factors, :with_premium_tables, market: 'shop', dental_level: 'high', active_year: start_on.year, deductible: 4000, coverage_kind: 'dental')
  plan4 = FactoryBot.create(:plan, :with_rating_factors, :with_premium_tables, market: 'shop', dental_level: 'low', active_year: start_on.year, deductible: 4000, coverage_kind: 'dental')
  Caches::PlanDetails.load_record_cache!
end

Then(/^the broker enters Employer Contribution percentages for health plan$/) do
  page.execute_script(" QuoteSliders.slider_listeners()")
  page.execute_script("$('#pct_employee').bootstrapSlider({})")
  sleep(1)
  find(:xpath, "//div[contains(@class, 'health')]//*[@id='employee_slide_input']").set("80")
  page.execute_script("$('#pct_employee').bootstrapSlider('setValue', employee_value= 80)")
  sleep(1)
  page.execute_script("$('#pct_employee').trigger('slideStop')")
end

Then(/^the broker enters Employer Contribution percentages for dental plan$/) do
  page.execute_script(" QuoteSliders.slider_listeners()")
  page.execute_script("$('#dental_pct_employee').bootstrapSlider({})")
  sleep(1)
  find(:xpath, "//div[contains(@class, 'dental')]//*[@id='employee_slide_input']").set("80")
  page.execute_script("$('#dental_pct_employee').bootstrapSlider('setValue', employee_value= 80)")
  sleep(1)
  page.execute_script("$('#dental_pct_employee').trigger('slideStop')")
end

Then(/^the broker filters health plans$/) do
  find(:xpath, "//*[@id='quote-plan-list']/label[1]").click
  find(:xpath, "//*[@id='quote-plan-list']/label[2]").click
end

Then(/^the broker filters dental plans$/) do
  find(:xpath, "//*[@id='quote-dental-plan-list']/label[1]").click
  find(:xpath, "//*[@id='quote-dental-plan-list']/label[2]").click
end

Then(/^the broker clicks Compare Costs for health plans$/) do
  find('#CostComparison').click
end

Then(/^the broker clicks Compare Costs for dental plans$/) do
  find('#DentalCostComparison').click
end

When(/^the broker selects the Reference Health Plan$/) do
  wait_for_ajax(3)
  find('div#single_plan_1').click
end

When(/^the broker selects the Reference Dental Plan$/) do
  wait_for_ajax(3)
  find('div#single_dental_plan_1').click
  wait_for_ajax
end

Then(/^the broker clicks Publish Quote button$/) do
  find('#publish_quote').click
end

Then(/^the broker sees that the Quote is published$/) do
  expect(page).to have_content('Your quote has been published')
end

When(/^the broker clicks Dental Features$/) do
  find('.interaction-click-control-dental-features-and-cost-criteria').click
end
