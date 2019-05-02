import UIKit


fileprivate let space = CGFloat(4)


final class ImagedLabel: UIControl
{
	// MARK: - Public properties
	// Label
	private(set) var label = UILabel()
	// Image
	private(set) var imageView = UIImageView()
	// Alignment (lbl & image)
	var align = NSTextAlignment.left
	{
		didSet
		{
			self.label.textAlignment = align
			self.updateFrames()
		}
	}

	// MARK: - Properties override
	override var frame: CGRect
	{
		didSet
		{
			self.updateFrames()
		}
	}

	// MARK: - UILabel properties
	// Text
	public var text: String?
	{
		get
		{
			return self.label.text
		}
		set
		{
			self.label.text = newValue
		}
	}
	// Attributed text
	public var attributedText: NSAttributedString?
	{
		get
		{
			return self.label.attributedText
		}
		set
		{
			self.label.attributedText = newValue
		}
	}
	// Text color
	public var textColor: UIColor!
	{
		get
		{
			return self.label.textColor
		}
		set
		{
			self.label.textColor = newValue
		}
	}
	// Font
	public var font: UIFont!
	{
		get
		{
			return self.label.font
		}
		set
		{
			self.label.font = newValue
		}
	}

	// MARK: - UIImageView properties
	// Image
	public var image: UIImage?
	{
		get
		{
			return self.imageView.image
		}
		set
		{
			self.imageView.image = newValue
		}
	}

	// MARK: - Initializers
	init()
	{
		super.init(frame: .zero)

		commonInit()
	}

	override init(frame: CGRect)
	{
		super.init(frame: frame)

		commonInit()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	private func commonInit()
	{
		self.imageView.frame = CGRect(.zero, frame.height, frame.height)
		self.addSubview(self.imageView)

		self.label.frame = CGRect(self.imageView.maxX + space, 0, frame.width - self.imageView.maxX - space, frame.height)
		self.addSubview(self.label)

		initializeTheming()
	}

	// MARK: - Private
	private func updateFrames()
	{
		if align == .left
		{
			imageView.frame = CGRect(.zero, frame.height, frame.height)
			label.frame = CGRect(imageView.maxX + space, 0, frame.width - imageView.maxX - space, frame.height)
		}
		else
		{
			imageView.frame = CGRect(frame.width - frame.height, 0, frame.height, frame.height)
			label.frame = CGRect(.zero, frame.width - frame.height - space, frame.height)
		}
	}
}

extension ImagedLabel: Themed
{
	func applyTheme(_ theme: Theme)
	{

	}
}