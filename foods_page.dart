import 'dart:ui';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart' as extended;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:our_pizza/core/injection/injection.dart';
import 'package:our_pizza/core/presentation/widgets/bottom_sheets/alert_bottom_sheet.dart';
import 'package:our_pizza/core/presentation/widgets/builders/scroll_controller_builder.dart';
import 'package:our_pizza/core/presentation/widgets/builders/tab_controller_builder.dart';
import 'package:our_pizza/core/presentation/widgets/buttons/my_ink_well.dart';
import 'package:our_pizza/core/presentation/widgets/buttons/responsive_elevation_button.dart';
import 'package:our_pizza/core/presentation/widgets/indicators/loader.dart';
import 'package:our_pizza/extensions.dart';
import 'package:our_pizza/features/auth/infrastructure/fields/phone_field.dart';
import 'package:our_pizza/features/auth/presentation/blocs/location/location_bloc.dart';
import 'package:our_pizza/features/auth/presentation/blocs/profile/profile_bloc.dart';
import 'package:our_pizza/features/foods/infrastructure/models/internal/food_section.dart';
import 'package:our_pizza/features/foods/infrastructure/models/internal/type_sorting.dart';
import 'package:our_pizza/features/foods/presentation/blocs/food/food_bloc.dart';
import 'package:our_pizza/features/foods/presentation/pages/food_section_page.dart';
import 'package:our_pizza/features/navigation/presentation/blocs/navigation/navigation_bloc.dart';
import 'package:our_pizza/features/navigation/presentation/widgets/navigation_drawer.dart';
import 'package:our_pizza/generated/l10n.dart';
import 'package:our_pizza/ui.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodsPage extends StatefulWidget {
  const FoodsPage({Key? key}) : super(key: key);

  @override
  _FoodsPageState createState() => _FoodsPageState();
}

