## Redmine Stakeholder Plugin

A comprehensive Redmine plugin for managing and analyzing project stakeholders with advanced visualization and export capabilities.

### Features

#### Core Functionality
- **Complete CRUD Operations**: Add, edit, and delete stakeholder records for each project
- **Inline Editing**: Edit stakeholder data directly in the list view with hover-activated pencil icons
- **Change History Tracking**: Comprehensive audit trail of all stakeholder modifications (create, update, delete)
- **Comprehensive Stakeholder Tracking**:
  - Stakeholder name
  - Title
  - Internal/External location type
  - Project role
  - Primary needs
  - Expectations
  - Influence/Attitude level (Completely Unaware / Resistant / Neutral / Supportive / Leading)

#### Data Export
- **CSV Export**: Export all stakeholder data to CSV format with UTF-8 encoding
- **Excel Export**: Export to .xls format (SpreadsheetML) with formatted headers and styling

#### Change History
- **Audit Trail**: Complete record of all stakeholder changes
- **User Tracking**: Track who made each change and when
- **Field Change Details**: See old values and new values for each modification
- **Language Support**: History records display values in the current system language

#### Design and Internationalization
- Fully responsive web design for all devices
- Complete bilingual support (Traditional Chinese / English)
- Integrated as a dedicated tab in project pages
- Permission-based access control (view_stakeholders / manage_stakeholders)

### Installation

1. Copy this plugin to your Redmine `plugins` directory:
   ```bash
   cd /path/to/redmine/plugins
   git clone [repository-url] redmine_stakeholder
   ```

2. Run the plugin migrations:
   ```bash
   bundle exec rake redmine:plugins:migrate NAME=redmine_stakeholder RAILS_ENV=production
   ```

3. Restart Redmine

4. Enable the "Stakeholders" module in your project settings

### Usage

#### Basic Operations
1. Go to your project page
2. Click on the "Stakeholders" tab
3. Add new stakeholders using the "New Stakeholder" button
4. Edit stakeholders by:
   - Clicking the "Edit" button for full editing form
   - OR hovering over a field and clicking the pencil icon for inline editing
5. Delete stakeholders using the "Delete" button

#### Exporting Data
- Click "Export CSV" to download stakeholder data in CSV format
- Click "Export Excel" to download stakeholder data in Excel format (.xls)

#### Viewing Change History
1. Click on "View History" button in the stakeholder list or detail page
2. View all changes made to the stakeholder including:
   - Date and time of change
   - User who made the change
   - Type of change (Create / Modify / Delete)
   - Field that was changed
   - Old value and new value

### Permissions
Two permission levels are available:
- **View stakeholders**: Can view stakeholder lists and change history
- **Manage stakeholders**: Can create, edit, delete stakeholders, and view history

### Technical Details

#### Database Schema
The plugin creates two tables:

**stakeholders table**:
- `project_id` (integer): Reference to the project
- `name` (string): Stakeholder name
- `title` (string): Stakeholder title
- `location_type` (string): Internal or External
- `project_role` (string): Role in the project
- `primary_needs` (text): Stakeholder primary needs
- `expectations` (text): Stakeholder expectations
- `influence_attitude` (string): Influence/Attitude level
- `position` (integer): Display order

**stakeholder_histories table**:
- `stakeholder_id` (integer): Reference to stakeholder
- `user_id` (integer): Reference to user who made the change
- `action` (string): Type of action (create/update/delete)
- `field_name` (string): Field that was changed
- `old_value` (text): Previous value
- `new_value` (text): New value
- `created_at` (datetime): Timestamp of change

#### Technologies Used
- **Backend**: Ruby on Rails, ActiveRecord
- **Frontend**: JavaScript
- **Styling**: Responsive CSS with flexbox and grid layouts
- **Export Formats**: CSV (Ruby CSV library), SpreadsheetML XML for Excel
- **AJAX**: For inline editing functionality

#### File Structure
```
redmine_stakeholder/
├── app/
│   ├── controllers/
│   │   └── stakeholders_controller.rb
│   ├── models/
│   │   ├── stakeholder.rb
│   │   └── stakeholder_history.rb
│   └── views/
│       └── stakeholders/
│           ├── index.html.erb
│           ├── new.html.erb
│           ├── edit.html.erb
│           ├── show.html.erb
│           ├── _form.html.erb
│           └── history.html.erb
├── assets/
│   ├── javascripts/
│   │   └── inline_edit.js
│   └── stylesheets/
│       └── stakeholders.css
├── config/
│   ├── locales/
│   │   ├── en.yml
│   │   └── zh-TW.yml
│   └── routes.rb
├── db/
│   └── migrate/
│       ├── 001_create_stakeholders.rb
│       ├── 002_add_fields_to_stakeholders.rb
│       ├── 003_restructure_stakeholder_fields.rb
│       └── 004_create_stakeholder_histories.rb
├── lib/
│   └── redmine_stakeholder/
│       ├── hooks.rb
│       └── patches/
│           └── project_patch.rb
├── init.rb
└── README.md
```

### Uninstall

```bash
bundle exec rake redmine:plugins:migrate NAME=redmine_stakeholder VERSION=0 RAILS_ENV=production
rm -rf plugins/redmine_stakeholder
```

### License

This plugin is licensed under the MIT license.