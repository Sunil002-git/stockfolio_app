import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/broker_provider.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/broker_selector_bar.dart';
 
final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
 
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}
 
class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String,dynamic>> _txns    = [];
  bool    _loading    = true;
  String  _typeFilter = '';  // '' = all, 'deposit', 'withdraw'
  int?    _lastBroker = -99;
 
  // Form state
  String   _formType    = 'deposit';
  final _amountCtrl  = TextEditingController();
  final _noteCtrl    = TextEditingController();
  DateTime _formDate = DateTime.now();
  int?     _formBrokerId;
  bool     _submitting = false;
  String?  _formError;
 
  @override
  void initState() { super.initState(); _load(); }
 
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final b = context.read<BrokerProvider>().activeBrokerId;
    if (b != _lastBroker) { _lastBroker = b; _load(); }
  }
 
  @override
  void dispose() {
    _amountCtrl.dispose(); _noteCtrl.dispose(); super.dispose();
  }
 
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api    = context.read<ApiService>();
      final broker = context.read<BrokerProvider>().brokerParam;
      final params = <String,String>{};
      if (_typeFilter.isNotEmpty) params['type']   = _typeFilter;
      if (broker != null)         params['broker'] = broker;
      final res = await api.get('transactions/', params: params);
      if (mounted) setState(() {
        _txns   = List<Map<String,dynamic>>.from(res.data as List);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  Future<void> _addTransaction() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      setState(() => _formError = 'Enter a valid amount.');
      return;
    }
    setState(() { _submitting = true; _formError = null; });
    try {
      final payload = {
        'type':   _formType,
        'amount': amount,
        'note':   _noteCtrl.text.trim(),
        'date':   _formDate.toIso8601String().split('T')[0],
      };
      final brokerId = _formBrokerId;
      if (brokerId != null) payload['broker_id'] = brokerId;
      await context.read<ApiService>().post('transactions/', data: payload);
      _amountCtrl.clear(); _noteCtrl.clear();
      setState(() { _submitting = false; _formDate = DateTime.now(); });
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_formType == 'deposit' ? 'Deposit' : 'Withdrawal'} recorded!'),
          backgroundColor: AppColors.green,
        ),
      );
    } on DioException catch (e) {
      setState(() {
        _submitting = false;
        _formError  = e.response?.data?['error'] ?? 'Failed.';
      });
    }
  }
 
  // Summary totals
  double get _totalDeposit  =>
    _txns.where((t) => t['type'] == 'deposit')
    .fold(0.0, (s,t) => s + (t['amount'] as num).toDouble());
  double get _totalWithdraw =>
    _txns.where((t) => t['type'] == 'withdraw')
    .fold(0.0, (s,t) => s + (t['amount'] as num).toDouble());
 
  @override
  Widget build(BuildContext context) {
    final brokers = context.watch<BrokerProvider>().brokers;
    return Scaffold(
      appBar: AppBar(title: const Text('Funds')),
      body: Column(
        children: [
          const BrokerSelectorBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.brand,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Add form ──────────────────────────────
                  _AddForm(
                    formType:     _formType,
                    amountCtrl:   _amountCtrl,
                    noteCtrl:     _noteCtrl,
                    formDate:     _formDate,
                    brokerId:     _formBrokerId,
                    brokers:      brokers,
                    submitting:   _submitting,
                    error:        _formError,
                    onTypeChange: (v) => setState(() => _formType = v),
                    onDateChange: (d) => setState(() => _formDate = d),
                    onBrokerChange:(v) => setState(() => _formBrokerId = v),
                    onSubmit:     _addTransaction,
                  ),
                  const SizedBox(height: 16),
                  // ── Summary cards ─────────────────────────
                  Row(children: [
                    Expanded(child: _SummaryCard(
                      label: 'Deposits',
                      value: _totalDeposit,
                      color: AppColors.green,
                      icon:  Icons.arrow_downward,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _SummaryCard(
                      label: 'Withdrawals',
                      value: _totalWithdraw,
                      color: AppColors.red,
                      icon:  Icons.arrow_upward,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _SummaryCard(
                      label: 'Net',
                      value: _totalDeposit - _totalWithdraw,
                      color: AppColors.brand,
                      icon:  Icons.account_balance_wallet_outlined,
                    )),
                  ]),
                  const SizedBox(height: 16),
                  // ── Filter row ────────────────────────────
                  Row(children: [
                    ...[['All',''],['Deposits','deposit'],['Withdrawals','withdraw']]
                      .map((item) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label:    Text(item[0]),
                          selected: _typeFilter == item[1],
                          onSelected: (_) => setState(() {
                            _typeFilter = item[1]; _load();
                          }),
                          selectedColor: AppColors.brand.withOpacity(0.2),
                          checkmarkColor: AppColors.brand,
                          backgroundColor: AppColors.bgInput,
                          side: BorderSide(color: _typeFilter == item[1]
                            ? AppColors.brand : AppColors.border),
                          labelStyle: TextStyle(color: _typeFilter == item[1]
                            ? AppColors.brand : AppColors.textMuted),
                        ),
                      )).toList(),
                  ]),
                  const SizedBox(height: 12),
                  // ── List ──────────────────────────────────
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_txns.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text(
                        'No transactions yet.',
                        style: TextStyle(color: AppColors.textMuted),
                      )),
                    )
                  else
                    ...(_txns.map((t) => _TxnTile(txn: t,
                      onDelete: () async {
                        await context.read<ApiService>().delete('transactions/${t['id']}/');
                        _load();
                      },
                    ))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
// ── Add form widget ─────────────────────────────────────────────
class _AddForm extends StatelessWidget {
  final String   formType;
  final TextEditingController amountCtrl, noteCtrl;
  final DateTime formDate;
  final int?     brokerId;
  final List     brokers;
  final bool     submitting;
  final String?  error;
  final void Function(String)   onTypeChange;
  final void Function(DateTime) onDateChange;
  final void Function(int?)     onBrokerChange;
  final VoidCallback            onSubmit;
  const _AddForm({
    required this.formType,    required this.amountCtrl,
    required this.noteCtrl,    required this.formDate,
    required this.brokerId,    required this.brokers,
    required this.submitting,  required this.error,
    required this.onTypeChange,required this.onDateChange,
    required this.onBrokerChange, required this.onSubmit,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add Transaction',
            style: TextStyle(fontWeight: FontWeight.bold,
              fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          // Deposit / Withdraw toggle
          Row(children: [
            Expanded(child: _TypeBtn(
              label: 'Deposit',
              icon:  Icons.arrow_downward,
              active: formType == 'deposit',
              color:  AppColors.green,
              onTap:  () => onTypeChange('deposit'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _TypeBtn(
              label: 'Withdraw',
              icon:  Icons.arrow_upward,
              active: formType == 'withdraw',
              color:  AppColors.red,
              onTap:  () => onTypeChange('withdraw'),
            )),
          ]),
          const SizedBox(height: 12),
          if (error != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.red.withOpacity(0.3)),
              ),
              child: Text(error!,
                style: const TextStyle(color: AppColors.red, fontSize: 13)),
            ),
          Row(children: [
            Expanded(child: AuthTextField(
              label: 'Amount ₹',
              hint:  '0.00',
              controller: amountCtrl,
              prefixIcon: Icons.currency_rupee,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            )),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: formDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) onDateChange(d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    '${formDate.day}/${formDate.month}/${formDate.year}',
                    style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (brokers.isNotEmpty)
            DropdownButtonFormField<int?>(
              value: brokerId,
              decoration: const InputDecoration(
                labelText: 'Broker (optional)',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— No Broker —')),
                ...brokers.map((b) => DropdownMenuItem(
                  value: (b as dynamic).id as int,
                  child: Text(b.name as String),
                )),
              ],
              onChanged: onBrokerChange,
            ),
          const SizedBox(height: 10),
          AuthTextField(
            label: 'Note (optional)',
            hint:  'Monthly top-up, profit withdrawal...',
            controller: noteCtrl,
            prefixIcon: Icons.notes_outlined,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: submitting ? null : onSubmit,
            icon: submitting
              ? const SizedBox(width:18,height:18,
                  child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
              : Icon(formType == 'deposit'
                  ? Icons.arrow_downward : Icons.arrow_upward),
            label: Text('Add ${formType == 'deposit' ? 'Deposit' : 'Withdrawal'}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: formType == 'deposit'
                ? AppColors.green : AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}
 
// Type toggle button
class _TypeBtn extends StatelessWidget {
  final String label; final IconData icon;
  final bool active; final Color color;
  final VoidCallback onTap;
  const _TypeBtn({required this.label,required this.icon,
    required this.active,required this.color,required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : AppColors.bgInput,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: active ? color : AppColors.textMuted, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            color: active ? color : AppColors.textMuted,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          )),
        ]),
      ),
    );
  }
}
 
// Summary card
class _SummaryCard extends StatelessWidget {
  final String label; final double value;
  final Color color; final IconData icon;
  const _SummaryCard({required this.label,required this.value,
    required this.color,required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(_inr.format(value),
            style: TextStyle(fontWeight: FontWeight.bold,
              fontSize: 13, color: color),
            overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(
            fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
 
// Transaction list tile
class _TxnTile extends StatelessWidget {
  final Map<String,dynamic> txn;
  final VoidCallback onDelete;
  const _TxnTile({required this.txn, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final isDeposit = txn['type'] == 'deposit';
    final amount    = (txn['amount'] as num).toDouble();
    final color     = isDeposit ? AppColors.green : AppColors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
            color: color, size: 18),
        ),
        title: Row(children: [
          Text(isDeposit ? 'DEPOSIT' : 'WITHDRAW',
            style: TextStyle(fontWeight: FontWeight.bold,
              fontSize: 13, color: color)),
          if (txn['broker_name'] != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.purple.withOpacity(0.3)),
              ),
              child: Text(
                txn['broker_name'] as String,
                style: const TextStyle(
                  fontSize: 10, color: AppColors.purple,
                  fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ]),
        subtitle: Text('${txn['date']}  ${txn['note'] ?? ''}',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${isDeposit ? "+" : "−"}${_inr.format(amount)}',
            style: TextStyle(fontWeight: FontWeight.bold,
              fontSize: 14, color: color)),
          IconButton(
            icon: const Icon(Icons.delete_outline,
              color: AppColors.textHint, size: 18),
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.bgCard,
                title: const Text('Delete transaction?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Delete', style: TextStyle(color: AppColors.red))),
                ],
              ),
            ).then((confirmed) { if (confirmed == true) onDelete(); }),
          ),
        ]),
      ),
    );
  }
}
