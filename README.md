# HoYoShadeHub.Assets

A nuget package for HoYoShade-Hub.

## Included

- **Logo**: application logo (`Assets/logo.png`)
- **Fonts**: MiSans font (`Assets/Fonts/MiSans VF.ttf`)
- **Icons/Backgrounds**: other UI icons and background resources

## Usage

Add the package reference in your project file (`.csproj`):

```xml
<PackageReference Include="HoYoShadeHub.Assets" Version="1.0.0" />
```

Resource files will be automatically copied to the `Assets` folder in the output directory.

## XAML references

```xaml
<!-- Logo -->
<Image Source="ms-appx:///Assets/logo.png" />

<!-- Font -->
<FontFamily>ms-appx:///Assets/Fonts/MiSans VF.ttf#MiSans VF</FontFamily>
```

## Version History

### 1.0.0 (2025-12-25)
- Initial release
- Includes custom logo
- Includes MiSans font
- Includes default UI icons and background resources

## License

MIT License

## Project Home

Project page: https://github.com/HoYoShade-Dev/HoYoShadeHub.Assets

Repository that references this remote source: https://github.com/DuolaD/HoYoShade-Hub