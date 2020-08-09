import os
import sys
import json


# Verify script arguments
if len(sys.argv) != 3:
    sys.exit('Invalid number of arguments. Usage:\n updateSettings.py defaultSettingsFile.json outputSettingsFile.json')

default_settings = sys.argv[1]
transmission_settings = sys.argv[2]

if not os.path.isfile(default_settings):
    sys.exit('Invalid arguments, default settings file does not exist')

# Define which file to base the config on
if os.path.isfile(transmission_settings):
    configuration_baseline=transmission_settings
else:
    configuration_baseline=default_settings

print('Using config baseline ' + configuration_baseline)

# Read config base
with open(configuration_baseline, 'r') as f:
    settings_dict = json.load(f)

# For each setting, check if an environment variable is set to override it
for setting in settings_dict:
    setting_env_name = 'TRANSMISSION_' + setting.upper().replace('-', '_')
    if setting_env_name in os.environ:
        print('Overriding ' + setting + ' because ' + setting_env_name + ' is set to ' + os.environ.get(setting_env_name))
        settings_dict[setting] = os.environ.get(setting_env_name)

# Dump resulting settings to file
with open(transmission_settings, 'w') as fp:
    json.dump(settings_dict, fp)
