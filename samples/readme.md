# Translation Samples

This folder contains sample German (de) translations of MyID CMS Enterprise resource files, produced using an Azure-hosted GPT-4.1-mini LLM. They are provided as a reference and as a starting point for generating translations for newer versions of MyID CMS Enterprise.

| Folder       | MyID CMS Enterprise Version |
| ------------ | --------------------------- |
| MyID-12.6/   | v12.6                       |
| MyID-12.17/  | v12.17                      |
| MyID-12.18/  | v12.18                      |
| MyID-2026.1/ | v2026.1                     |

Each folder mirrors the folder structure found on the MyID CMS Enterprise web server under `C:\Program Files\Intercede\MyID`, and contains both the English source (`.en-US.resx`) and translated German (`.de.resx`) files.

## Installing sample translations onto a MyID CMS Enterprise web server

1. Copy the contents of the relevant version folder (e.g. `MyID-12.18/`) into `C:\Program Files\Intercede\MyID` on the web server. The folder structure matches, so the files will land in the correct locations.
2. For each component folder, run `Makedictionaries.bat` if it is present. This compiles the `.resx` files into `.resources` files that the application can load.
3. For the `rest.core`, `rest.provision` and `web.oauth2` components, add `"de"` as an entry in the `SupportedLanguages` array under the `Localization` section of each component's `appsettings.json`.
4. Run `iisreset` to ensure the web server picks up the new resources.
5. Set the OS or browser language to German so that the server returns the German translations.

## Using samples as previous translation files

The sample files can be used as `--previousFile` inputs when translating a newer version of MyID CMS Enterprise. Where a string has not changed between versions, the existing translation will be reused rather than re-translated. This speeds up translation and improves consistency.

### Using with LlmTranslateWebServerFiles.ps1 (recommended)

Follow the [workflow described in the main readme](../readme.md#translating-all-resx-files-on-the-web-server). When preparing the `Translate` folder in Step 1, also copy the sample files for the closest previous version into a `previous` subfolder inside each component folder. For example:

```
Translate\
  rest.core\
	Dictionaries\
	  Base.en-US.resx          <- source file to translate
	  previous\
		Base.de.resx            <- previous translation from samples\MyID-12.18 (MyID CMS Enterprise v12.18)
```

`LlmTranslateWebServerFiles.ps1` automatically picks up files in `previous\` subfolders.

To create this `previous` folder structure automatically, run `CopyPreviousTranslationsFromSample.ps1`, pointing it at the closest previous version's sample folder and your prepared `Translate` folder:

```
.\CopyPreviousTranslationsFromSample.ps1 -sampleFolder .\samples\MyID-12.18 -destination .\Translate
```

By default this copies every German (`de`) sample translation into the matching `previous\` subfolder. Add `-onlyWhereSourceExists` to create previous files only where a matching source file exists in the destination, or use `-outputLanguageCode` to select a different language.

### Using with LlmTranslateFilesInDirectory.ps1

Copy the sample translated files for the closest previous version into a `previous` subfolder within the directory you are translating, then run `LlmTranslateFilesInDirectory.ps1` as normal.

## Notes

- These translations were produced by an LLM and have not been professionally reviewed. Spot-checking is recommended before deployment to production.
- The samples cover German only. They can be used as a template for understanding the file structure when preparing to translate into other languages.
- Using a more recent sample version as `--previousFile` input will yield better results than an older one, as fewer strings will have changed.
