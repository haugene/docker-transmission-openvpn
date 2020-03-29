
@file:Include("../kotlin-scripts/common-utils.kts")
@file:DependsOn("com.github.kittinunf.fuel:fuel:2.2.1")

import com.github.kittinunf.fuel.httpGet
import com.github.kittinunf.result.Result

/*
 * Helper functions to handle configuring OpenVPN
 * Determining what provider, config and credentials to use.
 */

 fun determineOpenVpnConfigFileLocation(): String {
    val provider = openvpnProviderSetup()
    val config = openvpnConfigSetup(provider)
    return "${providerBasePath(provider)}/${config}"
 }

fun openvpnProviderSetup(): String {
    val provider = requiredEnv("OPENVPN_PROVIDER")

    // Check that it's not left at default value
    if (provider == "**None**") {
        log("OPENVPN_PROVIDER is not set, cannot start", LogLevel.FATAL)
        System.exit(1)
    }

    log("Using OpenVPN provider: $provider")
    return provider.toLowerCase()
}

fun openvpnConfigSetup(provider: String): String {
    val openVpnConfig = env("OPENVPN_CONFIG")
    val openVpnConfigUrl = env("OPENVPN_CONFIG_URL")

    val config = if (openVpnConfigUrl != null) {
        log("OPENVPN_CONFIG_URL is set, will download config from that URL")
        getConfigFromUrl(provider, openVpnConfigUrl)
    } else if (openVpnConfig == null) {
        log("OPENVPN_CONFIG not set. Finding a random config from provider $provider")
        pickRandomConfigFromProvider(provider)
    } else if (openVpnConfig.split(",").size > 1) {
        log("List of configs supplied in OPENVPN_CONFIG, picking one at random")
        openVpnConfig.split(",").random().trim()
    } else {
        // Nothing special. The user specified the config they wanted to use.
        openVpnConfig
    }

    require(File("${providerBasePath(provider)}/$config.ovpn").exists()) { "Cannot find config $config for provider $provider" }

    log("Using config $config")
    return "$config.ovpn"
}

fun getConfigFromUrl(provider: String, url: String): String {
    val configFileLines = downloadConfig(url)
    val modifiedConfigLines = modifyConfigFile(configFileLines)

    // Create provider folder if it doesn't exist, ie. for custom provider
    File(providerBasePath(provider)).mkdirs()

    File("${providerBasePath(provider)}/downloaded_config.ovpn").printWriter().use { out ->
        modifiedConfigLines.forEach { line -> out.println(line) }
    }
    return "downloaded_config"
}

fun downloadConfig(url: String): List<String> {
    val (request, response, result) = url
        .httpGet().responseString()

    when (result) {
        is Result.Failure -> {
            throw RuntimeException("Could not find config file at the requested URL: $url", result.getException())
        }
        is Result.Success -> {
            return result.get().split("\n")
        }
    }
}

fun pickRandomConfigFromProvider(provider: String): String {
    val providerConfigs: List<File>? = File(providerBasePath(provider)).listFiles()?.toList()
    requireNotNull(providerConfigs) { "No configs found for provider $provider" }
    return providerConfigs.filter { it.isFile && it.name.endsWith(".ovpn") }.random().nameWithoutExtension
}

fun modifyConfigFile(configFileLines: List<String>): List<String> {
    val newConfig = mutableListOf<String>()
    configFileLines.forEach {
        if (it.startsWith("auth-user-pass")) {
            newConfig.add("auth-user-pass /config/openvpn-credentials.txt")
        } else {
            newConfig.add(it)
        }
    }
    return newConfig
}

fun verifyUsernameAndPasswordSetup() {
    val openVpnCredentialsFilePath = "/config/openvpn-credentials.txt"
    val username = env("OPENVPN_USERNAME")
    val password = env("OPENVPN_PASSWORD")

    if (username != "**None**" && password != "**None**") {
        File(openVpnCredentialsFilePath).printWriter().use { out ->
            out.println(username)
            out.println(password)
        }
        log("Username and password written to $openVpnCredentialsFilePath")
        "chmod 600 $openVpnCredentialsFilePath".execute()
    } else if (File(openVpnCredentialsFilePath).exists()) {
        log("Found existing credentials file at ${openVpnCredentialsFilePath}, using it.")
    } else {
        throw IllegalArgumentException("OPENVPN_USERNAME/OPENVPN_PASSWORD is not set and no credentials file is mounted. Cannot start.")
    }
}

fun providerBasePath(provider: String) = "/etc/openvpn/${provider.toLowerCase()}"