part of '../../account_abstraction_alchemy.dart';

/// A class that implements the user operation struct defined in EIP4337.
class UserOperation implements UserOperationBase {
  // Common properties
  @override
  final EthereumAddress sender;
  @override
  final BigInt nonce;
  @override
  final Uint8List callData;
  @override
  final BigInt callGasLimit;
  @override
  final BigInt verificationGasLimit;
  @override
  final BigInt preVerificationGas;
  @override
  final BigInt maxFeePerGas;
  @override
  final BigInt maxPriorityFeePerGas;
  @override
  String signature;
  @override
  Uint8List paymasterAndData;

  // Version-specific properties

  // v.0.6
  @override
  final Uint8List? initCode;

  // v.0.7
  @override
  final EthereumAddress? factory;
  @override
  final Uint8List? factoryData;
  @override
  final BigInt? paymasterVerificationGasLimit;
  @override
  final BigInt? paymasterPostOpGasLimit;
  @override
  final EthereumAddress? paymaster;
  @override
  final Uint8List? paymasterData;

  UserOperation({
    required this.sender,
    required this.nonce,
    required this.callData,
    required this.callGasLimit,
    required this.verificationGasLimit,
    required this.preVerificationGas,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.signature,
    required this.paymasterAndData,
    this.factoryData,
    this.paymasterVerificationGasLimit,
    this.paymasterPostOpGasLimit,
    this.paymaster,
    this.paymasterData,
    this.initCode,
    this.factory,
  });

  factory UserOperation.fromJson(String source) =>
      UserOperation.fromMap(json.decode(source) as Map<String, String>);

  factory UserOperation.fromMap(Map<String, dynamic> map) {
    return UserOperation(
      sender: EthereumAddress.fromHex(map['sender']),
      nonce: BigInt.parse(map['nonce']),
      callData: hexToBytes(map['callData']),
      callGasLimit: BigInt.parse(map['callGasLimit']),
      verificationGasLimit: BigInt.parse(map['verificationGasLimit']),
      preVerificationGas: BigInt.parse(map['preVerificationGas']),
      maxFeePerGas: BigInt.parse(map['maxFeePerGas']),
      maxPriorityFeePerGas: BigInt.parse(map['maxPriorityFeePerGas']),
      signature: map['signature'],
      paymasterAndData: hexToBytes(map['paymasterAndData']),
      initCode:
          map.containsKey('initCode') ? hexToBytes(map['initCode']) : null,
      factory: map.containsKey('factory')
          ? EthereumAddress.fromHex(map['factory'])
          : null,
      factoryData: map.containsKey('factoryData')
          ? hexToBytes(map['factoryData'])
          : null,
      paymasterVerificationGasLimit:
          map.containsKey('paymasterVerificationGasLimit')
              ? BigInt.parse(map['paymasterVerificationGasLimit'])
              : null,
      paymasterPostOpGasLimit: map.containsKey('paymasterPostOpGasLimit')
          ? BigInt.parse(map['paymasterPostOpGasLimit'])
          : null,
      paymaster: map.containsKey('paymaster')
          ? EthereumAddress.fromHex(map['paymaster'])
          : null,
      paymasterData: map.containsKey('paymasterData')
          ? hexToBytes(map['paymasterData'])
          : null,
    );
  }

