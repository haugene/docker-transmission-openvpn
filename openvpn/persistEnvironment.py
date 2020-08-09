import os
import sys
import json


# Verify script arguments
if len(sys.argv) != 2:
    sys.exit(
        'Invalid number of arguments. Usage:\n persistEnvironment.py /path/to/varibles-script.sh')

envVarsScriptFile = sys.argv[1]

wantedVariables = ['OPENVPN_PROVIDER', 'ENABLE_UFW', 'PUID', 'PGID', 'DROP_DEFAULT_ROUTE', 'GLOBAL_APPLY_PERMISSIONS', 'DOCKER_LOG']

variablesToPersist = {}

for variable in os.environ:
    if variable.startswith('TRANSMISSION_'):
        variablesToPersist[variable] = os.environ.get(variable)
    if variable.startswith('WEBPROXY_'):
        variablesToPersist[variable] = os.environ.get(variable)
    if variable in wantedVariables:
        variablesToPersist[variable] = os.environ.get(variable)


# Dump resulting settings to file
with open(envVarsScriptFile, 'w') as file:
    for variable in variablesToPersist:
        file.write('export ' + variable + '=' +
                   variablesToPersist[variable] + '\n')
