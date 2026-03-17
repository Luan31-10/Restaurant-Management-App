import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/logic/blocs/end_of_day_report/end_of_day_report_bloc.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class EndOfDayScreen extends StatelessWidget {
  const EndOfDayScreen({super.key});

  // --- HÀM LOGIC ĐỂ IN BÁO CÁO ---
  Future<void> _printReport(BuildContext context, EndOfDayReportModel report) async {
    // Lưu ý: Đây là ví dụ in qua mạng. Bạn cần biết IP của máy in.
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);

    final res = await printer.connect('192.168.1.123', port: 9100); // <-- THAY IP MÁY IN CỦA BẠN

    if (res == PosPrintResult.success) {
      final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
      printer.text('BAO CAO CUOI NGAY', styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      printer.hr();
      printer.text('Thoi gian: ${DateFormat('dd/MM/yyyy HH:mm').format(report.reportTime)}');
      printer.hr();
      printer.row([
        PosColumn(text: 'Tong doanh thu:', width: 6),
        PosColumn(text: formatter.format(report.totalRevenue), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      printer.row([
        PosColumn(text: 'Tong so don:', width: 6),
        PosColumn(text: report.totalOrders.toString(), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      printer.row([
        PosColumn(text: 'Don da huy:', width: 6),
        PosColumn(text: report.cancelledOrders.toString(), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      printer.hr();
      printer.text('Doanh thu theo PT thanh toan:', styles: const PosStyles(bold: true));
      report.revenueByPaymentMethod.forEach((key, value) {
        printer.row([
          PosColumn(text: '- ${key.toUpperCase()}:', width: 6),
          PosColumn(text: formatter.format(value), width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
      });
      printer.hr();
      printer.feed(2);
      printer.cut();
      printer.disconnect();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi lệnh in!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi kết nối máy in: $res')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
    return Scaffold(
      appBar: AppBar(title: const Text('Chốt ca & Báo cáo cuối ngày')),
      body: Center(
        child: BlocConsumer<EndOfDayReportBloc, EndOfDayReportState>(
          listener: (context, state) {
            if (state is EndOfDayReportError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is EndOfDayReportLoading) {
              return const CircularProgressIndicator();
            }
            if (state is EndOfDayReportGenerated) {
              final report = state.report;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          Text('Báo cáo ngày ${DateFormat('dd/MM/yyyy').format(report.reportTime)}', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                          const Divider(height: 32),
                          _buildReportRow('Tổng doanh thu:', currencyFormatter.format(report.totalRevenue)),
                          _buildReportRow('Tổng số đơn đã bán:', report.totalOrders.toString()),
                          _buildReportRow('Số đơn đã hủy:', report.cancelledOrders.toString()),
                          const Divider(height: 32),
                          Text('Chi tiết theo thanh toán:', style: Theme.of(context).textTheme.titleLarge),
                          ...report.revenueByPaymentMethod.entries.map((entry) {
                            return _buildReportRow('- ${entry.key}:', currencyFormatter.format(entry.value));
                          }).toList(),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('In Báo cáo'),
                        onPressed: () => _printReport(context, report),
                      ),
                    )
                  ],
                ),
              );
            }
            return FilledButton.icon(
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Tạo Báo cáo Cuối ngày'),
              onPressed: () => context.read<EndOfDayReportBloc>().add(GenerateReport()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReportRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}