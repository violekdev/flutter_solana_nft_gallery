import 'package:solana/solana.dart';

class Workspace {
  final systemProgramId = Ed25519HDPublicKey.fromBase58(SystemProgram.programId);

  Future<void> workspace(SolanaClient solanaClient) async {}
}
