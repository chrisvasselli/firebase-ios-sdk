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

/// CacheKey is like a "key" to a "safe". It provides necessary metadata about the current cache to know if it should be expired.
struct CacheKey: Codable {
  var createdAt: Date
  var googleAppID: String
  var appVersion: String
}

/// SettingsCacheClient is responsible for accessing the cache that Settings are stored in.
protocol SettingsCacheClient {
  /// Returns in-memory cache content in O(1) time
  var cacheContent: [String: Any]? { get }
  /// Returns in-memory cache-key, no performance guarantee because type-casting depends on size of CacheKey
  var cacheKey: CacheKey? { get }
  /// Removes all cache content and cache-key
  func removeCache()
}

/// SettingsCache uses UserDefaults to store Settings on-disk, but also directly query UserDefaults when accessing Settings values during run-time. This is because UserDefaults encapsulates both in-memory and persisted-on-disk storage, allowing fast synchronous access in-app while hiding away the complexity of managing persistence asynchronously.
class SettingsCache: SettingsCacheClient {
  private static let settingsVersion: Int = 1
  private static let content: String = "firebase-sessions-settings"
  private static let key: String = "firebase-sessions-cache-key"
  /// UserDefaults holds values in memory, making access O(1) and synchronous within the app, while abstracting away async disk IO.
  private let cache: UserDefaults = .standard

  /// Converting to dictionary is O(1) because object conversion is O(1)
  var cacheContent: [String: Any]? {
    return cache.dictionary(forKey: SettingsCache.content)
  }

  /// Casting to Codable from Data is O(n)
  var cacheKey: CacheKey? {
    if let data = cache.data(forKey: SettingsCache.key) {
      do {
        return try JSONDecoder().decode(CacheKey.self, from: data)
      } catch {
        Logger.logError("[Settings] Decoding CacheKey failed with error: \(error)")
      }
    }
    return nil
  }

  /// Removes stored cache
  func removeCache() {
    cache.set(nil, forKey: SettingsCache.content)
    cache.set(nil, forKey: SettingsCache.key)
  }
}
