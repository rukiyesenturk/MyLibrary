//
//  ViewController.swift
//  MyLibrary
//
//  Created by Macbook on 7.02.2022.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var bookSeries = [String]()
    var idSeries = [UUID]()
    
    var selectedProduct = ""//detailse atacağım seçilen ürün bilgileri için
    var selectedUUID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        //Navigationbarın üstüne add butonu ekliyorum ve addButtonClicked metodum ile yönlendirme(iş tanımı) yapıyorum.
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        navigationController?.navigationBar.topItem?.leftBarButtonItem = UIBarButtonItem(title: "My Book List")
        fetchData()
    }
    override func viewWillAppear(_ animated: Bool) {
        //detailsview controllerdan gelen verileri alacak olan gözlemci
        NotificationCenter.default.addObserver(self, selector: #selector(fetchData), name: NSNotification.Name(rawValue: "DataEntered"), object: nil)
    }
    @objc func addButtonClicked(){
        selectedProduct = ""
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    @objc func fetchData(){
        //verlerin tekrar etmemesi için dizilerimi temizlemem gerek.
        bookSeries.removeAll(keepingCapacity: false)
        idSeries.removeAll(keepingCapacity: false)
        
        //verileri getirmek için appdelegate ulaşmam gerekiyor kaydetme işleminde olduğu gibi
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        //context.save yerine context.fetch yapacağım ama bundan önce bir veri çekme isteği yapmam gerekecek.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Books")
        fetchRequest.returnsObjectsAsFaults = false//büyük veriler kaydederken gerekli olacak.
        do{
            let sonuclar = try context.fetch(fetchRequest)
            //fetch bize bir any dizisi yani bir obje döndürüyor ama biz NSManagedObject döndürmesini istiyoruz.
            //bunun için sonucları NSManagedObject olarak cast ediyorum.
            if sonuclar.count > 0 {
                for sonuc in sonuclar as! [NSManagedObject]{
                    if let book = sonuc.value(forKey: "bookname") as? String{
                        bookSeries.append(book)
                    }
                    if let id = sonuc.value(forKey: "id") as? UUID{
                        idSeries.append(id)
                    }
                }
                //güncelleme işlemi tamamlandıktan sonra tableview verileri güncelledik mesajı vermemiz gerekiyor güncelleme yapması için
                tableView.reloadData()
            }
        } catch{
            print("Hata var...")
        }
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookSeries.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = bookSeries[indexPath.row]
        return cell
    }
    //details ekranına veri atma seque ile gerçekleştirilecek.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            let destinationVC = segue.destination as! DetailsViewController
            destinationVC.selectedProductName = selectedProduct
            destinationVC.selectedProductUUID = selectedUUID
            //diğer sayfadaki verilerime veri aktarımını yaptık birde ekleme butonu içerisine selectedProductı boş bir string olarak vereceğim diğer sayfaya gidince değer ataması yapmaması için.
        }
            
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedProduct = bookSeries[indexPath.row]
        selectedUUID = idSeries[indexPath.row]
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    //Silme işlemi için editingStyle 'ı çağıracağım
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Books")
            let uuidString = idSeries[indexPath.row].uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let sonuclar = try context.fetch(fetchRequest)
                if sonuclar.count > 0{
                    for sonuc in sonuclar as! [NSManagedObject]{
                        if let id = sonuc.value(forKey: "id") as? UUID{
                            if id == idSeries[indexPath.row]{
                                context.delete(sonuc)
                                bookSeries.remove(at: indexPath.row)
                                idSeries.remove(at: indexPath.row)
                                
                                self.tableView.reloadData()
                                do{
                                    try context.save()
                                } catch{
                                    
                                }
                                break
                            }
                        }
                    }
                }
            } catch {
                print("Hata var...")
            }
        }
    }
}

