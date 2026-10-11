import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.minSize = NSSize(width: 820, height: 560)

    let defaultWidth: CGFloat = 1000
    let defaultHeight: CGFloat = 680
    if let screen = self.screen ?? NSScreen.main {
      let screenFrame = screen.visibleFrame
      let x = screenFrame.origin.x + (screenFrame.width - defaultWidth) / 2
      let y = screenFrame.origin.y + (screenFrame.height - defaultHeight) / 2
      self.setFrame(NSRect(x: x, y: y, width: defaultWidth, height: defaultHeight), display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
