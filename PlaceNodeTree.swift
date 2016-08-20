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
    
//    Iterative tree function

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
                            queueNext.append(child) //queue holds nodes that are parents at this depth
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
    
    //Count each node until the node matching the index path requested is reached
    func returnNodeAtIndex(indexPath: Int) -> PlaceNodeTree?
    {
        var stack:[PlaceNodeTree] = [self]
        var currentNode:PlaceNodeTree? = self
        var visitedNodes:NSMutableSet = NSMutableSet()  //Set of Unique TreeNodes
        var counter = -1 //Start counter at -1 to indicate root node cannot be considered for matching index path
        var restart = false //used to determine when to call continue and restart while loop
        var removeParent = false
        
        while (currentNode != nil){
            //check the current node at the top of the stack and see if it has been counted
            if(!(visitedNodes.containsObject(currentNode!))){
                if(counter == indexPath) {    //check if node count matches index path
                    return currentNode
                }
                visitedNodes.addObject(currentNode!)
                counter += 1
            }
            //Loop over all current node's children to look for the next untraversed path
            if let children = currentNode?.children{
                for (childCount,child) in children.enumerate(){
                    if(!(visitedNodes.containsObject(child))){ //check for the first child that hasn't been traversed and add to stack
                        stack.append(child)
                        currentNode = child
                        restart = true
                        break   //first child found, quit for loop
                    }
                    //Keep track of when the current parent has iterated through all children
                    if(childCount == children.count - 1){ //child count enumerate is 0 based
                        removeParent = true
                    }
                }
                if(restart == true){
                    restart = false
                    continue    //restart while loop because there are more nodes to traverse to reach leaf
                }
            }
            //Once the leaf has been reached pop the leaf and reiterate while loop until a path is reached that hasn't been traversed
            //Don't reiterate over a leaf twice sunce this pop statement is only reached at the leaves
            if((currentNode?.children == nil) && (currentNode?.nodeValue == (stack.last)?.nodeValue)){
                stack.removeLast()
            }else if(currentNode?.children == nil){
                print("Unbalanced tree, current node is leaf \(currentNode?.nodeValue) but it is not on the Stack")
            }
            //Determine how to iterate over the stack, only pop parent if no more children exist
            if(removeParent){ //Only remove the parent if all children have been iterated over, otherwise, the parent remains the current node and top of stack
                removeParent = false
                stack.removeLast()  //Remove parent and don't reiterate over all child nodes
                currentNode = stack.count > 0 ? stack.last : nil
            }else{
                currentNode = stack.count > 0 ? stack.last : nil
            }
            
        }
        return nil  //No node was found matching index path
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
    
    
    
//     Unused
    //   Try 2 Depth first search for index path
    func returnNode(indexPath: Int) -> (Int,PlaceNodeTree?) {
        var leafCount = 0
        var tempCount = 0
        var treeNode:PlaceNodeTree? = nil
        
        if(self.children == nil)    //enter when each leaf is reached
        {
            return (1, nil)  //Counts the number of leaf nodes
        }else{
            //Check parent node for index path before checking children
            if(leafCount == indexPath){
                return (leafCount, self)     //Return calling parent if matching index path
            }else if let nodeChille = self.children{
                for child in nodeChille {
                    (tempCount, treeNode) = child.returnNode(indexPath)
                    leafCount += tempCount
                    if(leafCount == indexPath){     //Check on return for leaf node matching indexPath
                        return (leafCount, treeNode)
                    }
                }
            }
            leafCount += 1    //Reached after all children of the current node have been counted, include current node in the count
        }
        //reached when depth first traversal ends
        return (leafCount, treeNode)
    }
    
    //    Depth first tree traversal to map indexPath to a node
    func nodeAtIndexPath(indexPath: Int, nodeCount: Int) -> (currCount: Int, node: PlaceNodeTree?)  {
        var leafCount = 0
        var tempCount = 0
        var parentCount = 0
        var nodesTraversed = nodeCount
        var retNode:PlaceNodeTree? = nil
        if(self.children == nil)    //enter when each leaf is reached
        {
            if(nodeCount+1 == indexPath){   //Count the current leaf in the count of nodes traversed
                return (1, self)
            }
            else{
                return(1,nil)   //Leaves are counted by the child enumeration loop
            }
        }else{
            if(nodeCount == indexPath){   //Section root node is included in Node count
                return (1, self)  //Return 1 to Count the current node
            }
            else if let nodeChille = self.children{
                for child in nodeChille {
                    nodesTraversed += parentCount + leafCount   //enemurate starts at 0, count 1st parent node
                    //recurse into the next depth with a count of all previously recursed nodes plus the current parent
                    (tempCount, retNode) = child.nodeAtIndexPath(indexPath, nodeCount: nodesTraversed)
                    if(retNode != nil)  //If child was found matching index path then end recursion
                    {
                        return  (nodesTraversed, retNode)
                    }
                    leafCount += tempCount
                    if(leafCount + nodesTraversed == indexPath){   //Section root node is included in Node count
                        return (nodesTraversed, self)  //Return 1 to Count the current node
                    }
                }
//                parentCount += 1    //Count the current parent Node before counting it's leaves
            }
           
        }
        //reached when depth first traversal ends, leaf count holds total node count
        return (leafCount + parentCount, retNode)
    }
    

}
