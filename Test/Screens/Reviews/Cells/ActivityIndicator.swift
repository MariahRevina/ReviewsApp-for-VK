import UIKit

final class ShowMoreActivityIndicator: UIView {

    private let circleLayer = CAShapeLayer()
    private let animationKey = "rotationAnimation"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    private func setupLayer() {
        let radius = bounds.width / 2
        let circularPath = UIBezierPath(
            arcCenter: CGPoint(x: radius, y: radius),
            radius: radius * 0.5,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true
        )

        circleLayer.path = circularPath.cgPath
        circleLayer.strokeColor = UIColor.systemBlue.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineWidth = 2
        circleLayer.strokeStart = 0
        circleLayer.strokeEnd = 0.7
        circleLayer.lineCap = .round

        layer.addSublayer(circleLayer)
    }

    func startAnimating() {
        guard circleLayer.animation(forKey: animationKey) == nil else { return }

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = 2 * CGFloat.pi
        rotationAnimation.duration = 0.5
        rotationAnimation.repeatCount = .infinity

        circleLayer.add(rotationAnimation, forKey: animationKey)
        isHidden = false
    }

    func stopAnimating() {
        circleLayer.removeAnimation(forKey: animationKey)
        isHidden = true
    }
}
