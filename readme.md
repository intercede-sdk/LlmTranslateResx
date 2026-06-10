# LlmTranslateResx

A tool for translating .resx format resource files containing translation strings into another language.

This calls out to an LLM (that you need to provide) in order to do the translation.

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
If you have previously translated files using this tool for this target language, you should reuse translations from the previous run — this speeds up translation by only retranslating new or changed strings and ensures consistency. To do so, create a subfolder called `previous` and place the previously translated files there before running the script.

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

Two scripts are provided for translating the full set of resx files across the web server installation.

#### Recommended workflow: copy, translate, copy back

This approach keeps translation off the live server and gives you a clean backup before any files are changed.

**Step 1 — Copy source files to a Translate folder (run on the web server)**

Run `CopyResxToTranslateFolder.ps1` on the web server. It copies all source resx files from the known MyID component folders into a `Translate` folder, retaining the original folder hierarchy. This folder acts as both the input for translation and a backup of the originals.

```
.\CopyResxToTranslateFolder.ps1
```

To specify a custom web server root or destination:

```
.\CopyResxToTranslateFolder.ps1 -webServerRoot "C:\Program Files\Intercede\MyID" -destination "C:\MyTranslations"
```

**Step 2 — Move the Translate folder to a Translation PC**

Copy the `Translate` folder to the machine where `LlmTranslateResx.exe` is available (the Translation PC).

If you have previously translated files for this target language, you should reuse them to speed up translation and ensure consistency. Place the previously translated files in a `previous` subfolder within each component folder inside `Translate` (e.g. `Translate\rest.core\Dictionaries\previous\Base.de.resx`) before running the script.

**Step 3 — Translate (run on the Translation PC)**

Run `LlmTranslateWebServerFiles.ps1` against the `Translate` folder:

```
.\LlmTranslateWebServerFiles.ps1 -outputLanguageCode de -webServerRoot ".\Translate" --targetLanguage German --uri https://myOpenAiCompatApi --model gpt-4.1-mini --apiKey myApiKey
```

The script handles two source file naming conventions:

| Source file pattern | Example input   | Example output     |
| ------------------- | --------------- | ------------------ |
| `*.en-US.resx`      | Base.en-US.resx | Base.de.resx       |
| `*.resx` (no code)  | Dictionary.resx | Dictionary.de.resx |

Translated files are written alongside their source file within the `Translate` folder hierarchy.

**Step 4 — Copy translated files back to the web server**

Once you are satisfied with the translations, copy the translated `.resx` files from the `Translate` folder back to their corresponding locations under `C:\Program Files\Intercede\MyID` on the web server.

#### Alternative: run directly on the web server

`LlmTranslateWebServerFiles.ps1` can also be run directly on the web server against the live installation folder, which may be convenient in development environments:

```
.\LlmTranslateWebServerFiles.ps1 -outputLanguageCode de --targetLanguage German --uri https://myOpenAiCompatApi --model gpt-4.1-mini --apiKey myApiKey
```

The default web server root is `C:\Program Files\Intercede\MyID`. Use `-webServerRoot` to override it. Note that translated files are written directly into the live installation folder, so using `CopyResxToTranslateFolder.ps1` first is recommended for production servers.

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

## Sample translations

The `samples/` folder contains German translations of MyID CMS Enterprise resource files for versions v12.6, v12.17 and v12.18, produced using an Azure-hosted GPT-4.1-mini LLM. These can be:

- **Installed directly** onto a matching version of MyID as a ready-made set of German translations.
- **Used as `--previousFile` inputs** when translating a newer version. Where a string has not changed, the existing translation is reused — speeding up translation and improving consistency across versions.

See [samples/readme.md](samples/readme.md) for installation instructions and guidance on using the samples as previous translation files.

## Known Issues

- It has been observed on Azure provisioned OpenAI that some strings can wrongly and unexpectedly trigger the Azure OpenAI "content filter". In failure cases (such as this), the problem entries are reported in the program output and the original source string is used. You may manually correct these afterwards. The content moderation policy in Azure can be set to "Low"
- Real-time progress is not shown in LlmTranslateFilesInDirectory.ps1 or LlmTranslateWebServerFiles.ps1; the text output from LlmTranslateResx is delayed due to interaction when PowerShell calls an executable.
- LLM translations are non-deterministic and will not necessarily produce the same result on each run. Using the `--previousFile` option helps maintain consistency across runs by reusing translations for strings that have not changed.
