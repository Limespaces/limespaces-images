#!/bin/bash
# @author Claude Opus 4.6 inside Google Antigravity IDE

# Wrapper for sysbox-runc that strips the unsupported "time" namespace
# from the OCI spec before passing it to the real sysbox-runc binary.
# See: https://github.com/nestybox/sysbox/issues/1011

REAL_SYSBOX="/usr/bin/sysbox-runc.real"

# For the "create" command, we need to patch the config.json
if [[ "$*" == *"create"* ]]; then
    # Find the bundle path (--bundle flag or last argument)
    BUNDLE=""
    ARGS=("$@")
    for i in "${!ARGS[@]}"; do
        if [[ "${ARGS[$i]}" == "--bundle" ]]; then
            BUNDLE="${ARGS[$((i+1))]}"
            break
        fi
    done

    if [[ -n "$BUNDLE" && -f "$BUNDLE/config.json" ]]; then
        # Remove "time" namespace entries from the OCI spec
        jq 'if .linux.namespaces then .linux.namespaces |= map(select(.type != "time")) else . end' \
            "$BUNDLE/config.json" > "$BUNDLE/config.json.tmp" && \
            mv "$BUNDLE/config.json.tmp" "$BUNDLE/config.json"
    fi
fi

exec "$REAL_SYSBOX" "$@"
