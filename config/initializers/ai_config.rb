# config/initializers/ai_config.rb
module AiConfig
# Detect Windows Host IP from WSL
def self.detect_host_ip
  return "localhost" unless File.exist?("/proc/version") && File.read("/proc/version").include?("Microsoft")
  ip = `grep nameserver /etc/resolv.conf | awk '{print $2}'`.strip
  ip.empty? ? "localhost" : ip
end

# 1. Try to use the IP passed from the Batch script (fastest/safest)
# 2. Fallback to auto-detection inside WSL
WINDOWS_HOST = ENV.fetch("WINDOWS_HOST_IP") { detect_host_ip }

# Configuration matches your Windows Batch Script ports
LOCAL_LLM_URL = "http://#{WINDOWS_HOST}:8080"       # Instruct Server
LOCAL_EMBEDDING_URL = "http://#{WINDOWS_HOST}:8081" # Embeddings Server

# We use a generic name here. Since your Batch script handles the actual .gguf loading,
# Rails doesn't need to know the specific filename. Llama-server will accept 'default'.
LOCAL_MODEL_NAME = "default"
end
