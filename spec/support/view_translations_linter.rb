# frozen_string_literal: true

# The following class is can be used in RSpecs, Rake Tasks, etc. to lint different view files for untranslated strings.
# Currently supports linting for untranslated strings WITHIN ERB tags and OUTSIDE of ERB tags
# Class is initialized with three params:
# Stringified View Files- a hash of key value pairs - with the key as the linted filename
# and the value as a string to be linted, such as a whole file OR the changed git lines
# Approved Translation Strings - an array of approved strings to ignore, best kept in YML
# Filter Type - Denoting which query you'd like to lint the file for. Currently supported are
# 'in_erb' and 'outside_erb'
class ViewTranslationsLinter
  attr_accessor :filter_type, :puts_output, :stringified_view_files, :approved_translation_strings

  def initialize(stringified_view_files, approved_translation_strings, filter_type)
    @stringified_view_files = stringified_view_files
    @approved_translation_strings = approved_translation_strings
    @filter_type = filter_type
  end

  def all_translations_present?
    return true if stringified_view_files.blank?
    views_with_errors = {}
    stringified_view_files.each do |filename, stringified_view|
      if unapproved_strings_in_view(stringified_view).present?
        views_with_errors[filename] = unapproved_strings_in_view(stringified_view)
      end
    end
    untranslated_warning_message(views_with_errors) if views_with_errors.present?
    return false if views_with_errors.present?
    true
  end

  def unapproved_strings_in_view(stringified_view)
    non_approved_substrings = []
    potential_substrings(stringified_view).each do |substring|
      # Use match 
      non_approved_substring = approved_translation_strings.detect { |approved_substring| approved_substring.match(substring.downcase) }
      non_approved_substrings << substring if non_approved_substring.blank?
    end
    non_approved_substrings
  end

  def potential_substrings(stringified_view)
    case filter_type
    # Other queries for parsing files can be added here
    # when 'in_slim'
    # when 'outside_slim'
    when 'in_erb'
      # The following method will return all code between ERB tags.
      # Since this will return *all* code between ERB tags,
      # Suggested strings to add to approved list:
      # HTML Elements and helper methods not containing text, such as "render"
      # Methods for dates or currency amounts, such as "hired_on", or "current_year"
      # Record Identifiers such as, "model_name_id"
      potential_substrings_between_erb_tags = stringified_view.scan(/<%=(.*)%>/).flatten
      # REmove special characters
      potential_substrings_no_special_characters = potential_substrings_between_erb_tags.map { |substring| substring.gsub!(/[^0-9a-z ]/i, '') }
      # Remove leading and ending whitespace and downcase
      potential_substrings = potential_substrings_no_special_characters.map { |substring| substring.strip }.map(&:downcase)
    when 'outside_erb'
      # The following filter will take the full read HTML.erb file and:
      # Return a string without all HTML/ERB Tags
      # Remove the \n+ (from beginning of git diff lines)
      # Turn the string into an array, separated at each new line
      # Remove any blank strings from the array
      # Remove any blank space from left and right of array elements
      # Remove blank space to the left and right of sentences
      # Cut the array down to only the uniq elements
      # Remove any elements that don't have a length greater than 1
      # Remove any array elements which are all special characters (I.E. "!", ":")
      # removes leading and ending extra blankspace, and blank strings, and downcase, returning an array like:
      # ["list all attributes", "success"]
      #  Further reading: https://stackoverflow.com/a/54405741/5331859
      potential_substrings_no_html_tags = ActionView::Base.full_sanitizer.sanitize(stringified_view).split("\n+")
      potential_substrings_words_only = potential_substrings_no_html_tags.reject!(&:blank?).map(&:strip).uniq.select { |element| element.length > 1 }.map do |string|
        # Remove special characters from strings. This will also act to remove any single special character strings hanging around like "-"
        string.gsub!(/[^0-9a-z ]/i, '')
      end
      # Remove any blank strings (after the gsub removed special characters) and Downcase to simplify adding to the allow list
      potential_substrings = potential_substrings_words_only.reject!(&:blank?).map(&:downcase)
    end
    return [] if potential_substrings.blank?
    potential_substrings
  end

  def untranslated_warning_message(views_with_errors)
    views_with_errors.each do |filename, unapproved_substrings|
      puts("The following are potentially untranslated substrings missing #{filter_type.upcase} from #{filename}: #{unapproved_substrings.join(', ')}")
    end
    puts("Please modify your ERB and place them in translation helper tags with a coorelating translation or add them to the approved string list.")
  end
end
