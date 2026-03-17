import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../data/services/api_service.dart';

part 'menu_item_event.dart';
part 'menu_item_state.dart';

class MenuItemBloc extends Bloc<MenuItemEvent, MenuItemState> {
  final ApiService apiService;

  MenuItemBloc({required this.apiService}) : super(MenuItemInitial()) {
    on<FetchMenuItems>((event, emit) async {
      emit(MenuItemLoading());
      try {
        final menuItems = await apiService.getMenuItems();

        // TỰ ĐỘNG LỌC RA DANH SÁCH CÁC DANH MỤC DUY NHẤT
        final categories = menuItems
            .map((item) => item.category) // Lấy ra tất cả các category
            .toSet() // Dùng Set để loại bỏ các giá trị trùng lặp
            .toList(); // Chuyển lại thành List

        // SỬA LẠI: Gửi cả 2 danh sách vào State
        emit(MenuItemLoaded(menuItems: menuItems, categories: categories));

      } catch (e) {
        // Lỗi này bây giờ sẽ hoạt động đúng vì MenuItemError chỉ cần 1 tham số
        emit(MenuItemError(e.toString()));
      }
    });
  }
}