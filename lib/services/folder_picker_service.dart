import 'dart:io';

class FolderPickerService {
  /// Prompts the user to select a directory using native OS dialogs.
  static Future<String?> pickDirectory({
    String? prompt,
    String? initialDirectory,
  }) async {
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
            // Remove trailing slash if present
            return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
          }
        }
      } catch (_) {}
    } else if (Platform.isWindows) {
      try {
        const script =
            r'[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null; $f = New-Object System.Windows.Forms.FolderBrowserDialog; if($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){$f.SelectedPath}';
        final result = await Process.run('powershell', [
          '-NoProfile',
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
