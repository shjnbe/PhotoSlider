//
//  ImageView.swift
//
//  Created by nakajijapan on 3/29/15.
//  Copyright (c) 2015 net.nakajijapan. All rights reserved.
//

import UIKit
import Kingfisher

protocol PhotoSliderImageViewDelegate {
    func photoSliderImageViewDidEndZooming(_ viewController: PhotoSlider.ImageView, atScale scale: CGFloat)
}

class ImageView: UIView {

    var imageView: UIImageView!
    var scrollView: UIScrollView!
    var progressView: PhotoSlider.ProgressView!
    var delegate: PhotoSliderImageViewDelegate? = nil
    weak var imageLoader: PhotoSlider.ImageLoader?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initialize()
    }
    
    func initialize() {

        backgroundColor = UIColor.clear
        isUserInteractionEnabled = true

        // for zoom
        scrollView = UIScrollView(frame: self.bounds)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.bounces = true
        scrollView.delegate  = self
        
        // image
        imageView = UIImageView(frame: CGRect.zero)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true

        addSubview(scrollView)
        layoutScrollView()

        scrollView.addSubview(imageView)
       
        // progress view
        progressView = ProgressView(frame: CGRect.zero)
        progressView.isHidden = true
        addSubview(progressView)
        layoutProgressView()
        
        let doubleTabGesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap(_:)))
        doubleTabGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTabGesture)
        
        imageView.autoresizingMask = [
            .flexibleWidth,
            .flexibleLeftMargin,
            .flexibleRightMargin,
            .flexibleTopMargin,
            .flexibleHeight,
            .flexibleBottomMargin
        ]
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let boundsSize = self.bounds.size
        var frameToCenter = self.imageView.frame
        
        // Horizontally
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / 2.0)
        } else {
            frameToCenter.origin.x = 0
        }
        
        // Vertically
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / 2.0)
        } else {
            frameToCenter.origin.y = 0
        }
        
        // Center
        if !(imageView.frame.equalTo(frameToCenter)) {
            imageView.frame = frameToCenter
        }
    }
    
    // MARK: - Constraints
    
    private func layoutScrollView() {
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            scrollView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0),
            scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0),
            scrollView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0.0),
            scrollView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0.0),
            ].map { $0.isActive = true }
    }
    
    private func layoutProgressView() {

        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            progressView.heightAnchor.constraint(equalToConstant: 40.0),
            progressView.widthAnchor.constraint(equalToConstant: 40.0),
            progressView.centerXAnchor.constraint(lessThanOrEqualTo: self.centerXAnchor, constant: 1.0),
            progressView.centerYAnchor.constraint(lessThanOrEqualTo: self.centerYAnchor, constant: 1.0),
            ].map { $0.isActive = true }
     }
    
    func loadImage(imageURL: URL) {
        progressView.isHidden = false
        imageLoader?.load(
            imageView: imageView,
            fromURL: imageURL,
            progress: { [weak self] (receivedSize, totalSize) in
                let progress: Float = Float(receivedSize) / Float(totalSize)
                self?.progressView.animateCurveToProgress(progress: progress)
            },
            completion: { [weak self] (image) in
                self?.progressView.isHidden = true
                if let image = image {
                    self?.layoutImageView(image: image)
                }
            }
        )
    }
    
    func setImage(image:UIImage) {
        imageView.image = image
        layoutImageView(image: image)
    }
    
    func layoutImageView(image:UIImage) {
        var frame = CGRect.zero
        frame.origin = CGPoint.zero
        
        let height = image.size.height * (self.bounds.width / image.size.width)
        let width = image.size.width * (self.bounds.height / image.size.height)
        
        if image.size.width > image.size.height {
            
            frame.size = CGSize(width: self.bounds.width, height: height)
            if height >= self.bounds.height {
                frame.size = CGSize(width: width, height: self.bounds.height)
            }
            
        } else {

            frame.size = CGSize(width: width, height: self.bounds.height)
            if width >= self.bounds.width {
                frame.size = CGSize(width: self.bounds.width, height: height)
            }

        }
        
        imageView.frame = frame
        imageView.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    func layoutImageView() {
        
        guard let image = self.imageView.image else {
            return
        }
        layoutImageView(image: image)
    }
    
}

// MARK: - Actions

extension ImageView {

    func didDoubleTap(_ sender: UIGestureRecognizer) {
        if self.scrollView.zoomScale == 1.0 {
            let touchPoint = sender.location(in: self)
            scrollView.zoom(to: CGRect(x: touchPoint.x, y: touchPoint.y, width: 1, height: 1), animated: true)
        } else {
            scrollView.setZoomScale(0.0, animated: true)
        }
    }
    
}

// MARK: - UIScrollViewDelegate

extension ImageView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegate?.photoSliderImageViewDidEndZooming(self, atScale: scale)
    }
    
}
