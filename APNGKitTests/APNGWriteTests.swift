//
//  APNGWriteTests.swift
//  APNGKit
//
//  Created by Matt on 9/12/16.
//  Copyright © 2016 OneV's Den. All rights reserved.
//

import XCTest
@testable import APNGKit

class APNGWriteTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        APNGImage.searchBundle = Bundle.testBundle
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        APNGImage.searchBundle = Bundle.main
        super.tearDown()
    }
    
    func testUIImageWriteSingleFrame() {
        let bundle = Bundle(for: type(of: self))
        let fileName = ("demo", "png")
        let imagePath = bundle.path(forResource: fileName.0, ofType: fileName.1)!
        let image = UIImage(contentsOfFile: imagePath)!
        
        let newPNGImage = APNGImage(image: image)
        
        let dir = NSTemporaryDirectory() as NSString
        let path = dir.appendingPathComponent("\(fileName.0).\(fileName.1)")
        let fileURL = URL(fileURLWithPath: path)
        try! newPNGImage?.write(to: fileURL)
        
        let imageExists = FileManager.default.fileExists(atPath: path)
        print("Path: \(path)")
        let savedImage = UIImage(contentsOfFile: path)
        XCTAssertTrue(imageExists, "Saved file should be created.")
        XCTAssertNotNil(savedImage, "Saved image should be readable as image.")
    }
    
    func testUIImageWriteMultipleFrames() {
        let bundle = Bundle(for: type(of: self))
        let fileName = ("spinfox", "apng")
        let imagePath = bundle.path(forResource: fileName.0, ofType: fileName.1)!
        let newPNGImage = APNGImage(contentsOfFile: imagePath)
        
        let dir = NSTemporaryDirectory() as NSString
        let path = dir.appendingPathComponent("\(fileName.0).\(fileName.1)")
        let fileURL = URL(fileURLWithPath: path)
        try! newPNGImage?.write(to: fileURL)
        
        let imageExists = FileManager.default.fileExists(atPath: path)
        print("Path: \(path)")
        let savedImage = UIImage(contentsOfFile: path)
        XCTAssertTrue(imageExists, "Saved file should be created.")
        XCTAssertNotNil(savedImage, "Saved image should be readable as image.")
    }
}

extension UIImage {
    convenience init?(color: UIColor, size: CGSize) {
        defer {
            UIGraphicsEndImageContext()
        }
        var rect = CGRect.zero
        rect.size = size
        UIGraphicsBeginImageContext(size)
        let path = UIBezierPath(rect: rect)
        color.setFill()
        path.fill()
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
            let cgImage = image.cgImage else {
            return nil
        }
        
        self.init(cgImage: cgImage)
    }
}
