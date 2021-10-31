//
//  GifCollectionView.swift
//  GifCollectionView
//
//  Created by Tamim on 29/10/21.
//

import Foundation
import UIKit

public final class GifCollectionView: UIView {
    var collectionView: UICollectionView!
    public weak var delegate: GifCollectionViewDelegate?
    private var collectionViewLayout: GifCollectionViewCustomLayout!
    private var provider: GifProvider = TenorGifProvider.init()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeViews()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeViews()
    }
    
    public func replaceProvider(_ provider: GifProvider) {
        self.provider = provider
    }
    
    public func setTenorApiKey(apiKey: String) {
        self.provider.setApiKey(apiKey: apiKey)
    }
    
    public func startLoadingGifs() {
        self.startLoadingGifs(nil)
    }
}

extension GifCollectionView { //UIView
    fileprivate func initializeViews(){
        collectionViewLayout = GifCollectionViewCustomLayout.init()
        collectionView = UICollectionView.init(frame: self.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(collectionView)
        setupConstraints()
        setupCollectionView()
    }
    
    fileprivate func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            collectionView.leftAnchor.constraint(equalTo: self.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
    }
    
    fileprivate func setupCollectionView() {
        collectionView.register(GifCollectionViewCell.self, forCellWithReuseIdentifier: "GifCollectionViewCell")
        collectionView.alwaysBounceVertical = true
        collectionView.allowsSelection = true
        collectionView.isUserInteractionEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionViewLayout.delegate = self
    }
    
    fileprivate func loadMoreGifs(){
        provider.loadMoreGifs { [weak self] success, insertItemsAt in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if success {
                    self.collectionView.performBatchUpdates {
                        self.collectionView.insertItems(at: insertItemsAt)
                    } completion: { success in
                        print("LoadMoreGifs success")
                    }
                }
            }
        }
    }
    
    fileprivate func startLoadingGifs(_ searchTerm: String?){
        provider.startLoadingGifs(with: searchTerm) { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.collectionViewLayout?.purgeCache()
                //self.collectionViewLayout?.invalidateLayout()
                self.collectionView.reloadData()
                self.collectionView.setContentOffset(.zero, animated: true)
            }
        }
    }
}

extension GifCollectionView: GifCollectionViewCustomLayoutDelegate {
    func cellPaddingFor(_ collectionView: UICollectionView) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, heightForCellAtIndexPath indexPath: IndexPath, contentWidth width: CGFloat) -> CGFloat {
        //first find the ratio between size.width and layout columns
        let gifItem = provider.gifItemAt(indexPath: indexPath)
        let layoutColumnWidthRatio = width/gifItem.gifItemSize.width
        //calculate the height
        let heightByCalulating = gifItem.gifItemSize.height * layoutColumnWidthRatio
        return heightByCalulating
    }
}

extension GifCollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.scrollViewDidScroll(scrollView)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return provider.numberOfItems()
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GifCollectionViewCell", for: indexPath) as! GifCollectionViewCell
        let gifItem = provider.gifItemAt(indexPath: indexPath)
        cell.setGifImage(url: gifItem.gifItemURL)
        return cell

    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gifItem = provider.gifItemAt(indexPath: indexPath)
        provider.registerShare(gifItem: gifItem)
        self.delegate?.didSelectGifItem(gifItem: gifItem)
        
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        
        let gifItem = provider.gifItemAt(indexPath: indexPath)
        return gifItem.gifItemSize
    }
}