  factory UserOperation.partial({
    required Uint8List callData,
    EthereumAddress? sender,
    BigInt? nonce,
    Uint8List? initCode,
    BigInt? callGasLimit,
    BigInt? verificationGasLimit,
    BigInt? preVerificationGas,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
    EthereumAddress? factory,
    Uint8List? factoryData,
    BigInt? paymasterVerificationGasLimit,
    BigInt? paymasterPostOpGasLimit,
    EthereumAddress? paymaster,
    Uint8List? paymasterData,
    Uint8List? paymasterAndData,
    String? signature,
  }) {
    return UserOperation(
      sender: sender ?? Constants.zeroAddress,
      nonce: nonce ?? BigInt.zero,
      initCode: initCode ?? Uint8List(0),
      callData: callData,
      callGasLimit: callGasLimit ?? BigInt.from(250000),
      verificationGasLimit: verificationGasLimit ?? BigInt.from(750000),
      preVerificationGas: preVerificationGas ?? BigInt.from(51000),
      maxFeePerGas: maxFeePerGas ?? BigInt.one,
      maxPriorityFeePerGas: maxPriorityFeePerGas ?? BigInt.one,
      signature: signature ?? '0x',
      factory: factory,
      factoryData: factoryData ?? Uint8List(0),
      paymasterVerificationGasLimit:
          paymasterVerificationGasLimit ?? BigInt.zero,
      paymasterPostOpGasLimit: paymasterPostOpGasLimit ?? BigInt.zero,
      paymaster: paymaster ?? Constants.zeroAddress,
      paymasterData: paymasterData ?? Uint8List(0),
      paymasterAndData: paymasterAndData ?? Uint8List(0),
    );
  }

  @override
  Uint8List hash(NetworkConfig network) {
    final version = network.entrypoint.version;
    if (EntryPointAddress.v06.version == version) {
      return hashV06(network);
    }

    return hashV07(network);
  }

  @override
  String toJson() => jsonEncode(toMap());

  @override
  Map<String, dynamic> toMap([double version = 0.6]) {
    if (EntryPointVersion.v06.toDouble == version) {
      return toMapV06();
    }
    return toMapV07();
  }

  @override
  UserOperation updateOpGas(
    UserOperationGas? opGas,
    Map<String, dynamic>? feePerGas,
    double version,
  ) {
    return copyWith(
      version: version,
      callGasLimit: opGas?.callGasLimit,
      verificationGasLimit: opGas?.verificationGasLimit,
      preVerificationGas: opGas?.preVerificationGas,
      maxFeePerGas: (feePerGas?["maxFeePerGas"] as EtherAmount?)?.getInWei,
      maxPriorityFeePerGas:
          (feePerGas?["maxPriorityFeePerGas"] as EtherAmount?)?.getInWei,
    );
  }

  UserOperation copyWith({
    required double version,
    EthereumAddress? sender,
    BigInt? nonce,
    Uint8List? initCode,
    Uint8List? callData,
    BigInt? callGasLimit,
    BigInt? verificationGasLimit,
    BigInt? preVerificationGas,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
    String? signature,
    Uint8List? paymasterAndData,
  }) {
    if (version == EntryPointVersion.v06.toDouble) {
      return copyWithV06(
        sender: sender,
        nonce: nonce,
        initCode: initCode,
        callData: callData,
        callGasLimit: callGasLimit,
        verificationGasLimit: verificationGasLimit,
        preVerificationGas: preVerificationGas,
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        signature: signature,
        paymasterAndData: paymasterAndData,
      );
    }

    return copyWithV07(
      sender: sender,
      nonce: nonce,
      callData: callData,
      callGasLimit: callGasLimit,
      verificationGasLimit: verificationGasLimit,
      preVerificationGas: preVerificationGas,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      signature: signature,
      paymasterAndData: paymasterAndData,
      factory: factory,
      factoryData: factoryData,
      paymasterVerificationGasLimit: paymasterVerificationGasLimit,
      paymasterPostOpGasLimit: paymasterPostOpGasLimit,
      paymaster: paymaster,
      paymasterData: paymasterData,
    );
  }

  @override
  void validate(bool deployed, double version, [String? data]) {
    if (version == EntryPointVersion.v06.toDouble) {
      return validateV06(deployed, data);
    }
    return validateV07(deployed, data);
  }

