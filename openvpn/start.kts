#!/usr/bin/env kscript

@file:Include("../kotlin-scripts/openVpnConfig.kts")
@file:Include("../kotlin-scripts/common-utils.kts")

import java.io.File

/**
 * -- Main Script
 */
log("Starting application setup, verifying parameters")

val configFilePath = determineOpenVpnConfigFileLocation()
verifyUsernameAndPasswordSetup() // Write username/password variables to file or check that the file already exists

// Setting up routes to allow traffic to local networks 
val localNetworks = env("LOCAL_NETWORK")
if (localNetworks != null) {
    configureIpTables(localNetworks.split(","))
}

val openvpnOpts = StringBuilder()
    .append("--script-security 2 --up-delay --up /etc/openvpn/tunnelUp.sh --down /etc/openvpn/tunnelDown.sh")
    .append(" ")
    .append(env("OPENVPN_OPTS") ?: "") // Append custom OPENVPN_OPTS if provided
    .append(" ")
    .append("--auth-nocache")
    .toString()

// Persist environment variables for use with Transmission. Because Transmission will be started by OpenVPN
// in another shell it does not have access to the startup environment. Let's persist a good selection.
File("/etc/openvpn/.transmission-env").printWriter().use { out ->
    environmentVariablesToTransmission().forEach { line -> out.println(line) }
}

// Write the chosen config to env file used to launch OpenVPN.
File("/etc/openvpn/.openvpn-env").writeText(
    """
        export OPENVPN_OPTS="$openvpnOpts"
        export OPENVPN_CONFIG="$configFilePath"
    """.trimIndent()
)

// We're done, print message and exit - OpenVPN will start next
log("|-----------------------------------------------|")
log("|                                               |")
log("|   Configuration complete, starting OpenVPN    |")
log("|                                               |")
log("|-----------------------------------------------|")

/**
 * Helper functions to simplify the command flow in the main script
 */
fun configureIpTables(networks: List<String>) {

    // Base rules on the default route. Returns something like: "default via 172.20.0.1 dev eth0"
    val defaultRoute: String = "/sbin/ip r s default".runCommand().trim()

    val routeParts = defaultRoute.split(" ")
    check(routeParts.size == 5) { "Unknown output from iptables route: $defaultRoute" }

    val gw = routeParts[2]
    val int = routeParts[4]

    networks.forEach { network ->
        log("Adding route through local lan for traffic going to $network")
        try {
            "/sbin/ip r a $network via $gw dev $int".runCommand()
        } catch (e: Exception) {
            log("Got error while adding local network route for $network", LogLevel.ERROR)
            e.printStackTrace()
        }
    }
    log("All configured LOCAL_NETWORK values added, they are now bypassing VPN")
}

fun environmentVariablesToTransmission(): List<String> {
    val (envExitCode, envStdOut, envStdErr) = "env".execute()
    require(envExitCode == 0) { "Failed to fetch environment variables to persist for Transmission" }
    val envVariables = envStdOut.readLines()
    return envVariables.filter {
            it.startsWith("TRANSMISSION_") ||
            it.startsWith("OPENVPN_PROVIDER") ||
            it.startsWith("PUID") ||
            it.startsWith("PGID") ||
            it.startsWith("GLOBAL_APPLY_PERMISSIONS") ||
            it.startsWith("DOCKER_LOG")
    }
}
