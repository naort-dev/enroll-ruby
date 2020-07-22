# frozen_string_literal: true

module Validators
  module QualifyingLifeEventKind
    class QlekContract < ::Dry::Validation::Contract

      params do
        required(:start_on).filled(:date)
        optional(:end_on).maybe(:date)
        required(:title).filled(:string)
        optional(:tool_tip).maybe(:string)
        required(:pre_event_sep_in_days).filled(:integer)
        required(:is_self_attested).filled(:bool)
        required(:reason).filled(:string)
        required(:post_event_sep_in_days).filled(:integer)
        required(:market_kind).filled(:string)
        required(:effective_on_kinds).array(:string)
        optional(:ordinal_position).filled(:integer)
        optional(:other_reason).maybe(:string)
        optional(:_id).maybe(:string)
        optional(:coverage_effective_on).maybe(:date)
        optional(:coverage_end_on).maybe(:date)
        required(:event_kind_label).filled(:string)
        required(:is_visible).filled(:bool)
        optional(:termination_on_kinds).maybe(:array)
        required(:date_options_available).filled(:bool)

        before(:value_coercer) do |result|
          result_hash = result.to_h
          other_params = {}
          other_params[:ordinal_position] = 0 if result_hash[:ordinal_position].nil?
          other_params[:reason] = result_hash[:other_reason] if result_hash[:reason] == 'other'
          other_params[:reason] = (other_params[:reason] ? other_params : result_hash)[:reason].parameterize.underscore
          other_params[:termination_on_kinds] = [] if result_hash[:market_kind].to_s == 'individual' && result_hash[:termination_on_kinds].nil?
          result_hash.merge(other_params)
        end
      end

      rule(:end_on, :start_on) do
        if values[:end_on].present?
          key.failure('must be a date') unless values[:end_on].is_a?(Date)
          key.failure('End on must be after start on date') if values[:end_on].is_a?(Date) && values[:end_on] < values[:start_on]
        end
      end

      rule(:pre_event_sep_in_days) do
        key.failure('Invalid Pre Event SEP( In Days )') unless value >= 0
      end

      rule(:reason) do
        reasons = ::QualifyingLifeEventKind.by_market_kind(values[:market_kind]).active_by_state.pluck(:reason).uniq
        key.failure('sep type object exists with same reason') if reasons.include?(value)
      end

      rule(:post_event_sep_in_days) do
        key.failure('Invalid Post Event SEP( In Days )') unless value >= 0
      end

      rule(:market_kind) do
        key.failure('Invalid Market Kind') unless ::QualifyingLifeEventKind::MARKET_KINDS.include?(value)
      end

      rule(:effective_on_kinds) do
        effective_on_kinds_by_market = case values[:market_kind]
                                       when 'shop'
                                         ::QualifyingLifeEventKind::SHOP_EFFECTIVE_ON_KINDS
                                       when 'individual'
                                         ::QualifyingLifeEventKind::IVL_EFFECTIVE_ON_KINDS
                                       when 'fehb'
                                         ::QualifyingLifeEventKind::FEHB_EFFECTIVE_ON_KINDS
                                       end

        key.failure('one of the selected values is invalid') if value.any? {|each_kind| !effective_on_kinds_by_market.include?(each_kind)}
      end

      rule(:ordinal_position) do
        key.failure('Invalid Ordinal Position') unless value >= 0
      end

      rule(:coverage_effective_on) do
        if values[:coverage_effective_on].present?
          key.failure('must be a date') unless values[:coverage_effective_on].is_a?(Date)
        end
      end

      rule(:coverage_end_on) do
        if values[:coverage_end_on].present?
          key.failure('must be a date') unless values[:coverage_end_on].is_a?(Date)
        end
      end

      rule(:termination_on_kinds) do
        key.failure('must be selected') if values[:market_kind] != 'individual' && values[:termination_on_kinds].blank?

        if values[:termination_on_kinds].present?
          key.failure('contents must be a strings') if values[:termination_on_kinds].any? {|ele| !ele.is_a?(String)}
        end
      end
    end
  end
end
