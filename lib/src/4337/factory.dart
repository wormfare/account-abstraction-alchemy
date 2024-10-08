part of '../../account_abstraction_alchemy.dart';

enum AccountType {
  simple,
  light,
}

/// A factory class for creating various types of Ethereum smart wallets.
class SmartWalletFactory implements SmartWalletFactoryBase {
  final NetworkConfig _networkConfig;
  final Signer _signer;

  final num preVerificationGasMultiplier;
  final num maxFeePerGasMultiplier;
  final num maxPriorityFeePerGasMultiplier;
  final num callGasLimitMultiplier;
  final num verificationGasLimitMultiplier;
  final http.Client httpClient;

  late final JsonRPCProvider _jsonRpc;
  late final BundlerProvider _bundler;
  late final Contract _contract;

  /// Creates a new instance of the [SmartWalletFactory] class.
  ///
  /// [_networkConfig] is the network configuration.
  /// [_signer] is the signer instance used for signing transactions.
  ///
  /// Multiplier values can be passed to adjust the gas and fee calculations.
  SmartWalletFactory(
    this._networkConfig,
    this._signer, {
    this.preVerificationGasMultiplier = 3,
    this.maxFeePerGasMultiplier = 3,
    this.maxPriorityFeePerGasMultiplier = 3,
    this.callGasLimitMultiplier = 3,
    this.verificationGasLimitMultiplier = 3,
    http.Client? httpClient,
  })  : httpClient = httpClient ?? http.Client(),
        _jsonRpc = JsonRPCProvider(_networkConfig, httpClient),
        _bundler = BundlerProvider(_networkConfig, httpClient) {
    _contract = Contract(_jsonRpc.rpc);
  }

  /// A getter for the SimpleAccountFactory contract instance.
  _SimpleAccountFactory get _simpleAccountFactory => _SimpleAccountFactory(
      address: _networkConfig.accountFactory,
      chainId: _networkConfig.chainId,
      rpc: _jsonRpc.rpc);

  /// A getter for the LightAccountFactory contract instance.
  _LightAccountFactory get _lightAccountFactory => _LightAccountFactory(
      address: _networkConfig.accountFactory,
      chainId: _networkConfig.chainId,
      rpc: _jsonRpc.rpc);

  @override
  Future<SmartWallet> createSimpleAccount(Uint256 salt) async {
    if ((_networkConfig.accountType != AccountType.simple)) {
      throw Exception("Set account type to simple in network config");
    }
    assert(_networkConfig.accountType == AccountType.simple,
        'Set account type to simple in network config');

    final signer = EthereumAddress.fromHex(_signer.getAddress());

    // Get the predicted address of the simple account
    final address = await _simpleAccountFactory
        .getAddress((owner: signer, salt: salt.value));

    // Encode the call data for the `createAccount` function
    // This function is used to create the simple account with the given signer address and salt
    final initCalldata = _simpleAccountFactory.self
        .function('createAccount')
        .encodeCall([signer, salt.value]);

    // Generate the initialization code by combining the account factory address and the encoded call data
    final initCode = _getInitCode(initCalldata);

    // Create the SmartWallet instance for the simple account
    return _createAccount(_networkConfig, address, initCode);
  }

  @override
  Future<SmartWallet> createLightAccount(Uint256 salt) async {
    if (_networkConfig.accountType != AccountType.light) {
      throw Exception('Set account type to light in network config');
    }
    final signer = EthereumAddress.fromHex(_signer.getAddress());
    // Get the predicted address of the light account
    final address = await _lightAccountFactory
        .getAddress((owner: signer, salt: salt.value));

    // Encode the call data for the `createAccount` function
    // This function is used to create the simple account with the given signer address and salt
    final initCalldata = _lightAccountFactory.self
        .function('createAccount')
        .encodeCall([signer, salt.value]);

    // Generate the initialization code by combining the account factory address and the encoded call data
    final initCode = _getInitCode(initCalldata);

    // Create the SmartWallet instance for the light account
    return _createAccount(_networkConfig, address, initCode);
  }

  /// Creates a new [SmartWallet] instance with the provided network, address, and initialization code.
  ///
  /// [networkConfig] is the network configuration.
  /// [address] is the Ethereum address of the account.
  /// [initCalldata] is the initialization code for the account.
  ///
  /// The [SmartWallet] instance is created with various plugins added to it, including:
  /// - [Signer] signer plugin
  /// - [BundlerProviderBase] bundler plugin
  /// - [JsonRPCProviderBase] JSON-RPC provider plugin
  /// - [Contract] contract plugin
  ///
  /// Returns a [SmartWallet] instance representing the created account.
  SmartWallet _createAccount(NetworkConfig networkConfig,
      EthereumAddress address, Uint8List initCalldata) {
    final wallet = SmartWallet(networkConfig, address, initCalldata)
      ..addPlugin<Signer>('signer', _signer)
      ..addPlugin<BundlerProviderBase>('bundler', _bundler)
      ..addPlugin<JsonRPCProviderBase>('jsonRpc', _jsonRpc)
      ..addPlugin<Contract>('contract', _contract)
      ..addPlugin<PaymasterBase>(
        'paymaster',
        Paymaster(
          networkConfig,
          preVerificationGasMultiplier: preVerificationGasMultiplier,
          maxFeePerGasMultiplier: maxFeePerGasMultiplier,
          maxPriorityFeePerGasMultiplier: maxPriorityFeePerGasMultiplier,
          callGasLimitMultiplier: callGasLimitMultiplier,
          verificationGasLimitMultiplier: verificationGasLimitMultiplier,
        ),
      );

    return wallet;
  }

  /// Returns the initialization code for the account by concatenating the account factory address with the provided initialization call data.
  ///
  /// [initCalldata] is the initialization call data for the account.
  ///
  /// The initialization code is required to create the account on the client-side. It is generated by combining the account factory address and the encoded call data for the account creation function.
  ///
  /// Returns a [Uint8List] containing the initialization code.
  Uint8List _getInitCode(Uint8List initCalldata) {
    final List<int> extended =
        _networkConfig.accountFactory.addressBytes.toList();
    extended.addAll(initCalldata);
    return Uint8List.fromList(extended);
  }
}
