import 'package:metanoniawallet/qrcode_page.dart';
import 'package:metanoniawallet/qrcode_reader_page.dart';
import 'package:metanoniawallet/service/configuration_service.dart';
import 'package:metanoniawallet/wallet_create_page.dart';
import 'package:metanoniawallet/wallet_import_page.dart';
import 'package:metanoniawallet/wallet_main_page.dart';
import 'package:metanoniawallet/wallet_transfer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import 'context/wallet/wallet_provider.dart';
import 'context/setup/wallet_setup_provider.dart';
import 'context/transfer/wallet_transfer_provider.dart';
import 'intro_page.dart';

Map<String, WidgetBuilder> getRoutes(context) {
  return {
    '/': (BuildContext context) {
      var configurationService = Provider.of<ConfigurationService>(context);
      if (configurationService.didSetupWallet())
        return WalletProvider(builder: (context, store) {
          return WalletMainPage("Metanonia");
        });

      return IntroPage();
    },
    '/create': (BuildContext context) =>
        WalletSetupProvider(builder: (context, store) {
          useEffect(() {
            store.generateMnemonic();
            return null;
          }, []);

          return WalletCreatePage("Create wallet");
        }),
    '/import': (BuildContext context) => WalletSetupProvider(
          builder: (context, store) {
            return WalletImportPage("Import wallet");
          },
        ),
    '/transfer': (BuildContext context) => WalletTransferProvider(
          builder: (context, store) {
            return WalletTransferPage(title: "Send Tokens");
          },
        ),
    '/qrcode_reader': (BuildContext context) => QRCodePage(
          title: "Scan QRCode",
        ),
  };
}
