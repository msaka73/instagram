//
//  PostData.swift
//  Instagram
//
//  Created by 坂本充生 on 2020/07/09.
//  Copyright © 2020 Michio.Sakamoto. All rights reserved.
//

import UIKit
import Firebase

class PostData: NSObject {
    var id: String
    var name: String?
    var caption: String?
    var date: Date?
    var likes: [String] = []
    var isLiked: Bool = false
    //コメントとコメント投稿者
    var commnet: [String] = []
//    var commnetName: [String] = []

    init(document: QueryDocumentSnapshot) {
        self.id = document.documentID

        let postDic = document.data()

        self.name = postDic["name"] as? String

        self.caption = postDic["caption"] as? String

        let timestamp = postDic["date"] as? Timestamp
        self.date = timestamp?.dateValue()

        if let likes = postDic["likes"] as? [String] {
            self.likes = likes
            print("self.likes:\(self.likes)")
        }
        if let myid = Auth.auth().currentUser?.uid {
            // likesの配列の中にmyidが含まれているかチェックすることで、自分がいいねを押しているかを判断
            if self.likes.firstIndex(of: myid) != nil {
                // myidがあれば、いいねを押していると認識する。
                self.isLiked = true
            }
        }
        if let postComment = postDic["comment"] as? [String]{
            self.commnet = postComment
        }
        
//        if let comment = postDic["comment"] as? [String]{
//
//        }
        
    }
}
