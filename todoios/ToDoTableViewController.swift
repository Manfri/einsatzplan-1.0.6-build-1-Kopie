// ----------------------------------------------------------------------------
// Copyright (c) Actemium H&F
// ----------------------------------------------------------------------------
//
//
import Foundation
import UIKit
import CoreData

class ToDoTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var stepper: UIStepper!
    
   
  
    @IBOutlet weak var searchBar: UISearchBar!
    
   
    
   
    var _createdAt: AnyObject = "" as AnyObject
    var kawo: Int = 0
    var currentYear: Int = 0
    var firstDayOfWeek: String = ""
    var lastDayOfWeek: String = ""
    var abteil: String = "Montage"
    var sfilter: String = "*"
    var ssfilter: String = "*"
    var table : MSSyncTable?
    var store : MSCoreDataStore?
    var onrefresh : Bool = false
    var errorLocal : Bool = false
    var isConnected: Bool = true
    var counter : Int = 0
    
    let titleService = "Aktuelle Daten stehen momentan nicht zur Verfügung. Sie sehen die lokalen Daten die beim letzten Kontakt mit dem Service heruntergeladen worden sind."
    
    /*
    let titleService = "Sie haben momentan keinen Zugriff auf den Einsatzplan Mobile Service. Aktuelle Daten stehen nicht zur Verfügung."
    */
    let messageService = "Einsatzplan Actemium H&F App"
    var mob:[NSManagedObject] = []
    // MARK: UIsearchDelegate
    func searchBar(_ searchBar: UISearchBar,
                              textDidChange searchText: String){
        sfilter = "*\(searchText.lowercased())*"
        ssfilter = "*\(searchText)*"
        applyClick()
        
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar){
        searchBar.endEditing(true)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar){
        searchBar.endEditing(true)
    }
    
   
    
    @IBOutlet weak var buttonMontage: UIButton!
    @IBOutlet weak var buttonSer: UIBarButtonItem!
    
    @IBOutlet weak var buttonAutom: UIButton!
    @IBOutlet weak var buttonKFZ: UIButton!
    
    @IBAction func clickMon(_ sender: UIButton) {
        abteil = "Montage"
        applyClick()
        
    }
    @IBAction func clickServ(_ sender: AnyObject) {
        abteil = "Service"
        applyClick()
  }
    
    @IBAction func clickAutom(_ sender: UIButton) {
        abteil = "Automation"
        applyClick()    }
    
    @IBAction func clickKFZ(_ sender: UIButton) {
        abteil = "KFZ"
        applyClick()    }
    
    func applyClick() -> Void{
        fetchedResultController.fetchRequest.predicate = self.compPredicate()
        do {
            try self.fetchedResultController.performFetch()
        } catch let error1 as NSError {
            
            print("Unresolved error \(error1), \(error1.userInfo)")
            abort()
        }
        tableView.reloadData()
    }
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        self.kawo = Int(sender.value)
        self.firstDayOfWeek = getFirstDateOfWeek(self.kawo)
        self.lastDayOfWeek = getLastDateOfWeek(self.kawo)
        applyClick()
    }
    
    func compPredicate() -> NSCompoundPredicate  {
        
        let predicate1 = NSPredicate(format: "kw == %i", self.kawo)
        let predicate2 = NSPredicate(format: "abteilung == %@", self.abteil)
        let predicate3 = NSPredicate(format: "mitarbeiterNachname like %@ or mitarbeiterNachname like %@", self.sfilter, self.ssfilter)
        let compound = NSCompoundPredicate.init(andPredicateWithSubpredicates: [predicate1,predicate2, predicate3])
        return compound
    }
    
    lazy var fetchedResultController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TodoItem")
        let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!
        
       
        
        fetchRequest.predicate = self.compPredicate()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "mitarbeiterNachname", ascending: true)]
        
        // Note: if storing a lot of data, you should specify a cache for the last parameter
        // for more information, see Apple's documentation: http://go.microsoft.com/fwlink/?LinkId=524591&clcid=0x409
        let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        resultsController.delegate = self;
        
        return resultsController
    }();
    
    func respondToSwipeGesture(_ gesture: UISwipeGestureRecognizer?)  {
        if let swipeGesture = gesture {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                stepper.value -= 1;
                stepperValueChanged(self.stepper);
                //applyClick()
            case UISwipeGestureRecognizerDirection.left:
                stepper.value += 1;
                stepperValueChanged(self.stepper);
            default:
                break
            }
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 21
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ToDoTableViewController.respondToSwipeGesture(_:)));
        swipeRight.direction = UISwipeGestureRecognizerDirection.right;
        self.view.addGestureRecognizer(swipeRight);
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(ToDoTableViewController.respondToSwipeGesture(_:)));
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left;
        self.view.addGestureRecognizer(swipeLeft);
        
        self.searchBar.delegate = self
        
        setParameterAndSetter()
        // Do any additional setup after loading the view, typically from a nib.
        //let fileUrl = NSURL(string: "https://todoios.azure-mobile.net/")
        
        //let client = MSClient(applicationURL: fileUrl)
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let client = delegate.client
        let managedObjectContext = delegate.managedObjectContext!
        self.store = MSCoreDataStore(managedObjectContext: managedObjectContext)
        client.syncContext = MSSyncContext(delegate: nil, dataSource: self.store, callback: nil)
        self.table = client.syncTable(withName: "TodoItem")
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl!.addTarget(self, action: #selector(ToDoTableViewController.onRefresh(_:)), for: UIControlEvents.valueChanged)
        
        // Refresh data on load
        self.onrefresh = false
        self.onRefresh(self.refreshControl)
        
    }
    
    
    
    func onRefresh(_ sender: UIRefreshControl!) {
        
        
        var error : NSError? = nil
        let predicate =  NSPredicate(format: "true = true")
        //let predicateFalse =  NSPredicate(format: "true = false")
        
       
        self.refreshControl?.beginRefreshing()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        
        
        do {
            try self.fetchedResultController.performFetch()
        } catch let error1 as NSError {
            error = error1
            print("Unresolved error \(error), \(error?.userInfo)")
            abort()
        }
        
        self.tableView.reloadData()
        
        isConnected = isConnectedToNetwork()
        if !isConnected{
            self.popupAzureConflict()
        }
        else {
            self.table!.forcePurge(completion: nil)
            self.table!.pull(with: self.table!.query(with: predicate), queryId:"AllRecords") {
                (error) -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            /*
            if error != nil {
                // A real application would handle various errors like network conditions,
                // server conflicts, etc via the MSSyncContextDelegate
                print("Error: \(error!.description)")
                
                // We will just discard our changes and keep the servers copy for simplicity                
                if let opErrors = error!._userInfo[MSErrorPushResultKey] as Array<MSTableOperationError> {
                    for opError in opErrors {
                        print("Attempted operation to item \(opError.item["personalnummer"])")
                        if (opError.operation == MSTableOperationTypes() || opError.operation == .delete) {
                            print("Insert/Delete, failed discarding changes")
                            opError.cancelOperationAndDiscardItem(completion: nil)
                        } else {
                            print("Update failed, reverting to server's copy")
                            opError.cancelOperationAndUpdateItem(opError.serverItem!, completion: nil)
                        }
                    }
                }
            }
            */
                
        self.applyClick()
            
        }
            self.refreshControl?.endRefreshing()
        }
      
        self.refreshControl?.endRefreshing()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func popupAzureConflict(){
        // popup wind anzeigen
        let alert = UIAlertController(title: titleService, message: messageService, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Table Controls
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
    {
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String?
    {
        return "Complete"
    }
    
   
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let sections = self.fetchedResultController.sections {
            return sections[section].numberOfObjects
        }
        return 0;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier = "ToDoTVCCell"
        
        var cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as! ToDoTVCCell
        
            cell = configureCell(cell, indexPath: indexPath)
            return cell
        
    }
    
    override func willAnimateRotation(to toInterfaceOrientation:      UIInterfaceOrientation, duration: TimeInterval)
    {
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "KW \(self.kawo)   \(self.firstDayOfWeek) - \(self.lastDayOfWeek)  \(self.abteil)"
    }
    
    func configureCell(_ cell: ToDoTVCCell, indexPath: IndexPath) -> ToDoTVCCell {
        
        let item = self.fetchedResultController.object(at: indexPath) as! NSManagedObject
        
        
        if let text = item.value(forKey: "mitarbeiterNachname") as? String {
            cell.name!.text = text
        } else {
            cell.name!.text = ""
        }
 
        if let text2 = item.value(forKey: "mo") as? String {
            cell.mo!.text = text2
        } else {
            cell.mo!.text = ""
        }
        if let text3 = item.value(forKey: "di") as? String {
            cell.di!.text = text3
        } else {
            cell.di!.text = ""
        }
        if let text4 = item.value(forKey: "mi") as? String {
            cell.mi!.text = text4
        } else {
            cell.mi!.text = ""
        }
        if let text5 = item.value(forKey: "don") as? String {
            cell.don!.text = text5
        } else {
            cell.don!.text = ""
        }
        if let text6 = item.value(forKey: "fr") as? String {
            cell.fr!.text = text6
        } else {
            cell.fr!.text = ""
        }
        
        var myColor = UIColor.lightGray.cgColor
        let borderWidth = CGFloat(0.5)
        
        if indexPath.row % 2 == 0 {
           myColor = UIColor.clear.cgColor
        }
        else
        {
            let grey = UIColor(red: 232.0/255.0, green: 232.0/255.0, blue: 232.0/255.0, alpha: 1.0)
            myColor = grey.cgColor
            //myColor = UIColor.lightGrayColor().CGColor
        }
        cell.mo.layer.borderWidth = borderWidth
        cell.mo.layer.backgroundColor = myColor
        cell.di.layer.borderWidth = borderWidth
        cell.di.layer.backgroundColor = myColor
        cell.mi.layer.borderWidth = borderWidth
        cell.mi.layer.backgroundColor = myColor
        cell.don.layer.borderWidth = borderWidth
        cell.don.layer.backgroundColor = myColor
        cell.fr.layer.borderWidth = borderWidth
        cell.fr.layer.backgroundColor = myColor
        cell.name.layer.borderWidth = borderWidth
        cell.name.layer.backgroundColor = myColor
        
        return cell
    }
    
    
    /*
     2016-04-28 14:53:30.103 todoios[565:14090] *** Assertion failure in -[UITableView _endCellAnimationsWithContext:], /BuildRoot/Library/Caches/com.apple.xbs/Sources/UIKit_Sim/UIKit-3512.60.7/UITableView.m:1422
     2016-04-28 14:53:30.155 todoios[565:14090] *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'attempt to delete row 9 from section 0 which only contains 0 rows before the update'
    */
    /*
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
                self.tableView.endUpdates()
            
        });
    }
    */
    
    func setParameterAndSetter(){
        let currentWeekNumber = getWeek(Date());
        currentYear = getYear(Date())
        self.stepper.wraps = true
        self.stepper.autorepeat = true
        self.stepper.maximumValue = 53
        self.stepper.minimumValue = 1
        self.stepper.value =  Double(currentWeekNumber)
        self.kawo = Int(self.stepper.value)
        self.firstDayOfWeek = getFirstDateOfWeek(self.kawo)
        self.lastDayOfWeek = getLastDateOfWeek(self.kawo)
    }
    
    /*
    func printToDoItem(){
        // Query the TodoItem table
        let predicate =  NSPredicate(format: "true = true")
        let query = self.table!.query(with: predicate)
        
        query?.read { (result, error) in
            //if let err = error {
            //     print("ERROR ", err)
            // } else if let items = result?.items {
            if error == nil {
                print(result?.items.count)
                for item in (result!.items)! {
                    print("meldung:  \(item["personalnummer"])")
                }
            }
            
        }
    }
    */
    
    /*
     func deleteTable(){
        // Query the TodoItem table
        let predicate =  NSPredicate(format: "personalnummer  == 199")
        let query = self.table!.queryWithPredicate(predicate)
        query.orderByAscending("personalnummer")
        query.readWithCompletion { (result, error) in
            if let err = error {
                print("ERROR ", err)
            } else if let items = result?.items {
                print(items.count)
                
                for item in items {
                    self.table!.delete(item as! [NSObject : AnyObject]) { (error) in
                     if let err = error {
                        print("ERROR ", err)
                     } else {
                        print("Todo Item ID: ")
                     }
                     }
                    
                    print("PN: ", item["personalnummer"])
                }
            }
            
        }
    }
    */
    
    
}
