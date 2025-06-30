import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {
    
    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?
    weak var reviewsViewController: ReviewsViewController?
    
    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder
    
    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
    }
    
}

// MARK: - Internal

extension ReviewsViewModel {
    
    typealias State = ReviewsViewModelState
    
    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        
        if state.offset == 0 && !state.isRefreshing {
            state.isInitialLoading = true
            DispatchQueue.main.async {
                self.onStateChange?(self.state)
            }
        }
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.reviewsProvider.getReviews(offset: self.state.offset) { result in
                DispatchQueue.main.async {
                    self.gotReviews(result)
                }
            }
        }
    }
    
    /// Метод сброса отзывов.
    func refreshReviews() {
        state.offset = 0
        state.shouldLoad = true
        state.isRefreshing = true
        getReviews()
    }
    
    func getItem(at index: Int) -> (any TableCellConfig)? {
        guard index >= 0, index < state.items.count else { return nil }
        return state.items[index]
    }
    
}

// MARK: - Private

private extension ReviewsViewModel {
    
    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)
            state.items.removeAll { $0 is ReviewsCountCellConfig }
            if state.offset == 0 { state.items.removeAll() }
            state.items += reviews.items.map(makeReviewItem)
            let countConfig = ReviewsCountCellConfig(totalCount: reviews.count)
            state.items.append(countConfig)
            state.offset += state.limit
            state.shouldLoad = state.offset < reviews.count
        } catch {
            state.shouldLoad = true
        }
        state.isInitialLoading = false
        state.isRefreshing = false
        onStateChange?(state)
    }
    
    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        state.heightCache[id] = nil
        onStateChange?(state)
    }
    
}

// MARK: - Items

private extension ReviewsViewModel {
    
    typealias ReviewItem = ReviewCellConfig
    
    func makeReviewItem(_ review: Review) -> ReviewItem {
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let userAvatar = UIImage(named: "l5w5aIHioYc")
        let userName = (review.first_name + " " + review.last_name).attributed(font: .username)
        let rating = review.rating
        let avatarUrl = review.avatar_url
        let availablePhotos = ["IMG_0001", "IMG_0002", "IMG_0003", "IMG_0004", "IMG_0005", "IMG_0006"]
        let randomPhotos = Array(availablePhotos.shuffled().prefix(Int.random(in: 0...5)))
        
        let item = ReviewItem(
            avatarURL: avatarUrl,
            userAvatar: userAvatar,
            userName: userName,
            rating: rating,
            reviewText: reviewText,
            created: created,
            photoNames: randomPhotos,
            onTapShowMore: { [weak self] id in
                self?.showMoreReview(with: id)
            }
        )
        return item
    }
    
}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let config = state.items[indexPath.row]
//        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
//        config.update(cell: cell)
//        return cell
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let config = getItem(at: indexPath.row) else {
            return UITableViewCell() // Защита от выхода за границы массива
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        config.update(cell: cell)

        // Проверяем, является ли config типом ReviewCellConfig
        if let reviewConfig = config as? ReviewCellConfig,
           let reviewCell = cell as? ReviewCell {
            reviewCell.updatePhotoGallery(photoNames: reviewConfig.photoNames)
            reviewCell.onImageTap = { [weak self] image in
            self?.presentPhotoViewer(with: image)
            }
        }

        return cell
    }

    private func presentPhotoViewer(with image: UIImage) {
        guard let viewController = reviewsViewController else {
            print("Ошибка: reviewsViewController = nil")
            return
        }
        
        let viewerVC = PhotoViewerViewController(image: image)
        viewerVC.modalPresentationStyle = .fullScreen
        viewController.present(viewerVC, animated: true)
    }

    
}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let config = state.items[indexPath.row]
        
        // Для ReviewCellConfig используем кэш
        if let reviewConfig = config as? ReviewCellConfig {
            let key = reviewConfig.id
            if let cachedHeight = state.heightCache[key] {
                return cachedHeight
            } else {
                let newHeight = reviewConfig.height(with: tableView.bounds.size)
                state.heightCache[key] = newHeight
                return newHeight
            }
        } else {
            // Для остальных типов высота фиксированная
            return config.height(with: tableView.bounds.size)
        }
    }
    
    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }
    
    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }
    
}
