FactoryGirl.define do
  factory :user do
    sequence(:name) {|n| "user#{n}"}
  end

  factory :group do
    sequence(:name) {|n| "group#{n}"}
  end

  factory :permission do
    flags 0b01
  end

  factory :mongo_user do
    sequence(:name) {|n| "user#{n}"}
  end

  factory :mongo_group do
    sequence(:name) {|n| "group#{n}"}
  end

  factory :csv_item do
    sequence(:string) {|n| "string#{n}"}
    sequence(:integer) {|n| n}
    sequence(:boolean) {|n| n % 2 == 0}
    sequence(:date) {|n| n.days.ago}
    sequence(:datetime) {|n| n.days.ago}
  end
end
