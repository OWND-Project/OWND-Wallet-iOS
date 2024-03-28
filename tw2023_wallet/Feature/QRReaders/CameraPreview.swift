//
//  CameraPreview.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/16.
//

import AVFoundation
import UIKit

class CameraPreview: UIView {
    private var label: UILabel?

    var previewLayer: AVCaptureVideoPreviewLayer?
    var session = AVCaptureSession()
    weak var delegate: QrCodeCameraDelegate?

    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        self.session = session
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onClick() {
        delegate?.onSimulateScanning()
    }

    private var overlayView: UIView?

    private func setupOverlay() {
        guard overlayView == nil else { return }

        let scanAreaSize: CGFloat = 300
        let newOverlayView = UIView()
        newOverlayView.frame = bounds
        newOverlayView.layer.addSublayer(createOverlayLayer(scanAreaSize: scanAreaSize))
        addSubview(newOverlayView)
        overlayView = newOverlayView
    }

    private func createOverlayLayer(scanAreaSize: CGFloat) -> CALayer {
        let overlayLayer = CALayer()
        overlayLayer.frame = bounds
        overlayLayer.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor

        let clearArea = CGRect(x: (bounds.width - scanAreaSize) / 2,
                               y: (bounds.height - scanAreaSize) / 2,
                               width: scanAreaSize,
                               height: scanAreaSize)

        let clearPath = UIBezierPath(rect: bounds)
        let scanAreaPath = UIBezierPath(rect: clearArea)
        clearPath.append(scanAreaPath)
        clearPath.usesEvenOddFillRule = true

        let fillLayer = CAShapeLayer()
        fillLayer.path = clearPath.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        overlayLayer.addSublayer(fillLayer)

        // 枠線の追加
        let borderLayer = CAShapeLayer()
        borderLayer.path = UIBezierPath(rect: clearArea).cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 2
        overlayLayer.addSublayer(borderLayer)

        return overlayLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // `previewLayer`のフレーム更新
        previewLayer?.frame = bounds
        // オーバーレイのセットアップがまだ行われていない場合にのみ実行
        if overlayView == nil {
            setupOverlay()
        }
    }
}
