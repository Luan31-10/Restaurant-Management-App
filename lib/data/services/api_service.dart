import 'dart:convert'; // Thêm import này nếu chưa có
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qlnh_app/data/models/cart_item_model.dart';
import 'package:qlnh_app/data/models/active_order_model.dart';
import 'package:qlnh_app/data/models/table_model.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';
import 'package:qlnh_app/data/models/user_model.dart';
import 'package:qlnh_app/data/models/reservation_model.dart';
import '../../logic/blocs/end_of_day_report/end_of_day_report_bloc.dart';
import 'package:qlnh_app/logic/blocs/statistics/statistics_bloc.dart';
import 'package:qlnh_app/logic/blocs/sales_report/sales_report_bloc.dart';
import 'package:qlnh_app/logic/blocs/timekeeping_report/timekeeping_report_bloc.dart';
import 'package:qlnh_app/logic/blocs/dashboard/dashboard_bloc.dart';

class ApiService {
  late final Dio _dio;

  // Giữ nguyên baseUrl của bạn
  final String baseUrl = 'http://192.168.1.71:3000/api';

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl, 
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Logic đính kèm token
          if (!options.path.contains('/auth/signin') &&
              !options.path.contains('/auth/verify-admin') &&
              !options.path.contains('/auth/complete-admin-login')) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print(
              ' DioError: ${e.requestOptions.method} ${e.requestOptions.uri}');
          if (e.response != null) {
            print('    Status: ${e.response?.statusCode}');
            print('    Data: ${e.response?.data}');
          } else {
            print('    Error: ${e.message}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  // --- CÁC HÀM API ---

  Future<List<TableModel>> getTables() async {
    try {
      final response = await _dio.get('/tables');
      final List<dynamic> tableList = response.data as List<dynamic>;
      return tableList.map((json) =>
          TableModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Không thể tải danh sách bàn';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ getTables Parse Error: $e");
      throw Exception("Lỗi parse dữ liệu bàn.");
    }
  }

  Future<UserModel> login(String pin) async {
    try {
      final response = await _dio.post('/auth/signin', data: {'pin': pin});
      final user = UserModel.fromJson(response.data);
      if (user.accessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', user.accessToken!);
      }
      return user;
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Lỗi đăng nhập';
      throw Exception(errorMessage);
    }
  }

  Future<UserModel> verifyAdmin(int userId, String masterPin) async {
    try {
      final response = await _dio.post('/auth/verify-admin',
          data: {'userId': userId, 'masterPin': masterPin});
      final user = UserModel.fromJson(response.data);
      if (user.accessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', user.accessToken!);
      }
      return user;
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Xác thực admin thất bại';
      throw Exception(errorMessage);
    }
  }

  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _dio.get('/users');
      return (response.data as List).map((json) =>
          UserModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi tải danh sách người dùng';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ getUsers Parse Error: $e");
      throw Exception("Lỗi parse dữ liệu người dùng.");
    }
  }

  Future<void> createUser(String name, String pin, String role) async {
    try {
      await _dio.post('/users', data: {'name': name, 'pin': pin, 'role': role});
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi tạo người dùng';
      throw Exception(errorMessage);
    }
  }

  Future<void> updateUser(int id, String name, String role) async {
    try {
      await _dio.put('/users/$id', data: {'name': name, 'role': role});
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi cập nhật người dùng';
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _dio.delete('/users/$id');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi xóa người dùng';
      throw Exception(errorMessage);
    }
  }

  Future<List<MenuItemModel>> getMenuItems() async {
    try {
      final response = await _dio.get('/menu-items');
      return (response.data as List).map((json) =>
          MenuItemModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Không thể tải thực đơn';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ getMenuItems Parse Error: $e");
      throw Exception("Lỗi parse dữ liệu thực đơn.");
    }
  }

  Future<void> createOrder(int tableId, List<CartItemModel> cartItems,
      [String? customerPhone]) async {
    try {
      final List<Map<String, dynamic>> itemsJson = cartItems.map((item) =>
      {'menuItemId': item.menuItem.id, 'quantity': item.quantity}).toList();
      final Map<String, dynamic> requestData = {
        'tableId': tableId,
        'items': itemsJson
      };
      if (customerPhone != null && customerPhone.isNotEmpty) {
        requestData['customerPhone'] = customerPhone;
      }
      await _dio.post('/orders', data: requestData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tạo order');
    }
  }

  Future<void> editOrder(int orderId, List<CartItemModel> updatedItems) async {
    try {
      final List<Map<String, dynamic>> itemsJson = updatedItems.map((item) =>
      {'menuItemId': item.menuItem.id, 'quantity': item.quantity}).toList();
      await _dio.put('/orders/$orderId/items', data: {'items': itemsJson});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi sửa order');
    }
  }

  Future<void> updateOrderStatus(int orderId, String status,
      {String? paymentMethod}) async {
    try {
      final Map<String, dynamic> data = {'status': status};
      if (paymentMethod != null) data['paymentMethod'] = paymentMethod;
      await _dio.patch('/orders/$orderId', data: data);
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi cập nhật trạng thái order';
      throw Exception(errorMessage);
    }
  }

  Future<void> updateTableStatus(int tableId, String status) async {
    try {
      await _dio.patch('/tables/$tableId', data: {'status': status});
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi cập nhật trạng thái bàn';
      throw Exception(errorMessage);
    }
  }

  Future<List<ActiveOrderModel>> getKitchenOrders() async {
    try {
      final response = await _dio.get('/orders/kitchen/active');
      return (response.data as List).map((json) =>
          ActiveOrderModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Không thể tải danh sách order cho bếp';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ getKitchenOrders Parse Error: $e");
      throw Exception("Lỗi parse dữ liệu order bếp.");
    }
  }

  Future<void> updateOrderItemStatus(
      {required int orderItemId, required String status}) async {
    try {
      await _dio.patch('/orders/items/$orderItemId', data: {'status': status});
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi cập nhật trạng thái món ăn';
      throw Exception(errorMessage);
    }
  }

  Future<void> createMenuItem(Map<String, dynamic> data) async {
    try {
      await _dio.post('/menu-items', data: data);
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Lỗi khi tạo món ăn';
      throw Exception(errorMessage);
    }
  }

  Future<void> updateMenuItem(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/menu-items/$id', data: data);
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi cập nhật món ăn';
      throw Exception(errorMessage);
    }
  }

  Future<List<MenuItemModel>> getMenuItemsForAdmin() async {
    dynamic rawData;
    try {
      print("--- Gọi API GET /menu-items/all ---");
      final response = await _dio.get('/menu-items/all');
      print("--- Nhận được response từ /menu-items/all ---");
      rawData = response.data;
      print("   Kiểu dữ liệu data: ${rawData.runtimeType}");
      print("   Nội dung data: ${rawData}");

      List<dynamic> rawList;
      if (rawData is List) {
        rawList = rawData;
        print("   Dữ liệu là List với ${rawList.length} items.");
      } else
      if (rawData is Map<String, dynamic> && rawData.containsKey('data') &&
          rawData['data'] is List) {
        rawList = rawData['data'] as List<dynamic>;
        print("   Dữ liệu là Map, lấy List từ key 'data' (${rawList
            .length} items).");
      }
      else {
        print(
            "❌ getMenuItemsForAdmin Error: API response is not a List or expected Map. Type: ${rawData
                .runtimeType}");
        throw Exception("API không trả về danh sách món ăn hợp lệ.");
      }

      print("   Bắt đầu parse từng item menu...");
      List<MenuItemModel> menuItems = [];
      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is Map<String, dynamic>) {
          try {
            menuItems.add(MenuItemModel.fromJson(item));
          } catch (parseError, parseStacktrace) {
            print(
                "❌ Lỗi parse MenuItemModel.fromJson tại index $i: $parseError");
            print("   Item JSON bị lỗi: $item");
            print("   Stacktrace parse: $parseStacktrace");
            throw Exception(
                "Lỗi parse dữ liệu món ăn tại index $i: $parseError");
          }
        } else {
          print("❌ ERROR: Item menu tại index $i không phải Map. Value: $item");
          throw Exception(
              "Item không hợp lệ trong danh sách món ăn tại index $i.");
        }
      }
      print("--- Parse thành công ${menuItems.length} menu items. ---");
      return menuItems;
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Không thể tải thực đơn cho admin';
      print('❌ getMenuItemsForAdmin DioError: $errorMessage');
      if (e.response?.data != null) print('   Error Data: ${e.response?.data}');
      throw Exception(errorMessage);
    } catch (e, stacktrace) {
      print('❌ getMenuItemsForAdmin Unexpected Error: $e');
      print('   Stacktrace: $stacktrace');
      if (rawData != null) print('   Raw Data at time of error: $rawData');
      throw Exception('Lỗi xử lý dữ liệu menu items: $e');
    }
  }

  Future<void> deleteMenuItem(int id) async {
    try {
      await _dio.delete('/menu-items/$id');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Lỗi khi xóa món ăn';
      throw Exception(errorMessage);
    }
  }

  Future<List<ReservationModel>> getReservations({DateTime? filterDate}) async {
    try {
      Map<String, dynamic>? queryParameters;
      if (filterDate != null) {
        queryParameters = {
          'filterDate': filterDate.toIso8601String().split('T').first,
        };
      }
      final response = await _dio.get(
        '/reservations',
        queryParameters: queryParameters,
      );

      // === ĐẢM BẢO DÒNG PRINT NÀY ĐÚNG VỊ TRÍ ===
      print('>>> ApiService Raw reservation data received: ${response.data}');
      // ==========================================

      // Kiểm tra kiểu dữ liệu trước khi map
      if (response.data is List) {
        return (response.data as List).map((json) =>
            ReservationModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        print('❌ getReservations Error: response.data is NOT a List. Type: ${response.data.runtimeType}');
        throw Exception('API không trả về danh sách đặt bàn hợp lệ.');
      }

    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Không thể tải danh sách đặt bàn';
      throw Exception(errorMessage);
    } catch (e, stacktrace) {
      print("❌ getReservations Map/Parse Error: $e"); // Lỗi xảy ra trong .map hoặc fromJson
      print("   Stacktrace: $stacktrace");
      throw Exception("Lỗi parse dữ liệu đặt bàn.");
    }
  }

  Future<void> createReservation(Map<String, dynamic> data) async {
    try {
      await _dio.post('/reservations', data: data);
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Lỗi khi tạo đặt bàn';
      throw Exception(errorMessage);
    }
  }

  Future<void> updateReservationStatus(String id, String status) async {
    // API CỦA BẠN: router.patch("/:id", controller.updateReservationStatus);
    await _dio.patch(
      '/reservations/$id',
      data: {'status': status},
    );
  }

  Future<ReservationModel> updateReservation(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(
      '/reservations/$id',
      data: data,
    );
    return ReservationModel.fromJson(response.data);
  }

  Future<void> deleteReservation(String id) async {
    await _dio.delete('/reservations/$id');
  }

  Future<void> seatCustomer(String id) async {
    await _dio.post('/reservations/$id/seat');
  }

  Future<List<MenuItemModel>> getRecommendations(int menuItemId) async {
    try {
      final response = await _dio.get('/ai/recommendations/$menuItemId');
      return (response.data as List).map((json) =>
          MenuItemModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException {
      return [];
    } catch (e) {
      print("❌ getRecommendations Parse Error: $e");
      return [];
    }
  }

  Future<List<MenuItemModel>> getBestsellers() async {
    try {
      final response = await _dio.get('/ai/bestsellers');
      return (response.data as List).map((json) =>
          MenuItemModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException {
      return [];
    } catch (e) {
      print("❌ getBestsellers Parse Error: $e");
      return [];
    }
  }

  Future<List<RevenueData>> fetchRevenue(String period) async {
    try {
      final response = await _dio.get(
          '/statistics', queryParameters: {'period': period});
      return (response.data as List).map((item) =>
          RevenueData(
            label: item['label'] as String,
            revenue: (item['revenue'] as num).toDouble(),
            orderCount: item['orderCount'] as int,
          )
      ).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi tải dữ liệu thống kê';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ fetchRevenue Parse Error: $e");
      throw Exception("Lỗi parse dữ liệu thống kê.");
    }
  }

  Future<SalesReportModel> getSalesReport(DateTime startDate,
      DateTime endDate) async {
    try {
      final String start = DateFormat('yyyy-MM-dd').format(startDate);
      // Sửa: End date không cần +1 ngày nếu API backend xử lý đúng
      final String end = DateFormat('yyyy-MM-dd').format(endDate);
      // final String end = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1))); // Giữ lại nếu backend cần

      final response = await _dio.get(
        '/reports/sales',
        queryParameters: {'startDate': start, 'endDate': end},
      );
      return SalesReportModel.fromJson(
          response.data); // Giả sử model này xử lý parse
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi tải báo cáo bán hàng';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ getSalesReport Parse Error: $e");
      throw Exception("Lỗi parse dữ liệu báo cáo bán hàng.");
    }
  }

  Future<String> getClockInStatus() async {
    try {
      final response = await _dio.get('/timeclock/status');
      // Kiểm tra kiểu dữ liệu trả về
      if (response.data != null && response.data['status'] is String) {
        return response.data['status'] as String;
      } else {
        print("⚠️ getClockInStatus: API response không đúng định dạng.");
        throw Exception("Không nhận được trạng thái chấm công hợp lệ.");
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi lấy trạng thái chấm công';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ getClockInStatus Error: $e");
      throw Exception("Lỗi không xác định khi lấy trạng thái chấm công.");
    }
  }

  Future<void> clockIn() async {
    try {
      await _dio.post('/timeclock/clock-in');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Lỗi khi check-in';
      throw Exception(errorMessage);
    }
  }

  Future<void> clockOut() async {
    try {
      await _dio.post('/timeclock/clock-out');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Lỗi khi check-out';
      throw Exception(errorMessage);
    }
  }

  Future<List<DetailedTimeClockEntry>> getDetailedTimekeepingReport(
      DateTime startDate, DateTime endDate) async {
    try {
      final String start = DateFormat('yyyy-MM-dd').format(startDate);
      // Sửa: End date không cần +1 ngày
      final String end = DateFormat('yyyy-MM-dd').format(endDate);
      // final String end = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));

      final response = await _dio.get(
        '/reports/timekeeping/details',
        queryParameters: {'startDate': start, 'endDate': end},
      );

      final List<dynamic> reportList = response.data as List<dynamic>;
      return reportList
          .map((json) =>
          DetailedTimeClockEntry.fromJson(json as Map<String, dynamic>))
          .toList(); // Thêm ép kiểu
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi tải báo cáo chấm công';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ getDetailedTimekeepingReport Parse Error: $e");
      throw Exception("Lỗi parse dữ liệu báo cáo chấm công.");
    }
  }

  Future<EndOfDayReportModel> generateEndOfDayReport() async {
    try {
      final response = await _dio.post('/reports/end-of-day');
      return EndOfDayReportModel.fromJson(
          response.data); // Giả sử model xử lý parse
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi tạo báo cáo cuối ngày';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ generateEndOfDayReport Parse Error: $e");
      throw Exception("Lỗi parse dữ liệu báo cáo cuối ngày.");
    }
  }

  Future<List<PastReportInfo>> getPastReports() async {
    try {
      final response = await _dio.get('/reports/end-of-day');
      final List<dynamic> reportList = response.data as List<dynamic>;
      return reportList
          .map((json) =>
          PastReportInfo.fromJson(json as Map<String, dynamic>))
          .toList(); // Thêm ép kiểu
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi tải danh sách báo cáo cũ';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ getPastReports Parse Error: $e");
      throw Exception("Lỗi parse dữ liệu báo cáo cũ.");
    }
  }

  Future<EndOfDayReportModel> getReportById(int id) async {
    try {
      final response = await _dio.get('/reports/end-of-day/$id');
      return EndOfDayReportModel.fromJson(
          response.data); // Giả sử model xử lý parse
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi tải chi tiết báo cáo';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ getReportById Parse Error: $e");
      throw Exception("Lỗi parse dữ liệu chi tiết báo cáo.");
    }
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      String fileName = imageFile.path
          .split('/')
          .last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
            imageFile.path, filename: fileName),
      });

      final response = await _dio.post('/upload/image', data: formData);
      // Kiểm tra xem imageUrl có tồn tại và là string không
      if (response.data != null && response.data['imageUrl'] is String) {
        return response.data['imageUrl'];
      } else {
        print("⚠️ uploadImage: API response không chứa imageUrl hợp lệ.");
        throw Exception("Không nhận được URL ảnh sau khi tải lên.");
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Lỗi khi tải ảnh lên';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ uploadImage Error: $e");
      throw Exception("Lỗi không xác định khi tải ảnh lên.");
    }
  }

  Future<DashboardModel> getDashboardData() async {
    try {
      final response = await _dio.get('/dashboard');
      // Thêm kiểm tra null và kiểu dữ liệu trước khi truy cập
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw Exception("Dữ liệu dashboard trống.");

      final summaryData = data['todaySummary'] as Map<String, dynamic>? ?? {};
      final summary = TodaySummary(
        totalRevenue: (num.tryParse(
            summaryData['totalRevenue']?.toString() ?? '0') ?? 0).toDouble(),
        totalOrders: (num.tryParse(
            summaryData['totalOrders']?.toString() ?? '0') ?? 0).toInt(),
        // Parse an toàn hơn
        averageOrderValue: (num.tryParse(
            summaryData['averageOrderValue']?.toString() ?? '0') ?? 0)
            .toDouble(),
      );

      final topItemsData = data['topMenuItems'] as List? ?? [];
      final topItems = topItemsData.map((item) {
        final itemMap = item as Map<String, dynamic>? ?? {};
        return TopMenuItem(
          name: itemMap['MenuItem.name']?.toString() ?? 'N/A', // Xử lý null
          totalQuantity: int.tryParse(
              itemMap['totalQuantity']?.toString() ?? '0') ??
              0, // Parse an toàn
        );
      }).toList();

      final hourlyRevenueData = data['revenueByHour'] as List? ?? [];
      final hourlyRevenue = hourlyRevenueData.map((item) {
        final itemMap = item as Map<String, dynamic>? ?? {};
        return RevenueByHour(
          hour: (num.tryParse(itemMap['hour']?.toString() ?? '-1') ?? -1)
              .toInt(), // Parse an toàn
          revenue: (num.tryParse(itemMap['revenue']?.toString() ?? '0') ?? 0)
              .toDouble(),
        );
      }).toList();

      return DashboardModel(
        todaySummary: summary,
        topMenuItems: topItems,
        revenueByHour: hourlyRevenue,
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi tải dữ liệu dashboard';
      throw Exception(errorMessage);
    } catch (e, stacktrace) {
      print("❌ getDashboardData Parse Error: $e");
      print("   Stacktrace: $stacktrace");
      throw Exception("Lỗi parse dữ liệu dashboard.");
    }
  }

  Future<List<RevenueDataPoint>> fetchDetailedStatistics(String period) async {
    try {
      final response = await _dio.get(
          '/statistics/details', queryParameters: {'period': period});
      final List<dynamic> dataList = response.data as List<dynamic>;
      return dataList
          .map((json) =>
          RevenueDataPoint.fromJson(json as Map<String, dynamic>))
          .toList(); // Thêm ép kiểu
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Lỗi khi tải chi tiết thống kê';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ fetchDetailedStatistics Parse Error: $e");
      throw Exception("Lỗi parse dữ liệu chi tiết thống kê.");
    }
  }

  Future<String> createVnpayUrl(int orderId, double amount,
      String ipAddr) async {
    try {
      final response = await _dio.post('/payment/create_vnpay_url',
          data: {'orderId': orderId, 'amount': amount, 'ipAddr': ipAddr});
      if (response.data != null && response.data['paymentUrl'] is String) {
        return response.data['paymentUrl'];
      } else {
        print("⚠️ createVnpayUrl: API response không chứa paymentUrl hợp lệ.");
        throw Exception("Không nhận được URL thanh toán VNPay.");
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Không thể tạo URL thanh toán';
      throw Exception(errorMessage);
    } catch (e) {
      print("❌ createVnpayUrl Error: $e");
      throw Exception("Lỗi không xác định khi tạo URL VNPay.");
    }
  }

  Future<UserModel> completeAdminLogin(int userId) async {
    try {
      final response = await _dio.post(
          '/auth/complete-admin-login', data: {'userId': userId});
      final user = UserModel.fromJson(response.data);
      if (user.accessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', user.accessToken!);
        print('✅ Admin Token saved after biometric!');
      } else {
        print('⚠️ No admin token received after biometric!');
      }
      return user;
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Hoàn tất đăng nhập admin thất bại';
      print('❌ completeAdminLogin Error: $errorMessage');
      throw Exception(errorMessage);
    }
  }
}