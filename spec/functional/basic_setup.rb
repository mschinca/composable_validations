shared_context 'basic setup' do
  let(:valid_data) do
    {
      "store" => {
        "name"        => "Scrutton Street",
        "description" => "large store",
        "opening_hours" => {
          "monday"   => {"from" =>  9, "to" => 17},
          "tuesday"  => {"from" =>  9, "to" => 17},
          "wednesday"=> {"from" =>  9, "to" => 17},
          "thursday" => {"from" =>  9, "to" => 17},
          "friday"   => {"from" =>  9, "to" => 17},
          "saturday" => {"from" => 10, "to" => 16}
        },
        "employees"=> ["bob", "alice"]
      }
    }
  end

  let(:validator) do
    a_hash(
      allowed_keys("store"),
      key("store",
        a_hash(
          allowed_keys("name", "description", "opening_hours", "employees"),
          key("name", non_empty_string),
          optional_key("description"),
          key("opening_hours",
            a_hash(
              allowed_keys("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"),
              optional_key("monday",    from_to),
              optional_key("tuesday",   from_to),
              optional_key("wednesday", from_to),
              optional_key("thursday",  from_to),
              optional_key("friday",    from_to),
              optional_key("saturday",  from_to),
              optional_key("sunday",    from_to)
            )
          ),
          key("employees", array(each(non_empty_string)))
        )
      )
    )
  end

  let(:from_to) do
    a_hash(
      allowed_keys("from", "to"),
      fail_fast(
        run_all(
          key("from", hour),
          key("to", hour)
        ),
        key_greater_than_key("to", "from")
      )
    )
  end

  let(:hour) do
    fail_fast(non_negative_integer, less_or_equal(24))
  end
end

