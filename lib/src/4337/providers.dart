part of '../../account_abstraction_alchemy.dart';

/// A class that implements the `BundlerProviderBase` interface and provides methods
/// for interacting with a bundler for sending and tracking user operations on
/// an Ethereum-like blockchain.
class BundlerProvider implements BundlerProviderBase {
  /// The remote procedure call (RPC) client used to communicate with the bundler.
  final RPCBase rpc;

  /// A flag indicating whether the initialization process was successful.
  late final bool _initialized;

  /// Creates a new instance of the BundlerProvider class.
  ///
  /// [chain] is an object representing the blockchain chain configuration.
  ///
  ///  It sends an RPC request to
  /// retrieve the chain ID and verifies that it matches the expected chain ID.
  /// If the chain IDs don't match, the _initialized flag is set to false.
  BundlerProvider(NetworkConfig chain) : rpc = RPCBase(chain.bundlerUrl) {
    rpc
        .send<String>('eth_chainId')
        .then(BigInt.parse)
        .then((value) => value.toInt() == chain.chainId)
        .then((value) => _initialized = value);
  }

  @override
  Future<UserOperationGas> estimateUserOperationGas(
      Map<String, dynamic> userOp, EntryPointAddress entrypoint) async {
    Logger.conditionalWarning(
        !_initialized, "estimateUserOpGas may fail: chainId mismatch");

    final opGas = await rpc.send<Map<String, dynamic>>(
        'eth_estimateUserOperationGas', [userOp, entrypoint.address.hex]);

    return UserOperationGas.fromMap(opGas);
  }

  @override
  Future<UserOperationByHash> getUserOperationByHash(String userOpHash) async {
    Logger.conditionalWarning(
        !_initialized, "getUserOpByHash may fail: chainId mismatch");
    final opExtended = await rpc
        .send<Map<String, dynamic>>('eth_getUserOperationByHash', [userOpHash]);
    return UserOperationByHash.fromMap(opExtended);
  }

  @override
  Future<UserOperationReceipt?> getUserOpReceipt(String userOpHash) async {
    Logger.conditionalWarning(
        !_initialized, 'getUserOpReceipt may fail: chainId mismatch');

    try {
      final response = await rpc.send<Map<String, dynamic>?>(
          'eth_getUserOperationReceipt', [userOpHash]);

      if (response == null) {
        return null;
      }

      return UserOperationReceipt.fromMap(response);
    } catch (e) {
      Logger.conditionalWarning(
          true, 'Exception fetching operation receipt: $e');
      return null;
    }
  }

  @override
  Future<UserOperationResponse> sendUserOperation(
      Map<String, dynamic> userOp, EntryPointAddress entrypoint) async {
    Logger.conditionalWarning(
        !_initialized, 'sendUserOp may fail: chainId mismatch');

    final opHash = await rpc.send<String>(
        'eth_sendUserOperation', [userOp, entrypoint.address.hex]);

    debugPrint('>>>>>>>>>>> TX SENT SUCCESSFULLY :::: HASH $opHash ');

    return UserOperationResponse(opHash, getUserOpReceipt);
  }

  @override
  Future<List<String>> supportedEntryPoints() async {
    final entrypointList =
        await rpc.send<List<dynamic>>('eth_supportedEntryPoints');
    return List.castFrom(entrypointList);
  }
}

/// A class that implements the JsonRPCProviderBase interface and provides methods
/// for interacting with an Ethereum-like blockchain via the JSON-RPC protocol.
class JsonRPCProvider implements JsonRPCProviderBase {
  /// The remote procedure call (RPC) client used to communicate with the blockchain.
  final RPCBase rpc;

  /// Creates a new instance of the JsonRPCProvider class.
  ///
  /// [chain] is an object representing the blockchain chain configuration.
  ///
  /// The constructor checks if the JSON-RPC URL is a valid URL and initializes
  /// the RPC client with the JSON-RPC URL.
  JsonRPCProvider(NetworkConfig chain)
      : assert(chain.jsonRpcUrl.isURL(), InvalidJsonRpcUrl(chain.jsonRpcUrl)),
        rpc = RPCBase(chain.jsonRpcUrl);

  Future<TransactionReceipt> getTransactionReceipt(String txHash) async {
    final result = await rpc
        .send<Map<String, dynamic>>('eth_getTransactionReceipt', [txHash]);
    if (result == null) {
      throw Exception('Transaction receipt not found for $txHash');
    }
    return TransactionReceipt.fromMap(result);
  }

