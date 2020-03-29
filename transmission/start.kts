#!/usr/bin/env kscript

@file:Include("../kotlin-scripts/common-utils.kts")

log("Transmission startup script triggered")
log("Received arguments: ${args.joinToString(separator = " ")}")

val envVarFile = File("/etc/openvpn/.transmission-env").readLines()
val envVars: MutableMap<String, String> = envVarFile.map { it.substringBefore("=") to it.substringAfter("=") }.toMap().toMutableMap()
if (envVars["TRANSMISSION_WEB_HOME"]?.isEmpty() == true) {
    envVars.remove("TRANSMISSION_WEB_HOME")
}

val logFile = if (envVars["DOCKER_LOG"]?.toLowerCase() == "true") {
    "/proc/1/fd/1"
 } else {
     "\${TRANSMISSION_HOME}/transmission.log"
}
log("Transmission will be logging to $logFile")

val runAsUser = findUserToRunAs()
val (exitCode, stdOut, stdErr) = "/usr/bin/transmission-daemon -g \${TRANSMISSION_HOME} --logfile $logFile".execute(user=runAsUser, environment=envVars)

if (exitCode != 0) {
    log("Failed to start Transmission", LogLevel.ERROR)
    stdOut.readLines().forEach { log(it, LogLevel.ERROR) }
    stdErr.readLines().forEach { log(it, LogLevel.ERROR) }
}

log("Transmission startup script finished")

/*
 * Helper functions
 */

fun findUserToRunAs() : String {
    // Cheating - just call the existing script and see what it returns.
    // TODO: Rewrite to native Kotlin
    val (userSetupExitCode, userSetupStdOut, userSetupStdErr) = "/etc/transmission/userSetup.sh".execute(environment=envVars)
    val runAsUser = if (userSetupExitCode == 0) {
        val logLines = userSetupStdOut.readLines()
        logLines.forEach {line -> log(line)}
        val abcUser: String? = logLines.firstOrNull { it.contains("abc") }
        return if (abcUser != null) "abc" else "root"
    } else {
        log("Something went wrong when determining user to run as", LogLevel.ERROR)
        userSetupStdErr.readLines().forEach {line -> log(line, LogLevel.ERROR)}
        log("Defaulting to run as root", LogLevel.ERROR)
        return "root"
    }
}