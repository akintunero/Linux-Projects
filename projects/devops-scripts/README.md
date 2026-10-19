# DevOps scripts

Two real-world scripts that show how to wrap `curl`, `jq` and `docker` safely. Both are meant to be read,
broken and improved.

| Script | Purpose |
|--------|---------|
| [`api-client.sh`](api-client.sh) | REST client: methods, headers, JSON bodies, output formats, response caching |
| [`docker-manager.sh`](docker-manager.sh) | list, start, stop, restart, remove, logs, status, backup and clean up containers |

Requirements: Bash 4.4+, `curl`, `jq` (API client) and `docker` (container manager).

## api-client.sh

```bash
./api-client.sh https://api.github.com/repos/torvalds/linux
./api-client.sh -c -f table https://api.github.com/repos/torvalds/linux   # cached for 5 minutes
./api-client.sh -m POST -d '{"name":"demo"}' https://httpbin.org/post
API_KEY=ghp_xxx ./api-client.sh https://api.github.com/user
```

- Output formats: `pretty` (default), `compact`, `table`, `raw`. Non-JSON responses are printed unchanged.
- The token comes from the `API_KEY` **environment variable** and is sent as a Bearer header. There is no
  `--key` option on purpose: command-line arguments are visible to every user through `ps`.
- Only successful `GET` requests are cached, in `~/.cache/linux-projects/api-client/`.
- Optional settings file `~/.config/linux-projects/api-client.conf` with `TIMEOUT=` and `CACHE_TTL=`
  lines. It is parsed, never `source`d, so it cannot run code.
- Exit codes: `0` ok, `1` HTTP error or usage, `2` invalid input, `4` network failure.

## docker-manager.sh

```bash
./docker-manager.sh list status=exited
./docker-manager.sh --dry-run remove old-api old-worker   # preview first
./docker-manager.sh logs web 200
./docker-manager.sh backup web ./web.tar
./docker-manager.sh cleanup
```

- `--dry-run` prints each `docker` command and runs none of them. `--help` works even when Docker is not
  installed.
- Container names are validated against Docker's own naming rule before use, and no `eval` is involved.
- A failure on one container does not stop the others; the exit status is non-zero if any failed.
- `backup` uses `docker export` (the filesystem only, **not** volumes or running memory state).

## Tests

Both scripts are tested without internet or a real Docker daemon: a throw-away local HTTP server and a
stub `docker` stand in.

```bash
bats ../../tests/api-client.bats ../../tests/docker-manager.bats
```

## Exercises

1. **Easy.** Add `--retries N` to the API client with a one-second back-off.
2. **Medium.** Add `docker-manager.sh stats` showing CPU and memory per container using
   `docker stats --no-stream --format`.
3. **Hard.** Add a `--follow` mode to `logs` and handle `Ctrl+C` cleanly with `trap`.
