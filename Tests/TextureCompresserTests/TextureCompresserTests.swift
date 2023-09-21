import XCTest
import Metal
import MetalKit
@testable import TextureCompresser

final class CompressTextureTests: XCTestCase {
    let device = MTLCreateSystemDefaultDevice()!
    
    var compresser:TextureCompresser!
    
    override func setUp() async throws {
        compresser = TextureCompresser(device: device)
    }
   
    func makeTestTexture(pixels:[UInt8], size d:Int) -> MTLTexture {
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:.bgra8Unorm_srgb , width: d, height: d, mipmapped: false)
        
        descriptor.usage =   MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.shaderWrite.rawValue)
        let texture  = device.makeTexture(descriptor: descriptor)!
        
        let region = MTLRegionMake2D(0, 0, d, d)
        
        assert(pixels.count == 4 * d * d)
        
        var a = pixels

        texture.replace(region: region, mipmapLevel: 0, withBytes: &a, bytesPerRow: (4 * MemoryLayout<UInt8>.size ))
        
        return texture
    }
    
    func getUInt8( t:MTLTexture) -> [UInt8] {
        let w = t.width
        let h = t.height
        
        let region = MTLRegionMake2D(0, 0, w, h)
        
        var a = Array<UInt8>(repeating:0, count: 4*w*h)
        
        t.getBytes(&a, bytesPerRow: (4 * MemoryLayout<UInt8>.size * w), from: region, mipmapLevel: 0)
       
        return a
    }

    func compareTextures(s:MTLTexture, t:MTLTexture) -> Bool {
        let a = getUInt8(t: s)
        let b = getUInt8(t: t)
        print("\(a)->\(b)")
        return zip(a,b).allSatisfy { $0.0 == $0.1 }
    }
    
    func testOnePixelOpaqueTexture() throws {
        let testTexture = makeTestTexture(pixels: [24,72,233,255],size: 1)
        
        guard let pngData = compresser.compress(texture: testTexture)
        else {
            XCTFail("Failed to create png data.")
            return
        }
        
        let newTexture = try compresser.decompress(png: pngData)
        
        XCTAssert(compareTextures(s: testTexture, t: newTexture))
    }
    
    func testOnePixelSemiTransparantTexture() throws {
        let testTexture = makeTestTexture(pixels: [24,72,233,78],size:1)
        
        guard let pngData = compresser.compress(texture: testTexture)
        else {
            XCTFail("Failed to create png data.")
            return
        }
        
        let newTexture = try compresser.decompress(png: pngData)
        
        XCTAssert(compareTextures(s: testTexture, t: newTexture))
    }
    
    func testTwoByTwoOpaqueTexture() throws {
        let testTexture = makeTestTexture(pixels: [10,20,30,255,100,110,120,255,25,26,27,255,105,115,125,255],size: 2)
        
        guard let pngData = compresser.compress(texture: testTexture)
        else {
            XCTFail("Failed to create png data.")
            return
        }
        
        let newTexture = try compresser.decompress(png: pngData)
        
        XCTAssert(compareTextures(s: testTexture, t: newTexture))
    }
}
