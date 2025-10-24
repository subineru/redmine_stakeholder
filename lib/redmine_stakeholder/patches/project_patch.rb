module RedmineStakeholder
  module Patches
    module ProjectPatch
      def self.included(base)
        base.class_eval do
          has_many :stakeholders, dependent: :destroy
        end
      end
    end
  end
end

unless Project.included_modules.include?(RedmineStakeholder::Patches::ProjectPatch)
  Project.include(RedmineStakeholder::Patches::ProjectPatch)
end
