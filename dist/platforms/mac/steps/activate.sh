#!/usr/bin/env bash

# Run in ACTIVATE_LICENSE_PATH directory
echo "Changing to \"$ACTIVATE_LICENSE_PATH\" directory."
pushd "$ACTIVATE_LICENSE_PATH"

if [[ -n "$UNITY_SERIAL" && -n "$UNITY_EMAIL" && -n "$UNITY_PASSWORD" ]]; then
  #
  # SERIAL LICENSE MODE
  #
  # This will activate unity, using the serial activation process.
  #

  echo "Requesting activation"

  # Activate license
  /Applications/Unity/Hub/Editor/$UNITY_VERSION/Unity.app/Contents/MacOS/Unity \
    -logFile - \
    -batchmode \
    -nographics \
    -quit \
    -serial "$UNITY_SERIAL" \
    -username "$UNITY_EMAIL" \
    -password "$UNITY_PASSWORD" \
    -projectPath "$ACTIVATE_LICENSE_PATH"

  # Store the exit code from the verify command
  UNITY_EXIT_CODE=$?

elif [[ -n "$UNITY_LICENSING_SERVER" ]]; then
  #
  # Custom Unity License Server
  #
  echo "Adding licensing server config"
  mkdir -p "$UNITY_LICENSE_PATH/config/"

  # Render services-config.json from the template (substitute the server URL and the
  # product IDs). The macOS path previously copied a services-config.json that is never
  # generated, so the floating-license config was missing and activation failed. This
  # mirrors what the Windows path (activate.ps1) does.
  sed -e "s|%URL%|$UNITY_LICENSING_SERVER|g" \
      -e "s|%LICENSE_PRODUCT_IDS%|$UNITY_LICENSING_PRODUCT_IDS|g" \
      "$ACTION_FOLDER/unity-config/services-config.json.template" \
      > "$UNITY_LICENSE_PATH/config/services-config.json"
  echo "Wrote services-config.json:"
  cat "$UNITY_LICENSE_PATH/config/services-config.json"

  # Floating-license seats are often all in use. Poll --acquire-floating until a seat
  # frees or we hit the timeout (default 60 min), mirroring the Windows path, instead
  # of giving up after a single attempt.
  LICENSING_CLIENT="/Applications/Unity/Hub/Editor/$UNITY_VERSION/Unity.app/Contents/Frameworks/UnityLicensingClient.app/Contents/MacOS/Unity.Licensing.Client"
  POLL_INTERVAL_SEC="${UNITY_LICENCE_POLL_INTERVAL_SEC:-15}"
  TIMEOUT_MINUTES="${UNITY_LICENCE_POLL_TIMEOUT_MINUTES:-60}"
  DEADLINE=$(( $(date +%s) + TIMEOUT_MINUTES * 60 ))

  UNITY_EXIT_CODE=1
  ATTEMPT=0
  while [ "$(date +%s)" -lt "$DEADLINE" ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "Acquire floating license attempt $ATTEMPT ($(( (DEADLINE - $(date +%s)) / 60 )) min remaining)"
    "$LICENSING_CLIENT" --acquire-floating > license.txt
    UNITY_EXIT_CODE=$?
    if [ $UNITY_EXIT_CODE -eq 0 ]; then
      break
    fi
    echo "Failed to acquire floating license (attempt $ATTEMPT, exit code $UNITY_EXIT_CODE); retrying in ${POLL_INTERVAL_SEC}s..."
    sleep "$POLL_INTERVAL_SEC"
  done

  if [ $UNITY_EXIT_CODE -eq 0 ]; then
    PARSEDFILE=$(grep -oE '\"[^"]*\"' < license.txt | tr -d '"')
    export FLOATING_LICENSE
    FLOATING_LICENSE=$(sed -n 2p <<< "$PARSEDFILE")
    FLOATING_LICENSE_TIMEOUT=$(sed -n 4p <<< "$PARSEDFILE")

    echo "Acquired floating license: \"$FLOATING_LICENSE\" with timeout $FLOATING_LICENSE_TIMEOUT"
  else
    echo "::error ::Failed to acquire a floating license within ${TIMEOUT_MINUTES} minutes (all seats busy?)"
  fi
else
  #
  # NO LICENSE ACTIVATION STRATEGY MATCHED
  #
  # This will exit since no activation strategies could be matched.
  #
  echo "License activation strategy could not be determined."
  echo ""
  echo "Visit https://game.ci/docs/github/activation for more"
  echo "details on how to set up one of the possible activation strategies."

  echo "::error ::No valid license activation strategy could be determined. Make sure to provide UNITY_EMAIL, UNITY_PASSWORD, and either a UNITY_SERIAL \
or UNITY_LICENSE. Otherwise please use UNITY_LICENSING_SERVER. See more info at https://game.ci/docs/github/activation"

  # Immediately exit as no UNITY_EXIT_CODE can be derived.
  exit 1;

fi

#
# Display information about the result
#
if [ $UNITY_EXIT_CODE -eq 0 ]; then
  # Activation was a success
  echo "Activation complete."
else
  # Activation failed so exit with the code from the license verification step
  echo "Unclassified error occured while trying to activate license."
  echo "Exit code was: $UNITY_EXIT_CODE"
  echo "::error ::There was an error while trying to activate the Unity license."
  exit $UNITY_EXIT_CODE
fi

# Return to previous working directory
popd
