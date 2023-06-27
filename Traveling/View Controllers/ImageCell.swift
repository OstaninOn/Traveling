

import UIKit

class ImageCell: UICollectionViewCell {

    static let identifier = "ImageCell"
    
    @IBOutlet weak var imageView: UIImageView!
    
    public func configure(withImage image : UIImage) {
        imageView.image = image
       
    }
    
    override func prepareForReuse() {
        imageView.image = nil
        
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
  
}
