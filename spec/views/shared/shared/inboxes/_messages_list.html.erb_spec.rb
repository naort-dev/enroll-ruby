require 'rails_helper'

describe "shared/inboxes/_message_list.html.erb", db_clean: :after_each do
  let(:shared_message_properties) do
     {
      :from => "somebody",
      :folder => "Inbox",
      :message_read => false
     }
    end

  let(:message_1) { instance_double(Message, {:id => "11111", :created_at=>Time.find_zone('Eastern Time (US & Canada)').local(2016,1,10)}.merge(shared_message_properties)) }
  let(:message_2) { instance_double(Message, {:id => "22222", :created_at=>Time.find_zone('Eastern Time (US & Canada)').local(2016,11,1)}.merge(shared_message_properties)) }
  let(:mock_inbox) { instance_double(Inbox, {:messages => [message_1, message_2], :unread_messages => [message_1, message_2]}) }
  let(:mock_provider) { instance_double(EmployerProfile,{:id => "12345", :model_name => EmployerProfile, :inbox => mock_inbox} ) }
  before :each do
    allow(view).to receive(:policy_helper).and_return(double("PersonPolicy", updateable?: true))
    render "shared/inboxes/message_list.html.erb",  :folder => "Sent", :sent_box => true,:provider => mock_provider
  end

  it "should have text From" do
    expect(rendered).to have_content("From")
  end
  it "should not have text FROM" do
    expect(rendered).to_not have_content("FROM")
  end
  it "should not have text Inbox: FROM" do
    expect(rendered).to_not have_content("Inbox: FROM")
  end

  it "should have the latest message listed first" do
    expect(rendered).to have_selector(:xpath, "//tr[@class=\"msg-inbox-unread\"][1]/td[2]", :text => "11/01/2016")
  end

  it "should have the older message listed last" do
    expect(rendered).to have_selector(:xpath, "//tr[@class=\"msg-inbox-unread\"][2]/td[2]", :text => "01/10/2016")
  end
end
