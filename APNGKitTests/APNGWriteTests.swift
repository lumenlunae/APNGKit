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
    
    func testUIImageRead() {
        let bundle = Bundle(for: type(of: self))
        let imagePath = bundle.path(forResource: "demo", ofType: "png")!
        let image = UIImage(contentsOfFile: imagePath)!
        
        let newPNGImage = APNGImage(image: image)
        XCTAssertNotNil(newPNGImage, "Normal image should be created.")
        XCTAssertEqual(newPNGImage?.frames.count, 1, "There should be only one frame")
        XCTAssertNotNil(newPNGImage?.frames.first?.image,"The image of frame should not be nil")
        XCTAssertEqual(newPNGImage?.frames.first?.duration, TimeInterval.infinity, "And this frame lasts forever.")
        XCTAssertFalse(newPNGImage!.frames.first!.image!.isEmpty(), "This frame should not be an empty frame.")
    }
    
    func testUIImageWrite() {
        
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
