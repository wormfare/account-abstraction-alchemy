## 0.0.1

* Initial commit

## 0.0.2

* Updated supported platforms

## 0.0.3

* Updated README.md
  
## 0.0.4

* Added alchemy light account support for entrypoint v.0.6
* Fixed sending batch transactions

## 0.0.5

* Added Polygon Amoy testnet network support
* Added wallet estimateGasForSingleOperation and estimateGasForBatchedOperation functions to get transaction fee which will be paid by paymaster
  
## 0.0.6
* Fixed _estimateGas before was returning doubled price
* update dependencies, fixed code warnings
  
## 0.0.7
* Added gas multiplier
  
## 0.0.8
* Added the ability to pass gas multiplier values to the SmartWalletFactory class, enabling customized gas.

## 0.0.9
* Introduced the ability to pass a custom `http.Client` instance to the `SmartWalletFactory`, `JsonRPCProvider`, and `BundlerProvider` classes.
  - This can allow to pass SentryHttpClient to catch http rpc errors
  
## 0.1.0
* Added support for passing custom `jsonRpcUrl`, `bundlerUrl`, and `paymasterUrl` into `NetworkConfig`.

## 0.1.1
* Added drop and replace mechanism for stalled user operations (with 10% increase in gas when replaced)

## 0.1.2
* Wait for user operation - added support to pass callback when stuck transaction is replaced

## 0.1.3
* Update transaction fee estimation method

## 0.1.4
* Fix transaction fee estimation method

## 0.1.5
* Adjust gas price estimation as per entry point formula

## 0.1.6
* Minor fix gas price estimation