# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.2.0] - 2026-11-26
### :boom: BREAKING CHANGES
- due to [`6c3cb6d`](https://github.com/visibilityspots/dockerfile-gotify-mcp/commit/6c3cb6d458514c0e3c2559a7b956329f31dcb5ef) - require a bearer token per client on /mcp *(commit by [@visibilityspots](https://github.com/visibilityspots))*:

  the server refuses to start without MCP_TOKEN_SHA256.  
  Set MCP_AUTH_DISABLED=true to keep running without authentication.


### :sparkles: New Features
- [`6c3cb6d`](https://github.com/visibilityspots/dockerfile-gotify-mcp/commit/6c3cb6d458514c0e3c2559a7b956329f31dcb5ef) - require a bearer token per client on /mcp *(commit by [@visibilityspots](https://github.com/visibilityspots))*


## [v0.1.1] - 2026-11-26
### :construction_worker: Build System
- [`336766c`](https://github.com/visibilityspots/dockerfile-gotify-mcp/commit/336766c816be70540eb8d4757d9e0817b41525ad) - **deps**: bump python from 3.13.18-alpine3.24 to 3.15.2-alpine3.24 *(commit by [@dependabot[bot]](https://github.com/apps/dependabot))*


## [v0.1.0] - 2026-11-26
### :sparkles: New Features
- [`545bf05`](https://github.com/visibilityspots/dockerfile-gotify-mcp/commit/545bf05dea91f7515121d6fdbd5b6fe63c4bdb85) - read-only MCP server for Gotify notifications *(commit by [@visibilityspots](https://github.com/visibilityspots))*

[v0.1.0]: https://github.com/visibilityspots/dockerfile-gotify-mcp/compare/c8c157eca9bda090880f8b42e4c97f587a1d87ed...v0.1.0
[v0.1.1]: https://github.com/visibilityspots/dockerfile-gotify-mcp/compare/v0.1.0...v0.1.1
[v0.2.0]: https://github.com/visibilityspots/dockerfile-gotify-mcp/compare/v0.1.1...v0.2.0
