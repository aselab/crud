FactoryGirl.define do
  factory :principal do
    sequence(:name) {|n| "principal#{n}"}
  end

  factory :event do
    sequence(:name) {|n| "event#{n}"}
  end

  factory :permission do
    flags 0b01
  end
end
