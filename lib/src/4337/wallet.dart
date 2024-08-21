part of '../../account_abstraction_alchemy.dart';

/// A class that represents a Smart Wallet on an Ethereum-like blockchain.
///
/// The [SmartWallet] class implements the [SmartWalletBase] interface and provides
/// various methods for interacting with the wallet, such as sending transactions,
/// estimating gas, and retrieving balances. It uses various plugins for different
/// functionalities, such as contract interaction, gas estimation, and signing operations.
///
/// The class utilizes the `_PluginManager` and `_GasSettings` mixins for managing plugins
/// and gas settings, respectively.
///
/// Example usage:
///
/// ```dart
/// // Create a new instance of the SmartWallet
/// final wallet = SmartWallet(chain, walletAddress, initCode);
///
/// // Get the wallet balance
/// final balance = await wallet.balance;
///
/// // Send a transaction
/// final recipient = EthereumAddress.fromHex('0x...');
/// final amount = EtherAmount.fromUnitAndValue(EtherUnit.ether, 1);
/// final response = await wallet.send(recipient, amount);
/// ```
class SmartWallet with _PluginManager, _GasSettings implements SmartWalletBase {
  /// The blockchain chain configuration.
  final NetworkConfig _network;

  /// The address of the Smart Wallet.
  final EthereumAddress _walletAddress;

  /// The initialization code for deploying the Smart Wallet contract.
  final Uint8List _initCode;

  /// Creates a new instance of the [SmartWallet] class.
  ///
  /// [_network] is an object representing network configuration.
  /// [_walletAddress] is the address of the Smart Wallet.
  /// [_initCode] is the initialization code for deploying the Smart Wallet contract.
  SmartWallet(this._network, this._walletAddress, this._initCode);

  @override
  EthereumAddress get address => _walletAddress;

  @override
  Future<EtherAmount> get balance =>
      plugin<Contract>('contract').getBalance(_walletAddress);

  @override
  Future<bool> get isDeployed =>
      plugin<Contract>('contract').deployed(_walletAddress);

  @override
  String get initCode => hexlify(_initCode);

  @override
  Future<BigInt> get initCodeGas => _initCodeGas;

  @override
  Future<Uint256> get nonce => _getNonce();

  @override
  String? get toHex => _walletAddress.hexEip55;

  @override
  String get dummySignature => plugin<Signer>('signer').dummySignature;

  /// Returns the estimated gas required for deploying the Smart Wallet contract.
  ///
  /// The gas estimation is performed by interacting with the 'jsonRpc' plugin
  /// and estimating the gas for the initialization code.
  Future<BigInt> get _initCodeGas => plugin<JsonRPCProviderBase>('jsonRpc')
      .estimateGas(_network.entrypoint.address, initCode);

  @override
  UserOperation buildUserOperation({
    required Uint8List callData,
    BigInt? customNonce,
  }) =>
      UserOperation.partial(
          callData: callData,
          initCode: _initCode,
          sender: _walletAddress,
          nonce: customNonce);

  @override
  Future<UserOperationResponse> send(
          EthereumAddress recipient, EtherAmount amount) =>
      sendUserOperation(buildUserOperation(
          callData:
              Contract.execute(_walletAddress, to: recipient, amount: amount)));

  @override
  Future<UserOperationResponse> sendTransaction(
          EthereumAddress to, Uint8List encodedFunctionData,
          {EtherAmount? amount}) =>
      sendUserOperation(buildUserOperation(
          callData: Contract.execute(
        _walletAddress,
        to: to,
        amount: amount,
        innerCallData: encodedFunctionData,
      )));

  @override
  Future<UserOperationResponse> sendBatchedTransaction(
      List<EthereumAddress> recipients, List<Uint8List> calls,
      {List<EtherAmount>? amounts}) {
    return sendUserOperation(buildUserOperation(
        callData: Contract.executeBatch(
            walletAddress: _walletAddress,
            recipients: recipients,
            amounts: amounts,
            innerCalls: calls)));
  }

  @override
  Future<UserOperationResponse> sendSignedUserOperation(UserOperation op) =>
      plugin<BundlerProviderBase>('bundler')
          .sendUserOperation(op.toMap(_network.entrypoint.version),
              _network.entrypoint, dropAndReplaceUserOperation)
          .catchError((e) => throw SendError(e.toString(), op));

