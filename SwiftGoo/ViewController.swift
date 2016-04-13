//
//  ViewController.swift
//  SwiftGoo
//
//  Created by Simon Gladman on 13/04/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    let imageView = OpenGLImageView()
    let mona = CIImage(image: UIImage(named: "monalisa.jpg")!)
    
    let accumulator = CIImageAccumulator(extent: CGRect(x: 0, y: 0, width: 640, height: 640),
                                         format: kCIFormatARGB8)
    
    let warpKernel = CIWarpKernel(string:
        "kernel vec2 warp(float radius, vec2 location, vec2 direction)" +
        "{ " +
        " float dist = distance(location, destCoord()); " +
        
        "  if (dist < radius)" +
        "  { " +
            
        "     float normalisedDistance = 1.0 - (dist / radius); " +
        "     float smoothedDistance = smoothstep(0.0, 1.0, normalisedDistance); " +
            
        "    return destCoord() + (direction * 0.2) * smoothedDistance; " +
        "  } else { " +
        "  return destCoord();" +
        "  }" +
        "}")!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    
        view.addSubview(imageView)
        
        accumulator.setImage(mona!)
        
        imageView.image = accumulator.image()
    }

    override func viewDidLayoutSubviews()
    {
        imageView.frame = CGRect(x: 0, y: 0, width: 640, height: 640)
        
        imageView.frame.origin.x = view.frame.midX - imageView.frame.midX
        imageView.frame.origin.y = view.frame.midY - imageView.frame.midY
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first,
            coalescedTouches = event?.coalescedTouchesForTouch(touch)
            where imageView.bounds.contains(touch.locationInView(imageView)) else
        {
            return
        }
        
        for coalescedTouch in [touch] // coalescedTouches
        {
            let locationInViewY = accumulator.image().extent.height - coalescedTouch.locationInView(imageView).y
            
            let location = CIVector(x: coalescedTouch.locationInView(imageView).x, y: locationInViewY)
            let direction = CIVector(x: coalescedTouch.previousLocationInView(imageView).x - touch.locationInView(imageView).x,
                                     y: coalescedTouch.locationInView(imageView).y - touch.previousLocationInView(imageView).y)
            
            let arguments = [CGFloat(100), location, direction]
            
            let image = warpKernel.applyWithExtent(accumulator.image().extent,
                                                    roiCallback:
                {
                    (index, rect) in
                    return rect
                },
                                                    inputImage: accumulator.image(),
                                                    arguments: arguments)
            
            accumulator.setImage(image!)
            
            imageView.image = accumulator.image()
        }
    }
    
    
}

