import UIKit


final class AlbumDetailVC : NYXViewController
{
	// MARK: - Private properties
	// Selected album
	private let album: Album
	// Header view (cover + album name, artist)
	private var headerView: AlbumHeaderView! = nil
	// Tableview for song list
	private var tableView: TracksListTableView! = nil
	// Dummy view to color the nav bar
	private var colorView: UIView! = nil
	// MPD Data source
	private let mpdBridge: MPDBridge

	// MARK: - Initializers
	init(album: Album, mpdBridge: MPDBridge)
	{
		self.album = album
		self.mpdBridge = mpdBridge

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Color under navbar
		var defaultHeight: CGFloat = UIDevice.current.isiPhoneX() ? 88 : 64
		if navigationController == nil
		{
			defaultHeight = 0.0
		}
		colorView = UIView(frame: CGRect(0, 0, self.view.width, navigationController?.navigationBar.frame.maxY ?? defaultHeight))
		self.view.addSubview(colorView)

		// Album header view
		let coverSize = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSValue.self], from: Settings.shared.data(forKey: .coversSize)!) as? NSValue
		headerView = AlbumHeaderView(frame: CGRect(0, navigationController?.navigationBar.frame.maxY ?? defaultHeight, self.view.width, coverSize?.cgSizeValue.height ?? defaultHeight), coverSize: (coverSize?.cgSizeValue)!)
		self.view.addSubview(headerView)

		// Tableview
		tableView = TracksListTableView(frame: CGRect(0, headerView.bottom, self.view.width, self.view.height - headerView.bottom), style: .plain)
		tableView.useDummy = true
		tableView.delegate = self
		tableView.myDelegate = self
		tableView.tableFooterView = UIView()
		self.view.addSubview(tableView)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Update header
		updateHeader()

		// Get songs list if needed
		if let tracks = album.tracks
		{
			updateNavigationTitle()
			tableView.tracks = tracks
		}
		else
		{
			mpdBridge.getTracksForAlbums([album]) { [weak self] (tracks) in
				DispatchQueue.main.async {
					self?.updateNavigationTitle()
					self?.tableView.tracks = self?.album.tracks ?? []
				}
			}
		}
	}

	// MARK: - Private
	private func updateHeader()
	{
		// Update header view
		headerView.updateHeaderWithAlbum(album)
		colorView.backgroundColor = headerView.backgroundColor

		// Don't have all the metadatas
		if album.artist.count == 0
		{
			mpdBridge.getMetadatasForAlbum(album) {
				DispatchQueue.main.async {
					self.updateHeader()
				}
			}
		}
	}

	override func updateNavigationTitle()
	{
		if let tracks = album.tracks
		{
			let total = tracks.reduce(Duration(seconds: 0)){$0 + $1.duration}
			let minutes = total.seconds / 60
			titleView.setMainText("\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))", detailText: "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))")
		}
		else
		{
			titleView.setMainText("0 \(NYXLocalizedString("lbl_tracks"))", detailText: nil)
		}
	}
}

// MARK: - UITableViewDelegate
extension AlbumDetailVC : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Dummy cell
		guard let tracks = album.tracks else { return }
		if indexPath.row >= tracks.count
		{
			return
		}

		// Toggle play / pause for the current track
		if let currentPlayingTrack = mpdBridge.getCurrentTrack()
		{
			let selectedTrack = tracks[indexPath.row]
			if selectedTrack == currentPlayingTrack
			{
				mpdBridge.togglePause()
				return
			}
		}

		let b = tracks.filter({$0.trackNumber >= (indexPath.row + 1)})
		mpdBridge.playTracks(b, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
	{
		// Dummy cell
		guard let tracks = album.tracks else { return nil }
		if indexPath.row >= tracks.count
		{
			return nil
		}

		let action = UIContextualAction(style: .normal, title: NYXLocalizedString("lbl_add_to_playlist"), handler: { (action, view, completionHandler ) in
			self.mpdBridge.entitiesForType(.playlists) { (entities) in
				if entities.count == 0
				{
					return
				}

				DispatchQueue.main.async {
					guard let cell = tableView.cellForRow(at: indexPath) else
					{
						return
					}

					let vc = PlaylistsAddVC(mpdBridge: self.mpdBridge)
					let tvc = NYXNavigationController(rootViewController: vc)
					vc.trackToAdd = tracks[indexPath.row]
					tvc.modalPresentationStyle = .popover
					if let popController = tvc.popoverPresentationController
					{
						popController.permittedArrowDirections = [.up, .down]
						popController.sourceRect = cell.bounds
						popController.sourceView = cell
						popController.delegate = self
						popController.backgroundColor = Colors.backgroundAlt
						tvc.preferredContentSize = CGSize(300, 200)
						self.present(tvc, animated: true, completion: {
						});
					}
				}
			}
			completionHandler(true)
		})
		action.image = #imageLiteral(resourceName: "btn-playlist-add")
		action.backgroundColor = Colors.main

		return UISwipeActionsConfiguration(actions: [action])
	}
}

extension AlbumDetailVC : UIPopoverPresentationControllerDelegate
{
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
	{
		return .none
	}
}

// MARK: - Peek & Pop
extension AlbumDetailVC
{
	override var previewActionItems: [UIPreviewActionItem]
	{
		let playAction = UIPreviewAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action, viewController) in
			self.mpdBridge.playAlbum(self.album, shuffle: false, loop: false)
			MiniPlayerView.shared.stayHidden = false
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action, viewController) in
			self.mpdBridge.playAlbum(self.album, shuffle: true, loop: false)
			MiniPlayerView.shared.stayHidden = false
		}

		let addQueueAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action, viewController) in
			self.mpdBridge.addAlbumToQueue(self.album)
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, addQueueAction]
	}
}

extension AlbumDetailVC : TracksListTableViewDelegate
{
	func getCurrentTrack() -> Track?
	{
		return self.mpdBridge.getCurrentTrack()
	}
}
