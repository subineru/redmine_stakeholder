module StakeholdersHelper
  def support_level_badge(support_level)
    return '' if support_level.blank?

    badge_class = case support_level
                  when 'strong_support'
                    'success'
                  when 'support'
                    'info'
                  when 'neutral'
                    'secondary'
                  when 'oppose'
                    'warning'
                  when 'strong_oppose'
                    'danger'
                  else
                    'secondary'
                  end

    content_tag(:span,
                I18n.t("stakeholder.support_level.#{support_level}", default: support_level),
                class: "badge badge-#{badge_class}")
  end
end
