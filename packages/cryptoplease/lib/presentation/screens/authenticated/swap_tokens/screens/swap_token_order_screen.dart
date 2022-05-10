import 'package:cryptoplease/bl/amount.dart';
import 'package:cryptoplease/bl/swap_tokens/selector/swap_selector_bloc.dart';
import 'package:cryptoplease/l10n/device_locale.dart';
import 'package:cryptoplease/l10n/l10n.dart';
import 'package:cryptoplease/presentation/components/number_formatter.dart';
import 'package:cryptoplease/presentation/components/token_fiat_input_widget/amount_display.dart';
import 'package:cryptoplease/presentation/components/token_fiat_input_widget/enter_amount_keypad.dart';
import 'package:cryptoplease/presentation/dialogs.dart';
import 'package:cryptoplease/presentation/format_amount.dart';
import 'package:cryptoplease/presentation/screens/authenticated/swap_tokens/components/slippage_dropdown.dart';
import 'package:cryptoplease/presentation/screens/authenticated/swap_tokens/swap_token_router.dart';
import 'package:cryptoplease_ui/cryptoplease_ui.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SwapTokenOrderScreen extends StatefulWidget {
  const SwapTokenOrderScreen({Key? key}) : super(key: key);

  @override
  _SwapTokenOrderScreenState createState() => _SwapTokenOrderScreenState();
}

class _SwapTokenOrderScreenState extends State<SwapTokenOrderScreen> {
  final _inputKey = GlobalKey();
  final _outputKey = GlobalKey();
  final _controller = TextEditingController();
  late final SwapSelectorBloc swapTokenBloc;

  @override
  void initState() {
    super.initState();
    swapTokenBloc = context.read<SwapSelectorBloc>();
    _controller.addListener(_onAmountUpdate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insufficientTokenDialog({
    required Amount balance,
    required Amount currentAmount,
  }) =>
      showWarningDialog(
        context,
        title: context.l10n.insufficientFundsTitle,
        message: context.l10n.insufficientFundsMessage(
          currentAmount.format(DeviceLocale.localeOf(context)),
          balance.format(DeviceLocale.localeOf(context)),
        ),
      );

  void _insufficientFeeDialog(Amount fee) {
    showWarningDialog(
      context,
      title: context.l10n.insufficientFundsForFeeTitle,
      message: context.l10n.insufficientFundsForFeeMessage(
        fee.format(DeviceLocale.localeOf(context)),
      ),
    );
  }

  void _onAmountUpdate() {
    if (swapTokenBloc.state.selectedInput == null) return;

    final value = _controller.text.toDecimalOrZero(
      DeviceLocale.localeOf(context),
    );
    swapTokenBloc.add(
      SwapSelectorEvent.amountUpdated(value),
    );
  }

  void _onConfirm() {
    swapTokenBloc.validate().fold(
          (error) => error.map(
            insufficientFunds: (e) => _insufficientTokenDialog(
              balance: e.balance,
              currentAmount: e.currentAmount,
            ),
            insufficientFee: (e) => _insufficientFeeDialog(e.requiredFee),
          ),
          (_) => context.read<SwapTokenRouter>().onConfirm(),
        );
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<SwapSelectorBloc, SwapSelectorState>(
        bloc: swapTokenBloc,
        listener: (context, state) => state.processingState.whenOrNull(
          error: (error) => showErrorDialog(
            context,
            context.l10n.errorLoadingTokens,
            error,
          ),
        ),
        builder: (context, state) => CpTheme.dark(
          child: CpLoader(
            isLoading: state.processingState.maybeMap(
              processing: (_) => true,
              orElse: () => false,
            ),
            child: Scaffold(
              appBar: CpAppBar(
                leading: BackButton(
                  onPressed: () => context.read<SwapTokenRouter>().closeFlow(),
                ),
                nextButton: SlippageDropdown(
                  currentSlippage: state.slippage,
                  onSlippageChanged: (slippage) => swapTokenBloc.add(
                    SwapSelectorEvent.slippageUpdated(
                      slippage,
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                child: ListView(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => context
                              .read<SwapTokenRouter>()
                              .onSelectInputToken(),
                          child: const Text('Input!'),
                        ),
                        ElevatedButton(
                          onPressed: () => context
                              .read<SwapTokenRouter>()
                              .onSelectOutputToken(),
                          child: const Text('Output!'),
                        ),
                        Flexible(
                          child: AmountDisplay(
                            value: _controller.text,
                            currency: state.amount.currency,
                            onTokenChanged: null,
                            availableTokens: IList(),
                          ),
                        ),
                      ],
                    ),
                    EnterAmountKeypad(
                      controller: _controller,
                      maxDecimals: state.selectedInput?.decimals ?? 0,
                    ),
                    CpContentPadding(
                      child: CpButton(
                        text: context.l10n.swapTokens,
                        onPressed: state.canSwap ? _onConfirm : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
