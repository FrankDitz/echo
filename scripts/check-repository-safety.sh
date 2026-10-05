#!/bin/sh

set -eu

repository_root=$(git rev-parse --show-toplevel)
cd "$repository_root"

path_list=$(mktemp "${TMPDIR:-/tmp}/echo-paths.XXXXXX")
trap 'rm -f "$path_list"' EXIT HUP INT TERM

private_path_pattern='(^|/)(LocalData|UserData|JournalData|PrivateData|RuntimeData|UserContent|JournalMedia|Recordings|Backups|Exports)(/|$)|(^|/)(\.env($|\.)|Secrets\.xcconfig$|[^/]+\.secrets\.xcconfig$|credentials?(\.[^/]*)?\.json$|service-account[^/]*\.json$|GoogleService-Info\.plist$|AuthKey_[^/]+\.p8$)|\.(sqlite|sqlite-(shm|wal)|db|db-(shm|wal)|store|store-(shm|wal)|journal|backup|echobackup|p8|p12|pem|key|cer|mobileprovision|provisionprofile)$'
private_media_pattern='\.(heic|jpe?g|png|gif|tiff?|mov|mp4|m4v|m4a|wav|caf|aac)$'
credential_pattern='(sk-(proj-)?[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[0-9A-Za-z-]{10,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----)'
assignment_pattern="(api[_-]?key|access[_-]?token|client[_-]?secret|password)[[:space:]]*[:=][[:space:]]*[\"']?[A-Za-z0-9_+./=-]{16,}"

failure=0

check_paths() {
  label=$1

  blocked_paths=$(grep -Ei "$private_path_pattern" "$path_list" || true)
  if [ -n "$blocked_paths" ]; then
    printf '%s\n' "Repository safety check failed: private runtime or credential files are present in $label:" >&2
    printf '%s\n' "$blocked_paths" >&2
    failure=1
  fi

  blocked_media=$(grep -Ei "$private_media_pattern" "$path_list" | grep -Ev '^Echo/Shared/Resources/Assets\.xcassets/' || true)
  if [ -n "$blocked_media" ]; then
    printf '%s\n' "Repository safety check failed: media outside the reviewed public asset catalog is present in $label:" >&2
    printf '%s\n' "$blocked_media" >&2
    printf '%s\n' "Use synthetic assets and update the explicit allowlist only after review." >&2
    failure=1
  fi
}

check_credentials() {
  label=$1
  revision=$2

  if [ "$revision" = "--cached" ]; then
    credential_files=$(git grep --cached -lEI -e "$credential_pattern" -e "$assignment_pattern" -- . 2>/dev/null || true)
  else
    credential_files=$(git grep -lEI -e "$credential_pattern" -e "$assignment_pattern" "$revision" -- . 2>/dev/null || true)
  fi

  if [ -n "$credential_files" ]; then
    printf '%s\n' "Repository safety check failed: possible credentials were found in $label:" >&2
    printf '%s\n' "$credential_files" >&2
    printf '%s\n' "Values are intentionally not printed. Remove and rotate any real credential before continuing." >&2
    failure=1
  fi
}

if [ "${1:-}" = "--history" ]; then
  for revision in $(git rev-list --all); do
    short_revision=$(git rev-parse --short "$revision")
    git ls-tree -r --name-only "$revision" > "$path_list"
    check_paths "commit $short_revision"
    check_credentials "commit $short_revision" "$revision"
  done
  checked_scope="tracked Git history"
elif [ "$#" -eq 0 ]; then
  git ls-files > "$path_list"
  check_paths "the staged snapshot"
  check_credentials "the staged snapshot" "--cached"
  checked_scope="staged snapshot"
else
  printf '%s\n' "Usage: $0 [--history]" >&2
  exit 2
fi

if [ "$failure" -ne 0 ]; then
  exit 1
fi

printf '%s\n' "Repository safety check passed for $checked_scope."
