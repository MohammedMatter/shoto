import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/routes/app_router.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/shoto_logo.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_event.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_state.dart';
import 'package:shoto/features/auth/presentation/widgets/social_sign_in_button.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});
  bool get _showAppleButton => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: Scaffold(
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccessState) {
              context.goNamed(AppRouter.homePage);
            } else if (state is AuthErrorState) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
            }
          },
          builder: (context, state) {
            final bool isGoogleLoading =
                state is AuthLoadingState && state.method == AuthMethod.google;
            final bool isAppleLoading =
                state is AuthLoadingState && state.method == AuthMethod.apple;

            return Stack(
              fit: StackFit.expand,
              children: [
                const _AuthBackground(),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        const Spacer(flex: 3),
                        const ShotoLogo(size: 76),
                        SizedBox(height: 20.h),
                        Text(
                          'Welcome to SHOTO',
                          style: AppTextStyles.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          'Sign in to save, organize and find every\nscreenshot in one place.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const Spacer(flex: 4),
                        SocialSignInButton(
                          label: 'Continue with Google',
                          icon: FaIcon(FontAwesomeIcons.google),
                          isLoading: isGoogleLoading,
                          onPressed: () => context.read<AuthBloc>().add(
                            SignInWithGoogleEvent(),
                          ),
                        ),
                        if (_showAppleButton) ...[
                          SizedBox(height: 14.h),
                          SocialSignInButton(
                            label: 'Continue with Apple',
                            icon: const Icon(
                              Icons.apple,
                              color: Colors.white,
                              size: 22,
                            ),
                            isLoading: isAppleLoading,
                            onPressed: () => context.read<AuthBloc>().add(
                              SignInWithAppleEvent(),
                            ),
                          ),
                        ],
                        SizedBox(height: 20.h),
                        Text(
                          'By continuing, you agree to our Terms of\nService and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption,
                        ),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.background);
  }
}
