import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FolderPickerService {
  /// Prompts the user to select a directory using native OS dialogs.
  /// Works across Windows (Win32 IFileDialog), Android (SAF tree picker),
  /// macOS (NSOpenPanel), and Linux (GTK / portal).
  static Future<String?> pickDirectory({
    String? prompt,
    String? initialDirectory,
  }) async {
    // 1. Primary: Native file_picker plugin (supports Windows, Android, macOS, Linux)
    try {
      final selected = await FilePicker.getDirectoryPath(
        dialogTitle: prompt,
        initialDirectory: initialDirectory,
      );
      if (selected != null && selected.trim().isNotEmpty) {
        final path = selected.trim();
        return (path.length > 1 && path.endsWith('/') && !path.endsWith('://'))
            ? path.substring(0, path.length - 1)
            : path;
      }
      return null;
    } catch (_) {
      // If plugin throws (e.g. MissingPluginException in tests or headless), fall back to OS shell
    }

    // 2. Platform-specific fallbacks
    if (Platform.isMacOS) {
      try {
        final pText = prompt ?? 'Select VMware Download Directory';
        final initClause = (initialDirectory != null && initialDirectory.isNotEmpty)
            ? 'default location POSIX file "$initialDirectory" '
            : '';
        final result = await Process.run('osascript', [
          '-e',
          'POSIX path of (choose folder ${initClause}with prompt "$pText")',
        ]);
        if (result.exitCode == 0) {
          final path = result.stdout.toString().trim();
          if (path.isNotEmpty) {
            return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
          }
        }
      } catch (_) {}
    } else if (Platform.isWindows) {
      try {
        // -STA is mandatory for WinForms FolderBrowserDialog to avoid ThreadStateException
        const script =
            r'[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null; $f = New-Object System.Windows.Forms.FolderBrowserDialog; if($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){$f.SelectedPath}';
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-STA',
          '-Command',
          script,
        ]);
        if (result.exitCode == 0) {
          final path = result.stdout.toString().trim();
          if (path.isNotEmpty) return path;
        }
      } catch (_) {}
    } else if (Platform.isLinux) {
      try {
        final result = await Process.run('zenity', [
          '--file-selection',
          '--directory',
          '--title=${prompt ?? "Select VMware Download Directory"}',
        ]);
        if (result.exitCode == 0) {
          final path = result.stdout.toString().trim();
          if (path.isNotEmpty) return path;
        }
      } catch (_) {}
    }
    return null;
  }
}

