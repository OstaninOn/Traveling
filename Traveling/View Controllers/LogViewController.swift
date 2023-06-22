 

import MapKit
import UIKit
import RealmSwift
import PhotosUI

//
// MARK: - Log View Controller
//
@available(iOS 14.0, *)
class LogViewController: UITableViewController {
   
 let realm = try! Realm()
   
 // MARK: - IBOutlets
  //
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  
    //
    // MARK: - Variables And Properties
    //
    var searchResults = try! Realm().objects(Specimen.self)
    var searchController: UISearchController!
    var specimens = try! Realm().objects(Specimen.self)
    .sorted(byKeyPath: "name", ascending: true)

    //
    // MARK: - IBActions
  //
  @IBAction func scopeChanged(sender: Any) {
    
      let scopeBar = sender as! UISegmentedControl
      let realm = try! Realm()
      // to sort the returned results when the user taps a button in the scope bar.
      switch scopeBar.selectedSegmentIndex {
      case 1:
        specimens = realm.objects(Specimen.self)
          .sorted(byKeyPath: "created", ascending: true)
      default:
        specimens = realm.objects(Specimen.self)
          .sorted(byKeyPath: "name", ascending: true)
      }
        
      tableView.reloadData()
      
      
    }
      
   //You’ll pass the selected specimen to the AddNewEntryController instance. The complication with the if/else is because getting the selected specimen is different depending on whether or not the user is looking at search results.
      
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if (segue.identifier == "Edit") {
        let controller = segue.destination as! AddNewEntryViewController
        var selectedSpecimen: Specimen!
        let indexPath = tableView.indexPathForSelectedRow
          
        if searchController.isActive {
          let searchResultsController =
            searchController.searchResultsController as! UITableViewController
          let indexPathSearch = searchResultsController.tableView.indexPathForSelectedRow
          selectedSpecimen = searchResults[indexPathSearch!.row]
        } else {
          selectedSpecimen = specimens[indexPath!.row]
            
        }
        controller.specimen = selectedSpecimen
      }
        
    }

      
    func filterResultsWithSearchString(searchString: String) {
      // The [c] that follows BEGINSWITH indicates a case insensitive search.
      let predicate = NSPredicate(format: "name BEGINSWITH [c]%@", searchString)
      let scopeIndex = searchController.searchBar.selectedScopeButtonIndex // grab a reference to the currently selected scope index from the search bar.
      let realm = try! Realm()
        
      switch scopeIndex {
      case 0:
        searchResults = realm.objects(Specimen.self)
          .filter(predicate).sorted(byKeyPath: "name", ascending: true) // sorth by name
      case 1:
        searchResults = realm.objects(Specimen.self).filter(predicate)
          .sorted(byKeyPath: "created", ascending: true) // sorth by date
      default:
        searchResults = realm.objects(Specimen.self).filter(predicate) // If none of the buttons are selected, don’t sort the results, take them in the order they’re returned from the database.
      }
        tableView.reloadData()
        
    }

    
    //
    // MARK: - View Controller
    //
    override func viewDidLoad() {
      super.viewDidLoad()
      
        tableView.delegate = self
        tableView.dataSource = self
        
      let searchResultsController = UITableViewController(style: .plain)
      searchResultsController.tableView.delegate = self
      searchResultsController.tableView.dataSource = self
      searchResultsController.tableView.rowHeight = 63
      searchResultsController.tableView.register(LogCell.self, forCellReuseIdentifier: "LogCell")
      
       // searchResultsController.layer.cornerRadius = 22
      searchController = UISearchController(searchResultsController: searchResultsController)
      searchController.searchResultsUpdater = self
      searchController.searchBar.sizeToFit()
      searchController.searchBar.tintColor = UIColor.systemOrange
      searchController.searchBar.delegate = self
    
      tableView.tableHeaderView?.addSubview(searchController.searchBar)
      definesPresentationContext = true
    }
  }

  // MARK: - Search Bar Delegate
  //
  @available(iOS 14.0, *)
  extension LogViewController:  UISearchBarDelegate {
  }

  // MARK: - Search Results Updatings
  //
  @available(iOS 14.0, *)
  extension LogViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
      // apply filtering
      let searchString = searchController.searchBar.text!
      filterResultsWithSearchString(searchString: searchString)
      let searchResultsController = searchController.searchResultsController as! UITableViewController
      searchResultsController.tableView.reloadData()
    }
      
  }

  // MARK: - Table View Data Source
  @available(iOS 14.0, *)
  extension LogViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = self.tableView.dequeueReusableCell(withIdentifier: "LogCell") as! LogCell
      let specimen = searchController.isActive ? searchResults[indexPath.row] : specimens[indexPath.row]
        
      cell.titleLabel.text = specimen.name
      cell.subtitleLabel.text = specimen.category.name
        
        
        
      switch specimen.category.name {
      case "Животные":
        cell.iconImageView.image = UIImage(named: "IconMammal")
      case "Птицы":
        cell.iconImageView.image = UIImage(named: "IconBird")
      case "Синагога":
        cell.iconImageView.image = UIImage(named: "IconSinag")
      case "Часовня":
        cell.iconImageView.image = UIImage(named: "IconHasovnja")
      case "Кастел":
        cell.iconImageView.image = UIImage(named: "IconCastel")
      case "Кафедральный собор":
        cell.iconImageView.image = UIImage(named: "IconSabor")
      case "Православная церковь":
        cell.iconImageView.image = UIImage(named: "IconPravoslavnaja")
      case "Замок":
        cell.iconImageView.image = UIImage(named: "IconZamok2")
      case "Другое":
        cell.iconImageView.image = UIImage(named: "IconUncategorized")
      case "Памятник":
        cell.iconImageView.image = UIImage(named: "IconPamjatnic")
      case "Руины":
        cell.iconImageView.image = UIImage(named: "IconRuiny")
      case "Парк":
        cell.iconImageView.image = UIImage(named: "IconDerevo2")
      case "Усадьба":
        cell.iconImageView.image = UIImage(named: "IconUsadba")
      case "Монастырь":
        cell.iconImageView.image = UIImage(named: "IconMonastyr1")
      default:
        cell.iconImageView.image = UIImage(named: "IconUncategorized")
          
      }
        
      return cell
    }
      
      override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          
          return searchController.isActive ? searchResults.count : specimens.count
          
      }
   
      override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
          
          if editingStyle == .delete {
              presentDeletionFailsafe(indexPath: indexPath)
              
          }
      }


      override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
          let row = indexPath.row
          print("ячейка номер: \(row)")

          if (row == 1) {
            
          }
      }
      
      
      func presentDeletionFailsafe(indexPath: IndexPath) {
          let alert = UIAlertController(title: nil, message: "Удалить метку на карте?", preferredStyle: .actionSheet)

          let yesAction = UIAlertAction(title: "Удалить", style: .destructive) { _ in
              
              self.realm.beginWrite()
              self.realm.delete(self.specimens[indexPath.row])
              try! self.realm.commitWrite()
              self.tableView.deleteRows(at: [indexPath], with: .left)
              self.tableView.reloadData()
          }

          alert.addAction(yesAction)

          // cancel action
          alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))

          present(alert, animated: true, completion: nil)
      }
  }


      
