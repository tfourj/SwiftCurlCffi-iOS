import Foundation

public enum SwiftCurlCffiIOS {
    public static var resourceBundle: Bundle {
        Bundle.module
    }

    public static var payloadURL: URL? {
        Bundle.module.url(
            forResource: "curl_cffi_ios_payload",
            withExtension: "zip"
        )
    }

    public static var manifestURL: URL? {
        Bundle.module.url(
            forResource: "manifest",
            withExtension: "json"
        )
    }
}

