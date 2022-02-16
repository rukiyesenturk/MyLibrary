//
//  DetailsViewController.swift
//  MyLibrary
//
//  Created by Macbook on 8.02.2022.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var bookNameTextField: UITextField!
    @IBOutlet weak var bookWriterTextField: UITextField!
    @IBOutlet weak var bookAboutTextField: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    var selectedProductName = ""//viewcontrollerdaki seçili ürünlerden gelen değerleri alacağım buraya
    var selectedProductUUID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedProductName != "" {
            saveButton.isHidden = true // veri ile geliyorsam bu sayfama save butonum kapalı
            //CoreData seçilen ürün bilgilerini göster
            if let uuidString = selectedProductUUID?.uuidString{
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Books")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do{
                    let sonuclar = try context.fetch(fetchRequest)
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject]{
                            if let book = sonuc.value(forKey: "bookname") as? String{
                                bookNameTextField.text = book
                            }
                            if let writer = sonuc.value(forKey: "bookwriter") as? String{
                                bookWriterTextField.text = writer
                            }
                            if let about = sonuc.value(forKey: "booktype") as? String{
                                bookAboutTextField.text = about
                            }
                            if let imageData = sonuc.value(forKey: "bookimage") as? Data{
                                let image = UIImage(data: imageData)
                                imageView.image = image
                            }
                        }
                    }
                }catch{
                    print("Hata var...")
                }
            }
            
        }else{
            saveButton.isHidden = false //yeni veri girmek için geldiğimde ise save butonum açık olacak.
            bookNameTextField.text = ""
            bookWriterTextField.text = ""
            bookAboutTextField.text = ""
        }
        // klavyeyi kapatmak için parmak hareketlerini algılayan UITapGestureRecognizer'ı kullanacağız.
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        
        //image'i G.R ile tıklanabilir hale getirelim
        imageView.isUserInteractionEnabled = true
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(chooseImage))
        imageView.addGestureRecognizer(imageGestureRecognizer)
    }
    @objc func closeKeyboard(){
        view.endEditing(true)
    }
    @objc func chooseImage(){
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.editedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func saveButton(_ sender: Any) {
        //kayıt işlemi için appdelegatedeki contexte ulaşmam gerekiyor
        //bunun için appdelegate i değişken gibi tanımlamam gerekiyor.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        //veritabanındaki alisveris listeme ulasmam gerek.
        let myBooks = NSEntityDescription.insertNewObject(forEntityName: "Books", into: context)
        //veri tabanına değer atamalarını yapalım.
        myBooks.setValue(bookNameTextField.text!, forKey: "bookname")
        myBooks.setValue(bookWriterTextField.text!, forKey: "bookwriter")
        myBooks.setValue(bookAboutTextField.text!, forKey: "booktype")
        
        //universal unique id -- herkesin idsi farklı olacak
        myBooks.setValue(UUID(), forKey: "id")
        
        //imageview bir veriye çavirmemiz gerekmektedir.
        let data = imageView.image!.jpegData(compressionQuality: 0.5)
        myBooks.setValue(data, forKey: "bookimage")
        
        //son olarak bunu kaydetmemiz gerekecek.
        do{
            try context.save()
            print("Kaydedildi.")
        } catch{
            print("Hata var.")
        }
        
        //Kayıt olmuş gözlemcilere bilgi yayını yap
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DataEntered"), object: nil)
        //Bir önceki controllere dön
        self.navigationController?.popViewController(animated: true)
    }
}
