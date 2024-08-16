part of '../../account_abstraction_alchemy.dart';

/// Represents a Paymaster contract for sponsoring user operations.
class Paymaster implements PaymasterBase {
  final RPCBase _rpc;
  final NetworkConfig _network;

  /// The address of the Paymaster contract.
  ///
  /// This is an optional parameter and can be left null if the paymaster address
  /// is not known or needed.
  EthereumAddress? _paymasterAddress;

  /// Multiplier values for gas estimation.
  final num preVerificationGasMultiplier;
  final num maxFeePerGasMultiplier;
  final num maxPriorityFeePerGasMultiplier;
  final num callGasLimitMultiplier;
  final num verificationGasLimitMultiplier;

  /// Creates a new instance of the [Paymaster] class.
  ///
  /// [network] is the Ethereum chain configuration.
  /// [paymasterAddress] is an optional address of the Paymaster contract.
  ///
  /// Throws an [InvalidPaymasterUrl] exception if the paymaster URL in the
  /// provided chain configuration is not a valid URL.
  Paymaster(
    this._network, {
    EthereumAddress? paymasterAddress,
    this.preVerificationGasMultiplier = 1,
    this.maxFeePerGasMultiplier = 1,
    this.maxPriorityFeePerGasMultiplier = 1,
    this.callGasLimitMultiplier = 1,
    this.verificationGasLimitMultiplier = 1,
  })  : _paymasterAddress = paymasterAddress,
        assert(_network.paymasterUrl.isURL(),
            InvalidPaymasterUrl(_network.paymasterUrl)),
        _rpc = RPCBase(_network.paymasterUrl);

  @override
  set paymasterAddress(EthereumAddress? address) {
    _paymasterAddress = address;
  }

  @override
  Future<UserOperation> interceptToSponsor(UserOperation op) async {
    if (_paymasterAddress != null) {
      op.paymasterAndData = Uint8List.fromList([
        ..._paymasterAddress!.addressBytes,
        ...op.paymasterAndData.sublist(20)
      ]);
    }

    final PaymasterResponse paymasterResponse =
        await requestGasAndPaymasterAndData(
            op.toMap(_network.entrypoint.version), _network.entrypoint);

    // Create a new UserOperation with the updated Paymaster data and gas limits
    final updatedOp = op.copyWith(
      version: _network.entrypoint.version,
      paymasterAndData: paymasterResponse.paymasterAndData,
      preVerificationGas: paymasterResponse.preVerificationGas,
      verificationGasLimit: paymasterResponse.verificationGasLimit,
      callGasLimit: paymasterResponse.callGasLimit,
      maxFeePerGas: paymasterResponse.maxFeePerGas,
      maxPriorityFeePerGas: paymasterResponse.maxPriorityFeePerGas,
    );

    return updatedOp;
  }

  @override
  Future<UserOperation> interceptToDropReplace(UserOperationByHash op) async {
    final updatedOp = await updateGasAndPaymasterSignature(
        op.toMap(_network.entrypoint.version), _network.entrypoint);
    return updatedOp;
  }

  @override
  Future<PaymasterResponse> requestGasAndPaymasterAndData(
    Map<String, dynamic> userOp,
    EntryPointAddress entrypoint,
  ) async {
    final Map<String, dynamic> minimalUserOp = {
      'sender': userOp['sender'],
      'nonce': userOp['nonce'],
      'initCode': userOp['initCode'],
      'callData': userOp['callData'],
    };

    // Prepare the complete request payload
    final requestPayload = {
      'policyId': _network.gasPolicyId,
      'entryPoint': entrypoint.address.hex,
      'dummySignature': Constants.dummySignature,
      'userOperation': minimalUserOp,
      "overrides": {
        "preVerificationGas": {"multiplier": preVerificationGasMultiplier},
        "maxFeePerGas": {"multiplier": maxFeePerGasMultiplier},
        "maxPriorityFeePerGas": {"multiplier": maxPriorityFeePerGasMultiplier},
        "callGasLimit": {"multiplier": callGasLimitMultiplier},
        "verificationGasLimit": {"multiplier": verificationGasLimitMultiplier}
      }
    };

    final response = await _rpc.send<Map<String, dynamic>>(
        'alchemy_requestGasAndPaymasterAndData', [requestPayload]);

    // Parse the response into a PaymasterResponse object
    return PaymasterResponse.fromMap(response);
  }

  @override
  Future<UserOperation> updateGasAndPaymasterSignature(
    Map<String, dynamic> userOp,
    EntryPointAddress entrypoint,
  ) async {
    final feeOverrides = await estimateAndCompareFees(userOp);

    final BigInt freshMaxFeePerGas = feeOverrides["maxFeePerGas"]!;
    final BigInt freshMaxPriorityFeePerGas =
        feeOverrides["maxPriorityFeePerGas"]!;

    final String overrideMaxFeePerGasHex =
        '0x${freshMaxFeePerGas.toRadixString(16)}';
    final String overrideMaxPriorityFeePerGasHex =
        '0x${freshMaxPriorityFeePerGas.toRadixString(16)}';

    final userOperation = userOp["userOperation"] as Map<String, dynamic>;

    userOperation['maxFeePerGas'] = overrideMaxFeePerGasHex;
    userOperation['maxPriorityFeePerGas'] = overrideMaxPriorityFeePerGasHex;

    final paymasterSignatureResponse =
        await pmGetPaymasterStubData(userOperation);

    userOperation['paymasterAndData'] =
        paymasterSignatureResponse.paymasterAndData;

    return UserOperation.fromMap(userOperation);
  }

