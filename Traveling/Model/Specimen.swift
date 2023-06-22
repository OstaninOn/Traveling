import Foundation
import RealmSwift

// Object is the Realm Model. The act of creating a model defines the schema of the database. To create a model, you subclass Object and define the fields you want to persist as properties.

class Specimen: Object {
    // Specific data types in Realm, such as strings, must be initialized with a value. In this case, you initialize them with an empty string.
  @objc dynamic var name = ""
  @objc dynamic var specimenDescription = ""
  @objc dynamic var latitude = 0.0
  @objc dynamic var longitude = 0.0
  @objc dynamic var created = Date()
  //@objc dynamic var imagList = UIImage()
    // create relationships between models by declaring a property with the appropriate model to be linked. This sets up a one-to-many relationship between Specimen and Category. This means each Specimen can belong to only one Category, but each Category can have many Specimens
  @objc dynamic var category: Category!
    var imagesIds = List<String>()
    
}
