# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.3.0] - 2017-08-30
### Added
- {RT:447896} `resolve` function to resolve hostname to IP addresses list.


## [0.2.8] - 2017-08-21
### Changed
- Updated `IOWLib::Pkg_Ensure` type.
- Updated type aliases tests. w00h00!!


## [0.2.7] - 2017-07-25
### Changed
- Updated `IOWLib::Filename` type.


## [0.2.6] - 2017-07-21
### Added
- `IOWLib::Filename` type (needs further improvement).


## [0.2.5] - 2017-07-11
### Added
- Added `latest` to `IOWLib::Pkg_Ensure` type (thanks @alovtsov for reporting).


## [0.2.4] - 2017-07-06
### Changed
- `to_json()` now skips over keys which have `nil` (or `undef` in Puppet terms) values.


## [0.2.3] - 2017-07-05
### Fixed
- All `ensure_*` functions now return strings instead of symbols.


## [0.2.2] - 2017-07-05
### Added
- `ensure_present()` function to convert Boolean value to `present` or `absent`.
- Custom indent can be specified for `to_yaml()` function.

### Fixed
- More readable `to_json()` signatures.


## [0.2.1] - 2017-06-08
### Added
- `to_json()` function.
- `to_yaml()` function.


## [0.2.0] - 2017-05-25
### Added
- `IOWLib::Puppet::Path` type.

### Changed
- `IOWLib::Source_Path` renamed to `IOWLib::Puppet::Source_Path`.

### Removed
- Cron types.


## [0.1.1] - 2017-05-22
### Added
- `IOWLib::Source_Path` type.


## [0.1.0] - 2017-05-17
### Added
- `ensure_file()`, `ensure_link()` functions.
- `IOWLib::Ensure`, `IOWLib::File_Mode`, `IOWLib::Pkg_Ensure` types.


## [0.0.3] - 2017-05-12
### Added
- `ensure_directory()` function.


## [0.0.2] - 2017-05-11
### Added
- Copied over cron types.


## [0.0.1] - 2017-05-06
### Added
- `IOWLib::Hostname` type.