  Future<String> sendTransaction({
    required EthereumAddress from,
    required String to,
    required String data,
    String? gas,
    String? gasPrice,
    String? value,
    String? nonce,
  }) async {
    final params = {
      'from': from.hex,
      'to': to,
      'data': data,
      'value': value ?? '0x0',
      'gas': gas, // Consider estimating gas if not provided
      'gasPrice':
          gasPrice, // Consider fetching current gas price if not provided
      'nonce': nonce, // Consider fetching nonce if not provided
    };

    params.removeWhere((key, value) => value == null);

    return rpc.send<String>('eth_sendRawTransaction', [params]);
  }

  @override
  Future<BigInt> estimateGas(EthereumAddress to, String calldata) {
    return rpc.send<String>('eth_estimateGas', [
      {'to': to.hex, 'data': calldata}
    ]).then(hexToInt);
  }

  @override
  Future<int> getBlockNumber() {
    return rpc
        .send<String>('eth_blockNumber')
        .then(hexToInt)
        .then((value) => value.toInt());
  }

  @override
  Future<BlockInformation> getBlockInformation({
    String blockNumber = 'latest',
    bool isContainFullObj = true,
  }) {
    return rpc.send<Map<String, dynamic>>(
      'eth_getBlockByNumber',
      [blockNumber, isContainFullObj],
    ).then((json) => BlockInformation.fromJson(json));
  }

  @override
  Future<Map<String, EtherAmount>> getEip1559GasPrice() async {
    // Fetch the latest priority fee (tip)
    final tipResponse = await rpc.send<String>('eth_maxPriorityFeePerGas');
    final tip = Uint256.fromHex(tipResponse);

    // Fetch the latest base fee from the latest block
    final latestBlock = await rpc
        .send<Map<String, dynamic>>('eth_getBlockByNumber', ['latest', false]);
    final baseFee = Uint256.fromHex(latestBlock['baseFeePerGas']);

    // Calculate the priority fee with a buffer for Rundler's tip
    final tipBuffer =
        tip * Uint256(BigInt.from(25)) / Uint256(BigInt.from(100));
    final maxPriorityFeePerGas = tip + tipBuffer;

    // Calculate maxFeePerGas to be competitive
    final maxFeeBuffer = (baseFee + maxPriorityFeePerGas) *
        Uint256(BigInt.from(10)) /
        Uint256(BigInt.from(100));
    final maxFeePerGas = baseFee + maxPriorityFeePerGas + maxFeeBuffer;

    return {
      'maxFeePerGas': EtherAmount.fromBigInt(EtherUnit.wei, maxFeePerGas.value),
      'maxPriorityFeePerGas':
          EtherAmount.fromBigInt(EtherUnit.wei, maxPriorityFeePerGas.value)
    };
  }

  @override
  Future<Map<String, EtherAmount>> getGasPrice() async {
    try {
      return await getEip1559GasPrice();
    } catch (e) {
      final value = await getLegacyGasPrice();
      return {
        'maxFeePerGas': value,
        'maxPriorityFeePerGas': value,
      };
    }
  }

  @override
  Future<EtherAmount> getLegacyGasPrice() async {
    final data = await rpc.send<String>('eth_gasPrice');
    return EtherAmount.fromBigInt(EtherUnit.wei, hexToInt(data));
  }
}

class RPCBase extends JsonRPC {
  RPCBase(String url) : super(url, http.Client());

  /// Asynchronously sends an RPC call to the Ethereum node for the specified function and parameters.
  ///
  /// Parameters:
  ///   - `function`: The Ethereum RPC function to call. eg: `eth_getBalance`
  ///   - `params`: Optional parameters for the RPC call.
  ///
  /// Returns:
  ///   A [Future] that completes with the result of the RPC call.
  ///
  /// Example:
  /// ```dart
  /// final result = await send<String>('eth_getBalance', ['0x9876543210abcdef9876543210abcdef98765432']);
  /// ```
  Future<T> send<T>(String function, [List<dynamic>? params]) {
    return _makeRPCCall<T>(function, params);
  }

  Future<T> _makeRPCCall<T>(String function, [List<dynamic>? params]) {
    return super.call(function, params).then((data) => data.result as T);
  }
}
