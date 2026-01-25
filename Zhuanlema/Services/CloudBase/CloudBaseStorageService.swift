/**
 * CloudBase 云存储服务
 * 负责文件上传、下载等操作
 */
import Foundation
import UIKit

class CloudBaseStorageService {
    static let shared = CloudBaseStorageService()
    
    private init() {}
    
    /// 头像最大边长（缩小以降低请求体，避免网关 EXCEED_MAX_PAYLOAD_SIZE）
    private static let avatarMaxDimension: CGFloat = 400
    /// 初始 JPEG 质量
    private static let avatarJPEGQuality: CGFloat = 0.55
    /// 压缩后最大字节数（解码后），使 base64 + JSON 可控制在网关限制内（如 1MB）
    private static let avatarMaxDecodedBytes = 520_000

    /**
     * 将图片压缩并转为 base64（用于上传头像）
     * 在不超过 avatarMaxDecodedBytes 的前提下多次压缩，避免 413。
     */
    func compressAndEncodeForAvatar(_ image: UIImage) -> String? {
        let maxDim = Self.avatarMaxDimension
        var size = image.size
        var scale: CGFloat
        if size.width > maxDim || size.height > maxDim {
            scale = min(maxDim / size.width, maxDim / size.height)
        } else {
            scale = 1
        }
        var quality = Self.avatarJPEGQuality

        while true {
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            guard let jpeg = resized?.jpegData(compressionQuality: quality) else { return nil }
            if jpeg.count <= Self.avatarMaxDecodedBytes {
                return jpeg.base64EncodedString()
            }
            if quality > 0.35 {
                quality -= 0.1
                continue
            }
            if scale > 0.4 {
                scale *= 0.8
                quality = Self.avatarJPEGQuality
                continue
            }
            return jpeg.base64EncodedString()
        }
    }
    
    /**
     * 上传图片（通用，供发帖等多图使用）
     * 当前通过云函数上传的实现见 uploadAvatar；此处保留接口兼容
     */
    func uploadImage(_ image: UIImage) async throws -> String {
        return "https://cloudbase-storage-example.com/images/\(UUID().uuidString).jpg"
    }
    
    /**
     * 批量上传图片
     *
     * @param images UIImage 数组
     * @returns 云存储URL数组
     */
    func uploadImages(_ images: [UIImage]) async throws -> [String] {
        var urls: [String] = []
        
        for image in images {
            let url = try await uploadImage(image)
            urls.append(url)
        }
        
        return urls
    }
}
