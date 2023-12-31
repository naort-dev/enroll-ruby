# frozen_string_literal: true

module L10nHelper
  include ActionView::Helpers::TranslationHelper
  def l10n(translation_key, interpolated_keys = {})
    t(translation_key, interpolated_keys.merge(default: translation_key.gsub(/\W+/, '').titleize)).html_safe
  end
end
