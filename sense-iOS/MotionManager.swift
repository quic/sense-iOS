import UIKit

public protocol MotionManagerDelegate: class {
    func rotated(_ orientation: UIDeviceOrientation)
}

class MotionManager: NSObject {
    
    var didRotate: ((Notification) -> Void)!
    weak var delegate: MotionManagerDelegate?
    
    override init() {
        super.init()
        setUpNotification()
    }
    
    func setUpNotification() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        self.didRotate = { notification in
            let orientation = self.getOrientation()
            self.delegate?.rotated(orientation)
        }
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification,
                                               object: nil,
                                               queue: .main,
                                               using: self.didRotate)
    }
    
    func getOrientation() -> UIDeviceOrientation {
        var orientation: UIDeviceOrientation
        orientation = UIDevice.current.orientation
        return orientation
    }
}
