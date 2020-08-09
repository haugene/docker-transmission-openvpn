import argparse
import json
import os
import sys


parser = argparse.ArgumentParser(
    description='Updates output settings file based on a default file',
)

parser.add_argument(
    'input_file',
    type=str,
    help='Path to default settings json file',
)

parser.add_argument(
    'output_file',
    type=str,
    help='Path to output settings json file',
)

args = parser.parse_args()
default_settings = args.input_file
transmission_settings = args.output_file

# Fail if default settings file doesnt exist.
if not os.path.isfile(default_settings):
    sys.exit(
        'Invalid arguments, default settings file{file} does not exist'.format(
            file=default_settings,
        ),
    )


# Define which file to base the config on
if os.path.isfile(transmission_settings):
    configuration_baseline = transmission_settings
else:
    configuration_baseline = default_settings

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
