import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client_information/client_information.dart';
import 'dart:io';

class TrialState {
  final bool isValid;
  final int remainingDays;
  final bool isUnlocked;

  TrialState({
    required this.isValid,
    required this.remainingDays,
    required this.isUnlocked,
  });
}

class LicenseManager {
  static final LicenseManager instance = LicenseManager._init();
  LicenseManager._init();

  final SupabaseClient _client = Supabase.instance.client;

  Future<String> _getDeviceHWID() async {
    try {
      // 1. Try primary plugin first
      ClientInformation info = await ClientInformation.fetch();
      if (info.deviceId.isNotEmpty && info.deviceId != "unknown") {
        return "${info.deviceId}_${info.osName}";
      }
      throw Exception("Plugin ID unknown");
    } catch (e) {
      // 2. Verified Native Windows Fallback: Fetch Motherboard UUID via wmic shell command
      if (Platform.isWindows) {
        try {
          // FIXED: Changed 'cscorporation' to 'csproduct'
          ProcessResult result = await Process.run('wmic', [
            'csproduct',
            'get',
            'UUID',
          ]);
          if (result.exitCode == 0) {
            String systemUuid = result.stdout
                .toString()
                .replaceAll('UUID', '')
                .trim();
            if (systemUuid.isNotEmpty && !systemUuid.contains('Error')) {
              return "WIN_HW_$systemUuid";
            }
          }
        } catch (err) {
          print("⚠️ Motherboard shell command failed: $err");
        }
      }
      // Final emergency fallback if nothing works
      return "DEV_MACHINE_FALLBACK_ID";
    }
  }

  Future<TrialState> checkLicenseStatus() async {
    try {
      String hwid = await _getDeviceHWID();
      print("ℹ️ Your Current Machine HWID is: $hwid");

      final response = await _client
          .from('app_licenses')
          .select('start_date, is_unlocked')
          .eq('hwid', hwid)
          .maybeSingle();

      if (response == null) {
        await _client.from('app_licenses').insert({
          'hwid': hwid,
          'is_unlocked': false,
        });
        return TrialState(isValid: true, remainingDays: 7, isUnlocked: false);
      }

      if (response['is_unlocked'] == true) {
        return TrialState(isValid: true, remainingDays: 999, isUnlocked: true);
      }

      DateTime startDate = DateTime.parse(response['start_date']).toUtc();
      DateTime serverTime = await fetchServerTime();

      final difference = serverTime.difference(startDate).inDays;
      int remaining = 7 - difference;
      if (remaining < 0) remaining = 0;

      if (difference >= 7) {
        return TrialState(isValid: false, remainingDays: 0, isUnlocked: false);
      }

      return TrialState(
        isValid: true,
        remainingDays: remaining,
        isUnlocked: false,
      );
    } catch (e) {
      print("🚨 CRITICAL LICENSE ERROR: $e");
      // Safety fallback during unexpected connection outages
      return TrialState(isValid: true, remainingDays: 7, isUnlocked: false);
    }
  }

  Future<DateTime> fetchServerTime() async {
    try {
      final List<dynamic> result = await _client.rpc('snapshot_time_stub');
      if (result.isNotEmpty && result.first['now'] != null) {
        return DateTime.parse(result.first['now']).toUtc();
      }
      return DateTime.now().toUtc();
    } catch (e) {
      print(
        "⚠️ RPC time check failed ($e), falling back to basic date fields.",
      );
      return DateTime.now().toUtc();
    }
  }

  /// Verifies an activation key against Supabase and binds it permanently to this machine's HWID
  Future<bool> redeemActivationKey(String enteredKey) async {
    try {
      String hwid = await _getDeviceHWID();

      // 1. Check if the key exists and hasn't been used yet
      final response = await _client
          .from('activation_keys')
          .select()
          .eq('key_code', enteredKey.trim())
          .eq('is_used', false)
          .maybeSingle();

      if (response == null) {
        return false; // Key is invalid or already used by someone else!
      }

      // 2. Mark the key as used in Supabase
      await _client
          .from('activation_keys')
          .update({'is_used': true, 'used_by_hwid': hwid})
          .eq('key_code', enteredKey.trim());

      // 3. Permanently unlock this machine's app license row
      await _client
          .from('app_licenses')
          .update({'is_unlocked': true})
          .eq('hwid', hwid);

      return true; // Successfully activated!
    } catch (e) {
      print("Activation error: $e");
      return false;
    }
  }
}
