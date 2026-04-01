package space.iscreation.vkpn

import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import kotlin.concurrent.thread

class VkTurnProcessManager(
    private val executableProvider: () -> String,
    private val onLog: (String) -> Unit
) {
    private var process: Process? = null

    fun start(targetHost: String, proxyPort: Int, vkCallLink: String, useUdp: Boolean, threads: Int, localEndpoint: String) {
        stop()
        val executable = executableProvider()
        val args = mutableListOf(
            executable,
            "-peer", "$targetHost:$proxyPort",
            "-vk-link", vkCallLink,
            "-listen", localEndpoint,
            "-n", threads.toString()
        )
        if (useUdp) {
            args.add("-udp")
        }
        onLog(
            "vk-turn cmd: $executable -peer $targetHost:$proxyPort -vk-link [REDACTED] " +
                "-listen $localEndpoint -n $threads${if (useUdp) " -udp" else ""}"
        )
        process = ProcessBuilder(args)
            .redirectErrorStream(true)
            .start()
        thread(start = true, isDaemon = true) {
            try {
                val reader = BufferedReader(InputStreamReader(process?.inputStream))
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    onLog(line ?: "")
                }
            } catch (e: Exception) {
                onLog("vk-turn log reader error: ${e.message}")
            }
        }
    }

    fun stop() {
        process?.destroy()
        process = null
    }

    companion object {
        fun resolveExecutable(filesDir: File, nativeLibraryDir: String): String {
            val custom = File(filesDir, "custom_vkturn")
            if (custom.exists()) {
                custom.setExecutable(true)
                return custom.absolutePath
            }
            return "$nativeLibraryDir/libvkturn.so"
        }
    }
}
