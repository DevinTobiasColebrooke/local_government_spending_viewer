module ThemeHelper
  def theme_css_variables
    # In production, cache this. For now, we load it dynamically.
    themes = YAML.load_file(Rails.root.join("config/themes.yml"))
    current_theme = themes["default"] # Or current_user.theme

    css_lines = current_theme.map do |key, value|
      "--theme-#{key}: #{value};"
    end.join(" ")

    ":root { #{css_lines} }".html_safe
  end
end
