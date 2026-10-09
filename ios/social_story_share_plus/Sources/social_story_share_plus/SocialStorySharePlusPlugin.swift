import Flutter
import Photos
import UIKit

public class SocialStorySharePlusPlugin: NSObject, FlutterPlugin {
  private var documentController: UIDocumentInteractionController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "social_story_share_plus", binaryMessenger: registrar.messenger())
    let instance = SocialStorySharePlusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    do {
      switch call.method {
      case "shareToInstagramStories":
        try shareToInstagramStories(args, result: result)
      case "shareToFacebookStories":
        try shareToFacebookStories(args, result: result)
      case "shareToInstagramDirect":
        try shareToInstagramDirect(args, result: result)
      case "shareToWhatsAppStatus":
        try shareToWhatsAppStatus(args, result: result)
      case "saveToGallery":
        try saveToGallery(args, result: result)
      case "isInstagramInstalled":
        result(canOpen(Scheme.instagramStories))
      case "isFacebookInstalled":
        result(canOpen(Scheme.facebookStories))
      case "isWhatsAppInstalled":
        result(canOpen(Scheme.whatsApp))
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as ShareError {
      result(error.flutterError)
    } catch {
      result(ShareError.failed(error.localizedDescription).flutterError)
    }
  }

  // MARK: - Stories

  private func shareToInstagramStories(_ args: [String: Any], result: @escaping FlutterResult) throws {
    let appId = try requireString(args, "appId")
    let item = try storyItem(args, keyPrefix: "com.instagram.sharedSticker")
    guard let url = URL(string: "\(Scheme.instagramStories)share?source_application=\(percentEncoded(appId))") else {
      throw ShareError.invalidArgument("appId is not valid")
    }
    try openStory(url, item: item, appName: "Instagram", result: result)
  }

  private func shareToFacebookStories(_ args: [String: Any], result: @escaping FlutterResult) throws {
    let appId = try requireString(args, "appId")
    var item = try storyItem(args, keyPrefix: "com.facebook.sharedSticker")
    item["com.facebook.sharedSticker.appID"] = appId
    try openStory(URL(string: "\(Scheme.facebookStories)share")!, item: item, appName: "Facebook", result: result)
  }

  private func storyItem(_ args: [String: Any], keyPrefix: String) throws -> [String: Any] {
    var item: [String: Any] = [:]
    if let path = args["stickerPath"] as? String {
      item["\(keyPrefix).stickerImage"] = try pngData(at: path)
    }
    if let path = args["backgroundImagePath"] as? String {
      item["\(keyPrefix).backgroundImage"] = try pngData(at: path)
    } else {
      item["\(keyPrefix).backgroundTopColor"] = args["backgroundTopColor"] as? String
      item["\(keyPrefix).backgroundBottomColor"] = args["backgroundBottomColor"] as? String
    }
    guard item["\(keyPrefix).stickerImage"] != nil || item["\(keyPrefix).backgroundImage"] != nil else {
      throw ShareError.invalidArgument("Provide a stickerPath, a backgroundImagePath, or both")
    }
    return item
  }

  private func openStory(_ url: URL, item: [String: Any], appName: String, result: @escaping FlutterResult) throws {
    guard UIApplication.shared.canOpenURL(url) else { throw ShareError.appNotInstalled(appName) }
    UIPasteboard.general.setItems([item], options: [.expirationDate: Date().addingTimeInterval(5 * 60)])
    UIApplication.shared.open(url, options: [:]) { result($0) }
  }

  // MARK: - Instagram Direct

  private func shareToInstagramDirect(_ args: [String: Any], result: @escaping FlutterResult) throws {
    let text = try requireString(args, "text")
    guard let appURL = URL(string: Scheme.instagram), UIApplication.shared.canOpenURL(appURL) else {
      throw ShareError.appNotInstalled("Instagram")
    }

    // Instagram doesn't always honour the prefilled text, so it stays on the clipboard as a fallback.
    UIPasteboard.general.string = text
    guard let shareURL = URL(string: "\(Scheme.instagram)sharesheet?text=\(percentEncoded(text))") else {
      UIApplication.shared.open(appURL, options: [:]) { result($0) }
      return
    }
    UIApplication.shared.open(shareURL, options: [:]) { opened in
      if opened {
        result(true)
      } else {
        UIApplication.shared.open(appURL, options: [:]) { result($0) }
      }
    }
  }

  // MARK: - WhatsApp

  private func shareToWhatsAppStatus(_ args: [String: Any], result: @escaping FlutterResult) throws {
    let path = try requireString(args, "imagePath")
    guard canOpen(Scheme.whatsApp) else { throw ShareError.appNotInstalled("WhatsApp") }
    guard FileManager.default.fileExists(atPath: path) else { throw ShareError.fileNotFound(path) }
    guard let view = topViewController()?.view else {
      throw ShareError.uiUnavailable("No view controller to present the share menu from")
    }

    let controller = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
    controller.uti = "net.whatsapp.image"
    documentController = controller

    let anchor = CGRect(x: view.bounds.midX, y: view.bounds.maxY, width: 0, height: 0)
    result(controller.presentOpenInMenu(from: anchor, in: view, animated: true))
  }

  // MARK: - Gallery

  private func saveToGallery(_ args: [String: Any], result: @escaping FlutterResult) throws {
    guard let data = (args["imageBytes"] as? FlutterStandardTypedData)?.data else {
      throw ShareError.invalidArgument("imageBytes is required")
    }
    guard UIImage(data: data) != nil else { throw ShareError.invalidImage("imageBytes is not a supported image") }
    let fileName = args["fileName"] as? String

    requestAddAccess { granted in
      guard granted else {
        result(ShareError.permissionDenied("Photo library access was denied").flutterError)
        return
      }
      PHPhotoLibrary.shared().performChanges({
        let options = PHAssetResourceCreationOptions()
        options.originalFilename = fileName
        PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: options)
      }) { success, error in
        DispatchQueue.main.async {
          result(success ? true : ShareError.failed(error?.localizedDescription ?? "Could not save the image").flutterError)
        }
      }
    }
  }

  private func requestAddAccess(_ completion: @escaping (Bool) -> Void) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        DispatchQueue.main.async { completion(status == .authorized || status == .limited) }
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        DispatchQueue.main.async { completion(status == .authorized) }
      }
    }
  }

  // MARK: - Helpers

  private func canOpen(_ scheme: String) -> Bool {
    guard let url = URL(string: scheme) else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  private func pngData(at path: String) throws -> Data {
    guard FileManager.default.fileExists(atPath: path) else { throw ShareError.fileNotFound(path) }
    guard let data = UIImage(contentsOfFile: path)?.pngData() else {
      throw ShareError.invalidImage("\(path) is not a supported image")
    }
    return data
  }

  private func requireString(_ args: [String: Any], _ key: String) throws -> String {
    guard let value = args[key] as? String, !value.trimmingCharacters(in: .whitespaces).isEmpty else {
      throw ShareError.invalidArgument("\(key) is required")
    }
    return value
  }

  private func percentEncoded(_ value: String) -> String {
    value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
  }

  // Scene-based apps have no window on the app delegate, so look it up through the connected scenes.
  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let windows = (scenes.first { $0.activationState == .foregroundActive } ?? scenes.first)?.windows ?? []
    let legacyWindow = UIApplication.shared.delegate?.window ?? nil
    let window = windows.first { $0.isKeyWindow } ?? windows.first ?? legacyWindow

    var top = window?.rootViewController
    while let presented = top?.presentedViewController, !presented.isBeingDismissed {
      top = presented
    }
    return top
  }
}

private enum Scheme {
  static let instagram = "instagram://"
  static let instagramStories = "instagram-stories://"
  static let facebookStories = "facebook-stories://"
  static let whatsApp = "whatsapp://"
}

private struct ShareError: Error {
  let code: String
  let message: String

  var flutterError: FlutterError { FlutterError(code: code, message: message, details: nil) }

  static func appNotInstalled(_ app: String) -> ShareError {
    ShareError(code: "APP_NOT_INSTALLED", message: "\(app) is not installed")
  }
  static func fileNotFound(_ path: String) -> ShareError { ShareError(code: "FILE_NOT_FOUND", message: "No file at \(path)") }
  static func invalidImage(_ message: String) -> ShareError { ShareError(code: "INVALID_IMAGE", message: message) }
  static func invalidArgument(_ message: String) -> ShareError { ShareError(code: "INVALID_ARGUMENT", message: message) }
  static func uiUnavailable(_ message: String) -> ShareError { ShareError(code: "UI_UNAVAILABLE", message: message) }
  static func permissionDenied(_ message: String) -> ShareError { ShareError(code: "PERMISSION_DENIED", message: message) }
  static func failed(_ message: String) -> ShareError { ShareError(code: "FAILED", message: message) }
}
