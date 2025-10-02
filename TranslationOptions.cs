namespace LlmTranslateResx
{
    public class LlmOptions
    {
        public string? uri { get; set; }
        public string? apiKey { get; set; }
        public string? model { get; set; }

        /// <summary>
        /// Set to true if using Azure OpenAI, or false for other providers (eg ollama)
        /// </summary>
        public bool? azure { get; set; }
    }

    public class TranslationOptions
    {
        public string? input { get; set; }
        public string? output { get; set; }
        public LlmOptions? llm { get; set; }
        public string? targetLanguage { get; set; }
        public string? sourceLanguage { get; set; }
        public string? systemPrompt { get; set; }

        /// <summary>
        /// https://learn.microsoft.com/en-us/java/api/com.azure.ai.openai.models.chatcompletionsoptions
        /// optional (higher temp means more creative response)
        /// </summary>
        public float? temparature { get; set; }

        /// <summary>
        /// https://learn.microsoft.com/en-us/java/api/com.azure.ai.openai.models.chatcompletionsoptions
        /// optional (alternative way of controlling temperature). Is not recommended to set both topP and temperature together
        /// </summary>
        public float? topP { get; set; }

        /// <summary>
        /// optionally specify max output tokens
        /// </summary>
        public int? maxOutputTokenCount { get; set; }
    }
}
