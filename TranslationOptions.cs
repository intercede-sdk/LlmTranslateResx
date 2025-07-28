namespace LlmTranslateResx
{
    public class LlmOptions
    {
        public string? uri { get; set; }
        public string? apiKey { get; set; }
        public string? model { get; set; }
    }

    public class TranslationOptions
    {
        public string? input { get; set; }
        public string? output { get; set; }
        public LlmOptions? llm { get; set; }
        public string? targetLanguage { get; set; }
        public string? sourceLanguage { get; set; }
        public string? systemPrompt { get; set; }
    }
}
