//
//  HomeViewController.swift
//  Instagram
//
//  Created by 坂本充生 on 2020/07/04.
//  Copyright © 2020 Michio.Sakamoto. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController ,UITableViewDataSource,UITableViewDelegate,UITextViewDelegate{

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: UITextView!
    // 投稿データを格納する配列
    var postArray: [PostData] = []
    // Firestoreのリスナー
    var listener: ListenerRegistration!
    var targetButton :UIButton!
    
    var postArrayIndexRow:Int!
    
    var moveHeight :CGFloat = 0.0
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        textView.delegate = self

        // カスタムセルを登録する
        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        textView.isHidden = true
        //textViewの文字入力終了ボタンを設置
        let custombar = UIView(frame: CGRect(x:0, y:0,width:(UIScreen.main.bounds.size.width),height:40))
        let sendBtn = UIButton(frame: CGRect(x:(UIScreen.main.bounds.size.width)-50,y:0,width:50,height:40))
        sendBtn.setTitle(NSLocalizedString("送る", comment: ""), for: .normal)
        sendBtn.setTitleColor(UIColor.blue, for:.normal)
        sendBtn.addTarget(self, action:#selector(onClickSendButton), for: .touchUpInside)
        custombar.addSubview(sendBtn)
        textView.inputAccessoryView = custombar
        
        //キーボードサイズ取得用
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")

        if Auth.auth().currentUser != nil {
            // ログイン済み
            if listener == nil {
                // listener未登録なら、登録してスナップショットを受信する
                let postsRef = Firestore.firestore().collection(Const.PostPath).order(by: "date", descending: true)
                listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
                    if let error = error {
                        print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                        return
                    }
                    // 取得したdocumentをもとにPostDataを作成し、postArrayの配列にする。
                    self.postArray = querySnapshot!.documents.map { document in
                        print("DEBUG_PRINT: document取得 \(document.documentID)")
                        let postData = PostData(document: document)
                        return postData
                    }
                    // TableViewの表示を更新する
                    self.tableView.reloadData()
                }
            }
        } else {
            // ログイン未(またはログアウト済み)
            if listener != nil {
                // listener登録済みなら削除してpostArrayをクリアする
                listener.remove()
                listener = nil
                postArray = []
                tableView.reloadData()
            }
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得してデータを設定する
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PostTableViewCell
        cell.setPostData(postArray[indexPath.row])
        
        // セル内のボタンのアクションをソースコードで設定する
        cell.likeButton.addTarget(self, action:#selector(handleButton(_:forEvent:)), for: .touchUpInside)
        
        //セル内のコメントボタンを押された時のアクション
        cell.commentButton.addTarget(self,action:#selector(handleCommentButton(_:forEvent:)),for: .touchUpInside)
        

        return cell
    }
    //コメントボタンを押された時のメソッド
    @objc func handleCommentButton(_ sender: UIButton,forEvent event:UIEvent){
        print("コメントボタン押されたよ！！")
        targetButton = sender
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)

        // 配列からタップされたインデックスのデータを取り出す
//        let postData = postArray[indexPath!.row]
        postArrayIndexRow = indexPath!.row
        
        if sender.isEnabled == true{
        //        textview表示
            textView.frame.origin.y = view.frame.maxY
            textView.layer.cornerRadius = 5
            textView.layer.borderWidth = 1
            textView.layer.borderColor = UIColor.lightGray.cgColor
            textView.isHidden = false
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .allowUserInteraction, animations: {
                self.textView.frame.origin.y -= 100.0
            }, completion: nil)
            textView.becomeFirstResponder()
            sender.isEnabled = false
        }
        
    }
    //textViewを送信しキーボードを閉じる
    @objc func onClickSendButton(){
        //データベースに登録
        
        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[postArrayIndexRow!]
        // commentを更新する
        if (Auth.auth().currentUser?.uid) != nil {
            // 更新データを作成する
            var updateValue: FieldValue
            //textViewを追加する更新データを作成
            let upData = postData.name! + "さん_" + textView.text!
            updateValue = FieldValue.arrayUnion([upData])
            //textViewに更新データを書き込む
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
            postRef.updateData(["comment": updateValue])
        }
        
        //Viewをゆっくり元に戻す
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .allowUserInteraction, animations: {
            self.textView.frame.origin.y += 100.0
//            self.view.frame.origin.y +=  self.moveHeight
            self.view.frame.origin.y +=  250
            }) { (completed) in
                // Animationが完了したらtextViewを削除する
//                self.view.frame.origin.y =  0
//                self.textView.removeFromSuperview()
                self.textView.text = ""
                self.targetButton.isEnabled = true
            }
        textView.resignFirstResponder()
    }
    //キーボードを閉じる
    @objc func onClickCancelButton(){
        //Viewをゆっくり元に戻す
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .allowUserInteraction, animations: {
            self.textView.frame.origin.y += 100.0
//            self.view.frame.origin.y +=  self.moveHeight
            self.view.frame.origin.y +=  250
            }) { (completed) in
                // Animationが完了したらtextViewを削除する
//                self.view.frame.origin.y =  0
//                self.textView.removeFromSuperview()
                self.textView.text = ""
                self.targetButton.isEnabled = true
            }
        textView.resignFirstResponder()
    }
    //textViewをタップ、viewを上にあげる
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {

        //Viewを0.5秒で上にあげる(本当はキーボード高さ分のみ上げたい)
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.allowUserInteraction, animations: {
            self.view.frame.origin.y = -250
        })
        return true
    }

    //キーボードが出てきた時
//    @objc func keyboardWillShow(notification : NSNotification){
//        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//            if self.view.frame.origin.y == 0 {
////                self.view.frame.origin.y -= keyboardSize.height
//                moveHeight = keyboardSize.height
//            } else {
////                let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
////                self.view.frame.origin.y -= suggestionHeight
//                moveHeight = self.view.frame.origin.y + keyboardSize.height
//            }
//
//            self.view.frame.origin.y -= moveHeight
//        }
//    }
    
    // セル内のボタンがタップされた時に呼ばれるメソッド
    @objc func handleButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: likeボタンがタップされました。")

        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)

        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]

        // likesを更新する
        if let myid = Auth.auth().currentUser?.uid {
            // 更新データを作成する
            var updateValue: FieldValue
            if postData.isLiked {
                // すでにいいねをしている場合は、いいね解除のためmyidを取り除く更新データを作成
                updateValue = FieldValue.arrayRemove([myid])
            } else {
                // 今回新たにいいねを押した場合は、myidを追加する更新データを作成
                updateValue = FieldValue.arrayUnion([myid])
            }
            // likesに更新データを書き込む
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
            postRef.updateData(["likes": updateValue])
        }
    }

}
