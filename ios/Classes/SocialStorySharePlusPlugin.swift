import Flutter
import UIKit
import Photos

public class SocialStorySharePlusPlugin: NSObject, FlutterPlugin, UIDocumentInteractionControllerDelegate {

  private var documentInteractionController: UIDocumentInteractionController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "social_story_share_plus", binaryMessenger: registrar.messenger())
    let instance = SocialStorySharePlusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "shareToInstagramStories":
      shareToInstagramStories(call: call, result: result)
    case "shareToInstagramDirect":
      shareToInstagramDirect(call: call, result: result)
    case "shareToFacebookStories":
      shareToFacebookStories(call: call, result: result)
    case "shareToWhatsAppStatus":
      shareToWhatsApp(call: call, result: result)
    case "saveToGallery":
      saveToGallery(call: call, result: result)
    case "isInstagramInstalled":
      result(isAppInstalled(scheme: "instagram-stories://"))
    case "isFacebookInstalled":
      result(isAppInstalled(scheme: "facebook-stories://"))
    case "isWhatsAppInstalled":
      result(isAppInstalled(scheme: "whatsapp://"))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Helpers

  private func isAppInstalled(scheme: String) -> Bool {
    guard let url = URL(string: scheme) else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  /// Returns the foreground window. Replaces deprecated `UIApplication.shared.keyWindow`.
  private func activeWindow() -> UIWindow? {
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }

  // MARK: - Instagram Stories

  private func shareToInstagramStories(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let stickerPath = args["stickerPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Sticker path is required", details: nil))
      return
    }

    let source = Bundle.main.bundleIdentifier ?? ""
    guard let urlScheme = URL(string: "instagram-stories://share?source_application=\(source)") else {
      result(FlutterError(code: "URL_ERROR", message: "Invalid URL scheme", details: nil))
      return
    }

    if !UIApplication.shared.canOpenURL(urlScheme) {
      result(FlutterError(code: "INSTAGRAM_NOT_INSTALLED", message: "Instagram is not installed", details: nil))
      return
    }

    var pasteboardItems: [[String: Any]] = []

    if let stickerImage = UIImage(contentsOfFile: stickerPath) {
      pasteboardItems.append([
        "com.instagram.sharedSticker.stickerImage": stickerImage,
        "com.instagram.sharedSticker.backgroundImage": stickerImage
      ])
    }

    if let bgPath = args["backgroundImagePath"] as? String,
       let bgImage = UIImage(contentsOfFile: bgPath),
       var item = pasteboardItems.first {
      item["com.instagram.sharedSticker.backgroundImage"] = bgImage
      pasteboardItems[0] = item
    }

    if args["backgroundImagePath"] == nil,
       let topHex = args["backgroundTopColor"] as? String,
       let bottomHex = args["backgroundBottomColor"] as? String,
       var item = pasteboardItems.first {
      item["com.instagram.sharedSticker.backgroundTopColor"] = topHex
      item["com.instagram.sharedSticker.backgroundBottomColor"] = bottomHex
      pasteboardItems[0] = item
    }

    let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
      .expirationDate: Date().addingTimeInterval(60 * 5)
    ]

    UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)
    UIApplication.shared.open(urlScheme, options: [:]) { success in
      result(success)
    }
  }

  // MARK: - Instagram Direct

  private func shareToInstagramDirect(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let text = args["text"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Text is required", details: nil))
      return
    }

    guard let instagramURL = URL(string: "instagram://") else {
      result(FlutterError(code: "INVALID_URL", message: "Invalid Instagram URL", details: nil))
      return
    }

    if !UIApplication.shared.canOpenURL(instagramURL) {
      result(FlutterError(code: "INSTAGRAM_NOT_INSTALLED", message: "Instagram app is not installed", details: nil))
      return
    }

    guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let shareURL = URL(string: "instagram://sharesheet?text=\(encodedText)") else {
      result(FlutterError(code: "ENCODING_ERROR", message: "Failed to encode text", details: nil))
      return
    }

    UIApplication.shared.open(shareURL, options: [:]) { success in
      if success {
        result(true)
        return
      }
      // Fallback: copy to clipboard and open Instagram home.
      UIPasteboard.general.string = text
      UIApplication.shared.open(instagramURL, options: [:]) { fallbackSuccess in
        if fallbackSuccess {
          DispatchQueue.main.async {
            self.showToast(message: "Message copied — paste in Instagram")
          }
          result(true)
        } else {
          result(FlutterError(code: "FAILED_TO_OPEN", message: "Failed to open Instagram", details: nil))
        }
      }
    }
  }

  private func showToast(message: String) {
    guard let window = activeWindow() else { return }

    let label = UILabel()
    label.backgroundColor = UIColor.black.withAlphaComponent(0.8)
    label.textColor = .white
    label.textAlignment = .center
    label.font = UIFont.systemFont(ofSize: 14)
    label.text = message
    label.numberOfLines = 0
    label.alpha = 0
    label.layer.cornerRadius = 10
    label.clipsToBounds = true

    let size = label.intrinsicContentSize
    let width = min(size.width + 40, window.frame.width - 40)
    let height = size.height + 20
    label.frame = CGRect(
      x: (window.frame.width - width) / 2,
      y: window.frame.height - height - 100,
      width: width,
      height: height
    )

    window.addSubview(label)
    UIView.animate(withDuration: 0.3, animations: { label.alpha = 1.0 }) { _ in
      UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut, animations: {
        label.alpha = 0.0
      }) { _ in
        label.removeFromSuperview()
      }
    }
  }

  // MARK: - Facebook Stories

  private func shareToFacebookStories(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
      return
    }

    guard let appId = args["appId"] as? String, !appId.isEmpty else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Facebook appId is required", details: nil))
      return
    }

    guard let facebookURL = URL(string: "facebook-stories://share"),
          UIApplication.shared.canOpenURL(facebookURL) else {
      result(FlutterError(code: "FACEBOOK_NOT_INSTALLED", message: "Facebook app is not installed", details: nil))
      return
    }

    var pasteboardItem: [String: Any] = [
      "com.facebook.sharedSticker.appID": appId
    ]

    guard let stickerPath = args["stickerPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "stickerPath is required", details: nil))
      return
    }

    guard let stickerImage = UIImage(contentsOfFile: stickerPath),
          let stickerData = stickerImage.pngData() else {
      result(FlutterError(code: "IMAGE_ERROR", message: "Cannot load sticker image from path: \(stickerPath)", details: nil))
      return
    }

    pasteboardItem["com.facebook.sharedSticker.stickerImage"] = stickerData

    if let bgPath = args["backgroundImagePath"] as? String {
      guard let bgImage = UIImage(contentsOfFile: bgPath),
            let bgData = bgImage.pngData() else {
        result(FlutterError(code: "IMAGE_ERROR", message: "Cannot load background image from path: \(bgPath)", details: nil))
        return
      }
      pasteboardItem["com.facebook.sharedSticker.backgroundImage"] = bgData
    } else {
      // Use sticker as background fallback so the story isn't blank.
      pasteboardItem["com.facebook.sharedSticker.backgroundImage"] = stickerData
      if let topColor = args["backgroundTopColor"] as? String {
        pasteboardItem["com.facebook.sharedSticker.backgroundTopColor"] = topColor
      }
      if let bottomColor = args["backgroundBottomColor"] as? String {
        pasteboardItem["com.facebook.sharedSticker.backgroundBottomColor"] = bottomColor
      }
    }

    let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
      .expirationDate: Date().addingTimeInterval(60 * 5)
    ]
    UIPasteboard.general.setItems([pasteboardItem], options: pasteboardOptions)

    UIApplication.shared.open(facebookURL, options: [:]) { success in
      if success {
        result(true)
      } else {
        result(FlutterError(code: "SHARE_FAILED", message: "Failed to open Facebook app", details: nil))
      }
    }
  }

  // MARK: - WhatsApp

  private func shareToWhatsApp(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let imagePath = args["imagePath"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Image path is required", details: nil))
      return
    }

    guard let urlScheme = URL(string: "whatsapp://") else {
      result(FlutterError(code: "URL_ERROR", message: "Invalid URL scheme", details: nil))
      return
    }

    if !UIApplication.shared.canOpenURL(urlScheme) {
      result(FlutterError(code: "WHATSAPP_NOT_INSTALLED", message: "WhatsApp is not installed", details: nil))
      return
    }

    guard let controller = activeWindow()?.rootViewController else {
      result(FlutterError(code: "VIEW_ERROR", message: "Unable to find root view controller", details: nil))
      return
    }

    guard FileManager.default.fileExists(atPath: imagePath) else {
      result(FlutterError(code: "FILE_ERROR", message: "Image file does not exist", details: nil))
      return
    }

    let fileURL = URL(fileURLWithPath: imagePath)
    documentInteractionController = UIDocumentInteractionController(url: fileURL)
    documentInteractionController?.uti = "net.whatsapp.image"
    documentInteractionController?.delegate = self

    let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
    let success = documentInteractionController?.presentOpenInMenu(from: rect, in: controller.view, animated: true) ?? false
    if success {
      result(true)
    } else {
      result(FlutterError(code: "SHARE_FAILED", message: "Failed to present share options", details: nil))
    }
  }

  // MARK: - Save to Gallery

  private func saveToGallery(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let flutterData = args["imageBytes"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Image bytes required", details: nil))
      return
    }

    guard let image = UIImage(data: flutterData.data) else {
      result(FlutterError(code: "IMAGE_ERROR", message: "Could not decode image", details: nil))
      return
    }

    PHPhotoLibrary.requestAuthorization { status in
      guard status == .authorized else {
        result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library permission denied", details: nil))
        return
      }
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }) { success, error in
        if success {
          result(true)
        } else {
          result(FlutterError(code: "SAVE_FAILED", message: error?.localizedDescription, details: nil))
        }
      }
    }
  }
}
