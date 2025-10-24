require File.dirname(__FILE__) + '/lib/redmine_stakeholder/hooks'
require File.dirname(__FILE__) + '/lib/redmine_stakeholder/patches/project_patch'

# Register MIME types for exports
Mime::Type.register "application/vnd.ms-excel", :xls unless Mime::Type.lookup_by_extension(:xls)

Redmine::Plugin.register :redmine_stakeholder do
  name 'Redmine Stakeholder Plugin'
  author 'Subi Hung'
  description 'A plugin for managing project stakeholders in Redmine'
  version '0.1.0'
  url 'https://github.com/yourusername/redmine_stakeholder'
  author_url 'https://github.com/yourusername'

  project_module :stakeholders do
    permission :view_stakeholders, { stakeholders: [:index, :show, :analytics, :history] }, public: true
    permission :manage_stakeholders, { stakeholders: [:new, :create, :edit, :update, :destroy, :inline_update] }, require: :member
  end

  menu :project_menu, :stakeholders, { controller: 'stakeholders', action: 'index' },
       caption: :label_stakeholder, after: :activity, param: :project_id
end
