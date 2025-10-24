class StakeholderHistory < ActiveRecord::Base
  # 關聯
  belongs_to :stakeholder
  belongs_to :user

  # 驗證
  validates :stakeholder_id, presence: true
  validates :user_id, presence: true
  validates :action, presence: true, inclusion: { in: %w(create update delete) }

  # 常數
  ACTIONS = {
    'create' => '新增',
    'update' => '修改',
    'delete' => '刪除'
  }.freeze

  # 作用域
  scope :ordered, -> { order(created_at: :desc) }
  scope :by_stakeholder, ->(stakeholder_id) { where(stakeholder_id: stakeholder_id).ordered }
  scope :recent, ->(days = 30) { where('created_at >= ?', days.days.ago).ordered }

  # 方法：獲取操作描述
  def action_label
    I18n.t("stakeholder_history.action.#{action}", default: action)
  end

  # 方法：獲取欄位顯示名稱
  def field_label
    return nil if field_name.blank?
    I18n.t("field_#{field_name}", default: field_name)
  end

  # 方法：獲取用戶名稱
  def user_name
    user&.name || "Unknown User (ID: #{user_id})"
  end

  # 方法：判斷是否為更新操作
  def update_action?
    action == 'update'
  end

  # 方法：判斷是否為創建操作
  def create_action?
    action == 'create'
  end

  # 方法：判斷是否為刪除操作
  def delete_action?
    action == 'delete'
  end

  # 類方法：記錄創建
  def self.record_create(stakeholder, user)
    create(
      stakeholder_id: stakeholder.id,
      user_id: user.id,
      action: 'create'
    )
  end

  # 類方法：記錄修改
  def self.record_update(stakeholder, user, changes)
    changes.each do |field, (old_value, new_value)|
      # Convert values to display labels for certain fields
      display_old_value = convert_value_to_label(field, old_value)
      display_new_value = convert_value_to_label(field, new_value)

      create(
        stakeholder_id: stakeholder.id,
        user_id: user.id,
        action: 'update',
        field_name: field,
        old_value: display_old_value,
        new_value: display_new_value
      )
    end
  end

  # 私有類方法：轉換值為顯示標籤
  def self.convert_value_to_label(field, value)
    return value.to_s if value.blank?

    case field.to_s
    when 'location_type'
      # 轉換 internal/external 為中文標籤
      Stakeholder::LOCATION_TYPES.include?(value.to_s) ?
        I18n.t("stakeholder.location_type.#{value}", default: value.to_s) :
        value.to_s
    when 'influence_attitude'
      # 轉換影響態度代碼為中文標籤
      Stakeholder::INFLUENCE_ATTITUDES.include?(value.to_s) ?
        I18n.t("stakeholder.influence_attitude.#{value}", default: value.to_s) :
        value.to_s
    else
      value.to_s
    end
  end
  private_class_method :convert_value_to_label

  # 類方法：記錄刪除
  def self.record_delete(stakeholder, user)
    create(
      stakeholder_id: stakeholder.id,
      user_id: user.id,
      action: 'delete'
    )
  end
end
