FactoryBot.define do
  factory :user do
    sequence(:email) {|n| "example#{n}@example.com"}
    sequence(:oim_id) {|n| "example#{n}"}
    gen_pass = User.generate_valid_password
    password { gen_pass }
    password_confirmation { gen_pass }
    sequence(:authentication_token) {|n| "j#{n}-#{n}DwiJY4XwSnmywdMW"}
    approved { true }
    roles { ['web_service'] }
  end

  trait :with_hbx_staff_role do
    roles { ["hbx_staff"] }
  end

  trait "csr" do
    roles { ["csr"] }
  end

  trait "broker" do
    roles { ["broker"] }
  end

  trait "general" do
    roles { ["general"] }
  end

  trait :with_consumer_role do
    after :create do |user|
      FactoryBot.create :person, :with_consumer_role, :with_family, :with_active_consumer_role, :user => user
    end
  end
end
