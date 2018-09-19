//
//  Created by kaydell on 7/15/15.
//  Copyright (c) 2015 Kaydell Leavitt. All rights reserved.
//

import Foundation

public let tab = "\t"

// no xml key -- if this happens, it is an error.  you couldn't generate XML without an assertion happening.
public let xmlNoKey = ""

/**
 This class is used to parse an XML document.  The result is a document object model (DOM).
 The DOM is a tree.  Having the root node gives you access to all of the data of the DOM tree.
 The parsing is done by Apple's NSXMLParser object.
 Using this class, reads all of the data from the XML document into RAM memory, which isn't
 a problem with most documents, but should be kept in mind that you'll need enough RAM to
 hold the whole document in RAM.
 */
public class XMLDOMParser: NSObject, XMLParserDelegate {
    
    // MARK: - stored properties
    
    private var url_SP: URL           // The URL to read the document from
    private var root_SP: Node?          // The root to the resulting DOM tree
    private var currentNode_SP: Node?   // The currend node that data is being placed into
    private var firstError_SP: Error? // The first error.  Note that if an error occurs, all other data is ignored
    
    // MARK: - computed properties
    
    
    /// :returns: This property returns the root of the DOM tree.
    public var root: Node? {
        return root_SP
    }
    
    /**
     :returns: This property return the first error.  Either a parsing error (bad XML) or a validation error
     (the DTD doesn't validate).
     */
    public var firstError: Error? {
        return firstError_SP
    }
    
    /**
     :returns: This property returns XML that is equivalent to the original XML file that was parsed.
     Usually, instead of returning what was just parssed,
     this property is used to generate XML in a Save command.
     Your code can create a DOM tree and then use this property to generate the XML to save that data.
     */
    public override var description: String {
        if root_SP == nil {
            return ""
        } else {
            return root_SP!.toString(level: 0)
        }
    }
    
    // MARK: - initializers
    
    /**
     This initializer is used to create an XML DOM parser.
     :param: The URL to get the XML data from which is to be parsed.
     */
    public init(url: URL) {
        self.url_SP = url
    }
    
    // MARK: - instance methods
    
    /**
     You don't call this method yourself!
     This method is declared in the NSXMLParserDelegate protocol.
     This method is called by NSXMLParser when it starts parsing a document.
     */
    public func parserDidStartDocument(_ parser: XMLParser) {
    }
    
    /*
     This method is called by XMLParser when it starts parsing an element.  Notice that we
     store the element name and the attributes in a Node object.
     */
    public func parser(_: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        // don't do anything after the first error is found
        if firstError_SP != nil {
            return
        }
        // create a new element
        let node = Node(elementName: elementName, attributesDict: attributeDict)
        // if there is not a root yet, then this node is the root and the current node
        if root_SP == nil {
            root_SP = node
            currentNode_SP = node
            return
        }
        // otherwise add the new node as a child node to the current node and make the current node equal to the new node
        currentNode_SP!.appendChild(childNode: node)
        currentNode_SP = node
    }
    
    /*
     This method doesn't do anything but we seem to have to implement it for XMLParser to work.
     */
    public func parser(_ parser: XMLParser, foundCharacters string: String) {}
    
    /*
     This method is called when NSXMLParser finds the closing tag of an element.
     Notice that what we do is to set the current node to be the parent of the now current node.
     */
    public func parser(_: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // don't do anything after the first error is found
        if firstError_SP != nil {
            return
        }
        // make the current node the parent of the node named elementName
        assert(currentNode_SP != nil)
        currentNode_SP = currentNode_SP!.parent
    }
    
    /*
     This method is called by XMLParser when it tries to parse bad XML.  Note
     that we only keep track of the first error.
     */
    public func parser(_: XMLParser, parseErrorOccurred parseError: Error) {
        // don't do anything after the first error is found
        if firstError_SP != nil {
            return
        }
        // keep track of the first error
        self.firstError_SP = parseError
    }
    