  Uint8List hashV06(NetworkConfig network) {
    final encoded = keccak256(abi.encode([
      'address', // sender
      'uint256', // nonce
      'bytes32', // initCode
      'bytes32', // callData
      'uint256', // callGasLimit
      'uint256', // verificationGasLimit
      'uint256', // preVerificationGas
      'uint256', // maxFeePerGas
      'uint256', // maxPriorityFeePerGas
      'bytes32', // paymasterAndData
    ], [
      sender,
      nonce,
      keccak256(initCode ?? Uint8List(0)),
      keccak256(callData),
      callGasLimit,
      verificationGasLimit,
      preVerificationGas,
      maxFeePerGas,
      maxPriorityFeePerGas,
      keccak256(paymasterAndData),
    ]));

    // Final hash including chain-specific data
    return keccak256(abi.encode([
      'bytes32', // encoded operation hash
      'address', // entry point address from config
      'uint256' // chain ID
    ], [
      encoded,
      network.entrypoint.address,
      BigInt.from(network.chainId)
    ]));
  }

  Uint8List hashV07(NetworkConfig network) {
    final encoded = keccak256(abi.encode([
      'address', // sender
      'uint256', // nonce
      'address', // factory
      'bytes32', // factoryData
      'bytes32', // callData (hashed)
      'uint256', // callGasLimit
      'uint256', // verificationGasLimit
      'uint256', // paymasterVerificationGasLimit
      'uint256', // paymasterPostOpGasLimit
      'uint256', // preVerificationGas
      'uint256', // maxFeePerGas
      'uint256', // maxPriorityFeePerGas
      'bytes32', // paymasterData (hashed)
      'bytes32', // paymasterAndData (hashed)
    ], [
      sender,
      nonce,
      factory,
      factoryData,
      keccak256(callData),
      callGasLimit,
      verificationGasLimit,
      paymasterVerificationGasLimit,
      paymasterPostOpGasLimit,
      preVerificationGas,
      maxFeePerGas,
      maxPriorityFeePerGas,
      keccak256(paymasterData ?? Uint8List(0)),
      keccak256(paymasterAndData),
    ]));

    // Final hash including chain-specific data
    return keccak256(abi.encode([
      'bytes32', // encoded operation hash
      'address', // entry point address from config
      'uint256' // chain ID
    ], [
      encoded,
      network.entrypoint.address,
      BigInt.from(network.chainId)
    ]));
  }

  Map<String, dynamic> toMapV06() {
    return {
      'sender': sender.hexEip55,
      'nonce': '0x${nonce.toRadixString(16)}',
      'initCode': hexlify(initCode ?? Uint8List(0)),
      'callData': hexlify(callData),
      'callGasLimit': '0x${callGasLimit.toRadixString(16)}',
      'verificationGasLimit': '0x${verificationGasLimit.toRadixString(16)}',
      'preVerificationGas': '0x${preVerificationGas.toRadixString(16)}',
      'maxFeePerGas': '0x${maxFeePerGas.toRadixString(16)}',
      'maxPriorityFeePerGas': '0x${maxPriorityFeePerGas.toRadixString(16)}',
      'paymasterAndData': hexlify(paymasterAndData),
      'signature': signature,
    };
  }

  Map<String, dynamic> toMapV07() {
    return {
      'sender': sender.hexEip55,
      'nonce': '0x${nonce.toRadixString(16)}',
      'factory': factory?.hexEip55 ?? '',
      'factoryData': hexlify(factoryData ?? Uint8List(0)),
      'callData': hexlify(callData),
      'callGasLimit': '0x${callGasLimit.toRadixString(16)}',
      'verificationGasLimit': '0x${verificationGasLimit.toRadixString(16)}',
      'paymasterVerificationGasLimit':
          '0x${paymasterVerificationGasLimit?.toRadixString(16)}',
      'paymasterPostOpGasLimit':
          '0x${paymasterPostOpGasLimit?.toRadixString(16)}',
      'preVerificationGas': '0x${preVerificationGas.toRadixString(16)}',
      'maxFeePerGas': '0x${maxFeePerGas.toRadixString(16)}',
      'maxPriorityFeePerGas': '0x${maxPriorityFeePerGas.toRadixString(16)}',
      'paymaster': paymaster?.hexEip55,
      'paymasterData': hexlify(paymasterData ?? Uint8List(0)),
      'paymasterAndData': hexlify(paymasterAndData),
      'signature': signature,
    };
  }

