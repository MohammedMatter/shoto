import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/routes/app_router.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/core/widgets/shoto_logo.dart';
import 'package:shoto/features/onboarding/domain/entities/onboarding_item.dart';
import 'package:shoto/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:shoto/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:shoto/features/onboarding/presentation/bloc/onboarding_state.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  List<OnboardingItem> items = [];

  @override
  void initState() {
    super.initState();

    _startInfiniteScroll();
  }

  void _startInfiniteScroll() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_scrollController.hasClients && items.isNotEmpty) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;

        if (currentScroll >= maxScroll - 300) {
          _scrollController.jumpTo(0.0);
        } else {
          _scrollController.jumpTo(currentScroll + 0.8);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) =>
            OnboardingBloc(sl())..add(LoadOnboardingDataEvent()),
        child: BlocBuilder<OnboardingBloc, OnboardingState>(
          builder: (context, state) {
            if (state is OnboardingLoadingState) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            } else if (state is OnboardingLoadedState) {
              items = state.items;
              return Stack(
                children: [
                  MasonryGridView.builder(
                    gridDelegate:
                        const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                        ),
                    controller: _scrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final int itemIndex = index % items.length;
                      final item = items[itemIndex];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 10.h,
                          horizontal: 10.w,
                        ),
                        height: item.height.h,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25.r),
                          child: Image.asset(
                            item.imageUrl,
                            fit: BoxFit.fill,
                            width: double.infinity,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(24.w, 80.h, 24.w, 32.h),
                      decoration: const BoxDecoration(
                        gradient: AppColors.scrimGradient,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ShotoLogo(size: 56),
                          SizedBox(height: 16.h),
                          Text('SHOTO', style: AppTextStyles.headlineLarge),
                          SizedBox(height: 8.h),
                          Text(
                            'Save. Organize. Find any screenshot instantly.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium,
                          ),
                          SizedBox(height: 24.h),
                          PrimaryButton(
                            label: 'Get Started',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () =>
                                context.pushNamed(AppRouter.authPage),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Center(child: Text('There is an error'));
            }
          },
        ),
      ),
    );
  }
}
