import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {
    
    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)
    
    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
    /// URL аватара пользователя.
    let avatarURL: String?
    /// Аватар пользователя, оставившего отзыв.
    let userAvatar: UIImage?
    /// Имя пользователя
    let userName: NSAttributedString
    /// рейтинг отзыва
    let rating: Int
    /// Текст отзыва.
    let reviewText: NSAttributedString
    /// Максимальное отображаемое количество строк текста. По умолчанию 3.
    var maxLines = 3
    /// Время создания отзыва.
    let created: NSAttributedString
    /// Массив изображений к отзыву
    var photoNames: [String]?
    /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
    let onTapShowMore: (UUID) -> Void
    
    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()
    fileprivate let ratingRenderer: RatingRenderer = RatingRenderer()
}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {
    
    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created
        cell.avatarImageView.image = userAvatar
        cell.usernameLabel.attributedText = userName
        cell.ratingImageView.image = ratingRenderer.ratingImage(rating)
        cell.config = self
        cell.updatePhotoGallery(photoNames: photoNames)
        
        if let avatarURL = avatarURL, let url = URL(string: avatarURL) {
            ImageLoader.shared.loadImage(from: url) { [weak cell] image in
                guard let cell = cell else { return }
                cell.avatarImageView.image = image
            }
        } else {
            cell.avatarImageView.image = userAvatar
        }
    }
    
    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }
    
}

// MARK: - Private

private extension ReviewCellConfig {
    
    /// Текст кнопки "Показать полностью...".
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)
    
}

// MARK: - Cell

final class ReviewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    private let showMoreIndicator = ShowMoreActivityIndicator(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
    
    fileprivate var config: Config?
    
    fileprivate let reviewTextLabel = UILabel()
    fileprivate let createdLabel = UILabel()
    fileprivate let showMoreButton = UIButton()
    
    fileprivate let avatarImageView = UIImageView()
    fileprivate let usernameLabel = UILabel()
    fileprivate let ratingImageView = UIImageView()
    
    private let photoCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.itemSize = CGSize(width: 55, height: 66)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    var onImageTap: ((UIImage) -> Void)?
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        createdLabel.frame = layout.createdLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
        avatarImageView.frame = layout.avatarFrame
        usernameLabel.frame = layout.usernameFrame
        ratingImageView.frame = layout.ratingFrame
        showMoreIndicator.center = showMoreButton.center
        photoCollectionView.frame = layout.photoGalleryFrame
    }
    
    func updatePhotoGallery(photoNames: [String]?) {
        config?.photoNames = photoNames
        photoCollectionView.reloadData()
    }
}

// MARK: - Private

private extension ReviewCell {
    
    func setupCell() {
        setupReviewTextLabel()
        setupCreatedLabel()
        setupShowMoreButton()
        setupAvatarImageView()
        setupUsernameLabel()
        setupRatingImageView()
        setupShowMoreIndicator()
        setupPhotoCollectionView()
    }
    
    func setupPhotoCollectionView() {
        contentView.addSubview(photoCollectionView)
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        photoCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
    }
    
    func setupReviewTextLabel() {
        contentView.addSubview(reviewTextLabel)
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupCreatedLabel() {
        contentView.addSubview(createdLabel)
    }
    
    func setupShowMoreButton() {
        contentView.addSubview(showMoreButton)
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
        showMoreButton.addTarget(self, action: #selector(didTapShowMore), for: .touchUpInside)
    }
    
    func setupAvatarImageView() {
        contentView.addSubview(avatarImageView)
        avatarImageView.layer.cornerRadius = Layout.avatarCornerRadius
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
    }
    
    func setupUsernameLabel() {
        contentView.addSubview(usernameLabel)
    }
    
    func setupRatingImageView() {
        contentView.addSubview(ratingImageView)
        ratingImageView.contentMode = .scaleAspectFit
    }
    
    func setupShowMoreIndicator() {
        contentView.addSubview(showMoreIndicator)
        showMoreIndicator.isHidden = true
    }
    
    @objc
    private func didTapShowMore() {
        guard let id = config?.id else { return }
        
        showMoreButton.isHidden = true
        showMoreIndicator.startAnimating()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showMoreIndicator.stopAnimating()
            self?.showMoreButton.isHidden = false
            self?.config?.onTapShowMore(id)
        }
    }
}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {
    
    // MARK: - Размеры
    
    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0
    
    private static let photoSize = CGSize(width: 55.0, height: 66.0)
    private static let showMoreButtonSize = Config.showMoreText.size()
    
    // MARK: - Фреймы
    
    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero
    private(set) var avatarFrame = CGRect.zero
    private(set) var usernameFrame = CGRect.zero
    private(set) var ratingFrame = CGRect.zero
    private(set) var photoGalleryFrame = CGRect.zero
    
    // MARK: - Отступы
    
    /// Отступы от краёв ячейки до её содержимого.
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)
    