    /*
     This method is called when NSXMLParser gets a validation error.  I believe that a validation
     error means that the XML is well-formed but that it doesn't validate against it DTD.
     Note that we only keep track of the first error of any kind.
     */
    public func parser(_: XMLParser, validationErrorOccurred validationError: Error) {
        // don't do anything after the first error is found
        if firstError_SP != nil {
            return
        }
        // keep track of the first error
        self.firstError_SP = validationError
    }
    
    /*
     This method is called when NSXMLParser has finished parsing a document.
     */
    public func parserDidEndDocument(_: XMLParser) {
        // don't do anything after the first error is found
        if firstError_SP != nil {
            return
        }
        assert(currentNode_SP == nil)
        // NSLog(self) // print out XML data that is equivalent to the data that was just parsed.
    }
    
    /*
     You call this method to begin parsing an XML document.
     */
    public func parse() -> Error? {
        // create a parser object
        let parser = XMLParser(contentsOf: url_SP)
        assert(parser != nil)
        parser!.delegate = self
        // parse the document
        parser!.parse()
        // return the error (if any)
        return firstError_SP
    }
    
    // MARK: - nested classes
    
    /*
     This class is a node of the DOM tree.  Note that our DOM tree is doubly-linked to that
     a node can have zero or one parent.  The root has zero parents and the rest of the nodes
     in the tree will have one parent node.
     Note that each node may have zero or more child nodes.
     */
    public class Node: CustomStringConvertible {
        
        // MARK: - types
        
        /*
         Attributes are returned from NSXMLParser as a dictionary of this type.
         */
        public typealias Attribute = (name: String, value: String)
        public typealias Attributes = [Attribute]
        
        // MARK: - stored properties
        
        private var elementName_SP: String      // The name of the XML element that this node represents.
        private var attributes_SP: Attributes?  // The attributes of the element, or nil if there are no elements
        private var parent_SP: Node?            // The parent element of this element
        private var children_SP: [Node]?        // An array of child elements, or nil if this element has no child elements.
        
        // MARK: - computed properties
        
        /*
         This property is the name of the element that this node represents.
         */
        public var elementName: String {
            get {
                return elementName_SP
            }
            set {
                elementName_SP = newValue
            }
        }
        
        /*
         This property yields the attributes of this element
         */
        public var attributes: Attributes? {
            return attributes_SP
        }
        
        /*
         This property yields the parent element of this element or, for the root element,
         nil because it has no parent.
         */
        public var parent: Node? {
            return parent_SP
        }
        
        /*
         This property yiels an array of child elements, or nil, if there are no child
         elements.
         */
        public var children: [Node]? {
            return children_SP
        }
        
        /*
         This property yields the number of child elements that this element has.
         */
        public var numChildren: Int {
            if children_SP == nil {
                return 0
            } else {
                return children_SP!.count
            }
        }
        
        /*
         This property will generate the XML code for the tree, or subtree, beginning
         with this element.  This property is used beginning with the root.
         The level parameter to toString() tells the code how many tabs to indent with.
         */
        public var description: String {
            return self.toString(level: 0)
        }
        
        // MARK: - initializers
        
        public init(elementName: String, attributesArray: [Attribute]? = nil) {
            elementName_SP = elementName
            attributes_SP = attributesArray
        }
        
        public convenience init(elementName: String, attributesDict: [String:String]?) {
            var attributes = Attributes()
            if attributesDict != nil {
                for entry in attributesDict! {
                    let attribute = (entry.key, entry.value)
                    attributes.append(attribute)
                }
            }
            self.init(elementName: elementName, attributesArray: attributes)
        }
        
        /*
         This method adds an attribute to this element.
         */
        public func appendAttribute(name: String, value: String) {
            if attributes == nil {
                attributes_SP = []
            }
            attributes_SP!.append((name: name, value: value))
        }
        
