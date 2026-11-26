import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api_client.dart';
import '../core/format.dart';
import '../state/app_state.dart';
import 'bank_screen.dart';

class BankPayoutScreen extends StatefulWidget {
  const BankPayoutScreen({
    super.key,
    required this.state,
    required this.availableBalancePaise,
  });

  final AppState state;
  final int availableBalancePaise;

  @override
  State<BankPayoutScreen> createState() => _BankPayoutScreenState();
}

class _BankPayoutScreenState extends State<BankPayoutScreen> {
  static const _green = Color(0xFF07583D);
  static const _deepGreen = Color(0xFF064A35);
  static const _pale = Color(0xFFF5F8EF);
  static const _ink = Color(0xFF173F32);
  static const _muted = Color(0xFF7D8981);
  static const _line = Color(0xFFE7EBE5);

  final _amountController = TextEditingController(text: '0');
  bool _instant = true;
  bool _busy = false;
  bool _loadingMethods = true;
  bool _hasPrimaryAccount = false;
  String? _error;

  int get _amountRupees => int.tryParse(_amountController.text.trim()) ?? 0;
  int get _feeRupees => _instant ? 10 : 0;
  int get _receiveRupees => (_amountRupees - _feeRupees).clamp(0, 1 << 30).toInt();
  int get _balanceRupees => widget.availableBalancePaise ~/ 100;

