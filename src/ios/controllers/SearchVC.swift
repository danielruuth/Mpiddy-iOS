import UIKit

final class SearchVC: NYXViewController {
	// MARK: - Private properties
	// MPD Data source
	private let mpdBridge: MPDBridge
	// Blurred view
	private let blurEffectView = UIVisualEffectView()
	// Search view (searchbar + tableview)
	private let searchZone = UIView()
	// Search bar
	private var searchBar: UISearchBar! = nil
	// Tableview for results
	private var tableView: UITableView! = nil
	// All MPD albums
	private var albums = [Album]()
	// All MPD artists
	private var artists = [Artist]()
	// All MPD album artists
	private var albumsartists = [Artist]()
	// Search results
	private var albumsResults = [Album]()
	private var artistsResults = [Artist]()
	private var albumsartistsResults = [Artist]()
	// Searching flag
	private var searching = false
	// Tap gesture to dismiss
	private let singleTap = UITapGestureRecognizer()

	// MARK: - Initializers
	init(mpdBridge: MPDBridge) {
		self.mpdBridge = mpdBridge

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		view.frame = CGRect(.zero, view.width, view.height)
		view.backgroundColor = .clear
        view.isOpaque = false

		// Blurred background
		blurEffectView.effect = UIBlurEffect(style: traitCollection.userInterfaceStyle == .dark ? .dark : .light)
		blurEffectView.frame = view.bounds
		blurEffectView.isUserInteractionEnabled = true
		view.addSubview(blurEffectView)

		let y = UIApplication.shared.mainWindow?.safeAreaInsets.top ?? 0
		searchZone.frame = CGRect(10, y, view.width - 20, 44)
		view.addSubview(searchZone)

		searchBar = UISearchBar(frame: CGRect(0, 0, searchZone.width, 44))
		searchBar.searchBarStyle = .minimal
		searchBar.showsCancelButton = false
		searchBar.delegate = self
		searchBar.placeholder = NYXLocalizedString("lbl_search_library")
		searchZone.addSubview(searchBar)
		searchZone.enableCorners(withDivisor: 10)
		searchZone.frame = CGRect(10, y, view.width - 20, 300)

		tableView = UITableView(frame: CGRect(0, searchBar.maxY, searchZone.width, searchZone.height - searchBar.height), style: .plain)
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "fr.whine.shinobu.cell.search")
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.dataSource = self
		tableView.delegate = self
		tableView.tableFooterView = UIView()
		searchZone.addSubview(tableView)

		// Single tap to request full player view
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		singleTap.addTarget(self, action: #selector(singleTap(_:)))
		blurEffectView.addGestureRecognizer(singleTap)

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)

		initializeTheming()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		mpdBridge.entitiesForType(.albums, callback: { entities in
			self.albums = entities as! [Album]
		})

		mpdBridge.entitiesForType(.artists, callback: { entities in
			self.artists = entities as! [Artist]
		})

		mpdBridge.entitiesForType(.albumsartists, callback: { entities in
			self.albumsartists = entities as! [Artist]
		})

		searchBar.becomeFirstResponder()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}

	// MARK: - Notifications
	@objc func keyboardWillShow(_ aNotification: Notification?) {
		guard let notif = aNotification else { return }
		guard let userInfos = notif.userInfo else { return }
		guard let kbFrame = userInfos["UIKeyboardFrameEndUserInfoKey"] as? CGRect else { return }
		guard let duration = userInfos["UIKeyboardAnimationDurationUserInfoKey"] as? Double else { return }
		guard let curve = userInfos["UIKeyboardAnimationCurveUserInfoKey"] as? UInt else { return }
		var y = UIApplication.shared.mainWindow?.safeAreaInsets.top ?? 0
		y += UIApplication.shared.mainWindow?.safeAreaInsets.bottom ?? 0
		UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16), animations: {
			self.searchZone.height = (kbFrame.y - self.searchZone.y) - 10
			self.tableView.height = self.searchZone.height - self.searchBar.height
		}, completion: nil)
	}

	@objc func singleTap(_ gesture: UITapGestureRecognizer) {
		self.dismiss(animated: true, completion: nil)
	}

	// MARK: - Private
	private func handleEmptyView(tableView: UITableView, isEmpty: Bool) {
		if isEmpty {
			let emptyView = UIView(frame: CGRect(x: tableView.center.x, y: tableView.center.y, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
			emptyView.backgroundColor = tableView.backgroundColor

			let lbl = UILabel(frame: .zero)
			lbl.text = NYXLocalizedString("lbl_no_search_results")
			lbl.font = UIFont.systemFont(ofSize: 32, weight: .ultraLight)
			lbl.translatesAutoresizingMaskIntoConstraints = false
			lbl.tintColor = .label
			lbl.sizeToFit()
			emptyView.addSubview(lbl)
			lbl.x = (emptyView.width - lbl.width) / 2
			lbl.y = (emptyView.height - lbl.height) / 2

			tableView.backgroundView = emptyView
			tableView.separatorStyle = .none
		} else {
			tableView.backgroundView = nil
			tableView.separatorStyle = .singleLine
		}
	}
}

// MARK: - UITableViewDataSource
extension SearchVC: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 3
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		handleEmptyView(tableView: tableView, isEmpty: (albumsResults.count + artistsResults.count + albumsartistsResults.count)  == 0)

		switch section {
		case 0:
			return albumsResults.count
		case 1:
			return artistsResults.count
		case 2:
			return albumsartistsResults.count
		default:
			return 0
		}
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.shinobu.cell.search", for: indexPath)

		var ent: MusicalEntity

		switch indexPath.section {
		case 0:
			ent = albumsResults[indexPath.row]
		case 1:
			ent = artistsResults[indexPath.row]
		case 2:
			ent = albumsartistsResults[indexPath.row]
		default:
			return cell
		}

		cell.textLabel?.text = ent.name
		cell.textLabel?.highlightedTextColor = themeProvider.currentTheme.tintColor

		let view = UIView()
		view.backgroundColor = themeProvider.currentTheme.tintColor.withAlphaComponent(0.2)
		cell.selectedBackgroundView = view

		return cell
	}
}