    /// Горизонтальный отступ от аватара до имени пользователя.
    private let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    private let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    private let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    private let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    private let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    private let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    private let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    private let showMoreToCreatedSpacing = 6.0
    
    // MARK: - Расчёт фреймов и высоты ячейки
    // Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let contentWidth = maxWidth - insets.left - insets.right
        var maxY = insets.top
        
        // Размеры аватара пользователя
        avatarFrame = CGRect(
            x: insets.left,
            y: maxY,
            width: Self.avatarSize.width,
            height: Self.avatarSize.height
        )
        
        // Точка, откуда начинаем крепить имя, рейтинг и тд
        let rightBlockX = avatarFrame.maxX + avatarToUsernameSpacing
        let rightBlockWidth = contentWidth - Self.avatarSize.width - avatarToUsernameSpacing
        
        // Считаем размер текста имени пользователя
        let usernameSize = config.userName.boundingRect(
            with: CGSize(width: rightBlockWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        
        // Размещение имени в справа
        usernameFrame = CGRect(
            x: rightBlockX,
            y: maxY,
            width: min(usernameSize.width, rightBlockWidth),
            height: usernameSize.height
        )
        // Сдвигаем maxY, чтобы следующий элемент шёл под именем
        maxY = usernameFrame.maxY + usernameToRatingSpacing
        
        // Размещение рейтинга
        let ratingHeight: CGFloat = 16
        let ratingWidth: CGFloat = 80
        ratingFrame = CGRect(
            x: rightBlockX,
            y: maxY,
            width: ratingWidth,
            height: ratingHeight
        )
        // Сдвигаем maxY, чтобы текст отзыва шёл под рейтингом
        maxY = ratingFrame.maxY + ratingToTextSpacing
        
        // Фото
        if let photoAssets = config.photoNames, !photoAssets.isEmpty {
            let galleryHeight: CGFloat = Self.photoSize.height
            let galleryWidth = CGFloat(min(photoAssets.count, 5)) * (Self.photoSize.width + photosSpacing)
            photoGalleryFrame = CGRect(x: rightBlockX, y: maxY, width: galleryWidth, height: galleryHeight)
            maxY = photoGalleryFrame.maxY + photosToTextSpacing
        } else {
            photoGalleryFrame = .zero
        }
        
        // Текст отзыва
        var showShowMoreButton = false
        if !config.reviewText.isEmpty() {
            // Высота текста с текущим ограничением по количеству строк.
            let currentTextHeight = (config.reviewText.font()?.lineHeight ?? .zero) * CGFloat(config.maxLines)
            // Максимально возможная высота текста, если бы ограничения не было.
            let actualTextHeight = config.reviewText.boundingRect(width: rightBlockWidth).size.height
            // Показываем кнопку "Показать полностью...", если максимально возможная высота текста больше текущей.
            showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight
            
            reviewTextLabelFrame = CGRect(
                origin: CGPoint(x: rightBlockX, y: maxY),
                size: config.reviewText.boundingRect(width: rightBlockWidth, height: currentTextHeight).size
            )
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }
        
        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: rightBlockX, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }
        
        // Дата
        let createdSize = config.created.boundingRect(width: rightBlockWidth)
        createdLabelFrame = CGRect(
            x: rightBlockX,
            y: maxY,
            width: createdSize.width,
            height: createdSize.height
        )
        maxY = createdLabelFrame.maxY
        
        // Итоговая высота ячейки
        let totalHeight = max(avatarFrame.maxY, maxY) + insets.bottom
        return totalHeight
    }
}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout


// MARK: - UICollectionViewDataSource

extension ReviewCell {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return config?.photoNames?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        if let photoName = config?.photoNames?[indexPath.row] {
            cell.setImage(named: photoName)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photoName = config?.photoNames?[indexPath.row], let image = UIImage(named: photoName) else { return }
        onImageTap?(image)
    }
}
