const FileSystemStreamInit = {
    headers: {
        "Content-Type": "application/octet-stream"
    }
}

class FileInputStreamError extends Error {
    constructor(message, code) {
        super(message)
        this.code = code
        this.name = "FileInputStreamError"
    }
}

class FileOutputStreamError extends Error {
    constructor(message, code) {
        super(message)
        this.code = code
        this.name = "FileOutputStreamError"
    }
}

class FileSystemPermissionError extends Error {
    constructor(streamType) {
        super(
            `Unable to find the "window.Fs${streamType === "INPUT" ? "InputStream" : "OutputStream"
            }" interface. This likely means that the user has not granted the necessary permissions to access the filesystem. Please ensure that you have granted the required permissions and try again.`
        )
    }
}

/**
 * Opens an input stream for reading files from the filesystem
 * @param path - The file path to read from
 * @param init - Optional configuration for the readable stream
 * @returns Promise that resolves to a Response object containing the file data
 */
async function openInputStream(path, init = {}) {
    // Validate input parameters
    if (typeof path !== "string") {
        throw new TypeError("'path' must be a string")
    }

    if (typeof path === "string" && path.trim() === "") {
        throw new Error("'path' cannot be empty")
    }

    // Check if the FileInputStream interface is available
    if (
        !window.FileInputStream ||
        typeof window.FileInputStream.postMessage !== "function"
    ) {
        throw new FileSystemPermissionError("INPUT")
    }

    const mergedInit = {
        ...FileSystemStreamInit,
        ...init
    }

    return new Promise((resolve, reject) => {
        const chunks = []
        let aborted = false
        let messageHandler = null

        const onAbort = () => {
            aborted = true
            cleanup()
            reject(new DOMException("The operation was aborted.", "AbortError"))
        }

        // Handle abort signal
        if (mergedInit.signal?.aborted) {
            onAbort()
            return
        }

        mergedInit.signal?.addEventListener("abort", onAbort)

        const cleanup = () => {
            if (mergedInit.signal) {
                mergedInit.signal.removeEventListener("abort", onAbort)
            }
            if (messageHandler && window.FileInputStream) {
                window.FileInputStream.removeEventListener("message", messageHandler)
                window.FileInputStream.onmessage = null
            }
        }

        messageHandler = event => {
            if (aborted) return

            const msg = event.data

            if (msg instanceof ArrayBuffer) {
                chunks.push(new Uint8Array(msg))
            } else if (typeof msg === "string") {
                cleanup()
                reject(new FileInputStreamError(msg, "STREAM_ERROR"))
                return
            } else {
                cleanup()
                reject(
                    new FileInputStreamError(
                        "Received unexpected message type",
                        "INVALID_MESSAGE"
                    )
                )
                return
            }

            // Create the readable stream once we have data
            try {
                const stream = new ReadableStream({
                    start(controller) {
                        try {
                            for (const chunk of chunks) {
                                controller.enqueue(chunk)
                            }
                            controller.close()
                        } catch (error) {
                            controller.error(error)
                            throw error
                        }
                    },
                    cancel(reason) {
                        console.warn("Stream canceled:", reason)
                        cleanup()
                    }
                })

                cleanup()
                resolve(new Response(stream, mergedInit))
            } catch (error) {
                cleanup()
                reject(error instanceof Error ? error : new Error(String(error)))
            }
        }

        // Set up message listener and send request
        window.FileInputStream?.addEventListener("message", messageHandler)

        try {
            window.FileInputStream?.postMessage(path)
        } catch (error) {
            cleanup()
            reject(
                new FileInputStreamError(
                    `Failed to send message to FileInputStream: ${error}`,
                    "POST_MESSAGE_ERROR"
                )
            )
        }
    })
}

export { openInputStream }