
When(/^the user clicks Change FEIN link in the Actions dropdown for ABC Widgets Employer$/) do
  sleep(3)
  find_all('.dropdown.pull-right', text: 'Actions')[0].click
  click_link('Change FEIN')
end

And(/^the user enters FEIN with less than nine digits$/) do
  accept_alert do
    find('#organizations_general_organization_new_fein').set("89-42312")
    # Submit already within the alert block
    page.find_button('Submit').click
  end
end

And(/^the user clicks submit button$/) do
  # Needed accept confirm vs alert
  accept_confirm do
    page.find_button('Submit').click
  end
end

Then(/^an warning message will be presented as FEIN must be at least nine digits$/) do
  expect(page).to have_content('FEIN must be at least 9 digits')
end

And(/^the user enters FEIN matches an existing Employer Profile FEIN$/) do
  find('#organizations_general_organization_new_fein').set(employer("Xfinity Enterprise")[:fein])
end

Then(/^an warning message will be presented as FEIN matches HBX ID Legal Name$/) do
  expect(page).to have_content("FEIN matches HBX ID #{employer("Xfinity Enterprise")[:hbx_id]}, #{employer("Xfinity Enterprise")[:legal_name]}")
end

And(/^the user enters unique FEIN with nine digits$/) do
  find('#organizations_general_organization_new_fein').set("123456789")
end

Then(/^an success message will be presented as FEIN Update Successful$/) do
  expect(page).to have_content('FEIN Update Successful')
end