  @override
  Future<Map<String, BigInt>> estimateAndCompareFees(
      Map<String, dynamic> opToDrop) async {
    final blockResponse = _rpc.send<Map<String, dynamic>>(
      'eth_getBlockByNumber',
      ['latest', false],
    );

    final maxPriorityFeePerGasEstimate = _rpc.send<String>(
      'rundler_maxPriorityFeePerGas',
      [],
    );

    final responses =
        await Future.wait([blockResponse, maxPriorityFeePerGasEstimate]);

    final block = responses[0] as Map<String, dynamic>;
    final baseFeePerGas = BigInt.parse(block['baseFeePerGas'].toString());

    if (baseFeePerGas == BigInt.zero) {
      throw Exception("baseFeePerGas is null");
    }

    final maxPriorityFeePerGasEstimateBigInt =
        BigInt.parse(responses[1] as String);

    final maxFeePerGas = baseFeePerGas + maxPriorityFeePerGasEstimateBigInt;

    // Accessing the userOperation map within opToDrop
    final userOperation = opToDrop["userOperation"] as Map<String, dynamic>;

    final oldMaxFeePerGasHex = userOperation["maxFeePerGas"]?.toString();
    final oldMaxPriorityFeePerGasHex =
        userOperation["maxPriorityFeePerGas"]?.toString();

    if (oldMaxFeePerGasHex == null || oldMaxPriorityFeePerGasHex == null) {
      throw Exception(
          "maxFeePerGas or maxPriorityFeePerGas is null or invalid.");
    }

    final oldMaxFeePerGas = increaseByPercentage(
        BigInt.parse(oldMaxFeePerGasHex.replaceFirst("0x", ""), radix: 16), 10);

    final oldMaxPriorityFeePerGas = increaseByPercentage(
        BigInt.parse(oldMaxPriorityFeePerGasHex.replaceFirst("0x", ""),
            radix: 16),
        10);

    final overrideMaxFeePerGas =
        oldMaxFeePerGas > maxFeePerGas ? oldMaxFeePerGas : maxFeePerGas;
    final overrideMaxPriorityFeePerGas =
        oldMaxPriorityFeePerGas > maxPriorityFeePerGasEstimateBigInt
            ? oldMaxPriorityFeePerGas
            : maxPriorityFeePerGasEstimateBigInt;

    return {
      'maxFeePerGas': overrideMaxFeePerGas,
      'maxPriorityFeePerGas': overrideMaxPriorityFeePerGas,
    };
  }

  @override
  Future<PaymasterSignatureResponse> pmGetPaymasterStubData(
      Map<String, dynamic> opToDrop) async {
    final Map<String, dynamic> minimalUserOp = {
      'sender': opToDrop['sender'],
      'nonce': opToDrop['nonce'],
      'initCode': opToDrop['initCode'],
      'callData': opToDrop['callData'],
      "callGasLimit": opToDrop['callGasLimit'],
      "verificationGasLimit": opToDrop['verificationGasLimit'],
      "preVerificationGas": opToDrop['preVerificationGas'],
      "maxFeePerGas": opToDrop['maxFeePerGas'],
      "maxPriorityFeePerGas": opToDrop['maxPriorityFeePerGas'],
    };

    final requestPayload = [
      minimalUserOp,
      _network.entrypoint.address.hex,
      "0x${_network.chainId.toRadixString(16)}",
      {
        'policyId': _network.gasPolicyId,
      }
    ];

    final response = await _rpc.send<Map<String, dynamic>>(
        'pm_getPaymasterData', requestPayload);

    return PaymasterSignatureResponse.fromMap(response);
  }
}

class PaymasterResponse {
  final Uint8List paymasterAndData;
  final BigInt preVerificationGas;
  final BigInt verificationGasLimit;
  final BigInt callGasLimit;
  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;

  PaymasterResponse({
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.paymasterAndData,
    required this.preVerificationGas,
    required this.verificationGasLimit,
    required this.callGasLimit,
  });

  factory PaymasterResponse.fromMap(Map<String, dynamic> map) {
    return PaymasterResponse(
      paymasterAndData: hexToBytes(map['paymasterAndData']),
      preVerificationGas: BigInt.parse(map['preVerificationGas']),
      verificationGasLimit: BigInt.parse(map['verificationGasLimit']),
      callGasLimit: BigInt.parse(map['callGasLimit']),
      maxFeePerGas: BigInt.parse(map['maxFeePerGas']),
      maxPriorityFeePerGas: BigInt.parse(map['maxPriorityFeePerGas']),
    );
  }
}

class PaymasterSignatureResponse {
  final String paymasterAndData;

  PaymasterSignatureResponse({
    required this.paymasterAndData,
  });

  factory PaymasterSignatureResponse.fromMap(Map<String, dynamic> map) {
    return PaymasterSignatureResponse(
      paymasterAndData: map['paymasterAndData'],
    );
  }
}
