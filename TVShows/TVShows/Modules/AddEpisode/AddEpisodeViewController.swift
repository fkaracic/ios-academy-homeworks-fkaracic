//
//  AddEpisodeViewController.swift
//  TVShows
//
//  Created by Infinum Student Academy on 27/07/2018.
//  Copyright © 2018 Filip Karacic. All rights reserved.
//

import UIKit
import SVProgressHUD
import Alamofire
import Photos

protocol AddNewEpisodeDelegate: class {
    func shouldReloadEpisodes(episode: Episode)
}

class AddEpisodeViewController: UIViewController {
    //    MARK: - Public properties
    
    var showId: String?
    var token: String?
    
    //    MARK: - Private properties
    
    private var _imagePicker = UIImagePickerController()
    private var _mediaId = ""
    private var _image: UIImage?
    
    

    //    MARK: - IBOutlets
    
    @IBOutlet private weak var _episodeTitleTextField: UITextField!
    @IBOutlet private weak var _seasonNumberTextField: UITextField!
    @IBOutlet private weak var _episodeNumberTextField: UITextField!
    @IBOutlet private weak var _episodeDescriptionTextField: UITextField!
    
    //    MARK: - Delegators
    
    weak var delegate: AddNewEpisodeDelegate?
   
    //    MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        navigationItem.title = "Add episode"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(didSelectCancel))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add",
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(didSelectAddShow))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    //    MARK: - IBActions
    @IBAction func addEpisodeImage(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            _imagePicker.delegate = self
            _imagePicker.sourceType = .savedPhotosAlbum;
            _imagePicker.allowsEditing = false
            
            self.present(_imagePicker, animated: true, completion: nil)
        }
    }
    
    //    MARK: - Private methods
    
    private func showAlert(alertMessage: String) {
        let alertController = UIAlertController(title: "Alert", message:
            alertMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func uploadImageOnAPI(token: String) {
        let headers = ["Authorization": token]
        
        let someUIImage = _image!
        let imageByteData = UIImagePNGRepresentation(someUIImage)!
         SVProgressHUD.show()
        Alamofire
            .upload(multipartFormData: { multipartFormData in
                multipartFormData.append(imageByteData,
                                         withName: "file",
                                         fileName: "image.png",
                                         mimeType: "image/png")
            }, to: Constants.URL.baseUrl + "/media",
               method: .post,
               headers: headers)
            { [weak self] result in
                
                SVProgressHUD.dismiss()
                switch result {
                case .success(let uploadRequest, _, _):
                    self?.processUploadRequest(uploadRequest)
                case .failure(let encodingError):
                    print(encodingError)
                }
        }
        
    }
    
    private func processUploadRequest(_ uploadRequest: UploadRequest) {
        SVProgressHUD.show()
        uploadRequest
            .responseDecodableObject(keyPath: "data") {[weak self] (response:
                DataResponse<Media>) in
        
                SVProgressHUD.dismiss()
                
        switch response.result {

            case .success(let media):
                self?._mediaId = media.id
            self?.addEpisode()
            case .failure(let error):
                print("FAILURE: \(error)")
        }

        }
    }
    
    private func addEpisode(){
        let token: String = self.token!
        let headers = ["Authorization": token]
        
        let parameters: [String: String] = [
            "showId": showId!,
            "mediaId": _mediaId,
            "title": _episodeTitleTextField.text!,
            "description": _episodeDescriptionTextField.text!,
            "episodeNumber": _episodeNumberTextField.text!,
            "season": _seasonNumberTextField.text!
        ]
        
        SVProgressHUD.show()
        
        Alamofire
            .request(Constants.URL.baseUrl + "/episodes",
                     method: .post,
                     parameters: parameters,
                     encoding: JSONEncoding.default,
                     headers: headers)
            .validate()
            .responseDecodableObject(keyPath: "data", decoder: JSONDecoder()) {[weak self] (response:
                DataResponse<Episode>) in
                
                SVProgressHUD.dismiss()
                
                switch response.result {
                case .success(let episode):
                    self?.delegate?.shouldReloadEpisodes(episode: episode)
                    self?.dismiss(animated: true)
                case .failure(let error):
                    print(error)
                    self?.showAlert(alertMessage: "Adding episode failed")
                }
        }
    }
    
    //    MARK: - Private methods (objc)
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= (keyboardSize.height - 35)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += (keyboardSize.height - 35)
            }
        }
    }
    
    @objc func didSelectCancel() {
        self.dismiss(animated: false)
    }
    
    @objc func didSelectAddShow() {
        if _image != nil {
            uploadImageOnAPI(token: token!)
        }else{
            addEpisode()
        }
        
    }
}

//    MARK: - Extensions

extension AddEpisodeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            _image = pickedImage
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated:true, completion: nil)
    }
}
