#! /bin/bash

set -e

# Modify this with the location of the actual assistant binary and mod-dhcp script
ASSISTANT=original-proxmox-auto-install-assistant
MOD_DHCP_CMD=/assistant/mod-dhcp.sh

if [ "$1" != "prepare-iso" ]; then
  echo "Not running the prepare-iso command, skipping the wrapper"
  # We only run the dhcp modification if this is the prepare-iso command, so skip the rest of the script
  set -- ${ASSISTANT} "$@"
  exec "$@"
  echo "This should never be reached"
  exit 1
fi

ORIG_ARGS=("${@}")

shift

NEW_ARGS=()
MOD_DHCP=0
URL_SET=0
HELP_SET=0
OUTPUT=""
FETCH_FROM=""
INPUT=""

# We have to parse all the arguments of the original command and find the ones we need to modify.
# Specifically, if --mod-dhcp is set, we need to modify --output argument to a temporary intermediate file.
# This seems really brittle, breaking with any change in the original command,
# but it is the only way I could figure out how to do it.
while [ $# -gt 0 ]; do
  case "$1" in
    --mod-dhcp)
        MOD_DHCP=1
        shift
      ;;
    --output=*)
        OUTPUT="${1#--output=}"
        shift
      ;;
    --output)
        OUTPUT="$2"
        shift 2
      ;;
    --url=*)
        URL_SET=1
        NEW_ARGS+=("--url=${1#--url=}")
        shift
      ;;
    --url)
        URL_SET=1
        NEW_ARGS+=("--url" "$2")
        shift 2
      ;;
    --fetch-from=*)
        FETCH_FROM="${1#--fetch-from=}"
        NEW_ARGS+=("--fetch-from=${FETCH_FROM}")
        shift
      ;;
    --fetch-from)
        FETCH_FROM="$2"
        NEW_ARGS+=("--fetch-from" "$2")
        shift 2
      ;;
    --answer-file=*)
        NEW_ARGS+=("--answer-file=${1#--answer-file=}")
        shift
      ;;
    --answer-file)
        NEW_ARGS+=("--answer-file" "$2")
        shift 2
      ;;
    --cert-fingerprint=*)
        NEW_ARGS+=("--cert-fingerprint=${1#--cert-fingerprint=}")
        shift
      ;;
    --cert-fingerprint)
        NEW_ARGS+=("--cert-fingerprint" "$2")
        shift 2
      ;;
    --tmp=*)
        NEW_ARGS+=("--tmp=${1#--tmp=}")
        shift
      ;;
    --tmp)
        NEW_ARGS+=("--tmp" "$2")
        shift 2
      ;;
    --partition-label=*)
        NEW_ARGS+=("--partition-label=${1#--partition-label=}")
        shift
      ;;
    --partition-label)
        NEW_ARGS+=("--partition-label" "$2");
        shift 2
      ;;
    --on-first-boot=*)
        NEW_ARGS+=("--on-first-boot=${1#--on-first-boot=}")
        shift
      ;;
    --on-first-boot)
        NEW_ARGS+=("--on-first-boot" "$2")
        shift 2
      ;;
    --help)
        HELP_SET=1
        shift
      ;;
    -h)
        HELP_SET=1
        shift
      ;;
    *)
      NEW_ARGS+=("$1")
      INPUT="$1"
      shift
      ;;
  esac
done

if [ $HELP_SET -eq 1 ]; then
  ${ASSISTANT} prepare-iso --help
  echo ""
  echo "NOTE: you ran the wrapper, which offers an additional option"
  echo "  --mod-dhcp: "
  echo "       Modify the DHCP timeout before requesting the answer file (fixes issues for ipxe/netboot)"
else
  if [ $MOD_DHCP -eq 1 ]; then
    if [ -z "$INPUT" ] || [ -z "$FETCH_FROM" ]; then
      echo "input and fetch-from must be set going to pass it to the original command, but it is probably going to fail"
      echo "input: $INPUT"
      echo "fetch-from: $FETCH_FROM"
      echo ${ASSISTANT} "${ORIG_ARGS[@]}"
      set -- ${ASSISTANT} "${ORIG_ARGS[@]}"
      exec "$@"
      exit 1
    fi
    if [ -z "$OUTPUT" ]; then
      INPUT_DIR=$(dirname "$INPUT")
      INPUT_BASE_WITH_EXT=$(basename -- "$INPUT")
      INPUT_BASE="${INPUT_BASE_WITH_EXT%.*}"
      INPUT_EXTENSION="${INPUT_BASE_WITH_EXT##*.}"
      OUTPUT="${INPUT_DIR}/${INPUT_BASE}-auto-from-${FETCH_FROM}"
      if [ $URL_SET -eq 1 ]; then
        OUTPUT="$OUTPUT-url"
      fi
      OUTPUT="${OUTPUT}.${INPUT_EXTENSION}"
      echo "output was not explicitly set. Trying to reproduce the default behavior by outputting to \"${OUTPUT}\""
    fi
    TEMP_FILE=$(mktemp).iso
    set -- ${ASSISTANT} prepare-iso --output "$TEMP_FILE" "${NEW_ARGS[@]}"
    echo "Running the original command with the modified arguments"
    echo "$@"
    if ! "$@"; then
      echo ""
      echo "The prepare-iso command failed. It was executed by a wrapper that adds the --mod-dhcp option."
      echo "It's possible the wrapper is breaking things."
      echo "Try the following command, which executes the the original binary directly:"
      echo ""
      echo "$@"
      echo ""
      echo "If that works, you can execute the mod-dhcp.sh script manually as follows:"
      echo ""
      echo "${MOD_DHCP_CMD} $TEMP_FILE $OUTPUT"
      exit 1
    fi
    ${MOD_DHCP_CMD} "$TEMP_FILE" "$OUTPUT"
    rm "$TEMP_FILE"
  else
    echo "--mod-dhcp was not set, running the original command"
    # All this was for nothing.. we didn't modify the DHCP, so we can just run the original command
    set -- ${ASSISTANT} "${ORIG_ARGS[@]}"
    echo "$@"
    exec "$@"
  fi
fi
