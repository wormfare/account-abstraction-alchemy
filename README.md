
  
## ERC-4337: Account Abstraction, for usage with Alchemy Account Abstraction

![enter image description here](https://www.datocms-assets.com/105223/1701819587-logo.svg)

  [Read more about Alchemy account abstraction](https://www.alchemy.com/account-abstraction-infrastructure)
  [Alchemy AA API documentation](https://docs.alchemy.com/reference/bundler-api-quickstart)

## Features

  

- Create private key signer

- Create smart wallet

- ABI Encoding/Decoding

- Sent transactions with sponsored gas

- Wait for transaction receipt

  
  

## Getting started

  

To get started, you need to add account_abstraction_alchemy to your project.

```sh

flutter  pub  add  account_abstraction_alchemy

```

Create Alchemy app and get your Alchemy API key from [dashboard](https://dashboard.alchemy.com/).
Create [gas policy](https://dashboard.alchemy.com/gas-manager) for created app, and get gas policy ID.

  

## Usage

  

```dart

// Import the package

import  'package:account_abstraction_alchemy/account_abstraction_alchemy.dart';

// Create EthPrivateKey from private key hex string
// it's up to you how you obtain the private key hex you can create random or
// use private key provided by web3auth for example
// created private key will be used to create "signer"

final privateKey = EthPrivateKey.fromHex(PRIVATE KEY HEX HERE);


// Setup network config
// Currently supporting ethereum mainnet, polygon, and sepolia testnet networks.

final network = NetworkConfigs.getConfig(
			Network.sepolia,
			AccountType.simple,
			EntryPointVersion.v06,
			"ALCHEMY-API-KEY-HERE",
			"ALCHEMY-GAS-POLICY-ID-HERE");

// Generate salt

final salt = Uint256.fromHex(hexlify(
		keccak256(EthereumAddress.fromHex(signer.getAddress()).addressBytes)));

// Create wallet factory
final SmartWalletFactory walletFactory = SmartWalletFactory(_network, signer);

// Finally create simple smart account
final wallet = await walletFactory.createSimpleAccount(salt);
print('Wallet address: ${wallet?.address.hex}');

// Now you need send some sepolia eth to your newly created wallet address
// and send your first transaction

final recipient = EthereumAddress.fromHex('0x502FE2DCc50DfFec11317f26363fcb44D507D81C');
final amountWei = EtherAmount.inWei(BigInt.from(10000000000000000)); // 0.01 eth
// send it
final transaction = await wallet.send(recipient, amountWei);
// than we wait for receipt 
final response = await transaction.wait();
// done, you can check transactions details on sepolia explorer
print(response!.receipt.transactionHash);
```

  

## Additional information

This library designed to be used only with gas manager, to sponsor gas for transactions.

Important: if you want to send batch transactions use Light account type.

Currently supports only Entry point versions: 0.6
Currently supports smart accounts: Simple, Light

Tested on Android and Web platforms, but should work on all platforms.