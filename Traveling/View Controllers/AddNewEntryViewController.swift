//import Hero
import UIKit
import RealmSwift
import PhotosUI
//
// MARK: - Add New Entry View Controller
//

struct EntryImage {
    var id: String
    var image: UIImage
}

@available(iOS 14.0, *)
class AddNewEntryViewController: UIViewController {
    
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextView!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var collectionView: UICollectionView!
    var images = [EntryImage]()
    var imagesPerLine: CGFloat = 4
    let imageSpacing: CGFloat = 4
    
    
    // MARK: - Variables And Properties
    
    var selectedAnnotation: SpecimenAnnotation!
    var selectedCategory: Category!
    var specimen: Specimen!
    
    // MARK: - IBActions

    @IBAction func unwindFromCategories(segue: UIStoryboardSegue) {
        if segue.identifier == "CategorySelectedSegue" {
            let categoriesController = segue.source as! CategoriesTableViewController
            selectedCategory = categoriesController.selectedCategory
            categoryTextField.text = selectedCategory.name
            
            
        }
        print("ВЫБОР КАТЕГОРИИ")
    }
    // MARK: - Private Methods
    
    func fillTextFields() {
//        var lowercased = nameTextField.text
        //nameTextField.text = .capitalized
        
        nameTextField.text = specimen.name
        categoryTextField.text = specimen.category.name
        descriptionTextField.text = specimen.specimenDescription
        selectedCategory = specimen.category
        
        loadImage()
 
        print("СПИСОК")
    }
    
    func updateSpecimen() {
        let realm = try! Realm()
        
        try! realm.write {
            specimen.name = nameTextField.text!
            specimen.category = selectedCategory
            specimen.specimenDescription = descriptionTextField.text
            saveImagesIds()
            
            print("сохранение в список")
        }
        
            }
    
    private func saveImagesIds() {
        let savedImagesIds = Set(Array(specimen.imagesIds))
        let imagesIds = Set(images.map { $0.id })
        let dif = imagesIds.subtracting(savedImagesIds)
        specimen.imagesIds.append(objectsIn: dif)
    }
    
    func addNewSpecimen() {
        let realm = try! Realm() // start instance
        
        try! realm.write { // add your new Specimen to realm
            let newSpecimen = Specimen() // create new specimen instance
            
            newSpecimen.name = nameTextField.text! // assign values
            newSpecimen.category = selectedCategory
            newSpecimen.specimenDescription = descriptionTextField.text
            newSpecimen.latitude = selectedAnnotation.coordinate.latitude
            newSpecimen.longitude = selectedAnnotation.coordinate.longitude
            newSpecimen.imagesIds.append(objectsIn: images.map({ $0.id }))
            
            realm.add(newSpecimen) // Add the new Specimen to the realm.
            specimen = newSpecimen // Assign the new Specimen to your specimen property
            
            print("сохранить")
        }
    }
    
    override func shouldPerformSegue(
        withIdentifier identifier: String,
        sender: Any?
    ) -> Bool {
        if validateFields() {
            if specimen != nil {
                updateSpecimen()
                
            } else {
                addNewSpecimen()
            }
            
            return true
        } else {
            return false
        }
    }

    // MARK: - Private Methods
    
    func validateFields() -> Bool {
        if
            nameTextField.text!.isEmpty ||
                descriptionTextField.text!.isEmpty ||
                selectedCategory == nil {
            // This verifies that all of the fields are populated and that you’ve selected a category.
            
            let alertController = UIAlertController(title: "Ошибка проверки",
                                                    message: "Все поля должны быть заполнены",
                                                    preferredStyle: .alert)
            
            let alertAction = UIAlertAction(title: "OK", style: .destructive) { alert in
                alertController.dismiss(animated: true, completion: nil)
                
            }
            
            alertController.addAction(alertAction)
            
            present(alertController, animated: true, completion: nil)
            
            return false
        } else {
            return true
        }
    }
    
    //
    // MARK: - View Controller
    //
    override func viewDidLoad() {
        super.viewDidLoad()
   
        nameTextField.font = UIFont(name:"Architun", size: 30)
        nameTextField.textColor = UIColor.init(named: "RayGreen")
        descriptionTextField.font = UIFont(name:"Architun", size: 25)
        categoryTextField.font = UIFont(name:"Hayate", size: 25)
        categoryTextField.textColor = UIColor.red
        
        if let specimen = specimen {
            title = " \(specimen.name)"
            fillTextFields()
        } else {
            title = "Новая метка"
        }
        
        
        self.setupCollectionView()
        
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(changeCountInRow))
        collectionView.addGestureRecognizer(gesture)
        
        self.hideKeyboardWhenTappedAround()
        
