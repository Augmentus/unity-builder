import { BuildParameters } from '.';
import { SetupMac, SetupAndroid } from './platform-setup/';

class PlatformSetup {
  static async setup(buildParameters: BuildParameters, actionFolder: string) {
    PlatformSetup.SetupShared(buildParameters);

    switch (process.platform) {
      case 'win32':
        break;
      case 'darwin':
        await SetupMac.setup(buildParameters, actionFolder);
        break;

      // Add other baseOS's here
    }
  }

  private static SetupShared(buildParameters: BuildParameters) {
    SetupAndroid.setup(buildParameters);
  }
}

export default PlatformSetup;
