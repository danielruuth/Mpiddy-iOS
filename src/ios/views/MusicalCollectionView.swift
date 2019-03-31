import UIKit


final class MusicalCollectionViewFlowLayout : UICollectionViewFlowLayout
{
	let sideSpan = CGFloat(10.0)
	let columns = 3

	override init()
	{
		super.init()
		setupLayout()
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	func setupLayout()
	{
		self.itemSize = CGSize(itemWidth(), itemWidth() + 20.0)
		self.sectionInset = UIEdgeInsets(top: sideSpan, left: sideSpan, bottom: sideSpan, right: sideSpan)
		self.scrollDirection = .vertical
	}

	private func itemWidth() -> CGFloat
	{
		return ceil((UIScreen.main.bounds.width / CGFloat(columns)) - (2 * sideSpan))
	}

	override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint
	{
		return collectionView?.contentOffset ?? .zero
	}
}


final class MusicalCollectionView : UICollectionView
{
	// MARK: - Properties
	// Type of entities displayed
	var musicalEntityType = MusicalEntityType.albums
	{
		didSet
		{
			self.register(MusicalEntityBaseCell.self, forCellWithReuseIdentifier: self.cellIdentifier())
		}
	}

	init(frame: CGRect, musicalEntityType: MusicalEntityType)
	{
		super.init(frame: frame, collectionViewLayout: MusicalCollectionViewFlowLayout())

		self.isPrefetchingEnabled = false
		self.backgroundColor = Colors.background

		self.musicalEntityType = musicalEntityType
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Private
	private func cellIdentifier() -> String
	{
		switch musicalEntityType
		{
			case .albums:
				return "fr.whine.shinobu.cell.musicalentity.album"
			case .artists:
				return "fr.whine.shinobu.cell.musicalentity.artist"
			case .albumsartists:
				return "fr.whine.shinobu.cell.musicalentity.albumartist"
			case .genres:
				return "fr.whine.shinobu.cell.musicalentity.genre"
			case .playlists:
				return "fr.whine.shinobu.cell.musicalentity.playlist"
		}
	}
}

// MARK: - UIScrollViewDelegate
extension MusicalCollectionView
{
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
	{
		self.reloadItems(at: self.indexPathsForVisibleItems)
	}
}
