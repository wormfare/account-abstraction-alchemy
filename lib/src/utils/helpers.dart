part of '../../account_abstraction_alchemy.dart';

BigInt increaseByPercentage(BigInt value, int percentage) {
  return (value * BigInt.from(100 + percentage)) ~/ BigInt.from(100);
}
