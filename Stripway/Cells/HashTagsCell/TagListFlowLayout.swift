//
//  TagListFlowLayout.swift
//  TestTagList
//
//  Created by TrungHD-D1 on 4/16/20.
//  Copyright © 2020 TrungHD-D1. All rights reserved.
//

import UIKit

class TagListFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributesForElementsInRect = super.layoutAttributesForElements(in: rect) ?? []
        var newAttributesForElementsInRect = [UICollectionViewLayoutAttributes]()
        var leftMargin: CGFloat = 0.0
        
        for attributes in attributesForElementsInRect {
            if (attributes.frame.origin.x == self.sectionInset.left) {
                leftMargin = self.sectionInset.left
            } else {
                // set x position of attributes to current margin
                var newLeftAlignedFrame = attributes.frame
                newLeftAlignedFrame.origin.x = leftMargin
                attributes.frame = newLeftAlignedFrame
            }
            // calculate new value for current margin
            leftMargin += attributes.frame.size.width + 8
            newAttributesForElementsInRect.append(attributes)
        }
        return newAttributesForElementsInRect
    }
}
