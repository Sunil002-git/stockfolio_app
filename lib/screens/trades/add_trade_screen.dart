import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/broker_provider.dart';
import '../../widgets/auth_text_field.dart';
 
class AddTradeScreen extends StatefulWidget {
  const AddTradeScreen({super.key});
  @override
  State<AddTradeScreen> createState() => _AddTradeScreenState();
}
 
class _AddTradeScreenState extends State<AddTradeScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _symbolCtrl   = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _qtyCtrl      = TextEditingController();
  final _chargesCtrl  = TextEditingController(text: '0');
  final _notesCtrl    = TextEditingController();
  String  _segment    = 'equity';
  String  _exchange   = 'NSE';
  int?    _brokerId;
  bool    _loading    = false;
  String? _error;
  DateTime _date      = DateTime.now();
 
  static const _segments = [
    'equity','futures','ce','pe','mf'
  ];
  static const _exchanges = [
    'NSE','BSE','MCX','NFO','BFO'
  ];
 
  @override
  void dispose() {
    _symbolCtrl.dispose(); _priceCtrl.dispose();
    _qtyCtrl.dispose(); _chargesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _date,
      firstDate:   DateTime(2000),
      lastDate:    DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final api  = context.read<ApiService>();
      final data = <String, dynamic>{
        'symbol':    _symbolCtrl.text.trim().toUpperCase(),
        'segment':   _segment,
        'exchange':  _exchange,
        'buy_price': double.parse(_priceCtrl.text),
        'quantity':  int.parse(_qtyCtrl.text),
        'charges':   double.parse(_chargesCtrl.text),
        'date':      _date.toIso8601String().split('T')[0],
        'notes':     _notesCtrl.text,
      };
      if (_brokerId != null) data['broker_id'] = _brokerId;
      await api.post('trades/buy/', data: data);
      if (mounted) {
        // Return true — caller (PositionsScreen) will reload
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Buy trade added!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } on DioException catch (e) {
      final errData = e.response?.data;
      String msg = 'Failed to add trade.';
      if (errData is Map) {
        final errs = <String>[];
        (errData as Map).forEach((k, v) {
          if (v is List) errs.add('$k: ${v.first}');
          else if (v is String) errs.add(v);
        });
        if (errs.isNotEmpty) msg = errs.join(', ');
      }
      if (mounted) setState(() { _loading = false; _error = msg; });
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final brokers = context.watch<BrokerProvider>().brokers;
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Buy Trade'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
 
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
                  const SizedBox(height: 16),
                ],
 
                // Symbol
                AuthTextField(
                  label: 'Stock Symbol',
                  hint:  'e.g. RELIANCE',
                  controller: _symbolCtrl,
                  prefixIcon: Icons.search,
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Symbol is required' : null,
                ),
                const SizedBox(height: 14),
 
                // Segment + Exchange
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    value: _segment,
                    decoration: InputDecoration(
                      labelText: 'Segment',
                      filled: true,
                      fillColor: AppColors.bgInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.border)),
                    ),
                    items: _segments.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _segment = v!),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField<String>(
                    value: _exchange,
                    decoration: InputDecoration(
                      labelText: 'Exchange',
                      filled: true,
                      fillColor: AppColors.bgInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.border)),
                    ),
                    items: _exchanges.map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _exchange = v!),
                  )),
                ]),
                const SizedBox(height: 14),
 
                // Price + Qty
                Row(children: [
                  Expanded(child: AuthTextField(
                    label: 'Buy Price ₹',
                    hint:  '0.00',
                    controller: _priceCtrl,
                    prefixIcon: Icons.currency_rupee,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true),
                    validator: (v) => (v == null || v.isEmpty)
                      ? 'Required' : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: AuthTextField(
                    label: 'Quantity',
                    hint:  '0',
                    controller: _qtyCtrl,
                    prefixIcon: Icons.numbers,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty)
                      ? 'Required' : null,
                  )),
                ]),
                const SizedBox(height: 14),
 
                // Charges
                AuthTextField(
                  label: 'Charges ₹',
                  hint:  '0.00',
                  controller: _chargesCtrl,
                  prefixIcon: Icons.receipt_outlined,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true),
                ),
                const SizedBox(height: 14),
 
                // Date picker
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText:  'Trade Date',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      filled:     true,
                      fillColor:  AppColors.bgInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.border)),
                    ),
                    child: Text(
                      '${_date.day}/${_date.month}/${_date.year}',
                      style: const TextStyle(
                        color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(height: 14),
 
                // Broker
                if (brokers.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    value: _brokerId,
                    decoration: InputDecoration(
                      labelText:  'Broker (optional)',
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
                        value: null,
                        child: Text('— No Broker —')),
                      ...brokers.map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name))),
                    ],
                    onChanged: (v) => setState(() => _brokerId = v),
                  ),
                if (brokers.isNotEmpty) const SizedBox(height: 14),
 
                // Notes
                AuthTextField(
                  label: 'Notes (optional)',
                  hint:  'Strategy, reason for entry...',
                  controller: _notesCtrl,
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: 24),
 
                ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                    ? const SizedBox(width:20,height:20,
                        child:CircularProgressIndicator(
                          strokeWidth:2.5,color:Colors.white))
                    : const Icon(Icons.add_circle_outline,
                        color: Colors.white),
                  label: const Text('Add Buy Trade',
                    style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
