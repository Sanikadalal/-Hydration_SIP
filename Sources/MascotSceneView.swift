import SwiftUI
import SceneKit

enum MascotType {
    case blob
    case robot
}

struct MascotSceneView: View {
    var mascotType: MascotType = .blob
    
    var body: some View {
        SceneView(
            scene: createScene(),
            options: [.autoenablesDefaultLighting, .allowsCameraControl],
            preferredFramesPerSecond: 60,
            antialiasingMode: .multisampling4X
        )
        .background(Color.clear)
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor.clear
        
        let rootNode = SCNNode()
        scene.rootNode.addChildNode(rootNode)
        
        if mascotType == .blob {
            buildBlobMascot(in: rootNode)
        } else {
            buildRobotMascot(in: rootNode)
        }
        
        // Add a dropping animation
        let dropAction = SCNAction.sequence([
            SCNAction.move(to: SCNVector3(0, 5, 0), duration: 0),
            SCNAction.move(to: SCNVector3(0, -0.5, 0), duration: 0.6).timingMode(.easeOut),
            SCNAction.move(to: SCNVector3(0, 0, 0), duration: 0.3).timingMode(.easeInEaseOut)
        ])
        rootNode.runAction(dropAction)
        
        // Soft continuous floating animation
        let floatUp = SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 1.5)
        floatUp.timingMode = .easeInEaseOut
        let floatDown = floatUp.reversed()
        let floatSequence = SCNAction.sequence([floatUp, floatDown])
        let floatLoop = SCNAction.repeatForever(floatSequence)
        rootNode.runAction(floatLoop)
        
        // Add some lights
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.intensity = 500
        scene.rootNode.addChildNode(ambientLightNode)
        
