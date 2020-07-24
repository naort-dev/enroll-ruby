Given(/^a Hbx admin with hbx_tier3 permissions exists$/) do
  #Note: creates an enrollment for testing purposes in the UI
  p_staff=Permission.create(name: 'hbx_tier3', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
      modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: true, can_access_outstanding_verification_sub_tab: true, can_manage_qles: true)
  person = people['Hbx Admin']
  hbx_profile = FactoryBot.create :hbx_profile
  user = FactoryBot.create :user, :with_family, :hbx_staff, email: person[:email], password: person[:password], password_confirmation: person[:password]
  FactoryBot.create :hbx_staff_role, person: user.person, hbx_profile: hbx_profile, permission_id: p_staff.id
  FactoryBot.create :hbx_enrollment,family: user.primary_family, household: user.primary_family.active_household
end

And(/^the user will see the Manage SEP Types under admin dropdown$/) do
  find('.dropdown-toggle', :text => "Admin").click
  expect(page).to have_content('Manage SEP Types')
end

When("Admin clicks Manage SEP Types") do
  page.find('.interaction-click-control-manage-sep-types').click
end

Given("the Admin is navigated to the Manage SEP Types screen") do
  expect(page).to have_content('Manage SEP Types')
end

Then("Admin should see sorting SEP Types button and create SEP Type button") do
  expect(page).to have_content('Sorting SEP Types')
  step "Admin navigates to Create SEP Type page"
end

And(/^the Admin has the ability to use the following filters for documents provided: All, Individual, Shop and Congress$/) do
  expect(page).to have_xpath('//*[@id="Tab:all"]', text: 'All')
  expect(page).to have_xpath('//*[@id="Tab:ivl_qles"]', text: 'Individual')
  expect(page).to have_xpath('//*[@id="Tab:shop_qles"]', text: 'Shop')
  expect(page).to have_xpath('//*[@id="Tab:fehb_qles"]', text: 'Congress')
end

When("Admin clicks on List SEP Types link") do
  click_link 'List SEP Types'
end

Then("Admin navigates to SEP Type List page") do
  step "the Admin is navigated to the Manage SEP Types screen"
end

def ivl_qualifying_life_events
  {:effective_on_event_date => 1, :effective_on_first_of_month => 2}.map { |event_trait , ordinal_position| FactoryBot.create(:qualifying_life_event_kind, event_trait, market_kind: "individual", post_event_sep_in_days: 90, ordinal_position: ordinal_position)}
end

def  shop_qualifying_life_events
  @shop_qles ||= [FactoryBot.create(:qualifying_life_event_kind, title: 'Covid-19', reason: 'covid-19', market_kind: "shop", post_event_sep_in_days: 1,  effective_on_kinds: ["first_of_this_month", "fixed_first_of_next_month"], ordinal_position: 1, qle_event_date_kind: :submitted_at),
    FactoryBot.create(:qualifying_life_event_kind, market_kind: "shop", post_event_sep_in_days: 90, ordinal_position: 2)]
end

def fehb_qualifying_life_events
  {:effective_on_fixed_first_of_next_month => 1, :adoption => 2}.map { |event_trait , ordinal_position| FactoryBot.create(:qualifying_life_event_kind, event_trait, market_kind: "fehb", post_event_sep_in_days: 90, ordinal_position: ordinal_position)}
end

And(/^Qualifying life events of all markets are present$/) do
  ivl_qualifying_life_events
  shop_qualifying_life_events
  fehb_qualifying_life_events
end

When("Admin clicks on the Sorting SEP Types button") do
  page.find('.interaction-click-control-sorting-sep-types').click
end

Then("Admin should see three tabs Individual, Shop and Congress markets") do
  expect(page).to have_content('Individual')
  expect(page).to have_content('Shop')
  expect(page).to have_content('Congress')
end

When("Admin clicks on Individual tab") do
  find(:xpath, '//div[2]/div[2]/ul/li[1]/a').click
end

Then("I should see listed Individual market SEP Types") do
  expect(page).to have_content('Had a baby')
  expect(page).to have_content('Married')
end

Then(/^\w+ should see listed Individual market SEP Types with ascending ordinal positions$/) do
  step "I should see listed Individual market SEP Types"
  birth_ivl = page.all('div').detect { |div| div[:id] == 'birth_individual'}
  birth_ivl['data-ordinal_position'] == '1'
  marraige_ivl = page.all('div').detect { |div| div[:id] == 'marriage_individual'}
  marraige_ivl['data-ordinal_position'] == '2'
end

When("Admin sorts Individual SEP Types by drag and drop") do
  l = find("#birth_individual")
  k = find("#marriage_individual")
  k.drag_to(l)
end

