//
//  PlaceNodeTree.swift
//  Beta2
//
//  Created by Jason Johnston on 8/14/16.
//  Copyright © 2016 anuJ. All rights reserved.
//

import Foundation

//Implement Tree Stucture
class PlaceNodeTree{
    var nodeValue: String?
    var depth: Int?
    
    var parent: PlaceNodeTree?
    var children: [PlaceNodeTree]?
    
    //create root node
    init()
    {
        self.nodeValue = "Root"
        self.parent = nil
        self.children = nil
        self.depth = 0
    }
    
    init(nodeVal: String)
    {
        self.nodeValue = nodeVal
        self.parent = nil
        self.children = nil
        self.depth = 0
    }
    
    func setVal(nodeVal: String){
        self.nodeValue = nodeVal
    }
    
    func addChild(node: PlaceNodeTree) {
        if (self.children == nil){
            self.children = [node]
        }else{
            self.children?.append(node)
        }
        node.parent = self
        node.depth = self.depth! + 1
    }
    
    func search(value: String) -> PlaceNodeTree? {
        if value == self.nodeValue {
            return self
        }
        if let nodeChille = children{
            for child in nodeChille {
                if let found = child.search(value) {
                    return found
                }
            }
        }
        return nil
    }
    
    func nodeCountAtDepth(depth: Int) -> Int {
        if(self.children == nil)
        {
            return 0
        }else{
            return recursiveTreeTraversal([self], depth: depth, count: 0)
        }
    }
    
//    Breadth width recursion of the tree starting at the passed root node
        //Each succesive recursivve itertion is the next depth level 
    func recursiveTreeTraversal(queue: [PlaceNodeTree], depth: Int, count: Int) -> Int{
        var newCount = 0
        var queueNext:[PlaceNodeTree] = []
        
        for node in queue{
            //Iterate over each child if node contains children and add child to queueNext
            if let nodeChille = node.children{
                for child in nodeChille {
                    if(depth < 0){  //Count all nodes if depth = -1
                        newCount+=1  //newCount contains a breadth width count of nodes at the current level
                        if(child.children != nil){
                            queueNext.append(child) //only add node to queue if there are children to traverse
                        }
                    }
                    else if(child.depth == depth){
                        print(child.nodeValue)
                        newCount+=1
                    }
                    else{  //Only add children if current depth hasn't been reached
                        queueNext.append(child)
                    }
                }
            }
        }
        if (queueNext.count == 0){  //return the count of all nodes down to this branch.
            return newCount + count //newCount is the current leaves, and count is all the parents on the path to this leaf
        }else{
            return recursiveTreeTraversal(queueNext, depth: depth, count: newCount)   //Only need the count for one level so I don't have to add the count argument from current function call
        }
        
    }
    
    func sortChildNodes() {
        var queue:[PlaceNodeTree] = [self]
        var queueNext:[PlaceNodeTree]  = []
        var queueSort:[PlaceNodeTree]  = []
        while(queue.count > 0){
            for node in queue{
                //Iterate over each child if node contains children and add child to queueNext
                if let nodeChille = node.children{
                    for child in nodeChille {
                         //Children are sorted during the parent node's iteration, don't add leaves to queueNext
                        queueSort.append(child) //queue only holds current parent's nodes
                        if(child.children != nil){
                            queueNext.append(child) //queue holds nodes of all parents at this depth
                        }
                    }
                    //Sort all children for the current node
                     //Move + sign to end of sort
                     queueSort.sortInPlace({(node1:PlaceNodeTree, node2:PlaceNodeTree) -> Bool in
                        return node1.nodeValue < node2.nodeValue
                     })
                    node.children = queueSort
                    queueSort.removeAll()  //clear queue sort so next parent only sorts its children
                }
            }
            queue = queueNext   //iterate over the next depth
            queueNext.removeAll()
        }
        
    }

    
//    Depth first count of all nodes starting at calling node
    func nodeCount() -> Int {
        var leafCount = 0
        if(self.children == nil)    //enter when each leaf is reached
        {
            return 1  //Counts the number of leaf nodes
        }else{
            if let nodeChille = self.children{
                for child in nodeChille {
                    leafCount += child.nodeCount()
                }
            }
            leafCount += 1    //Reached after all children of the current node have been counted, include current node in the count
        }
        //reached when depth first traversal ends
        return leafCount
    }
    

}
