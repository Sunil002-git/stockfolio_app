import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../models/trade_group.dart';
import '../../providers/broker_provider.dart';
import '../../widgets/auth_text_field.dart';
 
// SellTradeSheet — slides up as a BottomSheet.
// Returns true via Navigator.pop(context, true) if sell was submitted.
class SellTradeSheet extends StatefulWidget {
  final TradeGroup position;
  const SellTradeSheet({super.key, required this.position});
  @override
  State<SellTradeSheet> createState() => _SellTradeSheetState();
}
 
class _SellTradeSheetState extends State<SellTradeSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _priceCtrl  = TextEditingController();
  final _qtyCtrl    = TextEditingController();
  final _chargesCtrl= TextEditingController(text: '0');
  final _notesCtrl  = TextEditingController();
  int?  _brokerId;
  bool  _loading = false;
  String? _error;
 
  @override
  void initState() {
    super.initState();
    // Pre-fill quantity with current holding
    _qtyCtrl.text = widget.position.totalQuantity.toString();
    // Pre-fill broker from existing position broker
    _brokerId = widget.position.brokerId;
  }
 
  @override
  void dispose() {
    _priceCtrl.dispose(); _qtyCtrl.dispose();
    _chargesCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final api  = context.read<ApiService>();
      final data = <String, dynamic>{
        'group_id':  widget.position.id,
        'sell_price': double.parse(_priceCtrl.text),
        'quantity':   int.parse(_qtyCtrl.text),
        'charges':    double.parse(_chargesCtrl.text),
        'date':       DateTime.now().toIso8601String().split('T')[0],
        'notes':      _notesCtrl.text,
      };
      if (_brokerId != null) data['broker_id'] = _brokerId;
      await api.post('trades/sell/', data: data);
      if (mounted) {
        // Return true — caller reloads positions
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.position.symbol} sold successfully!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error   = e.response?.data?['error'] ?? 'Sell failed.';
      });
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final pos     = widget.position;
    final brokers = context.watch<BrokerProvider>().brokers;
    // Sheet height adapts to keyboard
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
 
    return Container(
      decoration: const BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPad),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
              )),
 
              // Title
              Row(children: [
                Expanded(child: Text(
                  'Sell ${pos.symbol}',
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary))),
                // Available qty badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('Available: ${pos.totalQuantity}',
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted))),
              ]),
              const SizedBox(height: 4),
              Text('Avg cost: ₹${pos.avgCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 20),
 
              // Error banner
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.red.withOpacity(0.4))),
                  child: Text(_error!,
                    style: const TextStyle(
                      color: AppColors.red, fontSize: 13))),
                const SizedBox(height: 14),
              ],
 
              // Sell price + quantity row
              Row(children: [
                Expanded(child: AuthTextField(
                  label:       'Sell Price ₹',
                  hint:        '0.00',
                  controller:   _priceCtrl,
                  prefixIcon:   Icons.currency_rupee,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true),
                  validator: (v) => (v == null || v.isEmpty)
                    ? 'Required' : null,
                )),
                const SizedBox(width: 12),
                Expanded(child: AuthTextField(
                  label:       'Quantity',
                  hint:        '0',
                  controller:   _qtyCtrl,
                  prefixIcon:   Icons.numbers,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0)
                      return 'Must be > 0';
                    if (n > pos.totalQuantity)
                      return 'Max ${pos.totalQuantity}';
                    return null;
                  },
                )),
              ]),
              const SizedBox(height: 14),
 
              // Charges
              AuthTextField(
                label:       'Charges ₹',
                hint:        '0.00',
                controller:   _chargesCtrl,
                prefixIcon:   Icons.receipt_outlined,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true),
              ),
              const SizedBox(height: 14),
 
              // Broker dropdown
              if (brokers.isNotEmpty)
                DropdownButtonFormField<int?>(
                  value: _brokerId,
                  decoration: InputDecoration(
                    labelText:  'Broker',
                    prefixIcon: const Icon(Icons.business_outlined),
                    filled:     true,
                    fillColor:  AppColors.bgInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.border)),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null, child: Text('— No Broker —')),
                    ...brokers.map((b) => DropdownMenuItem(
                      value: b.id,
                      child: Text(b.name))),
                  ],
                  onChanged: (v) => setState(() => _brokerId = v),
                ),
              if (brokers.isNotEmpty) const SizedBox(height: 14),
 
              // Notes
              AuthTextField(
                label:     'Notes (optional)',
                hint:      'Exit reason, observations...',
                controller: _notesCtrl,
                prefixIcon: Icons.notes_outlined,
              ),
              const SizedBox(height: 20),
 
              // Action buttons
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Cancel'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                  ),
                  icon: _loading
                    ? const SizedBox(width:18,height:18,
                        child:CircularProgressIndicator(
                          strokeWidth:2,color:Colors.white))
                    : const Icon(Icons.sell_outlined,
                        color: Colors.white),
                  label: const Text('Confirm Sell',
                    style: TextStyle(color: Colors.white)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
