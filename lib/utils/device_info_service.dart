import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/constants.dart';

class DeviceInfoService {
  static const String _deviceInfoKey = 'device_info_cache';
  static const String _fallbackUuidKey = 'fallback_device_uuid';
  
  static DeviceInfoService? _instance;
  
  static DeviceInfoService get instance {
    _instance ??= DeviceInfoService._();
    return _instance!;
  }
  
  DeviceInfoService._();
  
  Map<String, dynamic>? _cachedDeviceInfo;
  
  /// 🎯 主要方法：收集並儲存設備資訊
  Future<void> collectAndStoreDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      debugPrint('${Constants.tag} Device info already cached');
      return; // 避免重複收集
    }
    
    try {
      final deviceInfo = await _gatherDeviceInfo();
      _cachedDeviceInfo = deviceInfo;
      
      // 儲存到本地
      await _storeDeviceInfoLocally(deviceInfo);
      
      debugPrint('${Constants.tag} Device info collected: ${deviceInfo['device_model']}');
    } catch (e) {
      debugPrint('${Constants.tag} Failed to collect device info: $e');
      rethrow;
    }
  }
  
  /// 📱 收集完整設備資訊
  Future<Map<String, dynamic>> _gatherDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    
    Map<String, dynamic> deviceData = {
      'collected_at': DateTime.now().toIso8601String(),
      'app_version': packageInfo.version,
      'app_build_number': packageInfo.buildNumber,
      'app_package_name': packageInfo.packageName,
      'app_name': packageInfo.appName,
    };
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData.addAll({
          'platform': 'Android',
          'device_uuid': androidInfo.id,
          'device_model': '${androidInfo.brand} ${androidInfo.model}',
          'device_brand': androidInfo.brand,
          'device_manufacturer': androidInfo.manufacturer,
          'device_product': androidInfo.product,
          'device_name': androidInfo.device,
          'os_version': androidInfo.version.release,
          'os_sdk_int': androidInfo.version.sdkInt,
          'hardware': androidInfo.hardware,
          'is_physical_device': androidInfo.isPhysicalDevice,
          'supported_abis': androidInfo.supportedAbis,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData.addAll({
          'platform': 'iOS',
          'device_uuid': iosInfo.identifierForVendor ?? await _generateFallbackUuid(),
          'device_model': iosInfo.model,
          'device_name': iosInfo.name,
          'device_localized_model': iosInfo.localizedModel,
          'os_version': iosInfo.systemVersion,
          'is_physical_device': iosInfo.isPhysicalDevice,
          'system_name': iosInfo.systemName,
        });
      }
    } catch (e) {
      debugPrint('${Constants.tag} Failed to get platform-specific device info: $e');
      
      // 添加回退資料
      deviceData.addAll({
        'platform': Platform.operatingSystem,
        'device_uuid': await _generateFallbackUuid(),
        'device_model': 'Unknown Device',
        'os_version': 'Unknown',
        'error': e.toString(),
      });
    }
    
    return deviceData;
  }
  
  /// 💾 儲存到本地
  Future<void> _storeDeviceInfoLocally(Map<String, dynamic> deviceInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deviceInfoKey, jsonEncode(deviceInfo));
    } catch (e) {
      debugPrint('${Constants.tag} Failed to store device info locally: $e');
    }
  }
  
  /// 🔄 回退 UUID 生成
  Future<String> _generateFallbackUuid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? existingUuid = prefs.getString(_fallbackUuidKey);
      if (existingUuid != null) return existingUuid;
      
      final newUuid = const Uuid().v4();
      await prefs.setString(_fallbackUuidKey, newUuid);
      return newUuid;
    } catch (e) {
      debugPrint('${Constants.tag} Failed to generate fallback UUID: $e');
      return 'fallback-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  /// 📖 獲取快取的設備資訊
  Map<String, dynamic>? get cachedDeviceInfo => _cachedDeviceInfo;
  
  /// 📖 從本地讀取設備資訊
  Future<Map<String, dynamic>?> getStoredDeviceInfo() async {
    if (_cachedDeviceInfo != null) return _cachedDeviceInfo;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceInfoString = prefs.getString(_deviceInfoKey);
      if (deviceInfoString != null) {
        _cachedDeviceInfo = jsonDecode(deviceInfoString);
        return _cachedDeviceInfo;
      }
    } catch (e) {
      debugPrint('${Constants.tag} Failed to get stored device info: $e');
    }
    return null;
  }
  
  /// 🆔 快速獲取設備 UUID
  String? get deviceUuid => _cachedDeviceInfo?['device_uuid'];
  
  /// 📱 快速獲取設備型號
  String? get deviceModel => _cachedDeviceInfo?['device_model'];
  
  /// 🖥️ 快速獲取平台
  String? get platform => _cachedDeviceInfo?['platform'];
  
  /// 📊 快速獲取 OS 版本
  String? get osVersion => _cachedDeviceInfo?['os_version'];
  
  /// 📦 快速獲取 App 版本
  String? get appVersion => _cachedDeviceInfo?['app_version'];
  
  /// 🔍 獲取設備指紋 (用於註冊/驗證)
  Map<String, dynamic> getDeviceFingerprint() {
    if (_cachedDeviceInfo == null) {
      return {
        'device_uuid': 'not_collected',
        'device_model': 'Unknown',
        'platform': Platform.operatingSystem,
        'os_version': 'Unknown',
        'app_version': 'Unknown',
      };
    }
    
    return {
      'device_uuid': deviceUuid,
      'device_model': deviceModel,
      'platform': platform,
      'os_version': osVersion,
      'app_version': appVersion,
    };
  }
  
  /// 🧹 清除快取 (測試用)
  Future<void> clearCache() async {
    _cachedDeviceInfo = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceInfoKey);
      debugPrint('${Constants.tag} Device info cache cleared');
    } catch (e) {
      debugPrint('${Constants.tag} Failed to clear device info cache: $e');
    }
  }
  
  /// 📋 獲取用於 Debug 的設備資訊摘要
  String getDeviceInfoSummary() {
    if (_cachedDeviceInfo == null) {
      return 'Device info not collected';
    }
    
    return '''
Device Info Summary:
- UUID: ${deviceUuid ?? 'Unknown'}
- Model: ${deviceModel ?? 'Unknown'}
- Platform: ${platform ?? 'Unknown'} ${osVersion ?? ''}
- App Version: ${appVersion ?? 'Unknown'}
- Physical Device: ${_cachedDeviceInfo?['is_physical_device'] ?? 'Unknown'}
''';
  }
  
  /// 🔒 獲取用於安全驗證的設備指紋
  Map<String, dynamic> getSecurityFingerprint() {
    final fingerprint = getDeviceFingerprint();
    
    // 添加額外的安全相關資訊
    fingerprint.addAll({
      'timestamp': DateTime.now().toIso8601String(),
      'is_debug': kDebugMode,
      'is_physical_device': _cachedDeviceInfo?['is_physical_device'] ?? false,
    });
    
    return fingerprint;
  }
}
