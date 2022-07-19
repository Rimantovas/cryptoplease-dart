import 'package:json_annotation/json_annotation.dart';
import 'package:solana/src/rpc/dto/meta.dart';
import 'package:solana/src/rpc/dto/transaction.dart';

part 'transaction_details.g.dart';

/// Details of a transaction
@JsonSerializable(createToJson: false)
class TransactionDetails {
  TransactionDetails({
    required this.slot,
    required this.transaction,
    this.blockTime,
    this.meta,
  });

  factory TransactionDetails.fromJson(Map<String, dynamic> json) =>
      _$TransactionDetailsFromJson(json)..rawJson = json;

  @JsonKey(ignore: true)
  late Map<String, dynamic> rawJson;

  /// The slot this transaction was processed in
  final int slot;

  /// Transaction object, either in JSON format or encoded binary
  /// data, depending on encoding parameter
  final Transaction transaction;

  /// The block time
  final int? blockTime;

  /// Transaction status metadata
  final Meta? meta;
}
