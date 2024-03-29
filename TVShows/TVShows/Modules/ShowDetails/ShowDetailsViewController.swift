//
//  ShowDetailsViewController.swift
//  TVShows
//
//  Created by Infinum Student Academy on 26/07/2018.
//  Copyright © 2018 Filip Karacic. All rights reserved.
//

import UIKit
import SVProgressHUD
import Alamofire

class ShowDetailsViewController: UIViewController {
    var token: String?
    var showId: String?
    
    private let refreshControl = UIRefreshControl()
    private var isRefreshing = false
    
    private var episodes: [Episode] = []
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var episodesNumberLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!{
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.refreshControl = refreshControl
            
            refreshControl.addTarget(self, action: #selector(refreshEpisodes), for: .valueChanged)
            refreshControl.tintColor = UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)
            refreshControl.attributedTitle = NSAttributedString(string: "Refreshing episodes...")
        }
    }
    
    @objc func refreshEpisodes(){
        isRefreshing = true
        getShowEpisodes()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        getShowInfo()
        getShowEpisodes()
    }
    
    private func getCoverImage(imageUrl: String){
        let url = URL(string: Constants.URL.baseDomainUrl + imageUrl)
        coverImageView.kf.setImage(with: url)
    }
    
    @IBAction func navigateback(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func addNewEpisode(_ sender: Any) {
        let storyboard = UIStoryboard(name: "AddEpisode", bundle: nil)
        let addEpisodeViewController =
            storyboard.instantiateViewController(withIdentifier: "AddEpisodeViewController") as! AddEpisodeViewController
        
        addEpisodeViewController.token = token
        addEpisodeViewController.showId = showId
        addEpisodeViewController.delegate = self
        
        let navigationController = UINavigationController.init(rootViewController:
            addEpisodeViewController)
        present(navigationController, animated: true, completion: nil)
    }
    
    private func getShowInfo(){
        let token: String = self.token!
        let headers = ["Authorization": token]
        
        SVProgressHUD.show()
        
        Alamofire
            .request(Constants.URL.baseUrl + "/shows/" + showId!,
                     method: .get,
                     encoding: JSONEncoding.default,
                     headers: headers)
            .validate()
            .responseDecodableObject(keyPath: "data", decoder: JSONDecoder()) {[weak self] (response:
                DataResponse<ShowDetails>) in
                
                SVProgressHUD.dismiss()
                
                switch response.result {
                case .success(let showDetails):
                    self?.titleLabel.text = showDetails.title
                    self?.descriptionLabel.text = showDetails.description
                    self?.getCoverImage(imageUrl: showDetails.imageUrl)
                case .failure:
                    print("Fail")
                }
        }
    }
    
    private func getShowEpisodes(){
        let token: String = self.token!
        let headers = ["Authorization": token]
        
        SVProgressHUD.show()
        
        Alamofire
            .request(Constants.URL.baseUrl + "/shows/" + showId! + "/episodes",
                     method: .get,
                     //                     parameters: parameter,
                encoding: JSONEncoding.default,
                headers: headers)
            .validate()
            .responseDecodableObject(keyPath: "data", decoder: JSONDecoder()) {[weak self] (response:
                DataResponse<[Episode]>) in
                
                SVProgressHUD.dismiss()
                
                switch response.result {
                case .success(let episodes):
                    self?.episodes = episodes
                    self?.tableView.reloadData()
                    self?.episodesNumberLabel.text = "Episodes " + String(episodes.count)
                    
                    if self!.isRefreshing {
                        self?.refreshControl.endRefreshing()
                        self?.isRefreshing = false
                    }
                case .failure(let error):
                    print(error)
                }
        }
    }
}

extension ShowDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = episodes[indexPath.row]

        presentEpisodeDetails(episode: episode)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func presentEpisodeDetails(episode: Episode){
        let storyboard = UIStoryboard(name: "EpisodeDetails", bundle: nil)
        let episodeDetailsViewController = storyboard.instantiateViewController(
            withIdentifier: "EpisodeDetailsViewController"
            ) as! EpisodeDetailsViewController
        
        episodeDetailsViewController.episode = episode
        episodeDetailsViewController.token = self.token
        
        let navigationController = UINavigationController(rootViewController:
           episodeDetailsViewController)
        present(navigationController, animated: true, completion: nil)
    }
}

extension ShowDetailsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ShowDetailsViewCell = tableView.dequeueReusableCell(
            withIdentifier: "ShowDetailsViewCell",
            for: indexPath
            ) as! ShowDetailsViewCell
        
        let episode = episodes[indexPath.row]
        cell.configureWith(episode: episode)
        
        return cell
    }
}

extension ShowDetailsViewController: AddNewEpisodeDelegate {
    func shouldReloadEpisodes(episode: Episode) {
        episodes.append(episode)
        episodesNumberLabel.text = "Episodes " + String(episodes.count)
        tableView.reloadData()
    }
}
