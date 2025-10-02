using Azure.AI.OpenAI;
using LlmTranslateResx;
using Microsoft.Extensions.Configuration;
using OpenAI.Chat;
using System.ClientModel;
using System.CommandLine;
using System.ComponentModel.Design;
using System.Resources.NetStandard;

class Program
{
    static async Task Main(string[] args)
    {
        var inputOption = new Option<string?>("--input") { Description = "Input filename (e.g. Base.en-US.resx)" };
        var outputOption = new Option<string?>("--output") { Description = "Output filename to create (e.g. Base.de.resx)" };
        var targetLanguageOption = new Option<string?>("--targetLanguage") { Description = "Language to translate to (e.g. German)" };
        var uriOption = new Option<string?>("--uri") { Description = "Uri of the Llm (must have an OpenAI compatible API, can use uris for Azure OpenAI, ChatGPT, Ollama etc)" };
        var apiKeyOption = new Option<string?>("--apiKey") { Description = "Api key to connect to the Llm" };
        var modelOption = new Option<string?>("--model") { Description = "Model of Llm (e.g. gpt-4.1-mini). Must be provisioned at the uri" };
        var azure = new Option<bool?>("--azure") { Description = "Set to true if using Azure OpenAI, or false for other providers (eg ollama)" };

        var rootCommand = new RootCommand("Uses an Llm to create translated dictionary entries in a resx file. Additional options may be set in the appsettings file, the options in commandline will take precedence if provided")
        {
            inputOption,
            outputOption,
            targetLanguageOption,
            uriOption,
            apiKeyOption,
            modelOption,
            azure,
        };
        
        rootCommand.SetAction(async parseResult => {
            await DoTranslations(parseResult.GetValue(inputOption), parseResult.GetValue(outputOption), parseResult.GetValue(targetLanguageOption), parseResult.GetValue(uriOption), parseResult.GetValue(apiKeyOption), parseResult.GetValue(modelOption), parseResult.GetValue(azure));
        });
        new CommandLineConfiguration(rootCommand).Invoke(args);
    }

    static async Task DoTranslations(string? input, string? output, string? targetLanguage, string? uri, string? apiKey, string? model, bool? azure)
    {
        var config = new ConfigurationBuilder()
                .SetBasePath(AppContext.BaseDirectory)
                .AddJsonFile("appsettings.json", optional: false)
                .AddJsonFile("appsettings.production.json", optional: true)
                .Build();

        var options = config.GetSection("config").Get<TranslationOptions>();

        input = input ?? options.input ?? throw new Exception("input not specified");
        output = output ?? options.output ?? throw new Exception("output not specified");
        targetLanguage = targetLanguage ?? options?.targetLanguage ?? throw new Exception("targetLanguage not specified");

        Console.WriteLine($"Translating {input} to {targetLanguage}\n");
        ConnectToAI(uri ?? options?.llm?.uri, apiKey ?? options?.llm?.apiKey, model ?? options?.llm?.model, azure ?? options.llm?.azure ?? true);

        // read resource entries
        var resourceEntries = new List<ResXDataNode>();
        using (ResXResourceReader reader = new ResXResourceReader(input))
        {
            reader.UseResXDataNodes = true;
            var readerEnumerator = reader.GetEnumerator();
            while (readerEnumerator.MoveNext())
            {
                resourceEntries.Add((ResXDataNode)readerEnumerator.Value);
            }
        }

        // translate each entry
        var translatedEntries = new List<ResXDataNode>();
        int errors = 0;
        int progress = 0;
        foreach (var entry in resourceEntries)
        {
            ++progress;
            Console.Write(".");

            string? value = entry.GetValue((ITypeResolutionService)null).ToString();
            try
            {
                string translated = string.IsNullOrEmpty(value) ? string.Empty : await Translate(value, targetLanguage, options.sourceLanguage ?? "English", options.systemPrompt ?? throw new Exception("System Prompt must be present in appsettings"), options.temparature, options.topP, options.maxOutputTokenCount);
                var newEntry = new ResXDataNode(entry.Name, translated);
                newEntry.Comment = value; // Comment will have the original text (allows for comparison later to tell which translations may want retranslation in future)
                translatedEntries.Add(newEntry);
            }
            catch(Exception e)
            {
                Console.WriteLine($"\nError translating entry {progress}, key: {entry.Name}, value: {value}\n{e.Message}\n");
                // untranslated text is kept if a translation was not made - these can be manually translated if needed
                var newEntry = new ResXDataNode(entry.Name, value);
                newEntry.Comment = $"***TRANSLATION ERROR***: {value}"; // mark in comment that we could not translate this
                translatedEntries.Add(newEntry);

                errors++;
            }
        }

        // write new resource file with translated entries
        using (ResXResourceWriter writer = new ResXResourceWriter(output))
        {
            foreach (var translatedEntry in translatedEntries)
            {
                writer.AddResource(translatedEntry);
            }
        }

        Console.WriteLine($"\nTranslation completed {input} translated to {targetLanguage}, creating file {output}. Number of translations={progress}, {errors} Errors(s)");
    }

    private static async Task<string> Translate(string dataToTranslate, string targetLanguage, string sourceLanguage, string systemPrompt, float? temperature, float? topP, int? maxTokens)
    {
        var options = new ChatCompletionOptions();
        if (temperature != null)
        {
            options.Temperature = temperature;
        }
        if (topP != null)
        {
            options.TopP = topP;
        }
        if (maxTokens != null)
        {
            options.MaxOutputTokenCount = maxTokens;
        }

        ChatCompletion completion = await CompleteChat(systemPrompt, sourceLanguage, targetLanguage, dataToTranslate, options);

        if (completion.Content.Count == 0)
        {
            // give it one more go. some OpenAI APIs seem to not return content sometimes
            completion = await CompleteChat(systemPrompt, sourceLanguage, targetLanguage, dataToTranslate, options);
            if (completion.Content.Count == 0)
                throw new Exception("No content returned from OpenAI API");
        }
        return completion.Content[0].Text;
    }

    private static async Task<ChatCompletion> CompleteChat(string systemPrompt, string sourceLanguage, string targetLanguage, string dataToTranslate, ChatCompletionOptions options)
    {
        return await chatClient.CompleteChatAsync(
        [
            // System messages represent instructions or other guidance about how the assistant should behave
            new SystemChatMessage($"{systemPrompt}. When you are given a string you must translate it from {sourceLanguage} to {targetLanguage}. The string may contain placeholders beginning with %, leave these intact. Do not output any explanations or notes, only output the translated string. Translate the following: "),
            new UserChatMessage(dataToTranslate),
        ],
        options);
    }

    private static void ConnectToAI(string uri, string apiKey, string model, bool azure)
    {
        if (azure)
        {
            azureOpenAIClient = new(
                new Uri(uri),
                new ApiKeyCredential(apiKey));

            // works for openai, not for ollama
            chatClient = azureOpenAIClient.GetChatClient(model);
        }
        else
        {
            // works for ollama, not for Azure
            chatClient = new ChatClient(
                model: model,
                credential: new ApiKeyCredential(apiKey),
                new OpenAI.OpenAIClientOptions
                {
                    Endpoint = new Uri(uri)
                }
            );
        }
    }

    private static AzureOpenAIClient azureOpenAIClient;
    private static ChatClient chatClient;
}