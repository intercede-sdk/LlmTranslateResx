# LlmTranslateResx

A tool for translating .resx format resource files containing translation strings into another language
This calls out to an LLM (that you need to provide) in order to do the translation

## Usage

Use the --help argument to find all the current options

```
LlmTranslateResx --help
```

Configuration can be achieved by (later items override earlier items)

- changing settings in appsettings.json - some sensible defaults exist here, but you may override them
- overriding those settings in appsettings.production.json
- overriding those settings via command-line arguments

At a minimum, the following need to be set

- input (file)
- output (file)
- targetLanguage (it should be possible to specify a dialect of a language too)
- uri (of the LLM). e.g. https://myprovisionedinstance.openai.azure.com
- apiKey (to auth to the LLM). Be careful not to share this.
- model (of LLM hosted at that uri)

Optional args:

- azure (true if it is an azure hosted model, otherwise false. If this is set incorrectly you may get HTTP 404 errors)
- previousFile (file). You can supply the file from a previous translation run (e.g., of an older version).

It is common for software that uses resx files to require a separate step (with ResGen.exe) to generate .resources file(s) from the .res(x) files.

## Tailoring translations

- Choose an LLM model that works with your intended targetLanguage.
- You may change the systemPrompt parameter. This lets you change the nature of the instructions used to translate (provides context to the translations). For example, before this prompt told the LLM that inventory control was part of the product, it was mistranslating "stock" to mean shares rather than the kind of stock held in inventory.
- You can alter temperature (or topN) in the appsettings (higher temperature means more creative responses)
- You may spot-check some results (e.g., use an LLM or search engine to reverse the translation)
- While the default systemPrompt is tailored for the Intercede MyID software, by changing the systemPrompt setting you can use this for any resx file for any software that contains translatable strings where the data/@name attribute is the placeholder the application uses and data/value is the (to be translated) text. The instruction to "translate from language x to language y" is automatically applied at the end of the configured systemPrompt.

This utility is just using the system prompt to tell an LLM to translate the given string to a given language.

## Choosing an LLM

Any LLM that has an OpenAI-compatible API can be used, including

- An Azure provisioned OpenAI
- ChatGPT
- Ollama (locally running model)

Choose a model that is suitable for your needs.
gpt-4.1-mini appears to work reasonably well, but this is not an endorsement of the model.

To predict costs of using hosted LLMs (which are the responsibility of the person running the tool), there will be a call per string to translate and the content consists of both systemPrompt and the text to translate.

Note that the suitability and accuracy of any translations is down to the model; this tool is merely a conduit.

### Tips for using Azure OpenAI models

- Use the Azure portal to create an "Azure OpenAI". This will give you the endpoint (URI) and an apiKey to use.
- Then use the "Explore Azure AI Foundry Portal" option in the Azure portal to launch the "Azure AI Foundry". From here you deploy a model (e.g. gpt-4.1-mini) which shows you the model string to configure in this utility.

### Tips for using OpenAI models directly

- Use the `--uri` parameter to specify the OpenAI API endpoint (e.g. `https://api.openai.com/v1`)
- Use the `--azure false` argument to disable Azure mode

### Tips for using local (ollama) models

- By default, the `--uri` parameter is `http://localhost:11434/v1`
- Use the argument `--azure false`

## Automating the translation of many resx files

It is advisable to test a single file first to ensure you are happy with the result.

### Translating all resx files in a directory

A script LlmTranslateFilesInDirectory.ps1 is provided that will iterate all resx files in a directory, enabling a single command to translate all resx files.
If you want to reuse previous translation files if available, create a subfolder called "previous" and put the previous file in that folder.

Usage:
The following example creates filename-de.resx files containing German translations of all resx files in the input directory, connecting to the LLM identified in the arguments:

```
.\LlmTranslateFilesInDirectory.ps1 -outputLanguageCode de --targetLanguage German --uri https://myOpenAiCompatApi --model gpt-4.1-mini --apiKey myApiKey
```

The following files in a directory are then created

