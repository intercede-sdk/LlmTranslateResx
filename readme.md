# LlmTranslateResx
A tool for translating .resx format resource files containing translation strings into another language
This calls out to an Llm AI (that you need to provide) in order to do the translation

## Usage
Use the --help argument to find all the current options
```
LlmTranslateResx --help
```

Configuration can be achieved by (later items override earlier items)
- changing settings in appsettings.json - some sensible defaults exist here, but you may override them
- overriding those settings in appsettings.production.json
- overriding those settings via commandline arguments

At a minimum, the following need to be set
- input (file)
- output (file)
- targetLanguage (it should be possible to specify a dialect of a language too)
- uri (of the llm). e.g. https://myprovisionedinstance.openai.azure.com
- apiKey (to auth to the llm). Be careful not to share this.
- model (of llm hosted at that uri)

It is common for software that uses resx files to require a separate step (with ResGen.exe) to then .resources file(s) from the .res(x) files. This utility does not perform that step.

## Tailoring translations
- Choose a llm model that works with your intended targetLanguage. 
- You may change the systemPrompt parameter. This lets you change the nature of the instructions used to translate (provides context to the translations). For example, before this prompt told the llm that inventory control was part of the product, it was mistranslating "stock" to mean shares rather than the kind of stock held in inventory.
- You can alter temperature (or topN) in the appsettings (higher temperature means more creative responses)
- You may spot check some results (eg use a llm or search engine to reverse the translation)
- While the default systemPrompt is tailored for the Intercede MyID software, by changing the systemPrompt setting you can use this for any resx file for any software that contains translatable strings where the data/@name attribute is the placeholder the application uses and data/value is the (to be translated) text. The instruction to "translate from language x to language y" is automatically applied at the end of the configured systemPrompt.

This utility is just using the system prompt to tell an llm to translate the given string to a given language

## Choosing an Llm
Any Llm that has an OpenAI compatible API can be used, including
- An Azure provisioned OpenAI
- ChatGPT
- Ollama (locally running model)

Choose a model that is suitable for your needs.
gpt-4.1-mini appears to work reasonable well, but this is not an endorsement of the model.

To predict costs of using hosted llms (which are the responsibility of the person running the tool), there will be a call per string to translate and the content consists of both systemPrompt and the text to translate.

Note that the suitability and accuracy of any translations is down to the model, this tool is merely a conduit.

### Tips for using Azure OpenAI models
- Use Azure portal to create an "Azure OpenAI". This will give you the endpoint (Uri) and an apiKey to use
- Then use the "Explore Azure AI Foundry Portal" option in Azure portal to launch the "Azure AI Foundry". From here you deploy a model (e.g. gpt-4.1-mini) which shows you the model string to configure in the this utility

## Automating the translation of many resx files
It is advisable to test a single file first to ensure you are happy with the result.
A script LlmTranslateAllFiles.ps1 is provider that will iterate all resx files in the directory, enabling a single command to translate all resx files

Usage:
The following example creates filename-de.resx files containing German translations of all resx files in the input directory, connecting to the llm identified in the arguments:
```
LlmTranslateAllFiles -outputLanguageCode de --targetLanguage German --uri https://myOpenAiCompatApi --model gpt-4.1-mini --apiKey myApiKey
```
The following files in a directory are then created
| OriginalFile | NewFile |
| ------------ | ------- |
| Base.en-US.resx | Base.de.resx |
| ErrorCodes.en-US.resx | ErrorCodes.de.resx |
| etc...       |         |

## Known Issues
- It has been observed on Azure provisioned OpenAI that some strings can wrongly and unexpectedly trigger the Azure OpenAI "profanity filter". In failure cases (such as this), the problem entries are reported in the program output and the original source string is used. You may manually correct these afterwards.
- Realtime progress is not shown in LlmTranslateAllFiles.ps1, the text output from LlmTranslateResx is delayed due to interaction when powershell calls an executable