  @override
  Future<UserOperationResponse> sendUserOperation(UserOperation op) =>
      prepareUserOperation(op)
          .then(signUserOperation)
          .then(sendSignedUserOperation);

  @override
  Future<UserOperation> prepareUserOperation(UserOperation op,
      {bool update = true, bool shouldPaymasterIntercept = true}) async {
    // Update the user operation with the latest nonce and gas prices if needed
    if (update) {
      op = await _updateUserOperation(op);
    }

    if (shouldPaymasterIntercept) {
      // intercept the user operation to populate gas data and sponsor tx
      op = await plugin<Paymaster>('paymaster').interceptToSponsor(op);
    }

    // Validate the user operation
    op.validate(op.nonce > BigInt.zero, _network.entrypoint.version, initCode);

    return op;
  }

  @override
  Future<BigInt> estimateGasForSingleOperation(
      EthereumAddress to, Uint8List encodedFunctionData,
      {EtherAmount? amount}) async {
    final op = buildUserOperation(
        callData: Contract.execute(
      _walletAddress,
      to: to,
      amount: amount,
      innerCallData: encodedFunctionData,
    ));

    return _estimateGas(op);
  }

  @override
  Future<BigInt> estimateGasForBatchedOperation(
      List<EthereumAddress> recipients, List<Uint8List> calls,
      {List<EtherAmount>? amounts}) async {
    final op = buildUserOperation(
        callData: Contract.executeBatch(
            walletAddress: _walletAddress,
            recipients: recipients,
            amounts: amounts,
            innerCalls: calls));

    return _estimateGas(op);
  }

  @override
  Future<UserOperation> signUserOperation(
    UserOperation op,
  ) async {
    // Calculate the operation hash
    final opHash = op.hash(_network);

    // Sign the operation hash using the 'signer' plugin
    final signature = await plugin<Signer>('signer').personalSign(opHash);
    final signatureHex = hexlify(signature);

    // Append the signature validity period
    op.signature = signatureHex;

    return op;
  }

  @override
  Future<ReplaceUserOperationResult> dropAndReplaceUserOperation(
      String opHash) async {
    final bundler = plugin<BundlerProviderBase>('bundler');
    final opToDrop = await bundler.getUserOperationByHash(opHash);

    final paymaster = plugin<Paymaster>('paymaster');
    final interceptedOp = await paymaster.interceptToDropReplace(opToDrop);
    final signedOp = await signUserOperation(interceptedOp);

    final receipt = await bundler.getUserOpReceipt(opHash);

    if (receipt != null) {
      return ReplaceUserOperationReceipt(receipt);
    }

    final response = await sendSignedUserOperation(signedOp);

    return ReplaceUserOperationResponse(response);
  }

  /// Returns the nonce for the Smart Wallet address.
  ///
  /// If the wallet is not deployed, returns 0.
  /// Otherwise, retrieves the nonce by calling the 'getNonce' function on the entrypoint.
  ///
  /// If an error occurs during the nonce retrieval process, a [NonceError] exception is thrown.
  Future<Uint256> _getNonce() => isDeployed.then((deployed) => !deployed
      ? Future.value(Uint256.zero)
      : plugin<Contract>("contract")
          .read(_network.entrypoint.address, ContractAbis.get('getNonce'),
              'getNonce',
              params: [_walletAddress, BigInt.zero])
          .then((value) => Uint256(value[0]))
          .catchError((e) => throw NonceError(e.toString(), _walletAddress)));

  /// Updates the user operation with the latest nonce and gas prices.
  ///
  /// [op] is the user operation to update.
  ///
  /// Returns a [Future] that resolves to the updated [UserOperation] object.
  Future<UserOperation> _updateUserOperation(UserOperation op) =>
      Future.wait<dynamic>([
        _getNonce(),
      ]).then((responses) {
        op = op.copyWith(
            version: _network.entrypoint.version,
            nonce: op.nonce > BigInt.zero ? op.nonce : responses[0].value,
            initCode: responses[0] > Uint256.zero ? Uint8List(0) : null,
            signature: dummySignature);

        return op;
      });

  /// Returns transaction fee price
  Future<BigInt> _estimateGas(UserOperation op) async {
    final preparedOp =
        await prepareUserOperation(op, shouldPaymasterIntercept: false);

    final res = await plugin<BundlerProviderBase>('bundler')
        .estimateTransactionFee(preparedOp, _network.entrypoint);

    return res;
  }
}
