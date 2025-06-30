/// Модель, хранящая состояние вью модели.
import Foundation

struct ReviewsViewModelState {
    var items = [any TableCellConfig]()
    var limit = 20
    var offset = 0
    var shouldLoad = true
    var isInitialLoading = false
    var isRefreshing = false
    var heightCache = [UUID: CGFloat]()
}
