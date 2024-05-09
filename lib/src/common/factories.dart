part of '../../account_abstraction_alchemy.dart';

/// A class that extends [SimpleAccountFactory] and implements [SimpleAccountFactoryBase].
/// It creates an instance of [SimpleAccountFactory] with a custom [RPCBase] client.
/// Used to create instances of [SmartWallet] for simple accounts.
class _SimpleAccountFactory extends SimpleAccountFactory {
  /// Creates a new instance of [_SimpleAccountFactory].
  ///
  /// [address] is the address of the simple account factory.
  /// [chainId] is the ID of the blockchain chain.
  /// [rpc] is the [RPCBase] client used for communication with the blockchain.
  _SimpleAccountFactory({
    required super.address,
    required RPCBase rpc,
    super.chainId,
  }) : super(client: Web3Client.custom(rpc));
}
