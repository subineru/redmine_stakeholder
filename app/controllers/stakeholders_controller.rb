class StakeholdersController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize
  before_action :find_stakeholder, only: [:show, :edit, :update, :destroy, :inline_update, :history]

  helper :sort
  include SortHelper

  # Security: Whitelist of fields allowed for inline editing
  ALLOWED_INLINE_FIELDS = %w[name title location_type project_role primary_needs expectations participation_degree power interest].freeze

  # Security: Whitelist of fields allowed for dynamic method calls
  ALLOWED_READABLE_FIELDS = %w[name title location_type project_role primary_needs expectations participation_degree power interest
                                project_sequence_number id created_at updated_at].freeze

  def index
    @stakeholders = @project.stakeholders.order(:position)

    respond_to do |format|
      format.html
      format.csv do
        Rails.logger.info("Security: Stakeholders CSV export - Project: #{@project.id}, User: #{User.current.id}, Records: #{@stakeholders.count}")
        send_data stakeholders_to_csv(@stakeholders),
                  type: 'text/csv; charset=utf-8',
                  filename: "stakeholders_#{@project.identifier}_#{Date.today}.csv"
      end
      format.xls do
        Rails.logger.info("Security: Stakeholders XLS export - Project: #{@project.id}, User: #{User.current.id}, Records: #{@stakeholders.count}")
        send_data stakeholders_to_xls(@stakeholders),
                  type: 'application/vnd.ms-excel',
                  filename: "stakeholders_#{@project.identifier}_#{Date.today}.xls"
      end
    end
  end

  def analytics
    @stakeholders = @project.stakeholders

    # Participation degree statistics
    @participation_degree_stats = @stakeholders.group(:participation_degree).count

    # Location type statistics
    @location_type_stats = @stakeholders.group(:location_type).count

    # Total count
    @total_count = @stakeholders.count

    # Participation degree distribution for chart (with stakeholder IDs)
    @participation_degree_data = Stakeholder::PARTICIPATION_DEGREES.map do |degree|
      stakeholder_ids = @stakeholders.where(participation_degree: degree).pluck(:id)
      {
        label: I18n.t("stakeholder.participation_degree.#{degree}", default: degree),
        value: stakeholder_ids.count,
        ids: stakeholder_ids
      }
    end

    # Security: Log analytics access
    Rails.logger.debug("Security: Analytics viewed - Project: #{@project.id}, User: #{User.current.id}, Total stakeholders: #{@total_count}")
  end

  def show
    # Security: Log stakeholder view
    Rails.logger.debug("Security: Stakeholder viewed - ID: #{@stakeholder.id}, Project: #{@project.id}, User: #{User.current.id}")
  end

  def history
    @stakeholder_histories = @stakeholder.histories.ordered
  end

  def new
    @stakeholder = @project.stakeholders.build
  end

  def create
    @stakeholder = @project.stakeholders.build(stakeholder_params)
    if @stakeholder.save
      # Security: Log stakeholder creation
      Rails.logger.info("Security: Stakeholder created - ID: #{@stakeholder.id}, Project: #{@project.id}, User: #{User.current.id}")
      # Record creation in history
      StakeholderHistory.record_create(@stakeholder, User.current)
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_stakeholders_path(@project)
    else
      # Security: Log failed creation attempt
      Rails.logger.warn("Security: Stakeholder creation failed for user #{User.current.id} in project #{@project.id} - Errors: #{@stakeholder.errors.full_messages.join(', ')}")
      render :new
    end
  end

  def edit
  end

  def update
    # Store old values before update
    old_values = @stakeholder.attributes.slice(*stakeholder_params.keys)

    if @stakeholder.update(stakeholder_params)
      # Record update in history if there are changes
      changes_made = {}
      stakeholder_params.each do |field, new_value|
        old_value = old_values[field]
        if old_value != new_value
          changes_made[field] = [old_value, new_value]
        end
      end

      if changes_made.any?
        StakeholderHistory.record_update(@stakeholder, User.current, changes_made)
      end

      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_to project_stakeholders_path(@project)
        end
        format.json do
          render json: {
            success: true,
            formatted_value: format_field_value(params[:field], @stakeholder)
          }
        end
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json do
          # Security: Don't expose internal validation details
          render json: {
            success: false,
            errors: ['Update failed. Please check your input.']
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def inline_update
    # Security: Check authorization
    unless User.current.allowed_to?(:manage_stakeholders, @project)
      Rails.logger.warn("Security: Unauthorized inline_update attempt by user #{User.current.id} on stakeholder #{@stakeholder.id}")
      render json: { success: false, errors: ['Permission denied'] }, status: :forbidden
      return
    end

    # Security: Rate limiting - max 30 requests per minute per user
    rate_limit_key = "inline_update:#{User.current.id}"
    request_count = (Rails.cache.read(rate_limit_key) || 0).to_i
    if request_count >= 30
      Rails.logger.warn("Security: Rate limit exceeded for user #{User.current.id}")
      render json: { success: false, errors: ['Too many requests. Please try again later.'] }, status: :too_many_requests
      return
    end
    Rails.cache.write(rate_limit_key, request_count + 1, expires_in: 1.minute)

    field = params[:field]&.to_s
    value = params[:value]

    # Security: Validate field is in whitelist
    unless ALLOWED_INLINE_FIELDS.include?(field)
      Rails.logger.warn("Security: Invalid field update attempt by user #{User.current.id}: #{field}")
      render json: { success: false, errors: ['Invalid field'] }, status: :forbidden
      return
    end

    # Security: Prevent updates to protected fields
    old_value = @stakeholder.send(field) rescue nil

    if @stakeholder.update(field => value)
      # Record update in history if value changed
      if old_value != value
        StakeholderHistory.record_update(@stakeholder, User.current, { field => [old_value, value] })
      end

      render json: {
        success: true,
        formatted_value: format_field_value(field, @stakeholder)
      }
    else
      # Security: Don't expose internal validation details
      render json: {
        success: false,
        errors: ['Update failed. Please check your input.']
      }, status: :unprocessable_entity
    end
  end

  def destroy
    # Security: Log stakeholder deletion
    stakeholder_id = @stakeholder.id
    project_id = @project.id

    # Record deletion in history before destroying
    StakeholderHistory.record_delete(@stakeholder, User.current)

    @stakeholder.destroy
    Rails.logger.info("Security: Stakeholder deleted - ID: #{stakeholder_id}, Project: #{project_id}, User: #{User.current.id}")
    flash[:notice] = l(:notice_successful_delete)
    redirect_to project_stakeholders_path(@project)
  end

  private

  # Security: Prevent CSV injection attacks
  def sanitize_csv_value(value)
    return value unless value.is_a?(String)

    # Prefix with single quote if value starts with formula characters
    if value.start_with?('=', '+', '-', '@', "\t", "\r")
      "'#{value}"
    else
      value
    end
  end

  def find_stakeholder
    @stakeholder = @project.stakeholders.find(params[:id])
    # Security: Verify stakeholder belongs to the current project (defense in depth)
    unless @stakeholder.project_id == @project.id
      Rails.logger.warn("Security: Potential IDOR attack - stakeholder #{params[:id]} does not belong to project #{@project.id} for user #{User.current.id}")
      render_404
      return
    end
  rescue ActiveRecord::RecordNotFound
    # Log access attempt to non-existent stakeholder (potential enumeration attack)
    Rails.logger.warn("Security: Access attempt to non-existent stakeholder #{params[:id]} in project #{@project.id} by user #{User.current.id}")
    render_404
  end

  def stakeholder_params
    params.require(:stakeholder).permit(
      :name,
      :title,
      :location_type,
      :project_role,
      :primary_needs,
      :expectations,
      :participation_degree,
      :power,
      :interest,
      :position
    )
  end

  def stakeholders_to_csv(stakeholders)
    require 'csv'

    CSV.generate(headers: true, encoding: 'UTF-8') do |csv|
      # CSV Header
      csv << [
        l(:field_id),
        l(:field_stakeholder_name),
        l(:field_title),
        l(:field_location_type),
        l(:field_project_role),
        l(:field_power),
        l(:field_interest),
        l(:field_primary_needs),
        l(:field_expectations),
        l(:field_participation_degree)
      ]

      # CSV Data
      stakeholders.each do |stakeholder|
        csv << [
          stakeholder.project_sequence_number,
          sanitize_csv_value(stakeholder.name),
          sanitize_csv_value(stakeholder.title),
          sanitize_csv_value(stakeholder.location_type_label),
          sanitize_csv_value(stakeholder.project_role),
          stakeholder.power,
          stakeholder.interest,
          sanitize_csv_value(stakeholder.primary_needs),
          sanitize_csv_value(stakeholder.expectations),
          sanitize_csv_value(stakeholder.participation_degree_label)
        ]
      end
    end
  end

  def format_field_value(field, stakeholder)
    # Security: Validate field is in whitelist before using send
    field_str = field.to_s
    unless ALLOWED_READABLE_FIELDS.include?(field_str)
      Rails.logger.warn("Security: Invalid field read attempt: #{field_str}")
      return ''
    end

    case field_str
    when 'location_type'
      return stakeholder.location_type_label
    when 'influence_attitude'
      return stakeholder.influence_attitude_label
    when 'power'
      return stakeholder.power_label
    when 'interest'
      return stakeholder.interest_label
    when 'participation_degree'
      return stakeholder.participation_degree_label
    when 'primary_needs', 'expectations'
      value = stakeholder.public_send(field_str)  # Use public_send instead of send
      return view_context.truncate(value, length: 50) if value.present?
      return ''
    else
      return stakeholder.public_send(field_str) || ''  # Use public_send instead of send
    end
  end

  def stakeholders_to_xls(stakeholders)
    require 'builder'

    xls = Builder::XmlMarkup.new(indent: 2)
    xls.instruct! :xml, version: "1.0", encoding: "UTF-8"

    xls.Workbook(
      'xmlns' => 'urn:schemas-microsoft-com:office:spreadsheet',
      'xmlns:o' => 'urn:schemas-microsoft-com:office:office',
      'xmlns:x' => 'urn:schemas-microsoft-com:office:excel',
      'xmlns:ss' => 'urn:schemas-microsoft-com:office:spreadsheet',
      'xmlns:html' => 'http://www.w3.org/TR/REC-html40'
    ) do
      # Styles
      xls.Styles do
        xls.Style 'ss:ID' => 'header' do
          xls.Font 'ss:Bold' => '1'
          xls.Interior 'ss:Color' => '#CCE5FF', 'ss:Pattern' => 'Solid'
        end
      end

      # Worksheet
      xls.Worksheet 'ss:Name' => 'Stakeholders' do
        xls.Table do
          # Header Row
          xls.Row 'ss:StyleID' => 'header' do
            xls.Cell { xls.Data l(:field_id), 'ss:Type' => 'String' }
            xls.Cell { xls.Data l(:field_stakeholder_name), 'ss:Type' => 'String' }
            xls.Cell { xls.Data l(:field_title), 'ss:Type' => 'String' }
            xls.Cell { xls.Data l(:field_location_type), 'ss:Type' => 'String' }
            xls.Cell { xls.Data l(:field_project_role), 'ss:Type' => 'String' }
            xls.Cell { xls.Data l(:field_power), 'ss:Type' => 'String' }
            xls.Cell { xls.Data l(:field_interest), 'ss:Type' => 'String' }
            xls.Cell { xls.Data l(:field_primary_needs), 'ss:Type' => 'String' }
            xls.Cell { xls.Data l(:field_expectations), 'ss:Type' => 'String' }
            xls.Cell { xls.Data l(:field_participation_degree), 'ss:Type' => 'String' }
          end

          # Data Rows
          stakeholders.each do |stakeholder|
            xls.Row do
              xls.Cell { xls.Data stakeholder.project_sequence_number.to_s, 'ss:Type' => 'Number' }
              xls.Cell { xls.Data stakeholder.name || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.title || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.location_type_label || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.project_role || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.power.to_s || '', 'ss:Type' => 'Number' }
              xls.Cell { xls.Data stakeholder.interest.to_s || '', 'ss:Type' => 'Number' }
              xls.Cell { xls.Data stakeholder.primary_needs || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.expectations || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.participation_degree_label || '', 'ss:Type' => 'String' }
            end
          end
        end
      end
    end

    xls.target!
  end
end