// MARK: - UITableViewDelegate
extension SearchVC: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			NotificationCenter.default.postOnMainThreadAsync(name: .showAlbumNotification, object: albumsResults[indexPath.row])
		} else {
			let artist = indexPath.section == 1 ? artistsResults[indexPath.row] : albumsartistsResults[indexPath.row]
			NotificationCenter.default.postOnMainThreadAsync(name: .showArtistNotification, object: artist.name)
		}
		self.dismiss(animated: true, completion: nil)
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		let sectionHeight = CGFloat(32)
		switch section {
		case 0:
			return albumsResults.isEmpty ? 0 : sectionHeight
		case 1:
			return artistsResults.isEmpty ? 0 : sectionHeight
		case 2:
			return albumsartistsResults.isEmpty ? 0 : sectionHeight
		default:
			return 0
		}
	}

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let view = UIView(frame: CGRect(.zero, tableView.width, 32))
		view.backgroundColor = .systemGroupedBackground

		let imageView = UIImageView(frame: CGRect(8, (view.height - 24) / 2, 24, 24))
		let label = UILabel(frame: CGRect(imageView.maxX + 8, 0, 200, view.height))
		label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
		label.backgroundColor = .systemGroupedBackground
		view.addSubview(imageView)
		view.addSubview(label)

		switch section {
		case 0:
			label.text = "\(albumsResults.count) \(albumsResults.count == 1 ? NYXLocalizedString("lbl_album") : NYXLocalizedString("lbl_albums"))"
			imageView.image = #imageLiteral(resourceName: "img-album").withTintColor(.label)
		case 1:
			label.text = "\(artistsResults.count) \(artistsResults.count == 1 ? NYXLocalizedString("lbl_artist") : NYXLocalizedString("lbl_artists"))"
			imageView.image = #imageLiteral(resourceName: "img-mic").withTintColor(.label)
		case 2:
			label.text = "\(albumsartistsResults.count) \(albumsartistsResults.count == 1 ? NYXLocalizedString("lbl_albumartist") : NYXLocalizedString("lbl_albumartists"))"
			imageView.image = #imageLiteral(resourceName: "img-artists").withTintColor(.label)
		default:
			break
		}

		return view
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 1
	}

	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}
}

// MARK: - UISearchBarDelegate
extension SearchVC: UISearchBarDelegate {
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		searchBar.text = ""
		searching = false
		albumsResults.removeAll()
		artistsResults.removeAll()
		albumsartistsResults.removeAll()
		tableView.reloadSections(IndexSet(arrayLiteral: 0, 1, 2), with: .fade)
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
		searchBar.endEditing(true)
		tableView.reloadSections(IndexSet(arrayLiteral: 0, 1, 2), with: .fade)
	}

	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		searching = true
	}

	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		if String.isNullOrWhiteSpace(searchText) {
			albumsResults.removeAll()
			artistsResults.removeAll()
			albumsartistsResults.removeAll()
			tableView.reloadSections(IndexSet(arrayLiteral: 0, 1, 2), with: .fade)
			return
		}

		if Settings.shared.bool(forKey: .pref_fuzzySearch) {
			albumsResults = albums.filter { $0.name.fuzzySearch(withString: searchText) }
			artistsResults = artists.filter { $0.name.fuzzySearch(withString: searchText) }
			albumsartistsResults = albumsartists.filter { $0.name.fuzzySearch(withString: searchText) }
		} else {
			albumsResults = albums.filter { $0.name.lowercased().contains(searchText.lowercased()) }
			artistsResults = artists.filter { $0.name.lowercased().contains(searchText.lowercased()) }
			albumsartistsResults = albumsartists.filter { $0.name.lowercased().contains(searchText.lowercased()) }
		}

		tableView.reloadSections(IndexSet(arrayLiteral: 0, 1, 2), with: .fade)
	}
}

extension SearchVC: Themed {
	func applyTheme(_ theme: Theme) {
		searchZone.backgroundColor = .systemGroupedBackground
		tableView.backgroundColor = .systemBackground
		searchBar.tintColor = theme.tintColor
		searchBar.barTintColor = .systemGroupedBackground
		searchBar.backgroundColor = .systemGroupedBackground
		guard let searchField = (searchBar.value(forKey: "searchField") as? UITextField) else { return }
		searchField.textColor = .secondaryLabel
		searchField.backgroundColor = .systemGroupedBackground
		searchBar.setSearchBarColor(color: .systemGroupedBackground)
	}
}