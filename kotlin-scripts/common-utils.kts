@file:DependsOn("org.zeroturnaround:zt-exec:1.11")
@file:DependsOn("org.slf4j:slf4j-nop:1.7.30") // zt-exec causes http://www.slf4j.org/codes.html#StaticLoggerBinder without

import java.io.File
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import org.zeroturnaround.exec.ProcessExecutor
import java.io.BufferedReader
import java.util.concurrent.TimeUnit
import kotlin.system.exitProcess

fun runCommand(vararg command: String, env: Map<String, String> = emptyMap()): String {
    return ProcessExecutor().command(command.toList())
        .readOutput(true)
        .exitValueNormal()
        .execute()
        .outputUTF8()
}

// Convenience method as extension of String - for simple commands with no customizations
fun String.runCommand(): String = runCommand(command= *split(" ").toTypedArray(), env= emptyMap())

fun String.execute(
        user: String = "",
        workingDir: File = File("."),
        environment: Map<String, String> = emptyMap(),
        timeoutAmount: Long = 60,
        timeoutUnit: TimeUnit = TimeUnit.SECONDS,
        stdoutRedirectBehavior: ProcessBuilder.Redirect = ProcessBuilder.Redirect.PIPE,
        stderrRedirectBehavior: ProcessBuilder.Redirect = ProcessBuilder.Redirect.PIPE
): ProcessResult {
    val processBuilder = if (user.isNotBlank()) {
        ProcessBuilder("su", "--preserve-environment", user, "-s", "/bin/bash", "-c", this)
    } else {
        ProcessBuilder("/bin/bash", "-c", this)
    }
    
    processBuilder
        .directory(workingDir)
        .redirectOutput(stdoutRedirectBehavior)
        .redirectError(stderrRedirectBehavior)

    val processEnvironment: MutableMap<String, String> = processBuilder.environment()
    processEnvironment.putAll(environment)
    return processBuilder.start()
            .apply {
                waitFor(timeoutAmount, timeoutUnit)
                if (isAlive) {
                    destroyForcibly()
                    println("Command timed out after ${timeoutUnit.toSeconds(timeoutAmount)} seconds: '$this'")
                    exitProcess(1)
                }
            }
            .let { process ->
                val stdOut = processBuilder.redirectOutput()?.file()?.bufferedReader()
                        ?: process.inputStream.bufferedReader()
                val stdErr = processBuilder.redirectError()?.file()?.bufferedReader()
                        ?: process.errorStream.bufferedReader()
                ProcessResult(process.exitValue(), stdOut, stdErr)
            }
}

data class ProcessResult(val exitCode: Int, val stdOut: BufferedReader, val stdErr: BufferedReader) {
    val succeeded: Boolean = exitCode == 0
    val failed: Boolean = !succeeded
}

fun booleanEnv(envVar: String): Boolean {
    return when (System.getenv(envVar)?.toLowerCase()) {
        "true" -> true
        else -> false
    }
}

fun requiredEnv(envVar: String): String {
    val variable = System.getenv(envVar)
    requireNotNull(variable) { "Required variable $envVar is not set" }
    return variable
}

fun env(envVar: String): String? = System.getenv(envVar)

fun log(message: String, level: LogLevel = LogLevel.INFO) {
    val timestamp = LocalDateTime.now()
        .format(DateTimeFormatter.ofPattern("EEE MMM dd HH:mm:ss yyyy"))
        //.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS"))

    println("$timestamp $level : $message")
}

enum class LogLevel {
    INFO, WARN, ERROR, FATAL
}