And("listed Individual SEP Types ordinal postions should change") do
  expect(page).to have_content('Married')
  marraige_ivl = page.all('div').detect { |div| div[:id] == 'marriage_individual'}
  marraige_ivl['data-ordinal_position'] == '1'
  expect(page).to have_content('Had a baby')
  birth_ivl = page.all('div').detect { |div| div[:id] == 'birth_individual'}
  birth_ivl['data-ordinal_position'] == '2'
end

When("Admin clicks on Shop tab") do
  find(:xpath, '//div[2]/div[2]/ul/li[2]/a').click
end

Then(/^\w+ should see listed Shop market SEP Types with ascending ordinal positions$/) do
  expect(page).to have_content('Covid-19')
  expect(page).to have_content('Married')
  birth_shop = page.all('div').detect { |div| div[:id] == 'covid-19_shop'}
  birth_shop['data-ordinal_position'] == '1'
  marraige_shop = page.all('div').detect { |div| div[:id] == 'marriage_shop'}
  marraige_shop['data-ordinal_position'] == '2'
end

When("Admin sorts Shop SEP Types by drag and drop") do
  l = find("#covid-19_shop")
  k = find("#marriage_shop")
  k.drag_to(l)
end

Then("listed Shop SEP Types ordinal postions should change") do
  expect(page).to have_content('Married')
  marraige_shop = page.all('div').detect { |div| div[:id] == 'marriage_shop'}
  marraige_shop['data-ordinal_position'] == '2'
  expect(page).to have_content('Covid-19')
  birth_shop = page.all('div').detect { |div| div[:id] == 'covid-19_shop'}
  birth_shop['data-ordinal_position'] == '2'
end

When("Admin clicks on Congress tab") do
  find(:xpath, '//div[2]/div[2]/ul/li[3]/a').click
end

Then(/^\w+ should see listed Congress market SEP Types with ascending ordinal positions$/) do
  expect(page).to have_content('Losing other health insurance')
  expect(page).to have_content('Adopted a child')
  birth_fehb = page.all('div').detect { |div| div[:id] == 'lost_access_to_mec_fehb'}
  birth_fehb['data-ordinal_position'] == '1'
  marraige_fehb = page.all('div').detect { |div| div[:id] == 'adoption_fehb'}
  marraige_fehb['data-ordinal_position'] == '2'
end

When("Admin sorts Congress SEP Types by drag and drop") do
  l = find("#lost_access_to_mec_fehb")
  k = find("#adoption_fehb")
  k.drag_to(l)
end

Then("listed Congress SEP Types ordinal postions should change") do
  expect(page).to have_content('Adopted a child')
  marraige_fehb = page.all('div').detect { |div| div[:id] == 'adoption_fehb'}
  marraige_fehb['data-ordinal_position'] == '1'
  expect(page).to have_content('Losing other health insurance')
  birth_fehb = page.all('div').detect { |div| div[:id] == 'lost_access_to_mec_fehb'}
  birth_fehb['data-ordinal_position'] == '2'
end

Then(/^Admin should see successful message after sorting$/) do
  expect(page).to have_content('Successfully sorted')
  sleep(2)
end

When("Individual with known qles visits the Insured portal outside of open enrollment") do
  FactoryBot.create(:hbx_profile, :no_open_enrollment_coverage_period)
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  visit "/"
  click_link 'Consumer/Family Portal'
  screenshot("individual_start")
end

And("Employee signed in") do
  find('.btn-link', :text => 'Sign In Existing Account', wait: 5).click
  sleep 5
  fill_in "user[login]", :with => "patrick.doe@dc.gov"
  fill_in "user[password]", :with => "aA1!aA1!aA1!"
  find('.sign-in-btn').click
end

Then("Employee should land on home page") do
  step "I should land on home page"
end

And("expired Qualifying life events of Shop market is present") do
  FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: 'shop', post_event_sep_in_days: 90, ordinal_position: 3, aasm_state: 'expired', reason: 'domestic partnership')
  reasons = QualifyingLifeEventKind.by_market_kind('shop').non_draft.pluck(:reason).uniq
  Types.const_set('ShopQleReasons', Types::Coercible::String.enum(*reasons))
end

When("Admin clicks on the Create SEP Type button") do
  page.find('.interaction-click-control-create-sep-types').click
end

Then("Admin navigates to Create SEP Type page") do
  expect(page).to have_content('Create SEP Type')
end

When("Admin fills the Create SEP Type form page for Shop market") do
  fill_in "Start Date", with: TimeKeeper.date_of_record.prev_month.at_beginning_of_month.strftime('%m/%d/%Y').to_s
  fill_in "End Date", with: TimeKeeper.date_of_record.next_year.prev_month.end_of_month.strftime('%m/%d/%Y').to_s
  fill_in "Title", with: "Entered into a legal domestic partnership"
  fill_in "Event Label", with: "Date of domestic partnership"
  fill_in "Tool Tip", with: "Enroll or add a family member due to a new domestic partnership"