| OriginalFile          | NewFile            |
| --------------------- | ------------------ |
| Base.en-US.resx       | Base.de.resx       |
| ErrorCodes.en-US.resx | ErrorCodes.de.resx |
| etc...                |                    |

### Translating all resx files on the web server

A script `LlmTranslateWebServerFiles.ps1` is provided that will recursively iterate all resx files across the full folder structure of the web server deployment, enabling a single command to translate all resx files regardless of their depth in the hierarchy.

The default web server root is `C:\Program Files\Intercede\MyID`, which can be overridden with the `-webServerRoot` parameter.

If you want to reuse previous translations where possible, place the existing translated file in a `previous` subfolder within the same directory as the source file (e.g. `rest.core\Dictionaries\previous\Base.de.resx`).

Usage:
The following example creates German translations of all resx files under the web server root:

```
.\LlmTranslateWebServerFiles.ps1 -outputLanguageCode de --targetLanguage German --uri https://myOpenAiCompatApi --model gpt-4.1-mini --apiKey myApiKey
```

To target a different installation path:

```
.\LlmTranslateWebServerFiles.ps1 -outputLanguageCode de -webServerRoot "D:\MyID" --targetLanguage German --uri https://myOpenAiCompatApi --model gpt-4.1-mini --apiKey myApiKey
```

The script handles two source file naming conventions found in the folder structure:

| Source file pattern | Example input     | Example output  |
| ------------------- | ----------------- | --------------- |
| `*.en-US.resx`      | Base.en-US.resx   | Base.de.resx    |
| `*.resx` (no code)  | Dictionary.resx   | Dictionary.de.resx |

Translated files are written to the same directory as their source file.

The folder structure to be iterated is as follows:

```
C:\Program Files\Intercede\MyID\
├── rest.core/
│   └── Dictionaries/
│       ├── Base.en-US.resx
│       ├── CoreForms.en-US.resx
│       ├── CustomerTerms.en-US.resx
│       ├── ErrorCodes.en-US.resx
│       ├── Languages.en-US.resx
│       ├── MIReports.en-US.resx
│       ├── MobileClient.en-US.resx
│       ├── OperatorClient.en-US.resx
│       ├── OtherClient.en-US.resx
│       ├── ProductTerms.en-US.resx
│       └── ProjectDesigner.en-US.resx
├── rest.provision/
│   └── Dictionaries/
│       └── Base.en-US.resx
├── SSP/
│   ├── MyIDDataSource/
│   │   └── Language/
│   │       ├── Master.EN-US.resx
│   │       ├── PivOverlay.EN-US.resx
│   │       ├── V10.6Overlay.EN-US.resx
│   │       └── V9Overlay.EN-US.resx
│   └── MyIDProcessDriver/
│       └── Language/
│           ├── Master.EN-US.resx
│           ├── PivOverlay.EN-US.resx
│           ├── V10.6Overlay.EN-US.resx
│           └── V9Overlay.EN-US.resx
├── SSRP/
│   ├── SSRP/
│   │   └── App_GlobalResources/
│   │       └── Dictionary.resx
│   ├── SSRPOID/
│   │   └── App_GlobalResources/
│   │       └── Dictionary.resx
│   ├── Start/
│   │   └── App_GlobalResources/
│   │       └── Dictionary.resx
│   └── StartPage/
│       └── App_GlobalResources/
│           └── StartPage.resx
└── web.oauth2/
    └── Dictionaries/
        ├── Base.en-US.resx
        ├── CustomerTerms.en-US.resx
        └── ErrorCodes.en-US.resx
```

## Known Issues

- It has been observed on Azure provisioned OpenAI that some strings can wrongly and unexpectedly trigger the Azure OpenAI "content filter". In failure cases (such as this), the problem entries are reported in the program output and the original source string is used. You may manually correct these afterwards. The content moderation policy in Azure can be set to "Low"
- Real-time progress is not shown in LlmTranslateFilesInDirectory.ps1 or LlmTranslateWebServerFiles.ps1, the text output from LlmTranslateResx is delayed due to interaction when PowerShell calls an executable.