  UserOperation copyWithV06({
    EthereumAddress? sender,
    BigInt? nonce,
    Uint8List? initCode,
    Uint8List? callData,
    BigInt? callGasLimit,
    BigInt? verificationGasLimit,
    BigInt? preVerificationGas,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
    String? signature,
    Uint8List? paymasterAndData,
  }) {
    return UserOperation(
      sender: sender ?? this.sender,
      nonce: nonce ?? this.nonce,
      initCode: initCode ?? this.initCode,
      callData: callData ?? this.callData,
      callGasLimit: callGasLimit ?? this.callGasLimit,
      verificationGasLimit: verificationGasLimit ?? this.verificationGasLimit,
      preVerificationGas: preVerificationGas ?? this.preVerificationGas,
      maxFeePerGas: maxFeePerGas ?? this.maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas ?? this.maxPriorityFeePerGas,
      signature: signature ?? this.signature,
      paymasterAndData: paymasterAndData ?? this.paymasterAndData,
    );
  }

  UserOperation copyWithV07({
    EthereumAddress? sender,
    BigInt? nonce,
    Uint8List? callData,
    BigInt? callGasLimit,
    BigInt? verificationGasLimit,
    BigInt? preVerificationGas,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
    String? signature,
    Uint8List? paymasterAndData,
    EthereumAddress? factory,
    Uint8List? factoryData,
    BigInt? paymasterVerificationGasLimit,
    BigInt? paymasterPostOpGasLimit,
    EthereumAddress? paymaster,
    Uint8List? paymasterData,
  }) {
    return UserOperation(
      sender: sender ?? this.sender,
      nonce: nonce ?? this.nonce,
      callData: callData ?? this.callData,
      callGasLimit: callGasLimit ?? this.callGasLimit,
      verificationGasLimit: verificationGasLimit ?? this.verificationGasLimit,
      preVerificationGas: preVerificationGas ?? this.preVerificationGas,
      maxFeePerGas: maxFeePerGas ?? this.maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas ?? this.maxPriorityFeePerGas,
      signature: signature ?? this.signature,
      paymasterAndData: paymasterAndData ?? this.paymasterAndData,
      factory: factory ?? this.factory,
      factoryData: factoryData ?? this.factoryData,
      paymasterVerificationGasLimit:
          paymasterVerificationGasLimit ?? this.paymasterVerificationGasLimit,
      paymasterPostOpGasLimit:
          paymasterPostOpGasLimit ?? this.paymasterPostOpGasLimit,
      paymaster: paymaster ?? this.paymaster,
      paymasterData: paymasterData ?? this.paymasterData,
    );
  }

  void validateV06(bool deployed, [String? initCode]) {
    require(
        deployed
            ? hexlify(this.initCode ?? Uint8List(0)).toLowerCase() == '0x'
            : hexlify(this.initCode ?? Uint8List(0)).toLowerCase() ==
                initCode?.toLowerCase(),
        'InitCode mismatch');
    require(callData.length >= 4, 'Calldata too short');
    require(signature.length >= 64, 'Signature too short');
  }

  void validateV07(bool deployed, [String? factoryDataCheck]) {
    if (!deployed && factory != null) {
      require(
          factory?.hexEip55.toLowerCase() == factoryDataCheck?.toLowerCase(),
          'Factory data mismatch');
    }

    require(callData.length >= 4, 'Calldata too short');
    require(signature.length >= 64, 'Signature too short');
    require(factoryData != null, 'Factory data cannot be empty');
  }
}

class UserOperationByHash {
  UserOperation userOperation;
  final String entryPoint;
  final BigInt blockNumber;
  final BigInt blockHash;
  final BigInt transactionHash;
  UserOperationByHash(this.userOperation, this.entryPoint, this.blockNumber,
      this.blockHash, this.transactionHash);

  factory UserOperationByHash.fromMap(Map<String, dynamic> map) {
    return UserOperationByHash(
      UserOperation.fromMap(map['userOperation']),
      map['entryPoint'],
      BigInt.parse(map['blockNumber']),
      BigInt.parse(map['blockHash']),
      BigInt.parse(map['transactionHash']),
    );
  }
}

