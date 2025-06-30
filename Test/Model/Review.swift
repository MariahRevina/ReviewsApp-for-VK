/// Модель отзыва.
struct Review: Decodable {

    /// Текст отзыва.
    let text: String
    /// Время создания отзыва.
    let created: String
    /// Имя пользователя,
    let first_name: String
    /// Фамилия пользователя
    let last_name: String
    /// Рейтинг отзыва
    let rating: Int
    /// URL аватара пользователя.
    let avatar_url: String?
}
