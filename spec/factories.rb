FactoryGirl.define do
  factory :ar_user, class: "Ar::User" do
    last_name "test"
    sequence(:first_name) {|n| "user#{n}"}
  end

  factory :ar_group, class: "Ar::Group" do
    sequence(:name) {|n| "group#{n}"}
  end

  factory :ar_permission, class: "Ar::Permission"

  factory :mongo_user, class: "Mongo::User" do
    last_name "test"
    sequence(:first_name) {|n| "user#{n}"}
  end

  factory :mongo_group, class: "Mongo::Group" do
    sequence(:name) {|n| "group#{n}"}
  end

  factory :mongo_permission, class: "Mongo::Permission"

  factory :csv_item do
    sequence(:string) {|n| "string#{n}"}
    sequence(:integer) {|n| n}
    sequence(:boolean) {|n| n % 2 == 0}
    sequence(:date) {|n| n.days.ago}
    sequence(:datetime) {|n| n.days.ago}
  end
end
