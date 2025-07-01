import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../screens/setting/setting_cubit.dart';
import '../../screens/setting/setting_state.dart';

class UserAccount extends StatefulWidget {
  const UserAccount({super.key});

  @override
  State<UserAccount> createState() => _UserAccountState();
}

class _UserAccountState extends State<UserAccount> {
  final GlobalKey _avatarMenuKey = GlobalKey();

  void _showEditNameSheet(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    final userCubit = context.read<SettingCubit>();
    String? errorText;

    void showResultDialog(String title, String message) {
      final theme = Theme.of(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(title,
              style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text(message,
              style: TextStyle(color: theme.colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Account Info',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)), 
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      ),
                    ),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    onChanged: (_) {
                      if (errorText != null) {
                        setState(() => errorText = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final newName = controller.text.trim();

                            // Validate input
                            if (newName.isEmpty) {
                              setState(() => errorText = 'Username cannot be empty');
                              return;
                            }

                            if (newName == currentName) {
                              Navigator.pop(context);
                              return;
                            }

                            // Close the bottom sheet
                            Navigator.pop(context);

                            try {
                              // Update the name
                              await userCubit.updateName(newName);

                              // Refresh user data
                              await userCubit.fetchUser();

                              // Show success dialog
                              showResultDialog(
                                'Success',
                                'Your username has been updated successfully.',
                              );
                            } catch (e) {
                              // Close loading dialog if open
                              Navigator.pop(context);

                              // Show error dialog
                              showResultDialog(
                                'Error',
                                'Failed to update username: ${e.toString()}',
                              );
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPasswordResetInfo(BuildContext context) async {
    await context.read<SettingCubit>().sendPasswordReset();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Account Info',
          style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
            'A password reset link will be sent to your email. Please check your inbox.',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAvatarDetail(BuildContext context, String? avatarUrl) {
    if (avatarUrl == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(avatarUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatarFromCamera(BuildContext context) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) {
      final file = File(picked.path);
      await context.read<SettingCubit>().uploadAvatar(file);
      await context.read<SettingCubit>().fetchUser();
    }
  }

  Future<void> _pickAvatarFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final file = File(picked.path);
      await context.read<SettingCubit>().uploadAvatar(file);
      await context.read<SettingCubit>().fetchUser();
    }
  }

  void _showAvatarMenu(BuildContext context) async {
    final RenderBox button =
        _avatarMenuKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset position =
        button.localToGlobal(Offset.zero, ancestor: overlay);
    final Size size = button.size;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'camera',
          child: ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Take a photo'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'gallery',
          child: ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choose from gallery'),
          ),
        ),
      ],
    );
    if (result == 'camera') {
      await _pickAvatarFromCamera(context);
    } else if (result == 'gallery') {
      await _pickAvatarFromGallery(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userCubit = context.read<SettingCubit>();
    String userId = userCubit.state.uid;
    if (userId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid;
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        }
        final data = snapshot.data?.data();
        final name = data?['name'] ?? userCubit.state.name;
        final avatarUrl = data?['avatarUrl'] ?? userCubit.state.avatarUrl;
        final email = data?['email'] ?? userCubit.state.email;
        return BlocBuilder<SettingCubit, SettingState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(child: Text('Error: \\${state.error}'));
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: () => _showAvatarDetail(context, avatarUrl),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Icon(Icons.person,
                                    size: 48, color: theme.colorScheme.primary)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: theme.colorScheme.surface,
                            shape: const CircleBorder(),
                            child: InkWell(
                              key: _avatarMenuKey,
                              customBorder: const CircleBorder(),
                              onTap: () => _showAvatarMenu(context),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.camera_alt_outlined,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.grey[800],
                                    size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface
                    )
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: theme.brightness == Brightness.dark
                          ? const BorderSide(color: Colors.white)
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Text(
                        email,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: email.length > 30 ? 13 : null,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: theme.brightness == Brightness.dark
                                ? const BorderSide(color: Colors.white)
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            leading: Icon(Icons.edit,
                                color: theme.colorScheme.primary),
                            title: const Text("Change username"),
                            onTap: () => _showEditNameSheet(context, name),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: theme.brightness == Brightness.dark
                                ? const BorderSide(color: Colors.white)
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            leading: Icon(Icons.lock_reset,
                                color: theme.colorScheme.primary),
                            title: const Text("Reset password"),
                            onTap: () => _showPasswordResetInfo(context),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: theme.brightness == Brightness.dark
                                ? const BorderSide(color: Colors.white)
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            leading: Icon(Icons.logout,
                                color: theme.colorScheme.error),
                            title: const Text('Logout'),
                            onTap: () {
                              context.read<SettingCubit>().logout();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
