import fs from 'node:fs';
import * as core from '@actions/core';
import { BuildParameters } from '.';
import { SetupMac, SetupAndroid } from './platform-setup/';

class PlatformSetup {
  static async setup(buildParameters: BuildParameters, actionFolder: string) {
    PlatformSetup.SetupShared(buildParameters, actionFolder);

    switch (process.platform) {
      case 'win32':
        break;
      case 'darwin':
        await SetupMac.setup(buildParameters, actionFolder);
        break;

      // Add other baseOS's here
    }
  }

  private static SetupShared(buildParameters: BuildParameters, actionFolder: string) {
    const servicesConfigPath = `${actionFolder}/unity-config/services-config.json`;
    const servicesConfigPathTemplate = `${servicesConfigPath}.template`;
    if (!fs.existsSync(servicesConfigPathTemplate)) {
      core.error(`Missing services config ${servicesConfigPathTemplate}`);

      return;
    }

    let servicesConfig = fs.readFileSync(servicesConfigPathTemplate).toString();
    servicesConfig = servicesConfig.replace('%URL%', buildParameters.unityLicensingServer);
    fs.writeFileSync(servicesConfigPath, servicesConfig);
    core.info(`Wrote services config to ${servicesConfigPath}`);
    core.info(`Wrote services config to ${servicesConfig}`);

    SetupAndroid.setup(buildParameters);
  }
}

export default PlatformSetup;
