import UIKit
import SCSDKCameraKit

enum Constants {
    static let apiToken = "<YOUR_API_TOKEN>"
    static let groupId = "<YOUR_LENS_GROUP_ID>"
    static let lensId = "<YOUR_LENS_ID>"
}

class CameraViewController: UIViewController {
    
    private lazy var previewView = PreviewView()
    
    private lazy var cameraKit: CameraKitProtocol = {
        let sessionConfig = SessionConfig(apiToken: Constants.apiToken)
        let lensesConfig = LensesConfig(cacheConfig: CacheConfig(lensContentMaxSize: 150*1024*1024))
        
        return Session(
            sessionConfig: sessionConfig,
            lensesConfig: lensesConfig,
            errorHandler: nil
        )
    }()
    
    private lazy var captureSession = AVCaptureSession()
    
    override func loadView() {
        view = previewView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startSession()
        fetchLens()
    }
    
    private func startSession() {
        previewView.automaticallyConfiguresTouchHandler = true
        cameraKit.add(output: previewView)
        
        let sessionInput = AVSessionInput(session: captureSession)
        let arInput = ARSessionInput()
        cameraKit.start(input: sessionInput, arInput: arInput)
        
        DispatchQueue.global(qos: .utility).async {
            sessionInput.startRunning()
        }
    }
    
    private func fetchLens() {
        cameraKit.lenses.repository.addObserver(self, specificLensID: Constants.lensId, inGroupID: Constants.groupId)
    }
    
    private func applyLens(lens: Lens) {
        cameraKit.lenses.processor?.apply(lens: lens, launchData: nil) { success in
            if success {
                print("Lens Applied")
            } else {
                print("Did fail to apply lens")
            }
        }
    }
}

extension CameraViewController: LensRepositorySpecificObserver {
    func repository(_ repository: LensRepository, didUpdate lens: Lens, forGroupID groupID: String) {
        applyLens(lens: lens)
    }
    
    func repository(_ repository: LensRepository, didFailToUpdateLensID lensID: String, forGroupID groupID: String, error: Error?) {
        print("Did fail to update lens")
    }
}
