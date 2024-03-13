import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../main/screens/BankDetailScreen.dart';
import '../../main.dart';
import '../../main/components/BodyCornerWidget.dart';
import '../../main/network/RestApis.dart';
import '../../main/screens/LanguageScreen.dart';
import '../../main/utils/Colors.dart';
import '../../main/utils/Common.dart';
import '../../main/utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../main/screens/AboutUsScreen.dart';
import '../../main/screens/ChangePasswordScreen.dart';
import '../../main/screens/EditProfileScreen.dart';
import '../../main/screens/ThemeScreen.dart';
import '../../main/components/UserCitySelectScreen.dart';
import '../../user/screens/DeleteAccountScreen.dart';
import '../../user/screens/WalletScreen.dart';
import '../screens/EarningHistoryScreen.dart';
import '../screens/VerifyDeliveryPersonScreen.dart';

class DProfileFragment extends StatefulWidget {
  @override
  DProfileFragmentState createState() => DProfileFragmentState();
}

class DProfileFragmentState extends State<DProfileFragment> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    LiveStream().on('UpdateLanguage', (p0) {
      setState(() {});
    });
    LiveStream().on('UpdateTheme', (p0) {
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(language.profile)),
      body: Observer(
        builder: (_) => BodyCornerWidget(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                commonCachedNetworkImage(appStore.userProfile.validate(), height: 90, width: 90, fit: BoxFit.cover, alignment: Alignment.center).cornerRadiusWithClipRRect(50),
                12.height,
                Text(getStringAsync(NAME).validate(), style: boldTextStyle(size: 20)),
                6.height,
                Text(appStore.userEmail, style: secondaryTextStyle(size: 16)),
                16.height,
                ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    settingItemWidget(Icons.person_outline, language.editProfile, () {
                      EditProfileScreen().launch(context);
                    }),
                    settingItemWidget(Icons.assignment_outlined, language.verifyDocument, () {
                      VerifyDeliveryPersonScreen().launch(context);
                    }, suffixIcon: getBoolAsync(IS_VERIFIED_DELIVERY_MAN) ? Icons.verified_user : null),
                    settingItemWidget(Icons.add_card_outlined, language.earningHistory, () {
                      EarningHistoryScreen().launch(context);
                    }),
                    settingItemWidget(Icons.wallet, language.wallet, () {
                      WalletScreen().launch(context);
                    }),
                    settingItemWidget(Icons.credit_card, language.bankDetails, () {
                      BankDetailScreen().launch(context);
                    }),
                    settingItemWidget(Icons.lock_outline, language.changePassword, () {
                      ChangePasswordScreen().launch(context);
                    }),
                    settingItemWidget(Icons.location_on_outlined, language.changeLocation, () {
                      UserCitySelectScreen(isBack: true).launch(context);
                    }),
                    settingItemWidget(Icons.language, language.language, () {
                      LanguageScreen().launch(context);
                    }),
                    settingItemWidget(Icons.wb_sunny_outlined, language.theme, () {
                      ThemeScreen().launch(context);
                    }),
                    settingItemWidget(Icons.assignment_outlined, language.privacyPolicy, () {
                      commonLaunchUrl(mPrivacyPolicy);
                    }),
                    settingItemWidget(Icons.help_outline, language.helpAndSupport, () {
                      commonLaunchUrl(mHelpAndSupport);
                    }),
                    settingItemWidget(Icons.assignment_outlined, language.termAndCondition, () {
                      commonLaunchUrl(mTermAndCondition);
                    }),
                    // settingItemWidget(Icons.info_outline, language.aboutUs, () {
                    //   AboutUsScreen().launch(context);
                    // }),
                    settingItemWidget(Icons.delete_forever, language.deleteAccount, () {
                      DeleteAccountScreen().launch(context);
                    }),
                    settingItemWidget(
                      Icons.logout,
                      language.logout,
                      () async {
                        await showConfirmDialogCustom(
                          context,
                          primaryColor: colorPrimary,
                          title: language.logoutConfirmationMsg,
                          positiveText: language.yes,
                          negativeText: language.no,
                          onAccept: (c) {

                          },
                        );
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
