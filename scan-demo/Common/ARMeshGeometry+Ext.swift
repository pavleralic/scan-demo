/// ARMeshGeometry+Ext.swift
/// This extension provides utility functions for handling and converting ARKit-generated mesh geometry.
/// The main purposes of this extension are:
///   - Extracting vertex data from an `ARMeshGeometry` object.
///   - Transforming local vertex coordinates into world coordinates using a provided model matrix.
///   - Converting ARKit's mesh format to `MDLMesh`, a Model I/O representation, for further processing, exporting, or rendering.
///
/// This extension is particularly useful in applications involving 3D scanning, AR object reconstruction,
/// and exporting scanned meshes to formats compatible with 3D modeling software.

import RealityKit
import ARKit
import MetalKit

extension ARMeshGeometry {
    /// Retrieves the vertex position at a given index within the ARMeshGeometry.
    ///
    /// - Parameter index: The index of the vertex to retrieve.
    /// - Returns: The 3D position of the vertex as a `SIMD3<Float>`.
    ///
    /// - Usage:
    ///   This function is used to extract individual vertex positions from the mesh geometry,
    ///   which is necessary for transforming, processing, or exporting scanned meshes.
    ///
    /// - How it works:
    ///   1. Verifies that the vertex format is `float3`, ensuring that each vertex consists of three floating-point numbers (X, Y, Z).
    ///   2. Computes the memory address of the desired vertex based on its index.
    ///   3. Reads the vertex position from the buffer and returns it.
    func vertex(at index: UInt32) -> SIMD3<Float> {
        assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
        let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
        return vertex
    }
    
    /// Converts the ARKit mesh to an `MDLMesh` (Model I/O Mesh) for further processing or exporting.
    ///
    /// - Parameters:
    ///   - device: A `MTLDevice` used for allocating buffers required by Model I/O.
    ///   - camera: The ARKit `ARCamera` that provides camera pose information (not used directly but included for context).
    ///   - modelMatrix: A transformation matrix that converts local vertex positions to world-space coordinates.
    /// - Returns: An `MDLMesh` representation of the ARKit mesh, including vertex and index buffers.
    ///
    /// - Purpose:
    ///   This function is crucial when exporting scanned meshes for use in external 3D applications.
    ///   The resulting `MDLMesh` can be saved as an OBJ, USDZ, or other 3D model formats.
    ///
    /// - How it works:
    ///   1. **Convert Vertex Positions to World Coordinates**:
    ///      - Iterates over each vertex, transforms it using the provided model matrix, and updates its position.
    ///   2. **Create Metal Buffers**:
    ///      - Allocates a MetalKit buffer for storing vertex data.
    ///      - Allocates a MetalKit buffer for storing index (face) data.
    ///   3. **Define Mesh Structure**:
    ///      - Creates a `MDLSubmesh` to define the triangle-based mesh topology.
    ///      - Defines a `MDLVertexDescriptor` for interpreting vertex data correctly.
    ///   4. **Construct and Return the MDLMesh**:
    ///      - Assembles the vertex buffer, index buffer, and descriptor into an `MDLMesh`.
    func toMDLMesh(device: MTLDevice, camera: ARCamera, modelMatrix: simd_float4x4) -> MDLMesh {
        /// Converts local vertex positions into world-space coordinates.
        ///
        /// - This step ensures that when the mesh is exported, it retains its correct positioning in the real world.
        func convertVertexLocalToWorld() {
            let verticesPointer = vertices.buffer.contents()
            
            for vertexIndex in 0..<vertices.count {
                let vertex = self.vertex(at: UInt32(vertexIndex))
                
                var vertexLocalTransform = matrix_identity_float4x4
                vertexLocalTransform.columns.3 = SIMD4<Float>(x: vertex.x, y: vertex.y, z: vertex.z, w: 1)
                let vertexWorldPosition = (modelMatrix * vertexLocalTransform).columns.3
                
                let vertexOffset = vertices.offset + vertices.stride * vertexIndex
                let componentStride = vertices.stride / 3
                verticesPointer.storeBytes(of: vertexWorldPosition.x, toByteOffset: vertexOffset, as: Float.self)
                verticesPointer.storeBytes(of: vertexWorldPosition.y, toByteOffset: vertexOffset + componentStride, as: Float.self)
                verticesPointer.storeBytes(of: vertexWorldPosition.z, toByteOffset: vertexOffset + (2 * componentStride), as: Float.self)
            }
        }
        convertVertexLocalToWorld()
        
        // Allocate a Metal buffer to store vertex data
        let allocator = MTKMeshBufferAllocator(device: device)
        let data = Data.init(bytes: vertices.buffer.contents(), count: vertices.stride * vertices.count)
        let vertexBuffer = allocator.newBuffer(with: data, type: .vertex)
        
        // Allocate a Metal buffer to store index (face) data
        let indexData = Data.init(bytes: faces.buffer.contents(), count: faces.bytesPerIndex * faces.count * faces.indexCountPerPrimitive)
        let indexBuffer = allocator.newBuffer(with: indexData, type: .index)
        
        // Define submesh, which represents how vertices are connected to form faces
        let submesh = MDLSubmesh(indexBuffer: indexBuffer,
                                 indexCount: faces.count * faces.indexCountPerPrimitive,
                                 indexType: .uInt32,
                                 geometryType: .triangles,
                                 material: nil)
        
        // Define the vertex structure (position only in this case)
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                            format: .float3,
                                                            offset: 0,
                                                            bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: vertices.stride)
        
        // Construct and return the final mesh
        let mesh = MDLMesh(vertexBuffer: vertexBuffer,
                           vertexCount: vertices.count,
                           descriptor: vertexDescriptor,
                           submeshes: [submesh])
        
        return mesh
    }
}