        descriptionTextField.layer.cornerRadius = 5
        descriptionTextField.layer.shadowRadius = 6
        descriptionTextField.layer.shadowOffset = .zero
        descriptionTextField.layer.shadowOpacity = 1
        descriptionTextField.layer.shadowColor = UIColor.black.cgColor
        descriptionTextField.layer.shadowPath = UIBezierPath(rect: descriptionTextField.bounds).cgPath
        descriptionTextField.layer.masksToBounds = false
                
        
    }
    
     func setupCollectionView() {
        collectionView.register(ImageCell.nib(), forCellWithReuseIdentifier: ImageCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        
    }
    
    @IBAction func pickImage(_ sender: Any) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraSelection = NSLocalizedString("Камера", comment: "the user will see the camera button")
        let cameraAction = UIAlertAction(title: cameraSelection, style: .default) { _ in
            self.showPicker(withSourceType: .camera)
        }
        
        
        let photoSelection = NSLocalizedString("Галерея", comment: "the user will see the photo library button")
        let libraryAction = UIAlertAction(title: photoSelection, style: .default) { _ in
      
            var config = PHPickerConfiguration()
            config.selectionLimit = 0

            let phPickerVC = PHPickerViewController(configuration: config)
            phPickerVC.delegate = self
            self.present(phPickerVC, animated: true)
            
            self.showPicker(withSourceType: .photoLibrary)
            
        }
       
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(cameraAction)
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(libraryAction)
        }

        let cancelAction = UIAlertAction(title: "выход", style: .destructive, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func setImage(_ image: UIImage, withName name: String? = nil) {
        let fileName = name ?? UUID().uuidString
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = URL(fileURLWithPath: fileName, relativeTo: directoryURL).appendingPathExtension("jpg")
        guard let data = image.jpegData(compressionQuality: 100) else { return }
        try? data.write(to: fileURL)
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        setImages(id: fileName, image: image)
    }
    
    @objc private func changeCountInRow(recognizer : UIPinchGestureRecognizer) {
        if recognizer.state == .ended {
            switch recognizer.scale {
            case 0...1:
                if Int(imagesPerLine) < images.count {
                    imagesPerLine += 1
                }
            default:
                if imagesPerLine > 1 {
                    imagesPerLine -= 1
                }
            }
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
    }
    
    private func loadImage() {
        specimen.imagesIds.forEach { id in
            let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let fileURL = URL(fileURLWithPath: id, relativeTo: directoryURL).appendingPathExtension("jpg")

            guard let savedData = try? Data(contentsOf: fileURL),
                  let image = UIImage(data: savedData) else { return }
            setImages(id: id, image: image)
        }
        self.collectionView.reloadData()
    }
    
    private func showPicker(withSourceType sourceType: UIImagePickerController.SourceType) {
    let pickerController = UIImagePickerController()
    pickerController.delegate = self
    pickerController.allowsEditing = false
    pickerController.mediaTypes = ["public.image"]
    pickerController.sourceType = sourceType
    
    present(pickerController, animated: true)
        
        
    }
    
    private func setImages(id: String, image: UIImage) {
        guard !images.contains(where: { $0.id == id }) else { return }
        images.append(EntryImage(id: id, image: image))
    }
    
    
    
}



@available(iOS 14, *)
extension AddNewEntryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    self.setImage(image)
                } else if let data = object as? Data,
                let image = UIImage(data: data){
                    self.setImage(image)
                }
            }
        }
        //self.presentedViewController?.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        var name: String?
        if let imageName = info[.imageURL] as? URL {
            name = imageName.lastPathComponent
        }
        setImage(image, withName: name)
        self.presentedViewController?.dismiss(animated: true)
            }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.presentedViewController?.dismiss(animated: true)
        let errorNotification = NSLocalizedString("Ошибка", comment: "the user will see error notification file not selected")
        let messageError = NSLocalizedString("Фотография не выбрана", comment: "the user will see error notification")
        let alert = UIAlertController(title: errorNotification, message: messageError, preferredStyle: .alert)
        let messageErrorBack = NSLocalizedString("закрыть", comment: "the user will see back button message error")
        let okAction = UIAlertAction(title: messageErrorBack, style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

@available(iOS 14.0, *)
extension AddNewEntryViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
        
        
        
        guard let destinationViewController = storyboard.instantiateViewController(withIdentifier: "SchowPhotoViewController") as? SchowPhotoViewController else { return }
        
        destinationViewController.image = images[indexPath.row].image
        
        destinationViewController.modalPresentationStyle = .formSheet
        present(destinationViewController, animated: true)
        
    }
   
}

@available(iOS 14.0, *)
extension AddNewEntryViewController : UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        images.count
        
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let index = indexPath.row
        print("КОЛЛИ\(indexPath.row)!")
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier:ImageCell.identifier, for: indexPath) as? ImageCell else { return UICollectionViewCell()}
        
        cell.configure(withImage: images[index].image)
        
       print("КОЛЛИЧЕСТВО ФОТО\(indexPath.item)!")
        
        return cell
        
    }
    
    
}

@available(iOS 14.0, *)
extension AddNewEntryViewController : UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout : UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalHorizontalSpacing = (imagesPerLine - 1) * imageSpacing
        let width = (collectionView.bounds.width - totalHorizontalSpacing) / imagesPerLine
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return imageSpacing
    }

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
            return imageSpacing
        }

}


// MARK: - Text Field Delegate
//
@available(iOS 14.0, *)
extension AddNewEntryViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        performSegue(withIdentifier: "Categories", sender: self)
    }
}
