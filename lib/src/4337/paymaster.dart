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

  /// Creates a new instance of the [Paymaster] class.
  ///
  /// [_network] is the Ethereum chain configuration.
  /// [_paymasterAddress] is an optional address of the Paymaster contract.
  ///
  /// Throws an [InvalidPaymasterUrl] exception if the paymaster URL in the
  /// provided chain configuration is not a valid URL.
  Paymaster(this._network, [this._paymasterAddress])
      : assert(_network.paymasterUrl.isURL(),
            InvalidPaymasterUrl(_network.paymasterUrl)),
        _rpc = RPCBase(_network.paymasterUrl);

  @override
  set paymasterAddress(EthereumAddress? address) {
    _paymasterAddress = address;
  }

  @override
  Future<UserOperation> intercept(UserOperation op) async {
    if (_paymasterAddress != null) {
      op.paymasterAndData = Uint8List.fromList([
        ..._paymasterAddress!.addressBytes,
        ...op.paymasterAndData.sublist(20)
      ]);
    }
    final paymasterResponse = await requestGasAndPaymasterAndData(
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
      'userOperation': minimalUserOp
    };

    final response = await _rpc.send<Map<String, dynamic>>(
        'alchemy_requestGasAndPaymasterAndData', [requestPayload]);

    // Parse the response into a PaymasterResponse object
    return PaymasterResponse.fromMap(response);
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
