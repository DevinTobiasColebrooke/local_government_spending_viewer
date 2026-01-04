class EnrichSpendingReportJob < ApplicationJob
  queue_as :default

  # Prevent multiple attempts on AI timeout to avoid server load
  discard_on StandardError do |job, error|
    Rails.logger.error "AI Enrichment failed for report #{job.arguments.first.id}: #{error.message}"
  end

  def perform(report)
    # 1. Generate Vector Embedding
    # This calls the local embedding server (port 8081)
    embedding = EmbeddingService.generate(report.description)

    # 2. Get AI Category
    # This calls the local LLM server (port 8080)
    llm = LocalLlmService.new
    system_prompt = Prompt.get("system.categorizer")
    user_prompt = Prompt.get("user.categorize_expense", description: report.description)

    # chat returns the raw string content (e.g. "Supplies")
    ai_category = llm.chat(user_prompt, system_message: system_prompt)

    # 3. Update Record
    updates = {}
    updates[:embedding] = embedding if embedding.present?
    updates[:category] = ai_category if ai_category.present?

    report.update!(updates) if updates.any?
  end
end
