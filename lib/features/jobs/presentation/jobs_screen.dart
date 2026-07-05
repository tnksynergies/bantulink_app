import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/branding/brand.dart';
import '../../../core/i18n/app_localizations.dart';
import 'offers_list_view.dart';
import 'my_candidatures_view.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const BrandLogo(BrandWorld.hire, height: 26),
          centerTitle: false,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: context.tr('jobs.offers')),
              Tab(text: context.tr('jobs.my_applications')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OffersListView(),
            MyCandidaturesView(),
          ],
        ),
      ),
    );
  }
}
