class Stakeholder < ActiveRecord::Base
  belongs_to :project
  has_many :histories, class_name: 'StakeholderHistory', dependent: :destroy

  # Location types (內部/外部)
  LOCATION_TYPES = [
    'internal',   # 內部
    'external'    # 外部
  ].freeze

  # Influence attitudes (影響/態度)
  INFLUENCE_ATTITUDES = [
    'completely_unaware',  # 完全不覺
    'resistant',           # 抵制
    'neutral',             # 中立
    'supportive',          # 支持
    'leading'              # 領導
  ].freeze

  validates :project_id, presence: true
  validates :name, presence: true, length: { maximum: 255 }
  validates :title, length: { maximum: 255 }, allow_blank: true
  validates :location_type, length: { maximum: 50 }, allow_blank: true
  validates :project_role, length: { maximum: 255 }, allow_blank: true
  validates :influence_attitude, inclusion: { in: INFLUENCE_ATTITUDES }, allow_nil: true

  # Default scope to order by position
  default_scope { order(:position) }

  def self.location_type_options
    LOCATION_TYPES.map { |type| [I18n.t("stakeholder.location_type.#{type}"), type] }
  end

  def self.influence_attitude_options
    INFLUENCE_ATTITUDES.map { |attitude| [I18n.t("stakeholder.influence_attitude.#{attitude}"), attitude] }
  end

  def location_type_label
    return '' if location_type.blank?
    I18n.t("stakeholder.location_type.#{location_type}", default: location_type)
  end

  def influence_attitude_label
    return '' if influence_attitude.blank?
    I18n.t("stakeholder.influence_attitude.#{influence_attitude}", default: influence_attitude)
  end

  # Override human_attribute_name to use custom translation keys
  def self.human_attribute_name(attribute, options = {})
    case attribute.to_s
    when 'location_type'
      I18n.t('field_location_type')
    when 'influence_attitude'
      I18n.t('field_influence_attitude')
    else
      super
    end
  end
end
