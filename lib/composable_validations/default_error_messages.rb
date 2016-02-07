ComposableValidations::Errors::DEFAULT_MESSAGE_MAP = {
  non_empty_string:            "can't be blank",
  non_empty:                   "can't be empty",
  allowed_keys:                "is not allowed",
  presence_of_key:             "can't be blank",
  just_hash:                   "must be a hash",
  just_array:                  "must be an array",
  string:                      "must be a string",
  integer:                     "must be an integer",
  stringy_integer:             "must be an integer",
  float:                       "must be a number",
  stringy_float:               "must be a number",
  non_negative:                "must be greater than or equal to 0",
  format:                      "is invalid",
  time_string:                 "must be a time",
  date_string:                 lambda { |object, path, format| "must be a date in format #{format}" },
  at_least_one_of:             lambda { |object, path, keys| "at least one of #{keys.join(', ')} is required" },
  key_greater_or_equal_to_key: lambda { |object, path, key1, key2| "must be greater than or equal to #{key2}" },
  key_greater_than_key:        lambda { |object, path, key1, key2| "must be greater than #{key2}" },
  key_less_or_equal_to_key:    lambda { |object, path, key1, key2| "must be less than or equal to #{key2}" },
  key_less_than_key:           lambda { |object, path, key1, key2| "must be less than #{key2}" },
  key_equal_to_key:            lambda { |object, path, key1, key2| "must be equal to #{key2}" },
  greater_or_equal:            lambda { |object, path, val| "must be greater than or equal to #{val}" },
  greater:                     lambda { |object, path, val| "must be greater than #{val}" },
  less_or_equal:               lambda { |object, path, val| "must be less than or equal to #{val}" },
  less:                        lambda { |object, path, val| "must be less than #{val}" },
  equal:                       lambda { |object, path, val| "must be equal to #{val}" },
  min_size:                    lambda { |object, path, n| "is too short (minium size is #{n})" },
  max_size:                    lambda { |object, path, n| "is too long (maximum size is #{n})" },
  exact_size:                  lambda { |object, path, n| "is the wrong size (should be #{n})" },
  size_range:                  lambda { |object, path, range| "is the wrong size (minimum is #{range.min} and maximum is #{range.max})" },
  in_range:                    lambda { |object, path, range| "must be in range #{range.min}..#{range.max}" },
  inclusion:                   lambda do |object, path, options|
    if options.length > 10
      "is not allowed"
    else
      "must be one of: #{options.join(', ')}"
    end
  end
}