class UserOperationGas {
  final BigInt callGasLimit;
  final BigInt verificationGasLimit;
  final BigInt preVerificationGas;
  BigInt? validAfter;
  BigInt? validUntil;
  UserOperationGas({
    required this.callGasLimit,
    required this.verificationGasLimit,
    required this.preVerificationGas,
    this.validAfter,
    this.validUntil,
  });
  factory UserOperationGas.fromMap(Map<String, dynamic> map) {
    final List<BigInt> accountGasLimits = map['accountGasLimits'] != null
        ? unpackUints(map['accountGasLimits'])
        : [
            BigInt.parse(map['verificationGasLimit']),
            BigInt.parse(map['callGasLimit'])
          ];

    return UserOperationGas(
      verificationGasLimit: accountGasLimits[0],
      callGasLimit: accountGasLimits[1],
      preVerificationGas: BigInt.parse(map['preVerificationGas']),
      validAfter:
          map['validAfter'] != null ? BigInt.parse(map['validAfter']) : null,
      validUntil:
          map['validUntil'] != null ? BigInt.parse(map['validUntil']) : null,
    );
  }
}

class UserOperationReceipt {
  final String userOpHash;
  final String entryPoint;
  final String sender;
  final BigInt nonce;
  final String paymaster;
  final BigInt actualGasCost;
  final BigInt actualGasUsed;
  final bool success;
  final String reason;
  final List<Map<String, dynamic>> logs;
  final Receipt receipt;

  UserOperationReceipt({
    required this.userOpHash,
    required this.entryPoint,
    required this.sender,
    required this.nonce,
    required this.paymaster,
    required this.actualGasCost,
    required this.actualGasUsed,
    required this.success,
    required this.reason,
    required this.logs,
    required this.receipt,
  });

  factory UserOperationReceipt.fromMap(Map<String, dynamic> map) {
    return UserOperationReceipt(
      userOpHash: map['userOpHash'],
      entryPoint: map['entryPoint'],
      sender: map['sender'],
      nonce: BigInt.parse(map['nonce']),
      paymaster: map['paymaster'],
      actualGasCost: BigInt.parse(map['actualGasCost']),
      actualGasUsed: BigInt.parse(map['actualGasUsed']),
      success: map['success'],
      reason: map['reason'] ?? '', // Handling possible null
      logs: List<Map<String, dynamic>>.from(map['logs'] as List<dynamic>),
      receipt: Receipt.fromMap(map['receipt'] as Map<String, dynamic>),
    );
  }
}

class Receipt {
  final String transactionHash;
  final String transactionIndex;
  final String blockHash;
  final String blockNumber;
  final String from;
  final String to;

  Receipt({
    required this.transactionHash,
    required this.transactionIndex,
    required this.blockHash,
    required this.blockNumber,
    required this.from,
    required this.to,
  });

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      transactionHash: map['transactionHash'],
      transactionIndex: map['transactionIndex'],
      blockHash: map['blockHash'],
      blockNumber: map['blockNumber'],
      from: map['from'],
      to: map['to'],
    );
  }
}

class UserOperationResponse {
  final String userOpHash;
  final Future<UserOperationReceipt?> Function(String) _callback;

  UserOperationResponse(this.userOpHash, this._callback);

  Future<UserOperationReceipt?> wait(
      [Duration timeout = const Duration(seconds: 60),
      Duration pollInterval = const Duration(seconds: 10)]) async {
    Duration elapsed = Duration.zero;
    while (elapsed < timeout) {
      try {
        print('Polling for receipt, elapsed time: ${elapsed.inSeconds}s');
        final receipt = await _callback(userOpHash);
        if (receipt != null) {
          print('Success: receipt received!');
          return receipt;
        } else {
          print('Waiting: no receipt available yet.');
        }
      } catch (e) {
        Logger.conditionalWarning(true, 'Error while waiting for receipt: $e');
      }

      await Future.delayed(pollInterval);
      elapsed += pollInterval;
    }

    throw TimeoutException(
        'Timeout waiting for user operation with hash $userOpHash', timeout);
  }
}
