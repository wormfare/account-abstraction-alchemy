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