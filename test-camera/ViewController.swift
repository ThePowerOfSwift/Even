//
//  ViewController.swift
//  test-camera
//
//  Created by Henry Yang on 4/30/16.
//  Copyright © 2016 Henry Yang. All rights reserved.
//
import UIKit
import Foundation


class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate, G8TesseractDelegate {

    //@IBOutlet weak var abc: UIImageView!
    //@IBOutlet weak var efg: UIImageView!
    var activityIndicator:UIActivityIndicatorView!
    var imagePicker: UIImagePickerController!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func capture(sender: UIButton) {
        view.endEditing(true)
        
        let imagePickerActionSheet = UIAlertController(title: "Take or Upload a Picture!", message: nil, preferredStyle: .ActionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let cameraButton = UIAlertAction(title: "Take Photo", style: .Default) { (alert) -> Void in
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .Camera
                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
            imagePickerActionSheet.addAction(cameraButton)
        }
        
        let libraryButton = UIAlertAction(title: "Use Existing Photo", style: .Default) { (alert) -> Void in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        imagePickerActionSheet.addAction(libraryButton)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .Cancel) { (alert) -> Void in
        }
        imagePickerActionSheet.addAction(cancelButton)
        
        presentViewController(imagePickerActionSheet, animated: true, completion: nil)
    }
    
    
    func performImageRecognition(image: UIImage) {
        let tesseract = G8Tesseract()
        tesseract.language = "eng"
        tesseract.delegate = self
        tesseract.engineMode = .TesseractCubeCombined
        tesseract.maximumRecognitionTime = 60.0
        tesseract.image = image.g8_blackAndWhite()
        tesseract.recognize()
        
        let recognizedText = tesseract.recognizedText
        
        let regexString = "[0-9]+\u{2E}[0-9][0-9]"
        
        var resultArr = matchesForRegexInText(regexString, text: recognizedText)
        
        var wordsToDelete: [String] = [String]()
        
        for element in resultArr {
            if (element.rangeOfString(".") == nil) {
                wordsToDelete.append(element)
            }
        }
        
        for element in wordsToDelete {
            if let index = resultArr.indexOf(element) {
                resultArr.removeAtIndex(index)
            }
        }
        
        var result: String = String()
        
        for index in 0...(resultArr.count-6) {
            result += "Item "
            result += String(index+1)
            result += " - $"
            result += resultArr[index]
            result += "\n"
        }
        
        textView.text = result
        removeActivityIndicator()
    }
    
    func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substringWithRange($0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    
    
    
    func cropImage(image: UIImage) -> UIImage {
        
        var section: CGRect
        
        print(image.size)
        if(image.size.width < image.size.height){
            section = CGRectMake(image.size.width/3, image.size.height, image.size.width/3, image.size.height)
        }
        else {
            section = CGRectMake(image.size.height/3, image.size.width, image.size.height/3, image.size.width)
        }
        
        
        let mask = CGImageCreateWithImageInRect(image.CGImage, section)
        return UIImage(CGImage: mask!, scale: CGFloat(1.0), orientation: .Right)
 
    }
    
    func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height {
        scaleFactor = image.size.height / image.size.width
        scaledSize.width = maxDimension
        scaledSize.height = scaledSize.width * scaleFactor
        } else {
        scaleFactor = image.size.width / image.size.height
        scaledSize.height = maxDimension
        scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.drawInRect(CGRectMake(0, 0, scaledSize.width, scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
        
        let contextImage: UIImage = UIImage(CGImage: image.CGImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRectMake(posX, posY, cgwidth, cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(CGImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: view.bounds)
        activityIndicator.activityIndicatorViewStyle = .WhiteLarge
        activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.25)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }
    
    func removeActivityIndicator() {
        activityIndicator.removeFromSuperview()
        activityIndicator = nil
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let selectedPhoto = info[UIImagePickerControllerOriginalImage] as! UIImage
        //let croppedPhoto = cropImage(selectedPhoto)
        //let scaledPhoto = scaleImage(selectedPhoto, maxDimension: 640)
        let croppedPhoto = cropToBounds(selectedPhoto, width: Double(selectedPhoto.size.height), height: Double(selectedPhoto.size.width/3))
        //abc.image = selectedPhoto
        //efg.image = croppedPhoto
        addActivityIndicator()
        dismissViewControllerAnimated(true, completion: {self.performImageRecognition(selectedPhoto)})
    }
    
    


}