        /*
         This method will generate the XML for the DOM tree starting at this
         element.  Note that this method is recursive.
         */
        public func toString(level level1: Int) -> String {
            
            func repeatString(string: String, times: Int) -> String {
                var result = ""
                var i = 0
                while i < times {
                    result += string
                    i += 1
                }
                return result
            }
            
            var level2 = level1
            var isElementClosed = false
            // assure that the element name isn't the empty string
            assert(elementName_SP != xmlNoKey)
            // add the opening element along with any attributes
            var string = "\(repeatString(string: "\t", times: level2))<\(elementName_SP)"
            level2 += 1
            // add the attributes
            if attributes_SP != nil {
                for (name, value) in attributes_SP! {
                    string += " \(name)=\"\(value)\""
                }
            }
            // close the opening element
            if numChildren <= 0 {
                string += " />\n"
                isElementClosed = true
            } else {
                string += ">\n"
            }
            // add the child nodes
            if children_SP != nil {
                for child in children_SP! {
                    string += "\(child.toString(level: level2))"
                }
            }
            // add the closing element
            if !isElementClosed {
                level2 -= 1
                string += "\(repeatString(string: tab, times: level2))</\(elementName)>\n"
            }
            // return the result
            return string
        }
        
        // MARK: - instance methods
        
        /*
         This method will return the nth child, or nil if the index is too big.
         */
        public func child(n: Int) -> Node? {
            if n > numChildren - 1 {
                return nil
            } else {
                return children_SP![n]
            }
        }
        
        /*
         This method will return the attribute with the given key.
         nil is returned if there is not an attribute with the given
         key.
         */
        public func attributeNamed(key key1: String) -> String? {
            if attributes == nil {
                return nil
            } else {
                for attribute in attributes! {
                    let key2 = attribute.name
                    if key1 == key2 {
                        return attribute.value
                    }
                }
                return nil
            }
        }
        
        /*
         This method will return a Bool attribute using the given
         key.  If there is no attribute with the given key, then
         nil is returned.
         */
        public func boolAttribute(key: String) -> Bool? {
            let value: Any? = attributeNamed(key: key)
            if value == nil {
                return nil
            }
            let string = value! as! String
            switch string {
            case "1", "true":
                return true
            case "0", "false":
                return false
            default:
                return nil
            }
        }
        
        /*
         This method will return an Int attribute using the given
         key.  If there is no attribute with the given key, then
         nil is returned.
         */
        public func intAttribute(key: String) -> Int? {
            let value: Any? = attributeNamed(key: key)
            if value == nil {
                return nil
            }
            let intString = value! as! String
            return Int(intString)
        }
        
        /*
         This method will return a String attribute using the given
         key.  If there is no attribute with the given key, then
         nil is returned.
         */
        public func stringAttribute(key: String) -> String? {
            let value: Any? = attributeNamed(key: key)
            if value == nil {
                return nil
            }
            let string = value! as! String
            return string
        }
        
        /*
         This method will return a child node with the given
         element name.  Note that only immediate children (no grandchildren)
         are ever returned by this method.  nil is returned if
         there are no child nodes with the given name.
         */
        public func childNamed(elementName: String) -> Node? {
            var i = 0
            while i < numChildren {
                let node = child(n: i)
                if node == nil {
                    return nil
                }
                if node!.elementName == elementName {
                    return node
                }
                i += 1
            }
            return nil
        }
        
        /*
         This method is called to add a child node to a node.
         Note that this method is called both during parsing to assemble a tree
         and can also be called during archiving in your own code to assemble a tree.
         Once a tree is assembled, you can very easily generate XML by using the
         description property.
         */
        public func appendChild(childNode: Node) {
            // if the parent node doesn't have any children yet, then set its array of children to be an empty array
            if self.children_SP == nil {
                self.children_SP = []
            }
            // link from the child to the parent
            childNode.parent_SP = self
            // append the child node to the parent node's array of children
            self.children_SP!.append(childNode)
        }
        
    }
    
}
