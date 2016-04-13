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
        "kernel vec2 gooWarp(float radius, float force,  vec2 location, vec2 direction)" +
        "{ " +
        " float dist = distance(location, destCoord()); " +
        
        "  if (dist < radius)" +
        "  { " +
            
        "     float normalisedDistance = 1.0 - (dist / radius); " +
        "     float smoothedDistance = smoothstep(0.0, 1.0, normalisedDistance); " +
            
        "    return destCoord() + (direction * force) * smoothedDistance; " +
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
        
        imageView.frame = view.bounds.insetBy(dx: 10, dy: topLayoutGuide.length)
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first,
            coalescedTouches = event?.coalescedTouchesForTouch(touch)
            where imageView.imageExtent.contains(touch.locationInView(imageView)) else
        {
            return
        }
        
        for coalescedTouch in coalescedTouches
        {
            let locationInImageY = (imageView.frame.height - coalescedTouch.locationInView(imageView).y - imageView.imageExtent.origin.y) / imageView.imageScale
            let locationInImageX = (coalescedTouch.locationInView(imageView).x - imageView.imageExtent.origin.x) / imageView.imageScale
            
            let location = CIVector(x: locationInImageX,
                                    y: locationInImageY)
            
            let direction = CIVector(x: coalescedTouch.previousLocationInView(imageView).x - touch.locationInView(imageView).x,
                                     y: coalescedTouch.locationInView(imageView).y - touch.previousLocationInView(imageView).y)
            
            let radius: CGFloat
            let force: CGFloat
            
            if coalescedTouch.maximumPossibleForce == 0
            {
                radius = 100
                force = 0.2
            }
            else
            {
                let normalisedForce = coalescedTouch.force / coalescedTouch.maximumPossibleForce
                radius = normalisedForce * 200
                force = normalisedForce * 0.4
            }

            let arguments = [radius, force, location, direction]
            
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

