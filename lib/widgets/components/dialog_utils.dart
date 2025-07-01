import 'package:flutter/material.dart';

Future<bool?> showCustomDialog(
  BuildContext context,
  String message, {
  String okLabel = 'OK',
  String cancelLabel = 'Cancel',
}) async {
  final theme = Theme.of(context);
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Notification', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(message, style: TextStyle(color: theme.colorScheme.onSurface)),
        actions: <Widget>[
          TextButton(
            child: Text(cancelLabel),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text(okLabel),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
}

Future<String?> showRenameDialog(
  BuildContext context,
  String originalName, {
  required List<String> existingNames,
  required String originalExtension,
}) async {
  final theme = Theme.of(context);
  final dotIdx = originalName.lastIndexOf('.');
  final baseName =
      dotIdx > 0 ? originalName.substring(0, dotIdx) : originalName;
  final ext = dotIdx > 0 ? originalName.substring(dotIdx) : '';
  final controller = TextEditingController(text: baseName);
  String? errorText;
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text('Duplicate File',
              style: TextStyle(color: theme.colorScheme.onSurface)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A file with this name already exists. Please enter a new name:',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'File name',
                          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)), 
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          errorText: errorText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        autofocus: true,
                      ),
                    ),
                    Text(ext, style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface)),
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(null),
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    setState(() => errorText = 'File name cannot be empty');
                    return;
                  }
                  final newFullName = value + ext;
                  // Check for duplicate (case-insensitive, ignore extension)
                  final lowerName = value.toLowerCase();
                  final lowerExisting = existingNames.map((n) {
                    final idx = n.lastIndexOf('.');
                    return (idx > 0 ? n.substring(0, idx) : n).toLowerCase();
                  }).toList();
                  if (lowerExisting.contains(lowerName)) {
                    setState(() =>
                        errorText = 'A file with this name already exists');
                    return;
                  }
                  // Check extension (should always match, but just in case)
                  if (ext.toLowerCase() != originalExtension.toLowerCase()) {
                    setState(() =>
                        errorText = 'You cannot change the file extension');
                    return;
                  }
                  Navigator.of(context).pop(newFullName);
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<String?> showEditBookDialog(
  BuildContext context,
  String originalName, {
  required List<String> existingNames,
}) async {
  final theme = Theme.of(context);
  // Find the last occurrence of .pdf or .epub
  final pdfIdx = originalName.toLowerCase().lastIndexOf('.pdf');
  final epubIdx = originalName.toLowerCase().lastIndexOf('.epub');
  final extIdx = pdfIdx > epubIdx ? pdfIdx : epubIdx;

  final baseName =
      extIdx > 0 ? originalName.substring(0, extIdx) : originalName;
  final ext = extIdx > 0 ? originalName.substring(extIdx) : '';
  final controller = TextEditingController(text: baseName);
  String? errorText;
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text('Rename Book',
              style: TextStyle(color: theme.colorScheme.onSurface)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter a new name for the book:',
                  style: TextStyle(color: theme.colorScheme.onSurface)
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Book name',
                    labelStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    errorText: errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(null),
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    setState(() => errorText = 'Book name cannot be empty');
                    return;
                  }
                  final lowerName = value.toLowerCase();
                  final lowerExisting =
                      existingNames.map((n) => n.toLowerCase()).toList();
                  if (lowerExisting.contains(lowerName)) {
                    setState(() =>
                        errorText = 'A book with this name already exists');
                    return;
                  }
                  Navigator.of(context).pop(value + ext);
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showOkDialog(
  BuildContext context,
  String message, {
  String title = 'Notification',
  String okLabel = 'OK',
}) async {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(title, style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(message, style: TextStyle(color: theme.colorScheme.onSurface)),
        actions: <Widget>[
          TextButton(
            child: Text(okLabel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> showEmailNotVerifiedDialog(BuildContext context) async {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Email Not Verified',
          style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
            'Your email address is not verified. Please check your inbox and verify your email before signing in.',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> showPasswordPolicyDialog(BuildContext context) async {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Password Policy',
          style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
            'Your password does not meet the latest security requirements. Please update your password in the settings.',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> showResetPasswordSentDialog(BuildContext context) async {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Reset Password',
          style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
            'A password reset link has been sent to your email. Please check your inbox.',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> showLoadingDialog(BuildContext context,
    {String message = 'Uploading book...'}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}
