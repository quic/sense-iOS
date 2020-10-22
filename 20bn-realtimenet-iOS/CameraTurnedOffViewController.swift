import UIKit

class CameraTurnedOffViewController: UIViewController {
    
    @IBOutlet weak var cameraDescriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraDescriptionLabel.text = "please allow the app access to your camera. Turn on Camera in your device settings."
    }
    

    @IBAction func goToSettingsAction(_ sender: UIButton) {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
