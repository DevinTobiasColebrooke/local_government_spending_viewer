# AI & Data Services

## Configuration
Check `config/initializers/ai_config.rb` for settings regarding IP detection (WSL/Windows) and API keys.

## AI Providers
- **Local Llama**: Use `LocalLlmService`. Connects to Windows host on port 8080. See `config/initializers/ai_config.rb`.

## Vector Database
- **Model**: `Document` (content, embedding, metadata).
- **Usage**: `Document.semantic_search("query")`.
- **Embeddings**: Auto-generated via `EmbeddingService`.

## Prompt Management
- Edit prompts in `config/prompts.yml`.
- Access via `Prompt.get('key')`.

