//
//  CameraTurnedOffViewController.swift
//  iOS-Millie
//
//  Created by Kushal Pandya on 2019-12-05.
//  Copyright © 2019 TwentyBN. All rights reserved.
//

import UIKit

class CameraTurnedOffViewController: UIViewController {
    
    @IBOutlet weak var cameraDescriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraDescriptionLabel.text = "please allow the caloriemeter access to your camera. Turn on Camera in your device settings."
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