end

And("Admin selects Shop market radio button and their reason") do
  sleep(2)
  find(:xpath, '//input[@value="shop"]', :wait => 2).click
  find(:xpath, '//select[@id="reason"]', :wait => 10).click
  find("option[value='domestic partnership']").click
end

And("Admin fills rest of the form on create page") do
  find("input[type='checkbox'][name='forms_qualifying_life_event_kind_form[effective_on_kinds][]'][value='date_of_event']").set(true)
  find("input[type='checkbox'][name='forms_qualifying_life_event_kind_form[termination_on_kinds][]'][value='date_of_event']").set(true)
  fill_in "Pre Event SEP( In Days )", with: "0"
  fill_in "Post Event SEP( In Days )", with: "30"
end

And("Admin clicks on Create Draft button") do
  page.find_button('Create Draft').click
end

Then("Admin should see SEP Type Created Successfully message") do
  expect(page).to have_content('New SEP Type Created Successfully')
end

When("Admin navigates to SEP Types List page") do
  step "Admin should see sorting SEP Types button and create SEP Type button"
end

When("Admin clicks Shop filter on SEP Types datatable") do
  divs = page.all('div')
  shop_filter = divs.detect { |div| div.text == 'Shop' && div[:id] == 'Tab:shop_qles' }
  shop_filter.click
end

And("Admin clicks Draft filter under Shop filter on SEP Types datatable") do
  filter_divs = page.all('div')
  shop_draft_filter = filter_divs.detect { |div| div.text == 'Draft' && div[:id] == 'Tab:shop_qles-shop_draft_qles' }
  shop_draft_filter.click
end

Then("Admin should see newly SEP created title on Datatable") do
  expect(page).to have_content('Entered into a legal domestic partnership')
end

Given("expired Qualifying life events of Individual market is present") do
  FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: 'individual', post_event_sep_in_days: 90, ordinal_position: 3, aasm_state: 'expired', reason: 'domestic partnership')
  reasons = QualifyingLifeEventKind.by_market_kind('individual').non_draft.pluck(:reason).uniq
  Types.const_set('IndividualQleReasons', Types::Coercible::String.enum(*reasons))
end

When("Admin fills the Create SEP Type form page for Individual market") do
  step "Admin fills the Create SEP Type form page for Shop market"
end

When("Admin selects Individual market radio button and their reason") do
  sleep(2)
  find(:xpath, '//input[@value="individual"]', :wait => 2).click
  find(:xpath, '//select[@id="reason"]', :wait => 10).click
  find("option[value='domestic partnership']").click
end

When("Admin clicks Individual filter on SEP Types datatable") do
  divs = page.all('div')
  ivl_filter = divs.detect { |div| div.text == 'Individual' && div[:id] == 'Tab:ivl_qles' }
  ivl_filter.click
end

When("Admin clicks Draft filter under Individual filter on SEP Types datatable") do
  filter_divs = page.all('div')
  ivl_draft_filter = filter_divs.detect { |div| div.text == 'Draft' && div[:id] == 'Tab:ivl_qles-ivl_draft_qles' }
  ivl_draft_filter.click
end

Given("expired Qualifying life events of Congress market is present") do
  FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: 'fehb', post_event_sep_in_days: 90, ordinal_position: 3, aasm_state: 'expired', reason: 'domestic partnership')
  reasons = QualifyingLifeEventKind.by_market_kind('fehb').non_draft.pluck(:reason).uniq
  Types.const_set('FehbQleReasons', Types::Coercible::String.enum(*reasons))
end

When("Admin fills the Create SEP Type form page for Congress market") do
  step "Admin fills the Create SEP Type form page for Shop market"
end

When("Admin selects Congress market radio button and their reason") do
  sleep(2)
  find(:xpath, '//input[@value="fehb"]', :wait => 2).click
  find(:xpath, '//select[@id="reason"]', :wait => 10).click
  find("option[value='domestic partnership']").click
end

When("Admin clicks Congress filter on SEP Types datatable") do
  divs = page.all('div')
  fehb_filter = divs.detect { |div| div.text == 'Congress' && div[:id] == 'Tab:fehb_qles' }
  fehb_filter.click
end

When("Admin clicks Draft filter under Congress filter on SEP Types datatable") do
  filter_divs = page.all('div')
  fehb_draft_filter = filter_divs.detect { |div| div.text == 'Draft' && div[:id] == 'Tab:fehb_qles-fehb_draft_qles' }
  fehb_draft_filter.click
end
