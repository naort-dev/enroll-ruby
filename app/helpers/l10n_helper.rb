module L10nHelper
  def l10n(translation_key, interpolated_keys={})
    t(translation_key, interpolated_keys.merge(default: translation_key.gsub(/\W+/, '').titleize)).html_safe
  end
end
