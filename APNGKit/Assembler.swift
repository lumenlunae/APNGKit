//
//  Disassembler.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/27.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

// Writing callback for libpng
func writeData(_ pngPointer: png_structp?, inBytes: png_bytep?, byteCountToWrite: png_size_t) {
    guard let pngPointer = pngPointer, let inBytes = inBytes else {
        return
    }
    
    let ioPointer = png_get_io_ptr(pngPointer)
    var writer = UnsafeRawPointer(ioPointer)!.load(as: Writer.self)
    
    writer.write(inBytes, bytesCount: byteCountToWrite)
}

/**
 Assembler Errors. An error will be thrown if the assembler encounters
 unexpected error.
 
 - InvalidFormat:       The file is not a PNG format.
 - PNGStructureFailure: Fail on creating a PNG structure. It might due to out of memory.
 - PNGInternalError:    Internal error when decoding a PNG image.
 - FileSizeExceeded:    The file is too large. There is a limitation of APNGKit that the max width and height is 1M pixel.
 */
public enum AssemblerError: Error {
    case invalidFormat
    case pngStructureFailure
    case pngInternalError
    case fileSizeExceeded
}

struct Assembler {
    fileprivate(set) var writer: Writer
    let image: APNGImage
    
    public init?(url: URL, apng: APNGImage) {
        guard let writer = Writer(url: url) else {
            return nil
        }
        self.writer = writer
        self.image = apng
    }
    
    mutating func encode() throws {
        
        
    }
    
    mutating func save() throws {
        writer.beginWriting()
        defer {
            writer.endWriting()
        }
        
        var pngPointer = png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        
        if pngPointer == nil {
            throw AssemblerError.pngStructureFailure
        }
        
        var infoPointer = png_create_info_struct(pngPointer)
        
        defer {
            png_destroy_write_struct(&pngPointer, &infoPointer)
        }
        
        if infoPointer == nil {
            throw AssemblerError.pngStructureFailure
        }
        
        png_set_write_fn(pngPointer, &writer, writeData, nil)
        
        let width = UInt32(self.image.size.width * self.image.scale)
        let height = UInt32(self.image.size.height * self.image.scale)
        let bitDepth = Int32(self.image.bitDepth)
        // TODO
        let colorType: Int32 = PNG_COLOR_TYPE_RGB_ALPHA
        let interlaceMethod: Int32 = 0
        let compressionMethod: Int32 = 0
        let filterMethod: Int32 = 0
        png_set_IHDR(pngPointer, infoPointer, width, height, bitDepth, colorType, interlaceMethod, compressionMethod, filterMethod)
        //png_write_info_before_PLTE(pngPointer, infoPointer)
        
        let frameCount: UInt32 = UInt32(self.image.frames.count)
        // RepeatForever is -1
        let playCount: UInt32 = UInt32(self.image.repeatCount + 1)
        png_set_acTL(pngPointer, infoPointer, frameCount, playCount)
        
        png_write_info(pngPointer, infoPointer)
        
        // firstFrameHidden?
        for i in 0..<self.image.frames.count {
            var frame = self.image.frames[i]
            var frameBytes = frame.bytes
            
            let offsetX: UInt32 = 0
            let offsetY: UInt32 = 0
            let frameWidth = width
            let frameHeight = height
            let delayNum: UInt16 = 100
            let delayDen: UInt16 = 100
            var disposeOP: UInt8 = 0
            var blendOP: UInt8 = 0
            
            frame.byteRows.withUnsafeMutableBufferPointer({ buffer in
                _ = withUnsafeMutablePointer(to: &buffer)  { (boundBuffer) in
                    boundBuffer.withMemoryRebound(to: (UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>).self, capacity: MemoryLayout<(UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>)>.size) { (rows) in
                        png_set_rows(pngPointer, infoPointer, rows.pointee)
                        png_write_frame_head(pngPointer, infoPointer, rows.pointee, frameWidth, frameHeight, offsetX, offsetY, delayNum, delayDen, disposeOP, blendOP)
                        
                    }
                }
            })
            
            png_set_next_frame_fcTL(pngPointer, infoPointer, frameWidth, frameHeight, offsetX, offsetY, delayNum, delayDen, disposeOP, blendOP)
            
            frame.byteRows.withUnsafeMutableBufferPointer({ buffer in
                _ = withUnsafeMutablePointer(to: &buffer)  { (boundBuffer) in
                    boundBuffer.withMemoryRebound(to: (UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>).self, capacity: MemoryLayout<(UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>)>.size) { (rows) in
                        
                        png_write_image(pngPointer, rows.pointee)
                    }
                }
            })
            
            png_write_frame_tail(pngPointer, infoPointer)
            
        }
        
        png_write_end(pngPointer, infoPointer)
    }
}