class _FoodsPageState extends State<FoodsPage> {
  final _bucket = PageStorageBucket();
  final _keys = FoodSection.values.map((e) => e.key).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavigationDrawer(),
      body: TabControllerBuilder(
        length: FoodSection.values.length,
        builder: (context, tabController) =>
            ScrollControllerBuilder(
              builder: (context, scrollController) =>
                  extended.NestedScrollView(
                    controller: scrollController,
                    pinnedHeaderSliverHeightBuilder: () {
                      return kToolbarHeight + MediaQuery
                          .of(context)
                          .padding
                          .top;
                    },
                    innerScrollPositionKeyBuilder: () {
                      return _keys[tabController.index];
                    },
                    headerSliverBuilder: (context, scrolled) =>
                    [
                      _buildAppBar(context, scrolled: scrolled),
                      _buildSectionTabBar(
                          context, tabController, scrolled ?? false),
                    ],
                    body: PageStorage(
                      bucket: _bucket,
                      child: TabBarView(
                        controller: tabController,
                        physics: const BouncingScrollPhysics(),
                        children: FoodSection.values.map((section) {
                          return extended
                              .NestedScrollViewInnerScrollPositionKeyWidget(
                            section.key,
                            FoodSectionPage(
                              key: section.key,
                              section: section,
                              onTap: getIt<ProfileBloc>().pickProduct,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
            ),
      ),
      bottomNavigationBar: _buildBottomButton(context),
      floatingActionButton: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          final isValidPhone = PhoneField(state.current?.phone ?? '').isValid;
          return Visibility(
            maintainSize: isValidPhone,
            maintainState: isValidPhone,
            maintainAnimation: isValidPhone,
            child: FloatingActionButton(
              backgroundColor: Colors.black,
              onPressed: () => launch('tel:${state.current?.phone}'),
              child: const FaIcon(
                FontAwesomeIcons.phone,
              ),
            ),
          );
        },
      ),
    );
  }

  /*
      return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        final isValidPhone = PhoneField(state.current?.phone ?? '').isValid;
        return Visibility(
          maintainSize: isValidPhone,
          maintainState: isValidPhone,
          maintainAnimation: isValidPhone,
          child: IconButton(
            padding: const EdgeInsets.only(right: 8),
            onPressed: () => launch('tel:${state.current?.phone}'),
            icon: const FaIcon(
              FontAwesomeIcons.phone,
            ),
          ),
        );
      },
    );
  */

  Widget _buildBottomButton(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        return Visibility(
          visible: state.order.products.isNotEmpty,
          child: SafeArea(
            child: IgnorePointer(
              ignoring: state.isLoading,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(thickness: 1.0, height: 1.0),
                  Container(
                    color: Theme
                        .of(context)
                        .backgroundColor,
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(elevation: 8),
                      onPressed: getIt<NavigationBloc>().showCart,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: state.isLoading
                            ? const Loader(color: Colors.white)
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(S
                                  .of(context)
                                  .cart),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white30,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${state.order.count}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(state.order.toTotalString()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTabBar(BuildContext context,
      TabController tabController,
      bool forceElevated,) {
    const barHeight = kToolbarHeight;
    const lineHeight = 4.0;
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: SliverAppBar(
        leading: const SizedBox(),
        leadingWidth: 0.0,
        titleSpacing: 0.0,
        expandedHeight: 0.0,
        forceElevated: forceElevated,
        title: Container(
          color: Theme
              .of(context)
              .backgroundColor,
          height: barHeight,
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              // margin: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 20.0),
              child: Container(
                height: 40,
                width: 40,
                margin: EdgeInsets.only(left: 2.0, top: 8),
                child: _buildSortingButton(context),
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: 0.0),
                height: barHeight,
                child: TabBar(
                  isScrollable: true,
                  controller: tabController,
                  indicator: ShapeDecoration(
                    color: Theme
                        .of(context)
                        .accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(lineHeight * 0.5),
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Theme
                      .of(context)
                      .accentColor,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  indicatorPadding:
                  const EdgeInsets.only(top: barHeight - lineHeight),
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: FoodSection.values
                      .map((e) => Tab(text: e.displayText(context)))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),);
  }

  Widget _buildAppBar(BuildContext context, {bool? scrolled}) {
    return SliverAppBar(
      leadingWidth: kToolbarHeight,
      centerTitle: true,
      floating: true,
      elevation: 0.0,
      leading: Builder(
        builder: (context) =>
            IconButton(
              onPressed: Scaffold
                  .of(context)
                  .openDrawer,
              icon: const FaIcon(
                FontAwesomeIcons.bars,
              ),
            ),
      ),
      // title: _buildProfileTitle(context),
      title: AnimatedOpacity(
        opacity: scrolled ?? false ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: _buildProfileButton(context),
      ),
      actions: [
        _buildBonusButton(context),
      ],
    );
  }

  Widget _buildSortingButton(BuildContext context) {
    const buttonHeight = kToolbarHeight * 0.6;
    final borderRadius = BorderRadius.circular(buttonHeight * 0.5);
    final itemsA = <String>[
      S.current.popularity,
      S.current.lower_price,
      S.current.upper_price
    ];

    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (_, state) => PopupMenuButton(
          icon: Image.asset(PizzaAssets.sortingLogo),
          color: Colors.white,
          elevation: 14,
          shape: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: Colors.grey, width: 0)),
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () {
                getIt<FoodBloc>().sortingFoodsInTab(TypeSorting.popularity);
                setState(() {});
              },
              child: Center(
                child: Text(itemsA[0]),
              ),
            ),
            PopupMenuItem(
              onTap: () {
                getIt<FoodBloc>()
                    .sortingFoodsInTab(TypeSorting.lower_price);
                setState(() {});
              },
              child: Center(
                child: Text(itemsA[1]),
              ),
            ),
            PopupMenuItem(
              onTap: () {
                getIt<FoodBloc>()
                    .sortingFoodsInTab(TypeSorting.upper_price);
                setState(() {});
              },
              child: Center(
                child: Text(itemsA[2]),
              ),
            ),
          ]),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    const buttonHeight = kToolbarHeight * 0.6;
    final borderRadius = BorderRadius.circular(buttonHeight * 0.5);

    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (_, state) =>
          ResponsiveElevationButton(
            elevationMax: 4,
            borderRadius: borderRadius,
            onTap: state.isSignedIn
                ? getIt<NavigationBloc>().showProfile
                : getIt<NavigationBloc>().signIn,
            builder: (_, elevation, child) =>
                Material(
                  shadowColor: Colors.black,
                  borderRadius: borderRadius,
                  elevation: elevation,
                  child: child,
                ),
            child: Container(
              height: buttonHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: Theme
                    .of(context)
                    .accentColor,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      state.isSignedIn ? state.profile.name | S
                          .of(context)
                          .profile : S
                          .of(context)
                          .signIn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildBonusButton(BuildContext cotnext) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state.user?.isAnonymous ?? true) {
          return const SizedBox();
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () {
              showAlertBottomSheet(
                context,
                title: Text('Бонусные рубли'),
                body: Text(
                    'Бонусы начисляются после заказа. Их можно использовать в виде скидки при следующем заказе. На вашем счету ${state
                        .maxScore} бонусных рублей.'),
                button: Text(S.current.understood),
              );
              //!
            },
            child: Row(
              children: [
                Text(
                  state.maxScore.toString(),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const FaIcon(
                  FontAwesomeIcons.rubleSign,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneButton(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        final isValidPhone = PhoneField(state.current?.phone ?? '').isValid;
        return Visibility(
          maintainSize: isValidPhone,
          maintainState: isValidPhone,
          maintainAnimation: isValidPhone,
          child: IconButton(
            padding: const EdgeInsets.only(right: 8),
            onPressed: () => launch('tel:${state.current?.phone}'),
            icon: const FaIcon(
              FontAwesomeIcons.phone,
            ),
          ),
        );
      },
    );
  }
}
