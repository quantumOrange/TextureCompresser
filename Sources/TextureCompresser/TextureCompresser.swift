import Foundation
import Metal
import MetalKit

public struct TextureCompresser {
    let context:CIContext
    let loader:MTKTextureLoader
    
    public init(device:MTLDevice) {
        loader = MTKTextureLoader(device: device)
        context = CIContext(options: [
            CIContextOption.outputPremultiplied: false,
                           ])
    }
    
    public func compress(texture:MTLTexture) -> Data? {
        let options:[CIImageOption:Any] = [CIImageOption.colorSpace:CGColorSpace(name: CGColorSpace.linearSRGB)!]
             
        guard let ciImage = CIImage(mtlTexture: texture, options:options)
            else { return nil }
        
        return  context.pngRepresentation(of: ciImage, format: .BGRA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)

    }
    
    public func decompress(png:Data) throws -> MTLTexture {
        let usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.shaderWrite.rawValue)
        
        let options:[MTKTextureLoader.Option : Any] = [
                                MTKTextureLoader.Option.textureUsage:usage.rawValue,
                                MTKTextureLoader.Option.origin:MTKTextureLoader.Origin.flippedVertically.rawValue,
                                MTKTextureLoader.Option.SRGB:NSNumber(value: true),
                                MTKTextureLoader.Option.generateMipmaps:NSNumber(value: false),
                            ]
        
        return try loader.newTexture(data:png,options:options)
    }
}
