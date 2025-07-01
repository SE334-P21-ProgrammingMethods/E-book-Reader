import 'package:ebook_reader/screens/auth/sign-up/signup_cubit.dart';
import 'package:ebook_reader/screens/auth/sign-up/signup_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../enums/processing/process_state_enum.dart';
import '../../../widgets/components/dialog_utils.dart';
import '../sign-in/signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  final Function toggleTheme;

  const SignUpScreen({super.key, required this.toggleTheme});

  static Widget newInstance({required void Function() toggleTheme}) =>
      BlocProvider(
        create: (context) => SignupCubit(),
        child: SignUpScreen(toggleTheme: toggleTheme),
      );

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  SignupCubit get cubit => context.read<SignupCubit>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // void _handleSignUp() {
  //   if (_passwordController.text != _confirmPasswordController.text) {
  //     setState(() {
  //       _errorMessage = "Passwords do not match";
  //     });
  //     return;
  //   }
  //   context.read<SignupCubit>().signUp(
  //         name: _nameController.text.trim(),
  //         email: _emailController.text.trim(),
  //         password: _passwordController.text,
  //       );
  // }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<SignupCubit, SignupState>(
      listener: (context, state) async {
        if (state.processState == ProcessState.success) {
          await showOkDialog(
            context,
            state.message,
            title: 'Verify Your Email',
            okLabel: 'OK',
          );
          cubit.toIdle();
          Navigator.pushNamedAndRemoveUntil(
              context, '/sign-in', (route) => false);
        } else if (state.processState == ProcessState.failure) {
          await showOkDialog(
            context,
            state.message,
            title: 'Error Signing Up',
            okLabel: 'OK',
          );
          cubit.toIdle();
        }
      },
    builder: (context, state) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Account',
                        style: Theme
                            .of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: colorScheme.primary,
                        ),
                        onPressed: () => widget.toggleTheme(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Icon(
                    Icons.person_add_outlined,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Join E-Book Reader to access your books anywhere',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (state.message.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        state.message,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  if (state.message.isNotEmpty) const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _nameController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Your name',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: colorScheme.brightness ==
                                        Brightness.dark
                                        ? Colors.white
                                        : Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _emailController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'your@email.com',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: colorScheme.brightness ==
                                        Brightness.dark
                                        ? Colors.white
                                        : Colors.grey),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: colorScheme.brightness ==
                                        Brightness.dark
                                        ? Colors.white
                                        : Colors.grey),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(_showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirm Password',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _confirmPasswordController,
                            obscureText: !_showConfirmPassword,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: colorScheme.brightness ==
                                        Brightness.dark
                                        ? Colors.white
                                        : Colors.grey),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(_showConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _showConfirmPassword =
                                    !_showConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: state.processState == ProcessState.loading ? null : () {
                      // Validate all fields are filled
                      if (_nameController.text.trim().isEmpty) {
                        cubit.toFailure('Please enter your name');
                        return;
                      }

                      // Email validation
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        cubit.toFailure('Please enter your email address');
                        return;
                      }

                      // Email format validation using regex
                      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(email)) {
                        cubit.toFailure('Please enter a valid email address');
                        return;
                      }

                      // Password validation
                      final password = _passwordController.text;
                      if (password.isEmpty) {
                        cubit.toFailure('Please enter a password');
                        return;
                      }

                      // Password length check
                      if (password.length < 6) {
                        cubit.toFailure('Password must be at least 6 characters long');
                        return;
                      }

                      // Password strength validation
                      final hasUppercase = password.contains(RegExp(r'[A-Z]'));
                      final hasLowercase = password.contains(RegExp(r'[a-z]'));
                      final hasDigit = password.contains(RegExp(r'[0-9]'));
                      final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

                      if (!hasUppercase) {
                        cubit.toFailure('Password must contain at least one uppercase letter');
                        return;
                      }

                      if (!hasLowercase) {
                        cubit.toFailure('Password must contain at least one lowercase letter');
                        return;
                      }

                      if (!hasDigit) {
                        cubit.toFailure('Password must contain at least one number');
                        return;
                      }

                      if (!hasSpecialChar) {
                        cubit.toFailure('Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)');
                        return;
                      }

                      if (_confirmPasswordController.text.isEmpty) {
                        cubit.toFailure('Please confirm your password');
                        return;
                      }

                      if (password != _confirmPasswordController.text) {
                        cubit.toFailure('Passwords do not match');
                        return;
                      }

                      // All validations passed, proceed with signup
                      cubit.signUp(
                        name: _nameController.text.trim(),
                        email: email,
                        password: password,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: state.processState == ProcessState.loading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                        : const Text('Sign Up'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SignInScreen.newInstance(
                                    toggleTheme: () => widget.toggleTheme(),
                                  ),
                            ),
                                (route) => false,
                          );
                        },
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    );
  }
}
