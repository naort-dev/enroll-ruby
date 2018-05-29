BenefitSponsors::Engine.routes.draw do
  resources :sites

  namespace :profiles do
    resources :registrations do
      collection do
        get :show_pending
      end
    end


    namespace :broker_agencies do
      resources :broker_agency_profiles, only: [:new, :create, :show, :index, :edit, :update] do
        collection do
          get :family_index
          get :messages
          get :staff_index
          get :agency_messages
          get :commission_statements
        end
        member do
          post :clear_assign_for_employer
          get :assign
          post :update_assign
          post :family_datatable
          get :inbox
          get :download_commission_statement
          get :show_commission_statement
        end
      end
      resources :broker_applicants
    end

    namespace :employers do
      resources :employer_profiles, only: [:show] do
        get :export_census_employees
        post :bulk_employee_upload
        get :premium_statements
        collection do
          get :show_pending
        end
        member do
          get :inbox
        end

        resources :broker_agency, only: [:index, :show, :create] do
          collection do
            get :active_broker
          end
          get :terminate
        end
      end

      resources :employer_staff_roles do
        member do
          get :approve
        end
      end
    end
  end

  namespace :inboxes do
    resources :messages, only: [:show, :destroy] do
      get :msg_to_portal
    end
  end

  namespace :organizations do
    resource :office_locations do
      member do
        get :new
      end
    end
  end

  resources :benefit_sponsorships do
    resources :benefit_applications, controller: "benefit_applications/benefit_applications" do
      post 'revert'
      post 'submit_application'
      post 'force_submit_application'

      resources :benefit_packages, controller: "benefit_packages/benefit_packages" do
        resources :sponsored_benefits, only: :new
      end
    end
  end
end
