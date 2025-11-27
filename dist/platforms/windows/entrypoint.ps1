Get-Process

# Setup Git Credentials
. "c:\steps\set_gitcredential.ps1"

# Activate Unity
if ($env:SKIP_ACTIVATION -ne "true") {
  . "c:\steps\activate.ps1"

  # If we didn't activate successfully, exit with the exit code from the activation step.
  if ($ACTIVATION_EXIT_CODE -ne 0) {
    exit $ACTIVATION_EXIT_CODE
  }
}
else {
  Write-Host "Skipping activation"
}

# Build the project
. "c:\steps\build.ps1"

# Free the seat for the activated license
if ($env:SKIP_ACTIVATION -ne "true") {
  . "c:\steps\return_license.ps1"
}

Get-Process

exit $BUILD_EXIT_CODE
