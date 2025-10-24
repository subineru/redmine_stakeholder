module RedmineStakeholder
  class Hooks < Redmine::Hook::ViewListener
    # This hook allows us to add content to project pages
    # The stakeholder tab is already added via the menu in init.rb
    # Additional hooks can be added here if needed for custom rendering

    def view_layouts_base_html_head(context={})
      output = ""

      # Get the plugin directory - use the actual plugin path
      plugin_dir = File.expand_path(File.dirname(__FILE__) + '/../..')

      # Load stylesheets using direct file paths
      # Note: matrix stylesheet is no longer used since matrix view was removed
      stylesheets = %w(stakeholders inline_edit)
      stylesheets.each do |stylesheet|
        path = File.join(plugin_dir, 'assets', 'stylesheets', "#{stylesheet}.css")
        if File.exist?(path)
          content = File.read(path)
          output << "<style type=\"text/css\">\n#{content}\n</style>\n"
        end
      end

      # Load Chart.js from CDN
      output << "<script src=\"https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js\"></script>\n"

      # Load inline_edit script
      path = File.join(plugin_dir, 'assets', 'javascripts', 'inline_edit.js')
      if File.exist?(path)
        content = File.read(path)
        output << "<script type=\"text/javascript\">\n#{content}\n</script>\n"
      end

      output.html_safe
    end
  end
end