  @override
  void initState() {
    super.initState();
    _loadPayoutMethods();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPayoutMethods() async {
    try {
      final result = await widget.state.api.get('/v1/payout-methods');
      final methods = mapList(result);
      if (!mounted) return;
      setState(() {
        _hasPrimaryAccount = methods.any((m) => asBool(m['isPrimary']));
        _loadingMethods = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMethods = false);
    }
  }

  void _setAmount(int value) {
    setState(() {
      _amountController.text = value.toString();
      _error = null;
    });
  }

  Future<void> _openAccounts() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BankScreen(state: widget.state),
    ));
    await _loadPayoutMethods();
  }

  Future<void> _transfer() async {
    if (!_hasPrimaryAccount) {
      setState(() => _error = 'Please add and verify a primary payout account first.');
      return;
    }
    if (_amountRupees < 100) {
      setState(() => _error = 'Minimum instant payout amount is ₹100.');
      return;
    }
    if (_amountRupees > _balanceRupees) {
      setState(() => _error = 'Amount cannot be higher than your available balance.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await widget.state.api.post(
        '/v1/payouts/instant',
        body: {'amountPaise': _amountRupees * 100},
        headers: {'Idempotency-Key': DateTime.now().microsecondsSinceEpoch.toString()},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout request submitted successfully.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Could not submit the payout. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final nextPayout = DateTime.now().add(Duration(
      days: (DateTime.monday - DateTime.now().weekday + 7) % 7 == 0
          ? 7
          : (DateTime.monday - DateTime.now().weekday + 7) % 7,
    ));
    final dateLabel = DateFormatForPayout.short(nextPayout);

    return Scaffold(
      backgroundColor: _pale,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The design is laid out on a 393 x 844 canvas, then scaled down
            // only when the available device height is smaller.
            return SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 393,
                  height: 844,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -25,
                        right: -35,
                        child: Transform.rotate(
                          angle: -.55,
                          child: Icon(Icons.eco_rounded, size: 120,
                              color: const Color(0xFFB9D69B).withOpacity(.18)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 72,
                              child: Row(
                                children: [
                                  Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => Navigator.of(context).pop(),
                                      child: const SizedBox(
                                        width: 54, height: 54,
                                        child: Icon(Icons.arrow_back, color: _ink, size: 24),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 17),
                                  const Text('Bank payout',
                                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: _ink)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _balanceCard(dateLabel),
                            const SizedBox(height: 14),
                            _payoutChoice(
                              selected: !_instant,
                              title: 'Weekly payout',
                              subtitle: 'Free · lands Monday by 6 PM',
                              badge: '●  Free',
                              badgeColor: const Color(0xFFDDF1E7),
                              badgeText: _green,
                              onTap: () => setState(() { _instant = false; _error = null; }),
                            ),
                            const SizedBox(height: 13),
                            _payoutChoice(
                              selected: _instant,
                              title: 'Instant payout',
                              subtitle: 'Within 30 min · min ₹100',
                              badge: '●  ₹10 fee',
                              badgeColor: const Color(0xFFFFF0C9),
                              badgeText: const Color(0xFF8B6412),
                              onTap: () => setState(() { _instant = true; _error = null; }),
                            ),
                            const SizedBox(height: 17),
                            _amountCard(),
                            const SizedBox(height: 17),
                            _accountCard(),
                            const SizedBox(height: 17),
                            _summaryRow('Amount', '₹${_amountRupees.toStringAsFixed(2)}'),
                            const SizedBox(height: 9),
                            _summaryRow(
                              _instant ? 'Instant fee (from balance)' : 'Payout fee',
                              _instant ? '₹${_feeRupees.toStringAsFixed(2)}' : '₹0.00',
                            ),
                            const SizedBox(height: 9),
                            _summaryRow('You receive', '₹${_receiveRupees.toStringAsFixed(2)}', emphasize: true),
                            if (_error != null) ...[
                              const SizedBox(height: 7),
                              Text(_error!, maxLines: 2,
                                style: const TextStyle(color: Color(0xFFB42318), fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                            const Spacer(),
                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _busy || !_instant ? null : _transfer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _green,
                                  disabledBackgroundColor: const Color(0xFF9EB8AA),
                                  foregroundColor: Colors.white,
                                  elevation: 7,
                                  shadowColor: _green.withOpacity(.20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                ),
                                child: _busy
                                  ? const SizedBox(width: 21, height: 21,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(_instant ? 'TRANSFER ₹$_amountRupees NOW' : 'WEEKLY PAYOUT SELECTED',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text('Payouts go only to your verified primary account.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: _muted)),
                            const SizedBox(height: 7),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _balanceCard(String dateLabel) => Container(
    height: 108,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(27),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_deepGreen, Color(0xFF197448)],
      ),
      boxShadow: [
        BoxShadow(
          color: _green.withOpacity(.14),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Available to withdraw',
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFD7E9DD),
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${_balanceRupees.toStringAsFixed(2)}',
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Auto-payout Mon, $dateLabel',
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD7E9DD),
              fontSize: 10,
              height: 1.1,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _payoutChoice({
    required bool selected,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required Color badgeText,
    required VoidCallback onTap,
  }) => Material(
    color: selected ? const Color(0xFFF6FAED) : Colors.white,
    borderRadius: BorderRadius.circular(25),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: selected ? _green : _line, width: selected ? 1.4 : 1),
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? _green : const Color(0xFFD4D9D4), size: 25),
          const SizedBox(width: 13),
          Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _ink, fontSize: 14, height: 1.1, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 10.5, height: 1.1)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
            child: Text(badge, style: TextStyle(color: badgeText, fontSize: 9, height: 1.0, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    ),
  );

  Widget _amountCard() => Container(
    height: 126,
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _line),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            color: _ink,
            fontSize: 13,
            height: 1.0,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(
          height: 39,
          child: Row(
            children: [
              const Text(
                '₹',
                style: TextStyle(
                  fontSize: 25,
                  height: 1.0,
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  onChanged: (_) => setState(() => _error = null),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF68736D),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1.5, color: _green),
        const SizedBox(height: 5),
        SizedBox(
          height: 34,
          child: Row(
            children: [
              Expanded(child: _quickAmount('₹500', 500)),
              const SizedBox(width: 5),
              Expanded(child: _quickAmount('₹1,000', 1000)),
              const SizedBox(width: 5),
              Expanded(child: _quickAmount('₹2,000', 2000)),
              const SizedBox(width: 5),
              Expanded(
                child: ActionChip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: const Text(
                    'All',
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  onPressed: () => _setAmount(_balanceRupees),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _line),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _quickAmount(String label, int value) => ActionChip(
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    label: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, style: const TextStyle(
        color: _ink, fontWeight: FontWeight.w700, fontSize: 11,
      )),
    ),
    onPressed: () => _setAmount(value > _balanceRupees ? _balanceRupees : value),
    backgroundColor: Colors.white,
    side: const BorderSide(color: _line),
    padding: EdgeInsets.zero,
  );

  Widget _accountCard() => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25),
    child: InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: _openAccounts,
      child: SizedBox(
        height: 66,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: const Color(0xFFEEF5DB), borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.account_balance_outlined, color: _green, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_loadingMethods ? 'Checking payout account' : _hasPrimaryAccount ? 'Primary payout account' : 'No payout account yet',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _ink, fontSize: 13, height: 1.1, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(_hasPrimaryAccount ? 'Your saved account details' : 'Add one to get paid',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 10.5, height: 1.1)),
              ],
            )),
            Text(_hasPrimaryAccount ? 'View' : 'Add',
              style: const TextStyle(color: _green, fontSize: 14, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    ),
  );

  Widget _summaryRow(String label, String value, {bool emphasize = false}) => Row(
    children: [
      Expanded(child: Text(label,
        style: TextStyle(color: emphasize ? _ink : _muted, fontSize: 12.5,
          fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500))),
      Text(value, style: TextStyle(color: emphasize ? _green : const Color(0xFF252A27),
        fontSize: 13.5, fontWeight: FontWeight.w800)),
    ],
  );
}

class DateFormatForPayout {
  static String short(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }
}
