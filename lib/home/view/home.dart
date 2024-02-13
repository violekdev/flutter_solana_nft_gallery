import 'package:flutter/material.dart';
import 'package:flutter_solana_nft_gallery/home/src/api.dart';
import 'package:solana/base58.dart';
import 'package:solana/solana.dart';
import 'package:solana_mobile_client/solana_mobile_client.dart';

Workspace workspace = Workspace();

class SolanaGalleryHomeView extends StatefulWidget {
  const SolanaGalleryHomeView({super.key});

  @override
  State<SolanaGalleryHomeView> createState() => _SolanaGalleryHomeViewState();
}

class _SolanaGalleryHomeViewState extends State<SolanaGalleryHomeView> {
  late AuthorizationResult? _result;
  int _accountBalance = 0;
  String userPubKey = '';
  late MobileWalletAdapterClient client;
  final solanaClient = SolanaClient(
    rpcUrl: Uri.parse('https://api.devnet.solana.com'),
    websocketUrl: Uri.parse('wss://api.devnet.solana.com'),
  );
  final int lamportsPerSol = 1000000000;

  @override
  void initState() {
    super.initState();
    (() async {
      _result = null;
      if (!await LocalAssociationScenario.isAvailable()) {
        debugPrint('No MWA Compatible wallet available; please install a wallet');
      } else {
        debugPrint('FOUND MWA WALLET');
        await authorizeUser();
        await getSOLBalance();
      }
    })();
  }

  Future<void> authorizeUser() async {
    /// step 1
    final localScenario = await LocalAssociationScenario.create();
    try {
      /// step 2
      localScenario.startActivityForResult(null).ignore();

      /// step 3
      client = await localScenario.start();

      /// step 4
      final result = await client.authorize(
        identityUri: Uri.parse('https://solanagallery.example.com'),
        iconUri: Uri.parse('favicon.ico'),
        identityName: 'Flutter Solana Gallery',
        cluster: 'devnet',
      );

      setState(() {
        _result = result;
      });
      pubKey();
      await getSOLBalance();
    } on Exception catch (e) {
      debugPrint(e.toString());
    } finally {
      await localScenario.close();
    }
  }

  Future<void> deauthorizeUser() async {
    try {
      await client.deauthorize(authToken: _result!.authToken);

      setState(() {
        _result = null;
        _accountBalance = 0;
      });
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  void pubKey() {
    userPubKey = (_result != null) ? '${base58encode(_result!.publicKey).substring(0, 12)}...' : '';
  }

  Future<void> requestAirDrop() async {
    try {
      await solanaClient.requestAirdrop(
        /// Ed25519HDPublicKey is the main class that represents public
        /// key in the solana dart library
        address: Ed25519HDPublicKey(
          _result!.publicKey.toList(),
        ),
        lamports: 1 * lamportsPerSol,
      );
      await getSOLBalance();
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> getSOLBalance() async {
    try {
      debugPrint('get balance');
      final balance = await solanaClient.rpcClient.getBalance(
        base58encode(_result!.publicKey),
      );
      debugPrint('balance${balance.value}');
      setState(() {
        _accountBalance = balance.value;
      });
    } catch (e) {
      debugPrint('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Solana Gallery'),
          centerTitle: true,
          actions: [
            ElevatedButton(
              onPressed: (_result == null) ? authorizeUser : deauthorizeUser,
              child: Text((_result == null) ? 'Sign in' : 'Sign out'),
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  userPubKey,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  (_accountBalance / lamportsPerSol).toStringAsPrecision(8),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: screenSize.width * 0.02,
                  children: [
                    ElevatedButton(
                      onPressed: requestAirDrop,
                      child: const Text('Request Airdrop'),
                    ),
                    ElevatedButton(
                      onPressed: getSOLBalance,
                      child: const Text('Request Balance'),
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
