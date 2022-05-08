//
//  MetalView.swift
//  MetalKitAndRenderingSetup
//
//  Created by Eric Bodnick on 5/7/22.
//

import MetalKit
import SwiftUI

@available(macOS 10.15, *)
private class MetalViewDelegate: NSObject, MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        sizeChanged(view, size)
    }
    
    init(_ draw: @escaping (MTKView) -> Void, sizeChanged: @escaping (MTKView, CGSize) -> Void) {
        self.draw = draw
        self.sizeChanged = sizeChanged
    }
    
    var sizeChanged: (MTKView, CGSize) -> Void
    
    var draw: (MTKView) -> Void
    
    func draw(in view: MTKView) {
        draw(view)
    }
}

@available(tvOS 13.0, iOS 13.0, macOS 10.15, *)
/// Displays Metal content.
public struct MetalView {
    private var device: MTLDevice?
    private var delegate: MetalViewDelegate = .init { _ in } sizeChanged: { _, _ in }
  
    private var pixelColorFormat: MTLPixelFormat = .bgra8Unorm
    private var colorspace: CGColorSpace?
    private var frameBufferOnly = true
    private var clearColor = MTLClearColor()
    
    private var depthStencilPixelFormat: MTLPixelFormat = .invalid
    private var depthStencilAttachmentTextureUsage: MTLTextureUsage = .renderTarget
    private var clearDepth = 1.0
    private var clearStencil: UInt32 = 0
    
    private var sampleCount = 1
    private var multisampleColorAttachmentTetureUsage: MTLTextureUsage = .renderTarget
    
    private var isPaused = false
    private var preferredFPS = 60
    private var enablesSetNeedsDisplay = false
    
    
    public init(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        self.device = device
    }
    
    func makeView() -> MTKView {
        MTKView(frame: .zero, device: device)
    }
    
    public func draw(do draw: @escaping (MTKView) -> Void) -> Self {
        let copy = self
        copy.delegate.draw = draw
        return copy
    }
    
    public func onSizeChange(do something: @escaping (MTKView, CGSize) -> Void ) -> Self {
        let copy = self
        copy.delegate.sizeChanged = something
        return copy
    }
    
    func updateView(_ view: MTKView) {
        view.delegate = delegate
        view.enableSetNeedsDisplay = enablesSetNeedsDisplay
        view.clearColor = clearColor
        view.colorPixelFormat = pixelColorFormat
        #if os(iOS) || os(watchOS) || os(tvOS)
        #else
        view.colorspace = colorspace
        #endif
        
        view.framebufferOnly = frameBufferOnly
        view.depthStencilPixelFormat = depthStencilPixelFormat
        view.depthStencilAttachmentTextureUsage = depthStencilAttachmentTextureUsage
        view.clearDepth = clearDepth
        view.clearStencil = clearStencil
        
        view.sampleCount = sampleCount
        view.multisampleColorAttachmentTextureUsage = multisampleColorAttachmentTetureUsage
        
        view.isPaused = isPaused
        view.preferredFramesPerSecond = preferredFPS
    }
    
    
    public func needsRedrawing() -> Self {
        var copy = self
        copy.enablesSetNeedsDisplay = true
        return copy
    }
    
    public func clearColor(red: Double, green: Double, blue: Double, alpha: Double = 1) -> Self {
        var copy = self
        copy.clearColor = MTLClearColor(red: red, green: green, blue: blue, alpha: alpha)
        return copy
    }
    
    public func colorFormat(_ format: MTLPixelFormat) -> Self {
        var copy = self; copy.pixelColorFormat = format; return copy
    }
}

#if os(iOS) || os(tvOS)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension MetalView: UIViewRepresentable {
    public func makeUIView(context: Context) -> MTKView {
        makeView()
    }
    
    public func updateUIView(_ uiView: MTKView, context: Context) {
        updateView(uiView)
    }
}

#else
@available(macOS 10.15, *)
extension MetalView: NSViewRepresentable {
    public func makeNSView(context: Context) -> MTKView {
        makeView()
    }
    
    public func updateNSView(_ nsView: MTKView, context: Context) {
        updateView(nsView)
    }
}

#endif
