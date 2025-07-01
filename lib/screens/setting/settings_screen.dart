import 'package:ebook_reader/screens/setting/setting_cubit.dart';
import 'package:ebook_reader/screens/setting/setting_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/settings/font_size_settings.dart';
import '../../widgets/settings/theme_settings.dart';
import '../../widgets/settings/user_account.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static Widget newInstance() => BlocProvider(
    create: (context) => SettingCubit(),
    child: const SettingsScreen(),
  );

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Settings',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: 'Appearance'),
                              Tab(text: 'Account'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Appearance Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Font Size Settings
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Font Size',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Adjust the text size to your preference for better readability',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      const FontSizeSettings(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Theme Settings
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Theme',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Choose between light and dark themes to customize your reading experience',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      const ThemeSettings(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Account Tab
                        BlocProvider(
                          create: (_) => SettingCubit()..fetchUser(),
                          child: BlocListener<SettingCubit, SettingState>(
                            listener: (context, state) {
                              if (state is UserLoggedOut || state.isLoggedOut) {
                                Navigator.pushNamedAndRemoveUntil(
                                    context, '/sign-in', (route) => false);
                              }
                            },
                            child: const SingleChildScrollView(
                              padding: EdgeInsets.all(16.0),
                              child: UserAccount(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