        let directionalLightNode = SCNNode()
        directionalLightNode.light = SCNLight()
        directionalLightNode.light?.type = .directional
        directionalLightNode.light?.intensity = 1000
        directionalLightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        directionalLightNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLightNode)
        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0.5, 6)
        scene.rootNode.addChildNode(cameraNode)
        
        return scene
    }
    
    private func buildBlobMascot(in rootNode: SCNNode) {
        // Body (Cute Blob)
        let bodyGeo = SCNSphere(radius: 1.0)
        bodyGeo.firstMaterial?.diffuse.contents = NSColor(calibratedRed: 0.3, green: 0.7, blue: 0.9, alpha: 1.0)
        bodyGeo.firstMaterial?.specular.contents = NSColor.white
        bodyGeo.firstMaterial?.shininess = 50
        let bodyNode = SCNNode(geometry: bodyGeo)
        rootNode.addChildNode(bodyNode)
        
        // Eyes
        let eyeGeo = SCNSphere(radius: 0.15)
        eyeGeo.firstMaterial?.diffuse.contents = NSColor.black
        
        let leftEye = SCNNode(geometry: eyeGeo)
        leftEye.position = SCNVector3(-0.35, 0.2, 0.85)
        bodyNode.addChildNode(leftEye)
        
        let rightEye = SCNNode(geometry: eyeGeo)
        rightEye.position = SCNVector3(0.35, 0.2, 0.85)
        bodyNode.addChildNode(rightEye)
        
        // Pout Mouth
        let mouthGeo = SCNTorus(ringRadius: 0.08, pipeRadius: 0.03)
        mouthGeo.firstMaterial?.diffuse.contents = NSColor.systemPink
        let mouthNode = SCNNode(geometry: mouthGeo)
        mouthNode.position = SCNVector3(0, -0.1, 0.95)
        // Rotate so it looks like a pout (O shape)
        mouthNode.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
        bodyNode.addChildNode(mouthNode)
        
        // Arms
        let armGeo = SCNCapsule(capRadius: 0.15, height: 0.8)
        armGeo.firstMaterial?.diffuse.contents = NSColor(calibratedRed: 0.3, green: 0.7, blue: 0.9, alpha: 1.0)
        
        let leftArm = SCNNode(geometry: armGeo)
        leftArm.position = SCNVector3(-1.1, -0.2, 0.2)
        leftArm.eulerAngles = SCNVector3(0, 0, Float.pi/4)
        bodyNode.addChildNode(leftArm)
        
        let rightArm = SCNNode(geometry: armGeo)
        rightArm.position = SCNVector3(1.1, -0.2, 0.5)
        rightArm.eulerAngles = SCNVector3(-Float.pi/4, 0, -Float.pi/4)
        bodyNode.addChildNode(rightArm)
        
        // Glass of Water in Right Arm
        let glassGeo = SCNCylinder(radius: 0.2, height: 0.6)
        glassGeo.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(0.3)
        glassGeo.firstMaterial?.transparency = 0.6
        glassGeo.firstMaterial?.isDoubleSided = true
        let glassNode = SCNNode(geometry: glassGeo)
        
        // Water inside glass
        let waterGeo = SCNCylinder(radius: 0.18, height: 0.4)
        waterGeo.firstMaterial?.diffuse.contents = NSColor.cyan.withAlphaComponent(0.8)
        let waterNode = SCNNode(geometry: waterGeo)
        waterNode.position = SCNVector3(0, -0.05, 0)
        glassNode.addChildNode(waterNode)
        
        glassNode.position = SCNVector3(0, 0.4, 0.2)
        glassNode.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
        rightArm.addChildNode(glassNode)
    }
    
    private func buildRobotMascot(in rootNode: SCNNode) {
        // Boxy Head
        let headGeo = SCNBox(width: 1.2, height: 1.0, length: 1.0, chamferRadius: 0.2)
        headGeo.firstMaterial?.diffuse.contents = NSColor.lightGray
        let headNode = SCNNode(geometry: headGeo)
        headNode.position = SCNVector3(0, 0.5, 0)
        rootNode.addChildNode(headNode)
        
        // Eyes
        let eyeGeo = SCNBox(width: 0.2, height: 0.1, length: 0.1, chamferRadius: 0.05)
        eyeGeo.firstMaterial?.diffuse.contents = NSColor.cyan
        eyeGeo.firstMaterial?.emission.contents = NSColor.cyan
        
        let leftEye = SCNNode(geometry: eyeGeo)
        leftEye.position = SCNVector3(-0.3, 0.1, 0.5)
        headNode.addChildNode(leftEye)
        
        let rightEye = SCNNode(geometry: eyeGeo)
        rightEye.position = SCNVector3(0.3, 0.1, 0.5)
        headNode.addChildNode(rightEye)
        
        // Pout Mouth
        let mouthGeo = SCNTorus(ringRadius: 0.08, pipeRadius: 0.03)
        mouthGeo.firstMaterial?.diffuse.contents = NSColor.darkGray
        let mouthNode = SCNNode(geometry: mouthGeo)
        mouthNode.position = SCNVector3(0, -0.2, 0.5)
        mouthNode.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
        headNode.addChildNode(mouthNode)
        
        // Body
        let bodyGeo = SCNBox(width: 0.8, height: 1.0, length: 0.6, chamferRadius: 0.1)
        bodyGeo.firstMaterial?.diffuse.contents = NSColor.gray
        let bodyNode = SCNNode(geometry: bodyGeo)
        bodyNode.position = SCNVector3(0, -0.6, 0)
        rootNode.addChildNode(bodyNode)
        
        // Right Arm with glass
        let armGeo = SCNCapsule(capRadius: 0.15, height: 0.8)
        armGeo.firstMaterial?.diffuse.contents = NSColor.lightGray
        let rightArm = SCNNode(geometry: armGeo)
        rightArm.position = SCNVector3(0.6, 0.2, 0.4)
        rightArm.eulerAngles = SCNVector3(-Float.pi/4, 0, -Float.pi/6)
        bodyNode.addChildNode(rightArm)
        
        // Glass of Water
        let glassGeo = SCNCylinder(radius: 0.2, height: 0.6)
        glassGeo.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(0.3)
        let glassNode = SCNNode(geometry: glassGeo)
        
        let waterGeo = SCNCylinder(radius: 0.18, height: 0.4)
        waterGeo.firstMaterial?.diffuse.contents = NSColor.cyan.withAlphaComponent(0.8)
        let waterNode = SCNNode(geometry: waterGeo)
        waterNode.position = SCNVector3(0, -0.05, 0)
        glassNode.addChildNode(waterNode)
        
        glassNode.position = SCNVector3(0, 0.4, 0.2)
        glassNode.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
        rightArm.addChildNode(glassNode)
    }
}
