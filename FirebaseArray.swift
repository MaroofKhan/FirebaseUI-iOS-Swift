/*
* FirebaseArray.swift
* Created by Maroof Khan.
*/

/*
* Firebase UI Bindings iOS Library
*
* Copyright © 2015 Firebase - All Rights Reserved
* https://www.firebase.com
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
* list of conditions and the following disclaimer.
*
* 2. Redistributions in binaryform must reproduce the above copyright notice,
* this list of conditions and the following disclaimer in the documentation
* and/or other materials provided with the distribution.
*
* THIS SOFTWARE IS PROVIDED BY FIREBASE AS IS AND ANY EXPRESS OR
* IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
* EVENT SHALL FIREBASE BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
* BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
* DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
* OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
* ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


import Foundation
import Firebase

protocol FirebaseArrayDelegate {
    func childAdded   (object: AnyObject, atIndex index: Int)
    func childChanged (object: AnyObject, atIndex index: Int)
    func childRemoved (object: AnyObject, atIndex index: Int)
    func childMoved   (object: AnyObject, fromIndex from: Int,
                                          toIndex to:Int)
}

class FirebaseArray {
    
    private let query:     FQuery
    private var snapshots: [FDataSnapshot]
    
    var delegate:  FirebaseArrayDelegate?
    var count: Int {
        return snapshots.count
    }
    
    convenience init (reference: Firebase) {
        self.init(query: reference)
    }
    
    private init (query: FQuery) {
        self.snapshots = [FDataSnapshot]()
        self.query = query
        self.setupListeners()
    }
    
    deinit {
        self.query.removeAllObservers()
    }
    
    private func setupListeners () {
        
        query.observeEventType(.ChildAdded, andPreviousSiblingKeyWithBlock: { (snapshot, previousChildKey) -> Void in
            let _index = self.index(previousChildKey)
            if let index = _index {
                self.snapshots.insert(snapshot, atIndex: (index + 1))
                self.delegate?.childAdded(snapshot, atIndex: (index + 1))
            }
        })
        
        query.observeEventType(.ChildChanged, andPreviousSiblingKeyWithBlock: { (snapshot, previousChildKey) -> Void in
            let _index = self.index(snapshot.key)
            if let index = _index {
                self.snapshots[index] = snapshot
                self.delegate?.childChanged(snapshot, atIndex: index)
            }
        })
        
        query.observeEventType(.ChildRemoved, withBlock: { (snapshot) -> Void in
            let _index = self.index(snapshot.key)
            if let index = _index {
                self.snapshots.removeAtIndex(index)
                self.delegate?.childRemoved(snapshot, atIndex: index)
            }

        })
        
        query.observeEventType(.ChildMoved, andPreviousSiblingKeyWithBlock: { (snapshot, previousChildKey) -> Void in
            let _toIndex = self.index(previousChildKey)
            let _fromIndex = self.index(snapshot.key)
            if let toIndex = _toIndex, fromIndex = _fromIndex {
                self.snapshots.insert(snapshot, atIndex: (toIndex + 1))
                self.delegate?.childMoved(snapshot, fromIndex: fromIndex, toIndex: (toIndex + 1))
            }
        })
        
    }
    
    private func index (key: String?) -> Int? {
        if let _key = key {
            for var index = 0; index < snapshots.count; index++ {
                if _key == snapshots[index].key {
                    return index
                }
            }
        } else {
            return -1
        }
        
        let reason = "Key \"\(key)\" not found in FirebaseArray \(snapshots)"
        let exception = NSException(name: "FirebaseArrayKeyNotFoundException", reason: reason, userInfo: [
            "Key"  : key!,
            "Array" : snapshots
            ])
        exception.raise()
        
        return nil
    }
    
    func object (index: Int) -> FDataSnapshot {
        return snapshots[index]
    }
    
    func reference (index: Int) -> Firebase {
        return snapshots[index].ref
    }
    
}
