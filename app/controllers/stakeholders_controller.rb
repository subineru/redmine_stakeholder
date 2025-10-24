class StakeholdersController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize
  before_action :find_stakeholder, only: [:show, :edit, :update, :destroy, :inline_update, :history]

  helper :sort
  include SortHelper

  def index
    @stakeholders = @project.stakeholders.order(:position)

    respond_to do |format|
      format.html
      format.csv do
        send_data stakeholders_to_csv(@stakeholders),
                  type: 'text/csv; charset=utf-8',
                  filename: "stakeholders_#{@project.identifier}_#{Date.today}.csv"
      end
      format.xls do
        send_data stakeholders_to_xls(@stakeholders),
                  type: 'application/vnd.ms-excel',
                  filename: "stakeholders_#{@project.identifier}_#{Date.today}.xls"
      end
    end
  end

  def analytics
    @stakeholders = @project.stakeholders

    # Influence attitude statistics
    @influence_attitude_stats = @stakeholders.group(:influence_attitude).count

    # Location type statistics
    @location_type_stats = @stakeholders.group(:location_type).count

    # Total count
    @total_count = @stakeholders.count

    # Influence attitude distribution for chart
    @influence_attitude_data = Stakeholder::INFLUENCE_ATTITUDES.map do |attitude|
      {
        label: I18n.t("stakeholder.influence_attitude.#{attitude}", default: attitude),
        value: @influence_attitude_stats[attitude] || 0
      }
    end
  end

  def show
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
      # Record creation in history
      StakeholderHistory.record_create(@stakeholder, User.current)
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_stakeholders_path(@project)
    else
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
            value: @stakeholder.send(params[:field]),
            formatted_value: format_field_value(params[:field], @stakeholder)
          }
        end
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json do
          render json: {
            success: false,
            errors: @stakeholder.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def inline_update
    field = params[:field]
    value = params[:value]
    old_value = @stakeholder.send(field)

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
      render json: {
        success: false,
        errors: @stakeholder.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    # Record deletion in history before destroying
    StakeholderHistory.record_delete(@stakeholder, User.current)

    @stakeholder.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to project_stakeholders_path(@project)
  end

  private

  def find_stakeholder
    @stakeholder = @project.stakeholders.find(params[:id])
  rescue ActiveRecord::RecordNotFound
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
      :influence_attitude,
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
        l(:field_primary_needs),
        l(:field_expectations),
        l(:field_influence_attitude)
      ]

      # CSV Data
      stakeholders.each do |stakeholder|
        csv << [
          stakeholder.id,
          stakeholder.name,
          stakeholder.title,
          stakeholder.location_type_label,
          stakeholder.project_role,
          stakeholder.primary_needs,
          stakeholder.expectations,
          stakeholder.influence_attitude_label
        ]
      end
    end
  end

  def format_field_value(field, stakeholder)
    case field.to_s
    when 'location_type'
      return stakeholder.location_type_label
    when 'influence_attitude'
      return stakeholder.influence_attitude_label
    when 'primary_needs', 'expectations'
      return view_context.truncate(stakeholder.send(field), length: 50) if stakeholder.send(field).present?
      return ''
    else
      return stakeholder.send(field) || ''
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
            xls.Cell { xls.Data l(:field_primary_needs), 'ss:Type' => 'String' }
            xls.Cell { xls.Data l(:field_expectations), 'ss:Type' => 'String' }
            xls.Cell { xls.Data l(:field_influence_attitude), 'ss:Type' => 'String' }
          end

          # Data Rows
          stakeholders.each do |stakeholder|
            xls.Row do
              xls.Cell { xls.Data stakeholder.id.to_s, 'ss:Type' => 'Number' }
              xls.Cell { xls.Data stakeholder.name || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.title || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.location_type_label || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.project_role || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.primary_needs || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.expectations || '', 'ss:Type' => 'String' }
              xls.Cell { xls.Data stakeholder.influence_attitude_label || '', 'ss:Type' => 'String' }
            end
          end
        end
      end
    end

    xls.target!
  end
end
