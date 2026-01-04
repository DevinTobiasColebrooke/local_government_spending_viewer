require "openai"
class LocalLlmService
  def initialize
    # Connects to your Windows Batch Script server on Port 8080
    @client = OpenAI::Client.new(access_token: "x", uri_base: AiConfig::LOCAL_LLM_URL)
  end

  def chat(prompt, system_message: "You are a helpful assistant.")
    response = @client.chat(
      parameters: {
        model: AiConfig::LOCAL_MODEL_NAME, # Sends "default", server ignores it and uses loaded model
        messages: [
          { role: "system", content: system_message },
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      }
    )
    response.dig("choices", 0, "message", "content")&.strip
  rescue => e
    Rails.logger.error "Local LLM Error: #{e.message}"
    "Error connecting to Windows Local Host. Make sure your Batch script is running."
  end
end
