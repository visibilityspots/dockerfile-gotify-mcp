# Gotify MCP

[![trivy](https://github.com/visibilityspots/dockerfile-gotify-mcp/actions/workflows/trivy.yml/badge.svg)](https://github.com/visibilityspots/dockerfile-gotify-mcp/actions/workflows/trivy.yml)
[![docker-hub-description](https://github.com/visibilityspots/dockerfile-gotify-mcp/actions/workflows/docker-hub-description.yml/badge.svg)](https://github.com/visibilityspots/dockerfile-gotify-mcp/actions/workflows/docker-hub-description.yml)
[![build status](https://github.com/visibilityspots/dockerfile-gotify-mcp/actions/workflows/main.yml/badge.svg)](https://github.com/visibilityspots/dockerfile-gotify-mcp/actions/workflows/main.yml)
[![gitHub release](https://img.shields.io/github/v/release/visibilityspots/dockerfile-gotify-mcp)](https://github.com/visibilityspots/dockerfile-gotify-mcp/releases)
[![docker image size](https://img.shields.io/docker/image-size/visibilityspots/gotify-mcp/latest)](https://hub.docker.com/r/visibilityspots/gotify-mcp)
[![docker pulls](https://img.shields.io/docker/pulls/visibilityspots/gotify-mcp.svg)](https://hub.docker.com/r/visibilityspots/gotify-mcp/)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

a read-only [MCP](https://modelcontextprotocol.io) server for a [Gotify](https://gotify.net)
notification server, so an AI agent can read the notifications you receive.

Gotify has no read-only token: a client token can read, delete and manage everything of its
user. This server is the boundary instead. It can only send `GET` requests to three fixed
paths, and its tools return only whitelisted fields, so the application tokens that
`GET /application` returns never reach the model. There is no tool to send, delete or
manage anything.

It is a single Python file on top of the MCP Python SDK, serving streamable HTTP on `/mcp`
behind a bearer token per client, and running as a non-root user.

## run

```
$ TOKEN=$(openssl rand -hex 32)
$ docker run -d --name gotify-mcp -p 8080:8080 \
    -e GOTIFY_URL=https://gotify.example.com \
    -e GOTIFY_CLIENT_TOKEN=<client token> \
    -e MCP_ALLOWED_HOSTS=gotify-mcp.example.com \
    -e MCP_TOKEN_SHA256="claude-code=$(printf %s "$TOKEN" | sha256sum | cut -c1-64)" \
    visibilityspots/gotify-mcp:latest
$ claude mcp add --transport http gotify https://gotify-mcp.example.com/mcp \
    --header "Authorization: Bearer $TOKEN"
```

### Client token

Create a dedicated client in the Gotify web UI (Clients, Create client), so you can revoke
the MCP's access without touching your other clients. It sees the messages of every
application of that user.

The token is sent in the `X-Gotify-Key` header only, never in a URL, so it does not end up
in proxy access logs. Error messages carry the HTTP status, never the URL, headers or
Gotify's response body.

### Authentication

Every request to `/mcp` needs `Authorization: Bearer <token>`. Give each client its own
token, so you can revoke one without touching the others:

```
MCP_TOKEN_SHA256="claude-code=<sha256 hex>,paperclip=<sha256 hex>"
```

The server only gets the SHA-256 hashes, never the tokens themselves. It hashes what a
client presents and compares it with every entry in constant time. A missing or wrong token
gets `401` with `WWW-Authenticate: Bearer realm="gotify-mcp", error="invalid_token"` and a
warning in the log. The log lists the configured client names at startup and never shows a
token or a hash.

Use long random tokens (`openssl rand -hex 32`): a plain SHA-256 is fine for 256 bits of
randomness and wrong for a password. Rotate a token by adding the new hash next to the old
one, switching the client, then removing the old hash.

Without `MCP_TOKEN_SHA256` the server refuses to start. `MCP_AUTH_DISABLED=true` runs it
open, for a network where something else already authenticates every request.

This is static bearer authentication, not the OAuth 2.1 flow the MCP specification
describes for HTTP servers: that needs an authorization server, which this server does not
assume you have. Serve it over HTTPS, since the token travels in every request.

## Tools

| tool | arguments | returns |
|---|---|---|
| `list_messages` | `limit` (1-100, default 20), `app_id`, `before_id`, `after_id`, `min_priority` | messages newest first: `id`, `app_id`, `app`, `date`, `priority`, `title`, `message`, `truncated` |
| `list_applications` | | `id`, `name`, `description` of each application |

- `before_id` pages back in time: pass the previous result's `next_before_id`. Gotify's own
  `since` parameter works this way (ids lower than the value), which the name makes explicit.
- `after_id` keeps only messages newer than the given id, e.g. the highest id seen last time.
  It filters within the fetched page; `more_after: true` means there may be more, so raise
  `limit` or page with `before_id`.
- Message `extras` (click URLs, markdown hints) are dropped, and bodies are cut at
  `GOTIFY_MESSAGE_MAX_CHARS`.

Titles and bodies are written by whatever sends you notifications. The server tells the
client to treat them as data, never as instructions; tell your agent the same.

## Configuration

| variable | default | |
|---|---|---|
| `GOTIFY_URL` | | base url of the Gotify server (required) |
| `GOTIFY_CLIENT_TOKEN` | | Gotify client token (required) |
| `MCP_TOKEN_SHA256` | | comma-separated `<client>=<sha256 hex of its token>` (required, see Authentication) |
| `MCP_AUTH_DISABLED` | `false` | `true` runs `/mcp` without authentication |
| `MCP_ALLOWED_HOSTS` | | comma-separated host names the server answers to, see below |
| `MCP_HOST` | `0.0.0.0` | listen address |
| `MCP_PORT` | `8080` | listen port |
| `GOTIFY_MESSAGE_MAX_CHARS` | `2000` | longer message bodies are truncated |

The MCP SDK protects against DNS rebinding and allows only `localhost` and `127.0.0.1` by
default. Behind a reverse proxy the `Host` header is the public name, and without
`MCP_ALLOWED_HOSTS` every request is answered `421 Misdirected Request`. A name also
matches with any port. `*` turns the protection off.

The server runs stateless (`stateless_http`), so clients keep working after a restart.

## build

```
$ docker build -t visibilityspots/gotify-mcp:latest .
```

### buildx

```
$ docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
$ docker buildx build -t visibilityspots/gotify-mcp:latest --platform linux/amd64,linux/arm64 --push .
```

### dgoss

The tests in goss.yaml run the real entrypoint without a Gotify behind it: they check the
MCP handshake under a proxied `Host` header with the test token, the 401 without a token,
the 421 for any other host and the path guard. The hash in `MCP_TOKEN_SHA256` is the one of
`test-token`, the token goss sends.
`goss_wait.yaml` waits until the port listens:

```
$ dgoss run -e MCP_TOKEN_SHA256=goss=$(printf %s test-token | sha256sum | cut -c1-64) \
    -e MCP_ALLOWED_HOSTS=gotify-mcp.example.com -e GOTIFY_URL=http://127.0.0.1:1 -e GOTIFY_CLIENT_TOKEN=test \
    visibilityspots/gotify-mcp:dev
...
Count: 15, Failed: 0, Skipped: 0
INFO: Deleting container
```

### act

using [act](https://github.com/nektos/act#overview----) for local testing of the written github actions makes my life and commit history a lot easier;

```
Stage  Job ID  Job name  Workflow name           Workflow file               Events
0      update  update    docker-hub-description  docker-hub-description.yml  push
0      main    main      CI                      main.yml                    push,pull_request
0      scan    scan      trivy                   trivy.yml                   workflow_dispatch,push,schedule
```

### release

Images are built and pushed by the shared workflow in
[visibilityspots/github-workflows](https://github.com/visibilityspots/github-workflows) when
a tag is pushed. Pushing to `main` builds nothing; a pull request only builds and runs dgoss.

## License

Distributed under the [MIT license](https://github.com/visibilityspots/dockerfile-gotify-mcp/blob/main/LICENSE)
