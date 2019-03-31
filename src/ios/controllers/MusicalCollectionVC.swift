import UIKit


class MusicalCollectionVC : NYXViewController
{
	// MARK: - Private properties
	// Collection view
	private(set) var collectionView: MusicalCollectionView!
	// Search view
	private(set) var searchView: UIView! = nil
	// Search bar
	private(set) var searchBar: UISearchBar! = nil
	// Should show the search view, flag
	private(set) var searchBarVisible = false
	// Is currently searching, flag
	private(set) var searching = false
	// Long press gesture is recognized, flag
	var longPressRecognized = false
	// Previewing context for peek & pop
	private(set) var previewingContext: UIViewControllerPreviewing! = nil
	// Long press gesture for devices without force touch
	private(set) var longPress: UILongPressGestureRecognizer! = nil

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Remove back button label
		navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "btn-back")
		navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "btn-back")
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		// Search button
		let searchButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-search"), style: .plain, target: self, action: #selector(showSearchBarAction(_:)))
		searchButton.accessibilityLabel = NYXLocalizedString("lbl_search")
		navigationItem.rightBarButtonItems = [searchButton]

		// Searchbar
		let navigationBar = (navigationController?.navigationBar)!
		searchView = UIView(frame: CGRect(0.0, 0.0, navigationBar.width, navigationBar.bottom))
		searchBar = UISearchBar(frame: CGRect(0.0, navigationBar.y, navigationBar.width, navigationBar.height))
		searchView.backgroundColor = Colors.background
		searchView.alpha = 0.0
		searchBar.searchBarStyle = .minimal
		searchBar.barTintColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		searchBar.tintColor = Colors.main
		(searchBar.value(forKey: "searchField") as? UITextField)?.textColor = Colors.main
		searchBar.showsCancelButton = true
		searchBar.delegate = self
		searchView.addSubview(searchBar)

		// Collection view
		collectionView = MusicalCollectionView(frame: self.view.bounds, collectionViewLayout: UICollectionViewLayout())
		collectionView.myDelegate = self
		self.view.addSubview(collectionView)

		// Longpress
		longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
		longPress.minimumPressDuration = 0.5
		longPress.delaysTouchesBegan = true
		updateLongpressState()

		// Double tap
		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
		doubleTap.numberOfTapsRequired = 2
		doubleTap.numberOfTouchesRequired = 1
		doubleTap.delaysTouchesBegan = true
		collectionView.addGestureRecognizer(doubleTap)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Since we are in search mode, show the bar
		if searchView.superview == nil
		{
			navigationController?.view.addSubview(searchView)
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		if searchView.superview != nil
		{
			searchView.removeFromSuperview()
		}
	}

	// MARK: - Gestures
	@objc func longPress(_ gest: UILongPressGestureRecognizer)
	{

	}

	@objc func doubleTap(_ gest: UITapGestureRecognizer)
	{
	}

	// MARK: - Actions
	@objc func showSearchBarAction(_ sender: Any?)
	{
		UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
			self.searchView.alpha = 1.0
			self.searchBar.becomeFirstResponder()
		}, completion: { finished in
			self.searchBarVisible = true
		})
	}

	// MARK: - Public
	public func updateLongpressState()
	{
#if DEBUG
		collectionView.addGestureRecognizer(longPress)
		longPress.isEnabled = true
#else
		if traitCollection.forceTouchCapability == .available
		{
			collectionView.removeGestureRecognizer(_longPress)
			longPress.isEnabled = false
			previewingContext = registerForPreviewing(with: self, sourceView: collectionView)
		}
		else
		{
			collectionView.addGestureRecognizer(_longPress)
			longPress.isEnabled = true
		}
#endif
	}

	// MARK: - Private
	private func showNavigationBar(animated: Bool = true)
	{
		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay: 0.0, options: .curveEaseOut, animations: {
			self.searchBar.resignFirstResponder()
			self.searchView.alpha = 0.0
		}, completion: { finished in
			self.searchBarVisible = false
		})
	}
}

// MARK: - UISearchBarDelegate
extension MusicalCollectionVC : UISearchBarDelegate
{
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
	{
		collectionView.searchResults.removeAll()
		searching = false
		searchBar.text = ""
		showNavigationBar(animated: true)
		collectionView.reloadData()
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
	{
		searchBar.resignFirstResponder()
		searchBar.endEditing(true)
		collectionView.reloadData()
	}

	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
	{
		searching = true
		// Copy original source to avoid crash when nothing was searched
		collectionView.searchResults = MusicDataSource.shared.selectedList()
	}

	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
	{
		if MusicDataSource.shared.selectedList().count > 0
		{
			if String.isNullOrWhiteSpace(searchText)
			{
				collectionView.searchResults = MusicDataSource.shared.selectedList()
				collectionView.reloadData()
				return
			}

			if Settings.shared.bool(forKey: .pref_fuzzySearch)
			{
				collectionView.searchResults = MusicDataSource.shared.selectedList().filter({$0.name.fuzzySearch(withString: searchText)})
			}
			else
			{
				collectionView.searchResults = MusicDataSource.shared.selectedList().filter({$0.name.lowercased().contains(searchText.lowercased())})
			}

			collectionView.reloadData()
		}
	}
}

// MARK: - MusicalCollectionViewDelegate
extension MusicalCollectionVC : MusicalCollectionViewDelegate
{
	@objc func isSearching(actively: Bool) -> Bool
	{
		return false
	}

	@objc func didSelectItem(indexPath: IndexPath)
	{
		
	}
}