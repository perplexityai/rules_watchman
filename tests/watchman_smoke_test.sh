#!/usr/bin/env bash

set -euo pipefail

watchman="${1:?watchman binary path is required}"
tmp_dir="$(mktemp -d /tmp/wm.XXXXXX)"
root="$tmp_dir/root"
socket="$tmp_dir/watchman.sock"
statefile="$tmp_dir/state"
pidfile="$tmp_dir/pid"
logfile="$tmp_dir/watchman.log"
server_pid=""

mkdir "$root"
root="$(cd "$root" && pwd -P)"

client=(
  "$watchman"
  "--unix-listener-path=$socket"
  "--statefile=$statefile"
  "--pidfile=$pidfile"
  "--logfile=$logfile"
  --no-spawn
  --no-pretty
)

cleanup() {
  local status=$?
  trap - EXIT INT TERM

  if [[ -n "$server_pid" ]] && kill -0 "$server_pid" 2>/dev/null; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi

  if [[ $status -ne 0 && -f "$logfile" ]]; then
    cat "$logfile" >&2
  fi

  rm -rf "$tmp_dir"
  exit "$status"
}
trap cleanup EXIT INT TERM

"$watchman" --version >/dev/null

"$watchman" \
  --foreground \
  "--unix-listener-path=$socket" \
  "--statefile=$statefile" \
  "--pidfile=$pidfile" \
  "--logfile=$logfile" &
server_pid=$!

for _ in {1..100}; do
  [[ -S "$socket" ]] && break
  if ! kill -0 "$server_pid" 2>/dev/null; then
    wait "$server_pid" 2>/dev/null || true
    echo "watchman server exited before creating its socket" >&2
    exit 1
  fi
  sleep 0.1
done
[[ -S "$socket" ]]

watch_response="$("${client[@]}" watch "$root")"
[[ "$watch_response" == *'"watcher":'* ]]

kill "$server_pid"
wait "$server_pid" 2>/dev/null || true
server_pid=""

printf 'watchman started its filesystem watcher with %s\n' "$watch_response"
