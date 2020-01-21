//
//  AppDelegate.swift
//  Helen v1
//
//  Created by Amrutavarsh Kinagi on 27/11/2019.
//  Copyright © 2019 Helen. All rights reserved.
//

import UIKit
import AWSS3

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:eb1de7db-5e6c-4050-ad9b-b34a41dbf285")

            //Setup the service configuration
            let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)

            //Setup the transfer utility configuration
            let tuConf = AWSS3TransferUtilityConfiguration()
        //    tuConf.isAccelerateModeEnabled = true

            //Register a transfer utility object asynchronously
            AWSS3TransferUtility.register(
                with: configuration!,
                transferUtilityConfiguration: tuConf,
                forKey: "transfer-utility-with-advanced-options"
            )
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

