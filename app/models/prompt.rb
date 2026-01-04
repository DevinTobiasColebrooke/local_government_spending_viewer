class Prompt
  # Simple wrapper to fetch prompts
  # Usage: Prompt.get('system.data_analyst')
  def self.get(key, **args)
    prompts = YAML.load_file(Rails.root.join("config/prompts.yml"))
    template = prompts.dig(*key.split("."))

    return "Prompt key '#{key}' not found" unless template

    if args.any?
      template % args
    else
      template
    end
  rescue KeyError
    "Missing arguments for prompt '#{key}'"
  end
end
