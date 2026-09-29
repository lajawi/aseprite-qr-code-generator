# Changelog

## [Unreleased]

### Added

- QR-Code Preview in the creation dialog
	- Updates when the input has changed
	- Updates when the colors have changed

### Changed

- Refactored the code
	- Extracted variables from functions
	- Separate functionality from functions
	- Applied StyLua formatting

## [1.1.0] - 2026.09.23

### Added

- Licenses dialog
- Changelog
- Error correction level setting
	- Setting is only used when `Use Advanced Opions` is enabled

### Changed

- Updated the [Luaqrcode library](https://github.com/speedata/luaqrcode)
- Fore- and background are separated onto two layers
- Dialog must be dismissed before you can interact with the rest of the application again
- Printing licenses is done in a dedicated dialog

### Fixed

- Changed the `dofile()` path to use forward slashes (`/`) instead of backwards slashes (`\\`)

## [1.0.0] - 2025.05.19

### Added

- [Luaqrcode library](https://github.com/speedata/luaqrcode)
- QR-Code generator button

[Unreleased]: https://codeberg.org/lajawi/aseprite-qr-code-generator/compare/v1.1.0...HEAD
[1.1.0]: https://codeberg.org/lajawi/aseprite-qr-code-generator/compare/v1.0.0...v1.1.0
[1.0.0]: https://codeberg.org/lajawi/aseprite-qr-code-generator/releases/tag/v1.0.0
