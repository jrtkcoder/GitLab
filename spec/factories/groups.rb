FactoryGirl.define do
  factory :group do
    sequence(:name) { |n| "group#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    type 'Group'

    trait :public do
      visibility_level Gitlab::VisibilityLevel::PUBLIC
    end

    trait :internal do
      visibility_level Gitlab::VisibilityLevel::INTERNAL
    end

    trait :private do
      visibility_level Gitlab::VisibilityLevel::PRIVATE
    end

    trait :access_requestable do
      request_access_enabled true
    end

    trait :nested do
      parent factory: :group
    end
  end
end
