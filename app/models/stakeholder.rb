class Stakeholder < ActiveRecord::Base
  belongs_to :project
  has_many :histories, class_name: 'StakeholderHistory', dependent: :destroy

  # Location types (內部/外部)
  LOCATION_TYPES = [
    'internal',   # 內部
    'external'    # 外部
  ].freeze

  # Participation degrees (參與度 - 原影響/態度)
  PARTICIPATION_DEGREES = [
    'completely_unaware',  # 完全不覺
    'resistant',           # 抵制
    'neutral',             # 中立
    'supportive',          # 支持
    'leading'              # 領導
  ].freeze

  # Power levels (權力級別 1-5)
  POWER_LEVELS = [1, 2, 3, 4, 5].freeze

  # Interest levels (關切級別 1-5)
  INTEREST_LEVELS = [1, 2, 3, 4, 5].freeze

  validates :project_id, presence: true
  validates :name, presence: true, length: { maximum: 255 }
  validates :title, length: { maximum: 255 }, allow_blank: true
  validates :location_type, inclusion: { in: LOCATION_TYPES }, allow_blank: true
  validates :project_role, length: { maximum: 255 }, allow_blank: true
  validates :participation_degree, inclusion: { in: PARTICIPATION_DEGREES }, allow_nil: true
  validates :power, inclusion: { in: POWER_LEVELS }, allow_nil: true
  validates :interest, inclusion: { in: INTEREST_LEVELS }, allow_nil: true
  # Security: Validate position field to prevent SQL injection
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  # Security: Validate text fields to prevent injection attacks
  validates :primary_needs, length: { maximum: 2000 }, allow_blank: true
  validates :expectations, length: { maximum: 2000 }, allow_blank: true

  # Callbacks
  before_create :set_project_sequence_number

  # Default scope to order by position
  default_scope { order(:position) }

  def self.location_type_options
    LOCATION_TYPES.map { |type| [I18n.t("stakeholder.location_type.#{type}"), type] }
  end

  def self.participation_degree_options
    PARTICIPATION_DEGREES.map { |degree| [I18n.t("stakeholder.participation_degree.#{degree}"), degree] }
  end

  def self.power_options
    POWER_LEVELS.map { |level| [I18n.t("stakeholder.power_level.#{level}"), level] }
  end

  def self.interest_options
    INTEREST_LEVELS.map { |level| [I18n.t("stakeholder.interest_level.#{level}"), level] }
  end

  def location_type_label
    return '' if location_type.blank?
    I18n.t("stakeholder.location_type.#{location_type}", default: location_type)
  end

  def participation_degree_label
    return '' if participation_degree.blank?
    I18n.t("stakeholder.participation_degree.#{participation_degree}", default: participation_degree)
  end

  def power_label
    return '' if power.blank?
    I18n.t("stakeholder.power_level.#{power}", default: power)
  end

  def interest_label
    return '' if interest.blank?
    I18n.t("stakeholder.interest_level.#{interest}", default: interest)
  end

  # Override human_attribute_name to use custom translation keys
  def self.human_attribute_name(attribute, options = {})
    case attribute.to_s
    when 'location_type'
      I18n.t('field_location_type')
    when 'participation_degree'
      I18n.t('field_participation_degree')
    when 'power'
      I18n.t('field_power')
    when 'interest'
      I18n.t('field_interest')
    else
      super
    end
  end

  # Get formatted sequence number with project identifier
  def formatted_sequence_number
    "#{project.identifier}-#{project_sequence_number}" if project
  end

  private

  # Automatically set project_sequence_number before creating
  def set_project_sequence_number
    return if project_sequence_number.present? && project_sequence_number > 0

    max_sequence = Stakeholder.where(project_id: project_id).maximum(:project_sequence_number) || 0
    self.project_sequence_number = max_sequence + 1
  end
end
