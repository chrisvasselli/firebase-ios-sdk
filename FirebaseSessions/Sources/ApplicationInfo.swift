//
// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

@_implementationOnly import FirebaseCore
@_implementationOnly import GoogleUtilities

/// Development environment for the application.
enum DevEnvironment: String {
  case prod // Prod environment
  case staging // Staging environment
  case autopush // Autopush environment
}

protocol ApplicationInfoProtocol {
  /// Google App ID / GMP App ID
  var appID: String { get }

  /// App's bundle ID / bundle short version
  var bundleID: String { get }

  /// Version of the Firebase SDK
  var sdkVersion: String { get }

  /// Crashlytics-specific device / OS filter values.
  var osName: String { get }

  /// Model of the device
  var deviceModel: String { get }

  /// Validated Mobile Country Code and Mobile Network Code
  var mccMNC: String { get }

  /// Development environment on which the application is running.
  var environment: DevEnvironment { get }

  var appBuildVersion: String { get }

  var appDisplayVersion: String { get }
}

class ApplicationInfo: ApplicationInfoProtocol {
  let appID: String

  private let networkInfo: NetworkInfoProtocol
  private let envParams: [String: String]

  init(appID: String, networkInfo: NetworkInfoProtocol = NetworkInfo(),
       envParams: [String: String] = ProcessInfo.processInfo.environment) {
    self.appID = appID
    self.networkInfo = networkInfo
    self.envParams = envParams
  }

  var bundleID: String {
    return Bundle.main.bundleIdentifier ?? ""
  }

  var sdkVersion: String {
    return FirebaseVersion()
  }

  var osName: String {
    return GULAppEnvironmentUtil.appleDevicePlatform()
  }

  var deviceModel: String {
    #if targetEnvironment(simulator)
      return GULAppEnvironmentUtil.deviceSimulatorModel() ?? ""
    #else
      return GULAppEnvironmentUtil.deviceModel() ?? ""
    #endif // targetEnvironment(simulator)
  }

  var mccMNC: String {
    return FIRSESValidateMccMnc(networkInfo.mobileCountryCode, networkInfo.mobileNetworkCode) ?? ""
  }

  var environment: DevEnvironment {
    if let environment = envParams["FirebaseSessionsRunEnvironment"] {
      return DevEnvironment(rawValue: environment.trimmingCharacters(in: .whitespaces).lowercased())
        ?? DevEnvironment.prod
    }
    return DevEnvironment.prod
  }

  var appBuildVersion: String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
  }

  var appDisplayVersion: String {
    return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
  }
}
