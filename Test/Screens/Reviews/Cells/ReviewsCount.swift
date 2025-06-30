import UIKit

struct ReviewsCountCellConfig: TableCellConfig {
    
    // Идентификатор для переиспользования
    static let reuseId = "ReviewsCountCellConfig"

    
    // Общее количество отзывов
    let totalCount: Int
    
    // Метод, который настраивает ячейку
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewsCountCell else { return }
        cell.countLabel.text = "\(totalCount) отзывов"
    }
    
    func height(with size: CGSize) -> CGFloat {
        return 44
    }
}

final class ReviewsCountCell: UITableViewCell {
    
    let countLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(countLabel)
        
        countLabel.textAlignment = .center
        countLabel.font = UIFont.reviewCount
        countLabel.textColor = UIColor.reviewCount
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            countLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
