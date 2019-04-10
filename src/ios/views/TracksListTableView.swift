import UIKit


protocol TracksListTableViewDelegate: class
{
	func getCurrentTrack() -> Track?
}


final class TracksListTableView: UITableView
{
	// MARK: - Public properties
	// Tracks list
	var tracks = [Track]()
	{
		didSet
		{
			DispatchQueue.main.async {
				self.reloadData()
			}
		}
	}
	// Should add a dummy cell at the end
	var useDummy = false
	// Cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.track"
	//
	weak var myDelegate: TracksListTableViewDelegate?

	override init(frame: CGRect, style: UITableView.Style)
	{
		super.init(frame: frame, style: style)

		self.dataSource = self
		self.register(TrackTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
		self.separatorStyle = .none
		self.rowHeight = 44

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)

		initializeTheming()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	deinit
	{
		NotificationCenter.default.removeObserver(self)
	}

	// MARK: - Private
	@objc func playingTrackChangedNotification(_ notification: Notification)
	{
		reloadData()
	}
}

// MARK: - UITableViewDataSource
extension TracksListTableView: UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return useDummy ? tracks.count + 1 : tracks.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! TrackTableViewCell

		// Dummy to let some space for the mini player
		if useDummy && indexPath.row == tracks.count
		{
			cell.lblTitle.text = ""
			cell.lblTrack.text = ""
			cell.lblDuration.text = ""
			cell.separator.isHidden = true
			cell.selectionStyle = .none
			return cell
		}

		cell.separator.isHidden = false
		cell.lblTitle.textColor = themeProvider.currentTheme.tableCellMainLabelTextColor
		cell.lblTrack.textColor = themeProvider.currentTheme.tableCellMainLabelTextColor
		cell.lblDuration.textColor = themeProvider.currentTheme.tableCellMainLabelTextColor

		let track = tracks[indexPath.row]
		cell.lblTrack.text = String(track.trackNumber)
		cell.lblTitle.text = track.name
		let minutes = track.duration.minutesRepresentation().minutes
		let seconds = track.duration.minutesRepresentation().seconds
		cell.lblDuration.text = "\(minutes):\(seconds < 10 ? "0" : "")\(seconds)"

		let currentTrack = myDelegate?.getCurrentTrack()
		if currentTrack != nil && currentTrack == track
		{
			cell.lblTrack.font = UIFont.systemFont(ofSize: 10, weight: .bold)
			cell.lblTitle.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
			cell.lblDuration.font = UIFont.systemFont(ofSize: 10, weight: .regular)
		}
		else
		{
			cell.lblTrack.font = UIFont.systemFont(ofSize: 10, weight: .regular)
			cell.lblTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
			cell.lblDuration.font = UIFont.systemFont(ofSize: 10, weight: .light)
		}

		// Accessibility
		var stra = "\(NYXLocalizedString("lbl_track")) \(track.trackNumber), \(track.name)\n"
		if minutes > 0
		{
			stra += "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes")) "
		}
		if seconds > 0
		{
			stra += "\(seconds) \(seconds == 1 ? NYXLocalizedString("lbl_second") : NYXLocalizedString("lbl_seconds"))"
		}
		cell.accessibilityLabel = stra

		return cell
	}
}

extension TracksListTableView: Themed
{
	func applyTheme(_ theme: ShinobuTheme)
	{
		backgroundColor = theme.backgroundColor
		reloadData()
	}
}
